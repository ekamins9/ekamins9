"""Preview a built face: the face-part PNGs (blender/out/faceparts) stacked over a
skin-coloured round head, the tinted layers tinted, rendered to one PNG.

    blender -b --python blender/face_preview.py -- out.png skin=#d9b48a eyes=Round eyeColor=#3c78dc brows=Angry browColor=#3a2a1a mouth=Grin mark=CheekScar paint=Band paintColor=#c81e1e

(several faces side by side: separate them with "|")
"""
import bpy, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PARTS = os.path.join(os.path.dirname(HERE), "blender", "out", "faceparts")


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def srgb_to_lin(c):
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def plane(img_path, x, z, tint=(1, 1, 1)):
    bpy.ops.mesh.primitive_plane_add(size=1, location=(x, 0, z))
    o = bpy.context.active_object
    m = bpy.data.materials.new("L"); m.use_nodes = True
    m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    nt = m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(img_path)
    mix = nt.nodes.new("ShaderNodeMixRGB"); mix.blend_type = "MULTIPLY"; mix.inputs[0].default_value = 1
    mix.inputs[2].default_value = (*srgb_to_lin(tint), 1)
    nt.links.new(tex.outputs["Color"], mix.inputs[1])
    em = nt.nodes.new("ShaderNodeEmission"); nt.links.new(mix.outputs[0], em.inputs["Color"])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    ms = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(tex.outputs["Alpha"], ms.inputs[0]); nt.links.new(tr.outputs[0], ms.inputs[1]); nt.links.new(em.outputs[0], ms.inputs[2])
    out = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(ms.outputs[0], out.inputs["Surface"])
    o.data.materials.append(m)
    return o


def disc(x, z, color):
    bpy.ops.mesh.primitive_circle_add(vertices=96, radius=0.44, fill_type="NGON", location=(x, 0, z))
    o = bpy.context.active_object
    m = bpy.data.materials.new("Skin"); m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs["Color"].default_value = (*srgb_to_lin(color), 1)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(em.outputs[0], out.inputs["Surface"])
    o.data.materials.append(m)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    out_path = argv[0]
    faces, cur = [], {}
    for a in argv[1:]:
        if a == "|":
            faces.append(cur); cur = {}
        elif "=" in a:
            k, v = a.split("=", 1); cur[k] = v
    faces.append(cur)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 16; sc.cycles.device = "CPU"
    sc.render.resolution_x, sc.render.resolution_y = 400 * len(faces), 400
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    cam = bpy.data.cameras.new("C"); cam.type = "ORTHO"; cam.ortho_scale = 1.0 * len(faces)
    co = bpy.data.objects.new("C", cam); sc.collection.objects.link(co); sc.camera = co
    co.location = (0, 5, 0); co.rotation_euler = (1.5708, 0, 3.14159)
    co.location = (0, -5, 0); co.rotation_euler = (1.5708, 0, 0)
    for i, f in enumerate(faces):
        x = (i - (len(faces) - 1) / 2) * 1.0
        disc(x, 0, hexc(f.get("skin", "#d9b48a")))
        bpy.context.active_object.rotation_euler = (1.5708, 0, 0)
        layers = [("paint", f.get("paint"), f.get("paintColor", "#c81e1e")), ("mark", f.get("mark"), None),
                  ("mouth", f.get("mouth"), None), ("brows", f.get("brows"), f.get("browColor", "#3a2a1a")),
                  ("eyes", f.get("eyes"), None), ("iris", f.get("eyes"), f.get("eyeColor", "#5c381e")), ("pupil", f.get("eyes"), None)]
        for k, (layer, pid, tint) in enumerate(layers):
            if not pid or pid == "None":
                continue
            path = os.path.join(PARTS, "%s_%s.png" % (layer, pid))
            if os.path.exists(path):
                o = plane(path, x, 0, hexc(tint) if tint else (1, 1, 1))
                o.rotation_euler = (1.5708, 0, 0)
                o.location.y = -0.01 * (k + 1)
    sc.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print("PREVIEW", out_path)
