"""Face textures for the R6 head (Decals), drawn as flat ink shapes and
rendered headless in Blender:

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python blender/faces.py -- [ids...] [--out dir]

Output: 512x512 transparent PNGs, blender/out/faces/<id>.png. Ids match
Catalog ▸ Body ▸ faces. Layout follows the classic Roblox face texture: the
features sit in the middle of the square (eyes a little above centre, mouth
below), dark ink so they read on every skin tone. Canvas units: the square
spans -0.5 .. 0.5, y up.
"""
import bpy, bmesh, math, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "faces")

INK = (0.045, 0.04, 0.055)
WHITE = (1.0, 1.0, 1.0)
SCAR = (0.70, 0.27, 0.27)
SCAR_DARK = (0.45, 0.14, 0.14)
BAG = (0.38, 0.22, 0.24)
PAINT = (0.82, 0.10, 0.10)
TONGUE = (0.85, 0.28, 0.33)
STRAP = (0.16, 0.10, 0.07)

EYE_X, EYE_Y, EYE_RX, EYE_RY = 0.125, 0.07, 0.036, 0.072
_layer = [0]


# ------------------------------------------------------------------ scene
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24
    try:
        sc.cycles.use_denoising = False
    except Exception:
        pass
    sc.render.resolution_x = sc.render.resolution_y = 512
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    cam = bpy.data.cameras.new("Cam"); cam.type = "ORTHO"; cam.ortho_scale = 1.0
    o = bpy.data.objects.new("Cam", cam); sc.collection.objects.link(o); sc.camera = o
    o.location = (0, 0, 5)
    _layer[0] = 0
    return sc


_mats = {}
def mat(color):
    key = tuple(round(c, 4) for c in color)
    if key in _mats and _mats[key].name in bpy.data.materials:
        return _mats[key]
    m = bpy.data.materials.new("Ink%d" % len(_mats)); m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs["Color"].default_value = (*color, 1); em.inputs["Strength"].default_value = 1.0
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    _mats[key] = m
    return m


def _obj(bm, color):
    _layer[0] += 1
    me = bpy.data.meshes.new("S"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("S", me); bpy.context.scene.collection.objects.link(o)
    o.location.z = _layer[0] * 0.001
    me.materials.append(mat(color))
    return o


# ------------------------------------------------------------------ shapes
def ellipse(cx, cy, rx, ry, color, rot=0.0, segs=72):
    bm = bmesh.new()
    vs = []
    c, s = math.cos(rot), math.sin(rot)
    for i in range(segs):
        a = 2 * math.pi * i / segs
        x, y = rx * math.cos(a), ry * math.sin(a)
        vs.append(bm.verts.new((cx + x * c - y * s, cy + x * s + y * c, 0)))
    bm.faces.new(vs)
    return _obj(bm, color)


def poly(points, color):
    bm = bmesh.new()
    bm.faces.new([bm.verts.new((x, y, 0)) for x, y in points])
    return _obj(bm, color)


def bezier(p0, p1, p2, n=24):
    """points on a quadratic bezier p0 -> p2 pulled toward p1"""
    out = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        out.append((x, y))
    return out


def stroke(points, width, color, caps=True):
    """a constant-width stroke along a polyline, round caps"""
    if len(points) < 2:
        return
    h = width / 2
    left, right = [], []
    for i, (x, y) in enumerate(points):
        if i == 0:
            dx, dy = points[1][0] - x, points[1][1] - y
        elif i == len(points) - 1:
            dx, dy = x - points[i - 1][0], y - points[i - 1][1]
        else:
            dx, dy = points[i + 1][0] - points[i - 1][0], points[i + 1][1] - points[i - 1][1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        left.append((x + nx * h, y + ny * h)); right.append((x - nx * h, y - ny * h))
    bm = bmesh.new()
    lv = [bm.verts.new((x, y, 0)) for x, y in left]
    rv = [bm.verts.new((x, y, 0)) for x, y in right]
    for i in range(len(points) - 1):
        bm.faces.new((lv[i], rv[i], rv[i + 1], lv[i + 1]))
    _obj(bm, color)
    if caps:
        for x, y in (points[0], points[-1]):
            ellipse(x, y, h, h, color, segs=32)


def line(a, b, width, color):
    stroke([a, b], width, color)


# ------------------------------------------------------------------ parts
def eye(x, y=EYE_Y, rx=EYE_RX, ry=EYE_RY, shine=True):
    ellipse(x, y, rx, ry, INK)
    if shine:
        ellipse(x + rx * 0.3, y + ry * 0.42, rx * 0.36, rx * 0.36, WHITE)


def eyes(**kw):
    eye(-EYE_X, **kw); eye(EYE_X, **kw)


def brow(side, inner_y, outer_y, width=0.034, inner_x=0.06, outer_x=0.2, bend=0.0):
    """side -1 = viewer's left, +1 = viewer's right"""
    a = (side * outer_x, outer_y); b = (side * inner_x, inner_y)
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + bend)
    stroke(bezier(a, mid, b, 12), width, INK)


def half_lid_eye(x, y=EYE_Y):
    """a tired eye: the lower half of the oval under a heavy lid line"""
    pts = [(x + EYE_RX * math.cos(a), y + 0.008 + EYE_RY * 0.75 * math.sin(a)) for a in [math.pi + i * math.pi / 30 for i in range(31)]]
    poly(pts, INK)
    line((x - EYE_RX * 1.35, y + 0.012), (x + EYE_RX * 1.35, y + 0.012), 0.02, INK)
    ellipse(x + EYE_RX * 0.35, y - 0.012, EYE_RX * 0.3, EYE_RX * 0.3, WHITE)


# ------------------------------------------------------------------ faces
def f_smile():
    eyes()
    stroke(bezier((-0.13, -0.075), (0, -0.21), (0.13, -0.075)), 0.03, INK)


def f_stern():
    eyes(ry=0.062)
    brow(-1, 0.155, 0.2); brow(1, 0.155, 0.2)
    stroke([(-0.085, -0.142), (-0.045, -0.128), (0.045, -0.128), (0.085, -0.142)], 0.028, INK)


def f_grin():
    eyes()
    brow(-1, 0.21, 0.2, bend=0.02, width=0.028); brow(1, 0.21, 0.2, bend=0.02, width=0.028)
    top = -0.06
    shape = [(-0.155, top)] + bezier((-0.155, top), (0, -0.3), (0.155, top), 30)[1:]
    poly(shape, INK)
    teeth = [(-0.125, top - 0.012), (0.125, top - 0.012), (0.11, top - 0.045), (-0.11, top - 0.045)]
    poly(teeth, WHITE)
    ellipse(0, -0.165, 0.055, 0.022, TONGUE)


def f_scarred():
    f_stern()
    pts = [(0.055, 0.235), (0.135, 0.09), (0.2, -0.045)]
    stroke(bezier(pts[0], pts[1], pts[2], 16), 0.024, SCAR)
    for t in (0.25, 0.5, 0.75):
        x = (1 - t) ** 2 * pts[0][0] + 2 * (1 - t) * t * pts[1][0] + t * t * pts[2][0]
        y = (1 - t) ** 2 * pts[0][1] + 2 * (1 - t) * t * pts[1][1] + t * t * pts[2][1]
        line((x - 0.028, y - 0.012), (x + 0.028, y + 0.012), 0.011, SCAR_DARK)


def f_weary():
    half_lid_eye(-EYE_X); half_lid_eye(EYE_X)
    brow(-1, 0.205, 0.16, width=0.026); brow(1, 0.205, 0.16, width=0.026)
    for s in (-1, 1):
        stroke(bezier((s * 0.075, -0.018), (s * 0.125, -0.05), (s * 0.18, -0.018), 10), 0.011, BAG)
    stroke(bezier((-0.08, -0.155), (0, -0.105), (0.08, -0.155)), 0.024, INK)


def f_fierce():
    eyes(ry=0.058)
    brow(-1, 0.105, 0.2, width=0.048); brow(1, 0.105, 0.2, width=0.048)
    # gritted teeth
    box = [(-0.12, -0.085), (0.12, -0.085), (0.1, -0.19), (-0.1, -0.19)]
    poly(box, INK)
    poly([(-0.1, -0.104), (0.1, -0.104), (0.086, -0.17), (-0.086, -0.17)], WHITE)
    line((-0.095, -0.137), (0.095, -0.137), 0.012, INK)
    for x in (-0.05, 0.0, 0.05):
        line((x, -0.108), (x, -0.166), 0.009, INK)
    # war paint under the eyes
    for s in (-1, 1):
        line((s * 0.085, -0.035), (s * 0.175, -0.055), 0.024, PAINT)
        line((s * 0.095, -0.07), (s * 0.165, -0.087), 0.02, PAINT)


def f_one_eyed():
    eye(-EYE_X)
    brow(-1, 0.16, 0.2)
    # strap first, then the patch over it
    stroke([(0.075, 0.13), (-0.5, 0.36)], 0.022, STRAP, caps=False)
    stroke([(0.19, 0.1), (0.5, 0.16)], 0.022, STRAP, caps=False)
    ellipse(EYE_X, EYE_Y + 0.005, 0.092, 0.082, INK, rot=0.12)
    ellipse(EYE_X - 0.025, EYE_Y + 0.035, 0.026, 0.014, (0.25, 0.25, 0.28), rot=0.3)
    stroke([(-0.085, -0.14)] + bezier((-0.03, -0.14), (0.07, -0.14), (0.105, -0.095), 10), 0.026, INK)


def f_smirk():
    eye(-EYE_X); eye(EYE_X, ry=0.06)
    brow(-1, 0.18, 0.18, width=0.028)
    brow(1, 0.235, 0.215, bend=0.03, width=0.028)
    stroke([(-0.095, -0.145)] + bezier((-0.02, -0.145), (0.07, -0.145), (0.115, -0.09), 10), 0.028, INK)


def f_battle_cry():
    # squeezed eyes ( > < ) and an open roar
    for s in (-1, 1):
        stroke([(s * 0.185, 0.115), (s * 0.085, 0.072), (s * 0.18, 0.03)], 0.032, INK)
    brow(-1, 0.12, 0.215, width=0.044); brow(1, 0.12, 0.215, width=0.044)
    ellipse(0, -0.14, 0.105, 0.088, INK)
    poly([(-0.085, -0.075), (0.085, -0.075), (0.07, -0.1), (-0.07, -0.1)], WHITE)
    ellipse(0, -0.19, 0.06, 0.03, TONGUE)


def f_calm():
    for s in (-1, 1):
        stroke(bezier((s * 0.065, 0.075), (s * 0.125, 0.025), (s * 0.185, 0.075), 12), 0.026, INK)
    brow(-1, 0.18, 0.17, width=0.024, bend=0.012); brow(1, 0.18, 0.17, width=0.024, bend=0.012)
    stroke(bezier((-0.075, -0.1), (0, -0.16), (0.075, -0.1)), 0.024, INK)


FACES = {
    "Smile": f_smile, "Stern": f_stern, "Grin": f_grin, "Scarred": f_scarred, "Weary": f_weary,
    "Fierce": f_fierce, "OneEyed": f_one_eyed, "Smirk": f_smirk, "BattleCry": f_battle_cry, "Calm": f_calm,
}


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for fid in (argv or list(FACES)):
        sc = reset()
        _mats.clear()
        FACES[fid]()
        sc.render.filepath = os.path.join(out_dir, fid + ".png")
        bpy.ops.render.render(write_still=True)
        print("RENDERED", sc.render.filepath)
