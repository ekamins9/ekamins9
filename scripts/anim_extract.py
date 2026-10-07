"""Turn AnimForge export batches (text files of "@@<Class>/<Clip> <base64>" lines,
as Studio returns them) into blender/out/anims/<Class>__<Clip>.rbxm files.

    python scripts/anim_extract.py <batch.txt> [<batch.txt> ...]

Prints each clip written and the @@NEXT cursor of the last batch.
"""
import base64, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "anims")


def extract(path):
    nxt = None
    for line in open(path, encoding="utf-8").read().split("\n"):
        line = line.strip()
        if not line.startswith("@@"):
            continue
        name, _, data = line[2:].partition(" ")
        if name == "NEXT":
            nxt = data
            continue
        blob = base64.b64decode(data, validate=True)
        assert blob.startswith(b"<roblox!") and blob.rstrip().endswith(b"</roblox>"), name
        cls, clip = name.split("/")
        os.makedirs(OUT, exist_ok=True)
        with open(os.path.join(OUT, "%s__%s.rbxm" % (cls, clip)), "wb") as f:
            f.write(blob)
        print("wrote", name, len(blob))
    return nxt


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print("NEXT", extract(p))
