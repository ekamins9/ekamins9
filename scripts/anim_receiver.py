"""Receives serialized animation clips from Studio and writes them to disk.

    python scripts/anim_receiver.py            # listens on localhost:34999

Studio (AnimForge export) POSTs each KeyframeSequence as raw .rbxm bytes to
http://localhost:34999/<Class>/<Clip>; the file lands in
blender/out/anims/<Class>__<Clip>.rbxm, ready for scripts/upload_anims.py.
Local only: it binds to 127.0.0.1 and accepts nothing but .rbxm bodies.
"""
import os, re
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "blender", "out", "anims")
NAME = re.compile(r"^/([A-Za-z0-9]+)/([A-Za-z0-9]+)$")


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        m = NAME.match(self.path)
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n)
        if not m or not body.startswith(b"<roblox!"):
            self.send_response(400); self.end_headers(); return
        os.makedirs(OUT, exist_ok=True)
        path = os.path.join(OUT, "%s__%s.rbxm" % m.groups())
        with open(path, "wb") as f:
            f.write(body)
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")

    def log_message(self, fmt, *args):
        print(self.path, flush=True)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 34999), Handler).serve_forever()
