"""Render a quick Workbench preview of exported weapon meshes (to check the look
without Studio):

    blender.exe -b --python blender/render.py -- blender/out/Longsword_Blade.fbx blender/out/Longsword_Grip.fbx --png blender/out/Longsword.png
"""
import bpy, math, os, sys

argv = sys.argv[sys.argv.index("--") + 1:]
png = "preview.png"
if "--png" in argv:
    i = argv.index("--png"); png = argv[i + 1]; del argv[i:i + 2]

for o in list(bpy.context.scene.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for p in argv:
    bpy.ops.import_scene.fbx(filepath=p)

# bounds of everything
xs, ys, zs = [], [], []
for o in bpy.context.scene.objects:
    if o.type == "MESH":
        for c in o.bound_box:
            v = o.matrix_world @ bpy.mathutils.Vector(c) if hasattr(bpy, "mathutils") else o.matrix_world @ __import__("mathutils").Vector(c)
            xs.append(v.x); ys.append(v.y); zs.append(v.z)
cx, cy, cz = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2
size = max(max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))

scene = bpy.context.scene
cam_data = bpy.data.cameras.new("Cam"); cam_data.type = "ORTHO"; cam_data.ortho_scale = size * 1.15
cam = bpy.data.objects.new("Cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
# look along -Y of the world (Blender's forward) at the flat of the blade: Roblox Y is up → after import, up is Z
cam.location = (cx, cy - size * 3, cz)
cam.rotation_euler = (math.radians(90), 0, 0)
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "VERTEX"
scene.display.shading.show_cavity = True
scene.render.resolution_x, scene.render.resolution_y = 500, 900
scene.render.film_transparent = False
scene.world = scene.world or bpy.data.worlds.new("W")
scene.world.color = (0.08, 0.1, 0.16)
scene.render.filepath = os.path.abspath(png)
bpy.ops.render.render(write_still=True)
print("RENDERED", scene.render.filepath)
