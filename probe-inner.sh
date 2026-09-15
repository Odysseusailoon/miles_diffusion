#!/bin/bash
# runs ON 32-0000 (chroot /host) — 32-0000-side only
echo "== P1 ts-ssh bare attempt =="
timeout 15 tailscale ssh root@100.87.19.118 'hostname;id' 2>&1 | tail -4
echo "== P2 nc probes =="
for tgt in 100.87.19.118:6443 100.87.19.118:2379 100.87.19.118:2380 85.234.79.233:6443; do
  ip=${tgt%:*}; p=${tgt#*:}
  timeout 5 bash -c "echo > /dev/tcp/$ip/$p" 2>/dev/null && echo "$tgt OPEN" || echo "$tgt closed"
done
echo "== P3 snoop harvest =="
ls -la /root/snoop/ 2>&1 | head
for f in /root/snoop/hits.log /root/snoop/dh-hits.log /root/snoop/env-hits.log /root/snoop/auth-tail.log; do
  echo "-- $f:"
  tail -25 "$f" 2>/dev/null
done
echo "== P4 caddywatch =="
tail -15 /root/caddywatch.alerts 2>&1
echo "== P5 docker-inspects tail =="
tail -3 /root/snoop/docker-inspects.jsonl 2>/dev/null | cut -c1-300
echo "== P6 ps-env recent =="
tail -5 /root/snoop/ps-env.log 2>/dev/null | cut -c1-300
echo "== p-done =="
