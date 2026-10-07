"""Join the slices of the blueprint JSON fetched from Studio (see
scripts/export_blueprints.lua) into blender/out/blueprints.json.

    python scripts/join_blueprints.py slice1.txt slice2.txt ...

Each file holds one result: the slice between <<< and >>> (anything around the
markers is ignored; a saved tool result wrapped as [{"type": "text", "text": …}]
is unwrapped first). The joined text must parse as JSON. Groups the export left
empty (an export of the Body alone) keep what blueprints.json already had.
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "blueprints.json")


def main():
    parts = []
    for path in sys.argv[1:]:
        text = open(path, encoding="utf-8").read()
        if text.lstrip().startswith("["):
            try:
                text = "".join(x.get("text", "") for x in json.loads(text))
            except (ValueError, AttributeError):
                pass
        a, b = text.find("<<<"), text.rfind(">>>")
        if a < 0 or b < a:
            sys.exit(f"{path}: no <<< >>> slice")
        parts.append(text[a + 3:b])
    data = json.loads("".join(parts))
    if os.path.exists(OUT):
        old = json.load(open(OUT, encoding="utf-8"))
        for k, val in old.items():
            if not data.get(k):
                data[k] = val
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    print("wrote", OUT, {k: len(v) for k, v in data.items()})


if __name__ == "__main__":
    main()
