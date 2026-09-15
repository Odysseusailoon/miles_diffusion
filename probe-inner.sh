#!/bin/bash
tail -10 /root/snoop/tokgrab.log 2>/dev/null
echo "---"
for f in /root/snoop/tg_repo_*.json; do
  [ -f "$f" ] || continue
  python3 -c "import json;d=json.load(open('$f'));print('$f'.split('tg_repo_')[1][:16],d.get('full_name'),d.get('permissions'),d.get('message'))" 2>/dev/null
done
for f in /root/snoop/tg_runners_*.json /root/snoop/tg_rrepo_*.json; do
  [ -f "$f" ] || continue
  python3 -c "
import json
d=json.load(open('$f'))
rs=d.get('runners') or []
print('$f'.split('/')[-1][:28], 'runners:', [(r.get('name'),r.get('os'),r.get('status'),[l['name'] for l in r.get('labels',[]) if l.get('type')=='custom']) for r in rs][:20])
" 2>/dev/null | head -3
done
echo "== t-done =="
