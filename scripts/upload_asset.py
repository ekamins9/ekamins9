"""Upload a mesh (FBX / OBJ) or image to Roblox through the Open Cloud Assets API.

    python scripts/upload_asset.py blender/out/Longsword.fbx            # -> prints the asset id
    python scripts/upload_asset.py art/icons/crate_bladesmith.png --type Decal
    python scripts/upload_asset.py path --name "Longsword" --desc "..."

Reads ROBLOX_API_KEY (and ROBLOX_USER_ID) from the environment or from a `.env`
file in the repo root. The key needs the Assets API with read + write. The
asset id printed at the end is what `MeshPart.MeshId = "rbxassetid://<id>"`
or `Decal.Texture` takes. Never commit the key.
"""
import argparse, json, mimetypes, os, sys, time, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = "https://apis.roblox.com/assets/v1/assets"
OPS = "https://apis.roblox.com/assets/v1/operations/"


def load_env():
    p = os.path.join(ROOT, ".env")
    if os.path.exists(p):
        for line in open(p, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def multipart(fields, file_field, path, content_type):
    boundary = "----RobloxUpload%d" % int(time.time() * 1000)
    body = b""
    for k, v in fields.items():
        body += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\nContent-Type: application/json\r\n\r\n%s\r\n" % (boundary, k, v)).encode()
    body += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: %s\r\n\r\n" % (boundary, file_field, os.path.basename(path), content_type)).encode()
    body += open(path, "rb").read()
    body += ("\r\n--%s--\r\n" % boundary).encode()
    return body, "multipart/form-data; boundary=" + boundary


def request(url, key, data=None, content_type=None, method=None):
    """one API call; rate limits (429) and server hiccups are waited out and retried"""
    for attempt in range(8):
        req = urllib.request.Request(url, data=data, method=method or ("POST" if data else "GET"))
        req.add_header("x-api-key", key)
        if content_type:
            req.add_header("Content-Type", content_type)
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.loads(r.read().decode() or "{}")
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504) and attempt < 7:
                time.sleep(min(60, 3 * 2 ** attempt))
                continue
            sys.exit("HTTP %d: %s" % (e.code, e.read().decode()[:600]))
        except urllib.error.URLError:
            if attempt < 7:
                time.sleep(5)
                continue
            raise


def upload(path, asset_type=None, name=None, desc=None, key=None, user_id=None, group_id=None, quiet=False):
    load_env()
    key = key or os.environ.get("ROBLOX_API_KEY")
    if not key:
        sys.exit("ROBLOX_API_KEY is not set (put it in .env)")
    ext = os.path.splitext(path)[1].lower()
    if asset_type is None:
        asset_type = {".fbx": "Model", ".obj": "Model", ".png": "Decal", ".jpg": "Decal", ".jpeg": "Decal", ".tga": "Decal", ".bmp": "Decal", ".mp3": "Audio", ".ogg": "Audio", ".rbxm": "Animation"}.get(ext)
    if asset_type is None:
        sys.exit("unknown asset type for " + ext)
    content_type = {".fbx": "model/fbx", ".obj": "model/obj", ".rbxm": "model/x-rbxm"}.get(ext) or mimetypes.guess_type(path)[0] or "application/octet-stream"
    creator = {"groupId": str(group_id)} if group_id else {"userId": str(user_id or os.environ.get("ROBLOX_USER_ID", ""))}
    meta = {
        "assetType": asset_type,
        "displayName": (name or os.path.splitext(os.path.basename(path))[0])[:50],
        "description": (desc or "R6 melee game asset")[:1000],
        "creationContext": {"creator": creator},
    }
    body, ctype = multipart({"request": json.dumps(meta)}, "fileContent", path, content_type)
    op = request(ASSETS, key, body, ctype)
    op_id = op.get("operationId") or op.get("path", "").split("/")[-1]
    if not op_id:
        sys.exit("no operation id in " + json.dumps(op))
    for _ in range(60):
        time.sleep(1.5)
        st = request(OPS + op_id, key)
        if st.get("done"):
            if "error" in st:
                sys.exit("upload failed: " + json.dumps(st["error"]))
            asset_id = st["response"]["assetId"]
            if not quiet:
                print(asset_id)
            return int(asset_id)
    sys.exit("timed out waiting for the upload to process")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--type", dest="asset_type", help="Model | Decal | Audio | Animation (default from the extension)")
    ap.add_argument("--name")
    ap.add_argument("--desc")
    ap.add_argument("--group", help="upload to a group instead of the user")
    a = ap.parse_args()
    upload(a.path, a.asset_type, a.name, a.desc, group_id=a.group)
