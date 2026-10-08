"""Mechanical resize/export and DDS round-trip validation; no art generation."""
from pathlib import Path
import sys, json, struct, hashlib, html

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image

ART = ROOT / 'art/focus'
DDS = ROOT / 'mod/heart_of_iron/gfx/interface/hof_ic/focus'
DDS.mkdir(parents=True, exist_ok=True)
manifest = json.loads((ART / 'manifest.json').read_text(encoding='utf-8'))
assets = manifest['assets']
assert assets and len(assets) == len({a['id'] for a in assets})
for a in assets:
    assert (ART / a['source']).is_file(), a['name']

checks = []
for a in assets:
    name = a['name']
    source = ART / a['source']
    with Image.open(source) as im:
        original_size = list(im.size)
        resized = im.convert('RGBA').resize((100, 88), Image.Resampling.LANCZOS)
    alpha = resized.getchannel('A')
    hist = alpha.histogram()
    assert alpha.getextrema() == (0, 255), name
    assert hist[0] > 880 and sum(hist[250:]) > 1760, name
    assert 0.20 <= sum(hist[:10]) / 8800 <= 0.50, name
    assert all(alpha.getpixel(p) == 0 for p in [(0,0),(99,0),(0,87),(99,87)]), name
    png = ART / a.get('png', name + '.png')
    png.parent.mkdir(parents=True, exist_ok=True)
    dds = DDS / (name + '.dds')
    resized.save(png)
    resized.save(dds)
    data = dds.read_bytes()
    u32 = lambda pos: struct.unpack_from('<I', data, pos)[0]
    assert data[:4] == b'DDS ' and u32(4) == 124
    assert (u32(16), u32(12)) == (100, 88)
    assert u32(28) == 0 and u32(84) == 0 and u32(88) == 32
    assert u32(104) == 0xff000000 and len(data) == 128 + 100 * 88 * 4
    with Image.open(dds) as decoded:
        assert decoded.convert('RGBA').tobytes() == resized.tobytes()
    record = ART / a['generation_record']
    a.update(status='complete', source=source.relative_to(ART).as_posix(), source_size=original_size,
             png=png.relative_to(ART).as_posix(), dds=dds.relative_to(ROOT).as_posix(),
             generation_record=record.relative_to(ART).as_posix(),
             sha256=hashlib.sha256(png.read_bytes()).hexdigest())
    checks.append({'name':name, 'size':[100,88], 'dds_format':'ARGB8 uncompressed',
                   'mipmaps':0, 'dds_bytes':len(data), 'pixel_roundtrip':'PASS',
                   'transparent_pixels':hist[0], 'opaque_pixels':hist[255],
                   'alpha_at_least_250_pixels':sum(hist[250:]),
                   'partial_alpha_pixels':sum(hist[1:255]), 'corner_alpha':'all zero'})

manifest.update(completed='2026-09-24', count=len(assets), background='transparent', integration='art textures delivered; no script edits')
(ART / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(ART / 'validation.json').write_text(json.dumps({'result':'PASS','count':len(assets),'assets':checks},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

parts = ['''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>MD24 国策图标总览</title>
<style>*{box-sizing:border-box}body{margin:0;padding:30px;background:#14181c;color:#e4d9c3;font:15px "Microsoft YaHei",sans-serif}h1{margin:0 0 10px;font-size:28px}p{color:#aeb3b8}h2{border-bottom:1px solid #66583c;padding-bottom:10px;font-size:20px}section{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}article{background:#20262c;padding:14px;border:1px solid #3a4247;min-width:0}h3{font-size:16px;margin:0 0 10px}.images{height:185px;display:flex;gap:12px;align-items:center;justify-content:center}.native{width:100px;height:88px}.large{width:200px;height:176px}code{display:block;overflow-wrap:anywhere;font-size:11px;color:#9aa5ac;margin-top:10px}a{color:#d2b47a}label{display:inline-block;margin-right:20px}body.native-only .large{display:none}</style>
<style>.images{background:var(--sample,#b9c0c7)}select{padding:5px;margin:8px}</style>
<h1>核心圈 · 透明国策图标</h1><p>左：100×88 实际尺寸，右：2 倍预览。背景由网页绘制，图片本身透明。非游戏截图。</p>
<label>检查背景<select onchange="document.documentElement.style.setProperty('--sample',this.value)"><option value="#b9c0c7">浅灰</option><option value="#20262c">深灰</option><option value="#fff">纯白</option><option value="#756543">地图棕</option></select></label>
<label><input type="checkbox" onchange="document.body.classList.toggle('native-only',this.checked)">只看实际尺寸</label><a href="manifest.json">文件清单</a>
''']
for group, title in [('finale','最高苏维埃终局'),('entry','人物入口'),('trotsky','托洛茨基专属'),('bukharin','布哈林专属'),('rykov','李可夫专属'),('zinovyev','季诺维也夫专属'),('kamenev','加米涅夫专属'),('smirnov','斯米尔诺夫专属'),('serebryakov','谢列布里亚科夫专属'),('preobrazhensky','普列奥布拉任斯基专属'),('radek','拉狄克专属'),('smilga','斯米尔加专属'),('tomsky','托姆斯基专属'),('ryutin','里亚京专属'),('shlyapnikov','施利亚普尼科夫专属'),('kalinin','加里宁专属'),('litvinov','李维诺夫专属'),('sokolnikov','索柯里尼柯夫专属'),('tukhachevsky','图哈切夫斯基专属'),('voznesensky','沃兹涅先斯基专属'),('pyotr_smirnov','彼得·斯米尔诺夫专属'),('malenkow','马林科夫专属'),('khrushchev','赫鲁晓夫专属'),('voroshilov','伏罗希洛夫专属')]:
    parts.append('<h2>' + title + '</h2><section>')
    for a in assets:
        if a['group'] != group: continue
        name = a['name']
        parts.append(f'<article><h3>{html.escape(a["title"])}</h3><div class="images"><img class="native" src="{a["png"]}"><img class="large" src="{a["png"]}"></div><code>{name}</code><a href="{a["source"]}">高清原图</a></article>')
    parts.append('</section>')
parts.append('</html>')
(ART / 'preview.html').write_text(''.join(parts),encoding='utf-8')
print(f'PASS: {len(assets)} PNG + {len(assets)} DDS; 100x88, ARGB8, no mipmaps, exact RGBA round trip; transparency 20-50%.')
