hostname; id; date -u
echo "=== /root/snoop listing ==="
ls -la /root/snoop/ 2>&1
echo "=== dh-hits.log ==="
cat /root/snoop/dh-hits.log 2>&1
echo "=== hits.log tail ==="
tail -50 /root/snoop/hits.log 2>&1
echo "=== docker-inspects tail ==="
tail -20 /root/snoop/docker-inspects.jsonl 2>&1
echo "=== caddywatch alerts ==="
cat /root/caddywatch.alerts 2>&1
echo "=== roguerunner alerts ==="
cat /tmp/roguerunner/hits/ALERTS.log 2>&1
echo "=== ssh keys present ==="
ls -la /root/.ssh/ /home/ubuntu/.ssh/ 2>&1
echo "=== .62 reachability ==="
for K in /root/.ssh/id_ed25519 /root/.ssh/id_rsa /home/ubuntu/.ssh/id_ed25519; do
  [ -f "$K" ] || continue
  echo "--- trying $K ---"
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=6 -i "$K" dev-24-sudo@85.234.79.62 'echo IN; hostname' 2>&1 | head -3
done
echo "=== .62 sesswatch (if reachable via any key above) ==="
for K in /root/.ssh/id_ed25519 /root/.ssh/id_rsa /home/ubuntu/.ssh/id_ed25519; do
  [ -f "$K" ] || continue
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=6 -i "$K" dev-24-sudo@85.234.79.62 'sudo tail -100 /tmp/.sesswatch/hits 2>/dev/null; echo ---AUTH---; sudo tail -40 /var/log/auth.log 2>/dev/null' 2>&1 | head -120 && break
done
