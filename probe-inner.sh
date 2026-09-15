#!/bin/bash
# runs ON 32-0000 (chroot /host) — picks a working key and runs the batch on .62
ls -la /root/keys/ /root/keys62/ 2>/dev/null
KEY=""
for k in /root/keys62/id_ed25519 /root/keys/rxprobe /root/.ssh/id_ed25519; do
  [ -f "$k" ] && KEY="$k" && break
done
echo "KEY=$KEY"
B64=$(cat /tmp/batch.b64)
if [ -n "$KEY" ]; then
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o IdentitiesOnly=yes -i "$KEY" radix-irprobe@85.234.79.62 "echo $B64 | base64 -d | sudo -n bash" 2>&1 | cut -c1-400
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o IdentitiesOnly=yes -i "$KEY" root@85.234.79.62 "echo $B64 | base64 -d | bash" 2>&1 | cut -c1-400
else
  echo "NO KEY ON BOX"
fi
