"""HYPE EDIT — the flashy cut: recorded gameplay (footage/) cut to the beat of the game's own
track (blender/music.py: 140 BPM, 30 bars), every cut on a beat, with:
    a white flash and a zoom punch on every cut, a pulse on the off-beats,
    camera shake on the drops and the title slams, slow motion in the intro,
    titles that slam in (the trailer's cards), punchier colour and a vignette,
    the music loud and the game's own sound low under it.

    blender.exe -b --python blender/hype_edit.py -- titles
        its own cards (footage/titles: FEEL EVERY HIT)
    blender.exe -b --python blender/hype_edit.py -- edit [--stills 7,21]
        -> footage/edits/hype.mp4 (1080p30 H.264, AAC 256k)

The SHOTS follow the music's sections: (second in the clip, beats, options). Options:
slow = playback speed (0.5 = half), quiet = no game sound.
"""
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import art_kit as K  # noqa: E402
K_rgb = K.rgb

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOOT = os.path.join(ROOT, "footage")
CLIP = os.path.join(FOOT, "clip01.mp4")
MUSIC = os.path.join(FOOT, "music", "anthem.wav")
TITLES = os.path.join(FOOT, "titles")
TRAILER_TITLES = os.path.join(ROOT, "store_art", "video", "titles")
OUT = os.path.join(FOOT, "edits")
FPS = 30
RES = (1920, 1080)
BPM = 140
BEAT = 60 / BPM

INTRO = [(48.0, 8, {"slow": 0.5, "quiet": True}), (291.0, 4, {}), (436.0, 4, {"slow": 0.5, "quiet": True})]
DROP_A = [(t, 2, {}) for t in (3.0, 12.0, 18.0, 21.0, 24.0, 294.0, 300.0, 303.0, 306.0, 309.0, 312.0, 336.0, 338.0, 342.0, 530.0, 533.0)]
BREAK = [(t, 4, {}) for t in (430.0, 433.0, 448.0, 460.0)]
# (first person, from clip02: the snow siege seen through the knight's eyes, the clashes loud)
FP = {"clip": "clip02.mp4", "fp": True}
DROP_B = [(t, 2, {}) for t in (220.0, 223.0, 226.0, 229.0, 578.0, 580.0, 632.0, 641.0, 644.0, 735.0)] +          [(t, 2, FP) for t in (13.0, 14.4, 53.0, 56.0, 59.0, 63.0, 108.0, 113.0, 117.0, 124.5)]
OUTRO = [(726.0, 16, {"quiet": False})]
SECTIONS = [("intro", INTRO), ("dropA", DROP_A), ("break", BREAK), ("dropB", DROP_B), ("outro", OUTRO)]

# (card, beat it slams in, beat it goes): the beat counted from the start (16 = the first drop)
CARDS = [
    ("end", 16, 23.5),          # STEEL & GLORY on the drop
    ("siege", 26, 34),          # STORM THE CASTLE over the siege
    ("armor", 48.5, 63.5),      # RARE ARMOR & SKINS over the parade
    ("duels", 64, 71.5),        # DUEL THE BEST
    ("battles", 76, 84),        # EPIC BATTLES
    ("feel", 84, 91.5),         # FEEL EVERY HIT, over the first person
    ("end", 104, 120),          # STEEL & GLORY at the end
    ("end_sub", 106, 120),      # PLAY NOW
]
SHAKES = [16, 64, 84, 104, 112]     # beats that shake the frame
NEW_CARDS = {
    "feel": [{"text": "FEEL EVERY HIT", "y": 3.5, "size": 1.6, "fill": (K_rgb(255, 230, 170), K_rgb(255, 90, 20)), "outline": K_rgb(60, 10, 0)}],
}


def fr(beat): return int(round(beat * BEAT * FPS)) + 1


def card_path(name):
    p = os.path.join(TITLES, name + ".png")
    return p if os.path.exists(p) else os.path.join(TRAILER_TITLES, name + ".png")


def vignette():
    p = os.path.join(TITLES, "vignette.png")
    if os.path.exists(p): return p
    w, h = RES
    y, x = np.mgrid[0:h, 0:w]
    d = np.sqrt(((x - w / 2) / (w / 2)) ** 2 + ((y - h / 2) / (h / 2)) ** 2)
    a = np.clip((d - 0.55) / 0.75, 0, 1) ** 1.6 * 0.6
    px = np.zeros((h, w, 4), np.float32); px[..., 3] = a
    img = bpy.data.images.new("vig", w, h, alpha=True)
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = p; img.file_format = "PNG"; img.save()
    return p


def _effect(strips, **kw):
    n = kw.pop("length")
    try:
        return strips.new_effect(length=n, **kw)
    except TypeError:
        return strips.new_effect(frame_end=kw["frame_start"] + n, **kw)


def key(obj, path, pts):
    """keyframes: pts = [(frame, value)], on obj.path (e.g. transform.scale_x)"""
    target, attr = (obj, path) if "." not in path else (getattr(obj, path.split(".")[0]), path.split(".")[1])
    for f, v in pts:
        setattr(target, attr, v)
        target.keyframe_insert(attr, frame=f)


def edit(stills=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_x, sc.render.resolution_y = RES
    sc.render.resolution_percentage = 100
    sc.render.fps = FPS
    ed = sc.sequence_editor_create()
    S = ed.strips
    beat = 0
    i = 0
    cuts = []
    for section, shots in SECTIONS:
        for t0, beats, opt in shots:
            f0, f1 = fr(beat), fr(beat + beats)
            n = f1 - f0
            slow = opt.get("slow", 1.0)
            off = int(round(t0 * FPS))
            ch = 1 + (i % 2) * 3
            src_path = os.path.join(FOOT, opt["clip"]) if opt.get("clip") else CLIP
            v = S.new_movie(name=f"v{i}", filepath=src_path, channel=ch, frame_start=f0 - off, fit_method="FILL")
            v.frame_offset_start = off
            # (the whole shot long, slow or not: a speed effect lasts as long as its input, and at
            # half speed it plays the first half of it)
            v.frame_final_duration = n
            v.frame_start = f0 - off
            v.color_saturation = 1.28
            m = v.modifiers.new(name="punch", type="BRIGHT_CONTRAST")
            m.bright, m.contrast = 2.0, 14.0
            shown = v
            if slow != 1.0:
                # (half speed: the speed effect stretches its input over the shot)
                sp = _effect(S, name=f"s{i}", type="SPEED", channel=ch + 1, frame_start=f0, length=n, input1=v)
                sp.speed_control = "MULTIPLY"; sp.speed_factor = slow
                shown = sp
            # the game's own sound, low under the music, eased at the cuts
            if not opt.get("quiet"):
                a = S.new_sound(name=f"a{i}", filepath=src_path, channel=20 + (i % 2), frame_start=f0 - off)
                a.frame_offset_start = off
                a.frame_final_duration = n
                a.frame_start = f0 - off
                lv = 0.2 if opt.get("fp") else 0.13   # (first person: the clashes up front)
                key(a, "volume", [(f0, 0.0), (f0 + 2, lv), (f1 - 2, lv), (f1, 0.0)])
            # a zoom punch as it lands (not in the slow intro), a pulse on its other beats; all of
            # it times the strip's own scale (a 720p clip's fill to 1080p is a scale of 1.5)
            k0 = shown.transform.scale_x
            # (first person: a little closer, so the corners' buttons and notices are out of frame)
            if opt.get("fp"): k0 *= 1.16
            def zoom(pts):
                key(shown, "transform.scale_x", [(f, k0 * z) for f, z in pts])
                key(shown, "transform.scale_y", [(f, k0 * z) for f, z in pts])
            if section != "intro":
                big = 1.16 if section in ("dropA", "dropB") else 1.08
                zoom([(f0, big), (f0 + 6, 1.0)])
                for b in range(1, beats):
                    fb = fr(beat + b)
                    if fb + 5 < f1:
                        zoom([(fb - 1, 1.0), (fb, 1.05), (fb + 5, 1.0)])
            else:
                zoom([(f0, 1.0), (f1, 1.08)])   # (a slow push-in)
            cuts.append((f0, section))
            beat += beats
            i += 1
    end = fr(beat) - 1
    # the shake: the frame jolts and settles (every shown strip at that moment)
    rng = np.random.default_rng(3)
    for b in SHAKES:
        f0 = fr(b)
        for s in list(S):
            if s.type in ("MOVIE", "SPEED") and s.frame_final_start <= f0 < s.frame_final_end and s.channel < 10:
                if s.type == "MOVIE" and any(e.type == "SPEED" and e.input_1 == s for e in S if e.type == "SPEED"):
                    continue
                pts_x, pts_y = [], []
                for k in range(12):
                    amp = 34 * (1 - k / 12) ** 1.5
                    pts_x.append((f0 + k, float(rng.uniform(-amp, amp))))
                    pts_y.append((f0 + k, float(rng.uniform(-amp, amp))))
                pts_x.append((f0 + 12, 0.0)); pts_y.append((f0 + 12, 0.0))
                key(s, "transform.offset_x", pts_x)
                key(s, "transform.offset_y", pts_y)
    # the flashes: white on every cut (a big one on the drops), black in the breath before drop B
    ch = 40
    for f0, section in cuts:
        big = f0 in (fr(16), fr(64), fr(104))
        if section == "intro" and not big:
            continue
        fl = _effect(S, name=f"f{f0}", type="COLOR", channel=ch, frame_start=f0, length=(9 if big else 4))
        fl.color = (1, 1, 1)
        fl.blend_type = "ADD"
        key(fl, "blend_alpha", [(f0, 1.0 if big else 0.5), (f0 + (8 if big else 3), 0.0)])
        ch = 41 if ch == 40 else 40
    # the booms of the intro flash too (bars 0-2)
    for b in (0, 4, 8):
        f0 = fr(b)
        fl = _effect(S, name=f"boom{b}", type="COLOR", channel=42, frame_start=f0, length=6)
        fl.color = (1, 1, 1); fl.blend_type = "ADD"
        key(fl, "blend_alpha", [(f0, 0.35), (f0 + 5, 0.0)])
    # the breath before drop B: dark on the last half-beat
    f0, f1 = fr(63.5), fr(64)
    dk = _effect(S, name="breath", type="COLOR", channel=43, frame_start=f0, length=f1 - f0)
    dk.color = (0, 0, 0); dk.blend_type = "ALPHA_OVER"
    key(dk, "blend_alpha", [(f0, 0.0), (f1 - 1, 0.85)])
    # the vignette, all the way through
    vg = S.new_image(name="vignette", filepath=vignette(), channel=50, frame_start=1)
    vg.frame_final_duration = end
    vg.blend_type = "ALPHA_OVER"
    # the cards: slam in big, settle, hold, fade
    for j, (name, b0, b1) in enumerate(CARDS):
        f0, f1 = fr(b0), min(fr(b1), end)
        c = S.new_image(name=f"c{j}", filepath=card_path(name), channel=60 + j, frame_start=f0)
        c.frame_final_duration = max(1, f1 - f0)
        c.blend_type = "ALPHA_OVER"
        key(c, "transform.scale_x", [(f0, 2.2), (f0 + 4, 0.94), (f0 + 7, 1.0)])
        key(c, "transform.scale_y", [(f0, 2.2), (f0 + 4, 0.94), (f0 + 7, 1.0)])
        pts = [(f0, 0.0), (f0 + 2, 1.0)] + ([(f1 - 5, 1.0), (f1, 0.0)] if f1 < end else [])
        key(c, "blend_alpha", pts)
    # the music
    mu = S.new_sound(name="music", filepath=MUSIC, channel=30, frame_start=1)
    mu.volume = 0.7   # (with the game's sound on top: peaks stay under full scale)
    # the last half second to black
    fade = _effect(S, name="fade", type="COLOR", channel=70, frame_start=end - 18, length=19)
    fade.color = (0, 0, 0); fade.blend_type = "ALPHA_OVER"
    key(fade, "blend_alpha", [(end - 18, 0.0), (end, 1.0)])

    sc.frame_start, sc.frame_end = 1, end
    os.makedirs(OUT, exist_ok=True)
    if stills:
        sc.render.image_settings.file_format = "PNG"
        for s_ in stills:
            f = int(round(s_ * FPS)) + 1
            sc.frame_set(f)
            sc.render.filepath = os.path.join(OUT, f"hype_{f:04d}.png")
            bpy.ops.render.render(write_still=True)
            print("STILL", s_, flush=True)
        return
    ims = sc.render.image_settings
    ims.media_type = "VIDEO"
    ims.file_format = "FFMPEG"
    ff = sc.render.ffmpeg
    ff.format = "MPEG4"; ff.codec = "H264"
    ff.constant_rate_factor = "HIGH"; ff.ffmpeg_preset = "GOOD"
    ff.audio_codec = "AAC"; ff.audio_bitrate = 256; ff.audio_channels = "STEREO"
    sc.render.filepath = os.path.join(OUT, "hype.mp4")
    bpy.ops.render.render(animation=True)
    print("EDITED", sc.render.filepath, end, "frames", f"{end / FPS:.1f}s", flush=True)


def titles():
    os.makedirs(TITLES, exist_ok=True)
    for name, items in NEW_CARDS.items():
        K.overlay(items, RES, os.path.join(TITLES, name + ".png"))
        print("CARD", name, flush=True)


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if a and a[0] == "titles":
        titles()
    elif a and a[0] == "edit":
        st = [float(x) for x in a[a.index("--stills") + 1].split(",")] if "--stills" in a else None
        edit(st)
    else:
        print(__doc__)


main()
