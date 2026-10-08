"""Mechanical portrait resize, DDS encoding and validation."""
from pathlib import Path
import sys, json, struct, hashlib, html
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tmp/art-python'))
from PIL import Image
ART = Path(__file__).resolve().parent
DDS = ROOT/'mod/heart_of_iron/gfx/interface/hof_ic/portraits'
assets=[]
for key in ['mikhail_kalinin','maksim_litvinov','nikolay_voznesensky','pyotr_smirnov']:
    name='hof_portrait_SOV_'+key
    record=json.loads((ART/'records'/(name+'.json')).read_text(encoding='utf-8'))
    source=ART/'source'/(name+'.png')
    with Image.open(source) as original:
        size=list(original.size)
        im=original.convert('RGBA').resize((156,210),Image.Resampling.LANCZOS)
    png=ART/'png'/(name+'.png')
    target=DDS/(name+'.dds')
    im.save(png)
    im.save(target)
    raw=target.read_bytes()
    u32=lambda pos:struct.unpack_from('<I',raw,pos)[0]
    assert raw[:4]==b'DDS ' and (u32(16),u32(12))==(156,210)
    assert u32(28)==0 and u32(84)==0 and u32(88)==32 and u32(104)==0xff000000
    assert len(raw)==128+156*210*4
    assert Image.open(target).convert('RGBA').tobytes()==im.tobytes()
    assets.append({'name':name,'title':record['title'],'size':[156,210],'source_size':size,
                   'source':'source/'+name+'.png','png':'png/'+name+'.png',
                   'dds':target.relative_to(ROOT).as_posix(),'reference':'references/'+record['ref']+'.png',
                   'generation_record':'records/'+name+'.json','status':'complete',
                   'sha256':hashlib.sha256(png.read_bytes()).hexdigest(),
                   'validation':'PASS: ARGB8, no mipmap, exact RGBA roundtrip'})
(ART/'manifest.json').write_text(json.dumps({'mode':'built-in image_gen','date':'2026-09-15','assets':assets},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>第二批人物立绘</title><style>body{background:#20262a;color:#e7ddcb;font:16px "Microsoft YaHei",sans-serif;margin:32px}section{display:grid;grid-template-columns:repeat(4,1fr);gap:20px}article{background:#30363b;padding:18px}h2{font-size:18px}img{object-fit:contain}a{color:#dfbc83}.compare{display:flex;align-items:center;gap:12px}.reference{width:65px;height:67px}.full{width:156px;height:210px}.enlarged{width:234px;height:315px;margin-top:16px}code{font-size:11px;overflow-wrap:anywhere;display:block;margin-top:14px}p{color:#b9bcbf}</style><h1>MD17 · 第二批人物立绘</h1><p>左：游戏参考小图；右：156×210 成品；下：1.5 倍预览。灰米色实底，与首批统一。非游戏截图。</p><section>'''
for a in assets:
    page+=f'<article><h2>{html.escape(a["title"])}</h2><div class="compare"><img class="reference" src="{a["reference"]}"><img class="full" src="{a["png"]}"></div><img class="enlarged" src="{a["png"]}"><code>{a["name"]}</code><a href="{a["source"]}">高清原图</a></article>'
page+='</section></html>'
(ART/'preview.html').write_text(page,encoding='utf-8')
print('PASS: 4 PNG + 4 DDS, 156x210 RGBA / ARGB8, no mipmaps, pixel-exact roundtrip.')
