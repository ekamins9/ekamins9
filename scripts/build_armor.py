"""Armor / hair / beard / face meshes — blueprint JSON → Blender → Open Cloud → MeshArmor snippet.

    python scripts/build_armor.py                 # everything in blender/out/blueprints.json
    python scripts/build_armor.py RoadLevy Hair   # only these sets / piece ids / body kinds
    python scripts/build_armor.py --no-upload     # Blender only
    python scripts/build_armor.py --upload-only   # no Blender: upload what the last bake left without ids

blender/out/blueprints.json comes from Studio (the Build ▸ Armor / Body specs;
see blender/parts2mesh.py). Outputs land in blender/out/armor/: one FBX per
region, <Model>.json with centres + asset ids, and assemble_armor.lua (run it
in Studio edit mode through the command bar or the Studio MCP). Asset ids
never leave blender/out (gitignored).
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "armor")
SRC = os.path.join(ROOT, "blender", "out", "blueprints.json")
BLENDER = os.environ.get("BLENDER", r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe")
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from upload_asset import upload  # noqa: E402


def main():
    argv = sys.argv[1:]
    do_upload = "--no-upload" not in argv
    only = [a for a in argv if not a.startswith("--")]
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
        lua.append(f'MeshArmor.build({{path = "{name}", regions = {{{regions}}}}}); n += 1')
    lua.append('print("[MeshArmor] built", n, "models")')
    with open(os.path.join(OUT, "assemble_armor.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")
    print("wrote", os.path.join(OUT, "assemble_armor.lua"), len(names), "models")


if __name__ == "__main__":
    main()
