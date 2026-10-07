"""Preview armor blueprints on an R6 mannequin, in Blender headless (Workbench),
straight from blender/out/blueprints.json — to judge the designs before any
mesh is uploaded.

    blender.exe -b --python blender/preview_armor.py -- blender/out/blueprints.json --sheet heads --png out.png
    ... --sheet figures | heads | torsos | legs      every set and earned piece in a grid
    ... --sets TourneyKnight,IronCrow                 front / side / back of each set, one row each
    ... --palette bright                               loud slot colors (default: the starter colors)

Slots are painted with the player's colors (default Navy / Slate / Ochre / Ash),
every other part with its own color, as in game.
"""
import bpy, bmesh, json, math, os, sys
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
from parts2mesh import part_mesh, box_mesh, cyl_mesh  # noqa: E402
from weapons import merge, paint, clear_scene  # noqa: E402


def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)


PALETTES = {
    "default": {"Primary": rgb(47, 63, 110), "Secondary": rgb(58, 58, 58), "Accent": rgb(160, 122, 42), "Metal": rgb(110, 117, 128)},
    "bright": {"Primary": rgb(74, 98, 168), "Secondary": rgb(96, 32, 48), "Accent": rgb(232, 184, 74), "Metal": rgb(150, 156, 164)},
}
SKIN = rgb(217, 180, 138)
SHIRT = rgb(90, 90, 96)
LIMB_AT = {"HeadClothing": (0, 1.5, 0), "TorsoClothing": (0, 0, 0), "LeftArmClothing": (-1.5, 0, 0),
           "RightArmClothing": (1.5, 0, 0), "LeftLegClothing": (-0.5, -2, 0), "RightLegClothing": (0.5, -2, 0)}
BODY = [((0, 1.5, 0), (1.2, 1.2, 1.2), SKIN), ((0, 0, 0), (2, 2, 1), SHIRT), ((-1.5, 0, 0), (1, 2, 1), SKIN),
        ((1.5, 0, 0), (1, 2, 1), SKIN), ((-0.5, -2, 0), (1, 2, 1), SHIRT), ((0.5, -2, 0), (1, 2, 1), SHIRT)]
# Roblox (Y up, front -Z) → Blender (Z up): the front ends up facing +Y, toward the camera
TO_BLENDER = Matrix.Rotation(math.radians(90), 4, "X")


# the classic R6 head (SpecialMesh "Head", scale 1.25): a round drum with rounded rims
HEAD_PROFILE = [(0.0, 0.625), (0.3, 0.625), (0.42, 0.61), (0.52, 0.565), (0.585, 0.5), (0.615, 0.43), (0.625, 0.35),
                (0.625, -0.35), (0.615, -0.43), (0.585, -0.5), (0.52, -0.565), (0.42, -0.61), (0.3, -0.625), (0.0, -0.625)]


def head_mesh(n=28):
    bm = bmesh.new()
    rings = []
    for r, y in HEAD_PROFILE:
        ring = []
        for i in range(n):
            a = 2 * math.pi * i / n
            ring.append(bm.verts.new((r * math.cos(a), y, r * math.sin(a))))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            try:
                bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
            except ValueError:
                pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def roty(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Y")


def at(x, y, z):
    return Matrix.Translation(Vector((x, y, z)))


class Sheet:
    def __init__(self, palette):
        self.pal = PALETTES[palette]
        self.bms = []
        self.labels = []

    def add_specs(self, specs, frame, hair=None):
        for s in specs:
            if s.get("n") == "Middle" or (s.get("t", 0) or 0) >= 1:
                continue
            bm = part_mesh(s)
            a = s.get("a") or {}
            slot = a.get("ColorSlot")
            if hair and not a.get("KeepColor"):
                paint(bm, hair)
            else:
                paint(bm, self.pal[slot] if slot else tuple(s.get("c", (0.8, 0.8, 0.8))))
            m = TO_BLENDER @ frame
            for v in bm.verts:
                v.co = m @ v.co
            self.bms.append(bm)

    def add_body(self, frame, parts=None):
        for i, (pos, size, color) in enumerate(BODY):
            if parts is not None and i not in parts:
                continue
            bm = head_mesh() if i == 0 else box_mesh(*size, 0.05)
            paint(bm, color)
            m = TO_BLENDER @ frame @ at(*pos)
            for v in bm.verts:
                v.co = m @ v.co
            self.bms.append(bm)

    def add_figure(self, slots, frame, parts=None):
        """slots = {SlotName: specs}; parts = the body parts to show (indices into BODY)"""
        self.add_body(frame, parts)
        for slot, specs in slots.items():
            self.add_specs(specs, frame @ at(*LIMB_AT[slot]))

    def label(self, text, x, y):
        self.labels.append((text, x, y))

    def render(self, png, res=(1800, 1200)):
        clear_scene()
        bm = merge(*self.bms)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new("Sheet")
        bm.to_mesh(me); bm.free()
        try:   # Workbench's vertex colors read the active color attribute
            me.color_attributes.active_color = me.color_attributes["Col"]
            me.color_attributes.render_color_index = me.color_attributes.active_color_index
        except Exception as e:
            print("color attribute:", e)
        ob = bpy.data.objects.new("Sheet", me)
        bpy.context.scene.collection.objects.link(ob)
        ob.select_set(True); bpy.context.view_layer.objects.active = ob
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
        xs = [v.co.x for v in me.vertices]; zs = [v.co.z for v in me.vertices]
        for text, x, y in self.labels:   # x, y in Roblox (x, y): Blender (x, z)
            cu = bpy.data.curves.new("L", "FONT"); cu.body = text; cu.size = 0.42; cu.align_x = "CENTER"
            t = bpy.data.objects.new("L", cu)
            t.location = (x, 2.0, y); t.rotation_euler = (math.radians(90), 0, math.radians(180))
            bpy.context.scene.collection.objects.link(t)
            xs += [x - 2, x + 2]; zs += [y - 0.4]
        cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
        w, h = max(xs) - min(xs), max(zs) - min(zs)
        sc = bpy.context.scene
        sc.render.resolution_x, sc.render.resolution_y = res
        aspect = res[0] / res[1]
        cam_data = bpy.data.cameras.new("Cam"); cam_data.type = "ORTHO"
        cam_data.ortho_scale = max(w, h * aspect) * 1.06
        cam = bpy.data.objects.new("Cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
        cam.location = (cx, 60, cz)
        cam.rotation_euler = Vector((0, -1, 0)).to_track_quat("-Z", "Y").to_euler()
        sc.render.engine = "BLENDER_WORKBENCH"
        sc.display.shading.light = "STUDIO"
        sc.display.shading.color_type = "VERTEX"
        sc.display.shading.show_cavity = True
        sc.display.shading.cavity_type = "BOTH"
        sc.display.shading.show_specular_highlight = True
        sc.world = sc.world or bpy.data.worlds.new("W")
        sc.world.color = (0.11, 0.12, 0.15)
        sc.render.filepath = os.path.abspath(png)
        bpy.ops.render.render(write_still=True)
        print("RENDERED", sc.render.filepath)


def grid(items, cols, dx, dy):
    """left to right as seen (the camera faces the figures, so its right is -X)"""
    for i, it in enumerate(items):
        yield it, -(i % cols) * dx, -(i // cols) * dy


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    data = json.load(open(argv[0], encoding="utf-8"))
    opt = {}
    i = 1
    while i < len(argv):
        opt[argv[i].lstrip("-")] = argv[i + 1]; i += 2
    sheet = Sheet(opt.get("palette", "default"))
    png = opt.get("png", os.path.join(ROOT, "blender", "out", "preview.png"))
    sets, pieces = data["sets"], data["pieces"]
    order = ["PeasantSkin", "RoadLevy", "MarshWardens", "CoastHarriers", "NightHunters",
             "GambesonSkin", "Sellswords", "RiverGuard", "GildedCourt", "WolfCompany",
             "KnightSkin", "TourneyKnight", "IronCrow", "Blackguard", "SunKnights"]
    order = [n for n in order if n in sets] + sorted(n for n in sets if n not in order)
    if "sets" in opt:
        names = opt["sets"].split(",")
        for row, name in enumerate(names):
            slots = sets.get(name) or pieces.get(name)
            for col, yaw in enumerate((0, 90, 180)):
                sheet.add_figure(slots, at(-col * 5.5, -row * 8, 0) @ roty(yaw))
            sheet.label(name, -5.5, -row * 8 - 3.9)
        sheet.render(png, (1500, 760 * len(names)))
        return
    kind = opt.get("sheet", "figures")
    if kind == "body":   # every hair and beard on a bare head, in a brown hair colour
        items = [("Hair " + k, v) for k, v in sorted(data["body"].get("Hair", {}).items())]
        items += [("Beard " + k, v) for k, v in sorted(data["body"].get("Beard", {}).items())]
        yaw = float(opt.get("yaw", 30))
        for (name, specs), x, y in grid(items, 6, 3.0, 3.4):
            frame = at(x, y - 1.5, 0) @ roty(yaw)
            sheet.add_body(frame, [0])
            sheet.add_specs(specs, frame @ at(*LIMB_AT["HeadClothing"]), hair=rgb(92, 62, 36))
            sheet.label(name, x, y - 1.25)
        sheet.render(png, (2400, 1500))
        return
    if kind == "figures":
        items = [(n, sets[n]) for n in order] + [(p, pieces[p]) for p in sorted(pieces)]
        for (name, slots), x, y in grid(items, 8, 5.2, 8.6):
            sheet.add_figure(slots, at(x, y, 0) @ roty(float(opt.get("yaw", 20))))
            sheet.label(name, x, y - 3.7)
        sheet.render(png, (int(opt.get("w", 2400)), int(opt.get("h", 1400))))
    elif kind in ("heads", "torsos", "legs"):
        want = {"heads": ("HeadClothing",), "torsos": ("TorsoClothing", "LeftArmClothing", "RightArmClothing"),
                "legs": ("LeftLegClothing", "RightLegClothing")}[kind]
        body = {"heads": [0], "torsos": [1, 2, 3], "legs": [4, 5]}[kind]
        items = []
        for n in order:
            items.append((n, sets[n]))
        for p in sorted(pieces):
            items.append((p, pieces[p]))
        items = [(n, {k: v for k, v in s.items() if k in want}) for n, s in items]
        items = [(n, s) for n, s in items if s]
        cols = 6
        dx, dy = (3.2, 3.6) if kind == "heads" else (5.4, 4.6)
        yoff = {"heads": -1.5, "torsos": 0, "legs": 2}[kind]
        yaw = float(opt.get("yaw", 28))
        for (name, slots), x, y in grid(items, cols, dx, dy):
            sheet.add_figure(slots, at(x, y + yoff, 0) @ roty(yaw), body)
            sheet.label(name, x, y - (1.25 if kind == "heads" else 1.9))
        sheet.render(png, (2400, int(2400 * (math.ceil(len(items) / cols) * dy) / (cols * dx))))


if __name__ == "__main__":
    main()
