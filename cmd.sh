echo "=== beacon check ==="
timeout 20 ssh -p 2222 -i /root/.rxk -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 radix-irprobe@127.0.0.1 'hostname; sudo -n true && echo SUDO_OK || echo SUDO_GONE' 2>&1 | head -5
echo "=== direct .62 check ==="
timeout 20 ssh -i /root/.rxk -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 radix-irprobe@85.234.79.62 'hostname; sudo -n true && echo SUDO_OK || echo SUDO_GONE' 2>&1 | head -5
echo "=== local sshd on 2222? ==="
ss -tlnp | grep 2222
echo "=== B24DONE ==="
