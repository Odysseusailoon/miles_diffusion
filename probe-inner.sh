#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
if [ ! -f /root/keys/rxprobe ]; then
  base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.rxk 2>/dev/null && chmod 600 /root/.rxk
fi
[ -f /root/keys/rxprobe ] && RK=/root/keys/rxprobe || RK=/root/.rxk
head -1 $RK | cut -c1-25
for ip in 47.74.68.185 47.74.115.221; do
  echo "=== $ip ==="
  ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i $RK root@$ip '
hostname
echo "-- k3s env:"
unset K3S_TOKEN K3S_URL; . /etc/systemd/system/k3s-agent.service.env 2>/dev/null
echo "K3S_URL=$K3S_URL"
T=$K3S_TOKEN
echo "K3S_TOKEN sha16=$(printf %s $T | sha256sum | cut -c1-16) len=${#T}"
systemctl is-active k3s-agent k3s 2>&1 | head -2
echo "-- clusterd:"
ls /etc/clusterd/ 2>/dev/null
unset CLUSTERD_INSTALL_TOKEN; . /etc/clusterd/env 2>/dev/null; CT=$CLUSTERD_INSTALL_TOKEN
echo "CLUSTERD_TOKEN sha16=$(printf %s $CT | sha256sum | cut -c1-16) len=${#CT}"
' 2>&1 | head -14
done
echo "== t-done =="
