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
chmod 711 /home/jonny
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
chmod 640 /home/sarah/user.txt

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
#include <time.h>

#define XOR_KEY 0x5A

static void xor_decode(char *dst, const unsigned char *src, size_t n) {
    for (size_t i = 0; i < n; i++)
        dst[i] = (char)(src[i] ^ XOR_KEY);
    dst[n] = '\0';
}

/* "/home/jonny/.report_in"  XOR 0x5A */
static const unsigned char ENC_IN[] = {
    0x75,0x32,0x35,0x37,0x3F,0x75,0x30,0x35,0x34,0x34,0x23,
    0x75,0x74,0x28,0x3F,0x2A,0x35,0x28,0x2E,0x05,0x33,0x34
};
/* "/home/jonny/.report_out" XOR 0x5A */
static const unsigned char ENC_OUT[] = {
    0x75,0x32,0x35,0x37,0x3F,0x75,0x30,0x35,0x34,0x34,0x23,
    0x75,0x74,0x28,0x3F,0x2A,0x35,0x28,0x2E,0x05,0x35,0x2F,0x2E
};

int main(void)
{
    char input_path[64], output_path[64];
    xor_decode(input_path,  ENC_IN,  sizeof ENC_IN);
    xor_decode(output_path, ENC_OUT, sizeof ENC_OUT);

    struct stat st;
    char buf[2048];
    size_t n;
    time_t ts = time(NULL);

    if (lstat(output_path, &st) == 0) {
        if (S_ISLNK(st.st_mode))
            return 1;
        unlink(output_path);
    }

    FILE *fin = fopen(input_path, "r");
    if (!fin)
        return 1;

    printf("[log-report] archiving report entry -- %s", ctime(&ts));
    fflush(stdout);

    sleep(30);

    FILE *fout = fopen(output_path, "w");
    if (!fout) {
        fclose(fin);
        return 1;
    }

    while ((n = fread(buf, 1, sizeof buf, fin)) > 0)
        fwrite(buf, 1, n, fout);

    fclose(fin);
    fclose(fout);

    printf("[log-report] done.\n");
    return 0;
}
C_EOF

gcc -O0 -s -o /usr/local/bin/log-report /tmp/log-report.c
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
cat > /etc/systemd/system/docker-bridge-fix.service << 'BRIDGEFIX_EOF'
[Unit]
Description=Disable iptables filtering for Docker bridge traffic
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
BRIDGEFIX_EOF

cat > /etc/systemd/system/omni-store.service << 'SVC_EOF'
[Unit]
Description=Omni Store (Docker Compose)
After=docker.service docker-bridge-fix.service network-online.target
Requires=docker.service docker-bridge-fix.service

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

echo "[*] Installing real Netdata..."
wget -q -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sh /tmp/netdata-kickstart.sh --non-interactive --stable-channel --disable-cloud --dont-start-it 2>&1 | tail -3
rm -f /tmp/netdata-kickstart.sh

# Configure: localhost only + custom-checks directory hint
cat > /etc/netdata/netdata.conf << 'NDCONF'
[global]
    run as user = netdata
    web files owner = root
    web files group = netdata
    bind to = 127.0.0.1
    default port = 19999

[plugins]
    custom.d directory = /opt/netdata/custom-checks
NDCONF

# Create custom-checks directory (group-writable — the privesc target)
mkdir -p /opt/netdata/custom-checks
chown root:netdata /opt/netdata/custom-checks
chmod 2775 /opt/netdata/custom-checks

# Add sarah to netdata group
usermod -aG netdata sarah

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
# Disable unprivileged user namespaces to mitigate kernel CVEs (CVE-2025-38236, CVE-2026-43284)
echo "kernel.unprivileged_userns_clone = 0" >> /etc/sysctl.d/99-ctf.conf
echo 0 > /proc/sys/fs/protected_symlinks
echo 0 > /proc/sys/fs/protected_hardlinks
echo 0 > /proc/sys/kernel/unprivileged_userns_clone 2>/dev/null || true
# Block xfrm_user / rxrpc kernel modules (CVE-2026-43284/43500 mitigation)
cat > /etc/modprobe.d/99-ctf-mitigations.conf << 'MODPROBE_EOF'
install xfrm_user /bin/false
install rxrpc /bin/false
MODPROBE_EOF

echo "[*] Setting hostname..."
hostnamectl set-hostname vulnshop
echo "vulnshop" > /etc/hostname
grep -q "127.0.1.1" /etc/hosts && sed -i 's/127.0.1.1.*/127.0.1.1\tvulnshop/' /etc/hosts || echo "127.0.1.1	vulnshop" >> /etc/hosts

echo "[*] Configuring /etc/hosts..."
grep -q "vulnshop.htb" /etc/hosts || echo "127.0.0.1 vulnshop.htb" >> /etc/hosts

echo "[*] Hardening SSH..."
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
# Allow password auth only for omni, sarah, root (jonny is key-only — that's the challenge)
grep -q 'Match User omni' /etc/ssh/sshd_config || cat >> /etc/ssh/sshd_config << 'SSH_EOF'

Match User omni,sarah,root
    PasswordAuthentication yes
SSH_EOF

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
ufw --force enable

echo "[*] Configuring dnsmasq to listen on loopback only..."
grep -q 'listen-address=127.0.0.1' /etc/dnsmasq.d/vulnshop.conf || \
  printf '\nlisten-address=127.0.0.1\nbind-interfaces\n' >> /etc/dnsmasq.d/vulnshop.conf
systemctl restart dnsmasq

# Docker ports are bound to 127.0.0.1 via docker-compose.prod.yml — no external exposure.
# Disable bridge-nf-call-iptables so iptables does not filter intra-bridge container traffic.
echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null || true
echo "net.bridge.bridge-nf-call-iptables = 0" >> /etc/sysctl.d/99-ctf.conf

echo ""
echo "[+] Base setup complete!"
echo "[!] Next step: copy project files to /opt/omni-store/ and run:"
echo "    sudo systemctl start omni-store"
