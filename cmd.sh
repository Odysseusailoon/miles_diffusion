echo "=== full tailscale status (novita/runner names) ==="
tailscale status 2>&1 | grep -iE "novita|runner|85-234|radixark" | head -30
echo "=== ssh .233 via tailnet (.rxk) ==="
for U in root ubuntu; do
  timeout 10 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=6 -i /root/.rxk $U@100.80.0.91 'echo BRIDGE-233; hostname; id' 2>&1 | head -4
done
echo "=== ssh k8s-cp-1 (.rxk) ==="
for U in root ubuntu; do
  timeout 10 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=6 -i /root/.rxk $U@100.83.208.122 'echo BRIDGE-CP1; hostname; id' 2>&1 | head -4
done
echo "=== ssh .62 via public IP from 32-0000 (.rxk) ==="
for U in root dev-24-sudo radix-irprobe; do
  timeout 10 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=6 -i /root/.rxk $U@85.234.79.62 'echo BRIDGE-62; hostname; id' 2>&1 | head -4
done
echo "=== tailscale ssh check on .233 ==="
timeout 12 tailscale ssh root@100.80.0.91 'echo TSSSH; hostname' 2>&1 | head -4
