"""Turn part blueprints (the Build ▸ Armor / Body spec lists, exported from
Studio as JSON) into smooth single meshes per color region, in Blender headless:

    blender.exe -b --python blender/parts2mesh.py -- blender/out/blueprints.json [--only RoadLevy,IronCrow] [--out dir]

Input JSON (scripts/export_blueprints.lua writes it):
  {"sets": {"RoadLevy": {"HeadClothing": [spec, …], …}, …},
   "pieces": {"WolfPeltHood": {"HeadClothing": [...]}, …},
   "body": {"Hair": {"Cropped": [...]}, "Beard": {...}, "Face": {...}}}
  spec = {k: box|cyl|ball|wedge|cwedge, n: name, s: [sx,sy,sz], cf: [12 CFrame components],
          c: [r,g,b], m: material, t: transparency, a: {ColorSlot=…, KeepColor=…, SkinPart=…}}
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


def box_mesh(sx, sy, sz, bevel):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sy, v.co.z * sz))
    b = min(bevel, sx * 0.3, sy * 0.3, sz * 0.3)
    if b > 0.004:
        bmesh.ops.bevel(bm, geom=list(bm.edges) + list(bm.verts), offset=b, segments=SEGS, profile=0.6, affect="EDGES")
    return bm


def cyl_mesh(sx, sy, sz):
    # Builder: a cylinder's axis is its X; size = (height, diameter, diameter)
    bm = bmesh.new()
    r1, r2, h = sy / 2, sz / 2, sx
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=18, radius1=max(r1, r2), radius2=max(r1, r2), depth=h)
    # create_cone is along Z: turn it onto X, squash to the ellipse
    rot = Matrix.Rotation(math.radians(90), 4, "Y")
    for v in bm.verts:
        v.co = rot @ v.co
        v.co = Vector((v.co.x, v.co.y * (r1 / max(r1, r2)), v.co.z * (r2 / max(r1, r2))))
    return bm


def ball_mesh(sx, sy, sz):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.5)
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
    elif k == "wedge":
        bm = wedge_mesh(sx, sy, sz)
    elif k == "cwedge":
        bm = wedge_mesh(sx, sy, sz, corner=True)
    else:
        bm = box_mesh(sx, sy, sz, BEVEL)
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
    for setName, slots in data.get("sets", {}).items():
        if only and setName not in only: continue
        for slot, specs in slots.items():
            jobs.append((f"{setName}/{slot}", specs, False))
    for pid, slots in data.get("pieces", {}).items():
        if only and pid not in only: continue
        for slot, specs in slots.items():
            jobs.append((f"Pieces/{pid}/{slot}", specs, False))
    for kind, items in data.get("body", {}).items():
        if only and kind not in only: continue
        for bid, specs in items.items():
            jobs.append((f"Body/{kind}/{bid}", specs, True))
    for name, specs, body in jobs:
        meta = build_model(name, specs, out_dir, body)
        print("WROTE", name, {r: m["tris"] for r, m in meta["regions"].items()})
