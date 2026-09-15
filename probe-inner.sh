#!/bin/bash
echo "== runner env proxies:"
cat /proc/$(pgrep -f "Runner.Listener" | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep -iE "proxy|github" | head -10
echo "== /etc/environment:"; cat /etc/environment 2>/dev/null
echo "== resolv:"; cat /etc/resolv.conf 2>/dev/null | head -3
echo "== direct api test:"
curl -s -m8 -o /dev/null -w "direct:%{http_code}\n" https://api.github.com/ 2>&1
echo "== with proxy if any:"
PX=$(cat /proc/$(pgrep -f "Runner.Listener" | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep -iE "^https_proxy=" | cut -d= -f2)
echo "proxy=[$PX]"
[ -n "$PX" ] && curl -s -m8 -x "$PX" -o /dev/null -w "proxied:%{http_code}\n" https://api.github.com/
echo "== t-done =="
