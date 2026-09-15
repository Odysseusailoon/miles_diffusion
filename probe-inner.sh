#!/bin/bash
echo "== R1 inspects cred mining (hash-only) =="
python3 - <<'PY'
import json,hashlib,re
pats=re.compile(r'(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|ghs_[A-Za-z0-9]{20,}|dckr_pat_[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|tskey-[a-z]+-[A-Za-z0-9_-]{10,}|xox[bpars]-[A-Za-z0-9-]{10,})')
kw=re.compile(r'TOKEN|SECRET|PASSWORD|AUTH|APIKEY|API_KEY|PRIVATE',re.I)
seen=set()
hits=0
for line in open('/root/snoop/docker-inspects.jsonl','rb'):
    try: d=json.loads(line)
    except: continue
    env=[]
    cfg=(d[0] if isinstance(d,list) and d else d).get('Config',{}) if isinstance(d,(list,dict)) else {}
    if isinstance(d,list) and d: env=d[0].get('Config',{}).get('Env') or []
    elif isinstance(d,dict): env=d.get('Config',{}).get('Env') or []
    for e in env:
        k,_,v=e.partition('=')
        if not v: continue
        m=pats.search(v)
        if m or (kw.search(k) and len(v)>12):
            h=hashlib.sha256(v.encode()).hexdigest()[:16]
            if h in seen: continue
            seen.add(h); hits+=1
            tag='PATTERN' if m else 'keyword'
            print(f"{tag} key={k[:40]} sha16={h} len={len(v)}")
    if hits>60: break
print(f"total unique hits={hits}")
PY
echo "== R2 caddywatch =="
pgrep -f caddywatch && echo ALIVE || echo DEAD
ls -la /root/caddywatch* 2>&1 | head -5
echo "== r-done =="
