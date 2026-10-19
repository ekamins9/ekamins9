"""Skins of one weapon that look alike: the same silhouette (blade, head, hammer), the same guard
and pommel, and close colours. Run it before adding a skin (or a theme's SHAPES row) so no two
skins of a weapon are the same weapon painted differently.

    python scripts/skin_twins.py [--under 110] [--weapon Hammer]

Lower scores are closer twins. Commons and plain finishes twinning each other are expected; an
Epic and up should not appear.
"""
import argparse, io, math, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "blender"))
import themes as TH  # noqa: E402

SWORDS = {"Shortsword", "Greatsword", "ArmingSword", "Dagger", "Longsword", "Cleaver", "Falchion", "Messer", "Estoc",
          "Rapier", "Zweihander", "Executioner"}
SPEARS = {"Spear", "Pitchfork"}
AXES = {"BattleAxe", "WarAxe", "Bardiche"}
HAMMERS = {"Hammer", "Maul"}
BLUNTS = {"Mace", "MorningStar"}
POLES = {"Halberd", "Billhook", "Glaive", "Poleaxe", "Quarterstaff"}


def colour(th):
    c = th["palette"].get("steel") or th["palette"].get("face") or (0.6, 0.6, 0.62)
    return tuple(int(x * 255) for x in c)


def silhouette(weapon, th):
    blade, spear, axe, blunt, _ = TH.SHAPES.get(th["id"], (None,) * 5)
    if weapon in SWORDS:
        return ("blade", blade)
    if weapon in SPEARS:
        return ("spear", spear)
    if weapon in AXES:
        return ("axe", axe)
    if weapon in HAMMERS:
        return ("hammer", th.get("hammer") or blunt)
    if weapon in BLUNTS:
        return ("blunt", blunt)
    if weapon in POLES:
        return ("pole", (spear, axe, blade if weapon == "Glaive" else None))
    return ("other", None)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--under", type=float, default=110)
    ap.add_argument("--weapon")
    a = ap.parse_args()
    src = io.open(os.path.join(ROOT, "roblox", "ReplicatedStorage", "Catalog", "Skins.lua"), encoding="utf-8").read()
    rows = re.findall(r'\{weapon = "(\w+)",\s*name = "([^"]+)",\s*rarity = "(\w+)"[^\n]*?look = "(\w+)"', src)
    by = {}
    for w, name, rarity, look in rows:
        th = TH.THEMES.get(look)
        if not th:
            print("NO THEME", w, name, look)
            continue
        if a.weapon and w != a.weapon:
            continue
        g = th.get("glow")
        by.setdefault(w, []).append((name, rarity, silhouette(w, th), th.get("guard"), th.get("pommel"), colour(th),
                                     tuple(int(x * 255) for x in g["color"]) if g else None))
    found = []
    for w, L in by.items():
        for i in range(len(L)):
            for j in range(i + 1, len(L)):
                p, q = L[i], L[j]
                if p[2] != q[2]:
                    continue
                d = math.dist(p[5], q[5])
                gd = math.dist(p[6], q[6]) if p[6] and q[6] else (0 if not p[6] and not q[6] else 200)
                score = d + 0.6 * gd + (0 if p[3] == q[3] else 60) + (0 if p[4] == q[4] else 30)
                if score < a.under:
                    found.append((score, w, "%s (%s)" % (p[0], p[1]), "%s (%s)" % (q[0], q[1]), p[2]))
    for f in sorted(found):
        print("%5.0f  %-12s %-32s ~ %-32s %s" % f)
    print(len(found), "pairs")


if __name__ == "__main__":
    main()
