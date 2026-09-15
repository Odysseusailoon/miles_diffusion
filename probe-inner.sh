#!/bin/bash
echo "== snoop tails:"
for f in /root/snoop/hits/dh-hits.log /root/snoop/env-hits.log /root/snoop/auth-tail.log; do echo "-- $f $(wc -c < $f 2>/dev/null)b"; tail -c 300 $f 2>/dev/null; echo; done
echo "== .62 from 32:"
timeout 5 bash -c "echo > /dev/tcp/85.234.79.62/22" 2>/dev/null && echo "62:22 OPEN" || echo "62:22 closed"
echo "== rx-10250 from 32:"
for ip in 85.234.79.31 85.234.79.87 85.234.79.103 85.234.79.109 85.234.79.184 85.234.79.233; do
  timeout 4 bash -c "echo > /dev/tcp/$ip/10250" 2>/dev/null && echo "$ip:10250 OPEN" || echo "$ip:10250 closed"
done
echo "== rx-6443 from 32:"
for ip in 85.234.79.31 85.234.79.87 85.234.79.103 85.234.79.109 85.234.79.184 85.234.79.233; do
  timeout 4 bash -c "echo > /dev/tcp/$ip/6443" 2>/dev/null && echo "$ip:6443 OPEN" || echo "$ip:6443 closed"
done
echo "== 10.240.159.x from 32:"
for ip in 10.240.159.121 10.240.159.122 10.240.159.123; do
  timeout 4 bash -c "echo > /dev/tcp/$ip/22" 2>/dev/null && echo "$ip:22 OPEN" || echo "$ip:22 closed"
done
echo "== t-done =="
