"""Create (or update) the game's Developer Products through Open Cloud.

    python scripts/dev_products.py            # list what exists, create the missing bundles
    python scripts/dev_products.py --update   # also push price / description / image to existing ones
    python scripts/dev_products.py --list     # only list

The bundles mirror Catalog ▸ Economy ▸ products: the server links each one to
its Developer Product BY NAME at start (EconomyServer), so the names here must
match `product` there. Images come from blender/icons.py (blender/out/icons).
Reads ROBLOX_API_KEY / ROBLOX_UNIVERSE_ID from .env.
"""
import json, os, sys, time, urllib.error, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "blender", "out", "icons")

BUNDLES = [
    {"name": "100 Crowns", "price": 99, "image": "crowns_100.png",
     "description": "A purse of 100 Crowns: open a Bladesmith's or Hafted crate, or buy armor pieces and premium colours."},
    {"name": "550 Crowns", "price": 499, "image": "crowns_550.png",
     "description": "550 Crowns (+10% bonus). Enough for an Epic pack or several crates."},
    {"name": "1200 Crowns", "price": 999, "image": "crowns_1200.png",
     "description": "1200 Crowns (+20% bonus). A Legendary pack and change, or ten Royal Armoury openings."},
    {"name": "2600 Crowns", "price": 1999, "image": "crowns_2600.png",
     "description": "2600 Crowns (+30% bonus). The treasury: every pack in today's store and more."},
]


def env():
    p = os.path.join(ROOT, ".env")
    if os.path.exists(p):
        for line in open(p, encoding="utf-8"):
            if "=" in line and not line.strip().startswith("#"):
                k, v = line.strip().split("=", 1)
                os.environ.setdefault(k, v)
    return os.environ["ROBLOX_API_KEY"], os.environ["ROBLOX_UNIVERSE_ID"]


def call(method, url, key, fields=None, files=None):
    data, headers = None, {"x-api-key": key}
    if fields is not None or files is not None:
        boundary = "----DevProducts%d" % int(time.time() * 1000)
        body = b""
        for k, v in (fields or {}).items():
            body += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" % (boundary, k, v)).encode()
        for k, path in (files or {}).items():
            body += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: image/png\r\n\r\n" % (boundary, k, os.path.basename(path))).encode()
            body += open(path, "rb").read() + b"\r\n"
        body += ("--%s--\r\n" % boundary).encode()
        data = body
        headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            txt = r.read().decode() or "{}"
            return r.status, json.loads(txt) if txt.strip().startswith(("{", "[")) else txt
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:800]


def main():
    key, universe = env()
    base = f"https://apis.roblox.com/developer-products/v2/universes/{universe}/developer-products"
    status, listing = call("GET", base + "/creator?pageSize=50", key)
    if status != 200:
        sys.exit(f"list failed: {status} {listing}")
    existing = {p.get("name"): p for p in listing.get("developerProducts", [])}
    print("existing:", json.dumps([{"productId": p.get("productId"), "name": p.get("name"), "robux": (p.get("priceInformation") or {}).get("defaultPriceInRobux"), "isForSale": p.get("isForSale")} for p in existing.values()]))
    if "--list" in sys.argv:
        return
    for b in BUNDLES:
        fields = {"Name": b["name"], "Description": b["description"], "Price": b["price"], "IsForSale": "true"}
        img = os.path.join(ICONS, b["image"])
        files = {"ImageFile": img} if os.path.exists(img) else None
        if b["name"] in existing:
            if "--update" not in sys.argv:
                print("exists:", b["name"]); continue
            pid = existing[b["name"]].get("productId")
            status, res = call("PATCH", f"{base}/{pid}", key, fields, files)
            print("updated" if status < 300 else "UPDATE FAILED", b["name"], status, res if status >= 300 else "")
        else:
            status, res = call("POST", base, key, fields, files)
            print("created" if status < 300 else "CREATE FAILED", b["name"], status, json.dumps(res)[:400] if not isinstance(res, str) else res[:400])
    status, listing = call("GET", base + "/creator?pageSize=50", key)
    print("now:", json.dumps([{"productId": p.get("productId"), "name": p.get("name"), "robux": (p.get("priceInformation") or {}).get("defaultPriceInRobux"), "isForSale": p.get("isForSale")} for p in listing.get("developerProducts", [])]))


if __name__ == "__main__":
    main()
