#!/bin/bash
chmod 600 /root/.rxk 2>/dev/null
RK=/root/.rxk
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -i $RK radix-irprobe@85.234.79.62 '
echo "== ts32 status:"
sudo tailscale --socket=/var/run/tailscale/tailscaled.sock status 2>/dev/null | head -3 || sudo /root/ts32/tailscale --socket=/root/ts32/tailscaled.sock status 2>/dev/null | head -3
echo "== healthz:"
curl -s --max-time 10 http://ci-monitor-1.tail134ba0.ts.net/healthz; echo
echo "== disk oracle on rx .233 (root via dashboard key):"
curl -s --max-time 30 "http://ci-monitor-1.tail134ba0.ts.net/api/runner/disk?runner=h100-novita-temp"; echo
' 2>&1 | head -40
echo "== t-done =="
