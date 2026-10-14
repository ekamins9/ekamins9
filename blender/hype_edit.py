"""HYPE EDIT — flashy cuts of recorded gameplay (footage/) to the beat of the game's own tracks
(blender/music.py), every cut on a beat, with:
    a white flash and a zoom punch on every cut, a pulse on the off-beats,
    camera shake on the drops and the title slams, slow motion in the intros,
    letterbox bars on the cinematic parts, titles that slam in, punchier colour, a vignette,
    the music loud and the game's own sound low under it.

    blender.exe -b --python blender/hype_edit.py -- titles
        the cards these edits add (footage/titles)
    blender.exe -b --python blender/hype_edit.py -- edit [name] [--stills 7,21]
        -> footage/edits/<name>.mp4 (1080p30 H.264, AAC 256k)

    hype         the first cut: 140 BPM (anthem), 51 s, cinematic + a first-person burst
    epic         the second: 150 BPM (warcry), 58 s, a cinematic intro, first-person melee,
                 magic, the collection (inventory, pets, crates, kill effects), the finale
    firstperson  all first person: 160 BPM (rush), 48 s

An EDIT is its music and tempo, its SECTIONS (kind: intro / drop / break / outro, each a list of
shots: (clip, second in the clip, beats, options)), its CARDS (card, beat in, beat out), and the
beats that SHAKE, FLASH big, BOOM (a soft flash in the intro), take a BREATH (dark before a drop)
and carry LETTERBOX bars. Shot options: slow (playback speed), quiet (no game sound),
fp (first person: a little closer, the sound up), crop (a closer frame: the recording's corners
out of shot).
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
TITLES = os.path.join(FOOT, "titles")
TRAILER_TITLES = os.path.join(ROOT, "store_art", "video", "titles")
OUT = os.path.join(FOOT, "edits")
FPS = 30
RES = (1920, 1080)

FP = {"fp": True}
CIN = {"crop": 1.13}                     # (the showcase's own shots: the top bar out of frame)
MENU = {"panel": 0.7, "croptop": 44, "quiet": True}   # (a menu as a floating screen: its top bar cropped off)
SLOWCIN = {"crop": 1.13, "slow": 0.5, "quiet": True}


def shots(clip, beats, times, opt=None):
    return [(clip, t, beats, dict(opt or {})) for t in times]


EDITS = {
    "hype": dict(
        music="anthem", bpm=140, volume=0.7,
        sections=[
            ("intro", [("clip01.mp4", 48.0, 8, {"slow": 0.5, "quiet": True}), ("clip01.mp4", 291.0, 4, {}),
                       ("clip01.mp4", 436.0, 4, {"slow": 0.5, "quiet": True})]),
            ("drop", shots("clip01.mp4", 2, (3.0, 12.0, 18.0, 21.0, 24.0, 294.0, 300.0, 303.0, 306.0, 309.0, 312.0,
                                             336.0, 338.0, 342.0, 530.0, 533.0))),
            ("break", shots("clip01.mp4", 4, (430.0, 433.0, 448.0, 460.0))),
            ("drop", shots("clip01.mp4", 2, (220.0, 223.0, 226.0, 229.0, 578.0, 580.0, 632.0, 641.0, 644.0, 735.0)) +
                     shots("clip02.mp4", 2, (13.0, 14.4, 53.0, 56.0, 59.0, 63.0, 108.0, 113.0, 117.0, 124.5), FP)),
            ("outro", [("clip01.mp4", 726.0, 16, {})]),
        ],
        cards=[("end", 16, 23.5), ("siege", 26, 34), ("armor", 48.5, 63.5), ("duels", 64, 71.5),
               ("battles", 76, 84), ("feel", 84, 91.5), ("end", 104, 120), ("end_sub", 106, 120)],
        shakes=[16, 64, 84, 104, 112], big=[16, 64, 104], booms=[0, 4, 8], breaths=[(63.5, 64)], letterbox=[],
    ),
    "epic": dict(
        music="warcry", bpm=150, volume=0.7,
        sections=[
            # a slow, cinematic opening: the castle at night, the arena, the blood pit, the desert duel
            ("intro", [("clip04.mp4", 391.0, 4, SLOWCIN), ("clip04.mp4", 184.0, 4, SLOWCIN),
                       ("clip04.mp4", 381.0, 4, SLOWCIN), ("clip04.mp4", 464.0, 4, SLOWCIN)]),
            # first person, steel
            ("drop", shots("clip05.mp4", 2, (55.0, 60.0, 117.0, 66.0, 76.0), FP) +
                     shots("clip03.mp4", 2, (54.0, 96.0), FP) +
                     shots("clip05.mp4", 2, (99.0, 102.0, 114.5), FP) +
                     shots("clip04.mp4", 2, (202.0, 205.0), FP) +
                     shots("clip05.mp4", 2, (260.0, 266.0), FP) +
                     shots("clip04.mp4", 2, (421.0, 433.0), FP)),
            # magic
            ("drop", shots("clip04.mp4", 2, (258.0, 262.0, 280.0, 283.0, 290.0), FP) +
                     shots("clip05.mp4", 2, (152.0, 165.0), FP) + shots("clip04.mp4", 2, (304.0,), FP)),
            # the collection: pets, crates, skins, kill effects
            ("break", [("clip04.mp4", 540.5, 4, MENU), ("clip04.mp4", 603.0, 4, MENU), ("clip04.mp4", 555.0, 4, MENU),
                       ("clip04.mp4", 577.0, 4, MENU), ("clip04.mp4", 582.0, 4, MENU), ("clip04.mp4", 592.0, 4, MENU)]),
            # the finale: first person and the battles from above
            ("drop", [("clip04.mp4", 393.0, 2, CIN)] + shots("clip05.mp4", 2, (302.0, 305.0), FP) +
                     [("clip04.mp4", 467.0, 2, CIN)] + shots("clip05.mp4", 2, (359.0, 365.0, 386.0, 390.0), FP) +
                     shots("clip03.mp4", 2, (132.0,), FP) + shots("clip05.mp4", 2, (447.0, 455.5, 456.5), FP) +
                     [("clip04.mp4", 474.0, 2, CIN)] + shots("clip04.mp4", 2, (493.0, 496.0), FP) +
                     [("clip04.mp4", 187.0, 2, CIN)] + [("clip04.mp4", 396.0, 2, CIN)] +
                     shots("clip05.mp4", 2, (323.0, 327.0), FP) + [("clip04.mp4", 480.0, 2, CIN)]),
            ("outro", [("clip04.mp4", 476.0, 16, SLOWCIN)]),
        ],
        cards=[("yours", 16, 24), ("magic", 48, 55.5), ("magic_sub", 49.5, 55.5), ("collect", 64.5, 79.5),
               ("collect_sub", 66, 79.5), ("feel", 88, 95.5), ("siege", 100, 107.5), ("duels", 112, 119.5),
               ("end", 128, 144), ("end_sub", 130, 144)],
        shakes=[16, 48, 88, 100, 112, 128], big=[16, 48, 88, 128], booms=[0, 4, 8], breaths=[(87.5, 88)],
        letterbox=[(0, 16), (128, 144)], backgrounds=[(64, 88, "clip04.mp4", 382.0)],
    ),
    "firstperson": dict(
        music="rush", bpm=160, volume=0.7,
        sections=[
            ("intro", [("clip05.mp4", 446.5, 4, {"fp": True, "slow": 0.5, "quiet": True}),
                       ("clip03.mp4", 6.0, 4, {"fp": True, "slow": 0.5, "quiet": True})]),
            ("drop", shots("clip05.mp4", 2, (19.0, 22.0, 25.0, 28.0), FP) + shots("clip03.mp4", 2, (12.0, 48.0), FP) +
                     shots("clip05.mp4", 2, (31.0, 37.0), FP) + shots("clip03.mp4", 2, (54.0, 96.0), FP) +
                     shots("clip05.mp4", 2, (40.0,), FP) + shots("clip04.mp4", 2, (334.0, 337.0), FP) +
                     shots("clip05.mp4", 2, (264.0, 270.0), FP) + shots("clip03.mp4", 2, (138.0,), FP)),
            ("drop", shots("clip05.mp4", 2, (147.0, 153.0), FP) + shots("clip04.mp4", 2, (268.0, 275.0), FP) +
                     shots("clip05.mp4", 2, (170.0,), FP) + shots("clip04.mp4", 2, (293.0, 310.0), FP) +
                     shots("clip05.mp4", 2, (206.0,), FP) +
                     shots("clip04.mp4", 2, (205.0, 212.0, 218.0, 224.0), FP) + shots("clip05.mp4", 2, (75.0, 78.0, 81.0, 87.0), FP)),
            ("break", [("clip05.mp4", 65.5, 4, {"fp": True, "slow": 0.5}), ("clip05.mp4", 389.5, 4, {"fp": True, "slow": 0.5})]),
            ("drop", shots("clip05.mp4", 2, (302.0, 308.0), FP) + shots("clip04.mp4", 2, (489.0, 499.0), FP) +
                     shots("clip05.mp4", 2, (320.0, 323.0), FP) + shots("clip04.mp4", 2, (425.0, 432.0), FP) +
                     shots("clip05.mp4", 2, (359.0, 362.0, 365.0, 386.0, 392.0, 455.0, 458.0, 461.0), FP)),
            ("outro", [("clip05.mp4", 450.0, 16, {"fp": True, "slow": 0.5, "quiet": True})]),
        ],
        cards=[("eyes", 0, 7.5), ("yours", 8, 15.5), ("magic", 40, 47.5), ("parry", 72, 79.5), ("feel", 80, 87.5),
               ("siege", 96, 103.5), ("end", 112, 128), ("end_sub", 114, 128)],
        shakes=[8, 40, 80, 96, 112], big=[8, 40, 80, 112], booms=[0, 2], breaths=[(79.5, 80)], letterbox=[(112, 128)],
    ),
}

NEW_CARDS = {
    "feel": [{"text": "FEEL EVERY HIT", "y": 3.5, "size": 1.6, "fill": (K_rgb(255, 230, 170), K_rgb(255, 90, 20)), "outline": K_rgb(60, 10, 0)}],
    "yours": [{"text": "EVERY SWING IS YOURS", "y": 3.5, "size": 1.35}],
    "eyes": [{"text": "THROUGH YOUR EYES", "y": 3.5, "size": 1.5, "fill": (K_rgb(235, 245, 255), K_rgb(120, 170, 255)), "outline": K_rgb(10, 20, 60)}],
    "collect": [{"text": "COLLECT IT ALL", "y": 3.5, "size": 1.6, "fill": (K_rgb(240, 220, 255), K_rgb(170, 90, 255)), "outline": K_rgb(30, 8, 60)}],
    "collect_sub": [{"text": "SKINS  •  PETS  •  KILL EFFECTS  •  CRATES", "size": 0.55, "fill": (K_rgb(255, 255, 255), K_rgb(235, 235, 245)),
                     "outline": K_rgb(30, 8, 60), "ow": 0.07, "plate": K_rgb(110, 50, 200), "plate_edge": K_rgb(255, 214, 110), "y": -4.35}],
}


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


def edit(name, stills=None):
    E = EDITS[name]
    beat_s = 60 / E["bpm"]

    def fr(beat): return int(round(beat * beat_s * FPS)) + 1

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
    for kind, shot_list in E["sections"]:
        for clip, t0, beats, opt in shot_list:
            f0, f1 = fr(beat), fr(beat + beats)
            n = f1 - f0
            slow = opt.get("slow", 1.0)
            off = int(round(t0 * FPS))
            ch = 3 + (i % 2) * 3
            src_path = os.path.join(FOOT, clip)
            v = S.new_movie(name=f"v{i}", filepath=src_path, channel=ch, frame_start=f0 - off, fit_method="FILL")
            v.frame_offset_start = off
            # (the whole shot long, slow or not: a speed effect lasts as long as its input, and at
            # half speed it plays the first half of it)
            v.frame_final_duration = n
            v.frame_start = f0 - off
            v.color_saturation = 1.28
            if opt.get("croptop"):
                v.crop.max_y = int(opt["croptop"])   # (source pixels off the top: the recorder's bar)
            m = v.modifiers.new(name="punch", type="BRIGHT_CONTRAST")
            m.bright, m.contrast = 2.0, 14.0
            shown = v
            if slow != 1.0:
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
            # a zoom punch as it lands (not in a slow intro), a pulse on its other beats; all of it
            # times the strip's own scale (a 720p clip's fill to 1080p is a scale of 1.5)
            k0 = shown.transform.scale_x * opt.get("crop", 1.16 if opt.get("fp") else 1.0) * opt.get("panel", 1.0)
            if opt.get("panel"):
                shown.transform.offset_y = -20

            def zoom(pts):
                key(shown, "transform.scale_x", [(f, k0 * z) for f, z in pts])
                key(shown, "transform.scale_y", [(f, k0 * z) for f, z in pts])
            if opt.get("panel"):
                zoom([(f0, 0.9), (f0 + 5, 1.0), (f1, 1.04)])   # (it pops up, then drifts closer)
            elif kind == "intro":
                zoom([(f0, 1.0), (f1, 1.08)])   # (a slow push-in)
            elif kind == "outro" and slow != 1.0:
                zoom([(f0, 1.0), (f1, 1.1)])
            else:
                big = 1.16 if kind == "drop" else 1.08
                zoom([(f0, big), (f0 + 6, 1.0)])
                for b in range(1, beats):
                    fb = fr(beat + b)
                    if fb + 5 < f1:
                        zoom([(fb - 1, 1.0), (fb, 1.05), (fb + 5, 1.0)])
            cuts.append((f0, kind))
            beat += beats
            i += 1
    end = fr(beat) - 1
    # a blurred, darkened battle behind the floating screens
    for j, (b0, b1, clip, t0) in enumerate(E.get("backgrounds", [])):
        f0, f1 = fr(b0), fr(b1)
        off = int(round(t0 * FPS))
        bg = S.new_movie(name=f"bg{j}", filepath=os.path.join(FOOT, clip), channel=1, frame_start=f0 - off, fit_method="FILL")
        bg.frame_offset_start = off
        bg.frame_final_duration = f1 - f0
        bg.frame_start = f0 - off
        bl = _effect(S, name=f"blur{j}", type="GAUSSIAN_BLUR", channel=2, frame_start=f0, length=f1 - f0, input1=bg)
        bl.size_x = bl.size_y = 28
        bl.color_multiply = 0.42
    # the shake: the frame jolts and settles (every shown strip at that moment)
    rng = np.random.default_rng(3)
    for b in E["shakes"]:
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
    # the flashes: white on every cut (a big one on the drops)
    bigs = {fr(b) for b in E["big"]}
    ch = 40
    for f0, kind in cuts:
        big = f0 in bigs
        if kind == "intro" and not big:
            continue
        fl = _effect(S, name=f"f{f0}", type="COLOR", channel=ch, frame_start=f0, length=(9 if big else 4))
        fl.color = (1, 1, 1)
        fl.blend_type = "ADD"
        key(fl, "blend_alpha", [(f0, 1.0 if big else 0.5), (f0 + (8 if big else 3), 0.0)])
        ch = 41 if ch == 40 else 40
    # the booms of the intro flash too
    for b in E["booms"]:
        f0 = fr(b)
        fl = _effect(S, name=f"boom{b}", type="COLOR", channel=42, frame_start=f0, length=6)
        fl.color = (1, 1, 1); fl.blend_type = "ADD"
        key(fl, "blend_alpha", [(f0, 0.35), (f0 + 5, 0.0)])
    # the breath before a drop: dark on the last half-beat
    for j, (b0, b1) in enumerate(E["breaths"]):
        f0, f1 = fr(b0), fr(b1)
        dk = _effect(S, name=f"breath{j}", type="COLOR", channel=43, frame_start=f0, length=f1 - f0)
        dk.color = (0, 0, 0); dk.blend_type = "ALPHA_OVER"
        key(dk, "blend_alpha", [(f0, 0.0), (f1 - 1, 0.85)])
    # the vignette, all the way through
    vg = S.new_image(name="vignette", filepath=vignette(), channel=50, frame_start=1)
    vg.frame_final_duration = end
    vg.blend_type = "ALPHA_OVER"
    # letterbox bars over the cinematic parts (2.35:1)
    bar_h = int((RES[1] - RES[0] / 2.35) / 2)
    for j, (b0, b1) in enumerate(E["letterbox"]):
        f0, f1 = fr(b0), min(fr(b1), end + 1)
        for k, sign in enumerate((1, -1)):
            lb = _effect(S, name=f"lb{j}{k}", type="COLOR", channel=52 + k, frame_start=f0, length=f1 - f0)
            lb.color = (0, 0, 0); lb.blend_type = "ALPHA_OVER"
            lb.transform.scale_y = bar_h / RES[1]
            lb.transform.offset_y = sign * (RES[1] - bar_h) / 2
    # the cards: slam in big, settle, hold, fade
    for j, (cname, b0, b1) in enumerate(E["cards"]):
        f0, f1 = fr(b0), min(fr(b1), end)
        c = S.new_image(name=f"c{j}", filepath=card_path(cname), channel=60 + j, frame_start=f0)
        c.frame_final_duration = max(1, f1 - f0)
        c.blend_type = "ALPHA_OVER"
        key(c, "transform.scale_x", [(f0, 2.2), (f0 + 4, 0.94), (f0 + 7, 1.0)])
        key(c, "transform.scale_y", [(f0, 2.2), (f0 + 4, 0.94), (f0 + 7, 1.0)])
        pts = [(f0, 0.0), (f0 + 2, 1.0)] + ([(f1 - 5, 1.0), (f1, 0.0)] if f1 < end else [])
        key(c, "blend_alpha", pts)
    # the music
    mu = S.new_sound(name="music", filepath=os.path.join(FOOT, "music", E["music"] + ".wav"), channel=30, frame_start=1)
    mu.volume = E["volume"]   # (with the game's sound on top: peaks stay under full scale)
    # the last half second to black
    fade = _effect(S, name="fade", type="COLOR", channel=90, frame_start=end - 18, length=19)
    fade.color = (0, 0, 0); fade.blend_type = "ALPHA_OVER"
    key(fade, "blend_alpha", [(end - 18, 0.0), (end, 1.0)])

    sc.frame_start, sc.frame_end = 1, end
    os.makedirs(OUT, exist_ok=True)
    if stills:
        sc.render.image_settings.file_format = "PNG"
        for s_ in stills:
            f = int(round(s_ * FPS)) + 1
            sc.frame_set(f)
            sc.render.filepath = os.path.join(OUT, f"{name}_{f:04d}.png")
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
    sc.render.filepath = os.path.join(OUT, name + ".mp4")
    bpy.ops.render.render(animation=True)
    print("EDITED", sc.render.filepath, end, "frames", f"{end / FPS:.1f}s", flush=True)


def titles():
    os.makedirs(TITLES, exist_ok=True)
    for cname, items in NEW_CARDS.items():
        K.overlay(items, RES, os.path.join(TITLES, cname + ".png"))
        print("CARD", cname, flush=True)


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if a and a[0] == "titles":
        titles()
    elif a and a[0] == "edit":
        name = a[1] if len(a) > 1 and not a[1].startswith("--") else "hype"
        st = [float(x) for x in a[a.index("--stills") + 1].split(",")] if "--stills" in a else None
        edit(name, st)
    else:
        print(__doc__)


main()
