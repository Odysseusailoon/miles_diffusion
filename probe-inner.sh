#!/bin/bash
chmod 600 /root/keys/rxprobe 2>/dev/null
for ip in 47.74.68.185 47.74.115.221; do
  echo "=== $ip ==="
  ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/keys/rxprobe root@$ip '
hostname
echo "-- k3s env:"
grep -E "K3S_URL" /etc/systemd/system/k3s-agent.service.env 2>/dev/null
T=$(grep K3S_TOKEN /etc/systemd/system/k3s-agent.service.env 2>/dev/null | awk -F"'" "{print \$2}")
echo "K3S_TOKEN sha16=$(printf %s "$T" | sha256sum | cut -c1-16) len=${#T}"
systemctl is-active k3s-agent k3s 2>&1 | head -2
echo "-- clusterd:"
ls /etc/clusterd/ 2>/dev/null
CT=$(grep -oE "CLUSTERD_INSTALL_TOKEN=.*" /etc/clusterd/env 2>/dev/null | cut -d= -f2)
echo "CLUSTERD_TOKEN sha16=$(printf %s "$CT" | sha256sum | cut -c1-16) len=${#CT}"
' 2>&1 | head -14
done
echo "== t-done =="
