"""Upload every Forge skin mesh (blender/out/skins/*.fbx) to Roblox, a few at a
time, remembering what is done in blender/out/skins/uploads.json (gitignored:
asset ids never go in the repo). A mesh whose file changed since its upload is
sent again; everything else is skipped, so this can be stopped and re-run.

    python scripts/upload_skins.py [--threads 4] [--only Longsword__Gilded]

Then Studio assembles the models: Build ▸ SkinModels (see roblox/README.md).
"""
import argparse, glob, hashlib, json, os, sys, threading, time
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
import upload_asset  # noqa: E402

SKINS = os.path.join(ROOT, "blender", "out", "skins")
DB = os.path.join(SKINS, "uploads.json")
lock = threading.Lock()


def digest(path):
    with open(path, "rb") as f:
        return hashlib.sha1(f.read()).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--threads", type=int, default=4)
    ap.add_argument("--only")
    a = ap.parse_args()
    db = json.load(open(DB)) if os.path.exists(DB) else {}
    todo = []
    for p in sorted(glob.glob(os.path.join(SKINS, "*.fbx"))):
        name = os.path.basename(p)
        if a.only and a.only not in name:
            continue
        h = digest(p)
        if db.get(name, {}).get("sha") == h:
            continue
        todo.append((p, name, h))
    print(f"{len(todo)} to upload, {len(db)} already up", flush=True)

    def one(job):
        p, name, h = job
        try:
            aid = upload_asset.upload(p, "Model", name=os.path.splitext(name)[0], desc="weapon skin mesh", quiet=True)
        except BaseException as e:   # (upload_asset exits on errors)
            return name, None, str(e)
        with lock:
            db[name] = {"id": aid, "sha": h}
            json.dump(db, open(DB, "w"), indent=0)
        return name, aid, None

    done = 0
    with ThreadPoolExecutor(max_workers=a.threads) as ex:
        for fut in as_completed([ex.submit(one, j) for j in todo]):
            name, aid, err = fut.result()
            done += 1
            print(f"[{done}/{len(todo)}] {name} {'FAILED ' + err if err else 'ok'}", flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
