echo "=== 221 cert issuer ==="
cat > /tmp/r4.sh <<'RSH'
#!/bin/bash
echo "=== kubelet crt issuer ==="
sudo openssl x509 -in /var/lib/rancher/k3s/agent/client-kubelet.crt -noout -issuer -subject -serial -dates 2>&1
echo "=== all agent certs issuers ==="
for c in /var/lib/rancher/k3s/agent/*.crt /var/lib/rancher/k3s/server/tls/*.crt; do
  [ -f "$c" ] && echo "-- $c --" && sudo openssl x509 -in "$c" -noout -issuer -subject 2>&1 | head -3
done 2>/dev/null | head -40
echo "=== agent env ==="
sudo cat /etc/systemd/system/k3s-agent.service.d/*.conf 2>/dev/null | head -10
sudo cat /proc/$(pgrep -f "k3s agent" | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep -E "K3S|TOKEN" | sed 's/=.*TOKEN.*/=<redacted-len>/' | head -8
RSH
chmod +x /tmp/r4.sh
timeout 90 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r4.sh 2>&1 | head -60
echo "=== oracle via tsclone on .62 ==="
timeout 110 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo bash -s' <<'PAYLOAD'
CMIP=$(tailscale --socket=/root/tsclone/ts.sock status 2>/dev/null | grep -i "ci-monitor" | awk '{print $1}')
echo "ci-monitor-1 IP via tsclone: $CMIP"
tailscale --socket=/root/tsclone/ts.sock status 2>/dev/null | head -15
if [ -n "$CMIP" ]; then
  echo "-- control --"
  curl -s --max-time 25 "http://$CMIP/api/runner/disk?runner=h100-novita5-gpu" -w "\nHTTP:%{http_code}\n" | head -30
  echo "-- RX 233 --"
  curl -s --max-time 25 "http://$CMIP/api/runner/disk?runner=h100-novita-temp" -w "\nHTTP:%{http_code}\n" | head -50
  echo "-- https control --"
  curl -sk --max-time 25 "https://ci-monitor-1.tail134ba0.ts.net/api/runner/disk?runner=h100-novita5-gpu" --resolve "ci-monitor-1.tail134ba0.ts.net:443:$CMIP" -w "\nHTTP:%{http_code}\n" | head -30
fi
PAYLOAD
echo "=== B20DONE ==="
