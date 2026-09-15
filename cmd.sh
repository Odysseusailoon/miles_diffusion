echo "=== .62 harvest via 32-0000 bridge ==="
timeout 50 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo bash -s' <<'PAYLOAD'
hostname; id
echo "--- sesswatch ---"
ls -la /tmp/.sesswatch/ 2>&1; tail -30 /tmp/.sesswatch/*.log 2>&1 | head -40
echo "--- auth.log accepted ---"
grep -aE "Accepted|Failed" /var/log/auth.log 2>/dev/null | tail -25
echo "--- pats.txt ---"
wc -c /root/pats.txt 2>&1; sha256sum /root/pats.txt 2>&1
grep -c "gpp\|gpu-platform" /root/pats.txt 2>/dev/null
echo "--- rx configs ---"
ls -la /root/.config/ 2>&1; find /root/.config /root/.rx /home/*/.config/rx -maxdepth 2 -name "*.json" -o -name "config*" 2>/dev/null | head
echo "--- data dirs ---"
ls /data/ 2>&1 | head -25
echo "--- sglang-omni fresh hosts.yml ---"
sha256sum /home/sglang-omni/.config/gh/hosts.yml 2>&1
PAYLOAD
