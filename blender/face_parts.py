"""FACE PARTS — the layers of the face builder (Catalog ▸ Body ▸ faceParts),
each its own transparent 512x512 PNG on the classic face layout, drawn as
clean ink shapes and rendered headless in Blender (helpers from faces.py):

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python blender/face_parts.py -- [layer_id ...] [--out dir]

Layers (bottom to top on the head): paint · mark · mouth · brows · eyes ·
iris · pupil. TINTED layers are drawn WHITE so a Decal's Color3 colours
them in the game: iris (eye colour), brows (hair colour), paint (paint
colour). Everything else keeps its own colours. Output names:
blender/out/faceparts/<layer>_<id>.png (an eye shape renders eyes_, iris_
and pupil_ images; shapes with no iris render only eyes_).
Canvas: -0.5 .. 0.5, y up; eyes at y 0.07, x +-0.125; mouth near y -0.12.
"""
import bpy, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import faces as F   # noqa: E402  reset, ellipse, poly, stroke, bezier, line, INK, WHITE

OUT = os.path.join(os.path.dirname(HERE), "blender", "out", "faceparts")
INK, WHITE = F.INK, F.WHITE
TEETH = (0.98, 0.97, 0.93)
MOUTH = (0.32, 0.06, 0.08)
TONGUE = (0.9, 0.36, 0.42)
SCAR = (0.72, 0.30, 0.30)
SCAR_DARK = (0.46, 0.15, 0.15)
FRECKLE = (0.55, 0.32, 0.18)
PLASTER = (0.93, 0.80, 0.62)
PLASTER_DOT = (0.75, 0.6, 0.45)
BRUISE = (0.48, 0.28, 0.52)
BLUSH = (0.96, 0.52, 0.58)
EX, EY = 0.125, 0.07


# ------------------------------------------------------------------ geometry
def arc_pts(cx, cy, rx, ry, a0, a1, n=40, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)
    out = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        out.append((cx + x * c - y * s, cy + x * s + y * c))
    return out


def ellipse_pts(cx, cy, rx, ry, rot=0.0, n=64):
    return arc_pts(cx, cy, rx, ry, 0, 2 * math.pi, n, rot)[:-1]


def almond_pts(cx, cy, w, top, bottom, tilt=0.0, n=40):
    """an eye opening: an upper arc `top` high and a lower arc `bottom` deep, w wide; tilt
    raises the outer corner (radians, + = outer corner up); side picks which corner is outer"""
    up = [(cx + w * math.cos(a), cy + top * math.sin(a)) for a in [math.pi * i / n for i in range(n + 1)]]
    lo = [(cx + w * math.cos(a), cy + bottom * math.sin(a)) for a in [math.pi + math.pi * i / n for i in range(1, n)]]
    pts = up + lo
    c, s = math.cos(tilt), math.sin(tilt)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]


def grow(pts, d):
    """push a convex outline out by d (its centroid as the middle)"""
    cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
    out = []
    for x, y in pts:
        dx, dy = x - cx, y - cy
        L = math.hypot(dx, dy) or 1
        out.append((x + dx / L * d, y + dy / L * d))
    return out


def clip(subject, clipper):
    """Sutherland-Hodgman: subject polygon clipped to a convex clipper (both CCW lists)"""
    def inside(p, a, b):
        return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) >= 0

    def cross(p1, p2, a, b):
        dc = (a[0] - b[0], a[1] - b[1]); dp = (p1[0] - p2[0], p1[1] - p2[1])
        n1 = a[0] * b[1] - a[1] * b[0]; n2 = p1[0] * p2[1] - p1[1] * p2[0]
        den = dc[0] * dp[1] - dc[1] * dp[0]
        if abs(den) < 1e-12:
            return p2
        return ((n1 * dp[0] - n2 * dc[0]) / den, (n1 * dp[1] - n2 * dc[1]) / den)

    out = subject
    for i in range(len(clipper)):
        a, b = clipper[i - 1], clipper[i]
        inp, out = out, []
        if not inp:
            break
        s = inp[-1]
        for e in inp:
            if inside(e, a, b):
                if not inside(s, a, b):
                    out.append(cross(s, e, a, b))
                out.append(e)
            elif inside(s, a, b):
                out.append(cross(s, e, a, b))
            s = e
    return out


def ccw(pts):
    area = sum(pts[i - 1][0] * pts[i][1] - pts[i][0] * pts[i - 1][1] for i in range(len(pts)))
    return pts if area > 0 else list(reversed(pts))


def taper(points, w0, w1, wmid, color):
    """a stroke whose width runs w0 -> wmid -> w1 along it (a brow, a lash)"""
    n = len(points)
    left, right = [], []
    for i, (x, y) in enumerate(points):
        t = i / (n - 1)
        w = (w0 + (wmid - w0) * (t / 0.5)) if t < 0.5 else (wmid + (w1 - wmid) * ((t - 0.5) / 0.5))
        if i == 0:
            dx, dy = points[1][0] - x, points[1][1] - y
        elif i == n - 1:
            dx, dy = x - points[i - 1][0], y - points[i - 1][1]
        else:
            dx, dy = points[i + 1][0] - points[i - 1][0], points[i + 1][1] - points[i - 1][1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        left.append((x + nx * w / 2, y + ny * w / 2)); right.append((x - nx * w / 2, y - ny * w / 2))
    F.poly(left + list(reversed(right)), color)
    F.ellipse(points[0][0], points[0][1], w0 / 2, w0 / 2, color, segs=20)
    F.ellipse(points[-1][0], points[-1][1], w1 / 2, w1 / 2, color, segs=20)


# ------------------------------------------------------------------ EYES
# each shape: opening(side) -> the white's outline for that eye (side -1 = viewer's left);
# iris r, pupil r, the iris's centre offset, extra(side) for lids and lashes
def opening_round(side):
    return ellipse_pts(side * EX, EY, 0.05, 0.062)


def opening_big(side):
    return ellipse_pts(side * EX, EY + 0.004, 0.06, 0.074)


def opening_narrow(side):
    return almond_pts(side * EX, EY, 0.058, 0.034, 0.03, tilt=side * 0.12)


def opening_fierce(side):
    return almond_pts(side * EX, EY, 0.056, 0.03, 0.036, tilt=-side * 0.32)


def opening_sleepy(side):
    return almond_pts(side * EX, EY - 0.01, 0.052, 0.02, 0.046)


def opening_wide(side):
    return ellipse_pts(side * EX, EY + 0.006, 0.058, 0.07)


def opening_determined(side):
    return almond_pts(side * EX, EY, 0.056, 0.044, 0.026, tilt=-side * 0.14)


def opening_kind(side):
    return almond_pts(side * EX, EY, 0.054, 0.05, 0.03, tilt=side * 0.2)


EYES = {
    #            opening,             iris r, pupil r, lid line, lashes
    "Round":      (opening_round,      0.034, 0.016, False, False),
    "Big":        (opening_big,        0.045, 0.021, False, False),
    "Narrow":     (opening_narrow,     0.03,  0.015, True,  False),
    "Fierce":     (opening_fierce,     0.03,  0.014, True,  False),
    "Sleepy":     (opening_sleepy,     0.032, 0.015, True,  False),
    "Wide":       (opening_wide,       0.024, 0.011, False, False),
    "Determined": (opening_determined, 0.031, 0.015, True,  False),
    "Kind":       (opening_kind,       0.032, 0.015, False, True),
    "Lashes":     (opening_round,      0.034, 0.016, False, True),
}
OUTLINE = 0.012


def eye_base(shape):
    open_fn, _, _, lid, lashes = EYES[shape]
    for side in (-1, 1):
        o = ccw(open_fn(side))
        F.poly(grow(o, OUTLINE), INK)
        F.poly(o, WHITE)
        top = max(o, key=lambda p: p[1])
        if lid:   # a heavy upper lid: a thick ink line along the top of the opening
            upper = sorted([p for p in o if p[1] >= sum(q[1] for q in o) / len(o)], key=lambda p: p[0])
            F.stroke(upper, 0.02, INK, caps=True)
        if lashes:   # three lashes flicking out at the outer corner
            outer = max(o, key=lambda p: side * p[0])
            for k in range(3):
                a = math.radians(20 + k * 22)
                d = (side * math.cos(a), math.sin(a))
                base = (outer[0] - side * 0.006 * k, outer[1] + 0.012 * k)
                taper([base, (base[0] + d[0] * 0.024, base[1] + d[1] * 0.024), (base[0] + d[0] * 0.04, base[1] + d[1] * 0.044)], 0.012, 0.003, 0.009, INK)


def eye_iris(shape):
    open_fn, ir, _, _, _ = EYES[shape]
    for side in (-1, 1):
        o = ccw(open_fn(side))
        cx = sum(p[0] for p in o) / len(o); cy = sum(p[1] for p in o) / len(o)
        circle = ccw(ellipse_pts(cx + side * 0.004, cy - 0.004, ir, ir))
        part = clip(circle, o)
        if len(part) >= 3:
            F.poly(part, WHITE)


def eye_pupil(shape):
    open_fn, ir, pr, _, _ = EYES[shape]
    for side in (-1, 1):
        o = ccw(open_fn(side))
        cx = sum(p[0] for p in o) / len(o); cy = sum(p[1] for p in o) / len(o)
        x, y = cx + side * 0.004, cy - 0.004
        # a dark ring round the iris's edge, the pupil, two glints (all kept inside the white)
        ring_out = clip(ccw(ellipse_pts(x, y, ir, ir)), o)
        if len(ring_out) >= 3:
            F.stroke(ring_out + [ring_out[0]], 0.006, INK, caps=False)
        for gx, gy, r, col in ((x, y, pr, INK), (x + ir * 0.38, y + ir * 0.42, ir * 0.3, WHITE), (x - ir * 0.35, y - ir * 0.4, ir * 0.13, WHITE)):
            part = clip(ccw(ellipse_pts(gx, gy, r, r)), o)
            if len(part) >= 3:
                F.poly(part, col)


def point_in(p, poly_pts):
    n = len(poly_pts)
    for i in range(n):
        a, b = poly_pts[i - 1], poly_pts[i]
        if (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) < 0:
            return False
    return True


def eye_happy():
    for side in (-1, 1):
        F.stroke(arc_pts(side * EX, EY - 0.02, 0.05, 0.05, math.radians(20), math.radians(160), 24), 0.03, INK)


def eye_wink():
    # the viewer's left eye open (round), the right winking shut
    o = ccw(opening_round(-1))
    F.poly(grow(o, OUTLINE), INK); F.poly(o, WHITE)
    F.stroke(arc_pts(EX, EY - 0.025, 0.05, 0.04, math.radians(200), math.radians(340), 24), 0.03, INK)
    F.stroke([(EX + 0.05, EY - 0.04), (EX + 0.07, EY - 0.02)], 0.016, INK)


def wink_iris():
    o = ccw(opening_round(-1))
    cx, cy = -EX, EY
    p = clip(ccw(ellipse_pts(cx - 0.004, cy - 0.004, 0.034, 0.034)), o)
    F.poly(p, WHITE)


def wink_pupil():
    o = ccw(opening_round(-1))
    x, y = -EX - 0.004, EY - 0.004
    F.poly(clip(ccw(ellipse_pts(x, y, 0.016, 0.016)), o), INK)
    F.poly(clip(ccw(ellipse_pts(x + 0.013, y + 0.014, 0.01, 0.01)), o), WHITE)


# ------------------------------------------------------------------ BROWS (white: tinted with the hair colour)
def brow_pair(inner, outer, bend, w0=0.016, wmid=0.03, w1=0.012, inner_x=0.06, outer_x=0.19):
    for side in (-1, 1):
        a = (side * inner_x, inner); b = (side * outer_x, outer)
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + bend)
        taper(F.bezier(a, mid, b, 16), w0, w1, wmid, WHITE)


BROWS = {
    "Soft":     lambda: brow_pair(0.165, 0.17, 0.022),
    "Thick":    lambda: brow_pair(0.17, 0.168, 0.008, w0=0.034, wmid=0.044, w1=0.026),
    "Angry":    lambda: brow_pair(0.135, 0.2, -0.004, w0=0.032, wmid=0.036, w1=0.018),
    "Raised":   lambda: brow_pair(0.2, 0.19, 0.03),
    "Worried":  lambda: brow_pair(0.205, 0.158, 0.008, w0=0.026, wmid=0.028, w1=0.014),
    "Thin":     lambda: brow_pair(0.17, 0.172, 0.018, w0=0.008, wmid=0.014, w1=0.006),
    "Unibrow":  lambda: (brow_pair(0.17, 0.168, 0.008, w0=0.034, wmid=0.04, w1=0.026), taper([(-0.07, 0.17), (0, 0.162), (0.07, 0.17)], 0.03, 0.03, 0.024, WHITE)),
    "Scarred":  lambda: (brow_pair(0.165, 0.172, 0.012, w0=0.03, wmid=0.036, w1=0.022)),
}


# ------------------------------------------------------------------ MOUTHS (their own colours)
def fill(pts, color):
    if pts and len(pts) >= 3:
        F.poly(pts, color)


def open_mouth(top_y, depth, half_w, teeth=True, tongue=True, lower_teeth=False):
    top = [(-half_w, top_y)] + F.bezier((-half_w, top_y), (0, top_y + 0.012), (half_w, top_y), 20)[1:]
    bottom = F.bezier((half_w, top_y), (0, top_y - depth * 2), (-half_w, top_y), 26)[1:-1]
    shape = top + bottom
    F.poly(grow(ccw(shape), 0.012), INK)
    F.poly(ccw(shape), MOUTH)
    if tongue:
        fill(clip(ccw(ellipse_pts(0, top_y - depth * 0.95, half_w * 0.55, depth * 0.42)), ccw(shape)), TONGUE)
    if teeth:
        fill(clip(ccw([(-half_w, top_y + 0.01), (half_w, top_y + 0.01), (half_w, top_y - 0.03), (-half_w, top_y - 0.03)]), ccw(shape)), TEETH)
    if lower_teeth:
        fill(clip(ccw([(-half_w, top_y - depth * 1.2), (half_w, top_y - depth * 1.2), (half_w, top_y - depth * 2), (-half_w, top_y - depth * 2)]), ccw(shape)), TEETH)


MOUTHS = {
    "Smile":   lambda: F.stroke(F.bezier((-0.115, -0.085), (0, -0.19), (0.115, -0.085)), 0.028, INK),
    "Grin":    lambda: open_mouth(-0.075, 0.07, 0.14),
    "Open":    lambda: open_mouth(-0.09, 0.05, 0.085, teeth=True, tongue=True),
    "Smirk":   lambda: (F.stroke(F.bezier((-0.09, -0.13), (0.03, -0.15), (0.11, -0.085)), 0.026, INK), F.stroke([(0.12, -0.075), (0.128, -0.1)], 0.014, INK)),
    "Flat":    lambda: F.stroke([(-0.08, -0.13), (0.08, -0.13)], 0.026, INK),
    "Frown":   lambda: F.stroke(F.bezier((-0.1, -0.16), (0, -0.07), (0.1, -0.16)), 0.026, INK),
    "Shout":   lambda: open_mouth(-0.07, 0.1, 0.1, lower_teeth=True),
    "Toothy":  lambda: (F.poly(ccw(grow([(-0.13, -0.08), (0.13, -0.08), (0.11, -0.16), (-0.11, -0.16)], 0.014)), INK),
                        F.poly(ccw([(-0.13, -0.08), (0.13, -0.08), (0.11, -0.16), (-0.11, -0.16)]), TEETH),
                        F.stroke([(-0.125, -0.12), (0.125, -0.12)], 0.008, INK),
                        [F.stroke([(x, -0.085), (x, -0.155)], 0.007, INK) for x in (-0.07, -0.023, 0.023, 0.07)]),
    "Tongue":  lambda: (F.poly(ccw(grow(ellipse_pts(0.025, -0.15, 0.04, 0.05), 0.012)), INK), F.poly(ccw(ellipse_pts(0.025, -0.15, 0.04, 0.05)), TONGUE),
                        F.stroke([(0.025, -0.13), (0.025, -0.175)], 0.007, (0.7, 0.22, 0.28)),
                        F.stroke(F.bezier((-0.115, -0.09), (0, -0.16), (0.115, -0.09)), 0.028, INK)),
    "Whistle": lambda: (F.poly(ccw(ellipse_pts(0.02, -0.12, 0.034, 0.03)), INK), F.poly(ccw(ellipse_pts(0.02, -0.12, 0.016, 0.014)), MOUTH)),
    "Fangs":   lambda: (F.stroke(F.bezier((-0.12, -0.085), (0, -0.18), (0.12, -0.085)), 0.028, INK),
                        [F.poly([(s * 0.05 - 0.016, -0.118), (s * 0.05 + 0.016, -0.118), (s * 0.05, -0.17)], TEETH) for s in (-1, 1)],
                        [F.stroke([(s * 0.05 - 0.016, -0.118), (s * 0.05, -0.17), (s * 0.05 + 0.016, -0.118)], 0.006, INK, caps=False) for s in (-1, 1)]),
    "Grimace": lambda: (F.poly(ccw(grow([(-0.12, -0.1), (0.12, -0.1), (0.12, -0.15), (-0.12, -0.15)], 0.012)), INK),
                        F.poly(ccw([(-0.12, -0.1), (0.12, -0.1), (0.12, -0.15), (-0.12, -0.15)]), TEETH),
                        F.stroke([(-0.12, -0.125), (0.12, -0.125)], 0.007, INK),
                        [F.stroke([(x, -0.1), (x, -0.15)], 0.006, INK) for x in (-0.08, -0.04, 0, 0.04, 0.08)]),
}


# ------------------------------------------------------------------ MARKS (their own colours)
def stitches(p0, p1, p2, color, dark, n=4):
    pts = F.bezier(p0, p1, p2, 16)
    F.stroke(pts, 0.018, color)
    for i in range(1, n + 1):
        t = i / (n + 1)
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        F.line((x - 0.022, y - 0.012), (x + 0.022, y + 0.012), 0.009, dark)


MARKS = {
    "CheekScar": lambda: stitches((-0.24, -0.02), (-0.2, -0.07), (-0.15, -0.13), SCAR, SCAR_DARK, 3),
    "EyeScar":   lambda: stitches((0.1, 0.26), (0.135, 0.07), (0.16, -0.08), SCAR, SCAR_DARK, 4),
    "Freckles":  lambda: [F.ellipse(x, y, 0.009, 0.009, FRECKLE, segs=16) for x, y in
                          [(-0.2, 0.0), (-0.17, -0.03), (-0.14, 0.005), (-0.22, -0.04), (0.2, 0.0), (0.17, -0.03), (0.14, 0.005), (0.22, -0.04), (-0.025, 0.02), (0.025, 0.02)]],
    "Bandage":   lambda: (F.poly(ccw([(0.13, -0.02), (0.25, 0.03), (0.27, -0.01), (0.15, -0.06)]), PLASTER),
                          F.poly(ccw([(0.17, 0.04), (0.23, -0.07), (0.27, -0.05), (0.21, 0.06)]), PLASTER),
                          [F.ellipse(x, y, 0.005, 0.005, PLASTER_DOT, segs=10) for x, y in [(0.19, -0.01), (0.21, -0.005), (0.2, -0.025)]]),
    "Stitches":  lambda: stitches((-0.12, 0.31), (0, 0.27), (0.13, 0.3), SCAR, SCAR_DARK, 5),
    "Bruise":    lambda: (F.poly(ccw(ellipse_pts(0.13, -0.005, 0.05, 0.022)), BRUISE), F.poly(ccw(ellipse_pts(0.13, 0.0, 0.034, 0.014)), (0.6, 0.38, 0.62))),
    "Blush":     lambda: [F.poly(ccw(ellipse_pts(s * 0.19, -0.04, 0.045, 0.022)), BLUSH) for s in (-1, 1)],
    "Eyepatch":  lambda: (F.stroke([(-0.4, 0.2), (0.4, -0.02)], 0.022, (0.16, 0.10, 0.07), caps=False),
                          F.poly(ccw(grow(ellipse_pts(EX, EY, 0.07, 0.075), 0.01)), INK), F.poly(ccw(ellipse_pts(EX, EY, 0.07, 0.075)), (0.12, 0.1, 0.1))),
    "Mole":      lambda: F.ellipse(-0.11, -0.06, 0.011, 0.011, (0.3, 0.18, 0.12), segs=20),
}


# ------------------------------------------------------------------ WAR PAINT (white: tinted with the paint colour)
PAINTS = {
    "Stripes":  lambda: [F.stroke([(s * 0.14, y), (s * 0.27, y + 0.01)], 0.024, WHITE) for s in (-1, 1) for y in (-0.03, -0.075)],
    "Band":     lambda: F.poly(ccw([(-0.31, 0.12), (0.31, 0.12), (0.3, 0.015), (-0.3, 0.015)]), WHITE),
    "Woad":     lambda: F.poly(ccw([(-0.36, 0.34), (-0.004, 0.34), (-0.004, -0.3), (-0.3, -0.3), (-0.37, 0.0)]), WHITE),
    "Tears":    lambda: [taper([(s * EX, EY - 0.08), (s * (EX + 0.004), EY - 0.17), (s * EX, EY - 0.26)], 0.02, 0.006, 0.018, WHITE) for s in (-1, 1)],
    "Chevron":  lambda: [F.stroke([(s * 0.13, -0.01), (s * 0.2, -0.06), (s * 0.27, -0.01)], 0.02, WHITE, caps=True) for s in (-1, 1)],
    "Skull":    lambda: (F.poly(ccw(grow(ellipse_pts(-EX, EY, 0.075, 0.08), 0.0)), WHITE), F.poly(ccw(ellipse_pts(EX, EY, 0.075, 0.08)), WHITE),
                         [F.stroke([(x, -0.2), (x, -0.27)], 0.014, WHITE) for x in (-0.09, -0.045, 0.0, 0.045, 0.09)]),
    "Tribal":   lambda: (taper(F.bezier((0.06, 0.28), (0.3, 0.2), (0.22, -0.04), 20), 0.01, 0.006, 0.03, WHITE),
                         taper(F.bezier((0.16, 0.0), (0.26, -0.14), (0.12, -0.24), 16), 0.006, 0.004, 0.022, WHITE)),
}


# ------------------------------------------------------------------ the jobs
def jobs():
    out = []
    for k in EYES:
        out.append(("eyes_" + k, lambda k=k: eye_base(k)))
        out.append(("iris_" + k, lambda k=k: eye_iris(k)))
        out.append(("pupil_" + k, lambda k=k: eye_pupil(k)))
    out.append(("eyes_Happy", eye_happy))
    out.append(("eyes_Wink", eye_wink)); out.append(("iris_Wink", wink_iris)); out.append(("pupil_Wink", wink_pupil))
    for k, fn in BROWS.items():
        out.append(("brows_" + k, fn))
    for k, fn in MOUTHS.items():
        out.append(("mouth_" + k, fn))
    for k, fn in MARKS.items():
        out.append(("mark_" + k, fn))
    for k, fn in PAINTS.items():
        out.append(("paint_" + k, fn))
    return out


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_dir = OUT
    if "--out" in argv:
        i = argv.index("--out"); out_dir = argv[i + 1]; del argv[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for name, fn in jobs():
        if argv and name not in argv:
            continue
        sc = F.reset()
        F._mats.clear()   # (a reset removes the materials faces.py cached)
        sc.cycles.samples = 16
        fn()
        sc.render.filepath = os.path.join(out_dir, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("RENDERED", name)
