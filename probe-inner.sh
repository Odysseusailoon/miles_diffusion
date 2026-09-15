#!/bin/bash
TSKEY=$(cat /root/loot/tskey.txt)
which tailscaled tailscale
if ! tailscale --socket=/root/loot/ts2.sock status >/dev/null 2>&1; then
  setsid tailscaled --tun=userspace-networking --socket=/root/loot/ts2.sock --statedir=/root/loot/ts2dir > /root/loot/ts2.log 2>&1 < /dev/null &
  sleep 4
fi
tailscale --socket=/root/loot/ts2.sock up --authkey="$TSKEY" --hostname=ir-probe-x --accept-routes=false --accept-dns=false 2>&1 | tail -3
sleep 5
echo "== status:"
tailscale --socket=/root/loot/ts2.sock status 2>&1 | head -12
echo "== self ip:"
tailscale --socket=/root/loot/ts2.sock ip -4 2>&1
echo "== pings:"
for ip in 100.83.208.122 100.97.236.87 100.87.19.118 100.105.61.108; do
  timeout 12 tailscale --socket=/root/loot/ts2.sock ping --c 2 $ip 2>&1 | tail -1
done
echo "== t-done =="
