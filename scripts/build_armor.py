"""Armor / hair / beard / face meshes — blueprint JSON → Blender → Open Cloud → MeshArmor snippet.

    python scripts/build_armor.py                 # everything in blender/out/blueprints.json
    python scripts/build_armor.py RoadLevy Hair   # only these sets / piece ids / body kinds
    python scripts/build_armor.py --no-upload     # Blender only
    python scripts/build_armor.py --upload-only   # no Blender: upload what the last bake left without ids
    python scripts/build_armor.py --under         # only under_armor.lua: each model's Under (see below)

blender/out/blueprints.json comes from Studio (the Build ▸ Armor / Body specs;
see blender/parts2mesh.py). Outputs land in blender/out/armor/: one FBX per
region, <Model>.json with centres + asset ids, and assemble_armor.lua (run it
in Studio edit mode through the command bar or the Studio MCP). Asset ids
never leave blender/out (gitignored).

Each torso / arm / leg model also gets an Under: what the Dresser paints the
limb beneath it (a shade of it), so a gap between plates shows cloth, not
skin. It is the colour of the model's biggest part, the base garment: a
ColorSlot name, or the part's own colour when it is vertex-coloured (Fixed).
--under writes under_armor.lua, which sets just that on models already built.
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "armor")
SRC = os.path.join(ROOT, "blender", "out", "blueprints.json")
BLENDER = os.environ.get("BLENDER", r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe")
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from upload_asset import upload  # noqa: E402


UNDER_SLOTS = ("TorsoClothing", "LeftArmClothing", "RightArmClothing", "LeftLegClothing", "RightLegClothing")


def blueprint_models():
    """{"<Set>/<Slot>" or "Pieces/<id>/<Slot>": [spec, ...]} from blueprints.json"""
    data = json.load(open(SRC, encoding="utf-8"))
    out = {}
    for s, slots in data.get("sets", {}).items():
        for slot, specs in slots.items():
            out[f"{s}/{slot}"] = specs
    for pid, slots in data.get("pieces", {}).items():
        for slot, specs in slots.items():
            out[f"Pieces/{pid}/{slot}"] = specs
    return out


def under_of(specs):
    """the base garment: the biggest part (by its box) — its ColorSlot name, or
    for a Fixed part its colour (r, g, b). Trim, studs and stitching are many
    but small; the shell round the limb is the one big piece."""
    best, vol = None, 0
    for sp in specs:
        if sp.get("t", 0) > 0.9:
            continue
        x, y, z = sp["s"]
        if x * y * z > vol:
            best, vol = sp, x * y * z
    if best is None:
        return None
    slot = (best.get("a") or {}).get("ColorSlot")
    return slot or tuple(round(v, 3) for v in best["c"])


def under_lua(u):
    return f'"{u}"' if isinstance(u, str) else "{%.3f, %.3f, %.3f}" % u


def write_under():
    lua = ["-- each model's Under (scripts/build_armor.py --under); run in Studio edit mode",
           "local ServerStorage, ReplicatedStorage = game:GetService(\"ServerStorage\"), game:GetService(\"ReplicatedStorage\")",
           "local n = 0",
           "local function set(path, u)",
           "\tlocal a, b, c = path:match(\"^([^/]+)/([^/]+)/?([^/]*)$\")",
           "\tlocal m",
           "\tif a == \"Pieces\" then",
           "\t\tlocal f = ReplicatedStorage:FindFirstChild(\"Cosmetics\") and ReplicatedStorage.Cosmetics:FindFirstChild(\"Pieces\")",
           "\t\tm = f and f:FindFirstChild(b) and f[b]:FindFirstChild(c)",
           "\telse",
           "\t\tlocal f = ServerStorage:FindFirstChild(\"Armor\")",
           "\t\tm = f and f:FindFirstChild(a) and f[a]:FindFirstChild(b)",
           "\tend",
           "\tif not m then return end",
           "\tm:SetAttribute(\"Under\", type(u) == \"table\" and Color3.new(u[1], u[2], u[3]) or u)",
           "\tn += 1",
           "end"]
    for name, specs in sorted(blueprint_models().items()):
        if name.split("/")[-1] in UNDER_SLOTS:
            u = under_of(specs)
            if u is not None:
                lua.append(f'set("{name}", {under_lua(u)})')
    lua.append('return "under set on " .. n .. " models"')
    path = os.path.join(OUT, "under_armor.lua")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")
    print("wrote", path)


def main():
    argv = sys.argv[1:]
    if "--under" in argv:
        return write_under()
    do_upload = "--no-upload" not in argv
    only = [a for a in argv if not a.startswith("--")]
    specs_of = blueprint_models() if os.path.exists(SRC) else {}
    if "--upload-only" in argv:
        # resume: every model the last bake wrote (that `only` names), uploading regions still without an id
        names = []
        for fn in sorted(os.listdir(OUT)):
            if not fn.endswith(".json"):
                continue
            model = json.load(open(os.path.join(OUT, fn), encoding="utf-8")).get("model")
            parts = (model or "").split("/")
            if model and (not only or model in only or parts[0] in only
                          or (parts[0] in ("Pieces", "Body") and len(parts) > 1 and parts[1] in only)):
                names.append(model)
        if "--reverse" in argv:   # a second uploader can work from the other end
            names.reverse()
    else:
        cmd = [BLENDER, "-b", "--python", os.path.join(ROOT, "blender", "parts2mesh.py"), "--", SRC, "--out", OUT]
        if only:
            cmd += ["--only", ",".join(only)]
        r = subprocess.run(cmd, capture_output=True, text=True)
        wrote = [l for l in r.stdout.splitlines() if l.startswith("WROTE")]
        if r.returncode != 0 or not wrote:
            sys.exit("blender failed:\n" + r.stdout[-3000:] + r.stderr[-3000:])
        print(f"blender wrote {len(wrote)} models")
        names = [l.split(" ", 2)[1] for l in wrote]
    lua = ["local MeshArmor = require(game.ServerScriptService.Build.MeshArmor)", "local n = 0"]
    for name in names:
        safe = name.replace("/", "_")
        meta_path = os.path.join(OUT, safe + ".json")
        meta = json.load(open(meta_path, encoding="utf-8"))
        for region, rg in meta["regions"].items():
            if do_upload and not rg.get("id"):
                rg["id"] = upload(os.path.join(OUT, rg["file"]), "Model", f"{safe} {region}", quiet=True)
                print("uploaded", safe, region)
        json.dump(meta, open(meta_path, "w", encoding="utf-8"), indent=1)
        regions = ", ".join(
            f'{reg} = {{id = {rg.get("id", 0)}, material = "{rg.get("material", "SmoothPlastic")}", center = {{{rg["center"][0]:.4f}, {rg["center"][1]:.4f}, {rg["center"][2]:.4f}}}}}'
            for reg, rg in meta["regions"].items())
        u = under_of(specs_of[name]) if name.split("/")[-1] in UNDER_SLOTS and name in specs_of else None
        under = f", under = {under_lua(u)}" if u is not None else ""
        lua.append(f'MeshArmor.build({{path = "{name}"{under}, regions = {{{regions}}}}}); n += 1')
    lua.append('print("[MeshArmor] built", n, "models")')
    with open(os.path.join(OUT, "assemble_armor.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")
    print("wrote", os.path.join(OUT, "assemble_armor.lua"), len(names), "models")


if __name__ == "__main__":
    main()
