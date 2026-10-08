import os, sys, colorsys
from collections import Counter
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

G = r"F:\Hearts of Iron IV\gfx\interface\goals"
names = ["focus_GER_ascension_of_todt", "focus_GER_ascension_of_speer",
         "focus_GER_ascension_of_goring", "focus_GER_ascension_of_himmler",
         "focus_GER_ascension_of_goebbels", "focus_GER_party_chancellor_hess",
         "focus_GER_party_chancellor_bormann", "focus_GER_fuhrerprinzip",
         "focus_GER_fuhrerprinzip_hess"]

for n in names:
    p = os.path.join(G, n + ".dds")
    if not os.path.exists(p):
        print("MISS %s" % n); continue
    im = Image.open(p); im.load()
    im = im.convert("RGBA")
    px = list(im.getdata())
    total = len(px)
    skin = 0; purple = 0; colorful = 0
    cnt = Counter()
    for r, g, b, a in px:
        if a < 32:
            cnt[(0, 0, 0, 0)] += 1
            continue
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        deg = h * 360
        if s > 0.10 and v > 0.15:
            colorful += 1
            if 10 <= deg <= 45 and s > 0.15 and v > 0.35:      # 肤色
                skin += 1
            if 260 <= deg <= 320 and s > 0.15:                  # 紫
                purple += 1
        cnt[(r // 48 * 48, g // 48 * 48, b // 48 * 48, 255)] += 1

    top = [c for c, k in cnt.most_common(4)]
    print("%-34s %3dx%-3d  不透明=%5d  彩色像素=%4.1f%%  肤色=%4.1f%%  紫色=%4.1f%%  主色=%s"
          % (n, im.width, im.height, total - cnt[(0, 0, 0, 0)],
             colorful * 100.0 / total, skin * 100.0 / total, purple * 100.0 / total, top))
