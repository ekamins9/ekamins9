"""EMBLEMS IN RELIEF — the shield emblems (Studio-only ReplicatedStorage ▸ ShieldArt, the art
the painted shields wore) as real raised meshes: each picture's silhouette traced, smoothed and
extruded with a rounded bevel, so a shield's lion is metal standing off the board, catching the
light, not a decal.

    blender.exe -b --python blender/emblems.py -- [--preview out.png] [names...]

Input: blender/out/forge/emblems/masks_*.txt (gitignored): one line per emblem,
`name=row,row,...`, 128 rows top to bottom, each row run lengths (two base-36 digits each)
alternating clear, solid, clear... (read out of Studio's EditableImage).
Output: blender/out/forge/emblems/<name>.fbx and <name>.json (its size), a unit emblem: the
picture's 1 × 1 square in X (right) and Y (up), the relief toward +Z (out of the board), ready
for scripts/upload_asset.py --type Model.
"""
import bpy, bmesh, math, os, sys, glob, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
import weapons as W  # noqa: E402

DIR = os.path.join(ROOT, "blender", "out", "forge", "emblems")
N = 128
DEPTH = 0.05      # how far it stands off the board (of the emblem's width)
BEVEL = 0.018     # the rounded edge
BUDGET = 14000    # triangles at most (a shield wears one; a crowd wears dozens)


def b36(s):
    return int(s, 36)


def load():
    out = {}
    for p in sorted(glob.glob(os.path.join(DIR, "masks_*.txt"))):
        for line in open(p, encoding="utf-8"):
            line = line.strip()
            if "=" not in line:
                continue
            name, data = line.split("=", 1)
            rows = data.split(",")
            if len(rows) != N:
                continue
            grid = []
            for r in rows:
                runs = [b36(r[i:i + 2]) for i in range(0, len(r), 2)]
                row, on = [], 0
                for n in runs:
                    row += [on] * n
                    on = 1 - on
                if len(row) != N:
                    break
                grid.append(row)
            if len(grid) == N:
                out[name] = grid
    return out


# --------------------------------------------------------------------------
#  tracing: marching squares on the pixel grid -> closed loops (pixel corners)
# --------------------------------------------------------------------------
def loops_of(grid):
    H, Wd = len(grid), len(grid[0])
    def g(x, y):
        return grid[y][x] if 0 <= x < Wd and 0 <= y < H else 0
    # directed boundary edges around every solid pixel (a corner where two pixels touch only
    # diagonally has two ways on: the walk takes the left turn, so each loop closes on itself)
    edges = {}
    def add(a, b):
        edges.setdefault(a, []).append(b)
    for y in range(-1, H + 1):
        for x in range(-1, Wd + 1):
            if not g(x, y):
                continue
            if not g(x, y - 1):
                add((x + 1, y), (x, y))
            if not g(x, y + 1):
                add((x, y + 1), (x + 1, y + 1))
            if not g(x - 1, y):
                add((x, y), (x, y + 1))
            if not g(x + 1, y):
                add((x + 1, y + 1), (x + 1, y))
    used = set()
    loops = []
    for start in list(edges.keys()):
        for first in edges[start]:
            if (start, first) in used:
                continue
            loop = [start]
            used.add((start, first))
            prev, p = start, first
            while p != start:
                loop.append(p)
                outs = [q for q in edges.get(p, []) if (p, q) not in used]
                if not outs:
                    break
                if len(outs) > 1:
                    dx, dy = p[0] - prev[0], p[1] - prev[1]
                    outs.sort(key=lambda q: -(dx * (q[1] - p[1]) - dy * (q[0] - p[0])))
                q = outs[0]
                used.add((p, q))
                prev, p = p, q
            if len(loop) >= 4:
                loops.append(loop)
    return loops


def simplify(pts, eps):
    """Douglas-Peucker on a closed loop"""
    if len(pts) < 8:
        return pts
    def rdp(seg):
        if len(seg) < 3:
            return seg
        (ax, ay), (bx, by) = seg[0], seg[-1]
        dx, dy = bx - ax, by - ay
        L = math.hypot(dx, dy) or 1e-9
        best, bi = -1, 0
        for i in range(1, len(seg) - 1):
            px, py = seg[i]
            d = abs(dy * px - dx * py + bx * ay - by * ax) / L
            if d > best:
                best, bi = d, i
        if best > eps:
            return rdp(seg[:bi + 1])[:-1] + rdp(seg[bi:])
        return [seg[0], seg[-1]]
    half = len(pts) // 2
    a = rdp(pts[:half + 1])
    b = rdp(pts[half:] + [pts[0]])
    return a[:-1] + b[:-1]


def chaikin(pts, it=2):
    for _ in range(it):
        out = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            out.append((0.75 * x0 + 0.25 * x1, 0.75 * y0 + 0.25 * y1))
            out.append((0.25 * x0 + 0.75 * x1, 0.25 * y0 + 0.75 * y1))
        pts = out
    return pts


def area(pts):
    return sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts))) / 2


# --------------------------------------------------------------------------
#  the relief: a filled 2D curve (holes and all), extruded and bevelled
# --------------------------------------------------------------------------
def sun_masks():
    """the sun's own: a disc ringed with sixteen rays, its face raised inside a groove"""
    lo, hi = [], []
    for y in range(N):
        rl, rh = [], []
        for x in range(N):
            u, v = (x + 0.5) / N - 0.5, 0.5 - (y + 0.5) / N
            r, a = math.hypot(u, v), math.atan2(v, u)
            k = (a / (2 * math.pi / 16)) % 1.0
            reach = 0.47 if int((a + math.pi) / (2 * math.pi / 16)) % 2 == 0 else 0.4
            ray = r < 0.27 + (reach - 0.27) * max(0.0, 1 - abs(k - 0.5) * 2) ** 0.9
            disc = r < 0.27
            rl.append(1 if (disc or ray) else 0)
            rh.append(1 if (r < 0.21 or (0.235 < r < 0.27) or (ray and r > 0.3)) else 0)
        lo.append(rl); hi.append(rh)
    return lo, hi


def layer(cu, grid):
    kept = 0
    for lp in loops_of(grid):
        pts = [(x / N - 0.5, 0.5 - y / N) for x, y in lp]
        if abs(area(pts)) < (1.5 / N) ** 2:
            continue   # (a stray pixel)
        pts = simplify(pts, 0.8 / N)
        if len(pts) < 3:
            continue
        pts = chaikin(pts, 1)
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for i, (x, y) in enumerate(pts):
            sp.points[i].co = (x, y, 0, 1)
        sp.use_cyclic_u = True
        kept += 1
    return kept


def slab(name, grid, depth, z0, bevel):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    cu.extrude = depth / 2
    cu.bevel_depth = bevel
    cu.bevel_resolution = 0
    cu.resolution_u = 1
    kept = layer(cu, grid)
    ob = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(ob)
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob = bpy.context.view_layer.objects.active
    for v in ob.data.vertices:
        v.co.z += z0 + depth / 2 + bevel
    return ob, kept


def finish(ob, budget):
    """one layer cleaned, its unseen back gone, flat faces merged, under its triangle budget"""
    for o in bpy.context.selected_objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    # (a bevel at a needle-sharp corner can throw a spike far out: anything off the art's
    # square goes)
    far = [v for v in bm.verts if abs(v.co.x) > 0.53 or abs(v.co.y) > 0.53]
    if far:
        bmesh.ops.delete(bm, geom=far, context="VERTS")
    # (its back lies on the board, never seen: gone, bevel and all)
    bm.normal_update()
    zmin = min((v.co.z for v in bm.verts), default=0)
    back = [f for f in bm.faces if f.normal.z < -0.3 and sum(v.co.z for v in f.verts) / len(f.verts) < zmin + BEVEL * 1.6]
    bmesh.ops.delete(bm, geom=back, context="FACES")
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    m = ob.modifiers.new("Flat", "DECIMATE")
    m.decimate_type = "DISSOLVE"
    m.angle_limit = math.radians(4)
    bpy.ops.object.modifier_apply(modifier=m.name)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="EAR_CLIP")
    bm.to_mesh(ob.data)
    bm.free()
    tris = len(ob.data.polygons)
    if tris > budget:
        m = ob.modifiers.new("Dec", "DECIMATE")
        m.ratio = budget / tris
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    ob.select_set(False)
    return ob


def relief(name, grid, hi=None):
    """the silhouette as a low slab (worn a shade darker), the bright parts raised above it (its
    lines cut in between): two meshes -> [(layer, object)], and how many outlines"""
    lo_d = DEPTH * (0.6 if hi else 1.0)
    base, kept = slab(name + "_lo", grid, lo_d, 0.0, BEVEL)
    out = [("lo", finish(base, BUDGET // 2))]
    if hi:
        top, k2 = slab(name + "_hi", hi, DEPTH - lo_d, lo_d + BEVEL * 0.6, BEVEL * 0.55)
        if k2:
            out.append(("hi", finish(top, BUDGET - BUDGET // 2)))
        else:
            bpy.data.objects.remove(top)
    return out, kept


def relief_old(name, grid):
    loops = loops_of(grid)
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    cu.extrude = DEPTH / 2
    cu.bevel_depth = BEVEL
    cu.bevel_resolution = 2
    cu.resolution_u = 1
    kept = 0
    for lp in loops:
        pts = [(x / N - 0.5, 0.5 - y / N) for x, y in lp]
        if abs(area(pts)) < (1.5 / N) ** 2:
            continue   # (a stray pixel)
        pts = simplify(pts, 0.55 / N)
        if len(pts) < 3:
            continue
        pts = chaikin(pts, 2)
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for i, (x, y) in enumerate(pts):
            sp.points[i].co = (x, y, 0, 1)
        sp.use_cyclic_u = True
        kept += 1
    ob = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob = bpy.context.view_layer.objects.active
    # (it stands on the board: its back at z = 0, the face out at +DEPTH)
    for v in ob.data.vertices:
        v.co.z += DEPTH / 2 + BEVEL
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    ob.select_set(False)
    return ob, kept


def main(names, png=None):
    masks = load()
    names = names or sorted(masks)
    os.makedirs(DIR, exist_ok=True)
    W.clear_scene()
    x = 0.0
    names = [n for n in names if not n.startswith("hi_")]
    for name in names:
        if name not in masks:
            print("NO MASK", name)
            continue
        if name == "sun":
            lo, hi = sun_masks()
        else:
            lo, hi = masks[name], masks.get("hi_" + name)
        layers, loops = relief(name, lo, hi)
        if png:
            for _, ob in layers:
                ob.location.x = x
            x += 1.2
            continue
        meta = {"name": name, "loops": loops, "layers": {}}
        for layer_name, ob in layers:
            p = os.path.join(DIR, "%s_%s.fbx" % (name, layer_name))
            W.export(ob, p)
            meta["layers"][layer_name] = {"tris": len(ob.data.polygons), "bounds": W.bounds(ob), "file": os.path.basename(p)}
            print("WROTE", p, len(ob.data.polygons), "tris")
            bpy.data.objects.remove(ob)
        json.dump(meta, open(os.path.join(DIR, name + ".json"), "w"), indent=1)
    if png:
        sc = bpy.context.scene
        sc.render.resolution_x, sc.render.resolution_y = int(260 * max(1, x / 1.2)), 300
        cd = bpy.data.cameras.new("Cam"); cd.type = "ORTHO"; cd.ortho_scale = max(1.3, x)
        cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
        cam.location = (x / 2 - 0.6, -0.9, 3)
        cam.rotation_euler = (math.radians(15), 0, 0)
        sc.render.engine = "BLENDER_WORKBENCH"
        sc.display.shading.light = "STUDIO"
        sc.display.shading.show_cavity = True
        sc.display.shading.show_specular_highlight = True
        sc.world = sc.world or bpy.data.worlds.new("W")
        sc.world.color = (0.11, 0.12, 0.15)
        sc.render.filepath = os.path.abspath(png)
        bpy.ops.render.render(write_still=True)
        print("RENDERED", png)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    png = None
    if "--preview" in argv:
        i = argv.index("--preview"); png = argv[i + 1]; del argv[i:i + 2]
    main(argv, png)
