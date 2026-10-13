"""STORE ADS — ad creatives for Steel & Glory's Roblox campaigns, made with blender/store_art.py's kit.

    blender.exe -b --python blender/store_ads.py -- <ad> <out.png> [--preview | --layout]
    ads: versus · parry · armory · all (<out> a folder)

Sponsored-experience, search and image ads are 16:9 (1920×1080) and are mostly seen small, as
a tile on the Home page. So each has one subject, big and off-centre; one to three words a child
can read at a glance; nothing important in the bottom strip (the tile's name and rating cover
it); bright, saturated colours. Ads only reach players 13+ and must show the game as it is: the
real armour, weapons and spells, no blood (the game is rated Mild), no "best" or "#1" claims."""
import bpy, math, os, sys
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import store_art as S  # noqa: E402
import art_kit as K  # noqa: E402
from art_kit import rgb, T, R  # noqa: E402

SUN = {"Primary": rgb(40, 90, 220), "Secondary": rgb(230, 230, 236), "Accent": rgb(240, 190, 70), "Metal": rgb(230, 232, 238)}
PYRO = {"Primary": rgb(200, 50, 20), "Secondary": rgb(40, 20, 16), "Accent": rgb(255, 170, 40), "Metal": rgb(240, 190, 90)}


def _pixels(path):
    im = bpy.data.images.load(path)
    w, h = im.size
    return np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4), im


def _save(px, path):
    h, w = px.shape[:2]
    img = bpy.data.images.new("out", w, h, alpha=True)
    img.pixels = px.ravel()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()


# ------------------------------------------------------------------------
#  VERSUS: the Knight on the left, the Mage on the right, split on a slant of light
# ------------------------------------------------------------------------
def versus_side(path, side):
    S.setup()
    probes = []
    if side == "knight":
        K.sky(top=rgb(10, 24, 90), horizon=rgb(70, 140, 255), strength=1.2, band=0.5)
        S.sunburst((-3.5, 30, 3.5), 60, n=26, colors=(rgb(80, 150, 255), rgb(30, 70, 200)), strength=1.5, facing=(0.1, -1, 0))
        pose = dict(torso=(-6, -14, 0), head=(-4, -10, 0), rarm=(150, 0, 30), larm=(46, 22, -16), rleg=(-14, 0, 8), lleg=(16, 0, -6))
        f, _ = K.figure("SunKnights", at=(-2.6, 0.3, 0), yaw=-118, pose=pose, colors=SUN)
        K.weapon("Greatsword", S.held(K.hand(f), (0.55, 0.15, 1), slide=-0.2, roll=90))
        K.embers((-8, -2, 0), (2, 6, 8), n=60, color=rgb(170, 210, 255), seed=4, size=(0.02, 0.05), strength=6)
        key = rgb(200, 220, 255)
    else:
        K.sky(top=rgb(70, 10, 10), horizon=rgb(255, 120, 30), strength=1.3, band=0.5)
        S.sunburst((3.5, 30, 3.5), 60, n=26, colors=(rgb(255, 170, 50), rgb(220, 60, 20)), strength=1.5, facing=(-0.1, -1, 0))
        # three-quarters to us, the right hand (the near side to the Knight) thrust at him with a
        # fireball over it, the staff upright in the left
        pose = dict(torso=(-4, 0, 0), head=(-6, -14, 0), rarm=(112, -26, 0), larm=(18, 0, -12), rleg=(-12, 0, 8), lleg=(14, 0, -6))
        f, _ = K.figure("Pyromancer", at=(3.0, 0.3, 0), yaw=128, pose=pose, colors=PYRO, neon=2.6)
        K.staff("Emberwood", S.held(K.hand(f, "L"), (0.1, 0.1, 1), slide=-0.9), neon=4)
        hand = K.hand(f)
        palm = hand.translation + (hand.to_3x3() @ Vector((0, 0.5, 0))) + Vector((0, 0, 0.5))
        K.fire(tuple(palm), r=0.74, strength=2.4, power=900, seed=21)
        probes = [("palm", palm), ("mage head", f["Head"].translation)]
        K.embers((-1, -2, 0), (8, 6, 8), n=80, color=rgb(255, 140, 40), seed=6, size=(0.02, 0.06), strength=6)
        key = rgb(255, 210, 170)
    K.ground(240, K.stone_mat(rgb(90, 86, 96), rgb(40, 38, 46), 1.6))
    K.light("AREA", (0, -8, 7), key, 700, size=6, target=(0, 0, 3.6))
    K.light("AREA", (-6 if side == "knight" else 6, 5, 7), rgb(255, 220, 160), 1800, size=4, target=(0, 0, 4))
    K.camera((0, -9.2, 3.0), (0, 0, 3.75), lens=34, focus=(0, 0.3, 4), fstop=4)
    for label, p in probes:
        K.where(label, p)
    K.bloom(0.5, 1.1, 0.7, saturation=1.15)
    K.render(path)


def versus(out):
    left, right = S.base_of(out, "left"), S.base_of(out, "right")
    versus_side(left, "knight")
    versus_side(right, "mage")
    a, _ = _pixels(left)
    b, _ = _pixels(right)
    h, w = a.shape[:2]
    # the split: a line slanting up to the right through the middle (rows run bottom-up)
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    edge = w * 0.5 + (ys - h * 0.5) * 0.28
    d = xs - edge
    out_px = np.where((d < 0)[..., None], a, b)
    # a blade of light along it, white at the heart, gold round it
    glow = np.exp(-(d / (w * 0.004)) ** 2)[..., None]
    halo = np.exp(-(d / (w * 0.02)) ** 2)[..., None]
    out_px[..., :3] = np.clip(out_px[..., :3] + halo * np.array([1.0, 0.75, 0.3]) * 0.55 + glow * 1.2, 0, 1)
    out_px[..., 3] = 1
    _save(out_px, S.base_of(out))
    S.finish(out, VERSUS_TITLES)


VERSUS_TITLES = [
    {"text": "VS", "x": 0.15, "y": -0.6, "size": 3.0, "fill": (rgb(255, 250, 220), rgb(255, 170, 30)), "outline": rgb(40, 16, 4), "ow": 0.08},
    {"text": "KNIGHT", "x": -5.2, "y": 3.7, "size": 1.25, "fill": (rgb(230, 240, 255), rgb(110, 170, 255)), "outline": rgb(6, 18, 60), "tilt": 3},
    {"text": "MAGE", "x": 5.6, "y": 3.7, "size": 1.25, "fill": (rgb(255, 240, 200), rgb(255, 140, 40)), "outline": rgb(60, 10, 4), "tilt": -3},
]


# ------------------------------------------------------------------------
#  PARRY: tight on two blades meeting, the parry's white-gold burst between them
# ------------------------------------------------------------------------
def parry(out):
    S.setup()
    K.sky(top=rgb(14, 10, 40), horizon=rgb(255, 120, 40), strength=1.4, band=0.25)
    K.fog(0.004, rgb(255, 170, 120), 0.6, size=(200, 90, 10), center=(0, 50, 4))
    K.ground(240, K.stone_mat(rgb(96, 86, 76), rgb(44, 40, 36), 1.6))
    S.castle_backdrop(46)
    # the defender (right, toward us), guard up; the attacker (left, half out of frame) swinging in
    dpose = dict(torso=(6, 18, 0), head=(-8, 22, 0), rarm=(118, 34, 0), larm=(118, -34, 0), rleg=(-14, 0, 8), lleg=(16, 0, -6))
    fd, _ = K.figure("Lionheart", at=(1.7, 0.4, 0), yaw=150, pose=dpose,
                     colors={"Primary": rgb(190, 30, 34), "Secondary": rgb(240, 236, 228), "Accent": rgb(255, 200, 70), "Metal": rgb(236, 238, 244)})
    guard = K.hand(fd)
    K.weapon("Longsword", S.held(guard, (-0.75, -0.1, 0.65), roll=90))
    apose = dict(torso=(12, -10, 0), head=(-4, -8, 0), rarm=(120, 30, 20), larm=(100, 40, -20), rleg=(-20, 0, 6), lleg=(22, 0, -4))
    fa, _ = K.figure("Blackguard", at=(-2.9, 1.4, 0), yaw=-70, pose=apose,
                     colors={"Primary": rgb(160, 24, 24), "Secondary": rgb(30, 26, 28), "Accent": rgb(200, 30, 30), "Metal": rgb(60, 60, 66)})
    K.weapon("Zweihander", S.held(K.hand(fa), (0.85, -0.05, -0.3), roll=90))
    hit = guard.translation + Vector((-1.55, -0.05, 1.25))
    K.sparks(tuple(hit), n=80, color=rgb(255, 236, 170), spread=2.2, length=0.6, power=1400, strength=4)
    K.light("AREA", (-6, -8, 7), rgb(130, 160, 255), 500, size=8, target=(0, 0, 4))
    K.light("AREA", (5, 7, 7), rgb(255, 150, 70), 2400, size=5, target=(1.7, 0.4, 4.5))
    K.camera((-0.4, -7.4, 4.4), (0.2, 0, 4.85), lens=32, focus=tuple(hit), fstop=2.8)
    K.where("hit", hit)
    K.where("defender head", fd["Head"].translation)
    K.bloom(0.6, 1.0, 0.8, saturation=1.12)
    K.render(S.base_of(out))
    S.finish(out, PARRY_TITLES)


PARRY_TITLES = [
    {"text": "PARRY!", "x": -4.6, "y": 3.2, "size": 2.3, "tilt": 6},
]


# ------------------------------------------------------------------------
#  ARMORY: three of the rarest sets side by side, each in its rarity's light
# ------------------------------------------------------------------------
ARMORY = [
    # set, at, yaw, colours, light (rarity), neon
    ("StarSage", (-3.6, 1.0, 0), 196, {"Primary": rgb(70, 40, 170), "Secondary": rgb(24, 18, 60), "Accent": rgb(255, 214, 110), "Metal": rgb(230, 220, 255)},
     rgb(190, 110, 255), 3.0),
    ("Phoenix", (0, -0.4, 0), 180, {"Primary": rgb(196, 40, 30), "Secondary": rgb(60, 26, 16), "Accent": rgb(255, 196, 80), "Metal": rgb(232, 184, 74)},
     rgb(255, 80, 60), 2.6),
    ("Obsidian", (3.6, 1.0, 0), 164, {"Primary": rgb(30, 26, 34), "Secondary": rgb(16, 14, 20), "Accent": rgb(170, 90, 255), "Metal": rgb(70, 64, 84)},
     rgb(255, 196, 80), 3.0),
]


def armory(out):
    S.setup()
    K.sky(top=rgb(8, 6, 20), horizon=rgb(50, 30, 80), strength=1.0, band=0.5)
    K.ground(240, K.stone_mat(rgb(60, 56, 70), rgb(24, 22, 30), 1.4))
    for i, (set_name, at, yaw, cols, glow, neon) in enumerate(ARMORY):
        pose = dict(torso=(2, 0, 0), head=(-6, (yaw - 180) * 0.5, 0), rarm=(12, 0, 10), larm=(12, 0, -10), rleg=(-4, 0, 3), lleg=(4, 0, -3))
        f, _ = K.figure(set_name, at=at, yaw=yaw, pose=pose, colors=cols, neon=neon)
        # its rarity's light: a burst of rays behind, a ring on the floor, a beam from above
        S.sunburst((at[0], at[1] + 3.5, at[2] + 3.6), 4.6, n=16, colors=(glow, tuple(c * 0.3 for c in glow)), strength=2.2, facing=(0, -1, 0))
        n = 48
        ring = [(at[0] + math.cos(a) * 1.9, at[1] + math.sin(a) * 1.9, 0.03) for a in [k / n * 2 * math.pi for k in range(n + 1)]]
        K.obj("Ring", K.W.tube(ring, 0.06, glow, caps=False), K.flat_mat("ring", glow, emit=5), K.Matrix())
        K.light("SPOT", (at[0], at[1] - 2, 11), glow, 2500, size=0.6, target=(at[0], at[1], 3), angle=28)
        K.embers((at[0] - 1.5, at[1] - 1, 0.2), (at[0] + 1.5, at[1] + 1.5, 7), n=40, color=glow, seed=10 + i, size=(0.02, 0.05), strength=6)
    K.light("AREA", (0, -9, 6), rgb(220, 220, 255), 500, size=8, target=(0, 0, 3.5))
    K.camera((0, -10.6, 2.6), (0, 0, 3.6), lens=33, focus=(0, -0.4, 4), fstop=5)
    K.bloom(0.55, 1.0, 0.75, saturation=1.12)
    K.render(S.base_of(out))
    S.finish(out, ARMORY_TITLES)


ARMORY_TITLES = [
    {"text": "35+ ARMOR SETS", "y": 3.75, "size": 1.55},
]

ADS = {"versus": versus, "parry": parry, "armory": armory}

if __name__ == "__main__":
    name, out = S.ARGS[0], os.path.abspath(S.ARGS[1])
    if name == "all":
        for k, fn in ADS.items():
            fn(os.path.join(out, f"ad_{k}.png"))
    else:
        ADS[name](out)
