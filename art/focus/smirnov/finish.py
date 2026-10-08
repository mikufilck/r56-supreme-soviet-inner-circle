"""Install MD40 through the shared exporter and prepare batch preview."""
from pathlib import Path
import sys,json,runpy,hashlib,re,contextlib
B=Path(__file__).resolve().parent
ART=B.parent
ROOT=ART.parents[1]
sys.path.insert(0,str(ROOT/'tmp/art-python'))
from PIL import Image
plan=json.loads((B/'plan.json').read_text(encoding='utf-8'))
expected=set(re.findall(r'`(GFX_hof_ic_smirnov_\w+)`',(ROOT/'docs/40-smirnov-focus-icon-prompts.md').read_text(encoding='utf-8-sig')))
assert expected=={a['name'] for a in plan} and len(plan)==6
manifest=json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
old=json.loads((B/'previous-manifest.json').read_text(encoding='utf-8'))
for a in plan:
    im=Image.open(B/'source'/f'{a["name"]}.png')
    assert im.mode=='RGBA',a['name']
    alpha=im.resize((100,88),Image.Resampling.LANCZOS).getchannel('A')
    assert .2<=sum(alpha.histogram()[:10])/8800<=.5,a['name']
    if not any(x['name']==a['name'] for x in manifest['assets']):
        manifest['assets'].append({**a,'png':f'smirnov/{a["name"]}.png','source':f'smirnov/source/{a["name"]}.png','generation_record':f'smirnov/records/{a["name"]}.json'})
(ART/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
runpy.run_path(str(ART/'export_focus.py'),run_name='__main__')
for a in old['assets']:
    assert hashlib.sha256((ART/a['png']).read_bytes()).hexdigest()==a['sha256'],a['name']
with (B/'check-alpha-report.txt').open('w',encoding='utf-8') as f:
    with contextlib.redirect_stdout(f):
        runpy.run_path(str(ART/'check_alpha.py'),run_name='__main__')
preview=(ART/'preview.html').read_text(encoding='utf-8')
head=preview[:preview.index('<h2>')].replace('核心圈 · 透明国策图标','MD40 · 斯米尔诺夫个人线').replace('href="manifest.json"','href="../manifest.json"')
cards=[]
for a in plan:
    card=next(c for c in re.findall(r'<article>.*?</article>',preview) if f'<code>{a["name"]}</code>' in c)
    cards.append(card.replace('src="','src="../').replace('href="','href="../'))
(B/'preview.html').write_text(head+'<h2>桥 · 队伍 · 政权 · 国界 · 邮电网 · 雪原</h2><section>'+''.join(cards)+'</section></html>',encoding='utf-8')
print(f'PASS: 6 MD40 icons; previous {len(old["assets"])} PNG hashes unchanged.')
