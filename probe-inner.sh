#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
echo "== k3s state:"
ls /etc/rancher/k3s/ 2>/dev/null
systemctl is-active k3s k3s-agent 2>/dev/null
echo "== who listens on 443:"
ss -tlnp | grep -E ":443|6666|5555|16000" 
echo "== api version local:"
curl -sk --max-time 5 https://127.0.0.1:443/version 2>&1 | head -3
curl -sk --max-time 5 -o /dev/null -w "tailnet-IP:%{http_code}\n" https://100.87.19.118:443/version 2>&1
echo "== kubectl nodes:"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes -o wide 2>&1 | head -15
echo "== server token hash:"
T=$(cat /var/lib/rancher/k3s/server/token 2>/dev/null)
echo "len=${#T} sha16=$(printf %s "$T" | sha256sum | cut -c1-16)"
echo "== k3s.yaml hash:"
sha256sum /etc/rancher/k3s/k3s.yaml 2>/dev/null | cut -c1-16
EOS
' 2>&1 | head -50
echo "== t-done =="
