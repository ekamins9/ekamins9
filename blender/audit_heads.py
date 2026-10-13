"""Audit every head piece (hoods, helmets, hats) for the head poking through it, in
Blender headless, straight from a blueprints JSON:

    blender.exe -b --python blender/audit_heads.py -- blender/out/blueprints.json [--sets A,B] [--all]

The head is the classic R6 head (preview_armor's drum, diameter 1.25). A point of the
head's skin CLIPS when it's outside every part of the piece but a part's outer surface
runs just under it (within DEPTH): the head shows through the cloth or the steel, the
look of a face pressed into a hood. Open faces (nothing under the skin) don't count.
Prints each piece's clipped share, by region (face, sides, top, back, chin), worst first.
"""
import bmesh, json, math, os, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
from parts2mesh import part_mesh  # noqa: E402
from preview_armor import HEAD_PROFILE  # noqa: E402

DEPTH = 0.3       # how far under the skin a part's surface still shows the head through it
ANGLES = 48


def samples():
    """points on the head's skin with their outward normals (Roblox axes: Y up, front -Z)"""
    out = []
    prof = HEAD_PROFILE
    for (r0, y0), (r1, y1) in zip(prof, prof[1:]):
        for t in (0.25, 0.75):
            r, y = r0 + (r1 - r0) * t, y0 + (y1 - y0) * t
            # the profile's normal in (r, y): perpendicular to the segment, pointing out
            dr, dy = r1 - r0, y1 - y0
            nr, ny = dy, -dr
            ln = math.hypot(nr, ny) or 1
            nr, ny = nr / ln, ny / ln
            if nr < 0 or (abs(nr) < 1e-6 and ny * y < 0):
                nr, ny = -nr, -ny
            if y < -0.48:   # (inside the torso: the head's foot never shows)
                continue
            steps = max(1, int(ANGLES * r / 0.625))
            for i in range(steps):
                a = 2 * math.pi * (i + 0.5) / steps
                c, s = math.cos(a), math.sin(a)
                out.append((Vector((r * c, y, r * s)), Vector((nr * c, ny, nr * s)).normalized()))
    return out


def region(p):
    if p.y > 0.55:
        return "top"
    if p.y < -0.55:
        return "chin"
    if p.z < -0.35 and abs(p.x) < 0.42:
        return "face"
    if p.z > 0.2:
        return "back"
    return "sides"


def trees(specs):
    """each part's own tree and bounds (for inside tests), and one tree of them all"""
    parts, allbm = [], bmesh.new()
    for s in specs:
        if s.get("n") == "Middle" or (s.get("t", 0) or 0) >= 1:
            continue
        bm = part_mesh(s)
        lo = Vector((min(v.co.x for v in bm.verts), min(v.co.y for v in bm.verts), min(v.co.z for v in bm.verts)))
        hi = Vector((max(v.co.x for v in bm.verts), max(v.co.y for v in bm.verts), max(v.co.z for v in bm.verts)))
        parts.append((s.get("n", "?"), BVHTree.FromBMesh(bm), lo, hi))
        vmap = {v: allbm.verts.new(v.co) for v in bm.verts}
        for f in bm.faces:
            try:
                allbm.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                pass
        bm.free()
    allbm.normal_update()
    return parts, BVHTree.FromBMesh(allbm)


RAYS = (Vector((0.31, 0.93, 0.17)).normalized(), Vector((-0.57, 0.12, 0.81)).normalized())


def inside(part, p):
    """odd crossings along two skew rays, both: inside that closed part"""
    _, tree, lo, hi = part
    if not (lo.x <= p.x <= hi.x and lo.y <= p.y <= hi.y and lo.z <= p.z <= hi.z):
        return False
    for d in RAYS:
        n, o = 0, p.copy()
        while n < 64:
            hit = tree.ray_cast(o, d)
            if hit[0] is None:
                break
            n += 1
            o = hit[0] + d * 1e-4
        if n % 2 == 0:
            return False
    return True


def audit(name, specs, pts):
    parts, whole = trees(specs)
    if not parts:
        return None
    tally = {}
    under = {}
    for p, n in pts:
        reg = region(p)
        t = tally.setdefault(reg, [0, 0])
        t[1] += 1
        if any(inside(pt, p) for pt in parts):
            continue
        hit = whole.ray_cast(p + n * 0.002, -n, DEPTH)
        if hit[0] is not None and hit[1].dot(n) > 0:   # an outer surface, facing the skin
            t[0] += 1
            # which part
            for pn, tr, _, _ in parts:
                h2 = tr.ray_cast(p + n * 0.002, -n, DEPTH)
                if h2[0] is not None and abs(h2[3] - hit[3]) < 1e-4:
                    under[pn] = under.get(pn, 0) + 1
                    break
    total = sum(v[0] for v in tally.values())
    n_all = sum(v[1] for v in tally.values())
    return total / max(1, n_all), tally, under


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    src = argv[0] if argv else os.path.join(ROOT, "blender", "out", "blueprints.json")
    want = None
    if "--sets" in argv:
        want = set(argv[argv.index("--sets") + 1].split(","))
    show_all = "--all" in argv
    data = json.load(open(src, encoding="utf-8"))
    items = []
    for group in ("sets", "pieces"):
        for name, slots in (data.get(group) or {}).items():
            if want and name not in want:
                continue
            specs = slots.get("HeadClothing")
            if specs:
                items.append((name, specs))
    pts = samples()
    rows = []
    for name, specs in items:
        r = audit(name, specs, pts)
        if r:
            rows.append((name,) + r)
    rows.sort(key=lambda r: -r[1])
    print("AUDIT %d head pieces, %d skin points" % (len(rows), len(pts)))
    for name, share, tally, under in rows:
        if share < 0.005 and not show_all:
            continue
        regs = "  ".join("%s %d/%d" % (k, v[0], v[1]) for k, v in sorted(tally.items()) if v[0])
        parts = ", ".join("%s %d" % kv for kv in sorted(under.items(), key=lambda kv: -kv[1])[:4])
        print("AUDIT %-22s %5.1f%%   %s   [%s]" % (name, share * 100, regs, parts))


main()
