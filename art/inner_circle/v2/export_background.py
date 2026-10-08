"""Resize the generated backplate and validate full coverage before replacement."""
from pathlib import Path
import sys, json, struct, shutil, hashlib
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tmp/art-python'))
from PIL import Image
ART = Path(__file__).resolve().parent
TARGET = ROOT / 'mod/heart_of_iron/gfx/interface/hof_ic/hof_ic_window_bg.dds'
others = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in TARGET.parent.glob('*.dds') if p != TARGET}
im = Image.open(ART / 'source/hof_ic_window_bg.png').convert('RGBA')
assert im.width == im.height
assert im.getchannel('A').getextrema() == (255,255), 'Generated panel must already be opaque'
im = im.resize((640,640), Image.Resampling.LANCZOS)
im.save(ART / 'hof_ic_window_bg.png')
im.save(ART / 'hof_ic_window_bg.dds')
raw = (ART / 'hof_ic_window_bg.dds').read_bytes()
u32 = lambda offset: struct.unpack_from('<I', raw, offset)[0]
assert raw[:4] == b'DDS ' and (u32(16),u32(12)) == (640,640)
assert u32(28) == 0 and u32(84) == 0 and u32(88) == 32 and u32(104) == 0xff000000
assert len(raw) == 128+640*640*4
assert Image.open(ART / 'hof_ic_window_bg.dds').convert('RGBA').tobytes() == im.tobytes()
backup = ART / 'previous-hof_ic_window_bg.dds'
if TARGET.exists() and not backup.exists(): shutil.copy2(TARGET,backup)
shutil.copy2(ART / 'hof_ic_window_bg.dds', TARGET)
assert all(hashlib.sha256(p.read_bytes()).hexdigest() == digest for p,digest in others.items())
report = {'result':'PASS','size':[640,640],'alpha_min':255,'alpha_max':255,
          'opaque_bounds':[0,0,640,640],'transparent_pixels':0,'four_edges':'fully opaque',
          'dds':'ARGB8, no mipmaps','roundtrip':'pixel exact','other_dds_unchanged':len(others),
          'installed':TARGET.relative_to(ROOT).as_posix()}
(ART / 'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
