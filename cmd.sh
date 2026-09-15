cd /tmp
echo "=== zcy key (so_rsa) repo read tests ==="
for repo in gpu-platform-proto keel rdxa-infra ci-monitor benchmark-infra miles-prod miles miles_diffusion sglang-omni gpu-cluster-setup b200-di; do
  r=$(GIT_SSH_COMMAND="ssh -i /tmp/irk_so_rsa -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8" timeout 15 git ls-remote git@github.com:radixark/$repo.git HEAD 2>&1 | head -1)
  echo "$repo => $r"
done
echo "=== lvy010 key (so_ed) spot tests ==="
for repo in gpu-platform-proto keel; do
  r=$(GIT_SSH_COMMAND="ssh -i /tmp/irk_so_ed -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8" timeout 15 git ls-remote git@github.com:radixark/$repo.git HEAD 2>&1 | head -1)
  echo "$repo => $r"
done
echo "=== PopSoda2002 key (sg_ed) spot tests ==="
for repo in gpu-platform-proto keel; do
  r=$(GIT_SSH_COMMAND="ssh -i /tmp/irk_sg_ed -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8" timeout 15 git ls-remote git@github.com:radixark/$repo.git HEAD 2>&1 | head -1)
  echo "$repo => $r"
done
