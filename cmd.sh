echo "=== .kube ==="
ls -laR /root/.kube/ 2>&1
for f in /root/.kube/config /root/.kube/*/*; do [ -f "$f" ] && echo "--- $f ---" && cat "$f"; done 2>&1 | head -120
echo "=== .rxk ==="
cat /root/.rxk 2>&1
echo "=== .config ==="
ls -laR /root/.config/ 2>&1 | head -30
echo "=== dxrg ==="
ls -la /root/dxrg/ 2>&1; cat /root/dxrg/* 2>&1 | head -20
echo "=== keys dirs ==="
ls -la /root/keys/ /root/keys62/ 2>&1
echo "=== bash_history ==="
tail -60 /root/.bash_history 2>&1
echo "=== tailscale rx-node IPs ==="
tailscale status 2>&1 | grep -E "novita|85-234" | head -20
