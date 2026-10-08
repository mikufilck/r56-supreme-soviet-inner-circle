# 把德国 7 个「升格国策」入口图标拼成一张对比图，一次看全
import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

G = r"F:\Hearts of Iron IV\gfx\interface\goals"
items = [
    ("todt",     os.path.join(G, "focus_GER_ascension_of_todt.dds")),
    ("speer",    os.path.join(G, "focus_GER_ascension_of_speer.dds")),
    ("goring",   os.path.join(G, "focus_GER_ascension_of_goring.dds")),
    ("himmler",  os.path.join(G, "focus_GER_ascension_of_himmler.dds")),
    ("goebbels", os.path.join(G, "focus_GER_ascension_of_goebbels.dds")),
    ("hess",     os.path.join(G, "focus_GER_party_chancellor_hess.dds")),
    ("bormann",  os.path.join(G, "focus_GER_party_chancellor_bormann.dds")),
]

W, H = 100, 88
SCALE = 3
cols, rows = 4, 2
sheet = Image.new("RGBA", (cols * W * SCALE, rows * H * SCALE), (40, 40, 40, 255))

for i, (name, path) in enumerate(items):
    try:
        im = Image.open(path); im.load()
        im = im.convert("RGBA").resize((W * SCALE, H * SCALE), Image.NEAREST)
        x = (i % cols) * W * SCALE
        y = (i // cols) * H * SCALE
        sheet.paste(im, (x, y), im)
        print("OK %s" % name)
    except Exception as e:
        print("FAIL %s %s" % (name, e))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png", "sheet_ger_entry.png")
sheet.save(out)
print(out)
