"""Build, upload and assemble weapon meshes — the whole pipeline in one go.

    python scripts/build_weapons.py Longsword Greatsword     # these
    python scripts/build_weapons.py all                       # every weapon in blender/weapons.py
    python scripts/build_weapons.py all --no-upload           # just the Blender step
    python scripts/build_weapons.py all --upload-only         # no Blender: finish the uploads, write assemble.lua

Steps per weapon:
  1. Blender headless (blender/weapons.py) → blender/out/<W>_Blade.fbx, <W>_Grip.fbx, <W>.json
  2. Open Cloud upload (scripts/upload_asset.py) → asset ids written into <W>.json ("id" per region)
  3. blender/out/assemble.lua: a Luau snippet calling Build ▸ MeshTool.build for every weapon
     built this run — paste it in the Studio command bar (or run it through the Studio MCP).
Asset ids stay in blender/out (gitignored): never in the repo.
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out")
BLENDER = os.environ.get("BLENDER", r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe")
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from upload_asset import upload  # noqa: E402

# Handle length, hitbox span and cross-section per weapon (studs, Tool frame)
# — keep in step with the shapes in blender/weapons.py
GRIPS = {
    "Longsword": (0.95, 0.55, 3.9, 0.6), "ArmingSword": (0.62, 0.4, 3.05, 0.6), "Shortsword": (0.55, 0.35, 2.6, 0.55),
    "Greatsword": (1.2, 0.7, 4.75, 0.65), "Zweihander": (1.4, 0.8, 5.9, 0.7), "Executioner": (1.2, 0.7, 4.35, 0.75),
    "Estoc": (1.0, 0.6, 4.05, 0.45), "Rapier": (0.6, 0.4, 3.6, 0.4), "Dagger": (0.45, 0.3, 1.45, 0.4),
    "Falchion": (0.6, 0.4, 2.85, 0.8), "Messer": (0.9, 0.55, 3.6, 0.7), "Cleaver": (0.5, 0.3, 2.25, 0.95),
    "Hammer": (0.7, 1.2, 1.9, 1.0), "Mace": (0.8, 1.15, 2.0, 1.0), "MorningStar": (0.9, 1.35, 2.5, 1.1), "Maul": (1.0, 2.1, 3.35, 1.3),
    "WarAxe": (0.8, 0.8, 1.95, 1.6), "BattleAxe": (1.1, 1.4, 3.3, 2.0), "Bardiche": (1.1, 1.4, 4.0, 1.6),
    "Spear": (0.9, 3.2, 4.9, 0.7), "Pitchfork": (0.9, 3.2, 4.65, 1.1), "Halberd": (1.0, 2.3, 4.75, 1.9),
    "Poleaxe": (1.0, 2.3, 4.35, 1.6), "Glaive": (1.0, 3.3, 5.65, 0.9), "Billhook": (1.0, 3.1, 5.3, 1.4),
    "Quarterstaff": (1.0, 0.6, 2.75, 0.5),
}


def run_blender(names):
    cmd = [BLENDER, "-b", "--python", os.path.join(ROOT, "blender", "weapons.py"), "--", *names, "--out", OUT]
    r = subprocess.run(cmd, capture_output=True, text=True)
    wrote = [l for l in r.stdout.splitlines() if l.startswith("WROTE")]
    if r.returncode != 0 or not wrote:
        sys.exit("blender failed:\n" + r.stdout[-2000:] + r.stderr[-2000:])
    for l in wrote:
        print(l)


def main():
    argv = sys.argv[1:]
    do_upload = "--no-upload" not in argv
    resume = "--upload-only" in argv   # no Blender: upload the regions the last bake left without ids
    argv = [a for a in argv if not a.startswith("--")]
    names = argv or ["all"]
    if not resume:
        run_blender(names)
    if names == ["all"]:
        # every weapon's <name>.json in blender/out (blueprints.json and the rest are not weapons)
        names = []
        for f in sorted(os.listdir(OUT)):
            if f.endswith(".json"):
                try:
                    if "weapon" in json.load(open(os.path.join(OUT, f), encoding="utf-8")):
                        names.append(f[:-5])
                except (ValueError, OSError):
                    pass
    lua = ["local MeshTool = require(game.ServerScriptService.Build.MeshTool)", "local built = {}"]
    for n in names:
        meta_path = os.path.join(OUT, n + ".json")
        meta = json.load(open(meta_path, encoding="utf-8"))
        for region, r in meta["regions"].items():
            if do_upload and not (resume and r.get("id")):
                r["id"] = upload(os.path.join(OUT, r["file"]), "Model", f"{n} {region}", quiet=True)
                print(f"uploaded {n} {region}")
        json.dump(meta, open(meta_path, "w", encoding="utf-8"), indent=1)
        g = GRIPS.get(n, (0.8, 0.5, 3.0, 0.6))
        regions = ", ".join(
            f'{reg} = {{id = {r.get("id", 0)}, material = "{"Metal" if reg == "Blade" else "SmoothPlastic"}", center = {{{r["center"][0]:.4f}, {r["center"][1]:.4f}, {r["center"][2]:.4f}}}, size = {{{r["size"][0]:.3f}, {r["size"][1]:.3f}, {r["size"][2]:.3f}}}}}'
            for reg, r in meta["regions"].items())
        lua.append(f'built[#built + 1] = MeshTool.build({{name = "{n}", grip = {g[0]}, hitbox = {{y0 = {g[1]}, y1 = {g[2]}, cross = {g[3]}}}, regions = {{{regions}}}}}).Name')
    lua.append('print("[MeshTool] built", table.concat(built, ", "))')
    with open(os.path.join(OUT, "assemble.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")
    print("wrote", os.path.join(OUT, "assemble.lua"))


if __name__ == "__main__":
    main()
