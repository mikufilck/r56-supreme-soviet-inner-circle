# 把参考用的 .dds 转成 .png 以便查看（Pillow 支持 DXT1/3/5 读取）
import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

pairs = [
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_GER_ascension_of_todt.dds",     "ref_ger_todt.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_GER_ascension_of_himmler.dds",  "ref_ger_himmler.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_GER_ascension_of_goebbels.dds", "ref_ger_goebbels.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_SOV_organize_wreckers.dds",     "ref_sov_wreckers.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_SOV_the_supreme_soviet.dds",    "ref_sov_supreme.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\focus_generic_soviet_politics.dds",   "ref_sov_politics.png"),
    (r"F:\Hearts of Iron IV\gfx\interface\goals\goal_support_fourth_int.dds",         "ref_sov_fourth_int.png"),
    (r"D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\interface\goals\sov\r56_goal_SOV_trotsky_victory.dds", "ref_r56_trotsky_victory.png"),
    (r"D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\interface\goals\generic\r56_goal_generic_arrests.dds", "ref_r56_arrests.png"),
]

outdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png")
os.makedirs(outdir, exist_ok=True)

for src, name in pairs:
    try:
        im = Image.open(src)
        im.load()
        out = os.path.join(outdir, name)
        im.convert("RGBA").save(out)
        print("OK   %-28s %dx%d  -> %s" % (name, im.width, im.height, out))
    except Exception as e:
        print("FAIL %-28s %s" % (name, e))
