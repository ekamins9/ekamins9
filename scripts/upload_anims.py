"""Upload the AnimForge clips (blender/out/anims/<Class>__<Clip>.rbxm) as Roblox
Animations, resumably, and print the Studio snippet that puts them in place.

    python scripts/upload_anims.py            # upload what isn't uploaded yet
    python scripts/upload_anims.py --lua      # just print the Studio snippet

Ids go to blender/out/anims/uploads.json (gitignored) and into Studio as
ReplicatedStorage ▸ Animations ▸ <Class> ▸ <Clip> (Animation instances, with
the clip's Load / Through / Settle marks as attributes). Never into code.
"""
import json, os, sys, threading
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from upload_asset import upload  # noqa: E402

DIR = os.path.join(ROOT, "blender", "out", "anims")
DB = os.path.join(DIR, "uploads.json")
HELD = {"Idle", "Block", "Hit"}
MARKS = {"Load": 0.30, "Through": 0.60, "Settle": 1.05}   # AnimForge WINDUP / STRIKE / FOLLOW
lock = threading.Lock()


def load_db():
    return json.load(open(DB)) if os.path.exists(DB) else {}


def save_db(db):
    with lock:
        json.dump(db, open(DB, "w"), indent=1, sort_keys=True)


def lua(db):
    rows = []
    for key, aid in sorted(db.items()):
        cls, clip = key.split("__")
        rows.append('{"%s", "%s", %d}' % (cls, clip, aid))
    marks = ", ".join("%s = %s" % kv for kv in MARKS.items())
    return """local RS = game:GetService("ReplicatedStorage")
local root = RS:FindFirstChild("Animations") or Instance.new("Folder")
root.Name = "Animations"; root.Parent = RS
if root:GetAttribute("Style") == nil then root:SetAttribute("Style", "Forged") end
local HELD = {Idle = true, Block = true, Hit = true}
local n = 0
for _, e in ipairs({%s}) do
	local f = root:FindFirstChild(e[1]) or Instance.new("Folder")
	f.Name = e[1]; f.Parent = root
	local a = f:FindFirstChild(e[2]) or Instance.new("Animation")
	a.Name = e[2]; a.AnimationId = "rbxassetid://" .. e[3]; a.Parent = f
	if not HELD[e[2]] then for k, v in pairs({%s}) do a:SetAttribute(k, v) end end
	n += 1
end
return n .. " animations in ReplicatedStorage.Animations"
""" % (", ".join(rows), marks)


def main():
    db = load_db()
    if "--lua" not in sys.argv:
        todo = [f[:-5] for f in sorted(os.listdir(DIR)) if f.endswith(".rbxm") and f[:-5] not in db]
        print(len(todo), "to upload", flush=True)

        def one(key):
            aid = upload(os.path.join(DIR, key + ".rbxm"), "Animation", key.replace("__", " "), "R6 melee combat animation", quiet=True)
            with lock:
                db[key] = aid
            save_db(db)
            print("uploaded", key, flush=True)

        with ThreadPoolExecutor(4) as ex:
            list(ex.map(one, todo))
    out = os.path.join(DIR, "studio_entries.lua")
    open(out, "w", encoding="utf-8").write(lua(db))
    print("studio snippet:", out, "(", len(db), "clips )")


if __name__ == "__main__":
    main()
