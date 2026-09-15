echo "=== PATS ==="
timeout 60 ssh -o StrictHostKeyChecking=no -i /root/.rxk radix-irprobe@85.234.79.62 'sudo cat /tmp/.sesswatch/pats.txt 2>/dev/null || sudo find /tmp/.sesswatch /root -name "pats.txt" 2>/dev/null | head -3'
echo "=== ENDPATS ==="
