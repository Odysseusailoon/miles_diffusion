echo "=== clusterd env ==="
cat /etc/clusterd* 2>/dev/null | head -40
ls /etc/clusterd/ 2>/dev/null
cat /etc/clusterd/env 2>/dev/null | head -40
echo "=== k3s agent env ==="
cat /etc/systemd/system/k3s-agent.service.env 2>/dev/null
cat /etc/systemd/system/k3s*.env 2>/dev/null | head -20
systemctl cat k3s-agent 2>/dev/null | grep -i -A2 -B2 token | head -20
echo "=== B26DONE ==="
