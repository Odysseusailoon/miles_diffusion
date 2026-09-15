timeout 240 ssh -i /root/.rxk -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 radix-irprobe@85.234.79.62 'sudo -n sh -s' <<'REOF' 2>&1 | head -300
echo "--- uuid histogram top20 ---"
grep -hoE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' /tmp/.sniff-*.log 2>/dev/null | sort | uniq -c | sort -rn | head -20
TOP3=$(grep -hoE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' /tmp/.sniff-*.log 2>/dev/null | sort | uniq -c | sort -rn | head -3 | awk '{print $2}')
i=0
for u in $TOP3; do
  i=$((i+1))
  echo "--- uuid#$i $u context ---"
  grep -h -C4 "$u" /tmp/.sniff-*.log 2>/dev/null | head -60
done
echo "--- root ssh dir ---"
ls -la /root/.ssh/ 2>&1
stat -c '%n mtime:%y' /root/.ssh/authorized_keys 2>/dev/null
stat -c '%n mtime:%y' /home/radix-irprobe/.ssh/authorized_keys 2>/dev/null
stat -c '%n mtime:%y' /home/dev-24-sudo/.ssh/authorized_keys 2>/dev/null
REOF
echo "=== B28DONE ==="
