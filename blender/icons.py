"""Shop icons, rendered in Blender headless with Cycles + a Freestyle ink
outline (the bright, outlined look of the menu):

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python blender/icons.py -- [names...] [--out dir]

names (default: all):
  crowns_100 / crowns_550 / crowns_1200 / crowns_2600   Robux bundle art (Developer Product images)
  icon_crowns                                           the Crowns currency mark (a crown)
  icon_marks                                            the Marks currency mark (a stack of gold coins)
Output: 512x512 RGBA PNGs in blender/out/icons/ (or --out).
"""
import bpy, bmesh, math, os, random, sys
from mathutils import Vector, Matrix

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "icons")

GOLD = (1.0, 0.70, 0.16)
GOLD_DARK = (0.80, 0.45, 0.06)
VELVET = (0.05, 0.10, 0.55)
GEM_BLUE = (0.22, 0.62, 1.0)
GEM_RED = (0.95, 0.10, 0.16)
INK = (0.03, 0.05, 0.13)


# ---------------------------------------------------------------- scene
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 64
    try:
        sc.cycles.use_denoising = True
    except Exception:
        pass
    sc.render.resolution_x = sc.render.resolution_y = 512
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    # world: a soft cool ambient
    w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.35, 0.42, 0.62, 1); bg.inputs["Strength"].default_value = 0.4
    # ink outline
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    vl = sc.view_layers[0]
    vl.use_freestyle = True
    fs = vl.freestyle_settings
    fs.crease_angle = math.radians(130)
    ls = fs.linesets[0] if len(fs.linesets) else fs.linesets.new("Ink")
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True; ls.select_border = True; ls.select_crease = True
    if ls.linestyle is None:   # an empty scene's lineset has no style yet
        ls.linestyle = bpy.data.linestyles.new("Ink")
    ls.linestyle.color = INK
    ls.linestyle.thickness = 4.0
    return sc


def light(name, loc, energy, size, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, "AREA"); l.energy = energy; l.size = size; l.color = color
    o = bpy.data.objects.new(name, l); bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector((0, 0, 0.6)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return o


def material(name, color, metallic=0.0, rough=0.4, emit=0.0, coat=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    def put(key, val):
        if key in b.inputs:
            b.inputs[key].default_value = val
    put("Base Color", (*color, 1)); put("Metallic", metallic); put("Roughness", rough)
    if emit > 0:
        put("Emission Color", (*color, 1)); put("Emission Strength", emit)
    if coat > 0:
        put("Coat Weight", coat)
    return m


def link(obj, mat, smooth=True):
    bpy.context.scene.collection.objects.link(obj) if obj.name not in bpy.context.scene.collection.objects else None
    obj.data.materials.clear(); obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth = smooth
    return obj


def mesh_obj(name, bm):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    return o


# ---------------------------------------------------------------- shapes
def gem(name, loc, r, mat, rot=(0, 0, 0)):
    """a brilliant-cut gem: table on top, crown, girdle, pavilion to a point"""
    bm = bmesh.new()
    n = 8
    girdle = [bm.verts.new((r * math.cos(2 * math.pi * i / n), r * math.sin(2 * math.pi * i / n), 0)) for i in range(n)]
    table = [bm.verts.new((0.58 * r * math.cos(2 * math.pi * (i + 0.5) / n), 0.58 * r * math.sin(2 * math.pi * (i + 0.5) / n), 0.32 * r)) for i in range(n)]
    culet = bm.verts.new((0, 0, -0.85 * r))
    bm.faces.new(table)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((girdle[i], girdle[j], table[i]))
        bm.faces.new((table[i], girdle[j], table[j]))
        bm.faces.new((girdle[j], girdle[i], culet))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = mesh_obj(name, bm)
    o.location = loc; o.rotation_euler = rot
    return link(o, mat, smooth=False)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    return o


def coin(name, loc, r, mat, rot=(0, 0, 0)):
    """a gold coin: beveled body, a raised rim ring and a boss on both faces"""
    t = 0.16 * r
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=r, depth=t, location=(0, 0, 0))
    body = bpy.context.active_object
    bv = body.modifiers.new("Bevel", "BEVEL"); bv.width = 0.04 * r; bv.segments = 3
    bpy.ops.object.modifier_apply(modifier="Bevel")
    parts = [body]
    for z in (t / 2, -t / 2):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.78 * r, minor_radius=0.05 * r, major_segments=40, minor_segments=8, location=(0, 0, z))
        parts.append(bpy.context.active_object)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.34 * r, depth=t + 0.07 * r, location=(0, 0, 0))
    boss = bpy.context.active_object
    bv = boss.modifiers.new("Bevel", "BEVEL"); bv.width = 0.03 * r; bv.segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")
    parts.append(boss)
    o = join(parts, name)
    link(o, mat)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    o.location = loc
    o.rotation_euler = rot
    return o


def crown(loc, scale, gold, velvet, gem_blue, gem_red):
    objs = []
    # the band: an open cylinder thickened outward, softened
    bpy.ops.mesh.primitive_cylinder_add(vertices=56, radius=1.0 * scale, depth=0.5 * scale, end_fill_type="NOTHING",
                                        location=(loc[0], loc[1], loc[2] + 0.25 * scale))
    band = bpy.context.active_object; band.name = "Band"
    so = band.modifiers.new("Solid", "SOLIDIFY"); so.thickness = 0.14 * scale; so.offset = 1
    bv = band.modifiers.new("Bevel", "BEVEL"); bv.width = 0.03 * scale; bv.segments = 3
    link(band, gold); objs.append(band)
    # a rim ring at the bottom and the top of the band
    for z in (0.02, 0.48):
        bpy.ops.mesh.primitive_torus_add(major_radius=1.05 * scale, minor_radius=0.06 * scale, major_segments=56, minor_segments=10,
                                         location=(loc[0], loc[1], loc[2] + z * scale))
        t = bpy.context.active_object; link(t, gold); objs.append(t)
    # five points with a ball on each
    for i in range(5):
        a = 2 * math.pi * i / 5 - math.pi / 2   # i = 0 at the front (-Y, toward the camera)
        x, y = math.cos(a) * 1.0 * scale, math.sin(a) * 1.0 * scale
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.36 * scale, radius2=0.0, depth=0.85 * scale,
                                        location=(loc[0] + x, loc[1] + y, loc[2] + (0.5 + 0.40) * scale))
        c = bpy.context.active_object
        c.rotation_euler = (0, 0, a + math.pi / 4)
        c.scale = (1, 0.55, 1)
        bv = c.modifiers.new("Bevel", "BEVEL"); bv.width = 0.03 * scale; bv.segments = 2
        link(c, gold); objs.append(c)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.14 * scale, location=(loc[0] + x * 1.0, loc[1] + y * 1.0, loc[2] + 1.36 * scale))
        s = bpy.context.active_object; link(s, gold); objs.append(s)
        # a gem on the band under each point
        g = gem(f"BandGem{i}", (loc[0] + x * 1.13, loc[1] + y * 1.13, loc[2] + 0.25 * scale), 0.17 * scale,
                gem_red if i == 0 else gem_blue, rot=(math.pi / 2, 0, a + math.pi / 2))
        objs.append(g)
    # the velvet cap inside
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.93 * scale, location=(loc[0], loc[1], loc[2] + 0.35 * scale), segments=40, ring_count=20)
    cap = bpy.context.active_object; cap.scale = (1, 1, 0.75); link(cap, velvet); objs.append(cap)
    # an orb and a cross on top of the cap
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.2 * scale, location=(loc[0], loc[1], loc[2] + 1.12 * scale))
    orb = bpy.context.active_object; link(orb, gold); objs.append(orb)
    # the cross: one plus-shaped solid (two overlapping boxes leave outline seams)
    w, a = 0.14, 0.21
    outline = [(-w / 2, -0.18), (w / 2, -0.18), (w / 2, 0.08), (a, 0.08), (a, 0.22), (w / 2, 0.22),
               (w / 2, 0.38), (-w / 2, 0.38), (-w / 2, 0.22), (-a, 0.22), (-a, 0.08), (-w / 2, 0.08)]
    bm = bmesh.new()
    face = bm.faces.new([bm.verts.new((x * scale, -0.07 * scale, z * scale)) for x, z in outline])
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    bmesh.ops.translate(bm, vec=(0, 0.14 * scale, 0), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    cross = mesh_obj("Cross", bm)
    cross.location = (loc[0], loc[1], loc[2] + 1.42 * scale)
    bv = cross.modifiers.new("Bevel", "BEVEL"); bv.width = 0.02 * scale; bv.segments = 2
    link(cross, gold, smooth=False); objs.append(cross)
    for o in objs:
        if o.type == "MESH" and o.data.materials and o.data.materials[0] in (gold, velvet):
            bpy.context.view_layer.objects.active = o
            o.select_set(True)
            try:
                bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
            except Exception:
                pass
            o.select_set(False)
    return objs


def pile(center, radius, height, n_gems, n_coins, mats, seed):
    """a treasure mound: a gold heap with coins laid on its surface and gems set into it"""
    rnd = random.Random(seed)
    objs = []
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=48, ring_count=24, location=center)
    heap = bpy.context.active_object; heap.name = "Heap"
    heap.scale = (radius, radius, max(height, 0.05))
    link(heap, mats["heap"])
    bpy.ops.object.shade_smooth()
    objs.append(heap)

    def surface(edge=1.0):
        a = rnd.uniform(0, 2 * math.pi)
        r = radius * edge * math.sqrt(rnd.uniform(0, 1))
        x, y = math.cos(a) * r, math.sin(a) * r
        z = max(height, 0.05) * math.sqrt(max(0.0, 1 - (r / radius) ** 2))
        n = Vector((x / radius ** 2, y / radius ** 2, z / max(height, 0.05) ** 2)).normalized()
        return Vector((center[0] + x, center[1] + y, center[2] + z)), n

    for i in range(n_coins):
        p, n = surface(0.97)
        cr = rnd.uniform(0.24, 0.32)
        q = n.to_track_quat("Z", "Y")
        tilt = Matrix.Rotation(rnd.uniform(-0.35, 0.35), 4, "X") @ Matrix.Rotation(rnd.uniform(-0.35, 0.35), 4, "Y")
        rot = (q.to_matrix().to_4x4() @ tilt).to_euler()
        objs.append(coin(f"PileCoin{i}", p + n * 0.02, cr, mats["gold"], rot=rot))
    for i in range(n_gems):
        p, n = surface(0.9)
        size = rnd.uniform(0.2, 0.3)
        m = mats["gem_red"] if rnd.random() < 0.2 else mats["gem_blue"]
        objs.append(gem(f"PileGem{i}", tuple(p + n * size * 0.35), size, m,
                        rot=(rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), rnd.uniform(0, 6.28))))
    return objs


# ---------------------------------------------------------------- framing + render
def frame_and_render(path, objs, elev=0.42, azim=-0.55, pad=0.9):
    sc = bpy.context.scene
    bpy.context.view_layer.update()
    pts = []
    for o in objs:
        if o.type == "MESH":
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    radius = max((p - center).length for p in pts)
    cam_data = bpy.data.cameras.new("Cam"); cam_data.lens = 70
    cam = bpy.data.objects.new("Cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
    fov = cam_data.angle
    dist = radius / math.sin(fov / 2) * pad
    d = Vector((math.cos(elev) * math.sin(azim), -math.cos(elev) * math.cos(azim), math.sin(elev)))
    cam.location = center + d * dist
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    # lights around the subject
    light("Key", center + Vector((-3.5, -4.0, 5.0)) * (radius / 1.6), 900 * (radius / 1.6) ** 2, 4 * radius / 1.6, (1.0, 0.95, 0.88))
    light("Fill", center + Vector((4.5, -2.5, 1.5)) * (radius / 1.6), 350 * (radius / 1.6) ** 2, 5 * radius / 1.6, (0.75, 0.85, 1.0))
    light("Rim", center + Vector((0.5, 5.0, 4.0)) * (radius / 1.6), 700 * (radius / 1.6) ** 2, 3 * radius / 1.6, (1.0, 1.0, 1.0))
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


def mats():
    return {
        "gold": material("Gold", GOLD, metallic=1.0, rough=0.3),
        "heap": material("Heap", GOLD_DARK, metallic=1.0, rough=0.5),
        "velvet": material("Velvet", VELVET, rough=0.7),
        "gem_blue": material("GemBlue", GEM_BLUE, rough=0.05, emit=0.35, coat=1.0),
        "gem_red": material("GemRed", GEM_RED, rough=0.05, emit=0.3, coat=1.0),
    }


def build(name, out_dir):
    reset()
    m = mats()
    path = os.path.join(out_dir, name + ".png")
    if name == "icon_crowns" or name == "crowns_100":
        objs = crown((0, 0, 0), 1.0, m["gold"], m["velvet"], m["gem_blue"], m["gem_red"])
        frame_and_render(path, objs, pad=0.8 if name == "icon_crowns" else 0.9)
    elif name == "crowns_550":
        objs = pile((0, 0, 0), 1.45, 0.28, 6, 16, m, 550)
        objs += crown((0, 0.05, 0.18), 0.85, m["gold"], m["velvet"], m["gem_blue"], m["gem_red"])
        frame_and_render(path, objs)
    elif name == "crowns_1200":
        objs = pile((0, 0, 0), 1.6, 0.55, 12, 34, m, 1200)
        objs += crown((0, 0.05, 0.42), 0.82, m["gold"], m["velvet"], m["gem_blue"], m["gem_red"])
        frame_and_render(path, objs)
    elif name == "crowns_2600":
        objs = pile((0, 0, 0), 1.9, 0.95, 26, 70, m, 2600)
        objs += crown((0, 0.05, 0.8), 0.85, m["gold"], m["velvet"], m["gem_blue"], m["gem_red"])
        frame_and_render(path, objs)
    elif name == "icon_marks":
        objs = []
        rnd = random.Random(7)
        for i in range(5):
            objs.append(coin(f"Stack{i}", (rnd.uniform(-0.03, 0.03), rnd.uniform(-0.03, 0.03), i * 0.12), 0.8, m["gold"]))
        objs.append(coin("Leaning", (0.95, -0.15, 0.32), 0.8, m["gold"], rot=(0.25, 1.15, 0)))
        frame_and_render(path, objs, elev=0.5, pad=0.84)
    else:
        raise SystemExit("unknown icon " + name)


ALL = ["crowns_100", "crowns_550", "crowns_1200", "crowns_2600", "icon_crowns", "icon_marks"]

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for n in (argv or ALL):
        build(n, out_dir)
