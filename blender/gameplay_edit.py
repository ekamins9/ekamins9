"""GAMEPLAY EDIT — the game page's video, cut from recorded gameplay (footage/, recorded with the
showcase): the best moments end to end, the game's sound under them (each cut eased in and out,
no clicks), title cards over them in the trailer's style, written as a 1080p H.264 MP4 with AAC
sound. Real gameplay, as Roblox wants on the game page.

    blender.exe -b --python blender/gameplay_edit.py -- titles
        the cards (footage/titles/*.png)
    blender.exe -b --python blender/gameplay_edit.py -- edit [--stills 30,300]
        the video (footage/edits/gameplay.mp4), or just those frames of it as PNGs

CUTS: (clip, second it starts in the clip, how long). CARDS: (card, from, to, pop) in seconds
of the finished video.
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import art_kit as K  # noqa: E402
from art_kit import rgb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOOT = os.path.join(ROOT, "footage")
TITLES = os.path.join(FOOT, "titles")
TRAILER_TITLES = os.path.join(ROOT, "store_art", "video", "titles")
OUT = os.path.join(FOOT, "edits")
FPS = 30
RES = (1920, 1080)
WHITE = (1.0, 1.0, 1.0)

CUTS = [
    # the rose garden: the opening, the name over it
    ("clip01.mp4", 726.0, 3.0), ("clip01.mp4", 735.0, 2.5),
    # EPIC BATTLES: the ruins at night
    ("clip01.mp4", 3.0, 2.5), ("clip01.mp4", 12.0, 2.5), ("clip01.mp4", 18.0, 2.0), ("clip01.mp4", 27.0, 2.0),
    # STORM THE CASTLE: the snow siege, the ram, the gate
    ("clip01.mp4", 294.0, 2.5), ("clip01.mp4", 306.0, 2.5), ("clip01.mp4", 336.0, 2.0), ("clip01.mp4", 338.0, 2.5),
    # DUEL THE BEST: the Colosseum, the arena, the grove
    ("clip01.mp4", 220.0, 3.0), ("clip01.mp4", 524.0, 2.0), ("clip01.mp4", 578.0, 2.5),
    # the rose garden from above, mid-fight
    ("clip01.mp4", 777.0, 2.5), ("clip01.mp4", 810.0, 2.5),
    # RARE ARMOR & SKINS: the parade
    ("clip01.mp4", 430.0, 2.0), ("clip01.mp4", 433.0, 2.0), ("clip01.mp4", 436.0, 2.0), ("clip01.mp4", 448.0, 2.0), ("clip01.mp4", 460.0, 2.0),
    # the end: the garden from above, the name and PLAY NOW
    ("clip01.mp4", 822.0, 4.0),
]

# the cards (made by `titles`; the trailer's own are reused: end = STEEL & GLORY, end_sub = PLAY NOW,
# siege = STORM THE CASTLE)
NEW_CARDS = {
    "battles": [{"text": "EPIC BATTLES", "y": 3.5, "size": 1.6}],
    "duels": [{"text": "DUEL THE BEST", "y": 3.5, "size": 1.6, "fill": (rgb(255, 236, 236), rgb(230, 60, 60)), "outline": rgb(50, 6, 6)}],
    "armor": [{"text": "RARE ARMOR & SKINS", "y": 3.5, "size": 1.45, "fill": (rgb(240, 220, 255), rgb(170, 90, 255)), "outline": rgb(30, 8, 60)}],
}


def starts():
    out, t = [], 0.0
    for c in CUTS:
        out.append(t)
        t += c[2]
    return out, t


def cards():
    s, total = starts()
    sec = lambda i: s[i]   # (the second a cut begins in the finished video)
    return [
        ("end", 0.25, 2.9, True),
        ("battles", sec(2) + 0.2, sec(4) + 1.6, True),
        ("siege", sec(6) + 0.2, sec(8) + 1.4, True),
        ("duels", sec(10) + 0.2, sec(12) + 1.6, True),
        ("armor", sec(15) + 0.2, sec(18) + 1.8, True),
        ("end", sec(20) + 0.2, total, True),
        ("end_sub", sec(20) + 1.0, total, True),
    ]


def card_path(name):
    p = os.path.join(TITLES, name + ".png")
    return p if os.path.exists(p) else os.path.join(TRAILER_TITLES, name + ".png")


def titles():
    os.makedirs(TITLES, exist_ok=True)
    for name, items in NEW_CARDS.items():
        K.overlay(items, RES, os.path.join(TITLES, name + ".png"))
        print("CARD", name, flush=True)


def _new_effect(strips, **kw):
    try:
        return strips.new_effect(length=kw.pop("length"), **kw)
    except TypeError:
        n = kw.pop("length", None)
        return strips.new_effect(frame_end=kw["frame_start"] + n, **kw)


def edit(stills=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    # (finished pictures: shown as they are, no grade on top)
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_x, sc.render.resolution_y = RES
    sc.render.resolution_percentage = 100
    sc.render.fps = FPS
    ed = sc.sequence_editor_create()
    strips = ed.strips
    s, total = starts()
    at = 1
    for i, (clip, t0, dur) in enumerate(CUTS):
        path = os.path.join(FOOT, clip)
        n = int(round(dur * FPS))
        off = int(round(t0 * FPS))
        ch = 1 + (i % 2)   # (alternate channels: neighbours never collide)
        # (a 720p recording fills the 1080p frame)
        try:
            v = strips.new_movie(name=f"v{i}", filepath=path, channel=ch, frame_start=at - off, fit_method="FILL")
        except TypeError:
            v = strips.new_movie(name=f"v{i}", filepath=path, channel=ch, frame_start=at - off)
        v.frame_offset_start = off
        v.frame_final_duration = n
        v.frame_start = at - off   # (the trim moves it: put the first kept frame back at `at`)
        a = strips.new_sound(name=f"a{i}", filepath=path, channel=5 + (i % 2), frame_start=at - off)
        a.frame_offset_start = off
        a.frame_final_duration = n
        a.frame_start = at - off
        # (each cut's sound eased in and out: no clicks)
        for fr, vol in ((at, 0.0), (at + 3, 1.0), (at + n - 3, 1.0), (at + n, 0.0)):
            a.volume = vol
            a.keyframe_insert("volume", frame=fr)
        at += n
    end = at - 1
    # the cards: fade in (landing large and settling), hold, fade out
    for j, (name, a0, a1, pop) in enumerate(cards()):
        f0, f1 = int(a0 * FPS) + 1, min(int(a1 * FPS) + 1, end)
        c = strips.new_image(name=f"c{j}", filepath=card_path(name), channel=10 + j, frame_start=f0)
        c.frame_final_duration = max(1, f1 - f0)
        c.blend_type = "ALPHA_OVER"
        keys = [(f0, 0.0), (f0 + 5, 1.0), (f1 - 5, 1.0), (f1, 0.0)] if f1 < end else [(f0, 0.0), (f0 + 5, 1.0)]
        for fr, al in keys:
            c.blend_alpha = al
            c.keyframe_insert("blend_alpha", frame=fr)
        if pop:
            for fr, k in ((f0, 1.3), (f0 + 7, 1.0)):
                c.transform.scale_x = c.transform.scale_y = k
                c.transform.keyframe_insert("scale_x", frame=fr)
                c.transform.keyframe_insert("scale_y", frame=fr)
    # a fade to black over the last half second
    fade = _new_effect(strips, name="fade", type="COLOR", channel=30, frame_start=end - 15, length=16)
    fade.color = (0, 0, 0)
    fade.blend_type = "ALPHA_OVER"
    for fr, al in ((end - 15, 0.0), (end, 1.0)):
        fade.blend_alpha = al
        fade.keyframe_insert("blend_alpha", frame=fr)
    sc.frame_start, sc.frame_end = 1, end
    os.makedirs(OUT, exist_ok=True)
    if stills:
        sc.render.image_settings.file_format = "PNG"
        for sec_ in stills:
            fr = int(sec_ * FPS) + 1
            sc.frame_set(fr)
            sc.render.filepath = os.path.join(OUT, f"still_{fr:04d}.png")
            bpy.ops.render.render(write_still=True)
            print("STILL", sec_, flush=True)
        return
    ims = sc.render.image_settings
    ims.media_type = "VIDEO"
    ims.file_format = "FFMPEG"
    ff = sc.render.ffmpeg
    ff.format = "MPEG4"
    ff.codec = "H264"
    ff.constant_rate_factor = "HIGH"
    ff.ffmpeg_preset = "GOOD"
    ff.audio_codec = "AAC"
    ff.audio_bitrate = 192
    ff.audio_channels = "STEREO"
    sc.render.filepath = os.path.join(OUT, "gameplay.mp4")
    bpy.ops.render.render(animation=True)
    print("EDITED", sc.render.filepath, end, "frames", f"{end / FPS:.1f}s", flush=True)


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if not a:
        print(__doc__)
    elif a[0] == "titles":
        titles()
    elif a[0] == "edit":
        st = None
        if "--stills" in a:
            st = [float(x) for x in a[a.index("--stills") + 1].split(",")]
        edit(st)


main()
