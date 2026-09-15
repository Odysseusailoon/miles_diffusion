echo "=== 221 k3s pull ==="
cat > /tmp/r2.sh <<'RSH'
#!/bin/bash
echo "=== k3s.yaml ==="
sudo cat /etc/rancher/k3s/k3s.yaml 2>&1 | head -30
echo "=== kubectl nodes ==="
sudo k3s kubectl get nodes -o wide 2>&1 | head -20
echo "=== node-ip mapping ==="
sudo k3s kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses}{"\n"}{end}' 2>&1 | head -15
echo "=== kubelet probes ==="
for ip in 31 87 103 109 184 233; do
  code=$(curl -sk --max-time 4 "https://85.234.79.$ip:10250/pods" -o /tmp/kp-$ip -w "%{http_code}")
  echo "  85.234.79.$ip:10250/pods -> $code ($(wc -c < /tmp/kp-$ip 2>/dev/null)B)"
  code2=$(curl -s --max-time 4 "http://85.234.79.$ip:10255/pods" -o /dev/null -w "%{http_code}")
  echo "  85.234.79.$ip:10255/pods -> $code2"
done
echo "=== tailscale ==="
sudo tailscale status 2>&1 | head -12
echo "=== ss ==="
sudo ss -tlnp 2>/dev/null | grep -vE "10\.42\.|127\.0\.0" | head -20
echo "=== docker ps ==="
sudo docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | head -15
echo "=== homes ==="; ls /home/
RSH
chmod +x /tmp/r2.sh
timeout 110 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r2.sh 2>&1 | head -120
echo "=== B17DONE ==="
