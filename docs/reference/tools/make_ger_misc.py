import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

G = r"F:\Hearts of Iron IV\gfx\interface\goals"
names = [
    "focus_GER_fuhrerprinzip",
    "focus_GER_a_strong_successor",
    "focus_GER_loyalty_to_the_fuhrer",
    "focus_GER_form_organization_todt",
    "focus_GER_hegemony_of_the_ss",
]
W, H, S = 100, 88, 3
found = []
for n in names:
    p = os.path.join(G, n + ".dds")
    if os.path.exists(p):
        found.append((n, p)); print("OK   %s" % n)
    else:
        print("MISS %s" % n)

if found:
    sheet = Image.new("RGBA", (len(found) * W * S, H * S), (40, 40, 40, 255))
    for i, (n, p) in enumerate(found):
        im = Image.open(p); im.load()
        im = im.convert("RGBA").resize((W * S, H * S), Image.LANCZOS)
        sheet.paste(im, (i * W * S, 0), im)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png", "sheet_ger_misc.png")
    sheet.save(out); print(out)
