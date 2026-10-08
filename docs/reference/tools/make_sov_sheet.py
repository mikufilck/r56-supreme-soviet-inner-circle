# 苏联国策图标风格参考拼图（原版 + R56）
import os, sys
_REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.insert(0, os.path.join(_REPO, "tmp", "art-python"))
from PIL import Image

V = r"F:\Hearts of Iron IV\gfx\interface\goals"
R = r"D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\gfx\interface\goals"

items = [
    ("supreme_soviet",   os.path.join(V, "focus_SOV_the_supreme_soviet.dds")),
    ("builder_red_army", os.path.join(V, "focus_SOV_builder_of_the_red_army.dds")),
    ("marxism_leninism", os.path.join(V, "focus_SOV_the_path_of_marxism_leninism.dds")),
    ("socialism_1ctry",  os.path.join(V, "focus_SOV_socialism_in_one_country.dds")),
    ("ally_bukharin",    os.path.join(V, "focus_SOV_ally_bukharinists.dds")),
    ("ally_zinovyev",    os.path.join(V, "focus_SOV_ally_zinovyevists.dds")),
    ("organize_wreckers",os.path.join(V, "focus_SOV_organize_wreckers.dds")),
    ("breadbasket",      os.path.join(V, "focus_SOV_breadbasket_of_the_union.dds")),
    ("military_purge",   os.path.join(V, "focus_SOV_military_purge.dds")),
    ("last_purge",       os.path.join(V, "focus_SOV_the_last_purge.dds")),
    ("approach_tukhach", os.path.join(V, "focus_SOV_approach_tukahchevsky.dds")),
    ("comecon",          os.path.join(V, "focus_SOV_the_comecon.dds")),
    ("r56_trot_victory", os.path.join(R, "sov", "r56_goal_SOV_trotsky_victory.dds")),
    ("r56_5year_plan",   os.path.join(R, "sov", "r56_goal_SOV_5year_plan_continue.dds")),
    ("r56_iron_curtain", os.path.join(R, "sov", "r56_goal_sov_iron_curtain.dds")),
    ("r56_comecon",      os.path.join(R, "sov", "r56_goal_sov_comecon.dds")),
]

W, H, SCALE = 100, 88, 2
cols = 4
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * W * SCALE, rows * H * SCALE), (40, 40, 40, 255))

for i, (name, path) in enumerate(items):
    try:
        im = Image.open(path); im.load()
        im = im.convert("RGBA").resize((W * SCALE, H * SCALE), Image.LANCZOS)
        sheet.paste(im, ((i % cols) * W * SCALE, (i // cols) * H * SCALE), im)
        print("OK   %-18s <- %s" % (name, os.path.basename(path)))
    except Exception as e:
        print("FAIL %-18s %s" % (name, e))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-refs-png", "sheet_sov_style.png")
sheet.save(out)
print(out)
