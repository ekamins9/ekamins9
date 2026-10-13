"""FOOTAGE — look through recorded gameplay and cut it, in Blender's video editor (there's no
ffmpeg on this machine; Blender carries its own).

    blender.exe -b --python blender/footage.py -- probe footage/clip01.mp4
        the clip's length, frame rate and size
    blender.exe -b --python blender/footage.py -- sheet footage/clip01.mp4 [every_seconds] [start_s] [end_s]
        contact sheets: 4 x 4 frames a page, every N seconds, each stamped with its time
        (footage/sheets/<clip>_<page>.png)
"""
import os
import sys

import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = os.path.join(ROOT, "footage", "sheets")


def args():
    a = sys.argv
    return a[a.index("--") + 1:] if "--" in a else []


def fresh():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    return sc


def movie(sc, path, channel=1, start=1):
    ed = sc.sequence_editor or sc.sequence_editor_create()
    s = ed.strips.new_movie(name=os.path.basename(path) + str(channel), filepath=path, channel=channel, frame_start=start)
    return s


def probe(path):
    sc = fresh()
    s = movie(sc, path)
    el = s.elements[0] if len(s.elements) else None
    fps = s.fps if hasattr(s, "fps") else 0
    print("PROBE", os.path.basename(path), "frames", s.frame_final_duration, "fps", round(fps, 3),
          "seconds", round(s.frame_final_duration / fps, 1) if fps else "?",
          "size", (el.orig_width, el.orig_height) if el else "?", flush=True)


def sheet(path, every=15.0, t0=0.0, t1=None):
    os.makedirs(SHEETS, exist_ok=True)
    sc = fresh()
    probe_strip = movie(sc, path)
    fps = probe_strip.fps
    total = probe_strip.frame_final_duration / fps
    sc.sequence_editor.strips.remove(probe_strip)
    t1 = min(t1 or total, total)
    times = []
    t = t0
    while t < t1:
        times.append(t)
        t += every
    W, H = 1920, 1080
    sc.render.resolution_x, sc.render.resolution_y = W, H
    sc.render.resolution_percentage = 100
    sc.render.fps = int(round(fps))
    sc.render.image_settings.file_format = "PNG"
    name = os.path.splitext(os.path.basename(path))[0]
    per = 16
    for page in range((len(times) + per - 1) // per):
        ed = sc.sequence_editor
        for s in list(ed.strips):
            ed.strips.remove(s)
        chunk = times[page * per:(page + 1) * per]
        for i, tt in enumerate(chunk):
            col, row = i % 4, i // 4
            ch = 1 + i * 2
            # (each cell: the clip, its start moved so frame 1 shows second tt)
            s = movie(sc, path, channel=ch, start=1 - int(tt * fps))
            s.transform.scale_x = s.transform.scale_y = 0.25
            s.transform.offset_x = (col - 1.5) * W / 4
            s.transform.offset_y = (1.5 - row) * H / 4
            s.blend_type = "ALPHA_OVER"
            try:
                txt = ed.strips.new_effect(name=f"t{i}", type="TEXT", channel=ch + 1, frame_start=1, length=1)
            except TypeError:
                txt = ed.strips.new_effect(name=f"t{i}", type="TEXT", channel=ch + 1, frame_start=1, frame_end=2)
            txt.text = f"{int(tt // 60)}:{int(tt % 60):02d}"
            txt.font_size = 34
            txt.use_shadow = True
            txt.location = ((col + 0.03) / 4, 1 - (row + 0.12) / 4)
            txt.anchor_x, txt.anchor_y = "LEFT", "CENTER"
        sc.frame_start = sc.frame_end = 1
        sc.frame_set(1)
        sc.render.filepath = os.path.join(SHEETS, f"{name}_{int(t0):04d}_{page + 1:02d}.png")
        bpy.ops.render.render(write_still=True)
        print("SHEET", page + 1, chunk[0], "-", chunk[-1], flush=True)


def main():
    a = args()
    if not a:
        print(__doc__)
        return
    cmd, path = a[0], os.path.join(ROOT, a[1]) if len(a) > 1 else None
    if cmd == "probe":
        probe(path)
    elif cmd == "sheet":
        sheet(path, float(a[2]) if len(a) > 2 else 15.0, float(a[3]) if len(a) > 3 else 0.0, float(a[4]) if len(a) > 4 else None)


main()
