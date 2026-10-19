"""DIVISIONS IN RELIEF — a shield's field split in a second colour (per pale, quarterly, a bordure…)
as a thin raised inlay clipped to the board's outline, instead of a painted picture: one mesh per
board shape and division (blender/emblems.py's tracing, a shallow slab).

    blender.exe -b --python blender/divisions.py -- [--preview out.png] [shape:division ...]

The frame is the outline's box, normalized: x and y from -0.5 to 0.5 (right, up), the inlay
toward +Z; ShieldPaint stretches it to the board's box. Output:
blender/out/forge/divisions/div_<shape>_<division>.fbx and .json (its middle and size in the box).
The outlines are ReplicatedStorage ▸ ShieldDress.outline's (the round board: a circle).
"""
import bpy, math, os, sys, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
import weapons as W  # noqa: E402
import emblems as E  # noqa: E402
E.SMOOTH = 0   # (a division's corners stay sharp)

OUT = os.path.join(ROOT, "blender", "out", "forge", "divisions")
N = 128
DEPTH = 0.022   # studs proud of the board (the slab isn't stretched in depth)

OUTLINES = {
    "heater": [(-1.15, 1.28), (1.15, 1.28), (1.15, -0.25), (0.0, -1.4), (-1.15, -0.25)],
    "kite": [(1.1, 0.65), (1.016, 1.071), (0.778, 1.428), (0.421, 1.666), (0.0, 1.75), (-0.421, 1.666), (-0.778, 1.428),
             (-1.016, 1.071), (-1.1, 0.65), (-1.1, -0.6), (0.0, -2.1), (1.1, -0.6)],
    "scutum": [(-0.65, 1.8), (0.65, 1.8), (0.65, -1.8), (-0.65, -1.8)],
    "rect": [(-1.25, 2.0), (1.25, 2.0), (1.25, -2.0), (-1.25, -2.0)],
    "round": None,
}
DIVISIONS = ["pale", "fess", "quarterly", "bend", "saltire", "chevron", "gyronny", "paly", "barry", "checky",
             "chief", "bordure", "pile", "cross"]


def normalized(poly):
    xs, ys = [p[0] for p in poly], [p[1] for p in poly]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    return [((x - x0) / (x1 - x0) - 0.5, (y - y0) / (y1 - y0) - 0.5) for x, y in poly], (x1 - x0, y1 - y0)


def inside(poly, u, v):
    if poly is None:
        return math.hypot(u, v) < 0.5
    c = False
    n = len(poly)
    for i in range(n):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
        if (y0 > v) != (y1 > v) and u < (x1 - x0) * (v - y0) / (y1 - y0) + x0:
            c = not c
    return c


def edge_dist(poly, u, v, aspect):
    """distance to the outline, in the box's height units (x stretched by the aspect)"""
    if poly is None:
        return 0.5 - math.hypot(u, v)
    best = 9
    n = len(poly)
    for i in range(n):
        (ax, ay), (bx, by) = poly[i], poly[(i + 1) % n]
        ax, bx, uu = ax * aspect, bx * aspect, u * aspect
        dx, dy = bx - ax, by - ay
        L = dx * dx + dy * dy or 1e-9
        t = max(0.0, min(1.0, ((uu - ax) * dx + (v - ay) * dy) / L))
        best = min(best, math.hypot(uu - (ax + t * dx), v - (ay + t * dy)))
    return best


def second(div, u, v, poly, aspect):
    """is (u, v) in the second colour?"""
    if div == "pale":
        return u > 0
    if div == "fess":
        return v < 0
    if div == "quarterly":
        return (u > 0) == (v > 0)
    if div == "bend":
        return abs(u + v) / math.sqrt(2) < 0.12
    if div == "saltire":
        return abs(u + v) / math.sqrt(2) < 0.1 or abs(u - v) / math.sqrt(2) < 0.1
    if div == "chevron":
        f = 0.16 - 0.95 * abs(u)
        return f - 0.17 < v < f
    if div == "gyronny":
        a = math.atan2(v, u)
        return int((a + math.pi) / (math.pi / 4)) % 2 == 1
    if div == "paly":
        return int((u + 0.5) * 6) % 2 == 1
    if div == "barry":
        return int((v + 0.5) * 8) % 2 == 1
    if div == "checky":
        return (int((u + 0.5) * 6) + int((v + 0.5) * 7)) % 2 == 1
    if div == "chief":
        return v > 0.2
    if div == "bordure":
        return edge_dist(poly, u, v, aspect) < 0.075
    if div == "pile":
        return v > -0.36 and abs(u) < 0.34 * (v + 0.36) / 0.86
    if div == "cross":
        return abs(u) < 0.09 or abs(v - 0.06) < 0.09
    return False


def mask(shape, div):
    poly = OUTLINES[shape]
    npoly, (bw, bh) = normalized(poly) if poly else (None, (1, 1))
    aspect = bw / bh
    grid = []
    for y in range(N):
        row = []
        for x in range(N):
            u, v = (x + 0.5) / N - 0.5, 0.5 - (y + 0.5) / N
            row.append(1 if inside(npoly, u, v) and second(div, u, v, npoly, aspect) else 0)
        grid.append(row)
    return grid


def build(shape, div):
    grid = mask(shape, div)
    if not any(any(r) for r in grid):
        return None
    ob, kept = E.slab("div_%s_%s" % (shape, div), grid, DEPTH * 0.6, 0.0, DEPTH * 0.2)
    return E.finish(ob, 4000)


def main(jobs, png=None):
    os.makedirs(OUT, exist_ok=True)
    W.clear_scene()
    x = 0.0
    for shape, div in jobs:
        ob = build(shape, div)
        if ob is None:
            print("EMPTY", shape, div)
            continue
        if png:
            ob.location.x = x
            x += 1.2
            continue
        p = os.path.join(OUT, "div_%s_%s.fbx" % (shape, div))
        W.export(ob, p)
        json.dump({"shape": shape, "division": div, "tris": len(ob.data.polygons), "bounds": W.bounds(ob)},
                  open(os.path.join(OUT, "div_%s_%s.json" % (shape, div)), "w"), indent=1)
        print("WROTE", p, len(ob.data.polygons))
        bpy.data.objects.remove(ob)
    if png:
        sc = bpy.context.scene
        sc.render.resolution_x, sc.render.resolution_y = int(200 * max(1, x / 1.2)), 260
        cd = bpy.data.cameras.new("Cam"); cd.type = "ORTHO"; cd.ortho_scale = max(1.3, x)
        cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
        cam.location = (x / 2 - 0.6, -0.6, 3)
        cam.rotation_euler = (math.radians(10), 0, 0)
        sc.render.engine = "BLENDER_WORKBENCH"
        sc.display.shading.light = "STUDIO"
        sc.display.shading.show_cavity = True
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
    jobs = [tuple(a.split(":")) for a in argv] or [(s, d) for s in OUTLINES for d in DIVISIONS]
    main(jobs, png)
