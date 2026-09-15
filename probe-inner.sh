#!/bin/bash
echo "== hits.log:"; cat /root/snoop/hits.log 2>/dev/null
python3 - <<'PY'
import hashlib,re
data=open("/root/snoop/ps-env.log",errors="replace").read()
seen=set();n=0
pats={
 "vault":re.compile(r"hvs\.[A-Za-z0-9_-]{20,}"),
 "rancher":re.compile(r"token-[a-z0-9]{4,}:[a-z0-9]{20,}"),
 "radix":re.compile(r"(?i)(?:radix|rx)[_-]?(?:tok|token|key)[_-]?[A-Za-z0-9]{0,4}=([A-Za-z0-9_-]{20,})"),
 "privkey":re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
 "bearer":re.compile(r"(?i)bearer ([A-Za-z0-9._-]{24,})"),
 "basic":re.compile(r"(?i)authorization[^=]*=.{0,20}basic ([A-Za-z0-9+/=]{16,})"),
 "generic":re.compile(r"(?i)([A-Z0-9_]{3,30}(?:TOKEN|SECRET|PASSWD|PASSWORD|APIKEY|API_KEY|PRIVATE_KEY|AUTH_KEY))=([^\s\x00]{16,200})"),
}
for name,p in pats.items():
    for m in p.finditer(data):
        v=m.group(1) if m.lastindex else m.group(0)
        if name=="generic":
            k=m.group(1); v=m.group(2)
            if k in ("GITHUB_TOKEN","ACTIONS_RUNTIME_TOKEN","ACTIONS_ID_TOKEN_REQUEST_TOKEN","VIRTUAL_ENV","HOSTNAME"): continue
        h=hashlib.sha256(v.encode()).hexdigest()[:16]
        if h in seen: continue
        seen.add(h);n+=1
        lbl=(name+":"+ (m.group(1) if name=="generic" else ""))[:44]
        print(f"{lbl} sha16={h} len={len(v)}")
print("total:",n)
PY
echo "== t-done =="
