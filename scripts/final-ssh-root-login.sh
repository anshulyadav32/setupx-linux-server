#!/usr/bin/env bash
set -euo pipefail

DEFAULT_PASS="passwordroot"
ROOT_PASS="$DEFAULT_PASS"

while getopts ":p:h" opt; do
  case $opt in
    p) ROOT_PASS="$OPTARG" ;;
    h) echo "Usage: sudo $0 [-p <root-pass>]"; exit 0 ;;
  esac
done

# Must be root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Run with sudo"; exit 1
fi

# Backup and disable extra configs
cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s) || true
mkdir -p /etc/ssh/sshd_config.d/disabled
mv /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config.d/disabled/ 2>/dev/null || true

# Write clean sshd_config
cat > /etc/ssh/sshd_config <<CFG
Port 22
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
CFG

# Set root password
echo "root:${ROOT_PASS}" | chpasswd
usermod -U root || true

# Verify locally
if echo "${ROOT_PASS}" | su - root -c "whoami" 2>/dev/null | grep -q root; then
  echo "🔑 Verified root password works via su"
else
  echo "⚠️ Password set but local su verification failed (check PAM)"
fi

# Restart sshd
systemctl restart ssh || systemctl restart sshd || service ssh restart || service sshd restart
echo "♻️ sshd restarted"

# Detect external IP
IP=$(curl -fs -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || curl -fs ifconfig.me 2>/dev/null || echo "UNKNOWN")

# Persist PUBLIC_IP env
if [[ -n "$IP" && "$IP" != "UNKNOWN" ]]; then
  echo "export PUBLIC_IP=${IP}" | tee /etc/profile.d/publicip.sh >/dev/null
  chmod +x /etc/profile.d/publicip.sh
fi

echo
echo "────────────────────────────────────"
echo "✅ Root login enabled"
echo "ROOT_PASSWORD = ${ROOT_PASS}"
echo "PUBLIC_IP = ${IP}"
echo
echo "Test from your PC:"
echo "ssh root@${IP} -o PreferredAuthentications=password -o PubkeyAuthentication=no"
echo "────────────────────────────────────"
