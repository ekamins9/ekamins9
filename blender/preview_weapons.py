"""Preview every weapon from blender/weapons.py in one Workbench render (to judge
the shapes before anything is exported or uploaded):

    blender.exe -b --python blender/preview_weapons.py -- [Longsword Mace ...] [--png out.png] [--edge]

Weapons stand point-up in a row, seen on the flat of the blade (--edge: on the
edge), with their vertex colours, named underneath. A grey R6 arm (1 x 2 x 1)
holds the first one, for scale.
"""
import bpy, bmesh, math, os, sys
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
import weapons as W  # noqa: E402


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    png = os.path.join(ROOT, "blender", "out", "weapons_preview.png")
    if "--png" in argv:
        i = argv.index("--png"); png = argv[i + 1]; del argv[i:i + 2]
    edge = "--edge" in argv
    argv = [a for a in argv if a != "--edge"]
    names = argv or list(W.WEAPONS)
    W.clear_scene()
    bms, labels = [], []
    x = 0.0
    for name in names:
        spec = W.WEAPONS[name]()
        parts = (spec.get("Blade") or []) + (spec.get("Grip") or [])
        bm = W.merge(*parts)
        xs = [v.co.x for v in bm.verts]
        w = max(xs) - min(xs)
        # Tool frame: Y up the blade, flats facing ±Z. Blender: Y → Z (up); seen from -Y
        turn = Matrix.Rotation(math.radians(90), 4, "X")
        if edge:
            turn = turn @ Matrix.Rotation(math.radians(90), 4, "Y")
        m = Matrix.Translation(Vector((x - min(xs) if not edge else x, 0, 0))) @ turn
        for v in bm.verts:
            v.co = m @ v.co
        bms.append(bm)
        labels.append((name, x + (w / 2 if not edge else 0)))
        x += (w if not edge else 0.4) + 0.9
    bm = W.merge(*bms)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("Weapons")
    bm.to_mesh(me); bm.free()
    try:
        me.color_attributes.active_color = me.color_attributes["Col"]
        me.color_attributes.render_color_index = me.color_attributes.active_color_index
    except Exception as e:
        print("color attribute:", e)
    ob = bpy.data.objects.new("Weapons", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.select_set(True); bpy.context.view_layer.objects.active = ob
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    zs = [v.co.z for v in me.vertices]; xs = [v.co.x for v in me.vertices]
    for text, lx in labels:
        cu = bpy.data.curves.new("L", "FONT"); cu.body = text; cu.size = 0.28; cu.align_x = "CENTER"
        t = bpy.data.objects.new("L", cu)
        t.location = (lx, -1.0, min(zs) - 0.5); t.rotation_euler = (math.radians(90), 0, 0)
        bpy.context.scene.collection.objects.link(t)
    sc = bpy.context.scene
    w, h = max(xs) - min(xs) + 1, max(zs) - min(zs) + 1.4
    res = (2600, max(400, int(2600 * h / w)))
    sc.render.resolution_x, sc.render.resolution_y = res
    cam_data = bpy.data.cameras.new("Cam"); cam_data.type = "ORTHO"; cam_data.ortho_scale = max(w, h * res[0] / res[1]) * 1.02
    cam = bpy.data.objects.new("Cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = ((max(xs) + min(xs)) / 2, -60, (max(zs) + min(zs)) / 2 - 0.35)
    cam.rotation_euler = Vector((0, 1, 0)).to_track_quat("-Z", "Y").to_euler()
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "VERTEX"
    sc.display.shading.show_cavity = True
    sc.display.shading.show_specular_highlight = True
    sc.world = sc.world or bpy.data.worlds.new("W")
    sc.world.color = (0.11, 0.12, 0.15)
    sc.render.filepath = os.path.abspath(png)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", sc.render.filepath)


if __name__ == "__main__":
    main()
