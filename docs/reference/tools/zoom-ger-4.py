import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

G = r"F:\Hearts of Iron IV\gfx\interface\goals"
items = [
    ("todt",     "focus_GER_ascension_of_todt.dds"),
    ("speer",    "focus_GER_ascension_of_speer.dds"),
    ("goring",   "focus_GER_ascension_of_goring.dds"),
    ("himmler",  "focus_GER_ascension_of_himmler.dds"),
]
S = 5
ims = []
for n, f in items:
    im = Image.open(os.path.join(G, f)); im.load()
    im = im.convert("RGBA")
    print("%-10s %dx%d" % (n, im.width, im.height))
    ims.append((n, im.resize((im.width * S, im.height * S), Image.LANCZOS)))

W = max(i.width for _, i in ims)
H = max(i.height for _, i in ims)
sheet = Image.new("RGBA", (W * 2, H * 2), (30, 30, 30, 255))
for k, (n, im) in enumerate(ims):
    sheet.paste(im, ((k % 2) * W, (k // 2) * H), im)
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png", "zoom_ger_4.png")
sheet.save(out); print(out)
