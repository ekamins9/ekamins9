"""Procedural medieval weapon meshes for the R6 melee game, built in Blender
headless and exported as FBX for Roblox.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python blender/weapons.py -- Longsword [More...]
    ... -- all            every weapon in WEAPONS
    ... -- all --out dir  export folder (default blender/out)
    blender/preview_weapons.py renders them all in a row first.

Each weapon is ONE mesh per region in the Tool's frame: the fist (the Handle)
at the origin, the business end along +Y, the edge in the XY plane (the blade's
flat faces look along ±Z); 1 unit = 1 stud. Vertex colours paint it (bright
ground edges, darker fullers, steel, leather, wood, brass) so the MeshPart reads
them with no texture; the Dresser tints SkinPart = "Blade" / "Grip" parts, so
each weapon is exported as TWO meshes: <Weapon>_Blade.fbx (the steel business
end) and <Weapon>_Grip.fbx (grip, guard, pommel, haft, fittings) that both sit
on the same origin. Studio: both become MeshParts welded to the Tool's Handle.

Every weapon keeps the size its Hitbox and reach were tuned for
(scripts/build_weapons.py GRIPS); the detail is in the shapes:
  blades     lofted sections — beveled edges ground bright, fullers shaded dark,
             distal taper, flamberge waves, clip points, falchion bellies
  guards     quillons as bent bars that swell to their finials, a centre block
             with langets, side rings, a rapier's swept hilt
  axes, bills, glaives, halberds
             flat pieces cut from an outline, thick at the socket and ground to
             an edge (plate()), on sockets with langets riveted down the haft
  grips      leather with a spiral wrap or wire, ferrules, scales and rivets
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out")

# vertex colours (Roblox shows them as-is when the MeshPart has no texture and `Color` is white)
STEEL = (0.84, 0.86, 0.90)
BRIGHT = (0.95, 0.96, 0.98)
EDGE = (1.0, 1.0, 1.0)
FULLER = (0.56, 0.59, 0.65)
FACE = (0.66, 0.68, 0.73)      # the flat of an axe or a bill, so its ground edge shines against it
DARKSTEEL = (0.40, 0.43, 0.48)
IRON = (0.52, 0.54, 0.58)
BLACKIRON = (0.22, 0.23, 0.26)
LEATHER = (0.45, 0.30, 0.19)
DARKLEATHER = (0.26, 0.17, 0.11)
WOOD = (0.58, 0.40, 0.23)
DARKWOOD = (0.36, 0.23, 0.13)
BRASS = (0.80, 0.63, 0.30)
GOLD = (0.95, 0.75, 0.28)
RED = (0.62, 0.12, 0.10)
ROPE = (0.74, 0.63, 0.43)
WIRE = (0.66, 0.68, 0.72)


# --------------------------------------------------------------------------
#  mesh primitives (all return a bmesh with a "Col" colour layer)
# --------------------------------------------------------------------------
def paint(bm, color):
    layer = bm.loops.layers.color.get("Col") or bm.loops.layers.color.new("Col")
    rgba = (*color, 1.0)
    for f in bm.faces:
        for l in f.loops:
            l[layer] = rgba


def merge(*bms):
    out = bmesh.new()
    layer = out.loops.layers.color.new("Col")
    for bm in bms:
        src = bm.loops.layers.color.get("Col")
        bm.verts.ensure_lookup_table()
        idx = {v: i for i, v in enumerate(bm.verts)}
        newv = [out.verts.new(v.co) for v in bm.verts]
        for f in bm.faces:
            try:
                nf = out.faces.new([newv[idx[v]] for v in f.verts])
            except ValueError:
                continue
            for l, nl in zip(f.loops, nf.loops):
                nl[layer] = l[src] if src else (1, 1, 1, 1)
        bm.free()
    bmesh.ops.delete(out, geom=[v for v in out.verts if not v.link_faces], context="VERTS")
    return out


def loft(sections, color, close_ends=True, colorfn=None):
    """sections: [(y, [(x, z), …])] rings with the same point count (a ring may
    instead hold full (x, y, z) points, its y ignored). colorfn(section, point)
    colours each vertex; else the whole tube is `color`."""
    bm = bmesh.new()
    rings, where = [], {}
    for si, (y, pts) in enumerate(sections):
        ring = []
        for pi, p in enumerate(pts):
            v = bm.verts.new((p[0], y, p[1]) if len(p) == 2 else tuple(p))
            where[v] = (si, pi)
            ring.append(v)
        rings.append(ring)
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            try:
                bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
            except ValueError:
                pass
    if close_ends:
        bm.faces.new(tuple(reversed(rings[0])))
        bm.faces.new(tuple(rings[-1]))
    if colorfn:
        layer = bm.loops.layers.color.new("Col")
        for f in bm.faces:
            for l in f.loops:
                l[layer] = (*colorfn(*where[l.vert]), 1.0)
    else:
        paint(bm, color)
    return bm


def ring_ellipse(rx, rz, n=12, rot=0.0):
    return [(rx * math.cos(2 * math.pi * i / n + rot), rz * math.sin(2 * math.pi * i / n + rot)) for i in range(n)]


def lathe(profile, color, n=16, rot=0.0):
    """profile: [(radius, y)] from bottom to top → a solid of revolution about Y"""
    return loft([(y, ring_ellipse(max(r, 0.004), max(r, 0.004), n, rot)) for r, y in profile], color)


def cylinder(y0, y1, r0, r1=None, color=WOOD, n=14, bulge=0.0):
    r1 = r0 if r1 is None else r1
    secs = []
    for i in range(5):
        f = i / 4
        r = r0 + (r1 - r0) * f + bulge * math.sin(math.pi * f)
        secs.append((y0 + (y1 - y0) * f, ring_ellipse(r, r, n)))
    return loft(secs, color)


def box(cx, cy, cz, sx, sy, sz, color, rot_y=0.0, rot_z=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        x, y, z = v.co.x * sx, v.co.y * sy, v.co.z * sz
        if rot_z:
            c, s = math.cos(rot_z), math.sin(rot_z)
            x, y = x * c - y * s, x * s + y * c
        if rot_y:
            c, s = math.cos(rot_y), math.sin(rot_y)
            x, z = x * c - z * s, x * s + z * c
        v.co = (x + cx, y + cy, z + cz)
    paint(bm, color)
    return bm


def sphere(c, r, color, u=12, v=8, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=r)
    for vert in bm.verts:
        vert.co = Vector((vert.co.x * scale[0] + c[0], vert.co.y * scale[1] + c[1], vert.co.z * scale[2] + c[2]))
    paint(bm, color)
    return bm


def tube(points, radius, color, n=8, caps=True, colorfn=None):
    """a round bar through 3-D points (radius: one number or one per point)"""
    pts = [Vector(p) for p in points]
    rs = list(radius) if isinstance(radius, (list, tuple)) else [radius] * len(pts)
    tan = [(pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(len(pts))]
    up = Vector((0, 0, 1)) if abs(tan[0].z) < 0.9 else Vector((1, 0, 0))
    nrm = (up - tan[0] * up.dot(tan[0])).normalized()
    secs = []
    for i, p in enumerate(pts):
        if i:
            nrm = (nrm - tan[i] * nrm.dot(tan[i])).normalized()
        bin_ = tan[i].cross(nrm)
        ring = [tuple(p + rs[i] * (math.cos(2 * math.pi * k / n) * nrm + math.sin(2 * math.pi * k / n) * bin_)) for k in range(n)]
        secs.append((0, ring))
    return loft(secs, color, close_ends=caps, colorfn=colorfn)


def cone(base, tip, r, color, n=10):
    """a round spike from the centre of its foot to its point"""
    b, t = Vector(base), Vector(tip)
    return tube([b, b + (t - b) * 0.5, t], [r, r * 0.55, 0.004], color, n=n)


def _pyr(base, tip, r, color, rot=0.0):
    """a square spike from the centre of its foot to its point"""
    b, t = Vector(base), Vector(tip)
    ax = (t - b).normalized()
    up = Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))
    u = (up - ax * up.dot(ax)).normalized()
    w = ax.cross(u)
    bm = bmesh.new()
    vs = [bm.verts.new(b + r * (math.cos(rot + k * math.pi / 2 + math.pi / 4) * u + math.sin(rot + k * math.pi / 2 + math.pi / 4) * w)) for k in range(4)]
    a = bm.verts.new(t)
    bm.faces.new(tuple(vs))
    for i in range(4):
        bm.faces.new((vs[i], vs[(i + 1) % 4], a))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    paint(bm, color)
    return bm


def disc(c, r, t, color, axis="z", n=20):
    """a round plate with a rolled rim, its face toward `axis`"""
    bm = lathe([(0.0, -t / 2), (r * 0.86, -t / 2), (r, -t * 0.2), (r, t * 0.2), (r * 0.86, t / 2), (0.0, t / 2)], color, n=n)
    for v in bm.verts:
        x, y, z = v.co
        if axis == "z":
            x, y, z = x, z, y
        elif axis == "x":
            x, y, z = y, x, z
        v.co = (x + c[0], y + c[1], z + c[2])
    return bm


def bez(p0, c, p1, n):
    """n + 1 points on a quadratic curve from p0 through the pull of c to p1"""
    out = []
    for k in range(n + 1):
        t = k / n
        out.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]))
    return out


def plate(outline, color, t=0.06, ground=None, bevel=0.14, t_edge=0.012, edge_color=EDGE, cz=0.0):
    """a flat piece in the XY plane cut to `outline` [(x, y), …] (counter-clockwise),
    `t` thick along Z (one number or one per point). The outline points whose
    index is in `ground` are an edge: the piece thins to t_edge over `bevel`
    toward them, and they shine (edge_color)."""
    n = len(outline)
    ground = set(ground or ())
    tt = list(t) if isinstance(t, (list, tuple)) else [t] * n
    pts = [Vector((x, y, 0)) for x, y in outline]
    inner = []
    for i, p in enumerate(pts):
        if i in ground:
            a, b = pts[(i - 1) % n], pts[(i + 1) % n]
            d = (b - a).normalized()
            inward = Vector((-d.y, d.x, 0))   # left of the direction of travel: inside for a CCW outline
            inner.append(p + inward * bevel)
        else:
            inner.append(p)
    bm = bmesh.new()
    fi = [bm.verts.new((q.x, q.y, cz + tt[i] / 2)) for i, q in enumerate(inner)]
    bi = [bm.verts.new((q.x, q.y, cz - tt[i] / 2)) for i, q in enumerate(inner)]
    fo, bo, shiny = [], [], set()
    for i, p in enumerate(pts):
        if i in ground:
            f_, b_ = bm.verts.new((p.x, p.y, cz + t_edge / 2)), bm.verts.new((p.x, p.y, cz - t_edge / 2))
            shiny.update((f_, b_))
            fo.append(f_); bo.append(b_)
        else:
            fo.append(fi[i]); bo.append(bi[i])

    def face(vs):
        uniq = []
        for v in vs:
            if v not in uniq:
                uniq.append(v)
        if len(uniq) >= 3:
            try:
                bm.faces.new(uniq)
            except ValueError:
                pass
    face(fi)
    face(list(reversed(bi)))
    for i in range(n):
        j = (i + 1) % n
        face([fi[i], fo[i], fo[j], fi[j]])
        face([bi[j], bo[j], bo[i], bi[i]])
        face([fo[i], bo[i], bo[j], fo[j]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    layer = bm.loops.layers.color.new("Col")
    for f in bm.faces:
        for l in f.loops:
            l[layer] = (*(edge_color if l.vert in shiny else color), 1.0)
    return bm


def turn(bm, angle_y=0.0, angle_x=0.0, about=(0, 0, 0)):
    """rotate a bmesh about Y (then X) through the point `about`"""
    ax, ay, az = about
    for v in bm.verts:
        x, y, z = v.co.x - ax, v.co.y - ay, v.co.z - az
        if angle_y:
            c, s = math.cos(angle_y), math.sin(angle_y)
            x, z = x * c + z * s, -x * s + z * c
        if angle_x:
            c, s = math.cos(angle_x), math.sin(angle_x)
            y, z = y * c - z * s, y * s + z * c
        v.co = (x + ax, y + ay, z + az)
    return bm


# --------------------------------------------------------------------------
#  blades
# --------------------------------------------------------------------------
def ring_diamond(w, t, fuller=0.0, bevel=0.34):
    """a double-edged section, 12 points: edges at ±X (index 0 and 6), the flats
    at ±Z, hollowed in the middle by `fuller` (index 3 and 9)"""
    hw, ht = w / 2, t / 2
    b = hw * (1 - bevel)
    f = ht * (1 - fuller)
    return [(hw, 0), (b, ht * 0.78), (b * 0.42, ht), (0, f), (-b * 0.42, ht), (-b, ht * 0.78), (-hw, 0),
            (-b, -ht * 0.78), (-b * 0.42, -ht), (0, -f), (b * 0.42, -ht), (b, -ht * 0.78)]


def ring_single(w, t, spine=0.8):
    """a single-edged section, 8 points: the edge at -X (index 3), the spine at +X"""
    hw, ht = w / 2, t / 2
    return [(hw, ht * spine), (hw * 0.3, ht), (-hw * 0.5, ht * 0.62), (-hw, 0), (-hw * 0.5, -ht * 0.62), (hw * 0.3, -ht), (hw, -ht * spine), (hw + ht * 0.25, 0)]


def blade(y0, length, w0, w1, t0, t1, tip=0.3, kind="double", fuller=0.0, fuller_end=0.6, curve=0.0,
          waves=0, wave_amp=0.0, belly=0.0, steps=10, color=STEEL):
    """a blade from y0 up `length`: width w0 → w1 and thickness t0 → t1 along the
    body, then a point over the last `tip` share. kind double | single.
    fuller: how deep the groove runs (0..0.6), to `fuller_end` of the body.
    curve: the blade sweeps toward -X (the edge side) by this much at the tip.
    waves: a flamberge — the edges ripple `waves` times by wave_amp. belly: a
    single edge swells out toward the point (falchion); its spine stays straight."""
    body = length * (1 - tip)
    secs, groove = [], []
    if waves:
        steps = max(steps, waves * 6)
    for i in range(steps + 1):
        f = i / steps
        y = y0 + body * f
        w = w0 + (w1 - w0) * f + belly * math.sin(math.pi * 0.5 * f) ** 2
        if waves and f > 0.08:
            w *= 1 + wave_amp * math.sin(2 * math.pi * waves * (f - 0.08) / 0.92)
        t = t0 + (t1 - t0) * f
        if kind == "single":
            pts = ring_single(w, t)
            dx = (w0 - w) / 2 - curve * f * f
        else:
            pts = ring_diamond(w, t, fuller if f <= fuller_end else 0.0)
            dx = -curve * f * f
        secs.append((y, [(x + dx, z) for x, z in pts]))
        groove.append(fuller > 0 and f <= fuller_end)
    # the point
    w_end, t_end = w, t
    edge_x = dx - w_end / 2 if kind == "single" else 0.0
    tip_steps = 4
    for k in range(1, tip_steps + 1):
        g = k / tip_steps
        y = y0 + body + (length - body) * g
        if kind == "single":   # a clipped point: the spine falls to meet the edge
            w = max(0.02, w_end * (1 - g) ** 1.15)
            pts = ring_single(w, t_end * (1 - 0.6 * g))
            dx = edge_x + w / 2 - curve * (1 + 0.4 * g) * (g * 0.3)
        else:
            w = max(0.02, w_end * (1 - g ** 1.7))
            pts = ring_diamond(w, t_end * (1 - 0.6 * g))
            dx = -curve * (1 + 0.6 * g)
        secs.append((y, [(x + dx, z) for x, z in pts]))
        groove.append(False)

    def col(si, pi):
        if kind == "single":
            return EDGE if pi == 3 else (BRIGHT if pi in (2, 4) else color)
        if pi in (0, 6):
            return EDGE
        if pi in (3, 9) and groove[si]:
            return FULLER
        return color
    return loft(secs, color, colorfn=col)


def guard(y, span, t=0.12, color=STEEL, droop=0.0, curl=0.0, flare=1.4, ends="ball", block=0.3, s_curve=False, langet=0.0):
    """quillons across X at height y, swelling `flare` times toward the ends; droop
    bends both ends toward the blade (+Y, negative: toward the hand); s_curve bends
    them opposite ways; curl rolls the tips; ends = ball | flat | none; block: the
    centre's width, with langets `langet` long up the blade's flats"""
    parts = []
    for side in (-1, 1):
        pts, rs = [], []
        for k in range(9):
            f = k / 8
            x = side * span / 2 * f
            bend = droop * f * f if not s_curve else side * droop * f * f
            yy = y + bend + curl * max(0.0, f - 0.75) ** 2 * 6 * (1 if bend >= 0 else -1)
            pts.append((x, yy, 0))
            rs.append(t / 2 * (1 + (flare - 1) * f ** 2))
        parts.append(tube(pts, rs, color, n=8))
        if ends == "ball":
            parts.append(sphere(pts[-1], rs[-1] * 1.25, color, u=10, v=6))
        elif ends == "flat":
            parts.append(sphere(pts[-1], rs[-1] * 1.3, color, u=10, v=6, scale=(0.6, 1.2, 1.0)))
    parts.append(box(0, y, 0, block, t * 1.5, t * 1.7, color))
    if langet:
        for z in (1, -1):
            parts.append(plate([(-block * 0.36, y), (block * 0.36, y), (0, y + langet)], color, t=0.03, cz=z * t * 0.62))
    return parts


def grip(length, r=0.13, color=LEATHER, wrap="spiral", wrap_color=DARKLEATHER, ferrules=IRON, y=0.0):
    """a swelling grip from y - length/2 to y + length/2: wrap = spiral | rings | wire | none"""
    y0, y1 = y - length / 2, y + length / 2
    parts = [cylinder(y0, y1, r, r * 0.94, color, n=14, bulge=0.014)]
    if wrap == "spiral" or wrap == "wire":
        turns = max(3, int(length / (0.08 if wrap == "wire" else 0.16)))
        pts = []
        for k in range(turns * 10 + 1):
            f = k / (turns * 10)
            a = 2 * math.pi * turns * f
            rr = r + 0.012 + 0.014 * math.sin(math.pi * f)
            pts.append((rr * math.cos(a), y0 + 0.03 + (length - 0.06) * f, rr * math.sin(a)))
        parts.append(tube(pts, 0.016 if wrap == "wire" else 0.024, WIRE if wrap == "wire" else wrap_color, n=5))
    elif wrap == "rings":
        n = max(2, int(length / 0.22))
        for i in range(n):
            yy = y0 + length * (i + 0.5) / n
            parts.append(cylinder(yy - 0.03, yy + 0.03, r + 0.022, r + 0.022, wrap_color, n=14))
    if ferrules:
        parts.append(cylinder(y1 - 0.06, y1 + 0.01, r + 0.03, r + 0.03, ferrules, n=14))
        parts.append(cylinder(y0 - 0.01, y0 + 0.06, r + 0.03, r + 0.03, ferrules, n=14))
    return parts


def pommel(y, size=0.3, kind="wheel", color=STEEL):
    """the knob below the grip, its top at y"""
    s = size
    if kind == "wheel":   # a disc facing the flats, a raised boss, the tang's peen
        c = y - s * 0.52
        return [disc((0, c, 0), s * 0.5, s * 0.34, color, axis="z"), disc((0, c, 0), s * 0.24, s * 0.5, color, axis="z"),
                sphere((0, y - s * 1.02, 0), s * 0.1, color, u=8, v=5)]
    if kind == "scent":   # a scent-stopper: an eight-sided swelling knob and its peen
        return [lathe([(0.0, y - s * 1.15), (s * 0.12, y - s * 1.12), (s * 0.18, y - s * 1.0), (s * 0.44, y - s * 0.62), (s * 0.5, y - s * 0.42),
                       (s * 0.3, y - s * 0.12), (s * 0.18, y)], color, n=8)]
    if kind == "pear":
        return [lathe([(0.0, y - s * 1.1), (s * 0.3, y - s * 1.05), (s * 0.5, y - s * 0.8), (s * 0.46, y - s * 0.45), (s * 0.24, y - s * 0.12), (s * 0.18, y)], color, n=14),
                sphere((0, y - s * 1.12, 0), s * 0.12, color, u=8, v=5)]
    if kind == "fishtail":   # a messer's cap, bent toward the edge (-X)
        return [sphere((-s * 0.12, y - s * 0.28, 0), s * 0.36, color, u=12, v=8, scale=(1.3, 0.8, 0.75)),
                tube([(-s * 0.2, y - s * 0.3, 0), (-s * 0.55, y - s * 0.42, 0), (-s * 0.72, y - s * 0.3, 0)], [s * 0.2, s * 0.15, s * 0.08], color, n=8)]
    if kind == "rondel":
        return [disc((0, y - s * 0.25, 0), s * 0.62, s * 0.22, color, axis="y"), sphere((0, y - s * 0.42, 0), s * 0.14, color, u=8, v=5)]
    if kind == "faceted":
        return [lathe([(0.0, y - s), (s * 0.3, y - s * 0.94), (s * 0.5, y - s * 0.5), (s * 0.3, y - s * 0.06), (s * 0.2, y)], color, n=8, rot=math.pi / 8)]
    return [lathe([(0.0, y - s), (s * 0.36, y - s * 0.86), (s * 0.5, y - s * 0.5), (s * 0.36, y - s * 0.14), (s * 0.2, y)], color, n=14)]


def sword(grip_len, blade_len, w0, w1, t0=0.14, t1=0.08, guard_w=1.2, pommel_kind="wheel", pommel_size=0.32,
          ricasso=0.0, kind="double", tip=0.3, curve=0.0, fuller=0.35, fuller_end=0.6, wrap="spiral", grip_color=LEATHER,
          guard_kw=None, blade_kw=None, extra_grip=(), extra_blade=()):
    y_guard = grip_len / 2 + 0.07
    y_blade = y_guard + 0.07 + ricasso
    g = grip(grip_len, color=grip_color, wrap=wrap)
    g += pommel(-grip_len / 2, pommel_size, pommel_kind)
    g += guard(y_guard, guard_w, **(guard_kw or {}))
    b = [blade(y_blade, blade_len, w0, w1, t0, t1, tip=tip, kind=kind, curve=curve, fuller=fuller, fuller_end=fuller_end, **(blade_kw or {}))]
    return {"Blade": b + list(extra_blade), "Grip": g + list(extra_grip)}


# --------------------------------------------------------------------------
#  hafts, sockets, langets
# --------------------------------------------------------------------------
def haft(y0, y1, r=0.1, color=WOOD, n=12):
    return [cylinder(y0, y1, r, r * 0.96, color, n=n)]


def ferrule(y, r=0.13, h=0.16, color=IRON):
    return [cylinder(y - h / 2, y + h / 2, r, r, color, n=12)]


def langets(y_top, length, r, color=DARKSTEEL, rivets=3, w=0.07):
    """two iron strips down the haft from the head, riveted through"""
    parts = []
    for z in (1, -1):
        parts.append(box(0, y_top - length / 2, z * (r + 0.012), w, length, 0.024, color))
        for k in range(rivets):
            yy = y_top - length * (k + 0.5) / rivets
            parts.append(sphere((0, yy, z * (r + 0.028)), 0.026, BRASS, u=6, v=4))
    return parts


def socket(y0, y1, r, color=DARKSTEEL):
    """the head's socket round the haft, with a collar at each end"""
    return [cylinder(y0, y1, r, r * 0.92, color, n=12), cylinder(y0 - 0.03, y0 + 0.04, r + 0.03, r + 0.03, color, n=12),
            cylinder(y1 - 0.04, y1 + 0.03, r * 0.92 + 0.03, r * 0.92 + 0.03, color, n=12)]


def butt(y, r, kind="cap", color=IRON):
    """the foot of a haft: a cap or a spike"""
    if kind == "spike":
        return [cylinder(y, y + 0.16, r + 0.02, r + 0.02, color, n=10), cone((0, y, 0), (0, y - 0.32, 0), r + 0.02, color, n=8)]
    return [cylinder(y - 0.02, y + 0.14, r + 0.025, r + 0.025, color, n=10), sphere((0, y - 0.02, 0), r + 0.025, color, u=10, v=4, scale=(1, 0.5, 1))]


def hafted(grip_len, y_bottom, y_top, r, head, cap_bottom=True, wrap=True, grip_y=0.0, fittings=(), foot="cap"):
    g = haft(y_bottom, y_top, r)
    if wrap:
        g += grip(grip_len, r + 0.02, LEATHER, wrap="spiral", ferrules=None, y=grip_y)
    if cap_bottom:
        g += butt(y_bottom, r, foot)
    return {"Blade": head, "Grip": g + list(fittings)}


def tassel(y, r, color=RED):
    """a horsehair tassel hanging below a spear's head"""
    parts = [cylinder(y - 0.05, y + 0.05, r + 0.03, r + 0.03, BRASS, n=10)]
    for k in range(10):
        a = 2 * math.pi * k / 10
        top = (math.cos(a) * (r + 0.02), y - 0.03, math.sin(a) * (r + 0.02))
        bot = (math.cos(a) * (r + 0.14), y - 0.42 - 0.05 * (k % 3), math.sin(a) * (r + 0.14))
        parts.append(tube([top, bot], [0.035, 0.012], color, n=4))
    return parts


# --------------------------------------------------------------------------
#  heads
# --------------------------------------------------------------------------
def war_hammer(y, r, crown=True, beak=0.7, top=0.6, face=0.36):
    """a hammer face (+X) crowned with four teeth, a curved beak (-X), a top spike"""
    parts = socket(y - 0.3, y + 0.3, r + 0.04)
    parts.append(box(0.24, y, 0, 0.34, face, face, STEEL))
    parts.append(box(0.43, y, 0, 0.06, face + 0.04, face + 0.04, STEEL))
    if crown:
        for dy in (-1, 1):
            for dz in (-1, 1):
                parts.append(_pyr((0.46, y + dy * face * 0.24, dz * face * 0.24), (0.58, y + dy * face * 0.24, dz * face * 0.24), 0.07, STEEL, 0))
    # the beak: a bar curving down to a point
    pts, rs = [], []
    for k in range(9):
        f = k / 8
        pts.append((-0.12 - beak * f, y - 0.22 * f ** 2 * beak, 0))
        rs.append(0.1 * (1 - f) + 0.006)
    parts.append(tube(pts, rs, STEEL, n=6))
    if top:
        parts.append(_pyr((0, y + 0.3, 0), (0, y + 0.3 + top, 0), 0.08, STEEL, 0))
    return parts


def axe(y, x0, top, reach, beard_tip, beard_x, t=0.15, t_bit=0.06, belly=0.14, neck=0.36, horn=0.08, color=FACE):
    """an axe head on the +X side of the haft at height y. The neck leaves the
    socket at x0, `neck` tall; the cutting edge runs from (x0 + reach, y + top)
    bowing out by `belly` down to the beard's tip (beard_x, y - beard_tip); the
    beard's back sweeps up to the neck."""
    xe = x0 + reach
    out = [(x0, y + neck / 2)]
    out += bez((x0, y + neck / 2), (x0 + reach * 0.55, y + neck / 2 + (top - neck / 2) * 0.2), (xe - horn, y + top), 4)[1:]
    e0 = len(out)
    edge = bez((xe - horn, y + top), (xe + belly * 2, y + (top - beard_tip) / 2), (beard_x, y - beard_tip), 8)
    out += edge[1:]
    e1 = len(out) - 1
    out += bez((beard_x, y - beard_tip), (x0 + (beard_x - x0) * 0.25, y - beard_tip * 0.55), (x0, y - neck / 2), 5)[1:-1]
    out.append((x0, y - neck / 2))
    ts = [t - (t - t_bit) * min(1.0, max(0.0, (px - x0) / reach)) for px, py in out]
    return plate(list(reversed(out)), color, t=list(reversed(ts)), ground=set(len(out) - 1 - i for i in range(e0 - 1, e1 + 1)), bevel=0.16)


def spear_head(y, length, w=0.4, t=0.09, wings=False, color=STEEL):
    """a leaf-shaped head with a raised midrib on a socket (wings: two lugs at its foot)"""
    secs = []
    n = 10
    for i in range(n + 1):
        f = i / n
        ww = w * (math.sin(math.pi * min(1.0, 0.12 + f * 1.05)) ** 0.8) if f < 0.97 else 0.02
        ww = max(ww, 0.02)
        tt = t * (1 - 0.65 * f) + 0.012
        secs.append((y + length * f, ring_diamond(ww, tt, 0.0, bevel=0.45)))
    head = loft(secs, color, colorfn=lambda si, pi: EDGE if pi in (0, 6) else color)
    parts = [head, cylinder(y - 0.55, y + 0.04, 0.13, 0.1, DARKSTEEL, n=12), cylinder(y - 0.58, y - 0.48, 0.15, 0.15, DARKSTEEL, n=12),
             cylinder(y - 0.2, y - 0.14, 0.13, 0.13, DARKSTEEL, n=12)]
    if wings:
        for side in (-1, 1):
            parts.append(plate([(0, y - 0.3), (side * 0.32, y - 0.22), (side * 0.36, y - 0.14), (0, y - 0.18)] if side > 0
                               else [(0, y - 0.3), (0, y - 0.18), (side * 0.36, y - 0.14), (side * 0.32, y - 0.22)], DARKSTEEL, t=0.05))
    return parts


# --------------------------------------------------------------------------
#  WEAPONS: each returns {"Blade": [bmeshes], "Grip": [bmeshes]}
# --------------------------------------------------------------------------
def longsword():
    return sword(0.95, 3.2, 0.34, 0.2, 0.15, 0.07, guard_w=1.35, pommel_kind="scent", pommel_size=0.34, fuller=0.5, fuller_end=0.55,
                 guard_kw=dict(droop=0.1, flare=1.5, ends="flat", block=0.3, langet=0.16))


def arming_sword():
    return sword(0.62, 2.6, 0.32, 0.22, 0.13, 0.07, guard_w=1.1, pommel_kind="wheel", pommel_size=0.34, fuller=0.55, fuller_end=0.65,
                 wrap="wire", guard_kw=dict(flare=1.3, ends="ball", block=0.28))


def shortsword():
    return sword(0.55, 2.2, 0.3, 0.26, 0.13, 0.08, guard_w=0.9, pommel_kind="round", pommel_size=0.28, fuller=0.3, fuller_end=0.45, tip=0.22,
                 guard_kw=dict(droop=0.12, flare=1.6, ends="ball", block=0.26, color=BRASS), extra_grip=[])


def greatsword():
    y_blade = 1.2 / 2 + 0.14
    lugs = [plate([(0.17, y_blade + 0.5), (0.36, y_blade + 0.62), (0.2, y_blade + 0.66)], STEEL, t=0.06),
            plate([(-0.2, y_blade + 0.66), (-0.36, y_blade + 0.62), (-0.17, y_blade + 0.5)], STEEL, t=0.06)]
    return sword(1.2, 4.0, 0.38, 0.22, 0.16, 0.07, guard_w=1.6, pommel_kind="scent", pommel_size=0.38, fuller=0.45, fuller_end=0.5,
                 wrap="rings", guard_kw=dict(droop=0.0, curl=0.08, flare=1.5, ends="ball", block=0.34, langet=0.22), extra_blade=lugs)


def zweihander():
    y_guard = 1.4 / 2 + 0.07
    y_ric = y_guard + 0.07
    extra = [cylinder(y_ric, y_ric + 0.55, 0.12, 0.12, LEATHER, n=10)]
    extra += grip(0.5, 0.12, LEATHER, wrap="spiral", ferrules=IRON, y=y_ric + 0.28)[1:2]
    # the parrying hooks at the top of the ricasso and the side rings
    for side in (-1, 1):
        extra.append(tube([(side * 0.12, y_ric + 0.6, 0), (side * 0.36, y_ric + 0.58, 0), (side * 0.42, y_ric + 0.45, 0)], [0.05, 0.04, 0.03], STEEL, n=6))
        ring_pts = [(0.17 * math.cos(a), y_guard + 0.02, side * 0.24 + 0.17 * math.sin(a)) for a in [k * math.pi / 6 for k in range(13)]]
        extra.append(tube(ring_pts, 0.03, STEEL, n=6, caps=False))
    return sword(1.4, 4.4, 0.4, 0.24, 0.16, 0.07, guard_w=1.9, pommel_kind="pear", pommel_size=0.42, ricasso=0.55, fuller=0.3, fuller_end=0.4,
                 wrap="spiral", guard_kw=dict(droop=0.14, s_curve=True, curl=0.1, flare=1.6, ends="flat", block=0.36),
                 blade_kw=dict(waves=7, wave_amp=0.16), extra_grip=extra)


def executioner():
    y_blade = 1.2 / 2 + 0.14
    holes = [disc((0, y_blade + 3.25 - k * 0.22, 0), 0.05, 0.13, BLACKIRON, axis="z") for k in range(3)]
    marks = [box(0, y_blade + 0.35 + k * 0.12, 0, 0.18 - k * 0.03, 0.03, 0.15, FULLER) for k in range(3)]
    return sword(1.2, 3.6, 0.52, 0.5, 0.13, 0.09, guard_w=1.2, pommel_kind="faceted", pommel_size=0.36, tip=0.035, fuller=0.35, fuller_end=0.5,
                 wrap="rings", guard_kw=dict(flare=1.3, ends="ball", block=0.36), extra_blade=holes + marks)


def estoc():
    y_guard = 1.0 / 2 + 0.07
    ring_pts = [(0.22 + 0.15 * math.cos(a), y_guard + 0.05, 0.15 * math.sin(a)) for a in [k * math.pi / 6 for k in range(13)]]
    return sword(1.0, 3.4, 0.2, 0.1, 0.2, 0.1, guard_w=1.2, pommel_kind="scent", pommel_size=0.32, tip=0.4, fuller=0.0,
                 guard_kw=dict(droop=0.08, flare=1.4, ends="ball", block=0.26), extra_grip=[tube(ring_pts, 0.03, STEEL, n=6, caps=False)])


def rapier():
    gl = 0.6
    y_guard = gl / 2 + 0.07
    yb = y_guard + 0.07
    parts = []
    # the knuckle bow, from the quillon block round the fingers to the pommel
    bow = [(0.0, y_guard, 0)] + [(-0.34 * math.sin(math.pi * f), y_guard - (gl + 0.12) * f, 0.0) for f in [k / 10 for k in range(1, 11)]]
    parts.append(tube(bow, 0.032, STEEL, n=6))
    # side rings and the arms of the hilt climbing to the ricasso
    for z in (1, -1):
        ring = [(0.16 * math.cos(a), y_guard + 0.03, z * 0.2 + 0.16 * math.sin(a)) for a in [k * math.pi / 8 for k in range(17)]]
        parts.append(tube(ring, 0.026, STEEL, n=6, caps=False))
        for x in (0.07, -0.07):
            parts.append(tube([(x * 3, y_guard, 0), (x * 2.2, y_guard + 0.18, z * 0.06), (x * 0.8, yb + 0.22, 0)], 0.022, STEEL, n=6))
    return sword(gl, 3.2, 0.15, 0.06, 0.11, 0.05, guard_w=1.1, pommel_kind="pear", pommel_size=0.28, tip=0.5, fuller=0.0, wrap="wire",
                 guard_kw=dict(droop=0.2, s_curve=True, flare=1.2, ends="ball", block=0.2), extra_grip=parts)


def dagger():
    y_guard = 0.45 / 2 + 0.07
    return {"Blade": [blade(y_guard + 0.06, 1.1, 0.2, 0.1, 0.12, 0.07, tip=0.45, fuller=0.0)],
            "Grip": grip(0.45, 0.11, DARKWOOD, wrap="rings", wrap_color=BRASS, ferrules=None)
            + [disc((0, y_guard, 0), 0.28, 0.08, STEEL, axis="y"), disc((0, y_guard, 0), 0.12, 0.12, BRASS, axis="y")]
            + pommel(-0.45 / 2, 0.36, "rondel")}


def falchion():
    return sword(0.6, 2.4, 0.34, 0.36, 0.12, 0.06, guard_w=1.0, pommel_kind="wheel", pommel_size=0.3, kind="single", tip=0.22, curve=0.08,
                 fuller=0.0, guard_kw=dict(droop=0.16, flare=1.5, ends="flat", block=0.26), blade_kw=dict(belly=0.26))


def messer():
    gl = 0.9
    y_guard = gl / 2 + 0.07
    # the nagel: a lug standing out of the cross on the flat side; a grip of riveted wooden scales
    extra = [tube([(0, y_guard, 0.06), (0, y_guard + 0.04, 0.2), (0, y_guard + 0.1, 0.27)], [0.04, 0.035, 0.03], STEEL, n=6),
             box(0, 0, 0, 0.3, gl, 0.2, DARKWOOD)]
    for k in range(3):
        yy = -gl / 2 + gl * (k + 0.5) / 3
        for z in (1, -1):
            extra.append(sphere((0, yy, z * 0.1), 0.03, BRASS, u=6, v=4))
    out = sword(gl, 3.0, 0.36, 0.34, 0.12, 0.06, guard_w=1.1, pommel_kind="fishtail", pommel_size=0.34, kind="single", tip=0.3, curve=0.2,
                fuller=0.0, wrap="none", guard_kw=dict(flare=1.5, ends="flat", block=0.28), extra_grip=extra)
    out["Grip"].pop(0)   # the scales replace the round grip
    return out


def cleaver():
    blade_pts = [(-0.38, 0.32), (0.32, 0.32), (0.36, 2.0), (0.06, 2.25), (-0.46, 2.18), (-0.47, 1.7), (-0.46, 1.2), (-0.43, 0.7)]
    body = plate(blade_pts, STEEL, t=[0.09, 0.09, 0.07, 0.06, 0.05, 0.06, 0.07, 0.08], ground={4, 5, 6, 7}, bevel=0.14)
    hole = disc((0.18, 1.95, 0), 0.07, 0.12, BLACKIRON, axis="z")
    g = [box(0, 0, 0, 0.26, 0.6, 0.18, DARKWOOD), box(0, 0.33, 0, 0.3, 0.08, 0.2, IRON)]
    for k in range(3):
        for z in (1, -1):
            g.append(sphere((0, -0.2 + k * 0.2, z * 0.09), 0.028, BRASS, u=6, v=4))
    return {"Blade": [body, hole], "Grip": g}


def hammer():
    return hafted(0.7, -0.5, 1.52, 0.09, war_hammer(1.55, 0.09, beak=0.6, top=0.5), fittings=langets(1.25, 0.6, 0.09), foot="cap")


def mace():
    y = 1.6
    head = [lathe([(0.0, 1.25), (0.13, 1.28), (0.17, 1.4), (0.17, 1.82), (0.12, 1.95), (0.0, 2.0)], STEEL, n=14),
            sphere((0, 2.02, 0), 0.08, STEEL, u=10, v=6), cylinder(1.22, 1.32, 0.15, 0.15, DARKSTEEL, n=12)]
    for k in range(7):   # gothic flanges: pointed above, swept below
        a = 2 * math.pi * k / 7
        f = plate([(0.1, 1.32), (0.36, 1.46), (0.4, 1.74), (0.18, 1.98), (0.1, 1.9)], STEEL, t=0.05, ground={1, 2, 3}, bevel=0.06)
        head.append(turn(f, angle_y=a))
    return hafted(0.8, -0.6, 1.3, 0.09, head, fittings=langets(1.2, 0.5, 0.09))


def morning_star():
    y = 1.78
    head = [sphere((0, y, 0), 0.34, DARKSTEEL, u=16, v=10), cylinder(1.4, 1.5, 0.16, 0.16, IRON, n=12),
            cylinder(y - 0.02, y + 0.02, 0.35, 0.35, IRON, n=16)]
    for ring_y, n, lift in ((0.0, 8, 0.0), (0.2, 6, 0.6), (-0.2, 6, -0.6)):
        for k in range(n):
            a = 2 * math.pi * k / n + (0.3 if lift else 0)
            d = Vector((math.cos(a), lift, math.sin(a))).normalized()
            base = Vector((0, y, 0)) + d * 0.3
            head.append(cone(base, base + d * 0.3, 0.07, STEEL, n=6))
    head.append(cone((0, y + 0.3, 0), (0, y + 0.66, 0), 0.08, STEEL, n=6))
    return hafted(0.9, -0.7, 1.45, 0.1, head, fittings=langets(1.42, 0.5, 0.1))


def maul():
    y = 2.55
    head = [loft([(x, ring_ellipse(r, r, 8, math.pi / 8)) for x, r in ((-0.6, 0.38), (-0.5, 0.4), (0.5, 0.4), (0.6, 0.38))], DARKSTEEL)]
    turn(head[0], angle_x=0)
    for v in head[0].verts:   # lay the octagonal block along X
        x, yy, z = v.co
        v.co = (yy, y + x, z)
    for x in (-0.42, 0.42):
        b = cylinder(-0.06, 0.06, 0.43, 0.43, IRON, n=8)
        for v in b.verts:
            xx, yy, z = v.co
            v.co = (x + yy, y + xx, z)
        head.append(b)
        for k in range(4):
            a = k * math.pi / 2 + math.pi / 4
            head.append(sphere((x, y + 0.42 * math.cos(a), 0.42 * math.sin(a)), 0.04, BRASS, u=6, v=4))
    head.append(_pyr((0, y + 0.38, 0), (0, y + 0.72, 0), 0.12, STEEL, 0))
    return hafted(1.0, -1.2, 2.3, 0.12, head, fittings=langets(2.2, 0.7, 0.12) + socket(2.18, 2.36, 0.15))


def war_axe():
    y = 1.35
    head = [axe(y, 0.1, 0.36, 0.84, 0.74, 0.5, t=0.15, belly=0.12, neck=0.32)]
    head += socket(y - 0.24, y + 0.24, 0.13)
    head.append(box(-0.17, y, 0, 0.12, 0.3, 0.26, DARKSTEEL))   # the poll
    return hafted(0.8, -0.7, 1.7, 0.09, head, fittings=langets(y - 0.24, 0.45, 0.09))


def battle_axe():
    y = 2.2
    head = [axe(y, 0.12, 0.72, 1.12, 0.66, 1.0, t=0.17, belly=0.2, neck=0.42, horn=0.1)]
    head += socket(y - 0.3, y + 0.3, 0.15)
    pts, rs = [], []
    for k in range(9):   # the back spike, curving down
        f = k / 8
        pts.append((-0.16 - 0.6 * f, y - 0.16 * f * f, 0)); rs.append(0.09 * (1 - f) + 0.006)
    head.append(tube(pts, rs, STEEL, n=6))
    head.append(_pyr((0, y + 0.3, 0), (0, y + 0.75, 0), 0.08, STEEL, 0))
    return hafted(1.1, -1.0, 2.5, 0.11, head, fittings=langets(y - 0.3, 0.6, 0.11), foot="spike")


def bardiche():
    # a long crescent blade fixed to the haft at its top socket and riveted below
    y0, y1 = 1.45, 3.4
    out = [(0.12, y1 - 0.25), (0.34, y1 + 0.08), (0.62, y1 + 0.3)]
    out += bez((0.62, y1 + 0.3), (1.25, (y0 + y1) / 2 + 0.2), (0.4, y0 + 0.02), 10)[1:]
    out += [(0.24, y0 + 0.14), (0.12, y0 + 0.3), (0.12, y1 - 0.6)]
    ground = set(range(2, 13))
    head = [plate(list(reversed(out)), FACE, t=0.1, ground=set(len(out) - 1 - i for i in ground), bevel=0.18)]
    head += socket(y1 - 0.45, y1 - 0.1, 0.14)
    head += socket(y0 + 0.12, y0 + 0.32, 0.13)
    return hafted(1.1, -1.3, 3.3, 0.11, head, fittings=langets(y0 + 0.1, 0.5, 0.11))


def spear():
    return hafted(0.9, -1.6, 3.5, 0.09, spear_head(3.45, 1.4, wings=True), wrap=False, foot="spike", fittings=tassel(2.88, 0.09))


def pitchfork():
    y = 3.3
    head = [box(0, y, 0, 0.92, 0.1, 0.1, IRON), cylinder(y - 0.35, y + 0.02, 0.11, 0.1, IRON, n=10)]
    for x in (-0.38, 0.0, 0.38):
        pts = [(x, y, 0), (x * 1.06, y + 0.5, 0.0), (x * 1.04, y + 1.0, 0.06), (x, y + 1.3, 0.16)]
        head.append(tube(pts, [0.05, 0.045, 0.035, 0.008], IRON, n=6))
    fit = []
    for k in range(4):   # rope binding below the socket
        fit.append(cylinder(y - 0.5 - k * 0.06, y - 0.46 - k * 0.06, 0.11, 0.11, ROPE, n=10))
    return hafted(0.9, -1.6, 3.3, 0.09, head, wrap=False, fittings=fit)


def halberd():
    y = 3.0
    blade_ = axe(y, 0.12, 0.5, 0.92, 0.5, 0.92, t=0.12, belly=-0.08, neck=0.5, horn=0.0)
    head = [blade_] + socket(y - 0.45, y + 0.4, 0.13)
    pts, rs = [], []
    for k in range(9):   # the back fluke
        f = k / 8
        pts.append((-0.14 - 0.62 * f, y + 0.05 - 0.3 * f * f, 0)); rs.append(0.08 * (1 - f) + 0.006)
    head.append(tube(pts, rs, STEEL, n=4))
    head.append(_pyr((0, y + 0.4, 0), (0, y + 1.45, 0), 0.09, STEEL, math.pi / 4))
    return hafted(1.0, -1.6, 3.5, 0.1, head, fittings=langets(y - 0.45, 1.0, 0.1, rivets=4), foot="spike")


def poleaxe():
    y = 2.9
    head = war_hammer(y, 0.1, beak=0.7, top=0.85, face=0.4)
    rondel = disc((0, 1.05, 0), 0.26, 0.05, STEEL, axis="y")
    return hafted(1.0, -1.5, 3.2, 0.1, head, fittings=langets(y - 0.3, 1.0, 0.1, rivets=4) + [rondel], foot="spike")


def glaive():
    y = 3.3
    out = [(0.1, y), (0.26, y + 0.06)]
    out += bez((0.26, y + 0.06), (0.32, y + 1.45), (-0.04, y + 2.3), 8)[1:]   # the spine, curving back
    out += bez((-0.04, y + 2.3), (-0.3, y + 1.1), (-0.14, y + 0.05), 8)[1:-1]   # the edge
    out += [(-0.12, y)]
    n = len(out)
    edge = set(range(9, n - 1))
    blade_ = plate(out, FACE, t=0.09, ground=edge, bevel=0.12)
    lug = _pyr((0.28, y + 0.45, 0), (0.56, y + 0.56, 0), 0.06, STEEL, 0)
    head = [blade_, lug] + socket(y - 0.4, y + 0.02, 0.13)
    return hafted(1.0, -1.5, 3.3, 0.1, head, fittings=tassel(y - 0.48, 0.1), foot="spike")


def billhook():
    y = 3.1
    out = [(0.1, y), (0.24, y + 0.1), (0.26, y + 0.9), (0.2, y + 1.3)]
    out += bez((0.2, y + 1.3), (0.06, y + 1.78), (-0.44, y + 1.52), 6)[1:]   # over the top and down: the beak
    out += [(-0.3, y + 1.42), (-0.17, y + 1.34), (-0.14, y + 1.1), (-0.2, y + 0.7), (-0.15, y + 0.12), (-0.1, y)]
    blade_ = plate(out, FACE, t=0.09, ground={9, 10, 11, 12, 13, 14}, bevel=0.12)
    head = [blade_, _pyr((0.06, y + 1.5, 0), (0.1, y + 2.08, 0), 0.07, STEEL, math.pi / 4),
            _pyr((0.26, y + 0.8, 0), (0.6, y + 0.9, 0), 0.06, STEEL, 0)]
    head += socket(y - 0.4, y + 0.02, 0.13)
    return hafted(1.0, -1.4, 3.1, 0.1, head, fittings=langets(y - 0.4, 0.6, 0.1), foot="spike")


def quarterstaff():
    g = haft(-2.4, 2.6, 0.1, DARKWOOD)
    for y in (1.3, -1.1):
        g += grip(0.6, 0.12, LEATHER, wrap="spiral", ferrules=None, y=y)
    iron = []
    for y in (2.6, -2.4):
        iron += [cylinder(y - 0.2, y + 0.0, 0.125, 0.125, IRON, n=10)] if y > 0 else [cylinder(y, y + 0.2, 0.125, 0.125, IRON, n=10)]
        iron.append(sphere((0, y, 0), 0.125, IRON, u=10, v=4, scale=(1, 0.4, 1)))
        for k in range(4):
            a = k * math.pi / 2
            iron.append(sphere((0.13 * math.cos(a), y - 0.1 if y > 0 else y + 0.1, 0.13 * math.sin(a)), 0.022, BRASS, u=6, v=4))
    for y in (0.4, -0.2, 2.1, -1.9):
        iron.append(cylinder(y - 0.03, y + 0.03, 0.115, 0.115, IRON, n=10))
    return {"Blade": iron, "Grip": g}


WEAPONS = {
    # swords
    "Longsword": longsword, "ArmingSword": arming_sword, "Shortsword": shortsword, "Greatsword": greatsword,
    "Zweihander": zweihander, "Executioner": executioner, "Estoc": estoc, "Rapier": rapier, "Dagger": dagger,
    "Falchion": falchion, "Messer": messer, "Cleaver": cleaver,
    # blunt
    "Hammer": hammer, "Mace": mace, "MorningStar": morning_star, "Maul": maul,
    # axes
    "WarAxe": war_axe, "BattleAxe": battle_axe, "Bardiche": bardiche,
    # polearms
    "Spear": spear, "Pitchfork": pitchfork, "Halberd": halberd, "Poleaxe": poleaxe, "Glaive": glaive,
    "Billhook": billhook, "Quarterstaff": quarterstaff,
}


# --------------------------------------------------------------------------
#  build + export
# --------------------------------------------------------------------------
def to_object(name, bms):
    bm = merge(*bms)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    # smooth by angle so flats stay crisp and round grips look round
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    ob.select_set(False)
    return ob


def export(ob, path):
    for o in bpy.context.scene.objects:
        o.select_set(o == ob)
    bpy.context.view_layer.objects.active = ob
    # Roblox takes the FBX's Z as its Y (and keeps X): spin the mesh so the
    # Tool's +Y (the blade) is on Blender +Z for the file, then spin it back
    ob.rotation_euler = (math.radians(90), 0, 0)
    # Roblox reads FBX centimetres (100 units = 1 stud) and takes the axes as
    # they come, so pass coordinates through unchanged at 1/100
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, global_scale=0.01,
                             axis_forward="Y", axis_up="Z", mesh_smooth_type="FACE", colors_type="LINEAR",
                             add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, path_mode="STRIP")
    ob.rotation_euler = (0, 0, 0)


def clear_scene():
    for o in list(bpy.context.scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def bounds(ob):
    xs = [v.co.x for v in ob.data.vertices]; ys = [v.co.y for v in ob.data.vertices]; zs = [v.co.z for v in ob.data.vertices]
    lo, hi = (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))
    return {"center": [(lo[i] + hi[i]) / 2 for i in range(3)], "size": [hi[i] - lo[i] for i in range(3)]}


def build(name, out_dir):
    """writes <name>_Blade.fbx / <name>_Grip.fbx and <name>.json. Roblox
    re-centres every mesh on its bounding box, so the json keeps each region's
    centre in the Tool frame: the weld offset from the Handle (the origin)."""
    import json
    spec = WEAPONS[name]()
    clear_scene()
    written = []
    meta = {"weapon": name, "regions": {}}
    for region in ("Blade", "Grip"):
        parts = spec.get(region) or []
        if not parts:
            continue
        ob = to_object(f"{name}_{region}", parts)
        p = os.path.join(out_dir, f"{name}_{region}.fbx")
        export(ob, p)
        tri = len(ob.data.polygons)
        meta["regions"][region] = dict(bounds(ob), tris=tri, file=os.path.basename(p))
        written.append((p, tri))
    with open(os.path.join(out_dir, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    return written


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    names = list(WEAPONS) if (not argv or argv == ["all"]) else argv
    for n in names:
        for p, tri in build(n, out_dir):
            print(f"WROTE {p} ({tri} tris)")
