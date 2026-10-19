"""THE FORGE — weapon skins as real meshes, built in Blender headless from the
same recipes as the weapons (blender/weapons.py) under a THEME.

    blender.exe -b --python blender/forge.py -- Longsword:gilded Mace:hellforged ...
    blender.exe -b --python blender/forge.py -- --manifest          every skin in Catalog ▸ Skins
    blender.exe -b --python blender/forge.py -- --preview a.png Longsword:gilded Mace:frostbite ...

A theme is a set of changes, not a recolour:
  palette    what each of the weapon's materials becomes (steel, edge, fuller,
             leather, wood, brass, gold ... see BASE): obsidian, bone, gold, ice
  pattern    painted into the steel by position: damascus, rust, blued, frost,
             scales, stripes, stars, filigree, embers, bark, knotwork, waves
  edge       the blade's cut: serrate, jag, nicks, wave, barb (blades AND axe heads)
  guard      a new crossguard (swords) or collar under the head (hafted):
             wings, horns, crescent, spikes, crown, bones, antlers, thorns, holly,
             sunburst, laurel, ribs, anchor, knot
  pommel     a new pommel (swords) or foot (hafted): skull, jewel, claw, spike,
             pumpkin, dragon, star, ring, lantern, acorn
  wrap       the grip: bone (vertebrae), fur, rope, gilt, candy
  ornaments  serpent, chains, candles, feathers, web, tassel, thornwrap, ribbon
  glow       {color, kinds}: Neon inlays raycast onto the flats — runes, cracks,
             veins, core, stars, halo — plus every GLOW-painted bit (jewels, eyes,
             pumpkin faces, crystals) on its own region
  blade      a sword's own silhouette (BLADES): flame leaf broad crystal bone fang
             twin lightning serpent sun tiered forked obsidian
  head       on a haft, by family: {spear = broad flame winged trident crescent crystal
             bone serpent sun, axe = double crescent bearded broad dragon,
             blunt = spiked skull crystal orb star crown}
  hammer     a war hammer's and a maul's head only (else the blunt one): the blunt
             styles, or drum (round, banded), anvil (a horn behind), beak (a bec
             de corbin), flanged
  haft       the shaft itself: banded spiral twisted bone vine gilded crystal runic
             bamboo rope scaled chain ash
Each skin exports <Weapon>__<Skin>_Body.fbx (vertex colours, written as sRGB: the palettes'
colours are what Roblox shows, a little deeper by weapons.TONE) and, when it glows,
<Weapon>__<Skin>_Glow.fbx (white; Studio makes it Neon in the glow colour), with
a json of region centres in the Tool frame (MeshTool-style weld offsets).
"""
import bpy, bmesh, math, os, sys, json, re
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
import weapons as W  # noqa: E402

OUT = os.path.join(ROOT, "blender", "out", "skins")
SKINS_LUA = os.path.join(ROOT, "roblox", "ReplicatedStorage", "Catalog", "Skins.lua")


def C(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# the weapon recipes' materials, by role
BASE = {"steel": W.STEEL, "bright": W.BRIGHT, "edge": W.EDGE, "fuller": W.FULLER, "face": W.FACE,
        "darksteel": W.DARKSTEEL, "iron": W.IRON, "blackiron": W.BLACKIRON, "leather": W.LEATHER,
        "darkleather": W.DARKLEATHER, "wood": W.WOOD, "darkwood": W.DARKWOOD, "brass": W.BRASS,
        "gold": W.GOLD, "red": W.RED, "rope": W.ROPE, "wire": W.WIRE}
STEELY = {"steel", "bright", "face", "fuller"}
ROLE_OF = {v: k for k, v in BASE.items()}


# --------------------------------------------------------------------------
#  ANCHORS: where each weapon's grip, guard, foot and head are (Tool frame)
# --------------------------------------------------------------------------
SWORDS = {   # grip length, grip radius
    "Longsword": (0.95, 0.13), "ArmingSword": (0.62, 0.13), "Shortsword": (0.55, 0.13), "Greatsword": (1.2, 0.13),
    "Zweihander": (1.4, 0.13), "Executioner": (1.2, 0.13), "Estoc": (1.0, 0.13), "Rapier": (0.6, 0.13),
    "Dagger": (0.45, 0.11), "Falchion": (0.6, 0.13), "Messer": (0.9, 0.13), "Cleaver": (0.6, 0.12),
}
HAFTED = {   # foot y, haft top y, haft radius, the head's lowest point (a collar sits there)
    "Hammer": (-0.5, 1.52, 0.09, 1.25), "Mace": (-0.6, 1.3, 0.09, 1.22), "MorningStar": (-0.7, 1.45, 0.1, 1.4),
    "Maul": (-1.2, 2.3, 0.12, 2.15), "WarAxe": (-0.7, 1.7, 0.09, 1.08), "BattleAxe": (-1.0, 2.5, 0.11, 1.88),
    "Bardiche": (-1.3, 3.3, 0.11, 1.55), "Spear": (-1.6, 3.5, 0.09, 2.88), "Pitchfork": (-1.6, 3.3, 0.09, 2.92),
    "Halberd": (-1.6, 3.5, 0.1, 2.53), "Poleaxe": (-1.5, 3.2, 0.1, 2.58), "Glaive": (-1.5, 3.3, 0.1, 2.88),
    "Billhook": (-1.4, 3.1, 0.1, 2.68), "Quarterstaff": (-2.4, 2.6, 0.1, 2.38),
}


def anchors(name):
    if name in SWORDS:
        gl, r = SWORDS[name]
        return {"kind": "sword", "guard": gl / 2 + 0.07, "foot": -gl / 2, "grip0": -gl / 2, "grip1": gl / 2, "r": r}
    yb, yt, r, hy = HAFTED[name]
    return {"kind": "hafted", "guard": hy, "foot": yb, "grip0": -0.5, "grip1": 0.5, "r": r, "top": yt}


# --------------------------------------------------------------------------
#  small shapes
# --------------------------------------------------------------------------
def col(theme, role, fallback=W.STEEL):
    """a colour for a theme part: a role name (palette-mapped later) or an rgb"""
    v = theme.get(role)
    if v is None:
        return fallback
    if isinstance(v, str):
        return BASE.get(v, fallback)
    return v


def leaf(cx, cy, length, width, angle, color, t=0.04, cz=0.0, spiky=False):
    """a leaf / feather / blade-shaped plate from (cx, cy) along `angle` (radians from +X)"""
    pts = []
    n = 7
    for k in range(n + 1):
        f = k / n
        w = width * math.sin(math.pi * f) ** 0.8
        if spiky and 0 < k < n:
            w *= 1.35 if k % 2 else 0.8
        pts.append((f * length, w / 2))
    for k in range(n - 1, 0, -1):
        f = k / n
        w = width * math.sin(math.pi * f) ** 0.8
        if spiky:
            w *= 1.35 if k % 2 else 0.8
        pts.append((f * length, -w / 2))
    c, s = math.cos(angle), math.sin(angle)
    outline = [(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts]
    # plate() wants counter-clockwise
    area = sum(outline[i][0] * outline[(i + 1) % len(outline)][1] - outline[(i + 1) % len(outline)][0] * outline[i][1] for i in range(len(outline)))
    if area < 0:
        outline.reverse()
    return W.plate(outline, color, t=t, cz=cz)


def torus(c, R, r, color, axis="y", n=16, m=6):
    pts = []
    for k in range(n + 1):
        a = 2 * math.pi * k / n
        if axis == "y":
            pts.append((c[0] + R * math.cos(a), c[1], c[2] + R * math.sin(a)))
        elif axis == "z":
            pts.append((c[0] + R * math.cos(a), c[1] + R * math.sin(a), c[2]))
        else:
            pts.append((c[0], c[1] + R * math.cos(a), c[2] + R * math.sin(a)))
    return W.tube(pts, r, color, n=m, caps=False)


def skull(c, s, color, eyes=None):
    """a little skull facing +Z: cranium, cheeks, jaw, eye sockets (eyes: a glow colour)"""
    x, y, z = c
    parts = [W.sphere((x, y + s * 0.15, z), s * 0.5, color, u=12, v=8, scale=(0.92, 0.95, 1.0)),
             W.box(x, y - s * 0.32, z + s * 0.08, s * 0.5, s * 0.28, s * 0.62, color)]
    for sx in (-1, 1):
        sock = (x + sx * s * 0.19, y + s * 0.02, z + s * 0.43)
        parts.append(W.sphere(sock, s * 0.13, eyes or W.BLACKIRON, u=8, v=6, scale=(1, 0.9, 0.5)))
    parts.append(W._pyr((x, y - s * 0.12, z + s * 0.44), (x, y - s * 0.02, z + s * 0.5), s * 0.06, W.BLACKIRON))
    for k in range(-2, 3):
        parts.append(W.box(x + k * s * 0.08, y - s * 0.4, z + s * 0.39, s * 0.05, s * 0.09, s * 0.05, (0.92, 0.9, 0.84)))
    return parts


def moved(bm, dx, dy, dz):
    for v in bm.verts:
        v.co.x += dx; v.co.y += dy; v.co.z += dz
    return bm


def chain(top, links, size, color):
    parts = []
    x, y, z = top
    for k in range(links):
        cy = y - k * size * 1.5
        parts.append(torus((x, cy, z), size * 0.55, size * 0.16, color, axis=("z" if k % 2 else "x"), n=10, m=5))
    return parts


# --------------------------------------------------------------------------
#  GUARDS: (theme, y, span, t) -> [bmesh]; for hafted weapons a collar under the head
# --------------------------------------------------------------------------
def g_wings(th, y, span, t):
    c = col(th, "guard_color", W.STEEL)
    parts = [W.box(0, y, 0, 0.32, t * 1.6, t * 1.8, c)]
    for side in (-1, 1):
        for k in range(5):
            a = math.radians(8 + k * 17) if side > 0 else math.pi - math.radians(8 + k * 17)
            L = span * (0.62 - k * 0.07)
            parts.append(leaf(side * 0.1, y - 0.02, L, 0.13 - k * 0.012, a, c, t=0.035, cz=(k % 2) * 0.015))
    return parts


def g_horns(th, y, span, t):
    c = col(th, "horn_color", C(214, 200, 170))
    parts = [W.box(0, y, 0, 0.34, t * 1.7, t * 1.9, col(th, "guard_color", W.DARKSTEEL))]
    for side in (-1, 1):
        pts = [(side * 0.12, y, 0), (side * span * 0.36, y - 0.04, 0), (side * span * 0.58, y + 0.18, 0), (side * span * 0.6, y + 0.48, 0), (side * span * 0.46, y + 0.68, 0)]
        parts.append(W.tube(pts, [0.09, 0.08, 0.06, 0.04, 0.006], c, n=8))
    return parts


def g_crescent(th, y, span, t):
    c = col(th, "guard_color", W.STEEL)
    pts, rs = [], []
    for k in range(13):
        f = k / 12
        a = math.pi * f
        pts.append((-math.cos(a) * span * 0.5, y + (1 - math.sin(a)) * 0.38 - 0.06, 0))
        rs.append(0.012 + 0.07 * math.sin(a))
    return [W.tube(pts, rs, c, n=8), W.box(0, y, 0, 0.3, t * 1.5, t * 1.7, c)]


def g_spikes(th, y, span, t):
    c = col(th, "guard_color", W.DARKSTEEL)
    parts = [W.box(0, y, 0, span * 0.55, t * 1.4, t * 1.6, c)]
    for side in (-1, 1):
        for k, (dx, dy) in enumerate(((0.55, 0.0), (0.42, 0.22), (0.3, -0.18))):
            b = (side * span * 0.22, y, 0)
            parts.append(W._pyr(b, (side * span * dx, y + dy, 0), 0.06, c))
    return parts


def g_crown(th, y, span, t):
    c = col(th, "guard_color", W.GOLD)
    parts = [torus((0, y, 0), 0.24, 0.05, c, axis="y", n=18), W.box(0, y, 0, span * 0.6, t * 1.2, t * 1.5, c)]
    for k in range(8):
        a = 2 * math.pi * k / 8
        base = (math.cos(a) * 0.24, y + 0.03, math.sin(a) * 0.24)
        parts.append(W._pyr(base, (math.cos(a) * 0.32, y + 0.42, math.sin(a) * 0.32), 0.06, c))
        parts.append(W.sphere((math.cos(a) * 0.32, y + 0.43, math.sin(a) * 0.32), 0.045, W.GLOW if th.get("glow") else c, u=6, v=4))
    for side in (-1, 1):
        parts.append(W.sphere((side * span * 0.3, y, 0), 0.07, c, u=10, v=6))
    return parts


def g_bones(th, y, span, t):
    bone = col(th, "bone_color", C(222, 210, 182))
    parts = []
    for side in (-1, 1):
        pts = [(side * 0.06, y, 0), (side * span * 0.25, y - 0.05, 0), (side * span * 0.45, y + 0.06, 0)]
        parts.append(W.tube(pts, [0.06, 0.045, 0.055], bone, n=8))
        end = pts[-1]
        for dz in (-1, 1):
            parts.append(W.sphere((end[0] + side * 0.03, end[1], dz * 0.04), 0.06, bone, u=8, v=6))
    parts += skull((0, y + 0.02, 0.0), 0.32, bone, eyes=W.GLOW if th.get("glow") else None)
    return parts


def g_antlers(th, y, span, t):
    c = col(th, "horn_color", C(150, 116, 80))
    parts = [W.box(0, y, 0, 0.3, t * 1.6, t * 1.8, col(th, "guard_color", W.DARKWOOD))]
    for side in (-1, 1):
        main = [(side * 0.1, y, 0), (side * span * 0.3, y + 0.12, 0), (side * span * 0.42, y + 0.4, 0), (side * span * 0.38, y + 0.75, 0)]
        parts.append(W.tube(main, [0.07, 0.055, 0.04, 0.012], c, n=7))
        for k, (fx, fy, lx, ly) in enumerate(((0.3, 0.12, 0.5, 0.3), (0.42, 0.4, 0.62, 0.55), (0.4, 0.58, 0.24, 0.8))):
            parts.append(W.tube([(side * span * fx, y + fy, 0), (side * span * lx, y + ly, 0.02 * k)], [0.04, 0.008], c, n=6))
    return parts


def g_thorns(th, y, span, t):
    c = col(th, "guard_color", C(70, 52, 40))
    parts = []
    for side in (-1, 1):
        pts = [(side * (0.05 + span * 0.5 * f), y + 0.06 * math.sin(f * 9), 0.05 * math.cos(f * 9)) for f in [k / 10 for k in range(11)]]
        parts.append(W.tube(pts, [0.05 - 0.03 * k / 10 for k in range(11)], c, n=6))
        for k in range(2, 10, 2):
            p = Vector(pts[k])
            d = Vector((side * 0.3, 0.6 if k % 4 else -0.6, 0.3 * (1 if k % 3 else -1))).normalized()
            parts.append(W.cone(tuple(p), tuple(p + d * 0.14), 0.025, c, n=5))
    parts.append(W.box(0, y, 0, 0.28, t * 1.5, t * 1.7, c))
    return parts


def g_holly(th, y, span, t):
    green = C(40, 110, 50)
    parts = [W.box(0, y, 0, 0.3, t * 1.5, t * 1.7, col(th, "guard_color", W.GOLD))]
    for side in (-1, 1):
        for k, a in enumerate((10, 35, -12)):
            ang = math.radians(a) if side > 0 else math.pi - math.radians(a)
            parts.append(leaf(side * 0.1, y, span * (0.42 - 0.06 * k), 0.18, ang, green, t=0.035, cz=0.02 * k, spiky=True))
    for k in range(3):
        parts.append(W.sphere((0.05 * (k - 1), y + 0.06, 0.08), 0.055, W.GLOW if th.get("glow") else W.RED, u=8, v=6))
    return parts


def g_sunburst(th, y, span, t):
    c = col(th, "guard_color", W.GOLD)
    parts = [W.disc((0, y, 0), 0.26, 0.08, c, axis="y"), W.box(0, y, 0, span * 0.45, t * 1.2, t * 1.4, c)]
    for k in range(12):
        a = 2 * math.pi * k / 12
        L = 0.42 if k % 2 == 0 else 0.3
        parts.append(W._pyr((math.cos(a) * 0.2, y, math.sin(a) * 0.2), (math.cos(a) * L, y + 0.02, math.sin(a) * L), 0.04, c))
    return parts


def g_laurel(th, y, span, t):
    c = col(th, "guard_color", W.GOLD)
    parts = []
    for side in (-1, 1):
        pts = [(side * span * 0.5 * f, y + 0.12 * f * f, 0) for f in [k / 8 for k in range(9)]]
        parts.append(W.tube(pts, 0.035, c, n=6))
        for k in range(1, 9, 2):
            px, py, _ = pts[k]
            for up in (1, -1):
                ang = math.atan2(0.4 * up, side * 1.0)
                parts.append(leaf(px, py, 0.16, 0.07, ang, c, t=0.025))
    parts.append(W.box(0, y, 0, 0.3, t * 1.5, t * 1.7, c))
    return parts


def g_ribs(th, y, span, t):
    bone = col(th, "bone_color", C(222, 210, 182))
    parts = []
    for side in (-1, 1):
        for k in range(3):
            pts = [(side * 0.06, y - k * 0.08, 0), (side * span * (0.3 - k * 0.04), y + 0.06 - k * 0.08, 0.06), (side * span * (0.42 - k * 0.06), y + 0.2 - k * 0.06, 0.0)]
            parts.append(W.tube(pts, [0.04, 0.032, 0.012], bone, n=6))
    parts.append(W.box(0, y - 0.08, 0, 0.18, 0.3, 0.16, bone))
    return parts


def g_anchor(th, y, span, t):
    c = col(th, "guard_color", W.BRASS)
    pts, rs = [], []
    for k in range(11):
        f = k / 10
        a = math.pi * f
        pts.append((-math.cos(a) * span * 0.42, y - math.sin(a) * 0.16 + 0.12, 0))
        rs.append(0.045)
    parts = [W.tube(pts, rs, c, n=6), W.box(0, y, 0, 0.26, t * 1.6, t * 1.8, c)]
    for side in (-1, 1):
        parts.append(W._pyr((side * span * 0.42, y + 0.12, 0), (side * span * 0.48, y + 0.3, 0), 0.06, c))
    return parts


def g_knot(th, y, span, t):
    c = col(th, "guard_color", W.BRASS)
    parts = [W.box(0, y, 0, span * 0.62, t * 1.6, t * 1.7, c)]
    for side in (-1, 1):
        parts.append(torus((side * span * 0.34, y, 0), 0.1, 0.03, c, axis="z", n=12))
        parts.append(torus((side * span * 0.34, y, 0), 0.1, 0.03, c, axis="x", n=12))
    return parts


GUARDS = {"wings": g_wings, "horns": g_horns, "crescent": g_crescent, "spikes": g_spikes, "crown": g_crown,
          "bones": g_bones, "antlers": g_antlers, "thorns": g_thorns, "holly": g_holly, "sunburst": g_sunburst,
          "laurel": g_laurel, "ribs": g_ribs, "anchor": g_anchor, "knot": g_knot}


# --------------------------------------------------------------------------
#  POMMELS: (theme, y_top, size) -> [bmesh]; the foot of a haft too
# --------------------------------------------------------------------------
def p_skull(th, y, s):
    bone = col(th, "bone_color", C(222, 210, 182))
    return skull((0, y - s * 0.6, 0), s * 1.1, bone, eyes=W.GLOW if th.get("glow") else None)


def p_jewel(th, y, s):
    c = col(th, "guard_color", W.GOLD)
    parts = [W.lathe([(0.0, y - s * 0.3), (s * 0.3, y - s * 0.22), (s * 0.18, y)], c, n=12)]
    parts.append(W.sphere((0, y - s * 0.62, 0), s * 0.36, W.GLOW if th.get("glow") else W.RED, u=12, v=8))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        parts.append(W.tube([(math.cos(a) * s * 0.22, y - s * 0.25, math.sin(a) * s * 0.22), (math.cos(a) * s * 0.34, y - s * 0.62, math.sin(a) * s * 0.34),
                             (math.cos(a) * s * 0.16, y - s * 0.95, math.sin(a) * s * 0.16)], 0.025, c, n=5))
    return parts


def p_claw(th, y, s):
    c = col(th, "guard_color", W.DARKSTEEL)
    parts = [W.sphere((0, y - s * 0.6, 0), s * 0.32, W.GLOW if th.get("glow") else col(th, "stone_color", C(40, 40, 46)), u=12, v=8)]
    for k in range(3):
        a = 2 * math.pi * k / 3
        parts.append(W.tube([(0, y, 0), (math.cos(a) * s * 0.36, y - s * 0.45, math.sin(a) * s * 0.36), (math.cos(a) * s * 0.18, y - s * 0.92, math.sin(a) * s * 0.18)],
                            [0.05, 0.035, 0.008], c, n=6))
    return parts


def p_spike(th, y, s):
    c = col(th, "guard_color", W.DARKSTEEL)
    return [W.cylinder(y - s * 0.2, y, s * 0.3, s * 0.25, c, n=8), W._pyr((0, y - s * 0.2, 0), (0, y - s * 1.2, 0), s * 0.22, c)]


def p_pumpkin(th, y, s):
    orange = C(232, 118, 30)
    parts = []
    for k in range(8):
        a = 2 * math.pi * k / 8
        parts.append(W.sphere((math.cos(a) * s * 0.2, y - s * 0.6, math.sin(a) * s * 0.2), s * 0.36, orange, u=10, v=8, scale=(0.75, 0.9, 0.75)))
    parts.append(W.cylinder(y - s * 0.22, y, s * 0.08, s * 0.06, C(70, 90, 40), n=6))
    g = W.GLOW if th.get("glow") else W.BLACKIRON
    for sx in (-1, 1):
        parts.append(W._pyr((sx * s * 0.16, y - s * 0.52, s * 0.5), (sx * s * 0.16, y - s * 0.46, s * 0.58), s * 0.09, g))
    parts.append(W.box(0, y - s * 0.8, s * 0.5, s * 0.36, s * 0.07, s * 0.08, g))
    return parts


def p_dragon(th, y, s):
    c = col(th, "guard_color", W.GOLD)
    parts = [W.tube([(0, y, 0), (0, y - s * 0.5, s * 0.1), (0, y - s * 0.9, s * 0.45), (0, y - s * 1.0, s * 0.85)], [s * 0.26, s * 0.28, s * 0.2, s * 0.08], c, n=8)]
    for sx in (-1, 1):
        parts.append(W.tube([(sx * s * 0.15, y - s * 0.75, s * 0.2), (sx * s * 0.35, y - s * 0.55, -s * 0.2), (sx * s * 0.3, y - s * 0.3, -s * 0.5)], [s * 0.07, s * 0.04, 0.006], c, n=6))
        parts.append(W.sphere((sx * s * 0.13, y - s * 0.9, s * 0.52), s * 0.06, W.GLOW if th.get("glow") else W.RED, u=6, v=4))
    return parts


def p_star(th, y, s):
    pts = []
    for k in range(10):
        a = math.pi / 2 + 2 * math.pi * k / 10
        r = s * 0.62 if k % 2 == 0 else s * 0.26
        pts.append((math.cos(a) * r, y - s * 0.65 + math.sin(a) * r))
    return [W.plate(pts, W.GLOW if th.get("glow") else W.GOLD, t=0.08), W.cylinder(y - s * 0.12, y, s * 0.12, s * 0.12, W.GOLD, n=8)]


def p_ring(th, y, s):
    c = col(th, "guard_color", W.STEEL)
    return [torus((0, y - s * 0.55, 0), s * 0.4, s * 0.09, c, axis="z", n=16), W.cylinder(y - s * 0.16, y, s * 0.12, s * 0.12, c, n=8)]


def p_lantern(th, y, s):
    c = col(th, "guard_color", W.BLACKIRON)
    parts = [W.box(0, y - s * 0.6, 0, s * 0.42, s * 0.6, s * 0.42, W.GLOW if th.get("glow") else C(255, 190, 90))]
    for dx in (-1, 1):
        for dz in (-1, 1):
            parts.append(W.box(dx * s * 0.22, y - s * 0.6, dz * s * 0.22, s * 0.06, s * 0.66, s * 0.06, c))
    parts.append(W._pyr((0, y - s * 0.28, 0), (0, y, 0), s * 0.3, c))
    parts.append(W.box(0, y - s * 0.94, 0, s * 0.5, s * 0.08, s * 0.5, c))
    return parts


def p_acorn(th, y, s):
    return [W.sphere((0, y - s * 0.7, 0), s * 0.34, C(150, 100, 50), u=10, v=8, scale=(1, 1.25, 1)),
            W.sphere((0, y - s * 0.38, 0), s * 0.38, C(96, 70, 40), u=10, v=6, scale=(1, 0.6, 1))]


POMMELS = {"skull": p_skull, "jewel": p_jewel, "claw": p_claw, "spike": p_spike, "pumpkin": p_pumpkin,
           "dragon": p_dragon, "star": p_star, "ring": p_ring, "lantern": p_lantern, "acorn": p_acorn}


# --------------------------------------------------------------------------
#  GRIPS: (theme, length, r, y) -> [bmesh] or None
# --------------------------------------------------------------------------
def wrap_grip(th, length, r, y):
    kind = th.get("wrap")
    y0, y1 = y - length / 2, y + length / 2
    if kind == "bone":
        bone = col(th, "bone_color", C(222, 210, 182))
        parts = [W.cylinder(y0, y1, r * 0.7, r * 0.7, C(120, 100, 80), n=10)]
        n = max(3, int(length / 0.14))
        for k in range(n):
            yy = y0 + length * (k + 0.5) / n
            parts.append(W.sphere((0, yy, 0), r * 1.15, bone, u=10, v=6, scale=(1, 0.5, 1)))
            for sx in (-1, 1):
                parts.append(W._pyr((sx * r, yy, 0), (sx * r * 1.7, yy - 0.03, 0), 0.025, bone))
        return parts
    if kind == "fur":
        fur = col(th, "fur_color", C(110, 82, 58))
        parts = [W.cylinder(y0, y1, r, r, W.LEATHER, n=10)]
        for k in range(int(length / 0.05)):
            yy = y0 + 0.03 + k * 0.05
            a = k * 2.4
            parts.append(W.sphere((math.cos(a) * r * 0.5, yy, math.sin(a) * r * 0.5), r * 0.75, fur, u=6, v=4, scale=(1, 0.55, 1)))
        return parts
    if kind in ("rope", "gilt", "candy", "red"):
        a, b = {"rope": (W.ROPE, W.DARKWOOD), "gilt": (W.GOLD, W.DARKLEATHER), "candy": (C(240, 236, 230), C(200, 30, 40)),
                "red": (C(150, 24, 30), W.GOLD)}[kind]
        parts = [W.cylinder(y0, y1, r, r * 0.94, b, n=14)]
        turns = max(3, int(length / 0.12))
        pts = []
        for k in range(turns * 10 + 1):
            f = k / (turns * 10)
            ang = 2 * math.pi * turns * f
            pts.append(((r + 0.015) * math.cos(ang), y0 + 0.02 + (length - 0.04) * f, (r + 0.015) * math.sin(ang)))
        parts.append(W.tube(pts, 0.04 if kind == "candy" else 0.028, a, n=5))
        return parts
    return None


# --------------------------------------------------------------------------
#  ORNAMENTS: extra geometry on the grip region
# --------------------------------------------------------------------------
def ornaments(th, A):
    parts = []
    for o in th.get("ornaments", ()):
        if o == "serpent":
            c = col(th, "serpent_color", C(60, 120, 60))
            y0, y1 = A["grip0"] - 0.05, A["guard"] + min(0.55, 0.16 * A.get("blade_len", 3))
            pts, rs = [], []
            turns = 3.2
            for k in range(60):
                f = k / 59
                a = 2 * math.pi * turns * f
                rr = A["r"] + 0.09 + 0.03 * math.sin(f * math.pi)
                pts.append((rr * math.cos(a), y0 + (y1 - y0) * f, rr * math.sin(a)))
                rs.append(0.012 + 0.05 * math.sin(math.pi * min(1.0, f * 1.15)) ** 0.6)
            parts.append(W.tube(pts, rs, c, n=6))
            hx, hy, hz = pts[-1]
            parts.append(W.sphere((hx, hy + 0.05, hz), 0.085, c, u=8, v=6, scale=(1, 0.8, 1.4)))
            for sx in (-1, 1):
                parts.append(W.sphere((hx + sx * 0.045, hy + 0.09, hz + 0.06), 0.022, W.GLOW if th.get("glow") else W.RED, u=6, v=4))
                parts.append(W.cone((hx + sx * 0.03, hy + 0.02, hz + 0.1), (hx + sx * 0.03, hy - 0.06, hz + 0.12), 0.012, W.BRIGHT, n=4))
        elif o == "chains":
            c = col(th, "chain_color", W.BLACKIRON)
            for side in (-1, 1):
                parts += chain((side * 0.32, A["guard"] - 0.05, 0.0), 5, 0.1, c)
                parts.append(W.sphere((side * 0.32, A["guard"] - 0.85, 0), 0.08, c, u=8, v=6))
                for k in range(6):
                    a = 2 * math.pi * k / 6
                    b = (side * 0.32, A["guard"] - 0.85, 0)
                    parts.append(W._pyr(b, (b[0] + math.cos(a) * 0.15, b[1] + math.sin(a) * 0.15, 0), 0.03, c))
        elif o == "candles":
            wax = C(236, 228, 206)
            for k, x in enumerate((-0.24, 0.2)):
                y = A["guard"] + 0.05
                h = 0.22 + 0.06 * k
                parts.append(moved(W.cylinder(y, y + h, 0.045, 0.045, wax, n=8), x, 0, 0))
                parts.append(W.sphere((x, y + h + 0.06, 0), 0.035, W.GLOW, u=6, v=4, scale=(0.8, 1.5, 0.8)))
                for d in range(3):
                    parts.append(W.tube([(x + 0.04 * (d - 1), y, 0.04), (x + 0.04 * (d - 1), y - 0.12 - 0.07 * d, 0.05)], [0.022, 0.008], wax, n=4))
        elif o == "feathers":
            c = col(th, "feather_color", C(30, 30, 36))
            for k in range(3):
                a = math.radians(-90 + (k - 1) * 18)
                parts.append(leaf(0, A["foot"] - 0.1, 0.55, 0.13, a, c, t=0.02, cz=0.03 * (k - 1)))
        elif o == "web":
            silk = C(230, 230, 236)
            cx, cy = 0.0, A["guard"] + 0.4
            for k in range(6):
                a = 2 * math.pi * k / 6
                parts.append(W.tube([(cx, cy, 0.09), (cx + math.cos(a) * 0.3, cy + math.sin(a) * 0.3, 0.09)], 0.008, silk, n=4))
            for ring in (0.1, 0.19, 0.28):
                pts = [(cx + math.cos(2 * math.pi * k / 6) * ring, cy + math.sin(2 * math.pi * k / 6) * ring, 0.09) for k in range(7)]
                parts.append(W.tube(pts, 0.007, silk, n=4, caps=False))
        elif o == "tassel":
            parts += W.tassel(A["foot"] - 0.02, 0.06, col(th, "tassel_color", W.RED))
        elif o == "thornwrap":
            c = col(th, "guard_color", C(70, 52, 40))
            for k in range(14):
                f = k / 13
                a = f * 2 * math.pi * 3
                y = A["grip0"] + (A["grip1"] - A["grip0"]) * f
                b = (math.cos(a) * (A["r"] + 0.01), y, math.sin(a) * (A["r"] + 0.01))
                parts.append(W.cone(b, (math.cos(a) * (A["r"] + 0.12), y + 0.04, math.sin(a) * (A["r"] + 0.12)), 0.022, c, n=4))
        elif o == "ribbon":
            c = col(th, "ribbon_color", W.RED)
            y = A["guard"] - 0.04
            parts.append(W.tube([(0.1, y, 0.05), (0.3, y - 0.3, 0.12), (0.22, y - 0.7, 0.05), (0.32, y - 1.0, 0.1)], 0.03, c, n=4))
    return parts


# --------------------------------------------------------------------------
#  PATTERNS painted into the steel: (pos, a, b) -> colour
# --------------------------------------------------------------------------
def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def pat(kind, p, a, b, f, theme):
    x, y, z = p
    if kind == "damascus":
        t = 0.5 + 0.5 * math.sin(y * 26 + 3.2 * math.sin(x * 15 + y * 3) + 1.6 * math.sin(y * 7.0 + z * 9))
        return lerp(a, b, t ** 1.6)
    if kind == "rust":
        # soft stains that gather and fade, mostly bare steel (low frequencies only: the colour lives on
        # the vertices, and finer noise aliases into hard blotches)
        n = noise.noise(Vector((x * 4, y * 3, z * 4))) + 0.35 * noise.noise(Vector((x * 9, y * 8, z * 9)))
        t = max(0.0, min(1.0, (n - 0.02) / 0.5))
        return lerp(a, b, t * t * (3 - 2 * t) * 0.85)
    if kind == "blued":
        return lerp(a, b, f)
    if kind == "frost":
        n = noise.noise(Vector((x * 9, y * 9, z * 9)))
        return lerp(a, b, f * 0.8 + n * 0.35)
    if kind == "scales":
        u, v = x * 13, y * 9
        t = abs(math.sin(u + (int(v) % 2) * 1.57)) * abs(math.sin(v * 1.57))
        return lerp(a, b, 1 - t)
    if kind == "stripes":
        t = math.sin((y + x * theme.get("twist", 1.4)) * theme.get("freq", 11))
        return a if t > 0 else b
    if kind == "stars":
        n = noise.noise(Vector((x * 30, y * 30, z * 30)))
        return b if n > 0.42 else a
    if kind == "filigree":
        t = math.sin(x * 34 + math.sin(y * 9) * 3) * math.sin(y * 21 + math.cos(x * 12) * 2)
        return b if t > 0.32 else a
    if kind == "embers":
        n = noise.noise(Vector((x * 7, y * 5, z * 7)))
        return lerp(a, b, max(0.0, n * 2.2 - 0.2) + f * 0.3)
    if kind == "bark":
        t = 0.5 + 0.5 * math.sin(x * 40 + noise.noise(Vector((x * 3, y * 12, z * 3))) * 6)
        return lerp(a, b, t)
    if kind == "knotwork":
        t = math.sin(x * 22 + y * 22) * math.sin(x * 22 - y * 22)
        return b if abs(t) > 0.7 else a
    if kind == "waves":
        t = math.sin(y * 18 + math.sin(x * 10) * 2.5)
        return lerp(a, b, 0.5 + 0.5 * t)
    if kind == "camo":
        n = noise.noise(Vector((x * 4, y * 4, z * 4)))
        return a if n > 0.1 else (b if n < -0.15 else lerp(a, b, 0.5))
    if kind == "sheen":
        t = 0.5 + 0.5 * math.sin(y * 3.2 - x * 4)
        return lerp(a, b, t * 0.6)
    return a


# --------------------------------------------------------------------------
#  GLOW INLAYS raycast onto the blade's flats
# --------------------------------------------------------------------------
RUNES = [  # strokes in a unit cell (x 0..1, y 0..1)
    [((0.2, 0), (0.2, 1)), ((0.2, 1), (0.8, 0.7)), ((0.2, 0.55), (0.8, 0.8))],
    [((0.3, 0), (0.3, 1)), ((0.3, 1), (0.8, 0.75)), ((0.8, 0.75), (0.3, 0.5)), ((0.3, 0.5), (0.8, 0))],
    [((0.5, 0), (0.5, 1)), ((0.5, 0.7), (0.15, 1)), ((0.5, 0.7), (0.85, 1))],
    [((0.5, 0), (0.5, 1)), ((0.5, 1), (0.15, 0.7)), ((0.5, 1), (0.85, 0.7))],
    [((0.5, 0), (0.15, 0.5)), ((0.15, 0.5), (0.5, 1)), ((0.5, 1), (0.85, 0.5)), ((0.85, 0.5), (0.5, 0))],
    [((0.25, 0), (0.25, 1)), ((0.75, 0), (0.75, 1)), ((0.25, 0.65), (0.75, 0.35))],
    [((0.2, 1), (0.8, 0)), ((0.2, 0), (0.8, 1))],
    [((0.3, 0), (0.3, 1)), ((0.3, 0.35), (0.75, 0.6)), ((0.3, 0.75), (0.75, 1.0))],
]


def seg_box(a, b, w, z, sz, color, th_z=0.022):
    ax, ay = a; bx, by = b
    L = math.hypot(bx - ax, by - ay)
    if L < 1e-4:
        return None
    ang = math.atan2(by - ay, bx - ax)
    return W.box((ax + bx) / 2, (ay + by) / 2, z + sz * th_z / 2, L + w * 0.6, w, th_z, color, rot_z=ang)


class Flats:
    """where the blade's flat faces are, by raycasting from ±Z"""
    def __init__(self, bm):
        self.bvh = BVHTree.FromBMesh(bm)
        xs = [v.co.x for v in bm.verts]; ys = [v.co.y for v in bm.verts]
        self.lo, self.hi = Vector((min(xs), min(ys), 0)), Vector((max(xs), max(ys), 0))

    def at(self, x, y, side):
        hit = self.bvh.ray_cast(Vector((x, y, side * 6.0)), Vector((0, 0, -side)))
        if hit[0] is None or abs(hit[1].z) < 0.55:   # (a loft's normals may face inward)
            return None
        return hit[0].z

    def row(self, y, side):
        xs = []
        n = 24
        for k in range(n + 1):
            x = self.lo.x + (self.hi.x - self.lo.x) * k / n
            if self.at(x, y, side) is not None:
                xs.append(x)
        if not xs:
            return None
        return min(xs), max(xs)


def inlays(th, blade_bm, A):
    g = th.get("glow")
    if not g:
        return []
    F = Flats(blade_bm)
    kinds = g.get("kinds", ())
    parts = []
    y0 = max(F.lo.y, A["guard"] + 0.12) if A["kind"] == "sword" else F.lo.y + 0.05
    y1 = F.hi.y - (F.hi.y - y0) * 0.22
    span = max(0.1, y1 - y0)
    import random
    rnd = random.Random(hash(th["id"]) & 0xffff)
    for side in (1, -1):
        if "core" in kinds or "runes" in kinds:
            step = 0.06 if "core" in kinds else 0.34
            y = y0
            k = 0
            while y < y1:
                r = F.row(y, side)
                if r and r[1] - r[0] > 0.06:
                    xc = (r[0] + r[1]) / 2
                    z = F.at(xc, y, side)
                    if z is not None:
                        if "core" in kinds:
                            w = min(0.05, (r[1] - r[0]) * 0.22)
                            b = seg_box((xc, y), (xc, y + step), w, z, side, W.GLOW)
                            if b: parts.append(b)
                        else:
                            cell = min(0.2, (r[1] - r[0]) * 0.55)
                            rune = RUNES[(k * 5 + (1 if side > 0 else 3)) % len(RUNES)]
                            for (ax, ay), (bx, by) in rune:
                                b = seg_box((xc - cell / 2 + ax * cell, y + ay * cell * 1.4), (xc - cell / 2 + bx * cell, y + by * cell * 1.4), cell * 0.16, z, side, W.GLOW)
                                if b: parts.append(b)
                            k += 1
                y += step
        if "cracks" in kinds or "veins" in kinds:
            veins = "veins" in kinds
            count = 5 if veins else 9
            for c in range(count):
                fy = y0 + span * (c + rnd.random() * 0.5) / count
                r = F.row(fy, side)
                if not r:
                    continue
                x = r[0] + (r[1] - r[0]) * (0.5 if veins else rnd.random())
                y = fy
                ang = math.pi / 2 if veins else rnd.uniform(0, math.pi * 2)
                for s in range(9 if veins else 6):
                    L = 0.07 if veins else 0.05
                    ang += rnd.uniform(-1.0, 1.0) * (0.9 if veins else 0.7)
                    if veins:
                        ang = max(math.pi / 2 - 0.8, min(math.pi / 2 + 0.8, ang))
                    nx, ny = x + math.cos(ang) * L, y + math.sin(ang) * L
                    z = F.at((x + nx) / 2, (y + ny) / 2, side)
                    if z is None:
                        break
                    b = seg_box((x, y), (nx, ny), 0.022 if veins else 0.018, z, side, W.GLOW)
                    if b: parts.append(b)
                    x, y = nx, ny
        if "stars" in kinds:
            for c in range(14):
                yy = y0 + span * rnd.random()
                r = F.row(yy, side)
                if not r:
                    continue
                xx = r[0] + (r[1] - r[0]) * rnd.uniform(0.15, 0.85)
                z = F.at(xx, yy, side)
                if z is None:
                    continue
                s = rnd.uniform(0.018, 0.034)
                parts.append(W.box(xx, yy, z + side * 0.008, s, s * 3, 0.016, W.GLOW, rot_z=0.0))
                parts.append(W.box(xx, yy, z + side * 0.008, s * 3, s, 0.016, W.GLOW, rot_z=0.0))
    if "halo" in kinds and A["kind"] == "sword":
        parts.append(torus((0, A["guard"] + 0.55, 0), 0.42, 0.028, W.GLOW, axis="y", n=24, m=6))
    if "crystals" in kinds:
        for k in range(7):
            a = 2 * math.pi * k / 7 + 0.3
            base = (math.cos(a) * 0.12, A["guard"] + 0.05, math.sin(a) * 0.08)
            tip = (math.cos(a) * 0.38, A["guard"] + 0.2 + 0.1 * (k % 3), math.sin(a) * 0.22)
            parts.append(W._pyr(base, tip, 0.05 + 0.01 * (k % 2), W.GLOW, rot=k))
    return parts


# --------------------------------------------------------------------------
#  SILHOUETTES: a theme's own blade (swords), head (on a haft) and haft, so a
#  skin is a different weapon to look at, not the same one painted
# --------------------------------------------------------------------------
import random as _random


def _accent(th):
    """shards, rays and cores: the theme's glow if it has one, else bright steel"""
    return W.GLOW if th.get("glow") else W.EDGE


def _plain(fn):
    """build with W.blade's own path (no theme silhouette inside a silhouette)"""
    was = W._HOOKING[0]
    W._HOOKING[0] = True
    try:
        return fn()
    finally:
        W._HOOKING[0] = was


def _body(a):
    return a["length"] * (1 - a["tip"])


def _width(a, f):
    return a["w0"] + (a["w1"] - a["w0"]) * f


# ---- BLADES: (theme, args) -> bmesh. args are W.blade's own (y0, length, w0, w1, t0, t1, tip, kind...)
def bs_flame(th, a):
    k = dict(a)
    k["waves"] = 4 if a["length"] < 1.6 else (6 if a["length"] < 3 else 8)
    k["wave_amp"] = 0.26 if a["kind"] == "double" else 0.17
    k["profile"] = lambda f: 1.0 + 0.14 * math.sin(math.pi * min(1.0, f))
    parts = [W.blade(**k)]
    c = _accent(th)
    s = min(1.0, a["length"] / 3.0)
    sides = (-1, 1) if a["kind"] == "double" else (1,)
    for side in sides:
        for i in range(3):
            L = (0.36 - 0.08 * i) * s + 0.1
            ang = math.radians(90 - side * (24 + 14 * i))
            parts.append(leaf(side * a["w0"] * 0.42, a["y0"] + 0.03 + i * 0.1 * s, L, 0.1, ang, c, t=0.03))
    return W.merge(*parts)


def bs_leaf(th, a):
    k = dict(a)
    k["profile"] = lambda f: 1.0 + 0.55 * math.sin(math.pi * min(1.0, f * 0.95)) ** 1.6
    k["tip"] = min(a["tip"], 0.25)
    k["fuller"] = a["fuller"] * 0.6
    return W.blade(**k)


def bs_broad(th, a):
    k = dict(a)
    k["w0"] = a["w0"] * 1.28
    k["w1"] = max(a["w1"] * 1.7, a["w0"] * 1.12)
    k["tip"] = 0.13
    k["t0"] = a["t0"] * 1.05
    return W.blade(**k)


def bs_crystal(th, a):
    k = dict(a)
    k["w0"], k["w1"] = a["w0"] * 0.82, a["w1"] * 0.75
    k["fuller"] = 0.0
    k["tip"] = max(a["tip"], 0.32)
    k["profile"] = lambda f: 1.0 + 0.2 * (0.5 - abs(((f * 6) % 1.0) - 0.5))
    parts = [W.blade(**k)]
    c = _accent(th)
    rnd = _random.Random(hash(th["id"]) & 0xfff)
    body = _body(k)
    n = max(3, int(a["length"] / 0.4))
    for i in range(n):
        f = (i + 0.7) / (n + 0.7)
        if f > 0.85:
            break
        y = a["y0"] + body * f
        w = _width(k, f)
        side = (1 if i % 2 == 0 else -1) if a["kind"] == "double" else 1
        base = (side * w * 0.4, y, 0.0)
        size = (0.18 + 0.16 * rnd.random()) * min(1.2, 0.5 + a["length"] / 4)
        tip = (side * (w * 0.4 + size * 0.85), y + size * 0.85, 0.0)
        parts.append(W._pyr(base, tip, 0.05 + 0.03 * rnd.random(), c, rnd.random()))
    for j in range(5):
        ang = 2 * math.pi * j / 5 + 0.4
        b0 = (math.cos(ang) * a["w0"] * 0.22, a["y0"] + 0.02, math.sin(ang) * 0.05)
        t0 = (math.cos(ang) * a["w0"] * 0.8, a["y0"] + 0.26 + 0.07 * (j % 2), math.sin(ang) * 0.13)
        parts.append(W._pyr(b0, t0, 0.05, c, j))
    return W.merge(*parts)


def bs_bone(th, a):
    k = dict(a)
    k["fuller"] = 0.0
    k["w0"], k["w1"] = a["w0"] * 1.18, a["w1"] * 1.25
    teeth = max(5, int(a["length"] / 0.36))
    k["profile"] = lambda f: (1.0 - 0.32 * ((f * teeth) % 1.0)) if f < 0.92 else 0.72
    parts = [W.blade(**k)]
    body = _body(a)
    n = max(4, int(body / 0.28))
    for i in range(n):
        f = (i + 0.5) / n * 0.95
        y = a["y0"] + body * f
        t = a["t0"] + (a["t1"] - a["t0"]) * f
        xc = 0.0 if a["kind"] == "double" else (a["w0"] - _width(a, f)) / 2 - a["curve"] * f * f
        for z in (1, -1):
            parts.append(W.sphere((xc, y, z * t * 0.42), t * 0.62 + 0.02, W.BRIGHT, u=8, v=5, scale=(1.6, 0.8, 0.75)))
    return W.merge(*parts)


def bs_fang(th, a):
    k = dict(a)
    k["kind"] = "single"
    k["curve"] = a["curve"] + a["length"] * 0.07
    k["belly"] = a["w0"] * 0.25
    k["tip"] = 0.34
    k["fuller"] = 0.0
    parts = [W.blade(**k)]
    body = a["length"] * (1 - 0.34)
    for i in range(1, 6):
        f = i / 7
        y = a["y0"] + body * f
        x = a["w0"] / 2 - k["curve"] * f * f
        parts.append(W._pyr((x - 0.02, y, 0.0), (x + 0.12, y + 0.1, 0.0), 0.03, W.EDGE))
    return W.merge(*parts)


def bs_twin(th, a):
    if a["kind"] != "double":
        return bs_tiered(th, a)
    L, w0 = a["length"], a["w0"]
    parts = []
    for side in (-1, 1):
        k = dict(a)
        k.update(w0=w0 * 0.34, w1=a["w1"] * 0.34, length=L * 0.9, tip=0.22, fuller=0.0, t0=a["t0"] * 0.85, t1=a["t1"] * 0.85)
        k["xoff"] = (lambda s: (lambda f: s * w0 * 0.44 * (1 - 0.62 * min(1.0, f) ** 1.3)))(side)
        parts.append(W.blade(**k))
    pk = dict(a)
    pk.update(y0=a["y0"] + L * 0.72, length=L * 0.28, w0=w0 * 0.55, w1=w0 * 0.5, tip=0.7, fuller=0.0)
    parts.append(W.blade(**pk))
    core = W.GLOW if th.get("glow") else W.FULLER
    parts.append(W.box(0, a["y0"] + L * 0.38, 0, w0 * 0.16, L * 0.66, a["t0"] * 0.35, core))
    parts.append(W.box(0, a["y0"] + 0.05, 0, w0 * 1.05, 0.12, a["t0"] * 1.1, W.STEEL))
    return W.merge(*parts)


def bs_lightning(th, a):
    amp = a["w0"] * 0.34
    k = dict(a)
    k["fuller"] = 0.0
    k["xoff"] = lambda f: amp * (2 * abs(2 * ((min(f, 1.0) * 3.5) % 1.0) - 1) - 1) * (0.35 + 0.65 * min(1.0, f))
    k["profile"] = lambda f: 0.92
    return W.blade(**k)


def bs_serpent(th, a):
    amp = a["w0"] * 0.45
    k = dict(a)
    k["xoff"] = lambda f: amp * math.sin(2 * math.pi * 1.25 * min(f, 1.15)) * min(1.0, f * 1.6)
    k["profile"] = lambda f: 0.92
    return W.blade(**k)


def bs_sun(th, a):
    parts = [bs_broad(th, a)]
    y = a["y0"] + 0.12
    for side in (-1, 1):
        for i in range(5):
            ang = math.radians(12 + i * 30)
            L = 0.44 - 0.05 * abs(i - 2)
            b = (side * a["w0"] * 0.5, y, 0.0)
            parts.append(W._pyr(b, (b[0] + side * math.cos(ang) * L, y + math.sin(ang) * L, 0.0), 0.05, W.GOLD))
    parts.append(W.disc((0, y, 0), a["w0"] * 0.62, a["t0"] * 1.6, W.GOLD, axis="z"))
    if th.get("glow"):
        parts.append(W.disc((0, y, 0), a["w0"] * 0.32, a["t0"] * 2.0, W.GLOW, axis="z"))
    return W.merge(*parts)


def bs_tiered(th, a):
    k = dict(a)
    k["profile"] = lambda f: 1.0 if f < 0.34 else (0.84 if f < 0.67 else 0.7)
    parts = [W.blade(**k)]
    body = _body(a)
    for fs in (0.34, 0.67):
        y = a["y0"] + body * fs
        w = _width(a, fs)
        if a["kind"] == "double":
            for side in (-1, 1):
                parts.append(W._pyr((side * w * 0.4, y - 0.02, 0.0), (side * (w * 0.5 + 0.15), y - 0.13, 0.0), 0.04, W.EDGE))
        else:
            x = a["w0"] / 2 - a["curve"] * fs * fs
            parts.append(W._pyr((x - 0.03, y - 0.02, 0.0), (x + 0.15, y - 0.13, 0.0), 0.04, W.EDGE))
    return W.merge(*parts)


def bs_forked(th, a):
    if a["kind"] != "double":
        return bs_fang(th, a)
    L = a["length"]
    k = dict(a)
    k.update(length=L * 0.76, tip=0.03)
    parts = [W.blade(**k)]
    off = a["w1"] * 0.27
    for side in (-1, 1):
        pk = dict(a)
        pk.update(y0=a["y0"] + L * 0.72, length=L * 0.3, w0=a["w1"] * 0.46, w1=a["w1"] * 0.36, tip=0.5, fuller=0.0, t0=a["t1"] * 1.1, t1=a["t1"])
        pk["xoff"] = (lambda s: (lambda f: s * (off + 0.09 * f * f)))(side)
        parts.append(W.blade(**pk))
    return W.merge(*parts)


def bs_obsidian(th, a):
    k = dict(a)
    k["fuller"] = 0.0
    k["profile"] = lambda f: 1.0 - 0.2 * abs(math.sin(min(f, 1.0) * math.pi * 7)) ** 0.7
    k["t0"] = a["t0"] * 1.15
    return W.blade(**k)


BLADES = {"flame": bs_flame, "leaf": bs_leaf, "broad": bs_broad, "crystal": bs_crystal, "bone": bs_bone, "fang": bs_fang,
          "twin": bs_twin, "lightning": bs_lightning, "serpent": bs_serpent, "sun": bs_sun, "tiered": bs_tiered,
          "forked": bs_forked, "obsidian": bs_obsidian}


def blade_hook(th):
    fn = BLADES.get(th.get("blade"))
    return (lambda a: fn(th, a)) if fn else None


# ---- HEADS on a haft: the spear's point, the axe's bit, the mace's head
def _spear_socket(y):
    return [W.cylinder(y - 0.55, y + 0.04, 0.13, 0.1, W.DARKSTEEL, n=12), W.cylinder(y - 0.58, y - 0.48, 0.15, 0.15, W.DARKSTEEL, n=12),
            W.cylinder(y - 0.2, y - 0.14, 0.13, 0.13, W.DARKSTEEL, n=12)]


def hd_spear(style, th, head):
    y = 3.45
    out = _spear_socket(y)
    c = _accent(th)
    if style == "broad":
        out.append(W.blade(y, 1.7, 0.6, 0.5, 0.11, 0.05, tip=0.5, fuller=0.25, fuller_end=0.5,
                           profile=lambda f: 1 + 0.35 * math.sin(math.pi * min(1.0, f)) ** 1.4))
    elif style == "flame":
        out.append(W.blade(y, 1.8, 0.46, 0.34, 0.1, 0.05, tip=0.42, waves=3, wave_amp=0.36))
        for side in (-1, 1):
            for i in range(2):
                out.append(leaf(side * 0.14, y + 0.02 + i * 0.12, 0.34 - 0.08 * i, 0.09, math.radians(90 - side * (30 + 16 * i)), c, t=0.03))
    elif style == "winged":
        out.append(W.blade(y, 1.45, 0.4, 0.3, 0.1, 0.05, tip=0.5, fuller=0.3, fuller_end=0.5))
        for side in (-1, 1):
            out.append(leaf(side * 0.1, y - 0.02, 0.72, 0.2, math.radians(90 - side * 72), W.STEEL, t=0.05))
            out.append(leaf(side * 0.1, y - 0.12, 0.42, 0.13, math.radians(90 - side * 112), W.STEEL, t=0.045))
    elif style == "trident":
        out.append(W.blade(y + 0.2, 1.3, 0.22, 0.15, 0.08, 0.05, tip=0.45))
        out.append(W.box(0, y + 0.16, 0, 0.98, 0.11, 0.11, W.DARKSTEEL))
        for side in (-1, 1):
            pts = [(side * 0.46, y + 0.16, 0), (side * 0.52, y + 0.55, 0), (side * 0.48, y + 0.95, 0), (side * 0.4, y + 1.2, 0)]
            out.append(W.tube(pts, [0.055, 0.05, 0.04, 0.008], W.STEEL, n=6))
            out.append(W._pyr((side * 0.45, y + 1.0, 0), (side * 0.6, y + 0.82, 0), 0.035, W.STEEL))
    elif style == "crescent":
        out.append(W.blade(y + 0.4, 1.2, 0.28, 0.2, 0.09, 0.05, tip=0.6))
        pts, rs = [], []
        for k in range(15):
            f = k / 14
            ang = math.pi * f
            pts.append((-math.cos(ang) * 0.66, y + 0.55 - math.sin(ang) * 0.46, 0))
            rs.append(0.012 + 0.075 * math.sin(ang) ** 0.8)
        out.append(W.tube(pts, rs, W.STEEL, n=8))
    elif style == "crystal":
        rnd = _random.Random(hash(th["id"]) & 0xff)
        out.append(W._pyr((0, y, 0), (0, y + 1.75, 0), 0.17, c, 0.3))
        for k in range(6):
            ang = 2 * math.pi * k / 6 + rnd.random() * 0.4
            r0 = 0.06
            b = (math.cos(ang) * r0, y + 0.05, math.sin(ang) * r0)
            L = 0.6 + 0.4 * rnd.random()
            t = (math.cos(ang) * 0.32, y + L, math.sin(ang) * 0.22)
            out.append(W._pyr(b, t, 0.07, c, k))
    elif style == "bone":
        teeth = 6
        out.append(W.blade(y, 1.55, 0.42, 0.3, 0.12, 0.06, tip=0.38, profile=lambda f: (1.0 - 0.24 * ((f * teeth) % 1.0)) if f < 0.92 else 0.8,
                           color=W.BRIGHT))
        for i in range(4):
            out.append(W.sphere((0, y + 0.15 + i * 0.22, 0.06), 0.07, W.BRIGHT, u=8, v=5, scale=(1.4, 0.8, 0.7)))
            out.append(W.sphere((0, y + 0.15 + i * 0.22, -0.06), 0.07, W.BRIGHT, u=8, v=5, scale=(1.4, 0.8, 0.7)))
    elif style == "serpent":
        out.append(W.blade(y, 1.85, 0.32, 0.22, 0.09, 0.05, tip=0.35, xoff=lambda f: 0.13 * math.sin(2 * math.pi * 1.5 * min(f, 1.1)) * min(1.0, f * 2)))
    elif style == "sun":
        out.append(W.blade(y + 0.15, 1.5, 0.34, 0.26, 0.1, 0.05, tip=0.5))
        yy = y + 0.12
        out.append(W.disc((0, yy, 0), 0.26, 0.12, W.GOLD, axis="z"))
        if th.get("glow"):
            out.append(W.disc((0, yy, 0), 0.14, 0.16, W.GLOW, axis="z"))
        for k in range(10):
            ang = 2 * math.pi * k / 10
            L = 0.5 if k % 2 == 0 else 0.36
            out.append(W._pyr((math.cos(ang) * 0.22, yy + math.sin(ang) * 0.22, 0), (math.cos(ang) * L, yy + math.sin(ang) * L, 0), 0.05, W.GOLD))
    else:
        return head
    return out


AXES = {"WarAxe": dict(y=1.35, x0=0.1, top=0.36, reach=0.84, beard_tip=0.74, beard_x=0.5, t=0.15, belly=0.12, neck=0.32, horn=0.08, sr=0.13, sh=0.24),
        "BattleAxe": dict(y=2.2, x0=0.12, top=0.72, reach=1.12, beard_tip=0.66, beard_x=1.0, t=0.17, belly=0.2, neck=0.42, horn=0.1, sr=0.15, sh=0.3)}


def hd_axe(style, th, head, weapon):
    A = dict(AXES[weapon])
    y, sr, sh = A.pop("y"), A.pop("sr"), A.pop("sh")
    s = 1.0 if weapon == "WarAxe" else 1.3

    def bit(**over):
        k = dict(A)
        k.update(over)
        return W.axe(y, k["x0"], k["top"], k["reach"], k["beard_tip"], k["beard_x"], t=k["t"], belly=k["belly"], neck=k["neck"], horn=k["horn"])
    out = W.socket(y - sh, y + sh, sr)
    if style == "double":
        out.append(bit())
        out.append(W.turn(bit(), angle_y=math.pi))
        out.append(W._pyr((0, y + sh, 0), (0, y + sh + 0.4 * s, 0), 0.07, W.STEEL))
    elif style == "crescent":
        out.append(bit(top=A["top"] * 1.45, beard_tip=A["beard_tip"] * 1.3, belly=A["belly"] * 2.6 + 0.1, horn=0.15, reach=A["reach"] * 1.06))
        out.append(W.box(-0.17 * s, y, 0, 0.12 * s, 0.3 * s, 0.26 * s, W.DARKSTEEL))
    elif style == "bearded":
        out.append(bit(top=A["top"] * 0.7, beard_tip=A["beard_tip"] * 1.55, beard_x=A["beard_x"] * 0.55, belly=A["belly"] * 0.6))
        out.append(W.box(-0.17 * s, y, 0, 0.12 * s, 0.3 * s, 0.26 * s, W.DARKSTEEL))
    elif style == "broad":
        out.append(bit(top=A["top"] * 1.3, beard_tip=A["beard_tip"] * 1.3, reach=A["reach"] * 1.25, belly=A["belly"] * 0.5))
        out.append(W.box(-0.2 * s, y, 0, 0.16 * s, 0.34 * s, 0.28 * s, W.DARKSTEEL))
    elif style == "dragon":
        big = dict(top=A["top"] * 1.35, beard_tip=A["beard_tip"] * 1.25, belly=A["belly"] * 2.2 + 0.08, horn=0.16)
        out.append(bit(**big))
        out.append(W.turn(bit(**big), angle_y=math.pi))
        c = _accent(th)
        for k in range(4):
            out.append(W._pyr((0, y + sh - 0.05, 0), (math.cos(k * math.pi / 2) * 0.16 * s, y + sh + (0.3 + 0.12 * (k % 2)) * s, math.sin(k * math.pi / 2) * 0.16 * s), 0.05, W.STEEL, k))
        out.append(W._pyr((0, y + sh, 0), (0, y + sh + 0.6 * s, 0), 0.08, c))
    else:
        return head
    return out


BLUNTS = {"Mace": (1.62, 0.4), "MorningStar": (1.78, 0.38), "Maul": (2.55, 0.48), "Hammer": (1.55, 0.34)}


def hd_blunt(style, th, head, weapon, r):
    cy, s = BLUNTS[weapon]
    c = _accent(th)
    out = [W.cylinder(cy - s * 1.15, cy - s * 0.55, r + 0.05, r + 0.04, W.DARKSTEEL, n=12)]
    if style == "spiked":
        out.append(W.sphere((0, cy, 0), s * 0.8, W.DARKSTEEL, u=16, v=10))
        for ring_y, n, lift in ((0.0, 9, 0.0), (0.45, 7, 0.65), (-0.45, 7, -0.65)):
            for k in range(n):
                ang = 2 * math.pi * k / n + (0.35 if lift else 0)
                d = Vector((math.cos(ang), lift, math.sin(ang))).normalized()
                base = Vector((0, cy, 0)) + d * s * 0.72
                out.append(W.cone(tuple(base), tuple(base + d * s * 0.62), s * 0.15, W.STEEL, n=6))
        out.append(W.cone((0, cy + s * 0.72, 0), (0, cy + s * 1.5, 0), s * 0.17, W.STEEL, n=6))
    elif style == "skull":
        out += skull((0, cy, 0), s * 1.7, W.BRIGHT, eyes=W.GLOW if th.get("glow") else None)
        for sx in (-1, 1):
            out.append(W.tube([(sx * s * 0.6, cy + s * 0.5, 0), (sx * s * 1.0, cy + s * 0.75, -s * 0.1), (sx * s * 1.05, cy + s * 1.2, -s * 0.2)],
                              [s * 0.16, s * 0.1, 0.008], W.DARKSTEEL, n=6))
    elif style == "crystal":
        rnd = _random.Random(hash(th["id"]) & 0xfff)
        out.append(W._pyr((0, cy - s * 0.4, 0), (0, cy + s * 1.5, 0), s * 0.32, c, 0.2))
        for k in range(8):
            ang = 2 * math.pi * k / 8 + rnd.random() * 0.3
            lift = 0.2 + 0.6 * rnd.random()
            d = Vector((math.cos(ang), lift, math.sin(ang))).normalized()
            base = Vector((0, cy, 0))
            out.append(W._pyr(tuple(base), tuple(base + d * s * (0.9 + 0.5 * rnd.random())), s * 0.2, c, k))
    elif style == "orb":
        core = W.GLOW if th.get("glow") else W.BRIGHT
        out.append(W.sphere((0, cy, 0), s * 0.55, core, u=16, v=12))
        for k in range(6):
            ang = 2 * math.pi * k / 6
            pts = []
            for j in range(9):
                g = j / 8
                a2 = math.pi * g
                pts.append((math.cos(ang) * math.sin(a2) * s * 0.78, cy - math.cos(a2) * s * 0.82, math.sin(ang) * math.sin(a2) * s * 0.78))
            out.append(W.tube(pts, s * 0.07, W.DARKSTEEL, n=5))
        out.append(W.cone((0, cy + s * 0.8, 0), (0, cy + s * 1.35, 0), s * 0.12, W.DARKSTEEL, n=6))
        out.append(W.cylinder(cy - s * 0.92, cy - s * 0.75, s * 0.3, s * 0.3, W.DARKSTEEL, n=12))
    elif style == "star":
        out.append(W.lathe([(0.0, cy - s * 0.85), (s * 0.3, cy - s * 0.78), (s * 0.4, cy - s * 0.3), (s * 0.4, cy + s * 0.3), (s * 0.3, cy + s * 0.8), (0.0, cy + s * 0.9)],
                           W.STEEL, n=12))
        for k in range(10):
            ang = 2 * math.pi * k / 10
            for dy in (-0.25, 0.3):
                b = (math.cos(ang) * s * 0.35, cy + dy * s, math.sin(ang) * s * 0.35)
                out.append(W._pyr(b, (math.cos(ang) * s * 1.05, cy + dy * s + 0.12 * s, math.sin(ang) * s * 1.05), s * 0.14, W.STEEL, ang))
        out.append(W._pyr((0, cy + s * 0.85, 0), (0, cy + s * 1.55, 0), s * 0.16, W.STEEL))
    elif style == "crown":
        out.append(W.lathe([(0.0, cy - s * 0.8), (s * 0.45, cy - s * 0.72), (s * 0.55, cy - s * 0.2), (s * 0.5, cy + s * 0.3), (0.0, cy + s * 0.35)], W.GOLD, n=16))
        for k in range(8):
            ang = 2 * math.pi * k / 8
            b = (math.cos(ang) * s * 0.48, cy + s * 0.25, math.sin(ang) * s * 0.48)
            t = (math.cos(ang) * s * 0.62, cy + s * 1.05, math.sin(ang) * s * 0.62)
            out.append(W._pyr(b, t, s * 0.13, W.GOLD, ang))
            out.append(W.sphere(t, s * 0.09, W.GLOW if th.get("glow") else W.RED, u=6, v=4))
        out.append(W.sphere((0, cy + s * 0.5, 0), s * 0.26, W.GLOW if th.get("glow") else W.RED, u=12, v=8))
    else:
        return head
    return out



# ---- POLEARMS: their own blades and points, in the theme's styles
def spear_top(style, th, y, L):
    """a point standing on y, L long, in a spear style (no socket): a polearm's top spike"""
    c = _accent(th)
    if style == "broad":
        return [W.blade(y, L * 1.05, 0.36, 0.3, 0.1, 0.05, tip=0.5, profile=lambda f: 1 + 0.35 * math.sin(math.pi * min(1.0, f)) ** 1.4)]
    if style == "flame":
        return [W.blade(y, L * 1.1, 0.3, 0.22, 0.09, 0.05, tip=0.42, waves=2, wave_amp=0.38)]
    if style == "winged":
        out = [W.blade(y, L, 0.26, 0.2, 0.09, 0.05, tip=0.5)]
        for side in (-1, 1):
            out.append(leaf(side * 0.06, y + 0.05, L * 0.4, 0.12, math.radians(90 - side * 70), W.STEEL, t=0.04))
        return out
    if style == "trident":
        out = [W.blade(y + 0.1, L * 0.9, 0.16, 0.12, 0.07, 0.05, tip=0.45), W.box(0, y + 0.08, 0, 0.56, 0.08, 0.08, W.DARKSTEEL)]
        for side in (-1, 1):
            out.append(W.tube([(side * 0.26, y + 0.08, 0), (side * 0.3, y + L * 0.45, 0), (side * 0.24, y + L * 0.75, 0)], [0.04, 0.03, 0.006], W.STEEL, n=6))
        return out
    if style == "crescent":
        out = [W.blade(y + 0.25, L * 0.8, 0.2, 0.15, 0.08, 0.05, tip=0.6)]
        pts, rs = [], []
        for k in range(13):
            f = k / 12
            a = math.pi * f
            pts.append((-math.cos(a) * 0.4, y + 0.36 - math.sin(a) * 0.28, 0))
            rs.append(0.01 + 0.05 * math.sin(a) ** 0.8)
        out.append(W.tube(pts, rs, W.STEEL, n=8))
        return out
    if style == "crystal":
        out = [W._pyr((0, y, 0), (0, y + L * 1.2, 0), 0.13, c, 0.3)]
        for k in range(4):
            a = 2 * math.pi * k / 4 + 0.5
            out.append(W._pyr((math.cos(a) * 0.04, y + 0.04, math.sin(a) * 0.04), (math.cos(a) * 0.22, y + L * 0.55, math.sin(a) * 0.16), 0.06, c, k))
        return out
    if style == "bone":
        teeth = 5
        return [W.blade(y, L, 0.3, 0.22, 0.11, 0.06, tip=0.38, profile=lambda f: (1.0 - 0.26 * ((f * teeth) % 1.0)) if f < 0.92 else 0.8, color=W.BRIGHT)]
    if style == "serpent":
        return [W.blade(y, L * 1.15, 0.22, 0.16, 0.08, 0.05, tip=0.35, xoff=lambda f: 0.09 * math.sin(2 * math.pi * 1.5 * min(f, 1.1)) * min(1.0, f * 2))]
    if style == "sun":
        out = [W.blade(y + 0.12, L * 0.9, 0.24, 0.18, 0.08, 0.05, tip=0.5), W.disc((0, y + 0.1, 0), 0.18, 0.1, W.GOLD, axis="z")]
        for k in range(8):
            a = 2 * math.pi * k / 8
            r1 = 0.36 if k % 2 == 0 else 0.26
            out.append(W._pyr((math.cos(a) * 0.15, y + 0.1 + math.sin(a) * 0.15, 0), (math.cos(a) * r1, y + 0.1 + math.sin(a) * r1, 0), 0.04, W.GOLD))
        return out
    return [W._pyr((0, y, 0), (0, y + L, 0), 0.09, W.STEEL, math.pi / 4)]


def _axe_over(style, A):
    """an axe style's changes to an axe bit's numbers"""
    if style == "crescent":
        return dict(top=A["top"] * 1.45, beard_tip=A["beard_tip"] * 1.3, belly=abs(A["belly"]) * 2.6 + 0.12, horn=0.15, reach=A["reach"] * 1.06)
    if style == "bearded":
        return dict(top=A["top"] * 0.7, beard_tip=A["beard_tip"] * 1.6, beard_x=A["beard_x"] * 0.55, belly=A["belly"] * 0.6)
    if style == "broad":
        return dict(top=A["top"] * 1.3, beard_tip=A["beard_tip"] * 1.3, reach=A["reach"] * 1.25, belly=A["belly"] * 0.5)
    if style in ("dragon", "double"):
        return dict(top=A["top"] * 1.3, beard_tip=A["beard_tip"] * 1.2, belly=abs(A["belly"]) * 2.0 + 0.08, horn=0.14) if style == "dragon" else {}
    return {}


def hd_halberd(hs, th, head):
    y = 3.0
    A = dict(x0=0.12, top=0.5, reach=0.92, beard_tip=0.5, beard_x=0.92, t=0.12, belly=-0.08, neck=0.5, horn=0.0)
    st = hs.get("axe")
    k = dict(A)
    k.update(_axe_over(st, A))
    out = W.socket(y - 0.45, y + 0.4, 0.13)
    bit = lambda: W.axe(y, k["x0"], k["top"], k["reach"], k["beard_tip"], k["beard_x"], t=k["t"], belly=k["belly"], neck=k["neck"], horn=k["horn"])
    out.append(bit())
    if st in ("double", "dragon"):
        out.append(W.turn(bit(), angle_y=math.pi))
    else:
        pts, rs = [], []
        for i in range(9):   # the back fluke
            f = i / 8
            pts.append((-0.14 - 0.62 * f, y + 0.05 - 0.3 * f * f, 0)); rs.append(0.08 * (1 - f) + 0.006)
        out.append(W.tube(pts, rs, W.STEEL, n=4))
    out += spear_top(hs.get("spear"), th, y + 0.4, 1.05)
    if st == "dragon":
        for j in range(3):
            out.append(W._pyr((0.12, y + 0.3 - j * 0.25, 0), (0.12 + 0.22, y + 0.42 - j * 0.25, 0), 0.04, W.STEEL))
    return out


def hd_poleaxe(hs, th, head):
    y = 2.9
    out = W.war_hammer(y, 0.1, beak=0.7, top=0.0, face=0.4)
    out += spear_top(hs.get("spear"), th, y + 0.3, 0.9)
    return out


def hd_billhook(hs, th, head):
    if not hs.get("spear"):
        return head
    y = 3.1
    out = [p for p in head]
    # (its top spike in the theme's spear style: the original stays, a new point rides on it)
    out += [moved(p, 0.08, 0, 0) for p in spear_top(hs["spear"], th, y + 1.5, 0.62)]
    return out


def hd_bardiche(hs, th, head):
    if hs.get("axe") not in ("double", "dragon"):
        return head
    y0, y1 = 1.45, 3.4
    out = list(head)
    o = [(0.12, y1 - 0.25), (0.34, y1 + 0.08), (0.62, y1 + 0.3)]
    o += W.bez((0.62, y1 + 0.3), (1.25, (y0 + y1) / 2 + 0.2), (0.4, y0 + 0.02), 10)[1:]
    o += [(0.24, y0 + 0.14), (0.12, y0 + 0.3), (0.12, y1 - 0.6)]
    ground = set(range(2, 13))
    back = W.plate(list(reversed(o)), W.FACE, t=0.1, ground=set(len(o) - 1 - i for i in ground), bevel=0.18)
    out.append(W.turn(back, angle_y=math.pi))
    return out


def hd_glaive(th, head):
    style = th.get("blade")
    fn = BLADES.get(style)
    if not fn:
        return head
    y = 3.3
    a = dict(y0=y, length=2.3, w0=0.46, w1=0.4, t0=0.1, t1=0.05, tip=0.3, kind="single", fuller=0.0, fuller_end=0.6,
             curve=0.32, waves=0, wave_amp=0.0, belly=0.12, steps=10, color=W.FACE)
    out = [fn(th, a), W._pyr((0.28, y + 0.45, 0), (0.56, y + 0.56, 0), 0.06, W.STEEL, 0)]
    out += W.socket(y - 0.4, y + 0.02, 0.13)
    return out


def hd_pitchfork(hs, th, head):
    st = hs.get("spear")
    if st not in ("trident", "flame", "crystal", "bone"):
        return head
    y = 3.3
    out = [W.box(0, y, 0, 0.92, 0.1, 0.1, W.IRON), W.cylinder(y - 0.35, y + 0.02, 0.11, 0.1, W.IRON, n=10)]
    c = _accent(th)
    for x in (-0.38, 0.0, 0.38):
        if st == "crystal":
            out.append(W._pyr((x, y, 0), (x * 1.1, y + 1.35, 0), 0.07, c, x))
            continue
        if st == "flame":
            pts = [(x + 0.07 * math.sin(f * 9), y + 1.3 * f, 0.0) for f in [k / 12 for k in range(13)]]
            out.append(W.tube(pts, [0.05 - 0.04 * (k / 12) for k in range(13)], W.IRON, n=6))
            continue
        pts = [(x, y, 0), (x * 1.06, y + 0.5, 0.0), (x * 1.04, y + 1.0, 0.06), (x, y + 1.3, 0.16)]
        out.append(W.tube(pts, [0.05, 0.045, 0.035, 0.008], W.BRIGHT if st == "bone" else W.IRON, n=6))
        if st == "trident":
            for side in (-1, 1):
                out.append(W._pyr((x, y + 1.08, 0.08), (x + side * 0.1, y + 0.92, 0.08), 0.03, W.STEEL))
        elif st == "bone":
            for k in range(3):
                out.append(W.sphere((x, y + 0.3 + k * 0.3, 0.02 * k), 0.07, W.BRIGHT, u=8, v=5, scale=(1, 0.6, 1)))
    return out


# ---- HAMMERS keep a hammer's head: a block across the haft, a face and a back, in the style
def hd_hammer(style, th, head, weapon, r):
    y, s = (1.55, 1.0) if weapon == "Hammer" else (2.55, 1.6)
    c = _accent(th)
    out = W.socket(y - 0.3 * s, y + 0.3 * s, (r + 0.04))
    face = 0.36 * s
    if style == "crystal":
        out.append(W.lathe([(0.0, -0.05), (face * 0.55, 0.0), (face * 0.62, 0.5 * s), (face * 0.5, 0.62 * s), (0.0, 0.66 * s)], c, n=6))
        for v in out[-1].verts:   # (laid along +X)
            x0, y0, z0 = v.co
            v.co = (y0, y + x0, z0)
        for k in range(5):
            a = 2 * math.pi * k / 5
            out.append(W._pyr((-0.1 * s, y + math.cos(a) * 0.1 * s, math.sin(a) * 0.1 * s),
                              (-(0.45 + 0.15 * (k % 2)) * s, y + math.cos(a) * 0.32 * s, math.sin(a) * 0.32 * s), 0.06 * s, c, k))
        return out
    if style == "drum":
        # a round head across the haft, banded (a bell-founder's, a mason's)
        out.append(W.lathe([(0.0, -0.46 * s), (face * 0.62, -0.46 * s), (face * 0.68, -0.38 * s), (face * 0.6, 0.0),
                            (face * 0.68, 0.38 * s), (face * 0.62, 0.46 * s), (0.0, 0.46 * s)], W.STEEL, n=16))
        for v in out[-1].verts:   # (laid along +X)
            x0, y0, z0 = v.co
            v.co = (y0, y + x0, z0)
        for bx in (-0.38, -0.13, 0.13, 0.38):
            out.append(torus((bx * s, y, 0), face * 0.68, 0.028 * s, W.GLOW if th.get("glow") else W.DARKSTEEL, axis="x", n=16))
        out.append(W._pyr((0, y + face * 0.6, 0), (0, y + face * 0.6 + 0.42 * s, 0), 0.07 * s, c if th.get("glow") else W.STEEL, 0))
        return out
    if style == "anvil":
        # an anvil: a broad struck face, a waist, a long horn behind
        out.append(W.box(0.12 * s, y + face * 0.12, 0, 0.62 * s, face * 0.6, face * 1.1, W.STEEL))
        out.append(W.box(0.12 * s, y - face * 0.36, 0, 0.36 * s, face * 0.42, face * 0.72, W.DARKSTEEL))
        out.append(W.box(0.45 * s, y + face * 0.12, 0, 0.04 * s, face * 0.66, face * 1.16, W.BRIGHT))
        pts, rs = [], []
        for k in range(9):
            f = k / 8
            pts.append((-0.19 * s - 0.62 * s * f, y + face * 0.2 + 0.1 * s * f * f, 0)); rs.append(face * 0.3 * (1 - f) + 0.006)
        out.append(W.tube(pts, rs, W.STEEL, n=8))
        if th.get("glow"):
            out.append(W.box(0.12 * s, y + face * 0.43, 0, 0.5 * s, 0.02 * s, face * 0.5, W.GLOW))
        return out
    if style == "beak":
        # a bec de corbin: a small toothed face, a long curved beak, a tall spike
        first = len(out)
        out.append(W.box(0.15 * s, y, 0, 0.22 * s, face * 0.7, face * 0.7, W.STEEL))
        for dy in (-1, 1):
            for dz in (-1, 1):
                out.append(W._pyr((0.26 * s, y + dy * face * 0.17, dz * face * 0.17), (0.36 * s, y + dy * face * 0.17, dz * face * 0.17), 0.05 * s, W.STEEL, 0))
        pts, rs = [], []
        for k in range(11):
            f = k / 10
            pts.append((-0.05 * s - 1.1 * s * f, y + 0.12 * s * f - 0.5 * s * f ** 2.2, 0)); rs.append(0.08 * s * (1 - f) + 0.005)
        out.append(W.tube(pts, rs, W.STEEL, n=6))
        if weapon == "Maul":
            out += [W.turn(p.copy(), angle_y=math.pi) for p in out[first:]]
        out.append(W._pyr((0, y + 0.3 * s, 0), (0, y + 1.15 * s, 0), 0.075 * s, c if th.get("glow") else W.STEEL, 0))
        return out
    first = len(out)
    out.append(W.box(0.24 * s, y, 0, 0.34 * s, face, face, W.STEEL))
    out.append(W.box(0.43 * s, y, 0, 0.06 * s, face + 0.04 * s, face + 0.04 * s, W.STEEL))
    if style == "skull":
        out += skull((0.62 * s, y, 0), 0.42 * s, W.BRIGHT, eyes=W.GLOW if th.get("glow") else None)
        for sx in (-1, 1):
            out.append(W.tube([(0.5 * s, y + 0.15 * s, sx * 0.18 * s), (0.62 * s, y + 0.38 * s, sx * 0.34 * s), (0.5 * s, y + 0.55 * s, sx * 0.4 * s)],
                              [0.06 * s, 0.04 * s, 0.006], W.DARKSTEEL, n=6))
    elif style == "spiked":
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                out.append(W._pyr((0.46 * s, y + dy * face * 0.3, dz * face * 0.3), (0.7 * s, y + dy * face * 0.34, dz * face * 0.34), 0.06 * s, W.STEEL, 0))
    elif style == "orb":
        out.append(W.sphere((0.24 * s, y, 0), face * 0.5, W.GLOW if th.get("glow") else W.BRIGHT, u=12, v=8))
        out.append(torus((0.24 * s, y, 0), face * 0.62, 0.03 * s, W.DARKSTEEL, axis="x", n=16))
    elif style == "star":
        for k in range(8):
            a = 2 * math.pi * k / 8
            out.append(W._pyr((0.24 * s, y + math.cos(a) * face * 0.45, math.sin(a) * face * 0.45),
                              (0.24 * s, y + math.cos(a) * face * 1.05, math.sin(a) * face * 1.05), 0.05 * s, W.STEEL, a))
    elif style == "flanged":
        # four plate flanges standing off the head in a cross, each tipped with a stud
        for dy, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            out.append(W.box(0.22 * s, y + dy * face * 0.78, dz * face * 0.78, 0.4 * s,
                             face * (0.62 if dy else 0.08), face * (0.62 if dz else 0.08), W.STEEL))
            out.append(W.sphere((0.22 * s, y + dy * face * 1.1, dz * face * 1.1), face * 0.11, W.GLOW if th.get("glow") else W.BRIGHT, u=8, v=6))
    elif style == "crown":
        for k in range(6):
            a = 2 * math.pi * k / 6
            out.append(W._pyr((0.46 * s, y + math.cos(a) * face * 0.42, math.sin(a) * face * 0.42), (0.62 * s, y + math.cos(a) * face * 0.5, math.sin(a) * face * 0.5),
                              0.05 * s, W.GOLD, 0))
        out.append(W.box(0.24 * s, y, 0, 0.36 * s, face * 1.08, face * 1.08, W.GOLD))
        out.append(W.sphere((0.5 * s, y, 0), face * 0.2, W.GLOW if th.get("glow") else W.RED, u=8, v=6))
    if weapon == "Maul":
        # (a maul's head is two-faced: the face again behind)
        out += [W.turn(p.copy(), angle_y=math.pi) for p in out[first:]]
        out.append(W._pyr((0, y + 0.3 * s, 0), (0, y + 0.65 * s, 0), 0.1 * s, c if th.get("glow") else W.STEEL, 0))
        return out
    # the back: a beak (the spiked and skull ones longer and hooked), a top spike
    pts, rs = [], []
    beak = (0.85 if style in ("spiked", "skull") else 0.65) * s
    for k in range(9):
        f = k / 8
        pts.append((-0.12 * s - beak * f, y - 0.26 * f ** 2 * beak, 0)); rs.append(0.1 * s * (1 - f) + 0.006)
    out.append(W.tube(pts, rs, W.STEEL, n=6))
    out.append(W._pyr((0, y + 0.3 * s, 0), (0, y + (0.3 + 0.5) * s, 0), 0.08 * s, c if th.get("glow") else W.STEEL, 0))
    return out


def head_hook(th):
    hs = th.get("head") or {}
    if not hs and not th.get("blade") and not th.get("hammer"):
        return None

    def fn(head, y_top, r):
        name = W.WEAPON_NAME

        def go():
            if name == "Spear" and hs.get("spear"):
                return hd_spear(hs["spear"], th, head)
            if name in AXES and hs.get("axe"):
                return hd_axe(hs["axe"], th, head, name)
            if name in ("Hammer", "Maul") and (th.get("hammer") or hs.get("blunt")):
                return hd_hammer(th.get("hammer") or hs["blunt"], th, head, name, r)
            if name in BLUNTS and hs.get("blunt"):
                return hd_blunt(hs["blunt"], th, head, name, r)
            if name == "Halberd" and (hs.get("axe") or hs.get("spear")):
                return hd_halberd(hs, th, head)
            if name == "Poleaxe" and hs.get("spear"):
                return hd_poleaxe(hs, th, head)
            if name == "Billhook":
                return hd_billhook(hs, th, head)
            if name == "Bardiche":
                return hd_bardiche(hs, th, head)
            if name == "Pitchfork":
                return hd_pitchfork(hs, th, head)
            if name == "Glaive":
                return hd_glaive(th, head)
            return head
        return _plain(go)
    return fn


# ---- HAFTS: the shaft of anything on a haft (a spear's, an axe's, a staff's), so it changes too
BONE_C = C(222, 210, 182)


def _spiral(y0, y1, r, turns, rad, color, phase=0.0, n=5):
    pts = []
    steps = max(12, int(turns * 10))
    for k in range(steps + 1):
        f = k / steps
        a = 2 * math.pi * turns * f + phase
        pts.append((r * math.cos(a), y0 + (y1 - y0) * f, r * math.sin(a)))
    return W.tube(pts, rad, color, n=n)


def hf_build(style, th, y0, y1, r, color, n):
    L = y1 - y0
    if style == "banded":
        parts = [W.cylinder(y0, y1, r, r * 0.96, color, n=n)]
        k = max(2, int(L / 0.42))
        for i in range(1, k):
            y = y0 + L * i / k
            parts.append(W.cylinder(y - 0.035, y + 0.035, r + 0.022, r + 0.022, W.IRON, n=n))
            for sx in (-1, 1):
                parts.append(W.sphere((sx * (r + 0.03), y, 0), 0.022, W.BRASS, u=6, v=4))
        return parts
    if style == "spiral":
        return [W.cylinder(y0, y1, r * 0.97, r * 0.93, color, n=n), _spiral(y0 + 0.05, y1 - 0.05, r * 0.98, max(3, L / 0.32), 0.022, W.DARKWOOD)]
    if style == "twisted":
        parts = [W.cylinder(y0, y1, r * 0.62, r * 0.6, W.DARKSTEEL, n=8)]
        for ph in (0.0, math.pi):
            parts.append(_spiral(y0, y1, r * 0.5, max(3, L / 0.55), r * 0.5, W.STEEL, phase=ph, n=6))
        return parts
    if style == "bone":
        bone = col(th, "bone_color", BONE_C)
        parts = [W.cylinder(y0, y1, r * 0.62, r * 0.6, C(120, 100, 80), n=8)]
        k = max(4, int(L / 0.17))
        for i in range(k):
            y = y0 + L * (i + 0.5) / k
            parts.append(W.sphere((0, y, 0), r * 1.12, bone, u=8, v=5, scale=(1, 0.52, 1)))
        return parts
    if style == "vine":
        green = C(46, 112, 52)
        parts = [W.cylinder(y0, y1, r, r * 0.96, color, n=n), _spiral(y0, y1, r + 0.012, max(2, L / 0.6), 0.03, green)]
        turns = max(2, L / 0.6)
        for i in range(1, int(turns * 3)):
            f = i / (turns * 3)
            a = 2 * math.pi * turns * f
            y = y0 + L * f
            px, pz = (r + 0.03) * math.cos(a), (r + 0.03) * math.sin(a)
            parts.append(leaf(px, y, 0.17, 0.08, math.radians(60 if i % 2 else 120), green, t=0.02, cz=pz))
        return parts
    if style == "gilded":
        parts = [W.cylinder(y0, y1, r, r * 0.96, W.DARKWOOD, n=n), _spiral(y0 + 0.05, y1 - 0.05, r + 0.006, max(3, L / 0.4), 0.012, W.GOLD, n=4)]
        k = max(2, int(L / 0.6))
        for i in range(k + 1):
            y = y0 + L * i / k
            parts.append(W.cylinder(y - 0.04, y + 0.04, r + 0.025, r + 0.025, W.GOLD, n=n))
        return parts
    if style == "crystal":
        ice = C(176, 222, 250)
        parts = []
        k = max(2, int(L / 0.5))
        for i in range(k):
            a, b = y0 + L * i / k, y0 + L * (i + 1) / k
            parts.append(W.lathe([(0.0, a), (r * 0.9, a + 0.03), (r * 1.08, (a + b) / 2), (r * 0.9, b - 0.03), (0.0, b)], ice, n=6, rot=i * 0.5))
            parts.append(W.cylinder(b - 0.025, b + 0.025, r * 0.95, r * 0.95, W.GLOW if th.get("glow") else W.BRIGHT, n=8))
        return parts
    if style == "runic":
        band = W.GLOW if th.get("glow") else W.BRASS
        parts = [W.cylinder(y0, y1, r, r * 0.96, W.DARKWOOD, n=n)]
        k = max(2, int(L / 0.6))
        for i in range(1, k):
            y = y0 + L * i / k
            parts.append(W.cylinder(y - 0.03, y + 0.03, r + 0.014, r + 0.014, band, n=n))
            for j in range(4):
                a = j * math.pi / 2 + i
                parts.append(W.box(math.cos(a) * (r + 0.004), y + 0.14, math.sin(a) * (r + 0.004), 0.02, 0.14, 0.02, band))
        return parts
    if style == "bamboo":
        cane, node = C(178, 162, 96), C(136, 120, 66)
        parts = [W.cylinder(y0, y1, r, r * 0.97, cane, n=n)]
        k = max(3, int(L / 0.4))
        for i in range(1, k):
            y = y0 + L * i / k
            parts.append(W.cylinder(y - 0.02, y + 0.02, r + 0.018, r + 0.018, node, n=n))
        return parts
    if style == "rope":
        parts = [W.cylinder(y0, y1, r, r * 0.96, color, n=n)]
        k = max(2, int(L / 0.75))
        for i in range(k):
            y = y0 + L * (i + 0.5) / k
            parts.append(_spiral(y - 0.09, y + 0.09, r + 0.012, 4, 0.02, W.ROPE, n=4))
        return parts
    if style == "scaled":
        parts = [W.cylinder(y0, y1, r * 0.9, r * 0.88, W.DARKSTEEL, n=8)]
        k = max(4, int(L / 0.15))
        for i in range(k):
            y = y0 + L * i / k
            parts.append(W.cylinder(y, y + L / k * 1.05, r + 0.03, r * 0.92, W.DARKSTEEL if i % 2 else W.IRON, n=8))
        return parts
    if style == "chain":
        parts = [W.cylinder(y0, y1, r, r * 0.96, color, n=n), _spiral(y0 + 0.04, y1 - 0.04, r + 0.01, max(3, L / 0.45), 0.02, W.IRON, n=4)]
        turns = max(3, L / 0.45)
        for i in range(int(turns * 4)):
            f = (i + 0.5) / (turns * 4)
            a = 2 * math.pi * turns * f
            parts.append(W.sphere(((r + 0.025) * math.cos(a), y0 + L * f, (r + 0.025) * math.sin(a)), 0.026, W.IRON, u=6, v=4))
        return parts
    if style == "ash":
        pale, grain = C(198, 172, 132), C(150, 120, 84)
        parts = [W.cylinder(y0, y1, r, r * 0.96, pale, n=n)]
        k = max(3, int(L / 0.3))
        for i in range(1, k):
            y = y0 + L * i / k
            parts.append(W.cylinder(y - 0.006, y + 0.006, r + 0.004, r + 0.004, grain, n=n))
        return parts
    return [W.cylinder(y0, y1, r, r * 0.96, color, n=n)]


def haft_hook(th):
    style = th.get("haft")
    return (lambda y0, y1, r, color, n: hf_build(style, th, y0, y1, r, color, n)) if style else None


# --------------------------------------------------------------------------
#  BUILD
# --------------------------------------------------------------------------
def nearest_role(c):
    best, bd = None, 9.0
    for role, v in BASE.items():
        d = (c[0] - v[0]) ** 2 + (c[1] - v[1]) ** 2 + (c[2] - v[2]) ** 2
        if d < bd:
            best, bd = role, d
    return best, bd


def recolor(bm, th, region, A):
    pal = {k: (v if not isinstance(v, str) else BASE[v]) for k, v in th.get("palette", {}).items()}
    pattern = th.get("pattern")
    layer = bm.loops.layers.color.get("Col")
    if layer is None:
        return
    ys = [v.co.y for v in bm.verts] or [0]
    ylo, yhi = min(ys), max(ys)
    for f in bm.faces:
        for l in f.loops:
            c = tuple(l[layer][:3])
            if abs(c[0] - 1) < 0.01 and c[1] < 0.01 and abs(c[2] - 1) < 0.01:
                continue   # GLOW
            role, d = nearest_role(c)
            if d > 0.004:
                continue   # a theme's own colour (horn, bone, holly...): keep it
            new = pal.get(role, BASE[role])
            heads = region == "blade" and role in ("darksteel", "iron", "blackiron") and role not in pal and "steel" in pal
            if heads:   # a blunt head / socket in the theme's metal, a shade darker
                new = tuple(c * 0.78 for c in pal["steel"])
            if pattern and region == "blade" and (role in STEELY or heads):
                fy = (l.vert.co.y - ylo) / max(1e-3, yhi - ylo)
                a = new
                b = pal.get("pattern_b", (1, 1, 1))
                new = pat(pattern, l.vert.co, a, b, fy, th)
            l[layer] = (*new, 1.0)


def subdivide(bm):
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
    n = len(bm.faces)
    cuts = 2 if n < 900 else (1 if n < 3000 else 0)   # (patterns need vertices; weapons need to stay light)
    if cuts:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)


def split_glow(bm):
    """faces painted GLOW leave the body for the Neon region"""
    layer = bm.loops.layers.color.get("Col")
    glow = bmesh.new()
    gl = glow.loops.layers.color.new("Col")
    take = []
    for f in bm.faces:
        cs = [l[layer] for l in f.loops]
        if all(abs(c[0] - 1) < 0.02 and c[1] < 0.02 and abs(c[2] - 1) < 0.02 for c in cs):
            take.append(f)
    vmap = {}
    for f in take:
        vs = []
        for v in f.verts:
            if v not in vmap:
                vmap[v] = glow.verts.new(v.co)
            vs.append(vmap[v])
        try:
            nf = glow.faces.new(vs)
            for nl in nf.loops:
                nl[gl] = (1, 1, 1, 1)
        except ValueError:
            pass
    bmesh.ops.delete(bm, geom=take, context="FACES_ONLY")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    return glow if glow.faces else None


def set_hooks(th):
    W.THEME = th
    W.GUARD_FN = (lambda y, span, t: GUARDS[th["guard"]](th, y, span, t)) if th.get("guard") in GUARDS else None
    W.POMMEL_FN = (lambda y, size: POMMELS[th["pommel"]](th, y, size)) if th.get("pommel") in POMMELS else None
    W.BUTT_FN = (lambda y, r: POMMELS[th["pommel"]](th, y + 0.05, 0.34)) if th.get("pommel") in POMMELS else None
    W.GRIP_FN = (lambda length, r, y: wrap_grip(th, length, r, y)) if th.get("wrap") else None
    W.BLADE_FN = blade_hook(th)
    W.HEAD_FN = head_hook(th)
    W.HAFT_FN = haft_hook(th)


def clear_hooks():
    W.THEME = W.GUARD_FN = W.POMMEL_FN = W.BUTT_FN = W.GRIP_FN = None
    W.BLADE_FN = W.HEAD_FN = W.HAFT_FN = W.WEAPON_NAME = None
    W._HOOKING[0] = False


def build_parts(weapon, th):
    """-> (body bmesh, glow bmesh or None)"""
    set_hooks(th)
    W.WEAPON_NAME = weapon
    try:
        spec = W.WEAPONS[weapon]()
        A = anchors(weapon)
        extra = []
        if A["kind"] == "hafted" and th.get("guard") in GUARDS:
            extra += GUARDS[th["guard"]](th, A["guard"] - 0.02, 0.9, 0.12)   # a collar under the head
        blade = W.merge(*spec["Blade"])
        ys = [v.co.y for v in blade.verts]
        A["blade_len"] = max(ys) - min(ys)
        extra += ornaments(th, A)
        glow_parts = inlays(th, blade, A)
        subdivide(blade)
        recolor(blade, th, "blade", A)
        grip = W.merge(*spec["Grip"], *extra)
        recolor(grip, th, "grip", A)
        body = W.merge(blade, grip, *glow_parts)
        glow = split_glow(body)
        return body, glow
    finally:
        clear_hooks()


def to_object(name, bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    ob.select_set(False)
    return ob


def build(weapon, skin, th, out_dir):
    W.clear_scene()
    body, glow = build_parts(weapon, th)
    key = f"{weapon}__{safe(skin)}"
    meta = {"weapon": weapon, "skin": skin, "theme": th["id"], "regions": {}}
    if th.get("glow"):
        meta["glow"] = [round(c * 255) for c in th["glow"]["color"]]
    written = []
    for region, bm in (("Body", body), ("Glow", glow)):
        if bm is None:
            continue
        ob = to_object(f"{key}_{region}", bm)
        p = os.path.join(out_dir, f"{key}_{region}.fbx")
        W.export(ob, p)
        meta["regions"][region] = dict(W.bounds(ob), tris=len(ob.data.polygons), file=os.path.basename(p))
        written.append((p, len(ob.data.polygons)))
    with open(os.path.join(out_dir, key + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    return written


def safe(name):
    return re.sub(r"[^A-Za-z0-9]+", "", name)


# --------------------------------------------------------------------------
#  the manifest: every skin in Catalog ▸ Skins that names a `look`
# --------------------------------------------------------------------------
def manifest():
    out = []
    with open(SKINS_LUA, encoding="utf-8") as f:
        for line in f:
            m = re.search(r'weapon\s*=\s*"(\w+)".*?name\s*=\s*"([^"]+)".*?look\s*=\s*"(\w+)"', line)
            if m:
                out.append((m.group(1), m.group(2), m.group(3)))
    return out


def preview(pairs, png):
    """every pair in one Workbench render, flats facing the camera; glow in its colour"""
    from mathutils import Matrix
    from themes import THEMES
    W.clear_scene()
    x = 0.0
    labels = []
    for weapon, tid in pairs:
        th = THEMES[tid]
        body, glow = build_parts(weapon, th)
        if glow:
            gl = glow.loops.layers.color.get("Col")
            gc = th["glow"]["color"]
            for f in glow.faces:
                for l in f.loops:
                    l[gl] = (*gc, 1)
            body = W.merge(body, glow)
        xs = [v.co.x for v in body.verts]
        w = max(xs) - min(xs)
        m = Matrix.Translation(Vector((x - min(xs), 0, 0))) @ Matrix.Rotation(math.radians(90), 4, "X")
        for v in body.verts:
            v.co = m @ v.co
        me = bpy.data.meshes.new("P")
        body.to_mesh(me); body.free()
        try:
            me.color_attributes.active_color = me.color_attributes["Col"]
            me.color_attributes.render_color_index = me.color_attributes.active_color_index
        except Exception:
            pass
        ob = bpy.data.objects.new("P", me)
        bpy.context.scene.collection.objects.link(ob)
        ob.select_set(True); bpy.context.view_layer.objects.active = ob
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40)); ob.select_set(False)
        labels.append((f"{weapon} {tid}", x + w / 2))
        x += w + 0.9
    zs, xs = [], []
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            zs += [v.co.z for v in o.data.vertices]; xs += [v.co.x for v in o.data.vertices]
    for text, lx in labels:
        cu = bpy.data.curves.new("L", "FONT"); cu.body = text; cu.size = 0.22; cu.align_x = "CENTER"
        t = bpy.data.objects.new("L", cu)
        t.location = (lx, -1.0, min(zs) - 0.45); t.rotation_euler = (math.radians(90), 0, 0)
        bpy.context.scene.collection.objects.link(t)
    sc = bpy.context.scene
    w, h = max(xs) - min(xs) + 1, max(zs) - min(zs) + 1.4
    res = (2600, max(400, int(2600 * h / w)))
    sc.render.resolution_x, sc.render.resolution_y = res
    cd = bpy.data.cameras.new("Cam"); cd.type = "ORTHO"; cd.ortho_scale = max(w, h * res[0] / res[1]) * 1.02
    cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = ((max(xs) + min(xs)) / 2, -60, (max(zs) + min(zs)) / 2 - 0.35)
    cam.rotation_euler = Vector((0, 1, 0)).to_track_quat("-Z", "Y").to_euler()
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "VERTEX"
    sc.display.shading.show_cavity = True
    sc.display.shading.show_specular_highlight = True
    sc.world = sc.world or bpy.data.worlds.new("W")
    sc.world.color = (0.11, 0.12, 0.15)
    sc.render.filepath = os.path.abspath(png)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", sc.render.filepath)


if __name__ == "__main__":
    from themes import THEMES
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "--preview" in argv:
        i = argv.index("--preview"); png = argv[i + 1]; del argv[i:i + 2]
        preview([tuple(a.split(":")) for a in argv], png)
        sys.exit(0)
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    only_new = "--new" in argv
    argv = [a for a in argv if a != "--new"]
    jobs = []
    if "--manifest" in argv:
        jobs = manifest()
    else:
        for a in argv:
            w, skin, tid = (a.split(":") + [None])[:3]
            jobs.append((w, skin, tid or skin))
    for weapon, skin, tid in jobs:
        if tid not in THEMES:
            print("NO THEME", tid, "for", weapon, skin); continue
        if only_new and os.path.exists(os.path.join(out_dir, f"{weapon}__{safe(skin)}.json")):
            continue
        for p, tri in build(weapon, skin, THEMES[tid], out_dir):
            print(f"WROTE {p} ({tri} tris)")
