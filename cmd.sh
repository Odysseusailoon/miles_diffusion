echo "=== snoop dir on .62 ==="
ssh -i /root/.rxk -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 radix-irprobe@85.234.79.62 'sudo -n ls -la /root/snoop/ 2>&1 | head -40; echo ---; sudo -n sh -c "for f in /root/snoop/tg_*.json; do [ -f \"\$f\" ] && echo \"== \$f ==\" && head -c 400 \"\$f\"; echo; done" 2>&1 | head -60'
echo "=== B25DONE ==="
