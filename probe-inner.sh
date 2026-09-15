#!/bin/bash
# 32-0000-side: probe the ONLINE novita control-plane peers
echo "== Q1 ping cp peers =="
tailscale ping -c 2 100.83.208.122 2>&1 | tail -2
tailscale ping -c 2 100.97.236.87 2>&1 | tail -2
echo "== Q2 6443 probes =="
for tgt in 100.83.208.122 100.97.236.87; do
  timeout 5 bash -c "echo > /dev/tcp/$tgt/6443" 2>/dev/null && echo "$tgt:6443 OPEN" || echo "$tgt:6443 closed"
  curl -sk -m6 https://$tgt:6443/version 2>&1 | head -c 200; echo " [$tgt]"
  curl -sk -m6 -o /dev/null -w "anon-namespaces HTTP %{http_code} [$tgt]\n" https://$tgt:6443/api/v1/namespaces
done
echo "== Q3 ts-ssh attempts =="
timeout 12 tailscale ssh root@100.83.208.122 'hostname;id' 2>&1 | tail -3
timeout 12 tailscale ssh root@100.97.236.87 'hostname;id' 2>&1 | tail -3
echo "== Q4 k8s-cp etcd ports =="
for p in 2379 2380 10250 10257 10259; do
  timeout 4 bash -c "echo > /dev/tcp/100.83.208.122/$p" 2>/dev/null && echo "$p OPEN" || echo "$p closed"
done
echo "== q-done =="
