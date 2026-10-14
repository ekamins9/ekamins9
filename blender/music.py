"""MUSIC — original tracks for the game's videos, synthesized from nothing (no samples, no
licence to worry about). Each PLAN is a tempo, a key (a chord progression and a lead hook), a
drum style and its sections, in bars:

    intro      a dark pad, heartbeat booms, a riser and a snare roll into
    drop       driving drums, a distorted pumping bass, supersaw stabs on the off-beats,
               an impact and a crash
    droplead   the drop with the lead hook on top, with echoes
    break      half-time drums, a pad, a 16th-note arpeggio, a riser, a roll, a breath
    outro      an impact, the last chord held, a final boom, the tail

    anthem   140 BPM, D minor, four-on-the-floor, 30 bars (51.4 s): the first hype edit
    warcry   150 BPM, E minor, four-on-the-floor, 36 bars (57.6 s): the second trailer
    rush     160 BPM, F minor, breakbeat drums, 32 bars (48 s): the first-person cut

    "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" blender/music.py [plan]
        -> footage/music/<plan>.wav (44.1 kHz, 16-bit stereo, loud)

Everything is numpy: oscillators, envelopes, FFT filters, an FFT reverb, a soft-clipping master.
"""
import os
import sys
import wave

import numpy as np

SR = 44100
TAIL = 1.6
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (bass root, chord) a bar each, four bars; the hook in eighths over those four bars
PROGS = {
    "A": [(38, [62, 65, 69]), (34, [58, 62, 65]), (41, [60, 65, 69]), (36, [60, 64, 67])],          # Dm Bb F C
    "B": [(40, [64, 67, 71]), (45, [64, 69, 72]), (36, [64, 67, 72]), (35, [63, 66, 71])],          # Em Am C B
    "C": [(41, [65, 68, 72]), (37, [65, 68, 73]), (39, [67, 70, 75]), (36, [64, 67, 72])],          # Fm Db Eb C
}
HOOKS = {
    "A": [(0, 1, 69), (1, 1, 69), (2, 2, 74), (4, 1, 72), (5, 1, 69), (6, 2, 67),
          (8, 1, 65), (9, 1, 65), (10, 2, 70), (12, 1, 69), (13, 1, 65), (14, 2, 62),
          (16, 1, 72), (17, 1, 72), (18, 2, 77), (20, 1, 76), (21, 1, 72), (22, 2, 69),
          (24, 1, 67), (25, 1, 69), (26, 2, 72), (28, 2, 74), (30, 2, 76)],
    "B": [(0, 1, 71), (1, 1, 71), (2, 2, 76), (4, 1, 74), (5, 1, 71), (6, 2, 67),
          (8, 1, 69), (9, 1, 72), (10, 2, 76), (12, 1, 74), (13, 1, 72), (14, 2, 69),
          (16, 1, 67), (17, 1, 72), (18, 2, 79), (20, 1, 76), (21, 1, 72), (22, 2, 71),
          (24, 2, 71), (26, 1, 75), (27, 1, 78), (28, 2, 83), (30, 2, 78)],
    "C": [(0, 1, 72), (1, 1, 72), (2, 1, 75), (3, 1, 77), (4, 2, 80), (6, 2, 77),
          (8, 1, 73), (9, 1, 77), (10, 2, 80), (12, 2, 77), (14, 2, 73),
          (16, 1, 75), (17, 1, 79), (18, 2, 82), (20, 1, 79), (21, 1, 75), (22, 2, 79),
          (24, 1, 76), (25, 1, 79), (26, 2, 84), (28, 2, 79), (30, 2, 76)],
}
PLANS = {
    "anthem": dict(bpm=140, prog="A", drums="four", seed=7,
                   sections=[("intro", 4), ("drop", 8), ("break", 4), ("droplead", 10), ("outro", 4)]),
    "warcry": dict(bpm=150, prog="B", drums="four", seed=11,
                   sections=[("intro", 4), ("drop", 8), ("droplead", 4), ("break", 6), ("droplead", 10), ("outro", 4)]),
    "rush":   dict(bpm=160, prog="C", drums="break", seed=23,
                   sections=[("intro", 2), ("drop", 8), ("droplead", 8), ("break", 2), ("droplead", 8), ("outro", 4)]),
}

# set by configure(plan)
BPM = BEAT = BAR = None
BARS = N = 0
OUT = ""
PROG = HOOK = None
rng = np.random.default_rng(7)


def configure(name):
    global BPM, BEAT, BAR, BARS, N, OUT, PROG, HOOK, rng
    P = PLANS[name]
    BPM = P["bpm"]; BEAT = 60 / BPM; BAR = 4 * BEAT
    BARS = sum(n for _, n in P["sections"])
    N = int((BARS * BAR + TAIL) * SR)
    OUT = os.path.join(ROOT, "footage", "music", name + ".wav")
    PROG, HOOK = PROGS[P["prog"]], HOOKS[P["prog"]]
    rng = np.random.default_rng(P["seed"])
    return P


def hz(m): return 440.0 * 2 ** ((m - 69) / 12)
def at(bar, beat=0.0): return bar * BAR + beat * BEAT
def secs(n): return np.arange(n) / SR


class Bus:
    """a stereo track: things are added at a time, with a pan"""

    def __init__(self): self.x = np.zeros((2, N))

    def add(self, t0, sig, gain=1.0, pan=0.0):
        i = int(t0 * SR)
        if i >= N: return
        if sig.ndim == 1: sig = np.stack([sig, sig])
        n = min(sig.shape[1], N - i)
        l, r = np.sqrt(0.5 * (1 - pan)), np.sqrt(0.5 * (1 + pan))
        self.x[0, i:i + n] += sig[0, :n] * gain * l * 1.414
        self.x[1, i:i + n] += sig[1, :n] * gain * r * 1.414


# ---------------------------------------------------------------- filters (FFT, zero phase)
def fft_filter(x, lo=None, hi=None, slope=1.0):
    """band-limit x (1-D or 2-D): a gentle high-pass at lo and low-pass at hi (Hz)"""
    n = x.shape[-1]
    X = np.fft.rfft(x, axis=-1)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.ones_like(f)
    if hi: g *= 1 / np.sqrt(1 + (f / hi) ** (4 * slope))
    if lo: g *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (4 * slope))
    return np.fft.irfft(X * g, n=n, axis=-1)


def noise(n, stereo=False):
    return rng.standard_normal((2, n) if stereo else n) * 0.35


# ---------------------------------------------------------------- the instruments
def kick(big=1.0):
    n = int(0.55 * SR); t = secs(n)
    f = 44 + 120 * np.exp(-t / 0.028) + 30 * np.exp(-t / 0.2)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (0.30 * big))
    click = fft_filter(noise(n), lo=1500) * np.exp(-t / 0.004) * 1.2
    return np.tanh(1.8 * (body + click)) * 0.95


def snare():
    n = int(0.45 * SR); t = secs(n)
    tone = (np.sin(2 * np.pi * 185 * t) + 0.5 * np.sin(2 * np.pi * 330 * t)) * np.exp(-t / 0.05)
    nz = fft_filter(noise(n), lo=1200, hi=9000) * np.exp(-t / 0.15) * 2.2
    return np.tanh(1.5 * (0.6 * tone + nz))


def clap():
    n = int(0.4 * SR); t = secs(n)
    env = np.zeros(n)
    for o in (0.0, 0.011, 0.023):
        i = int(o * SR); env[i:] += np.exp(-(t[:n - i]) / (0.02 if o < 0.02 else 0.18))
    return fft_filter(noise(n), lo=900, hi=7000) * env * 2.0


def hat(open_=False):
    n = int((0.25 if open_ else 0.07) * SR); t = secs(n)
    return fft_filter(noise(n), lo=7500) * np.exp(-t / (0.09 if open_ else 0.022)) * 2.4


def crash(length=2.5):
    n = int(length * SR); t = secs(n)
    nz = fft_filter(noise(n, True), lo=3500) * 2.0
    return nz * np.exp(-t / (length * 0.35))


def boom(length=2.5):
    n = int(length * SR); t = secs(n)
    f = 38 + 60 * np.exp(-t / 0.15)
    sub = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (length * 0.3))
    hit = fft_filter(noise(n), hi=2500) * np.exp(-t / 0.25) * 1.5
    return np.tanh(2.0 * (sub + hit))


def saw(freq, t, phase=0.0):
    return 2.0 * ((freq * t + phase) % 1.0) - 1.0


def supersaw(notes, dur, attack=0.005, decay=None, voices=7, spread=0.22, cutoff=6000):
    """a chord of detuned saws, wide in stereo; decay = None: held (a pad)"""
    n = int(dur * SR); t = secs(n)
    out = np.zeros((2, n))
    for m in notes:
        f0 = hz(m)
        for v in range(voices):
            det = (v - (voices - 1) / 2) / ((voices - 1) / 2)          # -1 .. 1
            for ch in (0, 1):
                cents = det * 18 * spread * 4 + (3 if ch else -3) * det
                out[ch] += saw(f0 * 2 ** (cents / 1200), t, rng.random())
    out /= voices * len(notes) * 0.6
    env = np.minimum(t / attack, 1.0)
    env *= np.exp(-t / decay) if decay else np.minimum((dur - t) / 0.05, 1.0)
    return fft_filter(out * env, lo=150, hi=cutoff)


def bass(m, dur):
    n = int(dur * SR); t = secs(n)
    f = hz(m)
    x = saw(f, t) + 0.6 * np.sin(2 * np.pi * f / 2 * t)
    x = np.tanh(3.2 * x)
    env = np.minimum(t / 0.004, 1) * np.minimum((dur - t) / 0.01, 1) * (0.55 + 0.45 * np.exp(-t / 0.12))
    return fft_filter(x * env, hi=1100)


def lead(m, dur):
    n = int(dur * SR); t = secs(n)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(t / 0.15, 1)
    f = hz(m) * vib
    ph = np.cumsum(f) / SR
    x = 0.6 * (2 * (ph % 1) - 1) + 0.5 * np.sign(np.sin(2 * np.pi * ph * 1.003))
    env = np.minimum(t / 0.008, 1) * np.minimum((dur - t) / 0.02, 1) * (0.7 + 0.3 * np.exp(-t / 0.2))
    return fft_filter(np.tanh(1.4 * x) * env, lo=200, hi=7000)


def pluck(m, dur=0.18):
    n = int(dur * SR); t = secs(n)
    x = np.sign(np.sin(2 * np.pi * hz(m) * t)) * 0.6 + saw(hz(m) * 2, t) * 0.3
    return fft_filter(x * np.exp(-t / 0.06), hi=5000)


def riser(length, lo=300, hi=9000):
    """noise opening up and a tone sweeping up, both swelling"""
    n = int(length * SR); t = secs(n); u = t / length
    nz = noise(n, True)
    bands = [fft_filter(nz, lo=lo * (hi / lo) ** (k / 5), hi=lo * (hi / lo) ** ((k + 1.5) / 5)) for k in range(5)]
    out = np.zeros((2, n))
    for k, b in enumerate(bands):
        w = np.clip(1 - np.abs(u * 4.5 - k) / 1.5, 0, 1)
        out += b * w * 2.2
    f = 180 * (2400 / 180) ** (u ** 1.6)
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.35
    return (out + tone) * (u ** 2.2)


# ---------------------------------------------------------------- the score
def build(P):
    drums, bassB, synth, leadB, fx, verb = Bus(), Bus(), Bus(), Bus(), Bus(), Bus()
    K, S, C, H, HO = kick(), snare(), clap(), hat(), hat(True)
    kicks = []
    style = P["drums"]

    def kick_at(t, sig=None, g=1.0):
        drums.add(t, K if sig is None else sig, g); kicks.append(t)

    def drop_bars(b0, b1, lead_on, impact):
        for b in range(b0, b1):
            root, chord = PROG[b % 4]
            if style == "four":
                for q in range(4):                    # four on the floor
                    kick_at(at(b, q))
                for q in (1, 3):
                    drums.add(at(b, q), S, 0.55); drums.add(at(b, q), C, 0.45, 0.1); verb.add(at(b, q), S, 0.25)
            else:                                     # a breakbeat: kick 1, the "and" of 2, a push on 4
                for q in ((0, 1.5, 2.5) if b % 2 == 0 else (0, 1.75, 2.5, 3.5)):
                    kick_at(at(b, q))
                for q in (1, 3):
                    drums.add(at(b, q), S, 0.65); drums.add(at(b, q), C, 0.35, 0.1); verb.add(at(b, q), S, 0.25)
                for q in (1.75, 3.25, 3.75):          # ghost notes
                    drums.add(at(b, q), S, 0.14, 0.2)
            for e in range(8):                        # hats: 8ths, 16ths in the second half
                drums.add(at(b, e / 2), HO if e % 2 else H, 0.22 if e % 2 else 0.16, -0.3)
                if (b - b0) % 8 >= 4 or style != "four":
                    drums.add(at(b, e / 2 + 0.25), H, 0.12, 0.3)
            for e in range(8):                        # the bass: 8ths, the octave on the off-beats
                bassB.add(at(b, e / 2), bass(root + (12 if e % 2 else 0), BEAT / 2 * 0.92), 0.5)
            for e in (1, 3, 5, 7):                    # stabs on the "and"s
                synth.add(at(b, e / 2), supersaw(chord, BEAT * 0.5, decay=0.16), 0.55)
            if lead_on:
                cyc = (b - b0) % 4
                for s0, ln, m in HOOK:
                    if cyc * 8 <= s0 < cyc * 8 + 8:
                        t0 = at(b, (s0 - cyc * 8) / 2)
                        sig = lead(m, ln * BEAT / 2 * 0.95)
                        leadB.add(t0, sig, 0.32)
                        for k, (dt, g) in enumerate(((0.75 * BEAT, 0.35), (1.5 * BEAT, 0.18))):   # echoes
                            leadB.add(t0 + dt, sig, 0.32 * g, (-0.5, 0.5)[k % 2])
                        verb.add(t0, sig, 0.15)
        fx.add(at(b0), crash(3.0 if impact else 2.0), 0.5 if impact else 0.38)
        if impact: fx.add(at(b0), boom(2.0), 0.9)
        for b in range(b0 + 4, b1, 4): fx.add(at(b), crash(2.0), 0.35)

    def intro(b0, n):
        for b in range(b0, b0 + n):
            root, chord = PROG[b % 4]
            synth.add(at(b), supersaw(chord, BAR, attack=0.4, cutoff=1400 + (b - b0) * 2800 / n), 0.45)
            bassB.add(at(b), bass(root, BAR * 0.98) * 0.6, 0.35)
            if b < b0 + n - 1:
                kick_at(at(b), kick(1.6), 0.9); verb.add(at(b), kick(1.6), 0.3)
                if n <= 2: kick_at(at(b, 2), kick(1.6), 0.8)
        fx.add(at(b0), riser(n * BAR), 0.55)
        last = b0 + n - 1
        for i, q in enumerate([0, 1, 2, 2.5, 3, 3.25, 3.5, 3.75]):   # the roll into the drop
            drums.add(at(last, q), S, 0.2 + 0.05 * i)
        for k in range(16):
            drums.add(at(last, 2 + k / 8), S, 0.12 + k * 0.025)

    def breakdown(b0, n):
        for b in range(b0, b0 + n):
            root, chord = PROG[b % 4]
            synth.add(at(b), supersaw(chord, BAR, attack=0.15, cutoff=2600), 0.4)
            bassB.add(at(b), bass(root, BAR * 0.95) * 0.7, 0.3)
            if b < b0 + n - 1:
                kick_at(at(b, 0), None, 0.9)
                drums.add(at(b, 2), S, 0.5); verb.add(at(b, 2), S, 0.3)
            tones = chord + [chord[0] + 12]
            for s in range(16):                       # the arpeggio
                m = tones[[0, 1, 2, 3, 2, 1, 2, 3][s % 8]] + 12
                synth.add(at(b, s / 4), pluck(m), 0.22, (-0.4, 0.4)[s % 2])
                verb.add(at(b, s / 4), pluck(m), 0.08)
        r = min(2, n)
        fx.add(at(b0 + n - r), riser(r * BAR), 0.6)
        for k in range(24):                           # the roll, then a breath of silence
            drums.add(at(b0 + n - 1, k / 8), S, 0.1 + k * 0.022)

    def outro(b0, n):
        root, chord = PROG[0]
        fx.add(at(b0), boom(3.0), 1.0); fx.add(at(b0), crash(4.0), 0.55)
        held = min(3.2, n - 0.8) * BAR
        synth.add(at(b0), supersaw(chord + [chord[0] + 12], held, attack=0.01, cutoff=5000) * np.exp(-secs(int(held * SR)) / 2.2), 0.6)
        bassB.add(at(b0), bass(root, 2 * BAR), 0.45)
        for q in range(0, 8, 2):
            kick_at(at(b0, q), None, 0.8)
            drums.add(at(b0, q + 1), S, 0.45); verb.add(at(b0, q + 1), S, 0.25)
        if n >= 3:
            fx.add(at(b0 + 2), boom(2.5), 1.0); fx.add(at(b0 + 2), crash(3.0), 0.45)
            drums.add(at(b0 + 2), kick(2.0), 1.0)

    b, prev = 0, None
    for kind, n in P["sections"]:
        if kind == "intro": intro(b, n)
        elif kind == "drop": drop_bars(b, b + n, False, prev not in ("drop", "droplead"))
        elif kind == "droplead": drop_bars(b, b + n, True, prev not in ("drop", "droplead"))
        elif kind == "break": breakdown(b, n)
        elif kind == "outro": outro(b, n)
        b += n
        prev = kind

    # the sidechain: bass and synths duck under every kick
    t = secs(N)
    duck = np.ones(N)
    for tk in kicks:
        i = int(tk * SR); j = min(N, i + int(0.3 * SR))
        duck[i:j] = np.minimum(duck[i:j], 1 - 0.75 * np.exp(-(t[i:j] - tk) / 0.07))
    bassB.x *= duck; synth.x *= duck; leadB.x *= 0.5 + 0.5 * duck

    # the reverb: a send through a decaying-noise room
    ir_n = int(2.2 * SR)
    ir = rng.standard_normal((2, ir_n)) * np.exp(-secs(ir_n) / 0.55)
    ir = fft_filter(ir, lo=200, hi=6000)
    ir /= np.abs(ir).sum(axis=1, keepdims=True) ** 0.5 * 18
    wet = np.zeros((2, N))
    L = N + ir_n
    for ch in (0, 1):
        wet[ch] = np.fft.irfft(np.fft.rfft(verb.x[ch], L) * np.fft.rfft(ir[ch], L), L)[:N]

    mix = drums.x * 1.0 + bassB.x * 0.9 + synth.x * 0.85 + leadB.x * 0.9 + fx.x * 0.8 + wet * 0.9
    mix = fft_filter(mix, lo=28)
    # the master: glue, drive, a soft ceiling, loud
    mix /= np.max(np.abs(mix)) + 1e-9
    mix = np.tanh(2.4 * mix) / np.tanh(2.4)
    mix /= np.max(np.abs(mix)) + 1e-9
    mix *= 0.97
    fade = np.minimum(1.0, (N - np.arange(N)) / (0.6 * SR))
    return mix * fade


def write(x):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    pcm = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    with wave.open(OUT, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    rms = np.sqrt(np.mean(x ** 2))
    print("MUSIC", OUT, f"{x.shape[1] / SR:.1f}s", f"rms {20 * np.log10(rms):.1f} dBFS", flush=True)


if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "anthem"
    write(build(configure(name)))
