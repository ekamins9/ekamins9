"""Procedural medieval weapon meshes for the R6 melee game, built in Blender
headless and exported as FBX for Roblox.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python blender/weapons.py -- Longsword [More...]
    ... -- all            every weapon in WEAPONS
    ... -- all --out dir  export folder (default blender/out)

Each weapon is ONE mesh in the Tool's frame: the fist (the Handle) at the
origin, the business end along +Y, the edge in the XY plane (the blade's flat
faces look along ±Z); 1 unit = 1 stud. Vertex colors paint the regions
(steel, leather, wood, brass) so the MeshPart reads them with no texture; the
Dresser tints SkinPart = "Blade" / "Grip" parts, so each weapon is exported as
TWO meshes: <Weapon>_Blade.fbx (everything steel) and <Weapon>_Grip.fbx (grip,
guard, pommel, haft) that both sit on the same origin. Studio: both become
MeshParts welded to the Tool's Handle at the identity offset.

Shapes: cross-section profiles lofted along Y (blades taper in width and
thickness, grips swell), lathed solids (pommels, mace heads) and a few boxes
(guards, axe bits), joined, smoothed by angle, triangulated.
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out")

# vertex colors (linear RGB) for the regions — Roblox shows them when the
# MeshPart has no texture and `Color` is white
STEEL = (0.62, 0.65, 0.69)
BRIGHT = (0.80, 0.83, 0.87)
DARKSTEEL = (0.22, 0.24, 0.27)
IRON = (0.33, 0.35, 0.38)
LEATHER = (0.22, 0.12, 0.07)
DARKLEATHER = (0.10, 0.06, 0.04)
WOOD = (0.36, 0.22, 0.11)
BRASS = (0.62, 0.45, 0.17)
GOLD = (0.85, 0.62, 0.18)

# --------------------------------------------------------------------------
#  mesh helpers (all return a bmesh)
# --------------------------------------------------------------------------
def loft(sections, color, close_ends=True):
    """sections: list of (y, [ (x, z), ... ]) rings with the same vertex count.
    Builds a tube through them along Y."""
    bm = bmesh.new()
    rings = []
    for y, pts in sections:
        rings.append([bm.verts.new((x, y, z)) for x, z in pts])
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    if close_ends:
        bm.faces.new(tuple(reversed(rings[0])))
        bm.faces.new(tuple(rings[-1]))
    paint(bm, color)
    return bm


def ring_ellipse(rx, rz, n=12, rot=0.0):
    return [(rx * math.cos(2 * math.pi * i / n + rot), rz * math.sin(2 * math.pi * i / n + rot)) for i in range(n)]


def ring_blade(w, t, fuller=0.0):
    """a double-edged diamond / lenticular blade section: width w (edge to
    edge, along X), thickness t (along Z). 8 points: edges sharp, flats with a
    slight fuller dip."""
    hw, ht = w / 2, t / 2
    f = ht * (1 - fuller)
    return [(hw, 0), (hw * 0.55, ht), (0, f), (-hw * 0.55, ht), (-hw, 0), (-hw * 0.55, -ht), (0, -f), (hw * 0.55, -ht)]


def ring_single_edge(w, t, spine=0.6):
    """a single-edged section (falchion / messer / cleaver): the edge at -X,
    a thick spine at +X."""
    hw, ht = w / 2, t / 2
    return [(hw, ht * spine), (hw * 0.6, ht), (-hw * 0.2, ht * 0.9), (-hw, 0), (-hw * 0.2, -ht * 0.9), (hw * 0.6, -ht), (hw, -ht * spine), (hw, 0)]


def blade(y0, length, w0, w1, t0, t1, tip=0.35, color=STEEL, kind="double", fuller=0.35, curve=0.0):
    """a blade from y0 up `length`, width w0→w1 and thickness t0→t1 along the
    body, then a point over the last `tip` fraction. `curve` bends the tip
    toward -X (falchions)."""
    secs = []
    body = length * (1 - tip)
    steps = 6
    for i in range(steps + 1):
        f = i / steps
        y = y0 + body * f
        w, t = w0 + (w1 - w0) * f, t0 + (t1 - t0) * f
        pts = ring_blade(w, t, fuller * (1 - f)) if kind == "double" else ring_single_edge(w, t)
        pts = [(x + curve * f * f, z) for x, z in pts]
        secs.append((y, pts))
    # the point: shrink to a sliver, slightly off-centre for single edges
    ytip = y0 + length
    pts = ring_blade(0.02, 0.02) if kind == "double" else ring_single_edge(0.02, 0.02)
    xoff = curve + (0 if kind == "double" else -w1 * 0.3)
    secs.append((ytip, [(x + xoff, z) for x, z in pts]))
    return loft(secs, color)


def cylinder(y0, y1, r0, r1=None, color=WOOD, n=14, bulge=0.0):
    r1 = r0 if r1 is None else r1
    secs = []
    for i in range(5):
        f = i / 4
        r = r0 + (r1 - r0) * f + bulge * math.sin(math.pi * f)
        secs.append((y0 + (y1 - y0) * f, ring_ellipse(r, r, n)))
    return loft(secs, color)


def lathe(profile, color, n=16):
    """profile: list of (radius, y) from bottom to top → solid of revolution."""
    secs = [(y, ring_ellipse(max(r, 0.005), max(r, 0.005), n)) for r, y in profile]
    return loft(secs, color)


def box(cx, cy, cz, sx, sy, sz, color, rot_y=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        x, y, z = v.co.x * sx, v.co.y * sy, v.co.z * sz
        if rot_y:
            c, s = math.cos(rot_y), math.sin(rot_y)
            x, z = x * c - z * s, x * s + z * c
        v.co = (x + cx, y + cy, z + cz)
    paint(bm, color)
    return bm


def wedge(cx, cy, cz, sx, sy, sz, color, flip=False):
    """a triangular prism: full width at the base (y = cy - sy/2), a ridge at
    the top (y = cy + sy/2); X is the across axis. flip: ridge at the bottom."""
    bm = bmesh.new()
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    yb, yt = (cy + hy, cy - hy) if flip else (cy - hy, cy + hy)
    a = bm.verts.new((cx - hx, yb, cz - hz)); b = bm.verts.new((cx + hx, yb, cz - hz))
    c = bm.verts.new((cx + hx, yb, cz + hz)); d = bm.verts.new((cx - hx, yb, cz + hz))
    e = bm.verts.new((cx - hx, yt, cz)); f = bm.verts.new((cx + hx, yt, cz))
    for face in ((a, d, c, b), (a, b, f, e), (d, e, f, c), (a, e, d), (b, c, f)):
        bm.faces.new(face)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    paint(bm, color)
    return bm


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
        vmap = {}
        for v in bm.verts:
            vmap[v.index if v.index >= 0 else id(v)] = out.verts.new(v.co)
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
    # drop the duplicate verts made by vmap bookkeeping
    bmesh.ops.delete(out, geom=[v for v in out.verts if not v.link_faces], context="VERTS")
    return out


# --------------------------------------------------------------------------
#  sub-assemblies (all in the Tool frame: fist at the origin, blade along +Y)
# --------------------------------------------------------------------------
def grip(length, r=0.13, color=LEATHER, wraps=True):
    parts = [cylinder(-length / 2, length / 2, r, r, color, bulge=0.012)]
    if wraps:
        n = max(2, int(length / 0.22))
        for i in range(n):
            y = -length / 2 + length * (i + 0.5) / n
            parts.append(cylinder(y - 0.03, y + 0.03, r + 0.02, r + 0.02, DARKLEATHER, n=14))
    return parts


def pommel(y, size=0.3, kind="wheel", color=STEEL):
    if kind == "wheel":   # a flat disc seen edge-on from the side
        bm = lathe([(0.0, y - size * 0.22), (size * 0.5, y - size * 0.2), (size * 0.5, y + size * 0.2), (0.0, y + size * 0.22)], color, n=18)
        # tilt the wheel so its flat faces look along ±Z (like a real wheel pommel)
        for v in bm.verts:
            x, yy, z = v.co
            v.co = (x, y + (z), (yy - y))
        return [bm]
    if kind == "scent":   # scent-stopper: a faceted tapering knob
        return [lathe([(0.0, y - size * 0.55), (size * 0.32, y - size * 0.5), (size * 0.5, y), (size * 0.28, y + size * 0.45), (0.0, y + size * 0.5)], color, n=8)]
    return [lathe([(0.0, y - size * 0.5), (size * 0.45, y - size * 0.3), (size * 0.5, y), (size * 0.45, y + size * 0.3), (0.0, y + size * 0.5)], color, n=14)]


def crossguard(y, width, t=0.14, color=STEEL, droop=0.0, flare=1.25):
    """a straight bar across X with a block at the centre; droop > 0 curves the
    quillon ends toward the blade (+Y)."""
    secs = []
    for i in range(7):
        f = i / 6
        x = -width / 2 + width * f
        edge = abs(f - 0.5) * 2
        thick = t * (1 + (flare - 1) * edge)
        yy = y + droop * edge * edge
        secs.append((x, yy, thick))
    bm = bmesh.new()
    rings = []
    for x, yy, thick in secs:
        rings.append([bm.verts.new((x, yy + dy, dz)) for dy, dz in ((thick * 0.5, thick * 0.45), (-thick * 0.5, thick * 0.45), (-thick * 0.5, -thick * 0.45), (thick * 0.5, -thick * 0.45))])
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            bm.faces.new((a[i], b[i], b[(i + 1) % 4], a[(i + 1) % 4]))
    bm.faces.new(tuple(rings[0])); bm.faces.new(tuple(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    paint(bm, color)
    block = box(0, y, 0, 0.34, t * 1.6, t * 1.5, color)
    return [bm, block]


def haft(y0, y1, r=0.11, color=WOOD):
    return [cylinder(y0, y1, r, r, color, n=12)]


def ferrule(y, r=0.13, h=0.16, color=IRON):
    return [cylinder(y - h / 2, y + h / 2, r, r, color, n=12)]


def axe_bit(y, height, reach, t=0.06, color=STEEL, beard=0.0, back="none"):
    """an axe head on the +X side of the haft at height y: a socket, a body
    widening to a curved edge; beard extends the edge downward; back = spike
    or hammer."""
    parts = [box(0, y, 0, 0.3, height * 0.55, 0.34, DARKSTEEL)]
    secs = []
    steps = 6
    for i in range(steps + 1):
        f = i / steps
        x = 0.12 + reach * f
        h = height * (0.45 + 0.55 * f) + beard * f * f
        yc = y - beard * f * f * 0.5
        tt = t * (1.6 - 1.4 * f) + 0.01
        secs.append([(x, yc + h / 2, tt / 2), (x, yc + h / 2, -tt / 2), (x, yc - h / 2, -tt / 2), (x, yc - h / 2, tt / 2)])
    bm = bmesh.new()
    rings = [[bm.verts.new(p) for p in s] for s in secs]
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            bm.faces.new((a[i], a[(i + 1) % 4], b[(i + 1) % 4], b[i]))
    bm.faces.new(tuple(reversed(rings[0]))); bm.faces.new(tuple(rings[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    paint(bm, color)
    parts.append(bm)
    if back == "spike":
        parts.append(spike(-0.15, y, 0.7, 0.16, DARKSTEEL, axis="-x"))
    elif back == "hammer":
        parts.append(box(-0.32, y, 0, 0.4, height * 0.5, 0.36, DARKSTEEL))
    return parts


def spike(x, y, length, base, color=STEEL, axis="+y"):
    """a square pyramid spike; axis = +y (up the blade), -x (a back spike)."""
    bm = bmesh.new()
    hb = base / 2
    if axis == "+y":
        base_pts = [(x - hb, y, -hb), (x + hb, y, -hb), (x + hb, y, hb), (x - hb, y, hb)]
        apex = (x, y + length, 0)
    else:
        base_pts = [(x, y - hb, -hb), (x, y + hb, -hb), (x, y + hb, hb), (x, y - hb, hb)]
        apex = (x - length, y, 0)
    vs = [bm.verts.new(p) for p in base_pts]
    a = bm.verts.new(apex)
    bm.faces.new(tuple(vs))
    for i in range(4):
        bm.faces.new((vs[i], vs[(i + 1) % 4], a))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    paint(bm, color)
    return bm


def spearhead(y, length, w=0.42, t=0.08, color=STEEL):
    """a leaf-shaped head on a socket."""
    secs = [(y, ring_blade(0.14, 0.14))]
    for i in range(1, 6):
        f = i / 5
        ww = w * math.sin(math.pi * min(1, 0.15 + 0.85 * f)) if f < 0.9 else w * 0.25
        secs.append((y + length * f * 0.92, ring_blade(max(ww, 0.03), t * (1 - 0.6 * f) + 0.02, 0)))
    secs.append((y + length, ring_blade(0.02, 0.02)))
    return [cylinder(y - 0.45, y + 0.05, 0.14, 0.12, DARKSTEEL), loft(secs, color)]


# --------------------------------------------------------------------------
#  WEAPONS: each returns {"Blade": [bmeshes], "Grip": [bmeshes]}
# --------------------------------------------------------------------------
def sword(grip_len, blade_len, w0, w1, t0=0.14, t1=0.08, guard_w=1.2, pommel_kind="wheel", pommel_size=0.32,
          ricasso=0.0, rings=False, kind="double", tip=0.3, curve=0.0, guard_droop=0.0, fuller=0.35):
    y_guard = grip_len / 2 + 0.07
    y_blade = y_guard + 0.07 + ricasso
    g = grip(grip_len)
    g += pommel(-grip_len / 2 - pommel_size * 0.5, pommel_size, pommel_kind)
    g += crossguard(y_guard, guard_w, droop=guard_droop)
    if ricasso:
        g.append(cylinder(y_guard + 0.07, y_blade, w0 * 0.55, w0 * 0.55, LEATHER, n=10))
        g += crossguard(y_blade + 0.02, w0 + 0.6, t=0.1, flare=1.0)
    if rings:
        for z in (0.2, -0.2):
            r = lathe([(0.0, -0.03), (0.22, -0.03), (0.22, 0.03), (0.0, 0.03)], STEEL, n=14)
            for v in r.verts:
                x, yy, zz = v.co
                v.co = (x, y_guard + 0.1 + zz, z + yy)
            g.append(r)
    b = [blade(y_blade, blade_len, w0, w1, t0, t1, tip=tip, kind=kind, curve=curve, fuller=fuller)]
    return {"Blade": b, "Grip": g}


def hafted(grip_len, y_bottom, y_top, r, head, cap_bottom=True, wrap=True):
    g = haft(y_bottom, y_top, r)
    if wrap:
        g += grip(grip_len, r + 0.03, LEATHER, wraps=True)
    if cap_bottom:
        g += ferrule(y_bottom + 0.08, r + 0.03)
    return {"Blade": head, "Grip": g}


WEAPONS = {
    # swords
    "Longsword":   lambda: sword(0.95, 3.2, 0.34, 0.22, guard_w=1.35, pommel_kind="scent", pommel_size=0.34),
    "ArmingSword": lambda: sword(0.62, 2.6, 0.32, 0.22, guard_w=1.1, pommel_kind="wheel"),
    "Shortsword":  lambda: sword(0.55, 2.2, 0.3, 0.2, guard_w=0.9, pommel_kind="wheel", pommel_size=0.26),
    "Greatsword":  lambda: sword(1.2, 4.0, 0.38, 0.24, 0.16, 0.08, guard_w=1.6, pommel_kind="scent", pommel_size=0.36),
    "Zweihander":  lambda: sword(1.4, 4.4, 0.4, 0.24, 0.16, 0.08, guard_w=1.8, pommel_kind="scent", pommel_size=0.38, ricasso=0.55, rings=True),
    "Executioner": lambda: sword(1.2, 3.6, 0.5, 0.48, 0.14, 0.1, guard_w=1.2, pommel_kind="round", pommel_size=0.34, tip=0.04, fuller=0.5),
    "Estoc":       lambda: sword(1.0, 3.4, 0.22, 0.1, 0.22, 0.12, guard_w=1.1, pommel_kind="scent", pommel_size=0.3, tip=0.45, fuller=0.0),
    "Rapier":      lambda: sword(0.6, 3.2, 0.16, 0.06, 0.12, 0.06, guard_w=0.9, pommel_kind="round", pommel_size=0.26, tip=0.5, fuller=0.0, guard_droop=0.25),
    "Dagger":      lambda: sword(0.45, 1.1, 0.22, 0.12, 0.1, 0.06, guard_w=0.5, pommel_kind="wheel", pommel_size=0.22, tip=0.45),
    "Falchion":    lambda: sword(0.6, 2.4, 0.4, 0.56, 0.12, 0.06, guard_w=1.0, pommel_kind="wheel", kind="single", tip=0.25, curve=-0.25),
    "Messer":      lambda: sword(0.9, 3.0, 0.36, 0.34, 0.12, 0.06, guard_w=1.1, pommel_kind="round", pommel_size=0.28, kind="single", tip=0.3, curve=-0.35),
    "Cleaver":     lambda: {"Blade": [blade(0.3, 1.9, 0.7, 0.8, 0.08, 0.06, tip=0.12, kind="single", fuller=0)], "Grip": grip(0.5, 0.12, WOOD, wraps=False) + [box(0, 0.3, 0, 0.3, 0.1, 0.2, IRON)]},
    # blunt
    "Hammer":      lambda: hafted(0.7, -0.5, 1.5, 0.09, [box(0.18, 1.55, 0, 0.6, 0.4, 0.4, STEEL), spike(-0.1, 1.55, 0.6, 0.22, DARKSTEEL, axis="-x"), box(0, 1.55, 0, 0.3, 0.5, 0.42, DARKSTEEL)]),
    "Mace":        lambda: hafted(0.8, -0.6, 1.35, 0.09, [lathe([(0.0, 1.25), (0.2, 1.3), (0.24, 1.6), (0.2, 1.9), (0.0, 1.95)], STEEL, n=12)] + [flange(1.6, k) for k in range(6)], wrap=True),
    "MorningStar": lambda: hafted(0.9, -0.7, 1.45, 0.1, [lathe([(0.0, 1.4), (0.3, 1.5), (0.36, 1.78), (0.3, 2.05), (0.0, 2.15)], DARKSTEEL, n=14)] + star_spikes(1.78, 0.34, 10) + [spike(0, 2.12, 0.35, 0.14)]),
    "Maul":        lambda: hafted(1.0, -1.2, 2.3, 0.12, [box(0, 2.55, 0, 1.1, 0.7, 0.7, DARKSTEEL), box(0, 2.55, 0, 1.14, 0.12, 0.74, IRON), spike(0, 2.9, 0.4, 0.5, STEEL)]),
    # axes
    "WarAxe":      lambda: hafted(0.8, -0.7, 1.7, 0.09, axe_bit(1.35, 0.9, 1.0, beard=0.3)),
    "BattleAxe":   lambda: hafted(1.1, -1.0, 2.75, 0.11, axe_bit(2.2, 1.3, 1.3, back="spike") + [spike(0, 2.75, 0.5, 0.2)]),
    "Bardiche":    lambda: hafted(1.1, -1.3, 3.3, 0.11, axe_bit(2.6, 2.2, 1.0, beard=0.6) + [box(0.1, 1.5, 0, 0.3, 0.2, 0.3, DARKSTEEL)]),
    # polearms
    "Spear":       lambda: hafted(0.9, -1.6, 3.5, 0.09, spearhead(3.45, 1.4), wrap=False),
    "Pitchfork":   lambda: hafted(0.9, -1.6, 3.3, 0.09, [box(0, 3.3, 0, 0.9, 0.12, 0.12, IRON)] + [spike(x, 3.3, 1.3, 0.1) for x in (-0.38, 0, 0.38)], wrap=False),
    "Halberd":     lambda: hafted(1.0, -1.6, 3.7, 0.1, axe_bit(3.0, 1.1, 1.0, back="spike") + [spike(0, 3.7, 1.0, 0.22), box(0, 2.3, 0, 0.28, 1.4, 0.28, DARKSTEEL)]),
    "Poleaxe":     lambda: hafted(1.0, -1.5, 3.4, 0.1, [box(0.3, 2.9, 0, 0.6, 0.45, 0.45, DARKSTEEL), spike(-0.15, 2.9, 0.7, 0.18, STEEL, axis="-x"), spike(0, 3.4, 0.9, 0.2), box(0, 2.2, 0, 0.26, 1.4, 0.26, DARKSTEEL)]),
    "Glaive":      lambda: hafted(1.0, -1.5, 3.3, 0.1, [blade(3.3, 2.3, 0.44, 0.36, 0.1, 0.06, tip=0.3, kind="single", curve=-0.2, fuller=0)] + ferrule(3.35, 0.15, 0.4, DARKSTEEL), wrap=True),
    "Billhook":    lambda: hafted(1.0, -1.4, 3.1, 0.1, [blade(3.1, 1.6, 0.36, 0.34, 0.1, 0.06, tip=0.08, kind="single", fuller=0), box(0.3, 4.75, 0, 0.6, 0.3, 0.07, STEEL), spike(0, 4.7, 0.5, 0.18), spike(-0.1, 3.9, 0.45, 0.12, STEEL, axis="-x")] + ferrule(3.15, 0.15, 0.4, DARKSTEEL)),
    "Quarterstaff": lambda: hafted(1.0, -2.4, 2.6, 0.1, ferrule(2.6, 0.13, 0.18) + ferrule(1.2, 0.13, 0.1) + ferrule(-1.2, 0.13, 0.1), cap_bottom=True, wrap=True),
}


def flange(y, k, n=6):
    a = 2 * math.pi * k / n
    bm = box(0.28 * math.cos(a), y, 0.28 * math.sin(a), 0.14, 0.62, 0.2, STEEL, rot_y=-a)
    return bm


def star_spikes(y, r, n):
    out = []
    for k in range(n):
        a = 2 * math.pi * k / n
        s = spike(0, 0, 0.32, 0.14, STEEL)
        for v in s.verts:
            x, yy, z = v.co
            # point the spike outward along (cos a, 0, sin a)
            px, py, pz = yy, 0, 0  # along local +Y → radial
            v.co = (r * math.cos(a) + yy * math.cos(a) + x * (-math.sin(a)), y + z, r * math.sin(a) + yy * math.sin(a) + x * math.cos(a))
        out.append(s)
    return out


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
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", colors_type="LINEAR",
                             add_leaf_bones=False, bake_anim=False, use_mesh_modifiers=True, path_mode="STRIP")


def clear_scene():
    for o in list(bpy.context.scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def build(name, out_dir):
    spec = WEAPONS[name]()
    clear_scene()
    written = []
    for region in ("Blade", "Grip"):
        parts = spec.get(region) or []
        if not parts:
            continue
        ob = to_object(f"{name}_{region}", parts)
        p = os.path.join(out_dir, f"{name}_{region}.fbx")
        export(ob, p)
        tri = len(ob.data.polygons)
        written.append((p, tri))
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
