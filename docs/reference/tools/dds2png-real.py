import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

# DLC001 German Historical Portraits —— 真实生效的入口图标（后加载覆盖原版）
DLC = r"F:\Hearts of Iron IV\dlc\dlc001_german_historical_portraits\gfx\interface\goals"
BASE = r"F:\Hearts of Iron IV\gfx\interface\goals"

cands = []
for nm in ["todt", "speer", "goring", "himmler", "goebbels"]:
    cands.append(("asc_" + nm, os.path.join(DLC, "focus_GER_ascension_of_%s.dds" % nm),
                                 os.path.join(BASE, "focus_GER_ascension_of_%s.dds" % nm)))
for nm in ["hess", "bormann"]:
    cands.append(("pc_" + nm, os.path.join(DLC, "focus_GER_party_chancellor_%s.dds" % nm),
                             os.path.join(BASE, "focus_GER_party_chancellor_%s.dds" % nm)))
cands.append(("fp_todt", os.path.join(DLC, "focus_GER_fuhrerprinzip_todt.dds"),
                         os.path.join(BASE, "focus_GER_fuhrerprinzip_todt.dds")))

outdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png")
os.makedirs(outdir, exist_ok=True)
chosen = []
for tag, dlc, base in cands:
    src = dlc if os.path.exists(dlc) else base
    kind = "DLC" if (src == dlc) else "base"
    try:
        im = Image.open(src); im.load()
        im = im.convert("RGBA")
        im.save(os.path.join(outdir, "real_%s.png" % tag))
        print("OK   %-10s %-4s %3dx%-3d  <- %s" % (tag, kind, im.width, im.height, src))
        chosen.append((tag, im))
    except Exception as e:
        print("FAIL %-10s %s" % (tag, e))

# 拼图（4 列）
S = 4
if chosen:
    W = max(i.width for _, i in chosen) * S
    H = max(i.height for _, i in chosen) * S
    cols = 4
    rows = (len(chosen) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * W, rows * H), (30, 30, 30, 255))
    for k, (tag, im) in enumerate(chosen):
        big = im.resize((im.width * S, im.height * S), Image.LANCZOS)
        sheet.paste(big, ((k % cols) * W, (k // cols) * H), big)
    p = os.path.join(outdir, "sheet_ger_entry_real.png")
    sheet.save(p); print(p)
