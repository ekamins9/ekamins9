"""Contact sheet of the face textures on skin-coloured discs (a quick review
of blender/faces.py output):

    blender.exe -b --python blender/face_sheet.py -- [--out blender/out/faces/_sheet.png]
"""
import bpy, glob, math, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "blender", "out", "faces")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = os.path.join(SRC, "_sheet.png")
if "--out" in argv:
    out = argv[argv.index("--out") + 1]

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 16
sc.view_settings.view_transform = "Standard"
files = sorted(f for f in glob.glob(os.path.join(SRC, "*.png")) if not os.path.basename(f).startswith("_"))
cols = 5
rows = math.ceil(len(files) / cols)
sc.render.resolution_x, sc.render.resolution_y = 260 * cols, 290 * rows
cam = bpy.data.cameras.new("C"); cam.type = "ORTHO"; cam.ortho_scale = 1.3 * cols
co = bpy.data.objects.new("C", cam); sc.collection.objects.link(co); sc.camera = co
co.location = (0, 0, 10)
w = bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.08, 0.16, 1)
SKINS = [(0.82, 0.62, 0.42), (0.62, 0.42, 0.26), (0.92, 0.75, 0.58), (0.38, 0.24, 0.14)]


def emission_mat(name, color=None, image=None):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    outn = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    if image:
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(image)
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        nt.links.new(tex.outputs["Color"], em.inputs["Color"])
        nt.links.new(tex.outputs["Alpha"], mix.inputs["Fac"])
        nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
        nt.links.new(em.outputs["Emission"], mix.inputs[2])
        nt.links.new(mix.outputs["Shader"], outn.inputs["Surface"])
    else:
        em.inputs["Color"].default_value = (*color, 1)
        nt.links.new(em.outputs["Emission"], outn.inputs["Surface"])
    return m


for i, f in enumerate(files):
    cx = (i % cols - (cols - 1) / 2) * 1.3
    cy = -(i // cols - (rows - 1) / 2) * 1.45
    bpy.ops.mesh.primitive_circle_add(vertices=64, radius=0.58, fill_type="NGON", location=(cx, cy, 0))
    disc = bpy.context.active_object
    disc.data.materials.append(emission_mat("Skin%d" % i, SKINS[i % len(SKINS)]))
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(cx, cy, 0.01))
    pl = bpy.context.active_object
    pl.data.materials.append(emission_mat("Face%d" % i, image=f))
    bpy.ops.object.text_add(location=(cx - 0.55, cy - 0.72, 0.02))
    t = bpy.context.active_object; t.data.body = os.path.splitext(os.path.basename(f))[0]; t.data.size = 0.16
    t.data.materials.append(emission_mat("T%d" % i, (1, 1, 1)))
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("SHEET", out)
