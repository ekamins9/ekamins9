"""ART KIT — store art for Steel & Glory (thumbnails, the icon, badge pictures) rendered
in Blender (Cycles on the GPU) out of the game's own pieces:

  figure(...)     an R6 fighter dressed in any armor set (blender/out/blueprints.json), posed
                  joint by joint (Roblox axes: X right, Y up, -Z front; degrees), with a weapon
                  (blender/weapons.py), a staff skin (blender/out/staff_heads.json), or a bow
  fire / blaze / sparks / embers       effects (emission, lit by point lights): a fireball
                  (a hot core in a ragged rim), a fire burning on something, sparks, embers
  ground / tower / wall / sky / fog    a stage
  overlay / compose                    titles as their own layer (crisp type, gradient fill,
                  outline, shadow, a plate) laid over the render
  setup / camera / render / bloom      Cycles, OptiX, AgX, bloom and a colour grade
  where(label, point)                  where a point lands in the frame (for laying out)

Used by blender/store_art.py (the scenes). Everything is in Blender space (Z up); a
figure's `at` is where its feet stand and `yaw` the way it faces (0 = toward -Y, the
camera's usual side is -Y looking +Y... see place())."""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Matrix, Vector, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
from parts2mesh import part_mesh, box_mesh  # noqa: E402
import weapons as W  # noqa: E402

OUT = os.path.join(ROOT, "blender", "out")
BP = json.load(open(os.path.join(OUT, "blueprints.json"), encoding="utf-8"))
STAFFS = {}
_sp = os.path.join(OUT, "staff_heads.json")
if os.path.exists(_sp):
    STAFFS = json.load(open(_sp, encoding="utf-8"))

TO_BL = Matrix.Rotation(math.radians(90), 4, "X")   # Roblox (x, y, z) → Blender (x, -z, y)
D = math.radians


def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)


def T(x, y, z):
    return Matrix.Translation(Vector((x, y, z)))


def R(rx=0, ry=0, rz=0):
    return Euler((D(rx), D(ry), D(rz)), "XYZ").to_matrix().to_4x4()


SKIN = rgb(217, 180, 138)
PAL = {"Primary": rgb(52, 84, 190), "Secondary": rgb(36, 40, 58), "Accent": rgb(232, 184, 74), "Metal": rgb(186, 192, 204)}

# --------------------------------------------------------------------------
#  MATERIALS (all read the mesh's "Col" corner colours)
# --------------------------------------------------------------------------
_mats = {}


def _vcol(nt):
    n = nt.nodes.new("ShaderNodeVertexColor")
    n.layer_name = "Col"
    return n


def mat(kind, strength=6.0, tint=None):
    key = (kind, strength, tint)
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new(f"{kind}")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    out = nt.nodes.get("Material Output")
    vc = _vcol(nt)
    if tint:
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        nt.links.new(vc.outputs["Color"], mix.inputs["A"]); mix.inputs["B"].default_value = (*tint, 1)
        col = mix.outputs["Result"]
    else:
        col = vc.outputs["Color"]
    nt.links.new(col, bsdf.inputs["Base Color"])
    if kind == "metal":
        bsdf.inputs["Metallic"].default_value = 0.85; bsdf.inputs["Roughness"].default_value = 0.3
    elif kind == "blade":
        bsdf.inputs["Metallic"].default_value = 1.0; bsdf.inputs["Roughness"].default_value = 0.16
    elif kind == "cloth":
        bsdf.inputs["Roughness"].default_value = 0.8
        try: bsdf.inputs["Sheen Weight"].default_value = 0.4
        except KeyError: pass
    elif kind == "skin":
        bsdf.inputs["Roughness"].default_value = 0.5
    elif kind == "grip":
        bsdf.inputs["Roughness"].default_value = 0.55
    elif kind == "glass":
        bsdf.inputs["Roughness"].default_value = 0.05
        try: bsdf.inputs["Transmission Weight"].default_value = 0.7
        except KeyError: pass
    elif kind == "neon":
        nt.links.new(col, bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = strength
        bsdf.inputs["Base Color"].default_value = (0, 0, 0, 1)
    _mats[key] = m
    return m


def flat_mat(name, color, metallic=0.0, rough=0.5, emit=0.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*color, 1)
        b.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
    return m


METALS = {"Metal", "Foil", "DiamondPlate", "CorrodedMetal"}


def mclass(m):
    if m == "Neon":
        return "neon"
    if m in ("Glass", "Ice"):
        return "glass"
    if m in METALS:
        return "metal"
    return "cloth"


def paint(bm, color):
    W.paint(bm, color)


def obj(name, bm, material, matrix=Matrix()):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    # (smooth, with the hard edges kept sharp: plates and boxes stay crisp, round things round)
    try:
        me.shade_smooth()
        me.set_sharp_from_angle(angle=math.radians(38))
    except Exception:
        for p in me.polygons:
            p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.matrix_world = matrix
    o.data.materials.append(material)
    return o


def group(name, bms_by_kind, matrix, neon=6.0):
    """{kind: [bmesh]} → one object per kind"""
    out = []
    for kind, bms in bms_by_kind.items():
        if not bms:
            continue
        out.append(obj(f"{name}_{kind}", W.merge(*bms), mat(kind, neon), matrix))
    return out


# --------------------------------------------------------------------------
#  THE BODY
# --------------------------------------------------------------------------
HEAD_PROFILE = [(0.0, 0.625), (0.3, 0.625), (0.42, 0.61), (0.52, 0.565), (0.585, 0.5), (0.615, 0.43), (0.625, 0.35),
                (0.625, -0.35), (0.615, -0.43), (0.585, -0.5), (0.52, -0.565), (0.42, -0.61), (0.3, -0.625), (0.0, -0.625)]


def head_mesh(n=32):
    bm = bmesh.new()
    rings = []
    for r, y in HEAD_PROFILE:
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * i / n), y, r * math.sin(2 * math.pi * i / n))) for i in range(n)])
    for a, b in zip(rings, rings[1:]):
        for i in range(n):
            try:
                bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
            except ValueError:
                pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    return bm


def sphere_bm(c, r, scale=(1, 1, 1), color=(1, 1, 1), segs=16):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=max(8, segs // 2), radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * r * scale[0] + c[0], v.co.y * r * scale[1] + c[1], v.co.z * r * scale[2] + c[2]))
    paint(bm, color)
    return bm


def face_bms(expression="fierce"):
    """the classic face, in the head's frame (front -Z): two eyes and a mouth"""
    out = []
    ey = 0.12 if expression != "fierce" else 0.1
    for s in (-1, 1):
        out.append(sphere_bm((s * 0.2, ey, -0.6), 0.075, (1, 1.45, 0.45), (0.05, 0.05, 0.06), 10))
        if expression == "fierce":   # brows, angled in
            bm = box_mesh(0.22, 0.05, 0.05, 0.01)
            m = T(s * 0.21, ey + 0.17, -0.6) @ R(0, 0, s * 18)
            for v in bm.verts: v.co = m @ v.co
            paint(bm, (0.05, 0.05, 0.06)); out.append(bm)
    bm = box_mesh(0.3, 0.05, 0.05, 0.02)
    m = T(0, -0.18, -0.6)
    for v in bm.verts: v.co = m @ v.co
    paint(bm, (0.05, 0.05, 0.06)); out.append(bm)
    return out


LIMBS = ("Head", "Torso", "RightArm", "LeftArm", "RightLeg", "LeftLeg")
SLOT_OF = {"Head": "HeadClothing", "Torso": "TorsoClothing", "RightArm": "RightArmClothing", "LeftArm": "LeftArmClothing",
           "RightLeg": "RightLegClothing", "LeftLeg": "LeftLegClothing"}


def place(at=(0, 0, 0), yaw=0.0):
    """the figure's root: feet at `at` (Blender), facing `yaw` degrees (0 = facing +Y, away
    from a camera at -Y; 180 = toward it; -90 = facing +X; 90 = facing -X)."""
    return T(*at) @ Matrix.Rotation(D(yaw), 4, "Z") @ TO_BL


def limb_frames(root, pose):
    """Roblox-space frames (as Blender matrices) of each limb's CENTRE for a pose:
    pose = {torso, head, rarm, larm, rleg, lleg, hips}: (rx, ry, rz) degrees each, Roblox axes;
    `hips` (y) lifts / lowers the whole body (a crouch)"""
    p = pose or {}
    body = root @ T(0, 3 + p.get("drop", 0), 0)
    torso = body @ T(0, -1, 0) @ R(*p.get("torso", (0, 0, 0))) @ T(0, 1, 0)
    f = {"Torso": torso}
    f["Head"] = torso @ T(0, 1, 0) @ R(*p.get("head", (0, 0, 0))) @ T(0, 0.5, 0)
    f["RightArm"] = torso @ T(1.5, 0.5, 0) @ R(*p.get("rarm", (0, 0, 0))) @ T(0, -0.5, 0)
    f["LeftArm"] = torso @ T(-1.5, 0.5, 0) @ R(*p.get("larm", (0, 0, 0))) @ T(0, -0.5, 0)
    f["RightLeg"] = body @ T(0.5, -1, 0) @ R(*p.get("rleg", (0, 0, 0))) @ T(0, -1, 0)
    f["LeftLeg"] = body @ T(-0.5, -1, 0) @ R(*p.get("lleg", (0, 0, 0))) @ T(0, -1, 0)
    return f


def figure(set_name=None, at=(0, 0, 0), yaw=0.0, pose=None, colors=None, face="fierce", neon=6.0, skin=SKIN, slots=None):
    """an R6 fighter in an armor set; returns (frames, objects). colors: ColorSlot → (r, g, b)"""
    pal = dict(PAL)
    pal.update(colors or {})
    slots = slots or (BP["sets"].get(set_name) or BP["pieces"].get(set_name) or {})
    frames = limb_frames(place(at, yaw), pose)
    objs = []
    for limb in LIMBS:
        kinds = {"skin": [], "cloth": [], "metal": [], "neon": [], "glass": []}
        if limb == "Head":
            bm = head_mesh(); paint(bm, skin); kinds["skin"].append(bm)
            if face:
                kinds["cloth"] += face_bms(face)
        else:
            size = (2, 2, 1) if limb == "Torso" else (1, 2, 1)
            bm = box_mesh(*size, 0.06); paint(bm, skin if "Arm" in limb else rgb(70, 70, 76)); kinds["skin"].append(bm)
        for s in slots.get(SLOT_OF[limb], []):
            if s.get("n") == "Middle" or (s.get("t", 0) or 0) >= 1:
                continue
            bm = part_mesh(s)
            a = s.get("a") or {}
            slot = a.get("ColorSlot")
            paint(bm, pal[slot] if slot and slot in pal else tuple(s.get("c", (0.8, 0.8, 0.8))))
            kinds[mclass(s.get("m", ""))].append(bm)
        objs += group(f"{set_name}_{limb}", kinds, frames[limb], neon)
    return frames, objs


def hand(frames, side="R"):
    """the grip frame in a hand: the weapon's +Y (its blade) points the way the arm's front (-Z) did"""
    return frames["RightArm" if side == "R" else "LeftArm"] @ T(0, -1.05, -0.05) @ R(-90, 0, 0)


def weapon(name, frame, glow=None):
    spec = W.WEAPONS[name]()
    out = []
    for region, kind in (("Blade", "blade"), ("Grip", "grip")):
        bms = spec.get(region) or []
        if bms:
            out.append(obj(f"{name}_{region}", W.merge(*bms), mat(kind), frame))
    return out


def staff(name, frame, neon=8.0):
    """a staff skin (blender/out/staff_heads.json: Roblox parts in the Handle's frame)"""
    parts = STAFFS.get(name, [])
    kinds = {"neon": [], "metal": [], "glass": [], "cloth": []}
    for shape, sx, sy, sz, x, y, z, rx, ry, rz, hexc, m, tr in parts:
        col = tuple(int(hexc[k:k + 2], 16) / 255 for k in (0, 2, 4))
        bm = bmesh.new()
        if shape == "S":
            bmesh.ops.create_uvsphere(bm, u_segments=18, v_segments=10, radius=0.5)
        elif shape == "C":
            bmesh.ops.create_cone(bm, cap_ends=True, segments=18, radius1=0.5, radius2=0.5, depth=1.0)
            bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(D(90), 3, "Y"))
        elif shape == "W":
            vs = [bm.verts.new(p) for p in [(-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5), (-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5)]]
            for f in [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]:
                bm.faces.new([vs[i] for i in f])
        else:
            bmesh.ops.create_cube(bm, size=1.0)
        # (Roblox's ToEulerAnglesXYZ undoes CFrame.Angles = Rx·Ry·Rz)
        M = T(x, y, z) @ Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Diagonal((sx, sy, sz, 1))
        for v in bm.verts:
            v.co = M @ v.co
        paint(bm, col)
        kinds["neon" if m == "N" else ("glass" if m == "G" else ("metal" if m == "M" else "cloth"))].append(bm)
    return group(f"Staff_{name}", kinds, frame, neon)


def bow(frame, color=rgb(120, 70, 36), string=rgb(240, 230, 210), drawn=0.6, height=5.0):
    """a longbow in the LEFT hand's frame: the grip at the origin, the limbs along ±Y,
    bending back (+Z… toward the archer) as it's drawn; the string pulled back by `drawn`"""
    n = 14
    pts = []
    for i in range(n + 1):
        t = i / n * 2 - 1
        y = t * height / 2
        z = (1 - t * t) * 0 + (t * t) * (0.45 + 0.6 * drawn)
        pts.append(Vector((0, y, z)))
    bm = W.tube([tuple(p) for p in pts], 0.09, color)
    tips = [pts[0], pts[-1]]
    nock = Vector((0, 0, 0.45 + 0.6 * drawn + 1.4 * drawn))
    s1 = W.tube([tuple(tips[0]), tuple(nock), tuple(tips[1])], 0.02, string)
    grip = W.cylinder(-0.35, 0.35, 0.12, 0.12, rgb(60, 40, 26))
    return [obj("Bow", W.merge(bm, grip), mat("grip"), frame), obj("BowString", s1, mat("cloth"), frame)], frame @ T(0, 0, nock.z)


# --------------------------------------------------------------------------
#  EFFECTS
# --------------------------------------------------------------------------
def light(kind, loc, color, energy, size=1.0, target=None, angle=60):
    ld = bpy.data.lights.new(kind, kind)
    ld.color = color
    ld.energy = energy
    if kind in ("POINT", "SPOT"):
        ld.shadow_soft_size = size
    if kind == "AREA":
        ld.size = size
    if kind == "SPOT":
        ld.spot_size = D(angle)
    o = bpy.data.objects.new(kind, ld)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.visible_camera = False   # (a point light's sphere shows in Cycles otherwise)
    if target is not None:
        d = Vector(target) - Vector(loc)
        o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return o


def glow_mat(color, strength):
    return flat_mat("glow", color, emit=strength)


def sparks(center, n=60, color=rgb(255, 200, 90), spread=2.5, length=0.5, seed=1, power=600, light_color=None, strength=40):
    rnd = random.Random(seed)
    c = Vector(center)
    bms = []
    for _ in range(n):
        d = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
        dist = rnd.uniform(0.15, 1.0) ** 0.7 * spread
        p = c + d * dist
        L = length * rnd.uniform(0.4, 1.4) * (0.4 + dist / spread)
        w = rnd.uniform(0.012, 0.035)
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=1.0)
        rot = d.to_track_quat("Z", "Y").to_matrix().to_4x4()
        M = Matrix.Translation(p) @ rot @ Matrix.Diagonal((w, w, L, 1))
        for v in bm.verts:
            v.co = M @ v.co
        paint(bm, color)
        bms.append(bm)
    o = obj("Sparks", W.merge(*bms), flat_mat("spark", color, emit=strength), Matrix())
    core = obj("SparkCore", sphere_bm(center, 0.22, color=(1, 1, 1)), flat_mat("core", (1, 0.95, 0.8), emit=strength * 1.5), Matrix())
    light("POINT", center, light_color or color, power, 0.3)
    return [o, core]


def embers(box_min, box_max, n=200, color=rgb(255, 140, 40), seed=3, size=(0.02, 0.06), strength=25):
    rnd = random.Random(seed)
    bms = []
    for _ in range(n):
        p = (rnd.uniform(box_min[0], box_max[0]), rnd.uniform(box_min[1], box_max[1]), rnd.uniform(box_min[2], box_max[2]))
        bms.append(sphere_bm(p, rnd.uniform(*size), (1, 1, rnd.uniform(1, 2.5)), color, 6))
    return obj("Embers", W.merge(*bms), flat_mat("ember", color, emit=strength), Matrix())


def fireball(center, r=0.8, color=rgb(255, 120, 30), core=(1, 0.9, 0.6), power=2500, seed=5, strength=(50, 18), outer=None):
    """a hot core in a lumpy shell; `outer` = (colour, strength): a third, darker, bigger skin of
    puffs (deep red) so the ball reads as fire, not a glowing blob (AgX whitens bright emission)"""
    rnd = random.Random(seed)
    objs = [obj("FireCore", sphere_bm(center, r * 0.55, color=core), flat_mat("fcore", core, emit=strength[0]), Matrix())]
    shell = []
    for _ in range(26):
        d = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
        shell.append(sphere_bm(Vector(center) + d * r * rnd.uniform(0.3, 0.75), r * rnd.uniform(0.25, 0.5), (1, 1, 1), color, 10))
    objs.append(obj("FireShell", W.merge(*shell), flat_mat("fshell", color, emit=strength[1]), Matrix()))
    if outer:
        puffs = []
        for _ in range(34):
            d = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
            puffs.append(sphere_bm(Vector(center) + d * r * rnd.uniform(0.7, 1.15), r * rnd.uniform(0.16, 0.34), (1, 1, 1), outer[0], 10))
        objs.append(obj("FireOuter", W.merge(*puffs), flat_mat("fouter", outer[0], emit=outer[1]), Matrix()))
    light("POINT", center, color, power, r)
    return objs


def _fire_shell(name, r, seed, lump, ramp, strength, rim=False, heat_scale=1.0):
    """one skin of a fireball: a noise-lumped ball whose colour runs from white-hot where it
    faces us to red at its rim. Solid, or (rim) only its edge shows: flames round a core"""
    from mathutils import noise
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=r)
    off = Vector((seed * 3.1, seed * 1.7, seed * 2.3))
    for v in bm.verts:
        n = v.co.normalized()
        v.co = n * r * (1 + lump * noise.fractal(n * 1.1 + off, 0.5, 2.0, 3))
    paint(bm, (1, 1, 1))
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes.get("Principled BSDF"))
    out = nt.nodes.get("Material Output")
    lw = nt.nodes.new("ShaderNodeLayerWeight"); lw.inputs["Blend"].default_value = 0.5
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 3.0; nz.inputs["Detail"].default_value = 6.0
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    # heat = 1 - facing, torn a little by noise
    inv = nt.nodes.new("ShaderNodeMath"); inv.operation = "SUBTRACT"; inv.inputs[0].default_value = 1.0
    nt.links.new(lw.outputs["Facing"], inv.inputs[1])
    nm = nt.nodes.new("ShaderNodeMath"); nm.operation = "MULTIPLY_ADD"
    nt.links.new(nz.outputs["Fac"], nm.inputs[0]); nm.inputs[1].default_value = 0.7; nm.inputs[2].default_value = -0.35
    heat = nt.nodes.new("ShaderNodeMath"); heat.operation = "ADD"; heat.use_clamp = True
    nt.links.new(inv.outputs["Value"], heat.inputs[0]); nt.links.new(nm.outputs["Value"], heat.inputs[1])
    cr = nt.nodes.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    while len(els) < len(ramp):
        els.new(0.5)
    for e, (pos, col) in zip(els, ramp):
        e.position = pos
        e.color = (*col, 1)
    hs = nt.nodes.new("ShaderNodeMath"); hs.operation = "MULTIPLY"; hs.inputs[1].default_value = heat_scale
    nt.links.new(heat.outputs["Value"], hs.inputs[0])
    nt.links.new(hs.outputs["Value"], cr.inputs["Fac"])
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs["Strength"].default_value = strength
    nt.links.new(cr.outputs["Color"], em.inputs["Color"])
    if not rim:
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
        return bm, m
    # a rim skin: clear where it faces us (the core shows through), licks of flame toward the
    # edge, fading out at the very silhouette: alpha = 4·h·(1 - h) (h = heat)
    one = nt.nodes.new("ShaderNodeMath"); one.operation = "SUBTRACT"; one.inputs[0].default_value = 1.0
    nt.links.new(heat.outputs["Value"], one.inputs[1])
    pr = nt.nodes.new("ShaderNodeMath"); pr.operation = "MULTIPLY"
    nt.links.new(heat.outputs["Value"], pr.inputs[0]); nt.links.new(one.outputs["Value"], pr.inputs[1])
    al = nt.nodes.new("ShaderNodeMath"); al.operation = "MULTIPLY"; al.inputs[1].default_value = 4.0; al.use_clamp = True
    nt.links.new(pr.outputs["Value"], al.inputs[0])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(al.outputs["Value"], mix.inputs["Fac"])
    nt.links.new(tr.outputs["BSDF"], mix.inputs[1]); nt.links.new(em.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    return bm, m


FIRE_RAMP = ((0.0, (0.45, 0.01, 0.0)), (0.3, (0.9, 0.08, 0.0)), (0.55, (1.0, 0.3, 0.0)), (0.8, (1.0, 0.62, 0.1)), (1.0, (1.0, 0.9, 0.55)))


def fire(center, r=1.2, strength=2.0, seed=5, power=3000, light_color=rgb(255, 110, 20), ramp=FIRE_RAMP, stretch=(1, 1, 1)):
    """a fireball: two lumpy skins (an outer red-orange one, softer, and a hot inner one);
    keep `strength` low (~2): AgX bleaches bright emission to white. stretch (1, 1, 1.8): a
    blaze rising off a wall rather than a ball"""
    objs = []
    for k, (rr, lump, st, rim, hsc) in enumerate(((1.0, 0.26, strength * 0.8, True, 0.75), (0.66, 0.14, strength, False, 1.0))):
        bm, m = _fire_shell(f"Fire{seed}_{k}", r * rr, seed + k * 7, lump, ramp, st, rim, hsc)
        o = obj(f"Fire{k}", bm, m, T(*center) @ Matrix.Diagonal((*stretch, 1)))
        o.data.shade_smooth()   # (no sharp edges: flames have no facets)
        try:
            o.data.shade_smooth(keep_sharp_edges=False)
        except TypeError:
            pass
        o.visible_shadow = False
        objs.append(o)
    if power:
        light("POINT", center, light_color, power, r * 0.6)
    return objs


def blaze(base, size=1.5, seed=1, power=1500, strength=2.4):
    """a fire burning ON something (a wall top): tongues of flame stacked up from `base`, each
    smaller and higher than the last, leaning a little, the light at its heart"""
    rnd = random.Random(seed)
    b = Vector(base)
    out = []
    z = 0.0
    for k in range(5):
        r = size * (1.0 - k * 0.17)
        off = Vector((rnd.uniform(-0.3, 0.3) * size, rnd.uniform(-0.2, 0.2) * size, z + r * 0.6))
        out += fire(tuple(b + off), r=r, strength=strength * (1.15 - k * 0.08), power=0, seed=seed * 10 + k, stretch=(0.85, 0.85, 1.6))
        z += r * 0.95
    light("POINT", tuple(b + Vector((0, 0, size))), rgb(255, 110, 30), power, size)
    return out


def where(label, point):
    """prints where a world point lands in the frame (0..1 across, 0..1 up): for laying out"""
    from bpy_extras.object_utils import world_to_camera_view
    sc = bpy.context.scene
    v = world_to_camera_view(sc, sc.camera, Vector(point))
    print(f"WHERE {label}: x {v.x:.2f}  y {v.y:.2f}  depth {v.z:.1f}")
    return v


def trail(points, radius, color, strength=20, name="Trail"):
    bm = W.tube([tuple(p) for p in points], radius, color)
    return obj(name, bm, flat_mat(name, color, emit=strength), Matrix())


# --------------------------------------------------------------------------
#  THE STAGE
# --------------------------------------------------------------------------
def stone_mat(base=rgb(120, 112, 100), dark=rgb(70, 64, 58), scale=1.6):
    m = bpy.data.materials.new("stone")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    tex = nt.nodes.new("ShaderNodeTexVoronoi"); tex.inputs["Scale"].default_value = scale * 0.35
    nt.links.new(tc.outputs["Object"], tex.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*dark, 1); ramp.color_ramp.elements[1].color = (*base, 1)
    ramp.color_ramp.elements[0].position = 0.02; ramp.color_ramp.elements[1].position = 0.12
    nt.links.new(tex.outputs["Distance"], ramp.inputs["Fac"])
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 0.6
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 0.35
    nt.links.new(ramp.outputs["Color"], mix.inputs["A"]); nt.links.new(noise.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.85
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.4
    nt.links.new(tex.outputs["Distance"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def ground(size=200, material=None):
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size / 2)
    paint(bm, (1, 1, 1))
    me = bpy.data.meshes.new("Ground"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("Ground", me); bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(material or stone_mat())
    return o


def block(name, center, size, material, rot_z=0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    M = Matrix.Translation(Vector(center)) @ Matrix.Rotation(D(rot_z), 4, "Z") @ Matrix.Diagonal((*size, 1))
    for v in bm.verts:
        v.co = M @ v.co
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(material)
    return o


def tower(center, r, h, material, roof=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=r, radius2=r, depth=h)
    for v in bm.verts:
        v.co += Vector((center[0], center[1], center[2] + h / 2))
    me = bpy.data.meshes.new("Tower"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("Tower", me); bpy.context.scene.collection.objects.link(o); o.data.materials.append(material)
    out = [o]
    for i in range(10):   # crenellations
        a = i / 10 * 2 * math.pi
        out.append(block("Merlon", (center[0] + math.cos(a) * r * 0.9, center[1] + math.sin(a) * r * 0.9, center[2] + h + 0.45), (0.9, 0.9, 0.9), material, math.degrees(a)))
    if roof:
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=r * 1.1, radius2=0, depth=r * 2.2)
        for v in bm.verts:
            v.co += Vector((center[0], center[1], center[2] + h + r * 1.1 + 0.9))
        me = bpy.data.meshes.new("Roof"); bm.to_mesh(me); bm.free()
        ro = bpy.data.objects.new("Roof", me); bpy.context.scene.collection.objects.link(ro); ro.data.materials.append(roof)
        out.append(ro)
    return out


def wall(a, b, h, thick, material):
    a, b = Vector(a), Vector(b)
    mid = (a + b) / 2
    d = b - a
    yaw = math.degrees(math.atan2(d.y, d.x))
    out = [block("Wall", (mid.x, mid.y, mid.z + h / 2), (d.length, thick, h), material, yaw)]
    n = int(d.length / 1.6)
    for i in range(n):
        p = a + d * ((i + 0.5) / n)
        out.append(block("Merlon", (p.x, p.y, p.z + h + 0.4), (0.8, thick, 0.8), material, yaw))
    return out


def banner(top, height, width, color, emblem=None, material_pole=None):
    out = [block("Pole", (top[0], top[1], top[2] - height / 2), (0.15, 0.15, height + 1), material_pole or flat_mat("pole", rgb(70, 50, 30)))]
    out.append(block("Banner", (top[0], top[1] - 0.05, top[2] - height * 0.35), (width, 0.05, height * 0.6), flat_mat("banner", color, rough=0.9)))
    return out


def sky(top=rgb(30, 20, 60), horizon=rgb(255, 120, 50), strength=1.0, ground_col=None, band=0.3):
    w = bpy.data.worlds.new("Sky")
    bpy.context.scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes.get("Background")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    # (the direction's Z: 0 at the horizon, 1 straight up; below it, the horizon's colour)
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*horizon, 1); ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[1].color = (*top, 1); ramp.color_ramp.elements[1].position = band
    mid = tuple((h * 0.45 + t * 0.55) for h, t in zip(horizon, top))
    e = ramp.color_ramp.elements.new(band * 0.25); e.color = (*mid, 1)
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength
    return w


def fog(density=0.02, color=(1, 1, 1), anisotropy=0.3, size=(160, 160, 40), center=(0, 30, 18)):
    """haze in a big box round the stage (a world volume would swallow the sky behind it)"""
    m = bpy.data.materials.new("fog")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes.get("Principled BSDF"))
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = density
    vol.inputs["Color"].default_value = (*color, 1)
    vol.inputs["Anisotropy"].default_value = anisotropy
    nt.links.new(vol.outputs["Volume"], nt.nodes.get("Material Output").inputs["Volume"])
    o = block("Fog", center, size, m)
    o.visible_shadow = False
    return o


# --------------------------------------------------------------------------
#  TYPE
# --------------------------------------------------------------------------
FONT = "C:/Windows/Fonts/impact.ttf"


def _text(body, size, font, extrude, offset=0.0, bevel=0.0):
    cu = bpy.data.curves.new("T", "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(font, check_existing=True)
    cu.size = size
    cu.align_x = "CENTER"; cu.align_y = "CENTER"
    cu.extrude = extrude
    cu.offset = offset
    cu.bevel_depth = bevel
    o = bpy.data.objects.new("Title", cu)
    bpy.context.scene.collection.objects.link(o)
    return o


def gradient_mat(top, bottom, emit=0.6, metallic=0.3):
    m = bpy.data.materials.new("titlefill")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*bottom, 1); ramp.color_ramp.elements[1].color = (*top, 1)
    ramp.color_ramp.elements[0].position = 0.25; ramp.color_ramp.elements[1].position = 0.8
    nt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = emit
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = 0.3
    return m


def title(body, cam, dist=10, x=0.0, y=0.0, size=1.0, fill=(rgb(255, 236, 140), rgb(255, 140, 20)), outline=rgb(40, 16, 6),
          font=FONT, tilt=0.0, outline_w=0.07, emit=0.8, plate=None):
    """big type facing the camera, `dist` in front of it, at (x, y) in the camera's own plane;
    plate = a colour: a banner of it behind the words"""
    M = cam.matrix_world @ T(x, y, -dist) @ R(0, 0, tilt)
    front = _text(body, size, font, 0.08, 0.0, 0.015)
    front.matrix_world = M
    front.data.materials.append(gradient_mat(*fill, emit=emit))
    if plate:
        bpy.context.view_layer.update()
        w, h = front.dimensions.x + size * 0.9, front.dimensions.y + size * 0.45
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for v in bm.verts:   # a banner with swallowtail-ish slanted ends
            v.co.x *= w * (1 if v.co.y > 0 else 0.94)
            v.co.y *= h; v.co.z *= 0.06
        paint(bm, plate)
        obj("Plate", bm, flat_mat("plate", plate, rough=0.6, emit=0.3), M @ T(0, 0, -0.3))
    back = _text(body, size, font, 0.14, outline_w * size, 0.0)
    back.matrix_world = M @ T(0, 0, -0.1)
    back.data.materials.append(flat_mat("outline", outline, rough=0.6))
    shadow = _text(body, size, font, 0.02, outline_w * size * 1.2, 0.0)
    shadow.matrix_world = M @ T(0.06 * size, -0.08 * size, -0.25)
    shadow.data.materials.append(flat_mat("shadow", (0, 0, 0), rough=1))
    return [front, back, shadow]


# --------------------------------------------------------------------------
#  CAMERA, RENDER
# --------------------------------------------------------------------------
def camera(loc, target, lens=35, focus=None, fstop=4.0):
    cd = bpy.data.cameras.new("Cam")
    cd.lens = lens
    o = bpy.data.objects.new("Cam", cd)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    d = Vector(target) - Vector(loc)
    o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = o
    if focus is not None:
        cd.dof.use_dof = True
        cd.dof.focus_distance = (Vector(focus) - Vector(loc)).length
        cd.dof.aperture_fstop = fstop
    bpy.context.view_layer.update()
    return o


def setup(res=(1920, 1080), samples=256, preview=False, scale=None):
    """scale: the share of `res` rendered (preview: 0.5); a quarter (0.25) for quick layouts"""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = res
    scale = scale or (0.5 if preview else 1.0)
    sc.render.resolution_percentage = int(scale * 100)
    sc.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = d.type == "OPTIX"
        sc.cycles.device = "GPU"
    except Exception as e:
        print("GPU setup failed:", e)
    sc.cycles.samples = (12 if scale <= 0.25 else 48) if scale < 1 else samples
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 6
    sc.cycles.volume_step_rate = 4
    try:
        sc.view_settings.view_transform = "AgX"
        sc.view_settings.look = "AgX - Punchy"
    except Exception as e:
        print("look:", e)
    return sc


def bloom(strength=0.6, threshold=1.0, size=0.6, kind="Bloom", saturation=1.0):
    sc = bpy.context.scene
    ng = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
    ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    rl = ng.nodes.new("CompositorNodeRLayers")
    gl = ng.nodes.new("CompositorNodeGlare")
    try:
        gl.inputs["Type"].default_value = kind
    except Exception as e:
        print("glare type:", e)
    for k, v in (("Threshold", threshold), ("Strength", strength), ("Size", size)):
        try: gl.inputs[k].default_value = v
        except Exception: pass
    out = ng.nodes.new("NodeGroupOutput")
    ng.links.new(rl.outputs["Image"], gl.inputs["Image"])
    last = gl.outputs["Image"]
    if saturation != 1.0:   # (a touch more colour, the way store art is graded)
        try:
            hs = ng.nodes.new("CompositorNodeHueSat")
            hs.inputs["Saturation"].default_value = saturation
            ng.links.new(last, hs.inputs["Image"])
            last = hs.outputs["Image"]
        except Exception as e:
            print("saturation:", e)
    ng.links.new(last, out.inputs["Image"])
    sc.compositing_node_group = ng
    sc.render.use_compositing = True


def render(path):
    sc = bpy.context.scene
    sc.render.filepath = path
    sc.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


# --------------------------------------------------------------------------
#  TITLES AS A LAYER: crisp type with exact colours (no tonemapping), composited over
#  the render — a gradient fill, a thick dark outline, a drop shadow, an optional banner
# --------------------------------------------------------------------------
def _emit_gradient(top, bottom, name="fill"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes.get("Principled BSDF"))
    em = nt.nodes.new("ShaderNodeEmission")
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Generated"], sep.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*bottom, 1); ramp.color_ramp.elements[0].position = 0.2
    ramp.color_ramp.elements[1].color = (*top, 1); ramp.color_ramp.elements[1].position = 0.75
    nt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], nt.nodes.get("Material Output").inputs["Surface"])
    return m


def overlay(items, res, path):
    """items: dicts {text, x, y, size (in units of the frame's height = 10), fill = (top, bottom),
    outline, ow (outline width as a share of size), shadow = True, plate = colour, font, tilt}.
    The frame: x from -W/2 to W/2 (W = 10 × aspect), y from -5 to 5. Writes an RGBA PNG."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 16
    sc.cycles.use_denoising = False
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    cd = bpy.data.cameras.new("Cam"); cd.type = "ORTHO"; cd.ortho_scale = 10 * res[0] / res[1]
    cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = (0, 0, 50)
    for it in items:
        size = it.get("size", 1.0)
        font = it.get("font", FONT)
        base = T(it.get("x", 0), it.get("y", 0), 0) @ R(0, 0, it.get("tilt", 0))
        front = _text(it["text"], size, font, 0.0, 0.0, 0.0)
        front.matrix_world = base @ T(0, 0, 3)
        fill = it.get("fill", (rgb(255, 244, 110), rgb(255, 128, 0)))
        front.data.materials.append(_emit_gradient(*fill))
        # (the outline: copies of the words in a ring round them; a curve offset spikes at corners)
        ow = it.get("ow", 0.09) * size
        om = _emit_gradient(it.get("outline", rgb(36, 14, 4)), it.get("outline", rgb(36, 14, 4)), "outline")
        sm = _emit_gradient((0, 0, 0), (0, 0, 0), "shadow")
        for k in range(20):
            a = k / 20 * 2 * math.pi
            o = _text(it["text"], size, font, 0.0, 0.0, 0.0)
            o.matrix_world = base @ T(math.cos(a) * ow, math.sin(a) * ow, 2)
            o.data.materials.append(om)
            if it.get("shadow", True) and k % 2 == 0:
                sh = _text(it["text"], size, font, 0.0, 0.0, 0.0)
                sh.matrix_world = base @ T(math.cos(a) * ow * 1.1 + size * 0.05, math.sin(a) * ow * 1.1 - size * 0.09, 1)
                sh.data.materials.append(sm)
        if it.get("plate"):
            bpy.context.view_layer.update()
            w, h = front.dimensions.x + size * 1.0, front.dimensions.y + size * 0.55
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            for v in bm.verts:
                v.co.x *= w; v.co.y *= h; v.co.z *= 0.01
            pl = obj("Plate", bm, _emit_gradient(it["plate"], tuple(c * 0.7 for c in it["plate"]), "plate"), base @ T(0, -size * 0.04, 0))
            pb = bmesh.new(); bmesh.ops.create_cube(pb, size=1.0)
            for v in pb.verts:
                v.co.x *= w + size * 0.16; v.co.y *= h + size * 0.16; v.co.z *= 0.01
            obj("PlateEdge", pb, _emit_gradient(it.get("plate_edge", rgb(255, 210, 90)), it.get("plate_edge", rgb(255, 210, 90)), "edge"), base @ T(0, -size * 0.04, -0.5))
    sc.render.filepath = path
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    bpy.ops.render.render(write_still=True)


def compose(base_png, overlay_png, out_png, res):
    """the overlay laid over the render (alpha over), written out"""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.view_settings.view_transform = "Standard"
    cd = bpy.data.cameras.new("Cam"); cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    sc.render.engine = "BLENDER_EEVEE"
    ng = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
    ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
    a = ng.nodes.new("CompositorNodeImage"); a.image = bpy.data.images.load(base_png)
    b = ng.nodes.new("CompositorNodeImage"); b.image = bpy.data.images.load(overlay_png)
    for im in (a.image, b.image):
        im.colorspace_settings.name = "sRGB"
    over = ng.nodes.new("CompositorNodeAlphaOver")
    outn = ng.nodes.new("NodeGroupOutput")
    ins = [i for i in over.inputs if i.type == "RGBA"]
    ng.links.new(a.outputs["Image"], ins[0])
    ng.links.new(b.outputs["Image"], ins[1])
    ng.links.new(over.outputs["Image"], outn.inputs["Image"])
    sc.compositing_node_group = ng
    sc.render.use_compositing = True
    sc.render.filepath = out_png
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    bpy.ops.render.render(write_still=True)
    print("COMPOSED", out_png)
