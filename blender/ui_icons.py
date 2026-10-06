"""Menu icons (the lobby dock and the screen headers), rendered like the shop
art in blender/icons.py (Cycles + Freestyle ink):

    blender.exe -b --python blender/ui_icons.py -- [names...] [--out dir]

names (default all): loadout (a great helm), armory (crossed longswords),
shop (a treasure chest), tasks (a sealed scroll), wardrobe (a tabard on a
hanger), settings (a gear). Output: 512x512 RGBA PNGs in blender/out/ui/.
"""
import bpy, bmesh, math, os, random, sys
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import icons as I          # noqa: E402  scene, lights, materials, gems, coins, framing
import weapons as W        # noqa: E402  the real weapon shapes

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "blender", "out", "ui")

STEEL = (0.78, 0.8, 0.86)
DARK = (0.06, 0.06, 0.08)
WOOD = (0.55, 0.32, 0.15)
WOOD_DARK = (0.36, 0.2, 0.09)
PARCH = (0.93, 0.84, 0.62)
PARCH_DARK = (0.78, 0.66, 0.44)
RED = (0.85, 0.12, 0.12)
BLUE = (0.12, 0.32, 0.9)
GREEN = (0.2, 0.75, 0.25)


def box(name, size, loc, mat, rot=(0, 0, 0), bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        bv = o.modifiers.new("Bevel", "BEVEL"); bv.width = bevel; bv.segments = 3
    I.link(o, mat)
    return o


def cyl(name, r, depth, loc, mat, rot=(0, 0, 0), verts=32, bevel=0.02):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    if bevel:
        bv = o.modifiers.new("Bevel", "BEVEL"); bv.width = bevel; bv.segments = 2
    I.link(o, mat)
    smooth(o)
    return o


def sphere(name, r, loc, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=32, ring_count=16)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    I.link(o, mat)
    smooth(o)
    return o


def smooth(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True); bpy.context.view_layer.objects.active = o
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    except Exception:
        pass


def vcol_material(name, metallic=0.4, rough=0.35):
    """a material that shows the mesh's vertex colours (the weapon meshes)"""
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor"); vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    return m


# ------------------------------------------------------------------ models
def helmet():
    steel = I.material("Steel", STEEL, metallic=1.0, rough=0.25)
    gold = I.material("Gold", I.GOLD, metallic=1.0, rough=0.3)
    dark = I.material("Dark", DARK, rough=0.6)
    red = I.material("Plume", RED, rough=0.55)
    objs = [cyl("Helm", 0.62, 1.15, (0, 0, 0), steel, verts=48, bevel=0.06)]
    objs.append(sphere("Top", 0.62, (0, 0, 0.55), steel, scale=(1, 1, 0.42)))
    # the eye slits, either side of the nasal bar, and breaths
    for x in (-0.24, 0.24):
        objs.append(box("Slit", (0.34, 0.12, 0.09), (x, -0.585, 0.16), dark, bevel=0.02))
    for i in range(3):
        for j in range(2):
            objs.append(cyl("Breath", 0.035, 0.1, (0.2 + j * 0.12, -0.59, -0.12 - i * 0.11), dark, rot=(math.pi / 2, 0, 0), verts=12, bevel=0))
    # gold cross on the face
    objs.append(box("CrossV", (0.12, 0.08, 1.0), (0, -0.62, -0.02), gold, bevel=0.02))
    objs.append(box("CrossH", (1.0, 0.08, 0.1), (0, -0.6, 0.3), gold, bevel=0.02))
    objs.append(cyl("Rim", 0.64, 0.08, (0, 0, -0.56), gold, verts=48, bevel=0.02))
    # a crest: a fan of flattened plumes running front to back over the top
    for k in range(9):
        t = k / 8
        a = math.pi * (0.15 + 0.7 * t)
        pos = (0, -math.cos(a) * 0.5, 0.82 + math.sin(a) * 0.32)
        objs.append(sphere("Crest", 0.2 - 0.05 * abs(t - 0.5), pos, red, scale=(0.35, 1.0, 1.15)))
    return objs


def crossed_swords():
    mat = vcol_material("SwordVC", metallic=0.55, rough=0.28)
    objs = []
    for side in (-1, 1):
        spec = W.WEAPONS["Longsword"]()
        parts = []
        for region in ("Blade", "Grip"):
            for bm in spec.get(region) or []:
                parts.append(bm)
        bm = W.merge(*parts)
        me = bpy.data.meshes.new("Sword"); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new("Sword", me); bpy.context.scene.collection.objects.link(o)
        o.data.materials.append(mat)
        for p in o.data.polygons:
            p.use_smooth = False
        # blade from +Y to +Z, then lean left / right, crossing at the blade's middle
        o.rotation_euler = (math.radians(90), math.radians(-side * 38), 0)
        o.location = (side * 0.9, 0, -1.0)
        objs.append(o)
    return objs


def chest():
    wood = I.material("Wood", WOOD, rough=0.7)
    woodd = I.material("WoodDark", WOOD_DARK, rough=0.7)
    gold = I.material("Gold", I.GOLD, metallic=1.0, rough=0.3)
    dark = I.material("Dark", DARK, rough=0.6)
    objs = [box("Base", (1.7, 1.0, 0.85), (0, 0, 0.42), wood, bevel=0.05)]
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.5, depth=1.7, location=(0, 0, 0.85), rotation=(0, math.pi / 2, 0))
    lid = bpy.context.active_object; lid.name = "Lid"
    bm = bmesh.new(); bm.from_mesh(lid.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.x < -0.001], context="VERTS")   # keep the upper half (local x is world z)
    bm.to_mesh(lid.data); bm.free()
    so = lid.modifiers.new("Solid", "SOLIDIFY"); so.thickness = 0.06
    I.link(lid, woodd); smooth(lid); objs.append(lid)
    # gold bands over base and lid
    for x in (-0.62, 0.62):
        objs.append(box("Band", (0.14, 1.06, 0.88), (x, 0, 0.42), gold, bevel=0.02))
        bpy.ops.mesh.primitive_torus_add(major_radius=0.53, minor_radius=0.05, major_segments=40, minor_segments=8, location=(x, 0, 0.85), rotation=(0, math.pi / 2, 0))
        t = bpy.context.active_object
        bm = bmesh.new(); bm.from_mesh(t.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.x < -0.02], context="VERTS")
        bm.to_mesh(t.data); bm.free()
        I.link(t, gold); smooth(t); objs.append(t)
    objs.append(box("Rim", (1.78, 1.08, 0.1), (0, 0, 0.86), gold, bevel=0.02))
    objs.append(box("Lock", (0.3, 0.12, 0.34), (0, -0.53, 0.78), gold, bevel=0.03))
    objs.append(box("Keyhole", (0.06, 0.05, 0.13), (0, -0.6, 0.76), dark, bevel=0))
    # a little treasure spilling out front
    m = I.mats()
    objs.append(I.coin("C1", (-0.55, -0.85, 0.06), 0.24, m["gold"], rot=(0.15, 0.1, 0)))
    objs.append(I.coin("C2", (-0.25, -0.95, 0.05), 0.22, m["gold"], rot=(-0.1, 0.2, 0)))
    objs.append(I.gem("G1", (0.45, -0.85, 0.16), 0.2, m["gem_blue"], rot=(0.3, 0.2, 0.5)))
    objs.append(I.gem("G2", (0.15, -0.95, 0.12), 0.16, m["gem_red"], rot=(-0.2, 0.4, 1.2)))
    return objs


def scroll():
    parch = I.material("Parch", PARCH, rough=0.8)
    parchd = I.material("ParchDark", PARCH_DARK, rough=0.8)
    wood = I.material("Wood", WOOD_DARK, rough=0.6)
    ink = I.material("Ink", (0.25, 0.18, 0.12), rough=0.8)
    green = I.material("Check", GREEN, rough=0.4, emit=0.15)
    red = I.material("Seal", RED, rough=0.35)
    objs = [box("Sheet", (1.25, 0.04, 1.45), (0, 0, 0), parch, bevel=0.01)]
    for z in (0.76, -0.76):
        objs.append(cyl("Roll", 0.13, 1.4, (0, 0.02, z), parchd, rot=(0, math.pi / 2, 0)))
        for x in (-0.76, 0.76):
            objs.append(sphere("Knob", 0.1, (x, 0.02, z), wood))
    for i, w in enumerate((0.8, 0.65, 0.75)):
        objs.append(box("Line", (w, 0.02, 0.06), (-0.08 - (0.8 - w) / 2, -0.03, 0.38 - i * 0.22), ink, bevel=0))
    # a green check, bottom right (two strokes in the sheet's plane)
    objs.append(box("CheckA", (0.2, 0.05, 0.1), (0.02, -0.05, -0.37), green, rot=(0, math.radians(45), 0), bevel=0.02))
    objs.append(box("CheckB", (0.46, 0.05, 0.1), (0.21, -0.05, -0.26), green, rot=(0, math.radians(-48), 0), bevel=0.02))
    objs.append(cyl("Seal", 0.14, 0.06, (-0.42, -0.05, -0.44), red, rot=(math.pi / 2, 0, 0), verts=24))
    return objs


def wardrobe():
    wood = I.material("Wood", WOOD, rough=0.6)
    cloth = I.material("Cloth", BLUE, rough=0.75)
    gold = I.material("Gold", I.GOLD, metallic=1.0, rough=0.3)
    steel = I.material("Steel", STEEL, metallic=1.0, rough=0.3)
    objs = []
    # the tabard: a tapered panel with a gold cross and a trim
    bm = bmesh.new()
    pts = [(-0.6, 0.62), (0.6, 0.62), (0.52, -0.95), (-0.52, -0.95)]
    face = bm.faces.new([bm.verts.new((x, 0, z)) for x, z in pts])
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    bmesh.ops.translate(bm, vec=(0, 0.08, 0), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    tab = I.mesh_obj("Tabard", bm); tab.location = (0, 0, -0.1)
    bv = tab.modifiers.new("Bevel", "BEVEL"); bv.width = 0.03; bv.segments = 2
    I.link(tab, cloth, smooth=False); objs.append(tab)
    objs.append(box("CrossV", (0.16, 0.04, 0.9), (0, -0.03, -0.2), gold, bevel=0.015))
    objs.append(box("CrossH", (0.62, 0.04, 0.16), (0, -0.03, 0.05), gold, bevel=0.015))
    objs.append(box("Hem", (1.06, 0.1, 0.08), (0, 0.04, -1.04), gold, bevel=0.015))
    # the hanger: a curved bar and a hook
    objs.append(box("Bar", (1.4, 0.12, 0.1), (0, 0.04, 0.58), wood, bevel=0.04))
    for s in (-1, 1):
        objs.append(box("Arm", (0.62, 0.12, 0.09), (s * 0.32, 0.04, 0.72), wood, rot=(0, math.radians(s * 22), 0), bevel=0.03))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.16, minor_radius=0.035, major_segments=32, minor_segments=8, location=(0, 0.04, 1.02), rotation=(math.pi / 2, 0, 0))
    hook = bpy.context.active_object; I.link(hook, steel); smooth(hook); objs.append(hook)
    objs.append(cyl("Neck", 0.035, 0.18, (0, 0.04, 0.86), steel, verts=12))
    return objs


def gear():
    steel = I.material("Steel", (0.58, 0.66, 0.78), metallic=1.0, rough=0.3)
    dark = I.material("Hub", (0.25, 0.28, 0.34), metallic=1.0, rough=0.4)
    teeth, r_out, r_in, r_root = 10, 1.0, 0.42, 0.8
    pts = []
    for i in range(teeth):
        a0 = 2 * math.pi * i / teeth
        for da, r in ((-0.11, r_root), (-0.07, r_out), (0.07, r_out), (0.11, r_root)):
            pts.append((r * math.cos(a0 + da), r * math.sin(a0 + da)))
        pts.append((r_root * math.cos(a0 + math.pi / teeth), r_root * math.sin(a0 + math.pi / teeth)))
    bm = bmesh.new()
    face = bm.faces.new([bm.verts.new((x, 0, z)) for x, z in pts])
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    bmesh.ops.translate(bm, vec=(0, 0.32, 0), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    g = I.mesh_obj("Gear", bm); g.location = (0, -0.16, 0)
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=r_in, depth=1.0, location=(0, 0, 0), rotation=(math.pi / 2, 0, 0))
    hole = bpy.context.active_object
    bo = g.modifiers.new("Hole", "BOOLEAN"); bo.object = hole; bo.operation = "DIFFERENCE"
    bpy.context.view_layer.objects.active = g
    bpy.ops.object.modifier_apply(modifier="Hole")
    bpy.data.objects.remove(hole, do_unlink=True)
    bv = g.modifiers.new("Bevel", "BEVEL"); bv.width = 0.03; bv.segments = 2
    I.link(g, steel, smooth=False)
    ring = cyl("Ring", r_in + 0.06, 0.36, (0, 0, 0), dark, rot=(math.pi / 2, 0, 0), verts=40)
    bm = bmesh.new(); bm.from_mesh(ring.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if abs(f.normal.y) > 0.9], context="FACES")
    bm.to_mesh(ring.data); bm.free()
    so = ring.modifiers.new("Solid", "SOLIDIFY"); so.thickness = 0.08
    return [g, ring]


MODELS = {"loadout": (helmet, 0.92, 0.0), "armory": (crossed_swords, 0.9, -0.55), "shop": (chest, 0.92, -0.55),
          "tasks": (scroll, 0.92, -0.3), "wardrobe": (wardrobe, 0.92, -0.3), "settings": (gear, 0.95, -0.4)}

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for name in (argv or list(MODELS)):
        I.reset()
        fn, pad, azim = MODELS[name]
        objs = fn()
        I.frame_and_render(os.path.join(out_dir, name + ".png"), objs, pad=pad, azim=azim, elev=0.3)
