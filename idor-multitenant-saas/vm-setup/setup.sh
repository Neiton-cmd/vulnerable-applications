#!/usr/bin/env bash
set -euo pipefail

JONNY_PUBKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6Pq6KVf6KoqJrW7tzOftvu3oWLhwVikHYmST0z4SEQunwSoyp48zhCAbSP236Ozu4sy2QPPx+7rwfa6R05J+mRCi4d0QzjMCWoQjTUNKBuXixo/fHsoKGUH2L8mtD5vTTBXj1Dr9NWb/DAQP5Fas7YqeOXieJfSqp1ofBLoSDYpcJWZ9ZVl09oqSpBEWftkT7VABNW2OkBYd8gbHB+6+atKyhWPZUeFrBStP0jzOLmN60aQbFgetQb52tc1n6wK6GI9M7M7dh72f1s1LmazNL4vSDW/hd6o1q7j42SaHzueLKCbQk95ezvmLQb/GRugHimz4Az9JtVkyXSjbJfvuTNPsbCi9BE+hEGHI1OR/Z47PVyzi9wXUYTikGG8qUFWaMpChP7Zt/Eu8MTcvqgQwU5NwgEMP65UWKc9amZMpEbgTzf1brmovC5wIdSG/zLLOxAlBMlTT9zUgM8UC+rhp3tEbmHpe09ZKhsOb14VIeqdb1KsVntdqPzBcx+N/o9/g3JcLPlsHIyTpb9SBjnpFGPuYj/Hi3ynHpGOYekWmyYX66YHv+JauZfsZCCZg2VvVrVmz5Hp6ZpfI2XsU44AVHsLZWG88hTKUwweigCmc3z5NIeZLYUPiqRk93kD5cqcWB3rsaJ2r8myTQnGG8+p2krC8WcMrO5wbhjH83fsXpMw== jonny@vulnshop.htb"
USER_FLAG="04b0064cf07df896f1ae5afb5e37bb41"
ROOT_FLAG="2f989df58508658fb95de2f6eef2208e"

echo "[*] Updating system..."
export DEBIAN_FRONTEND=noninteractive
# Remove any leftover third-party repos from previous runs
rm -f /etc/apt/sources.list.d/netdata.list /usr/share/keyrings/netdata-archive-keyring.gpg
apt-get update -qq
apt-get upgrade -y -qq

echo "[*] Installing packages..."
apt-get install -y -qq curl wget git nginx openssh-server ufw net-tools ca-certificates gnupg lsb-release dnsmasq

echo "[*] Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --batch --yes --no-tty --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable"   > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "[*] Creating project directory..."
mkdir -p /opt/omni-store
chown omni:omni /opt/omni-store
usermod -aG docker omni

echo "[*] Adding provisioning SSH key for omni..."
OMNI_PROVISION_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINAppLyA2sMoO+5PybaP+JpSR/yoG+Oqt4P+G239Qlny kali@kali"
mkdir -p /home/omni/.ssh
echo "$OMNI_PROVISION_KEY" > /home/omni/.ssh/authorized_keys
chmod 700 /home/omni/.ssh
chmod 600 /home/omni/.ssh/authorized_keys
chown -R omni:omni /home/omni/.ssh

echo "[*] Creating jonny user (foothold)..."
useradd -m -s /bin/bash jonny 2>/dev/null || true
mkdir -p /home/jonny/.ssh
# jonny's private key lives inside the backend Docker container (SSRF target)
# authorized_keys must match the public key baked into the container image
echo "$JONNY_PUBKEY" > /home/jonny/.ssh/authorized_keys
chmod 700 /home/jonny/.ssh
chmod 600 /home/jonny/.ssh/authorized_keys
chown -R jonny:jonny /home/jonny
passwd -l jonny

echo "[*] Creating sarah user..."
useradd -m -s /bin/bash sarah 2>/dev/null || true
passwd -l sarah
mkdir -p /home/sarah/.ssh
touch /home/sarah/.ssh/authorized_keys
chmod 700 /home/sarah/.ssh
chmod 600 /home/sarah/.ssh/authorized_keys
chown -R sarah:sarah /home/sarah/.ssh
mkdir -p /home/sarah/.local/share/omni
chown -R sarah:sarah /home/sarah/.local

echo "[*] Creating mark user..."
useradd -m -s /bin/bash mark 2>/dev/null || true
passwd -l mark

echo "[*] Writing flags..."
echo "$USER_FLAG" > /home/sarah/user.txt
chown root:sarah /home/sarah/user.txt
chmod 644 /home/sarah/user.txt

echo "$ROOT_FLAG" > /root/root.txt
chown root:root /root/root.txt
chmod 640 /root/root.txt

echo "[*] Building SUID binary log-report..."
apt-get install -y -qq gcc

cat > /tmp/log-report.c << 'C_EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h>

#define INPUT_PATH  "/tmp/.report_in"
#define OUTPUT_PATH "/tmp/.report_out"
#define BUF_SIZE    2048

int main(void)
{
    struct stat st;
    char buf[BUF_SIZE];
    size_t n;
    time_t ts = time(NULL);

    /* Security: refuse to write if output path is already a symlink. */
    if (lstat(OUTPUT_PATH, &st) == 0) {
        if (S_ISLNK(st.st_mode)) {
            fprintf(stderr, "[log-report] security check failed: "
                            "output path is a symlink\n");
            return 1;
        }
        unlink(OUTPUT_PATH);
    }

    FILE *fin = fopen(INPUT_PATH, "r");
    if (!fin) {
        fprintf(stderr, "[log-report] cannot open input %s: %s\n",
                INPUT_PATH, strerror(errno));
        return 1;
    }

    printf("[log-report] archiving report entry -- %s", ctime(&ts));
    fflush(stdout);

    /*
     * Small I/O scheduling delay to allow the filesystem buffer
     * to settle before writing the output archive.
     */
    sleep(2);

    /* Effective UID = sarah (SUID) */
    FILE *fout = fopen(OUTPUT_PATH, "w");
    if (!fout) {
        fclose(fin);
        fprintf(stderr, "[log-report] cannot open output %s: %s\n",
                OUTPUT_PATH, strerror(errno));
        return 1;
    }

    while ((n = fread(buf, 1, sizeof(buf), fin)) > 0)
        fwrite(buf, 1, n, fout);

    fclose(fin);
    fclose(fout);

    printf("[log-report] done. archived to %s\n", OUTPUT_PATH);
    return 0;
}
C_EOF

gcc -O0 -o /usr/local/bin/log-report /tmp/log-report.c
chown sarah:sarah /usr/local/bin/log-report
chmod 4755 /usr/local/bin/log-report
rm /tmp/log-report.c

# Remove gcc — no compiler on the target
apt-get remove -y gcc gcc-12 gcc-13 2>/dev/null || true
apt-get autoremove -y -qq

echo "[*] Verifying SUID binary..."
ls -la /usr/local/bin/log-report

echo "[*] Configuring nginx..."
cat > /etc/nginx/sites-available/omni << 'NGINX_EOF'
server {
    listen 80 default_server;
    server_name vulnshop.htb _;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        "upgrade";
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
ln -sf /etc/nginx/sites-available/omni /etc/nginx/sites-enabled/omni
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo "[*] Configuring Docker daemon..."
mkdir -p /etc/docker
echo '{"userland-proxy": false}' > /etc/docker/daemon.json

echo "[*] Creating systemd service..."
cat > /etc/systemd/system/omni-store.service << 'SVC_EOF'
[Unit]
Description=Omni Store (Docker Compose)
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/omni-store
ExecStart=/usr/bin/docker compose up -d --build
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
SVC_EOF

echo "[*] Setting up Netdata monitoring..."

# Create netdata system user/group
getent group netdata >/dev/null  || groupadd --system netdata
getent passwd netdata >/dev/null || useradd --system --no-create-home \
    --gid netdata --home /opt/netdata --shell /usr/sbin/nologin netdata

# Add sarah to netdata group
usermod -aG netdata sarah

# Netdata directory tree
mkdir -p /opt/netdata/{etc/netdata,var/{lib,log,run}/netdata,custom-checks}
chown -R netdata:netdata /opt/netdata/var
chown root:root /opt/netdata/etc
chown root:netdata /opt/netdata/custom-checks
chmod 2775 /opt/netdata/custom-checks   # SGID: new files inherit netdata group

# Minimal config file so enumeration finds it
mkdir -p /opt/netdata/etc/netdata
cat > /opt/netdata/etc/netdata/netdata.conf << 'NDCONF'
[global]
    run as user = netdata
    web files owner = root
    web files group = netdata
    bind socket to IP = 127.0.0.1
    default port = 19999

[plugins]
    custom.d directory = /opt/netdata/custom-checks
NDCONF

# Lightweight Python stub on 127.0.0.1:19999 (represents the Netdata dashboard)
apt-get install -y -qq python3 2>/dev/null || true
cat > /opt/netdata/netdata-stub.py << 'PYSTUB'
#!/usr/bin/env python3
import http.server, socketserver, json, time

INFO = {"netdata_version":"1.46.3","os":"linux","hostname":"vulnshop"}

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        body = json.dumps(INFO).encode()
        self.send_response(200)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

socketserver.TCPServer(("127.0.0.1", 19999), H).serve_forever()
PYSTUB
chmod 755 /opt/netdata/netdata-stub.py

# Systemd unit for the stub
cat > /etc/systemd/system/netdata.service << 'NDSVC'
[Unit]
Description=Netdata - Real-time performance monitoring
After=network.target

[Service]
Type=simple
User=netdata
Group=netdata
ExecStart=/usr/bin/python3 /opt/netdata/netdata-stub.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
NDSVC

# Root cron executes all *.sh scripts from the directory every minute
cat > /etc/cron.d/netdata-custom << 'CRON_EOF'
# Netdata custom health checks — team members can add monitoring scripts here
*/1 * * * * root find /opt/netdata/custom-checks -maxdepth 1 -name "*.sh" -executable -exec bash {} \;
CRON_EOF
chmod 644 /etc/cron.d/netdata-custom

systemctl daemon-reload
systemctl enable netdata
systemctl start netdata

echo "[*] Disabling protected symlinks (required for SUID race condition challenge)..."
echo "fs.protected_symlinks = 0" > /etc/sysctl.d/99-ctf.conf
echo "fs.protected_hardlinks = 0" >> /etc/sysctl.d/99-ctf.conf
echo 0 > /proc/sys/fs/protected_symlinks
echo 0 > /proc/sys/fs/protected_hardlinks

echo "[*] Configuring /etc/hosts..."
grep -q "vulnshop.htb" /etc/hosts || echo "127.0.0.1 vulnshop.htb" >> /etc/hosts

echo "[*] Hardening SSH..."
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

echo "[*] Disabling shell history..."
cat > /etc/profile.d/nohist.sh << 'HIST_EOF'
export HISTFILE=/dev/null
unset HISTFILE
HIST_EOF
chmod +x /etc/profile.d/nohist.sh

# Symlink history files → /dev/null for all users (immutable, owned root)
for USER_DIR in /root /home/omni /home/jonny /home/sarah /home/mark; do
    for HIST_FILE in .bash_history .zsh_history .sh_history .viminfo .mysql_history .python_history; do
        TARGET="$USER_DIR/$HIST_FILE"
        ln -sf /dev/null "$TARGET" 2>/dev/null || true
        chown root:root "$TARGET" 2>/dev/null || true
    done
done
# Also set in /etc/bash.bashrc for interactive shells
grep -q "HISTFILE=/dev/null" /etc/bash.bashrc || echo "export HISTFILE=/dev/null" >> /etc/bash.bashrc

echo "[*] Configuring DNS (dnsmasq) for vulnshop.htb..."
# Disable systemd-resolved stub on port 53 so dnsmasq can bind
sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
systemctl restart systemd-resolved 2>/dev/null || true

cat > /etc/dnsmasq.d/vulnshop.conf << 'DNS_EOF'
# Authoritative DNS for vulnshop.htb
no-resolv
no-hosts
domain=vulnshop.htb

# A records
address=/vulnshop.htb/MACHINE_IP
address=/www.vulnshop.htb/MACHINE_IP

# MX record (for realism)
mx-host=vulnshop.htb,mail.vulnshop.htb,10

# Fallback upstream
server=8.8.8.8
server=1.1.1.1
DNS_EOF

# Replace MACHINE_IP with actual interface IP at runtime
MACHINE_IP=$(ip -4 addr show enp0s3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
sed -i "s/MACHINE_IP/$MACHINE_IP/g" /etc/dnsmasq.d/vulnshop.conf

systemctl enable dnsmasq
systemctl restart dnsmasq

echo "[*] Configuring docker-compose ports (localhost-only)..."
# Will be applied after project files are copied

echo "[*] Enabling services..."
systemctl daemon-reload
systemctl enable docker nginx omni-store
systemctl restart nginx

echo "[*] Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (nginx)
ufw allow 53/tcp    # DNS
ufw allow 53/udp    # DNS
ufw --force enable

echo "[*] Blocking Docker port exposure (Docker bypasses UFW)..."
# Docker rewrites iptables and bypasses UFW; use DOCKER-USER chain to restrict
apt-get install -y -qq iptables-persistent 2>/dev/null || true
# Drop external access to Docker-exposed app ports; allow loopback only
iptables -I DOCKER-USER -i enp0s3 -p tcp --dport 3000 -j DROP
iptables -I DOCKER-USER -i enp0s3 -p tcp --dport 8000 -j DROP
iptables -I DOCKER-USER -i enp0s3 -p tcp --dport 5432 -j DROP
# Allow Docker containers to make outbound connections (SSRF chain requires this)
iptables -I FORWARD -s 172.18.0.0/16 -o enp0s3 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

echo ""
echo "[+] Base setup complete!"
echo "[!] Next step: copy project files to /opt/omni-store/ and run:"
echo "    sudo systemctl start omni-store"
