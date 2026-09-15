cd /tmp
echo "=== keys vs github.com ==="
for k in so_ed so_rsa ub_ed sg_ed; do
  r=$(timeout 12 ssh -i /tmp/irk_$k -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 -T git@github.com 2>&1 | head -1)
  echo "$k => $r"
done
