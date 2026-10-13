"""STORE VIDEO — Steel & Glory's trailer (~24 s, 1920×1080, 30 fps), rendered in Blender from the
game's own armour, weapons, staffs and spells (blender/art_kit.py), then cut together with its
title cards and written as an MP4.

    blender.exe -b --python blender/store_video.py -- titles
    blender.exe -b --python blender/store_video.py -- shot:<name> [--preview] [--frames a-b] [--every n] [--at 0,30,41]
    blender.exe -b --python blender/store_video.py -- edit [--preview] [--stills 40,300]
    shots: swing · parry · magic · archer · siege · lineup · end   (all: every shot, then the edit)

Frames go to store_art/video/frames/<shot>/####.png, the cards to store_art/video/titles, the film
to store_art/video/trailer.mp4 (--preview: half size, few samples: trailer_preview.mp4).

What it's for: a Roblox video ad (Ads Manager: MP4, 15-30 s, 16:9, 720p-1080p, under 100 MB; it
plays MUTED, so the words are on screen) and YouTube / TikTok. NOT the game page's video
preview: Roblox wants real gameplay there (record it in a game, see docs/LAUNCH.md).
No blood: the game is rated Mild. Silent: add music from Roblox's own library if you like."""
import bpy, math, os, sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import art_kit as K  # noqa: E402
from art_kit import rgb, T, R, ease, blend_pose, look  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VID = os.path.join(ROOT, "store_art", "video")
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREVIEW = "--preview" in ARGS
FPS = 30
RES = (1920, 1080)


def _arg(flag, default=None):
    return ARGS[ARGS.index(flag) + 1] if flag in ARGS and ARGS.index(flag) + 1 < len(ARGS) else default


def lerp(a, b, t):
    return Vector(a).lerp(Vector(b), t)


def keyed(keys, f, kind="inout"):
    """a value along keyframes [(frame, value)…] (numbers, tuples or pose dicts), eased between"""
    if f <= keys[0][0]:
        return keys[0][1]
    for (f0, v0), (f1, v1) in zip(keys, keys[1:]):
        if f <= f1:
            t = ease((f - f0) / max(1e-6, f1 - f0), kind)
            if isinstance(v0, dict):
                return blend_pose(v0, v1, t)
            if isinstance(v0, (int, float)):
                return v0 + (v1 - v0) * t
            return tuple(lerp(v0, v1, t))
    return keys[-1][1]


def setup():
    sc = K.setup(RES, samples=12 if PREVIEW else 20, scale=0.5 if PREVIEW else 1.0)
    sc.render.use_persistent_data = True   # (between frames only the moved objects update)
    sc.render.fps = FPS
    return sc


# ------------------------------------------------------------------------
#  EFFECTS THAT MOVE: built once at the origin, then placed / grown / hidden each frame
# ------------------------------------------------------------------------
class Burst:
    """sparks (or a fireball) that flash at a point and die away: show(at, f0) then step(f)"""
    def __init__(self, kind="sparks", color=rgb(255, 236, 170), size=2.4, life=10, power=900, n=80, strength=4):
        before = set(bpy.data.objects)
        if kind == "fire":
            K.fire((0, 0, 0), r=size * 0.45, strength=2.4, power=power, seed=7)
        else:
            K.sparks((0, 0, 0), n=n, color=color, spread=size, length=0.6, power=power, strength=strength)
        self.objs = [o for o in bpy.data.objects if o not in before]
        self.base = {o: o.matrix_world.copy() for o in self.objs}
        self.light = {o: o.data.energy for o in self.objs if o.type == "LIGHT"}
        self.life, self.at, self.f0 = life, Vector(), None
        self._hide(True)

    def _hide(self, h):
        for o in self.objs:
            o.hide_render = h

    def show(self, at, f0):
        self.at, self.f0 = Vector(at), f0

    def step(self, f):
        if self.f0 is None or f < self.f0 or f > self.f0 + self.life:
            self._hide(True)
            return
        t = (f - self.f0) / self.life
        s = 0.35 + 0.9 * ease(min(1, t * 3), "out")            # bursts out fast…
        fade = 1 - ease(max(0, (t - 0.35) / 0.65), "in")         # …and dies away
        self._hide(False)
        for o in self.objs:
            if o.type == "LIGHT":
                o.location = self.at
                o.data.energy = self.light[o] * fade
            else:
                o.matrix_world = T(*self.at) @ Matrix.Diagonal((s * max(fade, 0.05),) * 3 + (1,)) @ self.base[o]


class Mover:
    """objects that travel (a fireball, an arrow): place(at, toward) each frame; hide()"""
    def __init__(self, objs):
        self.objs = list(objs)
        self.base = {o: o.matrix_world.copy() for o in self.objs}

    def place(self, at, toward=None, scale=1.0):
        M = T(*at)
        if toward is not None:
            d = (Vector(toward) - Vector(at))
            if d.length > 1e-4:
                M = M @ d.normalized().to_track_quat("Y", "Z").to_matrix().to_4x4()
        for o in self.objs:
            o.hide_render = False
            if o.type == "LIGHT":
                o.location = at
            else:
                o.matrix_world = M @ Matrix.Diagonal((scale,) * 3 + (1,)) @ self.base[o]

    def hide(self):
        for o in self.objs:
            o.hide_render = True


def made_since(before):
    return [o for o in bpy.data.objects if o not in before]


# ------------------------------------------------------------------------
#  THE SHOTS: each builds its stage and returns (frame count, step(f) that poses frame f)
# ------------------------------------------------------------------------
import store_art as S  # noqa: E402

SUNK = {"Primary": rgb(40, 90, 220), "Secondary": rgb(230, 230, 236), "Accent": rgb(240, 190, 70), "Metal": rgb(230, 232, 238)}
BLACK = {"Primary": rgb(160, 24, 24), "Secondary": rgb(30, 26, 28), "Accent": rgb(200, 30, 30), "Metal": rgb(60, 60, 66)}
LION = {"Primary": rgb(190, 30, 34), "Secondary": rgb(240, 236, 228), "Accent": rgb(255, 200, 70), "Metal": rgb(236, 238, 244)}
IRON = {"Primary": rgb(30, 30, 36), "Secondary": rgb(20, 20, 24), "Accent": rgb(200, 40, 40), "Metal": rgb(70, 72, 80)}
SAGE = {"Primary": rgb(70, 40, 170), "Secondary": rgb(24, 18, 60), "Accent": rgb(255, 214, 110), "Metal": rgb(230, 220, 255)}
PHOENIX = {"Primary": rgb(196, 40, 30), "Secondary": rgb(60, 26, 16), "Accent": rgb(255, 196, 80), "Metal": rgb(232, 184, 74)}


def wield(rig, objs, st, side="R", key="dir", slide=0.0, roll=90):
    """keep a weapon in a hand, its blade along st[key] (a world direction, keyed per frame)"""
    rig.attach(objs, lambda f: S.held(K.hand(f, side), Vector(st[key]), slide=st.get(key + "_slide", slide), roll=roll))


def sunset_stage():
    K.sky(top=rgb(10, 8, 34), horizon=rgb(255, 110, 25), strength=1.5, band=0.24)
    K.ground(240, K.stone_mat(rgb(96, 86, 76), rgb(44, 40, 36), 1.6))
    S.castle_backdrop(46)
    K.obj("Sun", K.sphere_bm((0, 120, 16), 9, color=(1, 0.8, 0.5), segs=48), K.flat_mat("sun", rgb(255, 190, 110), emit=30))
    K.light("SUN", (0, 0, 0), rgb(255, 160, 90), 1.6)
    sun = [o for o in bpy.data.objects if o.type == "LIGHT" and o.data.type == "SUN"][-1]
    sun.rotation_euler = (math.radians(72), 0, math.radians(180))
    K.light("AREA", (-8, -10, 8), rgb(120, 160, 255), 500, size=8, target=(0, 0, 3))
    K.light("AREA", (0, 9, 7), rgb(255, 200, 140), 2500, size=6, target=(0, 0, 4))
    K.embers((-10, -6, 0), (10, 30, 9), n=200)


def shot_swing():
    """AIM EVERY SWING: the Sun Knight brings a greatsword over and down on the Blackguard"""
    sunset_stage()
    st = {"dir": (-0.6, -0.15, 0.8), "fdir": (0.7, -0.1, 0.7)}
    hero = K.Rig("SunKnights", at=(1.7, 0.2, 0), yaw=104, colors=SUNK)
    wield(hero, K.weapon("Greatsword", Matrix()), st)
    foe = K.Rig("Blackguard", at=(-1.9, 0.6, 0), yaw=-84, colors=BLACK)
    wield(foe, K.weapon("Zweihander", Matrix()), st, key="fdir")
    hit = Burst(size=1.7, n=70, power=1200)
    flash = Burst(color=rgb(255, 255, 255), size=0.9, n=30, power=500, strength=6, life=6)
    # two hands on the hilt all the way (arms turned in), the blade aimed by world direction
    rest = dict(torso=(6, 0, 0), head=(-4, 0, 0), rarm=(40, 30, 0), larm=(40, -30, 0), rleg=(-14, 0, 6), lleg=(16, 0, -6))
    wind = dict(torso=(-12, -18, 0), head=(-2, 10, 0), rarm=(165, 30, 0), larm=(165, -30, 0), rleg=(-20, 0, 6), lleg=(24, 0, -6))
    strike = dict(torso=(24, 14, 0), head=(-12, -6, 0), rarm=(36, 30, 0), larm=(36, -30, 0), rleg=(-36, 0, 6), lleg=(30, 0, -6))
    hero_keys = [(0, rest), (24, wind), (32, wind), (40, strike), (72, strike), (90, blend_pose(strike, rest, 0.4))]
    blade_keys = [(0, (-0.6, -0.15, 0.8)), (24, (0.75, 0.1, 0.6)), (32, (0.75, 0.1, 0.6)), (36, (-0.1, -0.1, 1)), (40, (-0.9, -0.2, -0.35)),
                  (72, (-0.9, -0.2, -0.35)), (90, (-0.7, -0.2, 0.2))]
    frest = dict(torso=(8, 0, 0), head=(-4, 0, 0), rarm=(50, 24, 0), larm=(50, -24, 0), rleg=(-16, 0, 6), lleg=(18, 0, -6))
    freel = dict(torso=(-24, 14, 8), head=(18, 12, 0), rarm=(20, 0, 50), larm=(10, 0, -60), rleg=(18, 0, 10), lleg=(-12, 0, -10))
    foe_keys = [(0, frest), (38, frest), (46, freel), (90, blend_pose(freel, frest, 0.3))]
    fblade = [(0, (0.6, -0.1, 0.8)), (38, (0.6, -0.1, 0.8)), (46, (0.2, 0.3, 1)), (90, (0.5, 0.1, 0.9))]
    cam = K.camera((0.6, -9.6, 2.2), (0, 0, 4.2), lens=30, focus=(0, 0, 4.2), fstop=3.2)
    K.bloom(0.5, 1.2, 0.7, saturation=1.1)

    def step(f):
        st["dir"], st["fdir"] = keyed(blade_keys, f), keyed(fblade, f)
        hero.set(keyed(hero_keys, f), at=(1.7 - 0.6 * ease(f / 40), 0.2, 0))
        fr = foe.set(keyed(foe_keys, f), at=tuple(lerp((-1.9, 0.6, 0), (-3.1, 1.5, 0), ease((f - 40) / 30, "out"))))
        if f == 40:
            p = fr["Torso"].translation + Vector((0.8, -0.4, 1.0))
            hit.show(p, f)
            flash.show(p, f)
        hit.step(f)
        flash.step(f)
        look(cam, lerp((0.6, -9.6, 2.2), (0.2, -7.4, 2.9), ease(f / 90)), (-0.1, 0, 4.2))
    return 90, step


def shot_parry():
    """PARRY!: the Blackguard's zweihander comes down, the Lionheart turns it in a burst of light"""
    sunset_stage()
    st = {"dir": (-0.75, -0.1, 0.65), "adir": (0.3, -0.1, 0.95)}
    dfd = K.Rig("Lionheart", at=(1.7, 0.4, 0), yaw=150, colors=LION)
    wield(dfd, K.weapon("Longsword", Matrix()), st)
    atk = K.Rig("Blackguard", at=(-2.7, 1.3, 0), yaw=-70, colors=BLACK)
    wield(atk, K.weapon("Zweihander", Matrix()), st, key="adir")
    burst = Burst(size=1.7, n=80, power=1600, strength=5, life=12)
    flash = Burst(color=rgb(255, 255, 255), size=1.1, n=34, power=900, strength=8, life=7)
    guard = dict(torso=(6, 18, 0), head=(-8, 22, 0), rarm=(118, 34, 0), larm=(118, -34, 0), rleg=(-14, 0, 8), lleg=(16, 0, -6))
    low = dict(torso=(4, 10, 0), head=(-6, 16, 0), rarm=(50, 30, 0), larm=(50, -30, 0), rleg=(-14, 0, 8), lleg=(16, 0, -6))
    riposte = dict(torso=(20, 4, 0), head=(-10, 8, 0), rarm=(70, 30, 0), larm=(70, -30, 0), rleg=(-34, 0, 8), lleg=(26, 0, -6))
    d_keys = [(0, low), (20, guard), (30, guard), (34, blend_pose(guard, low, 0.2)), (56, guard), (66, riposte), (90, riposte)]
    d_blade = [(0, (-0.7, -0.2, 0.5)), (20, (-0.75, -0.1, 0.65)), (56, (-0.75, -0.1, 0.65)), (66, (-0.95, -0.2, 0.1)), (90, (-0.95, -0.2, 0.1))]
    a_up = dict(torso=(-14, -10, 0), head=(-4, -8, 0), rarm=(170, 30, 0), larm=(170, -30, 0), rleg=(-20, 0, 6), lleg=(22, 0, -4))
    a_hit = dict(torso=(12, -10, 0), head=(-4, -8, 0), rarm=(118, 30, 0), larm=(118, -30, 0), rleg=(-24, 0, 6), lleg=(24, 0, -4))
    a_thrown = dict(torso=(-26, -16, 6), head=(14, -10, 0), rarm=(176, 0, 40), larm=(160, 0, -50), rleg=(14, 0, 8), lleg=(-16, 0, -8))
    a_keys = [(0, a_up), (22, a_up), (30, a_hit), (40, a_thrown), (90, blend_pose(a_thrown, a_up, 0.3))]
    a_blade = [(0, (-0.6, 0.2, 0.75)), (22, (-0.6, 0.2, 0.75)), (30, (0.85, -0.05, -0.3)), (40, (0.2, 0.2, 1)), (90, (0.3, 0.2, 0.95))]
    cam = K.camera((-0.4, -7.4, 4.4), (0.2, 0, 4.85), lens=32, focus=(0, 0, 4.8), fstop=2.8)
    K.bloom(0.6, 1.0, 0.8, saturation=1.12)

    def step(f):
        st["dir"], st["adir"] = keyed(d_blade, f), keyed(a_blade, f)
        fr = dfd.set(keyed(d_keys, f))
        atk.set(keyed(a_keys, f), at=tuple(lerp((-2.7, 1.3, 0), (-3.6, 2.0, 0), ease((f - 30) / 20, "out"))))
        if f == 30:
            p = K.hand(fr).translation + Vector((-1.55, -0.05, 1.25))
            burst.show(p, f)
            flash.show(p, f)
        burst.step(f)
        flash.step(f)
        look(cam, lerp((-0.9, -7.6, 4.2), (0.1, -6.6, 4.6), ease(f / 90)), lerp((0.2, 0, 4.85), (0.4, 0, 5.0), ease(f / 90)))
    return 90, step


def shot_magic():
    """MASTER MAGIC: the Star Sage throws a fireball across the night at an Iron Crow"""
    K.sky(top=rgb(6, 4, 24), horizon=rgb(110, 50, 190), strength=1.2, band=0.25)
    K.ground(240, K.stone_mat(rgb(70, 66, 82), rgb(30, 28, 38), 1.6))
    S.castle_backdrop(52, K.stone_mat(rgb(80, 78, 100), rgb(40, 38, 52), 1.2), K.flat_mat("roof", rgb(40, 30, 90), rough=0.6))
    K.obj("Moon", K.sphere_bm((60, 110, 52), 7, color=(1, 1, 1), segs=64), K.flat_mat("moon", rgb(210, 225, 255), emit=8))
    K.embers((-60, 60, 18), (60, 130, 60), n=400, color=rgb(220, 230, 255), size=(0.05, 0.14), seed=11)
    st = {"staff": (0.15, 0.1, 1), "kdir": (-0.5, -0.2, 0.85)}
    mage = K.Rig("StarSage", at=(-3.4, 0.4, 0), yaw=-118, colors=SAGE, neon=3)
    mage.attach(K.staff("Staff of the Cosmos", Matrix(), neon=5), lambda f: S.held(K.hand(f), Vector(st["staff"])))
    S.magic_circle((-3.4, 0.4, 0.02), 2.6, rgb(150, 80, 255), strength=3)
    knight = K.Rig("IronCrow", at=(5.4, 2.2, 0), yaw=112, colors=IRON)
    wield(knight, K.weapon("Longsword", Matrix()), st, key="kdir")
    before = set(bpy.data.objects)
    K.fire((0, 0, 0), r=1.0, strength=2.4, power=2500, seed=5)
    ball = Mover(made_since(before))
    tails = []
    for k, r in enumerate((0.7, 0.45)):
        before = set(bpy.data.objects)
        K.fire((0, 0, 0), r=r, strength=2.0, power=0, seed=8 + k)
        tails.append(Mover(made_since(before)))
    boom = Burst("fire", size=3.4, power=4000, life=16)
    sparks = Burst(color=rgb(255, 150, 40), size=2.8, n=60, power=500, strength=3, life=14)
    calm = dict(torso=(4, -18, 4), head=(-6, -30, 0), rarm=(70, -12, 22), larm=(30, 22, 0), rleg=(-16, 0, 10), lleg=(18, 0, -8))
    raise_ = dict(torso=(0, -10, 0), head=(-8, -24, 0), rarm=(150, -12, 22), larm=(40, -30, 0), rleg=(-16, 0, 10), lleg=(18, 0, -8))
    thrust = dict(torso=(8, 8, 0), head=(-4, 14, 0), rarm=(128, -12, 22), larm=(96, 22, 0), rleg=(-20, 0, 10), lleg=(22, 0, -8))
    m_keys = [(0, calm), (14, raise_), (22, raise_), (28, thrust), (105, thrust)]
    k_rest = dict(torso=(-4, 0, 0), head=(4, 0, 0), rarm=(60, 24, 0), larm=(56, -24, 0), rleg=(-16, 0, 6), lleg=(18, 0, -6))
    k_hit = dict(torso=(-30, 10, 8), head=(20, 6, 0), rarm=(20, 0, 50), larm=(10, 0, -60), rleg=(20, 0, 10), lleg=(-14, 0, -10))
    k_keys = [(0, k_rest), (60, k_rest), (68, k_hit), (105, blend_pose(k_hit, k_rest, 0.25))]
    cam = K.camera((-1.2, -10.0, 2.2), (-1.8, 0, 4.2), lens=30, focus=(-3.4, 0.4, 4), fstop=4)
    K.light("AREA", (-8, -10, 9), rgb(140, 160, 255), 600, size=8, target=(0, 0, 3))
    K.light("AREA", (-3, 9, 7), rgb(170, 110, 255), 2600, size=6, target=(-2.6, 0.5, 3.5))
    K.bloom(0.5, 1.4, 0.7, saturation=1.1)
    path = []

    def step(f):
        mf = mage.set(keyed(m_keys, f))
        kf = knight.set(keyed(k_keys, f), at=tuple(lerp((5.4, 2.2, 0), (6.4, 3.0, 0), ease((f - 60) / 25, "out"))))
        hand = K.hand(mf, "L").translation + Vector((0.5, -0.2, 0.2))
        target = kf["Torso"].translation + Vector((-0.6, -0.4, 0.6))
        if 26 <= f < 60:
            t = (f - 26) / 34
            p = hand.lerp(target, t) + Vector((0, 0, math.sin(t * math.pi) * 0.6))
            path.append(p)
            ball.place(p, scale=0.45 + 0.55 * ease(min(1, t * 4), "out"))
            for k, tl in enumerate(tails):
                tl.place(path[max(0, len(path) - 3 * (k + 1))])
        else:
            ball.hide()
            for tl in tails:
                tl.hide()
        if f == 60:
            boom.show(target, f)
            sparks.show(target, f)
        boom.step(f)
        sparks.step(f)
        u = ease((f - 20) / 50)
        look(cam, lerp((-1.2, -10.0, 2.2), (2.0, -10.6, 2.3), u), lerp((-1.8, 0, 4.2), (2.4, 0.6, 4.2), u))
    return 105, step


def shot_archer():
    """HEADSHOT!: the Phoenixborn draws a burning arrow on the walls at sunset and lets it fly"""
    K.sky(top=rgb(70, 18, 110), horizon=rgb(255, 92, 20), strength=1.8, band=0.4)
    stone = K.stone_mat(rgb(112, 88, 72), rgb(54, 42, 36), 0.9)
    far = K.stone_mat(rgb(120, 96, 90), rgb(70, 56, 54), 1.2)
    K.ground(240, K.stone_mat(rgb(110, 92, 78), rgb(64, 52, 44), 1.6))
    roof = K.flat_mat("roof", rgb(140, 34, 30), rough=0.6)
    K.wall((-34, 38, 0), (34, 38, 0), 11, 2.5, far)
    for x, rr, h in ((-26, 3.4, 17), (-12, 4.2, 25), (8, 3.6, 21), (24, 3.2, 15)):
        K.tower((x, 40, 0), rr, h, far, roof)
    K.obj("Sun", K.sphere_bm((52, 150, 40), 12, color=(1, 0.8, 0.5), segs=48), K.flat_mat("sun", rgb(255, 170, 70), emit=6))
    A = (-2.6, 0.6, 0)
    drawn = dict(torso=(0, 8, 0), head=(-6, 34, 0), rarm=(92, 62, 0), larm=(94, -14, 0), rleg=(-10, 0, 6), lleg=(10, 0, -6))
    start = dict(torso=(0, 8, 0), head=(-6, 34, 0), rarm=(94, 2, 0), larm=(94, -14, 0), rleg=(-10, 0, 6), lleg=(10, 0, -6))
    loose = dict(torso=(0, 8, 0), head=(-6, 34, 0), rarm=(80, 80, 20), larm=(94, -14, 0), rleg=(-10, 0, 6), lleg=(10, 0, -6))
    a_keys = [(0, start), (30, drawn), (48, drawn), (51, loose), (75, loose)]
    archer = K.Rig("Phoenix", at=A, yaw=186, pose=drawn, colors=PHOENIX, neon=2.4)
    full = archer.frames
    aim = (K.hand(full, "L").translation - K.hand(full, "R").translation).normalized()
    K.embers((A[0] - 3, A[1] - 1, 1.5), (A[0] + 3, A[1] + 3, 9), n=60, color=rgb(255, 110, 20), seed=21, size=(0.015, 0.045), strength=6)
    S.parapet(-1.0, -40, 40, 1.6, gaps_at=(A[0] + 0.6,), mat=stone, width=1.6, merlon=1.3, gap=1.6, merlons_to=A[0])
    before = set(bpy.data.objects)
    S.arrow((0, -2.3, 0), (0, 0, 0), flame=0.34, name="FlyingArrow")
    flying = Mover(made_since(before))
    flying.hide()
    K.light("SUN", (0, 0, 0), rgb(255, 150, 80), 2.2)
    sun = [o for o in bpy.data.objects if o.type == "LIGHT" and o.data.type == "SUN"][-1]
    sun.rotation_euler = (math.radians(76), 0, math.radians(185))
    K.light("AREA", (-7, -9, 6), rgb(120, 140, 255), 420, size=8, target=(A[0], A[1], 4))
    K.light("SPOT", (4, -6, 9), rgb(255, 170, 100), 1400, size=1.5, target=(A[0], A[1], 4.6), angle=28)
    K.light("AREA", (A[0] + 2, A[1] + 6, 8), rgb(255, 120, 50), 2200, size=5, target=(A[0], A[1], 4.5))
    cam = K.camera((0.4, -8.2, 2.0), (0.0, 0, 4.8), lens=26, focus=(A[0], A[1], 4.5), fstop=2.8)
    K.bloom(0.55, 1.0, 0.75, saturation=1.18)
    made = {"objs": []}

    def step(f):
        for o in made["objs"]:
            bpy.data.objects.remove(o, do_unlink=True)
        made["objs"] = []
        fr = archer.set(keyed(a_keys, f))
        g = K.hand(fr, "L").translation
        nk = K.hand(fr, "R").translation if f < 50 else g - aim * 0.4
        if (g - nk).length < 0.4:
            nk = g - aim * 0.4
        before = set(bpy.data.objects)
        S.drawn_bow(g, nk)
        if f < 50:
            S.arrow(nk - aim * 0.25, g + aim * 1.3, flame=0.34, name="DrawnArrow")
            flying.hide()
        else:
            tip = g + aim * (1.3 + 1.4 * (f - 50)) + Vector((0, 0, -0.003 * (f - 50) ** 2))
            flying.place(tip, toward=tip + aim)
        made["objs"] = made_since(before)
        u = ease(f / 75)
        look(cam, lerp((0.4, -8.2, 2.0), (-0.4, -7.0, 2.4), u), lerp((0.0, 0, 4.8), (-1.0, 0, 4.9), u))
    return 75, step


def run_pose(f, phase=0.0, period=20, arm=(150, 0, 14)):
    s = math.sin(2 * math.pi * (f / period + phase))
    return dict(torso=(-16, 0, 0), head=(12, 0, 0), rarm=arm, larm=(-40 * s, 0, -14),
                rleg=(46 * s, 0, 4), lleg=(-46 * s, 0, -4), drop=-0.22 + 0.14 * abs(s))


def shot_siege():
    """STORM THE CASTLE: the Crown charges, the Iron castle burning behind"""
    K.sky(top=rgb(40, 14, 30), horizon=rgb(255, 96, 30), strength=1.5, band=0.3)
    K.ground(400, K.stone_mat(rgb(110, 96, 80), rgb(60, 52, 44), 1.8))
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
    K.embers((-30, -40, 2), (30, 36, 30), n=700, color=rgb(255, 120, 30), seed=5, size=(0.03, 0.09), strength=8)
    st = {}
    runners = []
    speed = 0.36
    for i, (set_name, at, yaw, pose, kit, cols) in enumerate(S.SIEGE_CHARGE):
        rig = K.Rig(set_name, at=at, yaw=yaw, colors=S.CROWN, neon=2.5)
        key = f"d{i}"
        st[key] = (0.3 * (1 if at[0] > 0 else -1), -0.45, 1)
        if kit == "flag":
            st[key] = (0.1, 0.05, 1)
            rig.attach(S.flag(Matrix(), length=8, w=3.4, h=2.3, wind=(1, 0, 0), color=rgb(40, 80, 210), name=f"Flag{i}"),
                       lambda f, key=key: S.frame_at(K.hand(f).translation, st[key]))
        else:
            wield(rig, K.weapon(kit, Matrix()), st, key=key)
        runners.append((rig, Vector(at), yaw, i * 0.37))
    back_l = K.light("AREA", (-10, 12, 9), rgb(255, 120, 50), 4000, size=8, target=(-1, 0, 4))
    back_r = K.light("AREA", (10, 12, 9), rgb(255, 120, 50), 4000, size=8, target=(1, 0, 4))
    front = K.light("AREA", (0, -12, 8), rgb(150, 170, 255), 900, size=10, target=(0, 0, 3))
    cam = K.camera((0.4, -15.5, 1.8), (0.2, 0, 5.4), lens=27, focus=(-1.6, -2.4, 4), fstop=3.2)
    K.bloom(0.5, 1.0, 0.75, saturation=1.12)
    cam_speed = 0.335   # (a touch slower than them: they gain on us, but only a little)

    def step(f):
        run = Vector((0, -speed * f, 0))
        for rig, at, yaw, ph in runners:
            rig.set(run_pose(f, ph), at=tuple(at + run))
        back = Vector((0, -cam_speed * f, 0))
        look(cam, Vector((0.4, -15.5, 1.8)) + back, Vector((0.2, 0, 5.4)) + back)
        for L, x in ((back_l, -10), (back_r, 10)):
            L.location = Vector((x, 12, 9)) + run
        front.location = Vector((0, -12, 8)) + run
        cam.data.dof.focus_distance = 13.1 - (speed - cam_speed) * f
    return 120, step


def shot_lineup():
    """5 CLASSES: the camera rises over the line-up"""
    K.sky(top=rgb(20, 30, 110), horizon=rgb(255, 150, 60), strength=1.4, band=0.45)
    K.ground(240, K.stone_mat(rgb(120, 110, 100), rgb(60, 56, 52), 1.6))
    S.sunburst((0, 40, 7), 70, n=28, colors=(rgb(255, 200, 90), rgb(255, 110, 40)), strength=1.4)
    S.castle_backdrop(30, K.stone_mat(rgb(90, 80, 96), rgb(50, 44, 56), 1.2), K.flat_mat("roof", rgb(60, 40, 110), rough=0.6))
    for label, set_name, at, yaw, pose, cols, kit in S.CLASS_LINEUP:
        rig = K.Rig(set_name, at=at, yaw=yaw, pose=pose, colors=cols, neon=2.6)
        f = rig.frames
        if kit == "bow":
            g = K.hand(f, "R").translation
            back = (f["Torso"].translation - g)
            back.z = 0
            S.drawn_bow(g + Vector((0, -0.2, 0.5)), g + Vector((0, -0.2, 0.5)) + back.normalized() * 0.5, height=4.8, bend=0.6,
                        color=rgb(196, 206, 236), trim=rgb(110, 160, 255))
        elif kit == "staff":
            K.staff("Emberwood", S.held(K.hand(f, "L"), (0.28, -0.15, 1), slide=-0.8), neon=4)
            K.fire(tuple(K.hand(f).translation + Vector((0, -0.25, 0.5))), r=0.45, strength=2.4, power=300, seed=12)
        elif kit == "Halberd":
            K.weapon(kit, S.held(K.hand(f), (0.04, 0, 1), slide=-0.6))
        elif kit == "Greatsword":
            K.weapon(kit, S.held(K.hand(f), (0, -0.06, -1), slide=0.2))
        else:
            K.weapon(kit, S.held(K.hand(f, "L"), (0.4, -0.25, 1), slide=-0.4))
    K.light("AREA", (0, -10, 9), rgb(200, 210, 255), 900, size=10, target=(0, 0, 3))
    K.light("AREA", (-9, 6, 7), rgb(120, 160, 255), 2400, size=6, target=(-2, 0, 4))
    K.light("AREA", (9, 6, 7), rgb(255, 150, 70), 2400, size=6, target=(2, 0, 4))
    cam = K.camera((0, -9.0, 1.0), (0, 0, 3.4), lens=30, focus=(0, -0.6, 3.5), fstop=4.0)
    K.bloom(0.45, 1.1, 0.7, saturation=1.12)

    def step(f):
        u = ease(f / 75)
        look(cam, lerp((0, -9.0, 1.0), (0, -14.2, 2.9), u), lerp((0, 0, 3.4), (0, 0, 3.85), u))
    return 105, step


def shot_end():
    """the end card: the Lionheart, swords crossed behind, the blue burst turning"""
    K.sky(top=rgb(10, 20, 70), horizon=rgb(40, 80, 200), strength=1.0, band=0.5)
    burst = S.sunburst((0, 9, 4.3), 30, n=22, colors=(rgb(70, 130, 255), rgb(30, 60, 190)), strength=1.6, facing=(0, -1, 0))
    base = burst.matrix_world.copy()
    K.figure("Lionheart", at=(0, 0, 0), yaw=192, pose=dict(head=(-8, 6, 0), rarm=(10, 0, 8), larm=(10, 0, -8)), colors=LION)
    for sx in (-1, 1):
        K.weapon("Longsword", S.frame_at((sx * 1.0, 1.4, 2.6), (-sx * 0.62, 0, 1), face=(0, -1, 0), scale=1.4))
    K.light("AREA", (-3, -6, 7), rgb(255, 236, 210), 700, size=4, target=(0, 0, 4.4))
    K.light("AREA", (4, -4, 3), rgb(140, 170, 255), 250, size=4, target=(0, 0, 4.4))
    K.light("AREA", (0, 4, 8), rgb(255, 200, 120), 900, size=3, target=(0, 0, 4.6))
    cam = K.camera((2.4, -14.0, 4.4), (0.6, 0, 4.4), lens=40, focus=(0, 0, 4.5), fstop=8)
    K.bloom(0.4, 1.2, 0.6, saturation=1.1)

    def step(f):
        burst.matrix_world = T(0, 9, 4.3) @ Matrix.Rotation(math.radians(f * 0.25), 4, "Y") @ T(0, -9, -4.3) @ base
        u = ease(f / 120, "out")
        look(cam, lerp((2.4, -14.0, 4.4), (1.6, -11.0, 4.6), u), (0.6, 0, 4.5))
    return 120, step


SHOTS = {"swing": shot_swing, "parry": shot_parry, "magic": shot_magic, "archer": shot_archer,
         "siege": shot_siege, "lineup": shot_lineup, "end": shot_end}
ORDER = ["swing", "parry", "magic", "archer", "siege", "lineup", "end"]


def render_shot(name):
    setup()
    n, step = SHOTS[name]()
    out = os.path.join(VID, "frames_preview" if PREVIEW else "frames", name)
    os.makedirs(out, exist_ok=True)
    rng = _arg("--frames")
    a, b = (int(x) for x in rng.split("-")) if rng else (0, n - 1)
    every = int(_arg("--every", "1"))
    only = {int(x) for x in _arg("--at").split(",")} if _arg("--at") else None   # (just these frames)
    sc = bpy.context.scene
    import time
    for f in range(0, n):
        step(f)   # (every frame is stepped, rendered or not: Bursts are started by the frame they hit)
        if (f in only) if only else (a <= f <= b and (f - a) % every == 0):
            t0 = time.time()
            sc.render.filepath = os.path.join(out, f"{f:04d}.png")
            bpy.ops.render.render(write_still=True)
            print(f"FRAME {name} {f} {time.time() - t0:.1f}s", flush=True)
    print("SHOT DONE", name, n)


# ------------------------------------------------------------------------
#  THE CARDS: the words over each shot (a full-frame transparent PNG each), when they come in,
#  when they go, and whether they pop (land big and settle)
# ------------------------------------------------------------------------
WHITE = (rgb(255, 255, 255), rgb(255, 236, 200))
CARDS = [
    # shot, card, items, in, out, pop
    ("swing", "swing", [{"text": "AIM EVERY SWING", "y": 3.4, "size": 1.5}], 6, 88, True),
    ("parry", "parry", [{"text": "PARRY!", "x": -4.4, "y": 3.2, "size": 2.3, "tilt": 6}], 30, 90, True),
    ("magic", "magic", [{"text": "MASTER MAGIC", "y": 3.5, "size": 1.6, "fill": (rgb(240, 220, 255), rgb(170, 90, 255)), "outline": rgb(30, 8, 60)}], 8, 105, True),
    ("magic", "magic_sub", [{"text": "FIRE  •  LIGHTNING  •  FROST", "y": 2.1, "size": 0.58, "fill": WHITE, "outline": rgb(30, 8, 60), "ow": 0.07,
                             "plate": rgb(110, 50, 200), "plate_edge": rgb(255, 214, 110)}], 22, 105, False),
    ("archer", "archer", [{"text": "BOWS  •  CROSSBOWS", "x": 4.2, "y": 1.3, "size": 0.62, "fill": WHITE, "outline": rgb(70, 20, 4), "ow": 0.07,
                           "plate": rgb(210, 70, 20), "tilt": -4}], 6, 48, False),
    ("archer", "archer_hs", [{"text": "HEADSHOT!", "x": 4.2, "y": 3.0, "size": 2.0, "tilt": -4}], 50, 75, True),
    ("siege", "siege", [{"text": "STORM THE CASTLE", "y": 3.6, "size": 1.6}], 8, 120, True),
    ("siege", "siege_sub", [{"text": "6 BATTLE MODES", "y": 2.2, "size": 0.62, "fill": WHITE, "outline": rgb(70, 6, 6), "ow": 0.07,
                             "plate": rgb(40, 80, 210)}], 30, 120, False),
    ("lineup", "lineup", [{"text": "5 CLASSES", "y": 3.55, "size": 1.8}], 50, 105, True),
    ("lineup", "lineup_sub", [{"text": "PICK YOUR FIGHTER", "y": 2.05, "size": 0.62, "fill": WHITE, "outline": rgb(20, 14, 60), "ow": 0.07,
                               "plate": rgb(40, 70, 200)}], 62, 105, False),
    ("lineup", "lineup_names", None, 72, 105, False),   # (the class names at their feet: lineup_labels)
    ("end", "end", [{"text": "STEEL & GLORY", "y": 3.55, "size": 1.75}], 8, 120, True),
    ("end", "end_sub", [{"text": "PLAY NOW", "y": -3.3, "size": 1.0, "fill": WHITE, "outline": rgb(6, 30, 10), "ow": 0.08,
                         "plate": rgb(40, 170, 70), "plate_edge": rgb(255, 214, 110)}], 36, 120, True),
]


def lineup_labels():
    """the class names under their feet, where the line-up shot's camera ends"""
    setup()
    n, step = shot_lineup()
    step(n - 1)
    bpy.context.view_layer.update()
    W = 10 * 16 / 9
    items = []
    for label, set_name, at, yaw, pose, cols, kit in S.CLASS_LINEUP:
        v = K.where(label, Vector((at[0], at[1], 0)))
        items.append({"text": label, "x": (v.x - 0.5) * W, "y": max(-4.45, (v.y - 0.5) * 10 - 0.3), "size": 0.5,
                      "fill": WHITE, "outline": rgb(20, 14, 40), "ow": 0.08, "plate": rgb(36, 30, 70), "plate_edge": rgb(255, 200, 80)})
    return items


def render_titles():
    os.makedirs(os.path.join(VID, "titles"), exist_ok=True)
    names = lineup_labels()
    for shot, card, items, t_in, t_out, pop in CARDS:
        K.overlay(items if items is not None else names, RES, os.path.join(VID, "titles", card + ".png"))
        print("CARD", card, flush=True)


# ------------------------------------------------------------------------
#  THE EDIT: the shots end to end, the cards over them (fading in and out, the big ones
#  landing large and settling), a white flash on the hardest cuts, written as an H.264 MP4
# ------------------------------------------------------------------------
FLASH_INTO = {"parry", "magic", "siege", "end"}


def edit():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    # (the frames are finished pictures, AgX already applied: "Standard" passes them through
    # untouched; the factory default, AgX, would grade them a second time, grey and flat)
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure, sc.view_settings.gamma = 0.0, 1.0
    res = (RES[0] // 2, RES[1] // 2) if PREVIEW else RES
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.fps = FPS
    ed = sc.sequence_editor_create()
    strips = ed.strips
    frames_dir = os.path.join(VID, "frames_preview" if PREVIEW else "frames")
    start = {}
    at = 1
    for shot in ORDER:
        folder = os.path.join(frames_dir, shot)
        files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
        s = strips.new_image(name=shot, filepath=os.path.join(folder, files[0]), channel=1, frame_start=at)
        for f in files[1:]:
            s.elements.append(f)
        start[shot] = at
        if shot in FLASH_INTO and at > 1:
            try:
                fl = strips.new_effect(name="flash_" + shot, type="COLOR", channel=6, frame_start=at, length=5)
            except TypeError:
                fl = strips.new_effect(name="flash_" + shot, type="COLOR", channel=6, frame_start=at, frame_end=at + 5)
            fl.color = (1, 1, 1)
            fl.blend_type = "ADD"
            for fr, a in ((at, 0.85), (at + 4, 0.0)):
                fl.blend_alpha = a
                fl.keyframe_insert("blend_alpha", frame=fr)
        at += len(files)
    total = at - 1
    for i, (shot, card, items, t_in, t_out, pop) in enumerate(CARDS):
        path = os.path.join(VID, "titles", card + ".png")
        f0, f1 = start[shot] + t_in, start[shot] + t_out
        c = strips.new_image(name=card, filepath=path, channel=2 + i % 4, frame_start=f0)
        c.frame_final_duration = max(1, f1 - f0)
        c.blend_type = "ALPHA_OVER"
        keys = [(f0, 0.0), (f0 + 4, 1.0), (f1 - 4, 1.0), (f1, 0.0)]
        if f1 >= total:
            keys = [(f0, 0.0), (f0 + 4, 1.0)]
        for fr, a in keys:
            c.blend_alpha = a
            c.keyframe_insert("blend_alpha", frame=fr)
        if pop:
            for fr, sc_ in ((f0, 1.35), (f0 + 6, 1.0)):
                c.transform.scale_x = c.transform.scale_y = sc_
                c.transform.keyframe_insert("scale_x", frame=fr)
                c.transform.keyframe_insert("scale_y", frame=fr)
    sc.frame_start, sc.frame_end = 1, total
    stills = _arg("--stills")   # (check the cut: write just these frames of it as PNGs)
    if stills:
        sc.render.image_settings.file_format = "PNG"
        for fr in (int(x) for x in stills.split(",")):
            sc.frame_set(fr)
            sc.render.filepath = os.path.join(VID, f"still_{fr:04d}.png")
            bpy.ops.render.render(write_still=True)
            print("STILL", fr, flush=True)
        return
    ims = sc.render.image_settings
    ims.media_type = "VIDEO"
    ims.file_format = "FFMPEG"
    sc.render.ffmpeg.format = "MPEG4"
    sc.render.ffmpeg.codec = "H264"
    sc.render.ffmpeg.constant_rate_factor = "HIGH"
    sc.render.ffmpeg.ffmpeg_preset = "GOOD"
    out = os.path.join(VID, "trailer_preview.mp4" if PREVIEW else "trailer.mp4")
    sc.render.filepath = out
    bpy.ops.render.render(animation=True)
    print("EDITED", out, total, "frames", f"{total / FPS:.1f}s", flush=True)


if __name__ == "__main__":
    what = [a for a in ARGS if not a.startswith("--") and not a[0].isdigit()][0]
    if what.startswith("shot:"):
        render_shot(what.split(":", 1)[1])
    elif what == "titles":
        render_titles()
    elif what == "edit":
        edit()
