#!/bin/bash
sed -i "s/sleep 30/sleep 5/" /root/snoop/tokgrab.sh
pkill -f tokgrab.sh; sleep 1
setsid /root/snoop/tokgrab.sh > /root/snoop/tokgrab.err 2>&1 < /dev/null &
sleep 1
pgrep -f tokgrab.sh && echo GRABBER-5S-ALIVE
echo "== t-done =="
