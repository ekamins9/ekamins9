"""STORE ART — Steel & Glory's thumbnails, icon and badge pictures (blender/art_kit.py).

    blender.exe -b --python blender/store_art.py -- <scene> <out.png> [--preview | --layout]
    scenes: clash · mage · archer · lineup · siege · icon · badge:<Key> · badges (<out> a folder: all ten)
    retitle:<scene> <out.png>: new titles over that scene's last render (its TITLES)
Thumbnails 1920×1080, the icon and badges 512×512. --preview: half size, few samples;
--layout: a quarter, fewer still (for placing things; K.where prints where a point lands)."""
import bpy, math, os, sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import art_kit as K  # noqa: E402
from art_kit import rgb, T, R  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREVIEW = "--preview" in ARGS or "--layout" in ARGS
SCALE = 0.25 if "--layout" in ARGS else (0.5 if PREVIEW else 1.0)
ARGS = [a for a in ARGS if not a.startswith("--")]


def setup(res=(1920, 1080)):
    return K.setup(res, scale=SCALE)


def base_of(out, kind="base"):
    """where a picture's render before its titles goes (and its titles layer): work/ beside it"""
    d, name = os.path.split(out)
    return os.path.join(d, "work", f"{name[:-4]}.{kind}.png")


def finish(out, items, res=(1920, 1080)):
    """the scene already rendered to work/<name>.base.png: titles laid over it → out"""
    res = (int(res[0] * SCALE), int(res[1] * SCALE))
    base = base_of(out)
    lay = base_of(out, "titles")
    K.overlay(items, res, lay)
    K.compose(base, lay, out, res)


def castle_backdrop(dist=40, mat=None, roof=None):
    m = mat or K.stone_mat(rgb(150, 140, 128), rgb(90, 84, 76), 1.2)
    r = roof or K.flat_mat("roof", rgb(40, 60, 140), rough=0.6)
    out = []
    out += K.wall((-26, dist, 0), (26, dist, 0), 9, 2.5, m)
    for x in (-26, -9, 9, 26):
        out += K.tower((x, dist, 0), 3.2 if abs(x) > 10 else 3.8, 13 if abs(x) > 10 else 16, m, r)
    return out


# ------------------------------------------------------------------------
#  1. THE CLASH: a Sun Knight and a Blackguard, blades locked, sparks
# ------------------------------------------------------------------------
def clash(out):
    setup()
    K.sky(top=rgb(10, 8, 34), horizon=rgb(255, 110, 25), strength=1.4, band=0.22)
    K.fog(0.004, rgb(255, 170, 120), 0.6, size=(200, 90, 10), center=(0, 50, 4))
    K.ground(240, K.stone_mat(rgb(96, 86, 76), rgb(44, 40, 36), 1.6))
    castle_backdrop(46)
    # the sun going down behind the keep: a blinding disc, rays through the haze
    K.obj("Sun", K.sphere_bm((0, 120, 16), 9, color=(1, 0.8, 0.5)), K.flat_mat("sun", rgb(255, 190, 110), emit=30))
    # the hero (left, facing +X) and the villain (right, facing -X)
    hero = dict(torso=(14, 0, 0), head=(-6, 0, 0), rarm=(58, -6, 12), larm=(54, 10, -36), rleg=(-22, 0, 4), lleg=(26, 0, -4))
    villain = dict(torso=(16, 0, 0), head=(-4, 0, 0), rarm=(60, 6, 14), larm=(56, -10, -34), rleg=(-24, 0, 4), lleg=(28, 0, -4))
    fa, _ = K.figure("SunKnights", at=(-2.15, 0, 0), yaw=-90, pose=hero,
                     colors={"Primary": rgb(40, 90, 220), "Secondary": rgb(230, 230, 236), "Accent": rgb(240, 190, 70), "Metal": rgb(230, 232, 238)})
    K.weapon("Greatsword", K.hand(fa) @ R(0, 0, -28))
    fb, _ = K.figure("Blackguard", at=(2.15, 0, 0), yaw=90, pose=villain,
                     colors={"Primary": rgb(160, 24, 24), "Secondary": rgb(30, 26, 28), "Accent": rgb(200, 30, 30), "Metal": rgb(60, 60, 66)})
    K.weapon("Zweihander", K.hand(fb) @ R(0, 0, 28))
    hit = (0.0, 0.0, 5.9)
    K.sparks(hit, n=90, spread=2.8, length=0.7, power=900)
    K.embers((-10, -6, 0), (10, 30, 9), n=260)
    # light: a warm sun low behind, a cool fill from the front, rims on both
    K.light("SUN", (0, 0, 0), rgb(255, 160, 90), 1.6, target=None)
    sun = bpy.data.objects["SUN"]; sun.rotation_euler = (math.radians(72), 0, math.radians(180))
    K.light("AREA", (-8, -10, 8), rgb(120, 160, 255), 450, size=8, target=(0, 0, 3))
    K.light("AREA", (7, 6, 6), rgb(255, 120, 60), 1200, size=4, target=(0, 0, 3))
    K.light("AREA", (0, 9, 7), rgb(255, 200, 140), 2500, size=6, target=(0, 0, 4))   # a hard rim from behind
    # banners on the wall: the hero's blue and gold, the villain's black and red
    for x, col in ((-14, rgb(30, 70, 200)), (-5.5, rgb(30, 70, 200)), (5.5, rgb(170, 20, 20)), (14, rgb(170, 20, 20))):
        K.block("WallBanner", (x, 44.6, 5.5), (2.4, 0.1, 6), K.flat_mat("wb", col, rough=0.85, emit=0.15))
        K.block("WallBannerTrim", (x, 44.5, 2.4), (2.4, 0.12, 0.3), K.flat_mat("wbt", rgb(240, 190, 70), metallic=0.8, rough=0.3))
    cam = K.camera((0.3, -12.8, 1.45), (0, 0, 4.4), lens=27, focus=(0, 0, 4.3), fstop=3.0)
    K.bloom(0.5, 1.2, 0.7)
    K.render(base_of(out))
    finish(out, CLASH_TITLES)


# ------------------------------------------------------------------------
#  2. THE MAGE: a Star Sage with the Staff of the Cosmos hurls fire at a knight
# ------------------------------------------------------------------------
def magic_circle(center, r, color, n=48, strength=12):
    import bmesh as _b
    bms = []
    for ring_r, w in ((r, 0.09), (r * 0.82, 0.05)):
        bm = _b.new()
        _b.ops.create_circle(bm, cap_ends=False, segments=n, radius=ring_r)
        # (a thin band: extrude the circle's edge outward a little)
        bm2 = K.W.tube([(math.cos(a) * ring_r, math.sin(a) * ring_r, 0.03) for a in [i / n * 2 * math.pi for i in range(n + 1)]], w, color)
        bm.free()
        bms.append(bm2)
    for i in range(12):   # runes round the ring
        a = i / 12 * 2 * math.pi
        bm = K.box_mesh(0.22, 0.04, 0.32, 0.01)
        M = T(math.cos(a) * r * 0.91, math.sin(a) * r * 0.91, 0.04) @ R(0, 0, math.degrees(a))
        for v in bm.verts:
            v.co = M @ v.co
        K.paint(bm, color)
        bms.append(bm)
    K.obj("MagicCircle", K.W.merge(*bms), K.flat_mat("circle", color, emit=strength), T(*center))
    K.light("POINT", (center[0], center[1], center[2] + 0.6), color, 400, 2)


def mage(out):
    setup()
    K.sky(top=rgb(6, 4, 24), horizon=rgb(110, 50, 190), strength=1.2, band=0.25)
    K.fog(0.006, rgb(150, 110, 255), 0.5, size=(200, 90, 8), center=(0, 50, 3))
    K.ground(240, K.stone_mat(rgb(70, 66, 82), rgb(30, 28, 38), 1.6))
    castle_backdrop(52, K.stone_mat(rgb(80, 78, 100), rgb(40, 38, 52), 1.2), K.flat_mat("roof", rgb(40, 30, 90), rough=0.6))
    K.obj("Moon", K.sphere_bm((60, 110, 52), 7, color=(1, 1, 1), segs=64), K.flat_mat("moon", rgb(210, 225, 255), emit=8))
    K.embers((-60, 60, 18), (60, 130, 60), n=400, color=rgb(220, 230, 255), size=(0.05, 0.14), seed=11)   # stars
    # the Star Sage (left), three-quarters to us facing right: the staff raised high in her right
    # hand, the left thrust at the knight with the fireball leaving it
    M = (-3.4, 0.4, 0)
    pose = dict(torso=(6, 8, 0), head=(-4, 14, 0), rarm=(128, -12, 22), larm=(96, 22, 0), rleg=(-16, 0, 10), lleg=(18, 0, -8))
    f, _ = K.figure("StarSage", at=M, yaw=-118, pose=pose,
                    colors={"Primary": rgb(70, 40, 170), "Secondary": rgb(24, 18, 60), "Accent": rgb(255, 214, 110), "Metal": rgb(230, 220, 255)}, neon=3)
    grip = K.hand(f) @ R(0, 0, 0)
    for sx in (-1, 1):   # eyes burning in the shadow of the hood
        K.obj("Eye", K.sphere_bm((sx * 0.2, 0.1, -0.64), 0.085, (1, 1.3, 0.6)), K.flat_mat("eye", rgb(150, 210, 255), emit=14), f["Head"])
    K.light("POINT", (f["Head"] @ Vector((0, 0.1, -0.9))), rgb(150, 200, 255), 6, 0.1)
    K.staff("Staff of the Cosmos", grip, neon=5)
    magic_circle((M[0], M[1], 0.02), 2.6, rgb(150, 80, 255), strength=3)
    # the fireball, between them, its trail back to her hand
    hand = (K.hand(f, "L") @ K.Vector((0, 0.5, 0)))
    fb = Vector((2.2, -0.5, 4.0))
    K.fire(tuple(fb), r=1.5, strength=2.2, power=3500)
    pts = [hand.lerp(fb, t) + Vector((0, 0, math.sin(t * math.pi) * 0.35)) for t in [i / 10 for i in range(11)]]
    K.trail(pts, [0.06 + 0.55 * (i / 10) ** 1.5 for i in range(11)], rgb(255, 70, 0), 2.2, "FireTrail")
    K.sparks(tuple(fb), n=44, color=rgb(255, 110, 10), spread=2.6, length=0.55, power=300, seed=4, strength=2.5)
    K.embers((-1, -3, 1.5), (7, 3, 8), n=70, color=rgb(255, 110, 20), seed=8, size=(0.015, 0.045))
    # the knight bracing against it (right, half out of the frame)
    kpose = dict(torso=(-14, 0, 0), head=(10, 0, 0), rarm=(110, -20, 30), larm=(100, 20, -40), rleg=(-26, 0, 6), lleg=(20, 0, -6))
    fk, _ = K.figure("IronCrow", at=(6.0, 2.2, 0), yaw=112, pose=kpose,
                     colors={"Primary": rgb(30, 30, 36), "Secondary": rgb(20, 20, 24), "Accent": rgb(200, 40, 40), "Metal": rgb(70, 72, 80)})
    K.weapon("Longsword", K.hand(fk) @ R(0, 0, 40))
    K.light("POINT", (M[0] + 1.6, M[1] - 2.4, 5.6), rgb(255, 170, 90), 260, 0.6)   # firelight on her face
    K.light("AREA", (-8, -10, 9), rgb(140, 160, 255), 600, size=8, target=(0, 0, 3))
    K.light("AREA", (-3, 9, 7), rgb(170, 110, 255), 2600, size=6, target=(-2.6, 0.5, 3.5))
    cam = K.camera((0.6, -12.4, 2.1), (0.6, 0, 4.0), lens=28, focus=(M[0], M[1], 4), fstop=3.2)
    head = f["Head"].translation
    for label, pnt in (("head", head), ("staff top", (grip @ T(0, 4.5, 0)).translation), ("left hand", hand), ("fireball", fb), ("knight", fk["Head"].translation)):
        K.where(label, pnt)
    K.bloom(0.5, 1.4, 0.7)
    K.render(base_of(out))
    finish(out, MAGE_TITLES)


# ------------------------------------------------------------------------
#  3. THE ARCHER: the Phoenixborn on the battlements at sunset, a burning arrow drawn
# ------------------------------------------------------------------------
def arrow(tail, tip, flame=0.0, color=rgb(120, 80, 44), fletch=rgb(230, 60, 30), name="Arrow"):
    """a shaft from `tail` to `tip`, a steel head, three vanes; `flame` > 0: its head burns"""
    tail, tip = Vector(tail), Vector(tip)
    d = (tip - tail).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    up = side.cross(d)
    shaft = K.W.tube([tuple(tail), tuple(tip - d * 0.3)], 0.035, color)
    head = K.W.cone(tuple(tip - d * 0.32), tuple(tip), 0.09, rgb(200, 200, 210))
    vanes = []
    for k in range(3):
        a = k / 3 * 2 * math.pi
        n = side * math.cos(a) + up * math.sin(a)
        bm = K.bmesh.new()
        vs = [bm.verts.new(tuple(tail + d * 0.08)), bm.verts.new(tuple(tail + d * 0.55)), bm.verts.new(tuple(tail + d * 0.12 + n * 0.16))]
        bm.faces.new(vs)
        K.paint(bm, fletch)
        vanes.append(bm)
    out = [K.obj(name, K.W.merge(shaft, *vanes), K.mat("cloth"), K.Matrix()), K.obj(name + "Head", head, K.mat("metal"), K.Matrix())]
    if flame:
        out += K.fire(tuple(tip - d * 0.15), r=flame, strength=2.4, power=120 * flame * 10, seed=int(abs(tip.x * 7)) % 50 + 3)
    return out


def drawn_bow(grip, nock, up=(0, 0, 1), height=5.2, bend=0.5, color=rgb(70, 30, 20), trim=rgb(232, 184, 74)):
    """a bow held at `grip` (world), its string pulled to `nock`; the limbs curve back toward the
    archer at the tips (the string meets them there)"""
    grip, nock, up = Vector(grip), Vector(nock), Vector(up).normalized()
    back = (nock - grip)
    back = (back - up * back.dot(up)).normalized()
    pts = []
    n = 16
    for i in range(n + 1):
        t = i / n * 2 - 1
        pts.append(grip + up * (t * height / 2) + back * (t * t * bend - 0.1 * (1 - t * t)))
    limbs = K.W.tube([tuple(p) for p in pts], 0.1, color)
    tips = [K.W.sphere(tuple(pts[0]), 0.13, trim), K.W.sphere(tuple(pts[-1]), 0.13, trim)]
    wrap = K.W.tube([tuple(grip - up * 0.4), tuple(grip + up * 0.4)], 0.14, trim)
    string = K.W.tube([tuple(pts[0]), tuple(nock), tuple(pts[-1])], 0.018, rgb(250, 240, 220), n=5)
    return [K.obj("Bow", K.W.merge(limbs, *tips), K.mat("grip"), K.Matrix()), K.obj("BowTrim", wrap, K.mat("metal"), K.Matrix()),
            K.obj("BowString", string, K.mat("cloth"), K.Matrix())]


def parapet(y, x0, x1, top, merlon=1.4, width=1.7, gap=1.3, depth=1.0, mat=None, gaps_at=(), merlons_to=None):
    """a wall face toward the camera (at y), the walk behind it at z = 0; merlons along its top
    (up to x = `merlons_to`), with the embrasures (gaps) centred at `gaps_at` where given"""
    m = mat or K.stone_mat(rgb(170, 140, 110), rgb(96, 76, 60), 1.4)
    out = [K.block("Parapet", ((x0 + x1) / 2, y, (top - 30) / 2), (x1 - x0, depth, top + 30), m)]
    x = x0
    while x < x1:
        mid = x + width / 2
        if not any(abs(mid - g) < (width + gap) / 2 for g in gaps_at) and (merlons_to is None or mid < merlons_to):
            out.append(K.block("Merlon", (mid, y, top + merlon / 2), (width, depth, merlon), m))
        x += width + gap
    return out


def archer(out):
    setup()
    K.sky(top=rgb(70, 18, 110), horizon=rgb(255, 92, 20), strength=1.8, band=0.4)
    K.fog(0.003, rgb(255, 130, 70), 0.6, size=(200, 90, 14), center=(0, 62, 5))
    stone = K.stone_mat(rgb(112, 88, 72), rgb(54, 42, 36), 0.9)
    far = K.stone_mat(rgb(120, 96, 90), rgb(70, 56, 54), 1.2)
    K.ground(240, K.stone_mat(rgb(110, 92, 78), rgb(64, 52, 44), 1.6))
    # the keep behind: tall towers, red roofs, the sun going down between them
    roof = K.flat_mat("roof", rgb(140, 34, 30), rough=0.6)
    K.wall((-34, 38, 0), (34, 38, 0), 11, 2.5, far)
    for x, rr, h in ((-26, 3.4, 17), (-12, 4.2, 25), (8, 3.6, 21), (24, 3.2, 15)):
        K.tower((x, 40, 0), rr, h, far, roof)
    K.obj("Sun", K.sphere_bm((52, 150, 40), 12, color=(1, 0.8, 0.5), segs=48), K.flat_mat("sun", rgb(255, 170, 70), emit=6))
    # the archer, left, chest to us, drawing on something off to the right
    A = (-2.6, 0.6, 0)
    pose = dict(torso=(0, 8, 0), head=(-6, 34, 0), rarm=(92, 62, 0), larm=(94, -14, 0), rleg=(-10, 0, 6), lleg=(10, 0, -6))
    f, _ = K.figure("Phoenix", at=A, yaw=186, pose=pose, neon=2.4,
                    colors={"Primary": rgb(196, 40, 30), "Secondary": rgb(60, 26, 16), "Accent": rgb(255, 196, 80), "Metal": rgb(232, 184, 74)})
    g = K.hand(f, "L").translation
    nk = K.hand(f, "R").translation
    drawn_bow(g, nk)
    aim = (g - nk).normalized()
    arrow(nk - aim * 0.25, g + aim * 1.3, flame=0.34, name="DrawnArrow")
    K.embers((A[0] - 3, A[1] - 1, 1.5), (A[0] + 3, A[1] + 3, 9), n=60, color=rgb(255, 110, 20), seed=21, size=(0.015, 0.045), strength=6)
    parapet(-1.0, -40, 40, 1.6, gaps_at=(A[0] + 0.6,), mat=stone, width=1.6, merlon=1.3, gap=1.6, merlons_to=A[0])
    # light: the sun low behind (a hot rim on everything), a warm key from the right where the
    # arrow points, a cool fill from the front
    K.light("SUN", (0, 0, 0), rgb(255, 150, 80), 2.2)
    sun = [o for o in K.bpy.data.objects if o.type == "LIGHT" and o.data.type == "SUN"][-1]
    sun.rotation_euler = (math.radians(76), 0, math.radians(185))
    K.light("AREA", (-7, -9, 6), rgb(120, 140, 255), 420, size=8, target=(A[0], A[1], 4))
    K.light("SPOT", (4, -6, 9), rgb(255, 170, 100), 1400, size=1.5, target=(A[0], A[1], 4.6), angle=28)
    K.light("AREA", (A[0] + 2, A[1] + 6, 8), rgb(255, 120, 50), 2200, size=5, target=(A[0], A[1], 4.5))
    cam = K.camera((0.4, -8.2, 2.0), (0.0, 0, 4.8), lens=26, focus=(A[0], A[1], 4.5), fstop=2.8)
    for label, pnt in (("head", f["Head"].translation), ("grip", g), ("nock", nk), ("arrow tip", g + aim * 1.3)):
        K.where(label, pnt)
    K.bloom(0.55, 1.0, 0.75, saturation=1.18)
    K.render(base_of(out))
    finish(out, ARCHER_TITLES)


ARCHER_TITLES = [
    {"text": "HEADSHOT!", "x": 4.2, "y": 3.0, "size": 2.0, "tilt": -4},
    {"text": "BOWS  •  CROSSBOWS", "x": 4.2, "y": 1.25, "size": 0.62, "fill": (rgb(255, 255, 255), rgb(255, 236, 200)),
     "outline": rgb(70, 20, 4), "ow": 0.07, "plate": rgb(210, 70, 20), "tilt": -4},
]

# ------------------------------------------------------------------------
#  4. THE FIVE CLASSES: the line-up, a burst of light behind them
# ------------------------------------------------------------------------
def held(frame, direction, slide=0.0, roll=0.0):
    """a hand's grip frame turned so the weapon points along `direction` (world), slid along
    itself (`slide`: where along the haft the hand is) and rolled about its axis"""
    pos = frame.translation.copy()
    cur = frame.to_3x3() @ Vector((0, 1, 0))
    q = cur.rotation_difference(Vector(direction).normalized())
    M = (q.to_matrix() @ frame.to_3x3()).to_4x4()
    M.translation = pos
    return M @ T(0, slide, 0) @ R(0, roll, 0)


def sunburst(center, r, n=24, colors=(rgb(255, 196, 80), rgb(255, 120, 40)), strength=1.6, facing=(0, -1, 0)):
    """rays of light fanning out behind the stage (a disc of wedges facing the camera)"""
    import bmesh as _b
    bms = []
    for k in range(n):
        a0, a1 = k / n * 2 * math.pi, (k + 1) / n * 2 * math.pi
        bm = _b.new()
        vs = [bm.verts.new((0, 0, 0)), bm.verts.new((math.cos(a0) * r, math.sin(a0) * r, 0)), bm.verts.new((math.cos(a1) * r, math.sin(a1) * r, 0))]
        bm.faces.new(vs)
        K.paint(bm, colors[k % 2])
        bms.append(bm)
    M = T(*center) @ Vector(facing).to_track_quat("Z", "Y").to_matrix().to_4x4()
    m = K.bpy.data.materials.new("burst")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes.get("Principled BSDF"))
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs["Strength"].default_value = strength
    vc = nt.nodes.new("ShaderNodeVertexColor"); vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], nt.nodes.get("Material Output").inputs["Surface"])
    return K.obj("Sunburst", K.W.merge(*bms), m, M)


CLASS_LINEUP = [
    # (class label, set, at, yaw, pose, colours, kit)
    ("ARCHER", "Moonshadow", (-6.6, 1.9, 0), 204, dict(torso=(0, -6, 0), head=(-4, -10, 0), rarm=(26, 0, 14), larm=(8, 0, -8), rleg=(-6, 0, 4), lleg=(8, 0, -4)),
     {"Primary": rgb(40, 50, 110), "Secondary": rgb(20, 22, 40), "Accent": rgb(170, 200, 255), "Metal": rgb(200, 210, 230)}, "bow"),
    ("FOOTMAN", "WolfCompany", (-3.2, 0.6, 0), 196, dict(torso=(0, -4, 0), head=(-4, -6, 0), rarm=(36, 14, 0), larm=(12, 0, -16), rleg=(-8, 0, 6), lleg=(10, 0, -6)),
     {"Primary": rgb(70, 90, 120), "Secondary": rgb(50, 46, 44), "Accent": rgb(230, 230, 236), "Metal": rgb(170, 176, 186)}, "Halberd"),
    ("KNIGHT", "Lionheart", (0, -0.6, 0), 180, dict(torso=(4, 0, 0), head=(-6, 0, 0), rarm=(70, 34, 0), larm=(70, -34, 0), rleg=(-12, 0, 8), lleg=(12, 0, -8)),
     {"Primary": rgb(190, 30, 34), "Secondary": rgb(240, 236, 228), "Accent": rgb(255, 200, 70), "Metal": rgb(236, 238, 244)}, "Greatsword"),
    ("MAGE", "Pyromancer", (3.2, 0.6, 0), 164, dict(torso=(0, 4, 0), head=(-4, 6, 0), rarm=(70, -24, 10), larm=(112, 0, -26), rleg=(-8, 0, 6), lleg=(10, 0, -6)),
     {"Primary": rgb(200, 50, 20), "Secondary": rgb(40, 20, 16), "Accent": rgb(255, 170, 40), "Metal": rgb(240, 190, 90)}, "staff"),
    ("VANGUARD", "Berserker", (6.1, 1.8, 0), 158, dict(torso=(0, 6, 0), head=(-4, 10, 0), rarm=(16, 0, 20), larm=(118, 0, -34), rleg=(-10, 0, 6), lleg=(14, 0, -6)),
     {"Primary": rgb(120, 70, 40), "Secondary": rgb(50, 36, 28), "Accent": rgb(200, 60, 40), "Metal": rgb(180, 182, 190)}, "BattleAxe"),
]


def lineup(out):
    setup()
    K.sky(top=rgb(20, 30, 110), horizon=rgb(255, 150, 60), strength=1.4, band=0.45)
    K.ground(240, K.stone_mat(rgb(120, 110, 100), rgb(60, 56, 52), 1.6))
    sunburst((0, 40, 7), 70, n=28, colors=(rgb(255, 200, 90), rgb(255, 110, 40)), strength=1.4)
    castle_backdrop(30, K.stone_mat(rgb(90, 80, 96), rgb(50, 44, 56), 1.2), K.flat_mat("roof", rgb(60, 40, 110), rough=0.6))
    labels = []
    cam = K.camera((0, -14.2, 2.9), (0, 0, 3.85), lens=30, focus=(0, -0.6, 3.5), fstop=4.0)
    for label, set_name, at, yaw, pose, cols, kit in CLASS_LINEUP:
        f, _ = K.figure(set_name, at=at, yaw=yaw, pose=pose, colors=cols, neon=2.6)
        if kit == "bow":   # (in the outer hand, so the line-up doesn't hide it)
            g = K.hand(f, "R").translation
            fwd = Vector((math.sin(math.radians(-yaw)) * -1, 0, 0))
            back = (f["Torso"].translation - g); back.z = 0
            drawn_bow(g + Vector((0, -0.2, 0.5)), g + Vector((0, -0.2, 0.5)) + back.normalized() * 0.5, height=4.8, bend=0.6,
                      color=rgb(196, 206, 236), trim=rgb(110, 160, 255))
        elif kit == "staff":
            K.staff("Emberwood", held(K.hand(f, "L"), (0.28, -0.15, 1), slide=-0.8), neon=4)
            K.fire(tuple(K.hand(f).translation + Vector((0, -0.25, 0.5))), r=0.45, strength=2.4, power=300, seed=12)
        elif kit == "Halberd":
            K.weapon(kit, held(K.hand(f), (0.04, 0, 1), slide=-0.6))
        elif kit == "Greatsword":   # planted point-down before him, both hands on the hilt
            K.weapon(kit, held(K.hand(f), (0, -0.06, -1), slide=0.2))
        else:   # the Vanguard's axe up in the left hand, out to the side
            K.weapon(kit, held(K.hand(f, "L"), (0.4, -0.25, 1), slide=-0.4))
        feet = Vector((at[0], at[1], 0))
        v = K.where(label, feet)
        K.where(label + " head", f["Head"].translation)
        labels.append((label, v))
    K.light("AREA", (0, -10, 9), rgb(200, 210, 255), 900, size=10, target=(0, 0, 3))
    K.light("AREA", (-9, 6, 7), rgb(120, 160, 255), 2400, size=6, target=(-2, 0, 4))
    K.light("AREA", (9, 6, 7), rgb(255, 150, 70), 2400, size=6, target=(2, 0, 4))
    K.bloom(0.45, 1.1, 0.7, saturation=1.12)
    K.render(base_of(out))
    W = 10 * 16 / 9
    items = list(LINEUP_TITLES)
    for label, v in labels:
        items.append({"text": label, "x": (v.x - 0.5) * W, "y": max(-4.45, (v.y - 0.5) * 10 - 0.3), "size": 0.5,
                      "fill": (rgb(255, 255, 255), rgb(255, 236, 200)), "outline": rgb(20, 14, 40), "ow": 0.08,
                      "plate": rgb(36, 30, 70), "plate_edge": rgb(255, 200, 80)})
    finish(out, items)


LINEUP_TITLES = [
    {"text": "5 CLASSES", "y": 3.55, "size": 1.8},
    {"text": "PICK YOUR FIGHTER", "y": 2.05, "size": 0.62, "fill": (rgb(255, 255, 255), rgb(255, 236, 200)),
     "outline": rgb(20, 14, 60), "ow": 0.07, "plate": rgb(40, 70, 200)},
]

# ------------------------------------------------------------------------
#  5. THE SIEGE: the Crown's charge, the Iron's castle burning behind
# ------------------------------------------------------------------------
def flag(frame, length=6.5, w=2.6, h=1.8, color=rgb(40, 80, 210), trim=rgb(255, 200, 70), wind=(1, 0, 0), name="Flag"):
    """a war banner on a pole held at `frame` (the pole along its +Y): the cloth streams from the
    top in the `wind` (world direction), rippling; a gold border and a crown-ish emblem"""
    import bmesh as _b
    top = frame @ Vector((0, length * 0.75, 0))
    pole = K.W.tube([tuple(frame @ Vector((0, -length * 0.25, 0))), tuple(top)], 0.08, rgb(90, 60, 34))
    knob = K.W.sphere(tuple(top + (frame.to_3x3() @ Vector((0, 0.15, 0)))), 0.16, trim)
    up = (frame.to_3x3() @ Vector((0, 1, 0))).normalized()
    wd = Vector(wind); wd = (wd - up * wd.dot(up)).normalized()
    side = up.cross(wd)
    nx, ny = 14, 8
    bm = _b.new()
    grid = []
    for j in range(ny + 1):
        row = []
        for i in range(nx + 1):
            u, v = i / nx, j / ny
            ripple = math.sin(u * 6.0 + v * 1.3) * 0.42 * u
            p = top - up * (v * h + u * u * 0.35) + wd * (u * w) + side * ripple
            row.append(bm.verts.new(tuple(p)))
        grid.append(row)
    for j in range(ny):
        for i in range(nx):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    K.paint(bm, color)
    cl = bm.loops.layers.color.get("Col")
    for idx, f in enumerate(bm.faces):   # a gold band along the edges, a gold block near the pole
        j, i = divmod(idx, nx)
        if j in (0, ny - 1) or i == nx - 1 or (2 <= i <= 4 and 2 <= j <= 5):
            for lp in f.loops:
                lp[cl] = (*trim, 1)
    out = [K.obj(name + "Pole", K.W.merge(pole, knob), K.mat("grip"), K.Matrix())]
    o = K.obj(name, bm, K.mat("cloth"), K.Matrix())
    o.data.shade_smooth()
    out.append(o)
    return out


SIEGE_CHARGE = [
    # (set, at, yaw, pose, kit, colours)
    ("SunKnights", (-1.6, -2.4, 0), 170, dict(torso=(-16, 0, 0), head=(14, 0, 0), rarm=(150, 0, 14), larm=(-30, 0, -20), rleg=(-40, 0, 4), lleg=(44, 0, -4), drop=-0.25),
     "Longsword", None),
    ("RiverGuard", (3.6, 1.2, 0), 192, dict(torso=(-14, 0, 0), head=(12, 0, 0), rarm=(150, 0, 16), larm=(40, 0, -10), rleg=(42, 0, 4), lleg=(-36, 0, -4), drop=-0.25),
     "WarAxe", None),
    ("Sellswords", (-6.2, 3.0, 0), 164, dict(torso=(-14, 0, 0), head=(12, 0, 0), rarm=(150, 0, 20), larm=(-36, 0, -16), rleg=(46, 0, 4), lleg=(-34, 0, -4), drop=-0.25),
     "Mace", None),
    ("TourneyKnight", (8.4, 5.2, 0), 198, dict(torso=(-14, 0, 0), head=(12, 0, 0), rarm=(150, 0, 22), larm=(-30, 0, -16), rleg=(-38, 0, 4), lleg=(40, 0, -4), drop=-0.25),
     "Greatsword", None),
    ("GambesonSkin", (6.0, 8.0, 0), 186, dict(torso=(-14, 0, 0), head=(10, 0, 0), rarm=(150, 0, 10), larm=(-20, 0, -14), rleg=(40, 0, 4), lleg=(-36, 0, -4), drop=-0.25),
     "flag", None),
    ("KnightSkin", (-10.5, 7.5, 0), 160, dict(torso=(-14, 0, 0), head=(12, 0, 0), rarm=(150, 0, 18), larm=(-30, 0, -16), rleg=(-40, 0, 4), lleg=(42, 0, -4), drop=-0.25),
     "Zweihander", None),
    ("RoadLevy", (-2.6, 9.0, 0), 176, dict(torso=(-14, 0, 0), head=(12, 0, 0), rarm=(150, 0, 18), larm=(-30, 0, -16), rleg=(40, 0, 4), lleg=(-38, 0, -4), drop=-0.25),
     "Halberd", None),
]
CROWN = {"Primary": rgb(44, 86, 214), "Secondary": rgb(232, 232, 238), "Accent": rgb(255, 200, 70), "Metal": rgb(214, 218, 228)}


def siege(out):
    setup()
    K.sky(top=rgb(40, 14, 30), horizon=rgb(255, 96, 30), strength=1.5, band=0.3)
    K.fog(0.006, rgb(255, 120, 70), 0.6, size=(220, 70, 16), center=(0, 60, 6))
    K.ground(240, K.stone_mat(rgb(110, 96, 80), rgb(60, 52, 44), 1.8))
    # the Iron's castle: a gatehouse between two big towers, red banners, fire on the walls
    stone = K.stone_mat(rgb(110, 100, 96), rgb(56, 50, 50), 1.2)
    roof = K.flat_mat("roof", rgb(120, 24, 24), rough=0.6)
    K.wall((-40, 34, 0), (40, 34, 0), 12, 3, stone)
    for x, rr, h in ((-30, 4, 20), (-9, 5, 26), (9, 5, 26), (30, 4, 20)):
        K.tower((x, 36, 0), rr, h, stone, roof)
    K.block("Gate", (0, 32.4, 4.5), (7, 0.6, 9), K.flat_mat("gate", rgb(40, 26, 18), rough=0.8))
    for x in (-18, -4, 4, 18):
        K.block("IronBanner", (x, 32.3, 7.5), (2.6, 0.1, 6.5), K.flat_mat("ib", rgb(170, 20, 20), rough=0.85, emit=0.1))
    for k, (x, y, z, r) in enumerate(((-20, 33, 12, 1.5), (-9, 35, 26.5, 1.2), (14, 33, 12, 1.7), (30, 35, 20, 1.1), (-31, 35, 20, 1.0), (4, 33, 12, 1.0))):
        K.blaze((x, y, z), size=r * 1.5, seed=30 + k, power=1800)
    K.embers((-30, 10, 2), (30, 36, 30), n=500, color=rgb(255, 120, 30), seed=5, size=(0.03, 0.09), strength=8)
    cam = K.camera((0.4, -15.5, 1.8), (0.2, 0, 5.4), lens=27, focus=(-1.6, -2.4, 4), fstop=3.2)
    # the charge
    for i, (set_name, at, yaw, pose, kit, cols) in enumerate(SIEGE_CHARGE):
        f, _ = K.figure(set_name, at=at, yaw=yaw, pose=pose, colors=cols or CROWN, neon=2.5)
        if kit == "flag":
            flag(held(K.hand(f), (0.1, 0.05, 1), slide=0), length=8, w=3.4, h=2.3, wind=(1, 0.25, 0), color=rgb(40, 80, 210), name=f"Flag{i}")
        else:
            K.weapon(kit, held(K.hand(f), (0.3 * (1 if at[0] > 0 else -1), -0.45, 1), roll=90))
        if i == 0:
            K.where("hero head", f["Head"].translation)
    K.light("AREA", (0, -12, 8), rgb(150, 170, 255), 900, size=10, target=(0, 0, 3))
    K.light("AREA", (-10, 12, 9), rgb(255, 120, 50), 4000, size=8, target=(-1, 0, 4))
    K.light("AREA", (10, 12, 9), rgb(255, 120, 50), 4000, size=8, target=(1, 0, 4))
    K.bloom(0.5, 1.0, 0.75, saturation=1.12)
    K.render(base_of(out))
    finish(out, SIEGE_TITLES)


SIEGE_TITLES = [
    {"text": "STORM THE CASTLE", "y": 3.6, "size": 1.6},
    {"text": "6 BATTLE MODES", "y": 2.2, "size": 0.62, "fill": (rgb(255, 255, 255), rgb(255, 236, 200)),
     "outline": rgb(70, 6, 6), "ow": 0.07, "plate": rgb(40, 80, 210)},
]

# ------------------------------------------------------------------------
#  THE ICON (512²): a crowned knight's helm over crossed swords, a burst of blue behind
# ------------------------------------------------------------------------
def frame_at(pos, direction, face=(0, -1, 0), scale=1.0, fat=1.0):
    """a weapon's frame: its +Y (blade) along `direction`, its flat (+Z) toward `face`;
    `fat` widens it (a badge's little sword would be a needle otherwise)"""
    y = Vector(direction).normalized()
    z = Vector(face); z = (z - y * z.dot(y)).normalized()
    x = y.cross(z)
    M = K.Matrix((x, y, z)).transposed().to_4x4()
    M.translation = Vector(pos)
    return M @ K.Matrix.Diagonal((scale * fat, scale, scale, 1))


LIONHEART = {"Primary": rgb(190, 30, 34), "Secondary": rgb(240, 236, 228), "Accent": rgb(255, 200, 70), "Metal": rgb(236, 238, 244)}


def icon(out):
    setup((512, 512))
    K.sky(top=rgb(10, 20, 70), horizon=rgb(40, 80, 200), strength=1.0, band=0.5)
    sunburst((0, 9, 4.3), 30, n=22, colors=(rgb(70, 130, 255), rgb(30, 60, 190)), strength=1.6, facing=(0.1, -1, 0.05))
    f, _ = K.figure("Lionheart", at=(0, 0, 0), yaw=192, pose=dict(head=(-8, 6, 0), rarm=(10, 0, 8), larm=(10, 0, -8)), colors=LIONHEART)
    for z in (-0.66, -0.72, -0.78):   # eyes burning behind the visor's slit
        for sx in (-1, 1):
            K.obj("Eye", K.sphere_bm((sx * 0.21, 0.13, z), 0.075, (1.3, 0.7, 0.5)), K.flat_mat("eye", rgb(120, 200, 255), emit=16), f["Head"])
    for sx in (-1, 1):   # the swords, crossed behind the helm, their points to the corners
        K.weapon("Longsword", frame_at((sx * 1.0, 1.4, 2.6), (-sx * 0.62, 0, 1), face=(0, -1, 0), scale=1.4))
    K.light("AREA", (-3, -6, 7), rgb(255, 236, 210), 700, size=4, target=(0, 0, 4.4))
    K.light("AREA", (4, -4, 3), rgb(140, 170, 255), 250, size=4, target=(0, 0, 4.4))
    K.light("AREA", (0, 4, 8), rgb(255, 200, 120), 900, size=3, target=(0, 0, 4.6))
    K.camera((1.1, -8.0, 4.6), (0, 0, 4.95), lens=55, focus=(0, 0, 4.5), fstop=8)
    K.bloom(0.4, 1.2, 0.6, saturation=1.1)
    K.render(base_of(out))
    finish(out, [], res=(512, 512))


# ------------------------------------------------------------------------
#  BADGES (512², shown in a circle): a medallion each, its emblem standing out of it
# ------------------------------------------------------------------------
RIMS = {"bronze": rgb(214, 132, 60), "silver": rgb(210, 216, 226), "gold": rgb(255, 196, 60), "iron": rgb(130, 134, 144),
        "mythic": rgb(255, 70, 90)}


def medallion(rim, field):
    lighter = tuple(min(1, c * 1.5 + 0.08) for c in field)
    K.obj("Field", K.W.disc((0, 0, 0), 1.96, 0.3, field, axis="y"), K.flat_mat("field", field, rough=0.6, emit=0.35), K.Matrix())
    sunburst((0, -0.16, 0), 1.86, n=20, colors=(lighter, field), strength=0.55, facing=(0, -1, 0))
    n = 72
    ring = [(math.cos(a) * 2.0, -0.08, math.sin(a) * 2.0) for a in [i / n * 2 * math.pi for i in range(n + 1)]]
    inner = [(math.cos(a) * 1.76, -0.17, math.sin(a) * 1.76) for a in [i / n * 2 * math.pi for i in range(n + 1)]]
    studs = [K.W.sphere((math.cos(a) * 2.0, -0.26, math.sin(a) * 2.0), 0.08, tuple(min(1, c * 1.15) for c in rim))
             for a in [i / 12 * 2 * math.pi + math.pi / 12 for i in range(12)]]
    K.obj("Rim", K.W.merge(K.W.tube(ring, 0.22, rim, n=12, caps=False), K.W.tube(inner, 0.055, rim, n=8, caps=False), *studs), K.mat("metal"), K.Matrix())


def upright(bm):
    """a lathe (about Y) stood up about Z"""
    for v in bm.verts:
        v.co = Vector((v.co.x, v.co.z, v.co.y))
    return bm


def em_welcome():
    stone = rgb(200, 190, 176)
    body = upright(K.W.lathe([(0.0, -1.55), (0.62, -1.55), (0.62, 0.45), (0.78, 0.45), (0.78, 0.78), (0.0, 0.78)], stone, n=24))
    M = T(0, -0.7, -0.26) @ K.Matrix.Diagonal((0.84, 0.84, 0.84, 1))
    K.obj("Keep", body, K.stone_mat(rgb(200, 190, 176), rgb(140, 130, 118), 0.25), M)
    K.obj("KeepRoof", K.W.cone((0, 0, 0.78), (0, 0, 1.62), 0.92, rgb(60, 90, 220), n=24), K.mat("cloth"), M)
    K.obj("Gate", K.W.box(0, -0.62, -1.15, 0.5, 0.06, 0.72, rgb(50, 32, 20)), K.mat("grip"), M)
    K.obj("Window", K.W.box(0, -0.62, -0.05, 0.22, 0.06, 0.34, rgb(255, 200, 90)), K.flat_mat("win", rgb(255, 190, 80), emit=4), M)
    flag(M @ frame_at((0, 0, 1.45), (0, 0, 1)), length=0.75, w=0.8, h=0.48, wind=(1, 0, 0), color=rgb(255, 196, 60), trim=rgb(200, 40, 40), name="WFlag")


def em_graduate():
    K.obj("Shield", K.W.disc((0, -0.45, 0.15), 1.2, 0.18, rgb(150, 98, 52), axis="y"), K.mat("grip"), K.Matrix())
    ring = [(math.cos(a) * 1.2, -0.55, math.sin(a) * 1.2 + 0.15) for a in [i / 48 * 2 * math.pi for i in range(49)]]
    K.obj("ShieldRim", K.W.merge(K.W.tube(ring, 0.08, rgb(170, 176, 186), caps=False), K.W.sphere((0, -0.6, 0.15), 0.3, rgb(190, 196, 206))), K.mat("metal"), K.Matrix())
    K.weapon("ArmingSword", frame_at((-0.85, -1.0, -1.05), (0.62, 0, 1), scale=0.78, fat=1.7))


def em_firstblood():
    K.weapon("Longsword", frame_at((0, -0.8, 1.05), (0, 0, -1), scale=0.68, fat=1.8))
    K.sparks((0, -0.9, -1.3), n=40, color=rgb(255, 40, 30), spread=1.0, length=0.35, power=60, seed=3, strength=3)
    K.obj("Gem", K.W.sphere((0, -1.05, 0.62), 0.13, rgb(255, 30, 40)), K.flat_mat("gem", rgb(255, 30, 40), emit=3), K.Matrix())


def em_firstwin():
    gold = rgb(255, 196, 60)
    cup = upright(K.W.lathe([(0.0, -1.5), (0.78, -1.5), (0.78, -1.3), (0.34, -1.18), (0.16, -0.95), (0.16, -0.55), (0.36, -0.42),
                             (0.86, 0.05), (0.98, 0.95), (0.9, 1.0), (0.0, 1.0)], gold, n=32))
    handles = []
    for sx in (-1, 1):
        pts = [(sx * (0.9 + 0.42 * math.sin(t * math.pi)), 0, 0.75 - t * 0.8) for t in [k / 10 for k in range(11)]]
        handles.append(K.W.tube(pts, 0.08, gold))
    K.obj("Trophy", K.W.merge(cup, *handles), K.mat("metal"), T(0, -0.7, 0))
    K.sparks((0, -1.0, 0.9), n=24, color=rgb(255, 230, 140), spread=1.4, length=0.3, power=40, seed=7, strength=3)


def em_level5():
    drawn_bow((-0.35, -0.8, 0.0), (0.2, -0.8, -0.35), up=(-0.45, 0, 0.9), height=3.3, bend=0.45, color=rgb(120, 70, 36), trim=rgb(255, 196, 60))
    K.staff("Stormcaller", frame_at((0.5, -1.1, -1.1), (0.4, 0, 1), scale=0.56, fat=1.4), neon=4)


def em_level25():
    _, objs = K.figure("Lionheart", at=(0, 0, 0), yaw=180, pose=dict(head=(-6, 0, 0)), colors=LIONHEART)
    S = T(0, -0.9, 0.12) @ K.Matrix.Diagonal((1.25, 1.25, 1.25, 1)) @ T(0, 0, -4.5)
    for o in objs:
        if "_Head" not in o.name:
            K.bpy.data.objects.remove(o)
        else:
            o.matrix_world = S @ o.matrix_world


def em_champion():
    gold = rgb(255, 196, 60)
    K.weapon("Longsword", frame_at((-1.05, -0.5, -1.2), (0.62, 0, 1), scale=0.7, fat=1.7))
    n = 48
    band = [(math.cos(a) * 0.95, math.sin(a) * 0.95, 0) for a in [i / n * 2 * math.pi for i in range(n + 1)]]
    parts = [K.W.tube(band, 0.2, gold, n=10, caps=False)]
    gems = []
    for k in range(5):
        a = k / 5 * 2 * math.pi - math.pi / 2
        b = (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.15)
        parts.append(K.W.cone(b, (b[0] * 1.08, b[1] * 1.08, 1.05), 0.2, gold))
        parts.append(K.W.sphere((b[0] * 1.08, b[1] * 1.08, 1.1), 0.12, gold))
        gems.append(K.W.sphere((math.cos(a + 0.63) * 1.12, math.sin(a + 0.63) * 1.12, 0), 0.12, rgb(200, 30, 60)))
    M = T(0, -1.0, -0.25) @ R(-22, 0, 0)
    K.obj("Crown", K.W.merge(*parts), K.mat("metal"), M)
    K.obj("CrownGems", K.W.merge(*gems), K.flat_mat("cgem", rgb(220, 30, 70), emit=1.5), M)


def em_gauntlet10():
    pts = []
    for k in range(13):   # a heater shield: a flat top, the sides curving to a point
        t = k / 12
        pts.append((1.15 * (1 - t ** 2.2), 1.1 - t * 2.6))
    outline = [(-x, z) for x, z in reversed(pts)] + pts[1:]
    bm = K.bmesh.new()
    front = [bm.verts.new((x, -0.12, z)) for x, z in outline]
    back = [bm.verts.new((x, 0.12, z)) for x, z in outline]
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(len(outline)):
        j = (i + 1) % len(outline)
        bm.faces.new((front[i], front[j], back[j], back[i]))
    K.paint(bm, rgb(110, 114, 124))
    K.obj("Shield", bm, K.mat("metal"), T(0, -0.8, -0.05))
    edge = [(x * 1.02, -0.95, z - 0.05) for x, z in outline + [outline[0]]]
    K.obj("ShieldEdge", K.W.tube(edge, 0.07, rgb(200, 160, 70), caps=False), K.mat("metal"), K.Matrix())
    for x, z, sz, sd in ((-1.15, -0.9, 0.55, 9), (1.15, -0.9, 0.55, 10), (-0.6, -1.45, 0.5, 11), (0.6, -1.45, 0.5, 12)):
        K.blaze((x, -0.5, z), size=sz, seed=sd, power=60, strength=2.2)


def em_mythic():
    bm = K.bmesh.new()
    top, bot = bm.verts.new((0, 0, 1.45)), bm.verts.new((0, 0, -1.45))
    ring_a = [bm.verts.new((math.cos(a) * 0.72, math.sin(a) * 0.72, 0.28)) for a in [k / 6 * 2 * math.pi for k in range(6)]]
    ring_b = [bm.verts.new((math.cos(a) * 0.72, math.sin(a) * 0.72, -0.28)) for a in [k / 6 * 2 * math.pi for k in range(6)]]
    for k in range(6):
        j = (k + 1) % 6
        bm.faces.new((top, ring_a[k], ring_a[j]))
        bm.faces.new((ring_a[k], ring_b[k], ring_b[j], ring_a[j]))
        bm.faces.new((ring_b[j], ring_b[k], bot))
    K.paint(bm, rgb(255, 60, 90))
    o = K.obj("Crystal", bm, K.flat_mat("crystal", rgb(235, 20, 70), rough=0.1, emit=0.7), T(0, -0.9, 0) @ R(0, 0, 20))
    o.data.shade_flat()
    K.obj("CrystalCore", K.W.sphere((0, -0.9, 0), 0.32, rgb(255, 230, 200)), K.flat_mat("ccore", rgb(255, 220, 190), emit=8), K.Matrix())
    K.sparks((0, -1.0, 0), n=36, color=rgb(255, 210, 120), spread=1.7, length=0.3, power=80, seed=13, strength=3.5)
    K.light("POINT", (0, -1.6, 0), rgb(255, 80, 120), 120, 0.4)


def em_beta():
    K.weapon("Hammer", frame_at((-0.75, -0.8, -1.3), (0.42, 0, 1), scale=1.05, fat=1.3))
    K.sparks((0.3, -1.1, 0.85), n=30, color=rgb(255, 200, 90), spread=0.9, length=0.3, power=40, seed=17, strength=3)


BADGE_ART = {
    # key: (rim, field, emblem, text laid over it)
    "Welcome": ("bronze", rgb(40, 90, 200), em_welcome, []),
    "Graduate": ("bronze", rgb(40, 140, 70), em_graduate, []),
    "FirstBlood": ("silver", rgb(170, 20, 30), em_firstblood, []),
    "FirstWin": ("gold", rgb(36, 70, 200), em_firstwin, []),
    "Level5": ("silver", rgb(20, 130, 140), em_level5, []),
    "Level25": ("gold", rgb(120, 20, 30), em_level25,
                [{"text": "25", "y": -2.45, "size": 1.9, "ow": 0.1}]),
    "Champion": ("gold", rgb(90, 30, 160), em_champion, []),
    "Gauntlet10": ("iron", rgb(150, 50, 20), em_gauntlet10,
                   [{"text": "10", "y": 0.1, "size": 1.9, "fill": (rgb(255, 255, 255), rgb(220, 224, 232)), "outline": rgb(30, 30, 36), "ow": 0.09}]),
    "Mythic": ("mythic", rgb(110, 10, 60), em_mythic, []),
    "BetaTester": ("silver", rgb(30, 100, 170), em_beta,
                   [{"text": "BETA", "y": -2.25, "size": 1.3, "fill": (rgb(255, 255, 255), rgb(220, 240, 255)), "outline": rgb(10, 30, 60),
                     "ow": 0.08, "plate": rgb(30, 130, 220), "plate_edge": rgb(210, 216, 226)}]),
}


def badge(out, key):
    rim, field, emblem, items = BADGE_ART[key]
    setup((512, 512))
    K.sky(top=rgb(14, 12, 24), horizon=rgb(70, 66, 90), strength=0.9, band=0.6)
    medallion(RIMS[rim], field)
    emblem()
    K.light("AREA", (-3, -7, 4), rgb(255, 244, 228), 420, size=5, target=(0, 0, 0))
    K.light("AREA", (4, -6, -3), rgb(170, 190, 255), 160, size=5, target=(0, 0, 0))
    K.light("AREA", (0, 3, 5), rgb(255, 220, 160), 300, size=3, target=(0, -0.6, 0))
    cam = K.camera((0, -20, 0), (0, 0, 0), lens=50)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 4.62
    K.bloom(0.35, 1.2, 0.5, saturation=1.1)
    K.render(base_of(out))
    finish(out, items, res=(512, 512))


def badges(out_dir):
    for key in BADGE_ART:
        badge(os.path.join(out_dir, f"badge_{key}.png"), key)


MAGE_TITLES = [
    {"text": "MASTER MAGIC", "y": 3.6, "size": 1.75, "fill": (rgb(240, 220, 255), rgb(170, 90, 255)), "outline": rgb(30, 8, 60)},
    {"text": "FIRE  •  LIGHTNING  •  FROST", "y": 2.1, "size": 0.58, "fill": (rgb(255, 255, 255), rgb(240, 230, 255)),
     "outline": rgb(30, 8, 60), "ow": 0.07, "plate": rgb(110, 50, 200), "plate_edge": rgb(255, 214, 110)},
]

CLASH_TITLES = [
    {"text": "STEEL & GLORY", "y": 3.55, "size": 1.75},
    {"text": "EVERY SWING IS YOURS", "y": 2.05, "size": 0.62, "fill": (rgb(255, 255, 255), rgb(255, 236, 200)),
     "outline": rgb(70, 6, 6), "ow": 0.07, "plate": rgb(176, 22, 22)},
]

SCENES = {"clash": clash, "mage": mage, "archer": archer, "lineup": lineup, "siege": siege, "icon": icon}
TITLES = {"clash": CLASH_TITLES, "mage": MAGE_TITLES, "archer": ARCHER_TITLES, "siege": SIEGE_TITLES}   # (the line-up's labels need its render)

if __name__ == "__main__":
    name, out = ARGS[0], os.path.abspath(ARGS[1])
    if name.startswith("retitle:"):   # titles only, over the last render of that scene
        finish(out, TITLES[name.split(":", 1)[1]])
    elif name.startswith("badge:"):
        badge(out, name.split(":", 1)[1])
    elif name == "badges":   # <out> is a folder
        badges(out)
    else:
        SCENES[name](out)
