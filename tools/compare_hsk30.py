import csv, json, sys, collections
rows=list(csv.DictReader(open(sys.argv[1],encoding='utf8')))
off=collections.defaultdict(set)
for r in rows:
    for w in r['Simplified'].split('|'):
        off[r['Level']].add(w)
print({k:len(v) for k,v in off.items()})
mine=json.load(open(sys.argv[2],encoding='utf8'))
lvl=lambda p: p.get('hsk') or (int(p['topic'][4]) if p['topic'].startswith('HSK ') and p['topic'][4].isdigit() else None)
def key(p):
    t=p['topic']
    if t=='HSK 7-9': return '7-9'
    l=lvl(p); return str(l) if l else None
by=collections.defaultdict(set)
for p in mine:
    k=key(p)
    if k: by[k].add(p['hanzi'])
allmine={p['hanzi'] for p in mine}
for k in ['1','2','3','4','5','6','7-9']:
    o=off[k]; m=by[k]
    print(k,'official',len(o),'mine',len(m),'match',len(o&m),'missing-in-level',len(o-m),
          '(not present anywhere:',len(o-allmine),') extra',len(m-o))
miss=sorted(off['1']-allmine)
print('HSK1 missing anywhere:',miss)
# words in wrong level
off_lvl={w:k for k,v in off.items() for w in v}
wrong=collections.Counter((key(p),off_lvl[p['hanzi']]) for p in mine if key(p) and p['hanzi'] in off_lvl and off_lvl[p['hanzi']]!=key(p))
print('mismatched level (mine, official):',wrong.most_common(12))
