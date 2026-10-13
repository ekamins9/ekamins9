"""Turn part blueprints (the Build ▸ Armor / Body spec lists, exported from
Studio as JSON) into smooth single meshes per color region, in Blender headless:

    blender.exe -b --python blender/parts2mesh.py -- blender/out/blueprints.json [--only RoadLevy,IronCrow] [--out dir]

Input JSON (scripts/export_blueprints.lua writes it):
  {"sets": {"RoadLevy": {"HeadClothing": [spec, …], …}, …},
   "pieces": {"WolfPeltHood": {"HeadClothing": [...]}, …},
   "body": {"Hair": {"Cropped": [...]}, "Beard": {...}, "Face": {...}}}
  spec = {k: box|cyl|ball|wedge|cwedge|cone, n: name, s: [sx,sy,sz], cf: [12 CFrame components],
          c: [r,g,b], m: material, t: transparency, a: {ColorSlot=…, KeepColor=…, SkinPart=…},
          tp: a cone's (or a box's) top width as a share of its foot (0 = a point), bv: a box's bevel}
  k = torus: a ring in the spec's XZ plane, s = (outer width, tube thickness, outer depth).
  k = lathe: pf = [[radius, y], …] spun round the spec's Y (cf sits at the middle of its y range).
  k = cowl: a hollow egg (s = its outside), wall th deep, open at its front (-Z) ox × oy degrees
         round from the front: a hood the head sits in.
  Specs are in the LIMB frame (Middle = the limb box at the origin), studs.

Output per model (e.g. RoadLevy/HeadClothing): one FBX per REGION, where a
region is a ColorSlot (Primary / Secondary / Accent / Metal), "Hair" (parts
without KeepColor in Body models — the Dresser tints them with the hair color)
or "Fixed" (everything else, painted by vertex color). Each region's bounding
centre (the weld offset from Middle) goes into <Model>.json beside the FBXs.
Boxes get a small bevel, cylinders / balls are proper round solids, so the
result reads as one sculpted piece instead of a stack of parts.
"""
import bpy, bmesh, json, math, os, sys
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEVEL = 0.035       # studs: rounds every box edge
SEGS = 2

sys.path.insert(0, os.path.join(ROOT, "blender"))
from weapons import export, paint, merge, clear_scene  # noqa: E402


def cframe(cf):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    return Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))


def segs(d, big, mid, small):
    """fewer facets for small parts: rivets and studs don't need 24 sides"""
    return big if d >= 0.3 else (mid if d >= 0.12 else small)


def box_mesh(sx, sy, sz, bevel, top=None):
    """a box; `top` narrows (or widens) its top face to that share of the bottom's
    width and depth (a skirt, a fauld, a breastplate drawn in at the waist)"""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        k = (top if v.co.y > 0 else 1.0) if top else 1.0
        v.co = Vector((v.co.x * sx * k, v.co.y * sy, v.co.z * sz * k))
    b = min(bevel, sx * 0.45, sy * 0.45, sz * 0.45)
    if b > 0.004:
        bmesh.ops.bevel(bm, geom=list(bm.edges) + list(bm.verts), offset=b, segments=SEGS if b < 0.08 else 4,
                        profile=0.6 if b < 0.08 else 0.5, affect="EDGES")
    return bm


def cyl_mesh(sx, sy, sz):
    """a Build blueprint cylinder: its axis is the spec's local Y and its size
    is (diameter along X, height, diameter along Z), as B.cyl in Builder.lua"""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs(max(sx, sz), 24, 12, 8), radius1=0.5, radius2=0.5, depth=1.0)
    # create_cone runs along Z: stand it up along Y, then scale to the spec
    rot = Matrix.Rotation(math.radians(-90), 4, "X")
    for v in bm.verts:
        p = rot @ v.co
        v.co = Vector((p.x * sx, p.y * sy, p.z * sz))
    return bm


def cone_mesh(sx, sy, sz, top=0.0):
    """a cone standing along the spec's local Y, its point (or its narrower top,
    `top` × the foot's width) at +Y; size as a cylinder's"""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs(max(sx, sz), 24, 12, 8), radius1=0.5,
                          radius2=0.5 * max(0.0, top), depth=1.0)
    rot = Matrix.Rotation(math.radians(-90), 4, "X")
    for v in bm.verts:
        p = rot @ v.co
        v.co = Vector((p.x * sx, p.y * sy, p.z * sz))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    return bm


def torus_mesh(sx, sy, sz):
    """a ring in the XZ plane: outer extents sx × sz, tube thickness sy"""
    bm = bmesh.new()
    r = sy / 2
    rx, rz = max(sx / 2 - r, 0.001), max(sz / 2 - r, 0.001)
    nu, nv = segs(max(sx, sz), 28, 16, 10), (8 if sy >= 0.06 else 6)
    rings = []
    for i in range(nu):
        t = 2 * math.pi * i / nu
        rings.append([bm.verts.new(((rx + r * math.cos(2 * math.pi * j / nv)) * math.cos(t), r * math.sin(2 * math.pi * j / nv),
                                    (rz + r * math.cos(2 * math.pi * j / nv)) * math.sin(t))) for j in range(nv)])
    for i in range(nu):
        a, b = rings[i], rings[(i + 1) % nu]
        for j in range(nv):
            bm.faces.new((a[j], b[j], b[(j + 1) % nv], a[(j + 1) % nv]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def lathe_mesh(profile, sy):
    """a solid of revolution round Y; profile y values are about the spec's origin
    (Builder.lathe moved the frame to the middle of the y range)"""
    ys = [p[1] for p in profile]
    mid = (min(ys) + max(ys)) / 2
    n = segs(2 * max(p[0] for p in profile), 28, 14, 8)
    bm = bmesh.new()
    rings = []
    for r, y in profile:
        r = max(r, 0.002)
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / n), y - mid, r * math.sin(2 * math.pi * k / n))) for k in range(n)])
    for a, b in zip(rings, rings[1:]):
        for k in range(n):
            bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    bm.faces.new(tuple(reversed(rings[0])))
    bm.faces.new(tuple(rings[-1]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def cowl_mesh(sx, sy, sz, ox, oy, th):
    """a hood's shell: an egg's skin `th` thick with an opening at its front (-Z), an
    ellipse ox degrees round from the front across and oy up and down. Closed (outer
    skin, inner skin, the lip between) so it shades from inside and out."""
    bm = bmesh.new()
    rx, ry, rz = sx / 2, sy / 2, sz / 2
    ix, iy, iz = max(rx - th, 0.05), max(ry - th, 0.05), max(rz - th, 0.05)
    nphi, nth = 40, 18
    ox, oy = math.radians(ox), math.radians(oy)

    def edge(phi):   # the opening's angle from the front, round the ellipse
        c, s = math.cos(phi), math.sin(phi)
        return 1 / math.sqrt((c / ox) ** 2 + (s / oy) ** 2)

    def ring(i, r3):
        out = []
        for j in range(nphi):
            phi = 2 * math.pi * j / nphi
            t0 = edge(phi)
            th_ = t0 + (math.pi - t0) * i / nth
            d = (math.sin(th_) * math.cos(phi), math.sin(th_) * math.sin(phi), -math.cos(th_))
            out.append(bm.verts.new((r3[0] * d[0], r3[1] * d[1], r3[2] * d[2])))
        return out
    outer = [ring(i, (rx, ry, rz)) for i in range(nth)]
    inner = [ring(i, (ix, iy, iz)) for i in range(nth)]
    back_o = bm.verts.new((0, 0, rz))
    back_i = bm.verts.new((0, 0, iz))
    for rings, back in ((outer, back_o), (inner, back_i)):
        for a, b in zip(rings, rings[1:]):
            for j in range(nphi):
                k = (j + 1) % nphi
                bm.faces.new((a[j], a[k], b[k], b[j]))
        last = rings[-1]
        for j in range(nphi):
            bm.faces.new((last[j], last[(j + 1) % nphi], back))
    for j in range(nphi):   # the lip round the opening
        k = (j + 1) % nphi
        bm.faces.new((outer[0][j], inner[0][j], inner[0][k], outer[0][k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def ball_mesh(sx, sy, sz):
    bm = bmesh.new()
    d = max(sx, sy, sz)
    u, v = (24, 14) if d >= 0.8 else (16, 10) if d >= 0.3 else ((10, 6) if d >= 0.12 else (6, 4))
    if min(sx, sy, sz) < 0.1 and d < 0.8:   # flat leaves (feathers, dags, splashes) need few facets
        u, v = min(u, 12), min(v, 6)
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=0.5)
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sy, v.co.z * sz))
    return bm


def wedge_mesh(sx, sy, sz, corner=False):
    """Roblox WedgePart: the slope rises toward +Z... (top edge at +Y along the
    -Z side: the triangle in the YZ plane has the right angle at (-Y, -Z)...).
    Roblox: a WedgePart's vertical face is at the back (+Z) and the slope faces
    -Z and up. CornerWedge: a pyramid-ish corner with the apex at (+X? ) — kept
    as a right wedge over the +X,+Z corner."""
    bm = bmesh.new()
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    if not corner:
        a = bm.verts.new((-hx, -hy, -hz)); b = bm.verts.new((hx, -hy, -hz))
        c = bm.verts.new((hx, -hy, hz)); d = bm.verts.new((-hx, -hy, hz))
        e = bm.verts.new((-hx, hy, hz)); f = bm.verts.new((hx, hy, hz))
        for face in ((a, b, c, d), (d, c, f, e), (a, d, e), (b, f, c), (a, e, f, b)):
            bm.faces.new(face)
    else:
        a = bm.verts.new((-hx, -hy, -hz)); b = bm.verts.new((hx, -hy, -hz))
        c = bm.verts.new((hx, -hy, hz)); d = bm.verts.new((-hx, -hy, hz))
        apex = bm.verts.new((hx, hy, hz))
        for face in ((a, b, c, d), (a, apex, b), (b, apex, c), (c, apex, d), (d, apex, a)):
            bm.faces.new(face)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def part_mesh(spec):
    k = spec.get("k", "box")
    sx, sy, sz = spec["s"]
    if k == "cyl":
        bm = cyl_mesh(sx, sy, sz)
    elif k == "ball":
        bm = ball_mesh(sx, sy, sz)
    elif k == "cone":
        bm = cone_mesh(sx, sy, sz, spec.get("tp") or 0.0)
    elif k == "torus":
        bm = torus_mesh(sx, sy, sz)
    elif k == "lathe":
        bm = lathe_mesh(spec["pf"], sy)
    elif k == "cowl":
        bm = cowl_mesh(sx, sy, sz, spec.get("ox") or 40, spec.get("oy") or 35, spec.get("th") or 0.07)
    elif k == "wedge":
        bm = wedge_mesh(sx, sy, sz)
    elif k == "cwedge":
        bm = wedge_mesh(sx, sy, sz, corner=True)
    else:
        bm = box_mesh(sx, sy, sz, spec.get("bv") or BEVEL, spec.get("tp"))
    m = cframe(spec["cf"])
    for v in bm.verts:
        v.co = m @ v.co
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # tinted regions (ColorSlot / hair) are painted white so the Dresser's
    # Color becomes the colour; fixed parts keep their own vertex colour
    a = spec.get("a") or {}
    tinted = a.get("ColorSlot") or (spec.get("_body") and not a.get("KeepColor"))
    paint(bm, (1, 1, 1) if tinted else tuple(spec.get("c", (0.8, 0.8, 0.8))))
    return bm


def region_of(spec, body_model):
    a = spec.get("a") or {}
    if a.get("ColorSlot"):
        return a["ColorSlot"]
    if body_model and not a.get("KeepColor"):
        return "Hair"
    return "Fixed"


def build_model(name, specs, out_dir, body_model=False):
    """specs → one FBX per region; returns the json meta"""
    regions = {}
    for s in specs:
        if s.get("n") == "Middle" or (s.get("t", 0) or 0) >= 1:
            continue
        s["_body"] = body_model
        regions.setdefault(region_of(s, body_model), []).append(s)
    meta = {"model": name, "regions": {}}
    safe = name.replace("/", "_")
    for region, parts in regions.items():
        clear_scene()
        bm = merge(*[part_mesh(s) for s in parts])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        me = bpy.data.meshes.new(safe + "_" + region)
        bm.to_mesh(me); bm.free(); me.validate()
        ob = bpy.data.objects.new(me.name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.select_set(True); bpy.context.view_layer.objects.active = ob
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
        xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
        center = [(min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2]
        size = [max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)]
        fname = f"{safe}_{region}.fbx"
        export(ob, os.path.join(out_dir, fname))
        # the material / transparency hint: most common among the parts
        mats = {}
        for s in parts:
            mats[s.get("m", "SmoothPlastic")] = mats.get(s.get("m", "SmoothPlastic"), 0) + 1
        meta["regions"][region] = {"file": fname, "center": center, "size": size, "tris": len(me.polygons),
                                   "material": max(mats, key=mats.get), "color": parts[0].get("c")}
    with open(os.path.join(out_dir, safe + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    return meta


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    src = argv[0]
    out_dir = os.path.join(ROOT, "blender", "out", "armor")
    only = None
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]
    if "--only" in argv:
        i = argv.index("--only"); only = set(argv[i + 1].split(","))
    os.makedirs(out_dir, exist_ok=True)
    data = json.load(open(src, encoding="utf-8"))
    jobs = []   # (model name, specs, is_body)
    # --only takes set names / piece ids / body kinds, or whole model paths
    # ("Sellswords/HeadClothing", "Pieces/BloodiedKettle/HeadClothing")
    def wanted(group, path):
        return not only or group in only or path in only
    for setName, slots in data.get("sets", {}).items():
        for slot, specs in slots.items():
            if wanted(setName, f"{setName}/{slot}"): jobs.append((f"{setName}/{slot}", specs, False))
    for pid, slots in data.get("pieces", {}).items():
        for slot, specs in slots.items():
            if wanted(pid, f"Pieces/{pid}/{slot}"): jobs.append((f"Pieces/{pid}/{slot}", specs, False))
    for kind, items in data.get("body", {}).items():
        for bid, specs in items.items():
            if wanted(kind, f"Body/{kind}/{bid}"): jobs.append((f"Body/{kind}/{bid}", specs, True))
    for name, specs, body in jobs:
        meta = build_model(name, specs, out_dir, body)
        print("WROTE", name, {r: m["tris"] for r, m in meta["regions"].items()})
