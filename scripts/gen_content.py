#!/usr/bin/env python3
"""Generates the weapon Tool folders, the armor set folders and the Catalog
Weapons / Skins modules from the tables below. Run from the repo root after
editing a table:  python3 scripts/gen_content.py
Hand-edited files are never touched: it only writes the generated ones."""
import json, os, textwrap
ROOT = os.path.join(os.path.dirname(__file__), "..", "roblox")

ANIMS = {"IDLE_ID": "rbxassetid://132465214430348", "BLOCK_ID": "rbxassetid://72812411957933"}
ANIMS_1H = {"IDLE_ID": "rbxassetid://135659407369438", "BLOCK_ID": "rbxassetid://72812411957933"}
ATTACK_ANIMS = {
    "LeftSwing": "133334061889126", "RightSwing": "73820534240915", "LeftStab": "94684673453479",
    "RightStab": "108978202248647", "LeftOverhead": "127511139053596", "RightOverhead": "81289899270401",
    "LeftUnderhand": "0", "RightUnderhand": "0",
}

# id: (name, family, two_handed, secondary, speed, reach, slash, stab, speedMult, clunkMult, stabSpeed, description, unlock, marks)
WEAPONS = [
 ("Shortsword",  "Shortsword",        "OneHanded", False, True,  0.55, 4.0, 20, 20, 1.0, 1.0, 1.1, "A short, broad sidearm. Quick, close, and always there when the main weapon is not.", {"free": True}, 0),
 ("Pitchfork",   "Pitchfork",         "Polearm",   True,  False, 0.5,  9.0, 15, 22, 0.98, 1.0, 1.15, "Three tines of farm iron on an ash pole. The levy's spear, and it reaches just as far.", {"level": 2}, 300),
 ("Greatsword",  "Greatsword",        "TwoHanded", True,  False, 0.4,  9.0, 30, 30, 0.94, 1.1, 1.0, "Six feet of steel swung in great arcs. Every hit lands like a hammer, but it takes both hands and a wide stance.", {"free": True}, 0),
 ("Hammer",      "War Hammer",        "OneHanded", False, True,  0.45, 4.0, 20, 20, 1.0, 1.0, 1.0, "A small head on a short haft, with a spike on the back for helmets. Armor means nothing to it.", {"free": True}, 0),
 ("ArmingSword", "Arming Sword",      "OneHanded", False, True,  0.5,  5.0, 22, 20, 1.0, 1.0, 1.05, "The knight's sidearm: a straight cut-and-thrust blade that is quick in the hand and honest about its reach.", {"free": True}, 0),
 ("Dagger",      "Rondel Dagger",     "OneHanded", False, True,  0.75, 3.2, 14, 18, 1.04, 0.9, 1.15, "A hand's breadth of steel. Useless at range, deadly inside it: the stab goes through mail.", {"level": 2}, 500),
 ("Longsword",   "Longsword",         "TwoHanded", True,  False, 0.5,  6.5, 26, 24, 0.98, 1.05, 1.0, "Hand-and-a-half and fast for a two-hander. The fencer's weapon: feints, chambers, ripostes.", {"level": 3}, 900),
 ("Mace",        "Flanged Mace",      "OneHanded", False, True,  0.46, 4.6, 26, 14, 1.0, 1.05, 0.9, "Flanges that bite through plate. Slow to thrust, but a hit is a hit no matter what they're wearing.", {"level": 4}, 900),
 ("Cleaver",     "Cleaver",           "OneHanded", False, True,  0.52, 4.0, 24, 8,  1.0, 1.0, 0.8, "Taken from a butcher's block. Heavy chop, no point to speak of.", {"level": 4}, 600),
 ("Falchion",    "Falchion",          "OneHanded", False, True,  0.48, 4.8, 26, 12, 1.0, 1.0, 0.9, "A broad, forward-weighted blade. Cuts like an axe, swings like a sword.", {"level": 6}, 1000),
 ("BattleAxe",   "Battle Axe",        "TwoHanded", True,  False, 0.4,  7.0, 32, 14, 0.96, 1.15, 0.8, "A great bearded axe. The swing takes a moment; whatever it meets takes longer.", {"level": 7}, 1300),
 ("MorningStar", "Morning Star",      "OneHanded", False, False, 0.44, 5.0, 28, 16, 1.0, 1.1, 0.9, "A spiked ball on a haft. Blunt and sharp at once; nobody blocks it comfortably.", {"level": 8}, 1200),
 ("Halberd",     "Halberd",           "Polearm",   True,  False, 0.38, 10.0, 32, 26, 0.94, 1.15, 1.0, "Axe, spike and hook on a long pole. The infantry's answer to everything, if you can keep them at the end of it.", {"level": 8}, 1600),
 ("Messer",      "Kriegsmesser",      "OneHanded", False, False, 0.46, 5.8, 27, 18, 0.99, 1.05, 0.95, "A long single-edged knife with a nagel to guard the hand. Reach of a longsword, speed of a sword.", {"level": 9}, 1300),
 ("Maul",        "Maul",              "TwoHanded", True,  False, 0.3,  7.5, 40, 14, 0.9, 1.3, 0.7, "A sledge for men. One clean hit ends an argument; one miss ends you.", {"level": 10}, 1800),
 ("Billhook",    "Billhook",          "Polearm",   True,  False, 0.42, 9.5, 26, 22, 0.95, 1.1, 1.0, "The farmer's hedge tool, lengthened and sharpened. Its hook pulls riders and shields alike.", {"level": 10}, 1200),
 ("Estoc",       "Estoc",             "TwoHanded", True,  False, 0.46, 7.0, 14, 32, 0.98, 1.0, 1.1, "A blade with no edge, only a point, meant to find the gaps in plate. Thrust, don't swing.", {"level": 11}, 1500),
 ("Rapier",      "Rapier",            "OneHanded", False, True,  0.6,  6.0, 12, 24, 1.02, 0.95, 1.2, "Long, light and precise. The thrust arrives before the wind-up is noticed.", {"level": 12}, 1500),
 ("Glaive",      "Glaive",            "Polearm",   True,  False, 0.4,  10.0, 30, 20, 0.95, 1.1, 0.95, "A sword blade on a pole. Sweeps that reach the second rank.", {"level": 13}, 1600),
 ("Poleaxe",     "Poleaxe",           "Polearm",   True,  False, 0.4,  9.5, 30, 24, 0.94, 1.15, 1.0, "Hammer head, fluke and top spike: the knight's own polearm for fighting other knights.", {"level": 14}, 1800),
 ("Bardiche",    "Bardiche",          "TwoHanded", True,  False, 0.36, 8.5, 34, 18, 0.94, 1.2, 0.85, "A long crescent blade bound to a long haft. Few things cut deeper.", {"level": 15}, 1800),
 ("Zweihander",  "Zweihander",        "TwoHanded", True,  False, 0.36, 9.5, 34, 28, 0.93, 1.15, 1.0, "The great two-hander of the Landsknechte, with rings and a leather ricasso. Every swing is a wall of steel.", {"level": 16}, 2200),
 ("Executioner", "Executioner's Sword","TwoHanded", True, False, 0.38, 8.0, 36, 10, 0.94, 1.15, 0.6, "Broad, flat-tipped, built for one job. No point, all edge.", {"level": 18}, 2400),
 ("WarAxe",      "War Axe",           "OneHanded", False, True,  0.48, 4.8, 26, 10, 1.0, 1.05, 0.8, "A one-handed axe, light enough to carry as a sidearm and heavy enough to open a helm.", {"level": 3}, 500),
 ("Spear",       "Spear",             "Polearm",   True,  False, 0.5,  10.5, 12, 26, 0.98, 1.0, 1.15, "The oldest weapon there is. Keep the point between you and them.", {"free": True}, 0),
 ("Quarterstaff","Quarterstaff",      "Polearm",   True,  False, 0.62, 8.0, 14, 14, 1.0, 0.9, 1.0, "Iron-shod oak. It kills nobody quickly, and nobody gets near you either.", {"level": 3}, 400),
]
# the Archer's primaries: their Tools are hand-written (Tools/Bow, Tools/Crossbow)
RANGED = [
 ("Bow",      "Longbow",  {"free": True}, 0),
 ("Crossbow", "Crossbow", {"level": 3},   600),
]
# ARMOR PENETRATION: the share of a target's armor protection the weapon ignores
# (CombatServer: protection x (1 - ARMOR_PEN)). Blunt heads and armor-piercing
# points beat plate; edges don't.
PEN = {"Hammer": 0.6, "Maul": 0.6, "Mace": 0.5, "MorningStar": 0.45, "Poleaxe": 0.4, "Estoc": 0.4,
       "Dagger": 0.35, "Quarterstaff": 0.3, "BattleAxe": 0.25, "WarAxe": 0.2, "Halberd": 0.2,
       "Bardiche": 0.15, "Spear": 0.15, "Rapier": 0.1, "Pitchfork": 0.1}
EXISTING = set()   # every Tool folder is generated now (the four originals were remade as meshes)

CONFIG = '''--[[ {UPPER} — weapon config (ModuleScript inside the Tool).
     Only what makes this weapon different goes here; everything else comes
     from CombatServer.DEFAULTS / CombatClient.DEFAULTS and can be overridden
     by adding the key here. Both the server and client read this module.
     The Tool's body is built from Build ▸ Weapons.{id} if it has no Handle. ]]

return {{
	Name        = "{name}",
	Description = "{desc}",

	HIT_ID   = "rbxassetid://0",
	IDLE_ID  = "{idle}",
	BLOCK_ID = "{block}",

	SPEED_MULT = {speed},
	TYPE_SPEED = {{Swing = 1.0, Stab = {stabSpeed}, Overhead = 1.0, Underhand = 1.0}},
	WINDUP     = 0.15,
	RECOVERY   = 0.15,
	REACH      = {reach},
	TWO_HANDED = {two},
	SECONDARY  = {sec},

	SpeedMult = {speedMult},
	ClunkMult = {clunkMult},
	ARMOR_PEN = {pen},   -- the share of a target's armor protection it ignores

	ATTACKS = {{
{attacks}
	}},
}}
'''
SERVER = '''-- Script inside the Tool. All logic lives in ServerScriptService.Combat.CombatServer.
local CombatServer = require(game:GetService("ServerScriptService"):WaitForChild("Combat"):WaitForChild("CombatServer"))
CombatServer.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
'''
CLIENT = '''-- LocalScript inside the Tool. All logic lives in ReplicatedStorage.Combat.CombatClient.
local CombatClient = require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("CombatClient"))
CombatClient.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
'''

def lua_bool(b): return "true" if b else "false"

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f: f.write(text)

def gen_tools():
    for (wid, name, fam, two, sec, speed, reach, slash, stab, sm, cm, ss, desc, unlock, marks) in WEAPONS:
        if wid in EXISTING: continue
        attacks = []
        for key, aid in ATTACK_ANIMS.items():
            kind = "stab" if "Stab" in key else "slash"
            dmg = stab if kind == "stab" else slash
            block = int(round(dmg * 0.75))
            stam = max(4, int(round(dmg * 0.3)))
            attacks.append(f'\t\t{key:<15}= {{anim="rbxassetid://{aid}", kind="{kind}", damage={dmg}, blockCost={block}, staminaCost={stam}}},')
        anims = ANIMS if two else ANIMS_1H
        cfg = CONFIG.format(UPPER=name.upper(), id=wid, name=name, desc=desc.replace('"', '\\"'), idle=anims["IDLE_ID"], block=anims["BLOCK_ID"],
                            speed=speed, stabSpeed=ss, reach=reach, two=lua_bool(two), sec=lua_bool(sec), speedMult=sm, clunkMult=cm, pen=PEN.get(wid, 0),
                            attacks="\n".join(attacks))
        d = os.path.join(ROOT, "Tools", wid)
        write(os.path.join(d, "Config.lua"), cfg)
        write(os.path.join(d, "Server.server.lua"), SERVER)
        write(os.path.join(d, "Client.client.lua"), CLIENT)
        write(os.path.join(d, "init.meta.json"), json.dumps({"className": "Tool", "ignoreUnknownInstances": True,
              "properties": {"ToolTip": name, "CanBeDropped": False}}, indent=2) + "\n")

def gen_catalog_weapons():
    lines = ['--[[ WEAPONS — every Tool in ServerStorage ▸ Weapons that players may carry,',
             '     and how it is unlocked. GENERATED by scripts/gen_content.py from its',
             '     WEAPONS table (edit there, or edit here and stop running the script).',
             '       id        the Tool\'s name        name     shown in menus',
             '       family    "OneHanded" | "TwoHanded" | "Polearm" | "Ranged"   (kill counts and crates group by it)',
             '       ranged    a bow or a crossbow: the Archer\'s primary, nobody else\'s (Catalog.weaponFits)',
             '       secondary true = may be carried as the secondary (the Tool\'s Config SECONDARY must also be true)',
             '       unlock    {free = true} | {level = 5} | {kills = 40, family = "OneHanded"}',
             '       marks     price to buy it outright instead of unlocking (0 = cannot be bought)',
             '       weights   optional list of weights that may carry it; nil = any',
             '     The Tool\'s body and its menu display copy are built from Build ▸ Weapons',
             '     when no hand-made model exists. ]]', 'return {']
    for (wid, name, fam, two, sec, speed, reach, slash, stab, sm, cm, ss, desc, unlock, marks) in WEAPONS:
        u = ", ".join(f'{k} = {lua_bool(v) if isinstance(v, bool) else (repr(v) if isinstance(v, str) else v)}' for k, v in unlock.items())
        m = f", marks = {marks}" if marks else ""
        lines.append(f'\t{{id = "{wid}", name = "{name}", family = "{fam}", secondary = {lua_bool(sec)}, unlock = {{{u}}}{m}}},')
    # the bows (hand-written Tools under Tools/Bow, Tools/Crossbow: RangedServer, not CombatServer)
    for (wid, name, unlock, marks) in RANGED:
        u = ", ".join(f'{k} = {lua_bool(v) if isinstance(v, bool) else v}' for k, v in unlock.items())
        m = f", marks = {marks}" if marks else ""
        lines.append(f'\t{{id = "{wid}", name = "{name}", family = "Ranged", secondary = false, ranged = true, unlock = {{{u}}}{m}}},')
    lines.append('}')
    write(os.path.join(ROOT, "ReplicatedStorage", "Catalog", "Weapons.lua"), "\n".join(lines) + "\n")

# skin palettes: name -> rarity, blade / grip rgb, the trim (ReplicatedStorage >
# SkinTrims: the parts that change the weapon's shape) and optional accent / glow
TINTS = {
 "Blackened":  dict(rarity="Rare",      blade=(58, 61, 68),    grip=(42, 42, 42),   trim="studs", accent=(40, 40, 44)),
 "Bluesteel":  dict(rarity="Rare",      blade=(138, 168, 216), grip=(42, 42, 74),   trim="fuller", accent=(70, 120, 220)),
 "Pitted":     dict(rarity="Common",    blade=(154, 154, 138), grip=(74, 58, 42),   trim="wrap"),
 "Oiled":      dict(rarity="Common",    blade=(120, 126, 136), grip=(58, 42, 26),   trim="rings", accent=(60, 62, 68)),
 "Bronzed":    dict(rarity="Common",    blade=(176, 120, 72),  grip=(74, 42, 26),   trim="rivets", accent=(196, 140, 80)),
 "Crowfeather":dict(rarity="Epic",      blade=(42, 42, 48),    grip=(201, 154, 72), trim="feather"),
 "Bloodrust":  dict(rarity="Epic",      blade=(120, 48, 40),   grip=(40, 30, 26),   trim="spikes", accent=(110, 44, 36)),
 "Gilded":     dict(rarity="Legendary", blade=(242, 226, 176), grip=(201, 154, 72), trim="crown", glow=(220, 40, 60)),
 "Frostbite":  dict(rarity="Legendary", blade=(200, 236, 255), grip=(60, 90, 140),  trim="frost", glow=(190, 236, 255)),
 "Ember":      dict(rarity="Rare",      blade=(216, 106, 58),  grip=(58, 42, 26),   trim="fuller", glow=(255, 130, 40)),
 "Verdigris":  dict(rarity="Rare",      blade=(96, 160, 140),  grip=(74, 58, 42),   trim="laurel", accent=(90, 170, 120)),
 "Royal":      dict(rarity="Epic",      blade=(226, 232, 240), grip=(70, 90, 200),  trim="royal", glow=(60, 120, 255)),
 "Veteran":    dict(rarity="Epic",      blade=(184, 192, 200), grip=(106, 42, 42),  trim="laurel"),
}
SWORDS = {"Shortsword", "Greatsword", "ArmingSword", "Dagger", "Longsword", "Falchion", "Messer", "Estoc", "Rapier", "Zweihander", "Executioner", "Cleaver"}
# per weapon: list of (skin, crate) ; crate None = shop skin (marks), "earned" = kill skin
def skins_for(wid):
    if wid in SWORDS:
        base = [("Pitted", "Bladesmith"), ("Blackened", "Bladesmith"), ("Bluesteel", "Bladesmith"), ("Crowfeather", "Bladesmith"), ("Gilded", "Royal"), ("Veteran", "earned")]
    else:
        base = [("Oiled", "Hafted"), ("Bronzed", "Hafted"), ("Ember", "Hafted"), ("Bloodrust", "Hafted"), ("Frostbite", "Hafted"), ("Veteran", "earned")]
    if wid in ("Longsword", "Zweihander", "Halberd", "Poleaxe", "Rapier", "ArmingSword"): base.insert(4, ("Royal", "Royal"))
    if wid in ("Spear", "Quarterstaff", "Pitchfork", "Shortsword", "WarAxe", "ArmingSword"): base.append(("Verdigris", None))
    return base

# CRATES STAY SMALL AND THEMED: a crate finish is IN its crate only on these
# weapons (about 12-17 items a crate, a few legendaries). The finish on every
# other weapon is still made, but sold on the daily WEAPONS shelf instead
# (SHELF_PRICE by rarity, on the days the store offers it): never lost.
CRATE_PICKS = {
 # Bladesmith (swords)
 "Pitted":      {"Longsword", "ArmingSword", "Messer", "Dagger"},
 "Bluesteel":   {"Zweihander", "Rapier", "Falchion"},
 "Blackened":   {"Executioner", "Estoc", "Cleaver"},
 "Crowfeather": {"Longsword", "Dagger"},
 # Hafted (axes, maces, polearms)
 "Oiled":       {"Halberd", "Spear"},
 "Bronzed":     {"BattleAxe", "Maul"},
 "Ember":       {"Glaive", "Poleaxe", "WarAxe", "Quarterstaff"},
 "Bloodrust":   {"Maul", "Bardiche", "MorningStar"},
 "Frostbite":   {"Halberd", "BattleAxe"},
 # Royal
 "Royal":       {"Longsword", "Zweihander", "Rapier"},
 "Gilded":      {"Longsword"},
}
SHELF_PRICE = {"Common": "marks = 500", "Rare": "marks = 900, crowns = 45", "Epic": "marks = 1600, crowns = 80",
               "Legendary": "marks = 3200, crowns = 160", "Mythic": "marks = 6000, crowns = 300"}

# THE DAILY STORE'S WEAPONS SHELF: every weapon gets two of these (one plain,
# one showy), sold only on the days Catalog > Store offers them
SHOP_STYLES = {
 "Hunter":     dict(rarity="Common",    marks=500,              blade=(110, 116, 104), grip=(60, 80, 48),  trim="wrap", accent=(70, 96, 52)),
 "Ashen":      dict(rarity="Common",    marks=500,              blade=(150, 148, 146), grip=(70, 70, 72),  trim="rivets", accent=(120, 118, 116)),
 "Duelist":    dict(rarity="Rare",      marks=900,  crowns=45,  blade=(226, 228, 232), grip=(150, 30, 40), trim="fuller", accent=(170, 30, 44)),
 "Wyrmscale":  dict(rarity="Rare",      marks=900,  crowns=45,  blade=(70, 110, 80),   grip=(40, 60, 40),  trim="studs", accent=(150, 120, 60)),
 "Thornguard": dict(rarity="Epic",      marks=1600, crowns=80,  blade=(40, 36, 34),    grip=(120, 80, 40), trim="spikes", accent=(180, 120, 60)),
 "Nightfall":  dict(rarity="Epic",      marks=1600, crowns=80,  blade=(30, 30, 44),    grip=(60, 40, 90),  trim="runes", glow=(160, 110, 255)),
 "Sunsteel":   dict(rarity="Legendary", crowns=150,             blade=(255, 224, 150), grip=(180, 120, 50), trim="halo", glow=(255, 220, 120)),
 "Hellforged": dict(rarity="Legendary", crowns=150,             blade=(40, 30, 28),    grip=(90, 20, 10),  trim="flame", glow=(255, 120, 30)),
}
SHOP_PAIRS = [("Hunter", "Thornguard"), ("Duelist", "Sunsteel"), ("Ashen", "Nightfall"), ("Wyrmscale", "Hellforged")]

# TASK SKINS: earned by finishing daily tasks (contracts), counted for life
TASK_SKINS = [
 ("ArmingSword", "Squire's Oath", "Rare",      3,  dict(blade=(236, 238, 244), grip=(50, 80, 170),  trim="rings", accent=(232, 184, 74))),
 ("Spear",       "Wayfarer",      "Rare",      7,  dict(blade=(220, 224, 232), grip=(60, 90, 170),  trim="wrap", accent=(232, 184, 74))),
 ("Longsword",   "Oathbound",     "Epic",      12, dict(blade=(240, 242, 248), grip=(40, 70, 160),  trim="laurel")),
 ("WarAxe",      "Ironvow",       "Epic",      20, dict(blade=(210, 214, 222), grip=(40, 60, 140),  trim="studs", accent=(232, 184, 74))),
 ("Mace",        "Lionheart",     "Epic",      30, dict(blade=(246, 230, 180), grip=(150, 30, 40),  trim="royal", glow=(220, 40, 60))),
 ("Halberd",     "Warden's Vow",  "Legendary", 45, dict(blade=(236, 240, 250), grip=(40, 60, 150),  trim="halo", glow=(170, 210, 255))),
 ("Zweihander",  "Dawnbringer",   "Legendary", 60, dict(blade=(255, 240, 200), grip=(230, 230, 236), trim="flame", glow=(255, 236, 170))),
 ("Maul",        "Last Bastion",  "Legendary", 80, dict(blade=(225, 228, 236), grip=(36, 50, 120),  trim="crown", glow=(60, 120, 255))),
]

# SEASON PASS SKINS (Catalog > Pass names them): pass = true, so nothing else sells them.
# Season 1, The Iron Crown: dark iron with gold.
IRON, IRONGRIP, CROWNGOLD = (150, 154, 164), (46, 46, 54), (232, 184, 74)
PASS_SKINS = [
 ("ArmingSword", "Ironclad",          "Rare",      dict(blade=IRON, grip=IRONGRIP, trim="rivets", accent=CROWNGOLD)),
 ("Spear",       "Crownspike",        "Rare",      dict(blade=IRON, grip=(90, 30, 30), trim="spikes", accent=CROWNGOLD)),
 ("Shortsword",  "Iron Oath",         "Rare",      dict(blade=(176, 180, 188), grip=(60, 40, 30), trim="rings", accent=(110, 112, 120))),
 ("WarAxe",      "Ironbark",          "Epic",      dict(blade=(120, 124, 132), grip=(70, 50, 34), trim="studs", accent=CROWNGOLD)),
 ("Longsword",   "Crownguard",        "Epic",      dict(blade=(200, 204, 212), grip=(110, 24, 30), trim="royal", glow=(255, 200, 80))),
 ("Mace",        "Iron Lion",         "Epic",      dict(blade=(110, 112, 120), grip=IRONGRIP, trim="laurel", accent=CROWNGOLD)),
 ("Pitchfork",   "Iron Tines",        "Epic",      dict(blade=(96, 100, 108), grip=(80, 56, 36), trim="notch")),
 ("Halberd",     "Kingsguard",        "Epic",      dict(blade=(196, 200, 210), grip=(120, 20, 30), trim="royal", glow=(220, 40, 60))),
 ("Greatsword",  "Last Light",        "Legendary", dict(blade=(236, 238, 244), grip=(40, 40, 52), trim="halo", glow=(255, 240, 190))),
 ("Maul",        "Anvil of Kings",    "Legendary", dict(blade=(70, 72, 80), grip=(40, 30, 24), trim="thunder", glow=(255, 196, 80))),
 ("Dagger",      "Crown's Fang",      "Epic",      dict(blade=(180, 184, 192), grip=(30, 30, 36), trim="serpent", accent=CROWNGOLD, glow=(255, 60, 60))),
 ("Zweihander",  "The Iron Crown",    "Legendary", dict(blade=(140, 144, 154), grip=(30, 30, 36), trim="crown", glow=(255, 40, 60))),
]

# auras (ReplicatedStorage > SkinFX) by skin name; Legendary skins get one, Epic and
# Legendary get a swing trail automatically
FX_BY_NAME = {"Gilded": "gold", "Frostbite": "frost", "Sunsteel": "holy", "Hellforged": "embers",
              "Warden's Vow": "holy", "Dawnbringer": "embers", "Last Bastion": "storm",
              "Last Light": "holy", "Anvil of Kings": "storm", "The Iron Crown": "blood"}

# THE FORGE: every skin's mesh comes from a theme in blender/themes.py (blender/forge.py
# builds it, Studio welds it on). By name; a name not listed keeps the old tint + trim.
LOOK = {
 "Pitted": "pitted", "Notched": "notched", "Whetted": "whetted", "Oiled": "oiled", "Bronzed": "bronzed", "Grey Iron": "greyiron",
 "Tarred": "tarred", "Dented": "dented", "Ironhead": "greyiron", "Hunter": "hunter", "Ashen": "ashen", "Hayfork": "hayfork",
 "Blackened": "blackened", "Bluesteel": "bluesteel", "Verdigris": "verdigris", "Ember": "ember", "Duelist": "duelist",
 "Heraldic": "heraldic", "Wyrmscale": "wyrmscale", "Marsh Reed": "marshreed", "Riverstone": "riverstone",
 "Sellsword's Edge": "sellsword", "Crow-black": "crowblack", "Tourney Gilt": "tourneygilt", "Ironclad": "ironclad",
 "Crownspike": "crownspike", "Iron Oath": "ironoath", "Squire's Oath": "squiresoath", "Wayfarer": "wayfarer",
 "Crowfeather": "crowfeather", "Royal": "royal", "Veteran": "veteran", "Bloodrust": "bloodrust", "Thornguard": "thornguard",
 "Nightfall": "nightfall", "Executioner": "executioner", "Bloodletter": "bloodletter", "Reaper": "reaper",
 "Skullsplitter": "skullsplitter", "Bronze": "bronzeking", "Gilt Hilt": "gilthilt", "Boarspear Red": "boarspear",
 "Blackguard's Maul": "blackguard", "Ironbark": "ironbark", "Crownguard": "crownguard", "Iron Lion": "ironlion",
 "Iron Tines": "irontines", "Kingsguard": "kingsguard", "Crown's Fang": "crownsfang", "Oathbound": "oathbound",
 "Ironvow": "ironvow", "Lionheart": "lionheart",
 "Gilded": "gilded", "Frostbite": "frostbite", "Saint's Mercy": "saintsmercy", "Hundredfold": "hundredfold",
 "Sunforged": "sunforged", "Flamberge Wave": "flamberge", "Oathkeeper": "oathkeeper", "Serpent Tine": "serpenttine",
 "Peasant's Pride": "peasantspride", "Kingsbane": "kingsbane", "Thunderhead": "thunderhead", "Sunsteel": "sunsteel",
 "Hellforged": "hellforged", "Last Light": "lastlight", "Anvil of Kings": "anvilofkings", "The Iron Crown": "ironcrown",
 "Warden's Vow": "wardensvow", "Dawnbringer": "dawnbringer", "Last Bastion": "lastbastion", "Gilded Greatsword": "gilded",
}

# THE DROPS (Catalog ▸ Calendar): what each weekly drop adds. A skin with `drop` is
# hidden until that drop goes live; one in a crate leaves with the crate.
#  (weapon, name, rarity, source, look, fx)   source: crate / claim / limited / founder
def _drop(crate, drop, rows):
    out = []
    for rarity, look, name, weapons, fx in rows:
        for w in weapons:
            out.append((w, name, rarity, 'crate = "%s", drop = "%s"' % (crate, drop), look, fx))
    return out
DROP_SKINS = []
DROP_SKINS += [("Longsword", "Founder's Oath", "Mythic", 'founder = true, drop = "Founders"', "founders", "holy")]
DROP_SKINS += _drop("Ossuary", "Bonewright", [
 ("Common", "gravedigger", "Gravedigger", ["Shortsword", "Spear", "Hammer", "Pitchfork"], None),
 ("Rare", "bone", "Bone", ["Cleaver", "Dagger", "Mace", "Glaive"], None),
 ("Epic", "ossuary", "Ossuary", ["Falchion", "Halberd", "WarAxe", "Greatsword"], None),
 ("Legendary", "cryptlight", "Cryptlight", ["Longsword", "Poleaxe", "Messer"], "toxic"),
 ("Mythic", "marrowking", "The Marrow King", ["Executioner"], "toxic")])
DROP_SKINS += _drop("Hollow", "HollowNight", [
 ("Rare", "pumpkin", "Pumpkin", ["Mace", "Maul", "Quarterstaff", "ArmingSword"], None),
 ("Epic", "gravewood", "Gravewood", ["Billhook", "Glaive", "Rapier"], None),
 ("Epic", "candlewax", "Candlewax", ["Longsword", "Estoc", "Hammer"], None),
 ("Legendary", "witchlight", "Witchlight", ["Estoc", "Dagger", "Spear", "Zweihander"], "shadow"),
 ("Mythic", "hollowheadsman", "The Hollow Headsman", ["Halberd"], "embers")])
DROP_SKINS += [("Dagger", "Jack's Grin", "Epic", 'claim = "JacksGrin", drop = "AllHallows"', "jackgrin", "embers")]
DROP_SKINS += _drop("Foundry", "Ironclad", [
 ("Rare", "foundry", "Foundry", ["Hammer", "Maul", "Greatsword", "Cleaver"], None),
 ("Epic", "ironclad2", "Ironclad Plate", ["WarAxe", "MorningStar", "Zweihander"], None),
 ("Legendary", "slagheart", "Slagheart", ["Maul", "BattleAxe", "Falchion"], "embers"),
 ("Mythic", "forgefather", "The Forgefather", ["Maul"], "embers")])
DROP_SKINS += _drop("WildHunt", "WildHunt", [
 ("Rare", "huntsman", "Huntsman", ["Spear", "Shortsword", "BattleAxe", "Falchion"], None),
 ("Epic", "stagheart", "Stagheart", ["Glaive", "Longsword", "WarAxe"], None),
 ("Legendary", "thornwild", "Thornwild", ["Poleaxe", "Rapier", "Mace"], "toxic"),
 ("Mythic", "hornedking", "The Horned King", ["Bardiche"], "toxic")])
DROP_SKINS += _drop("Longship", "Northmen", [
 ("Rare", "runecarved", "Runecarved", ["WarAxe", "Spear", "ArmingSword", "Hammer"], None),
 ("Epic", "longship", "Longship", ["Messer", "BattleAxe", "Greatsword"], None),
 ("Epic", "seawolf", "Sea-Wolf", ["Glaive", "Dagger", "Mace"], None),
 ("Legendary", "skald", "Skald", ["Longsword", "Halberd", "Maul"], "gold"),
 ("Mythic", "jarlsbane", "Jarl's Bane", ["BattleAxe"], "storm")])
DROP_SKINS += _drop("Rime", "Frostfall", [
 ("Rare", "rime", "Rime", ["Estoc", "Spear", "Shortsword", "Mace"], None),
 ("Epic", "glacier", "Glacier", ["Greatsword", "Halberd", "Falchion"], None),
 ("Legendary", "frostbite", "Frostbite", ["Longsword", "Zweihander", "Dagger"], "frost"),
 ("Mythic", "rimeheart", "Rimeheart", ["Greatsword"], "frost")])
DROP_SKINS += _drop("Yule", "Yuletide", [
 ("Rare", "candycane", "Candy Cane", ["Quarterstaff", "Rapier", "Spear", "Shortsword"], None),
 ("Rare", "gingerbread", "Gingerbread", ["Mace", "Dagger", "Cleaver"], None),
 ("Epic", "evergreen", "Evergreen", ["Longsword", "Halberd", "Falchion"], None),
 ("Legendary", "starlight", "Starlight", ["Greatsword", "Estoc", "Glaive"], "gold"),
 ("Mythic", "krampus", "Krampus' Chain", ["MorningStar"], "blood")])
DROP_SKINS += [("Zweihander", "Frostgift", "Legendary", 'crowns = 400, limited = 2026, drop = "TwelfthNight"', "frostgift", "frost")]
DROP_SKINS += [("Longsword", "First Light", "Legendary", 'claim = "FirstLight", drop = "Midwinter"', "firstlight", "holy")]
DROP_SKINS += _drop("BlackSails", "BlackSails", [
 ("Rare", "cutthroat", "Cutthroat", ["Falchion", "Messer", "Dagger", "Cleaver"], None),
 ("Rare", "saltworn", "Saltworn", ["Spear", "Pitchfork", "Hammer"], None),
 ("Epic", "kraken", "Kraken", ["Rapier", "Glaive", "Mace"], None),
 ("Legendary", "blackflag", "Black Flag", ["Longsword", "Halberd", "BattleAxe"], "blood"),
 ("Mythic", "davyjones", "Davy's Locker", ["Messer"], "toxic")])


def rgb(t): return "Color3.fromRGB(%d, %d, %d)" % tuple(t)
def looks(d, name=None):
    out = 'blade = %s, grip = %s, trim = "%s"' % (rgb(d["blade"]), rgb(d["grip"]), d["trim"])
    if d.get("accent"): out += ', accent = ' + rgb(d["accent"])
    if d.get("glow"): out += ', glow = ' + rgb(d["glow"])
    fx = d.get("fx") or (name and FX_BY_NAME.get(name))
    if fx: out += ', fx = "%s"' % fx
    return out

SKINS_HEADER = """--[[ WEAPON SKINS — looks for a weapon; never stats. GENERATED by
     scripts/gen_content.py: the four original weapons are hand-written in
     scripts/skins_handmade.part, the rest come from TINTS, SHOP_STYLES and TASK_SKINS.
     Every weapon gets a free "Default" skin automatically, so only extras are listed.
       weapon   the weapon id       name    unique within the weapon
       rarity   Common | Rare | Epic | Legendary | Mythic
     WHERE A SKIN COMES FROM (never bought at will):
       crate    "Bladesmith" / "Hafted" / "Royal": rolled from that crate
       crate = "earned", kills = n        n kills with the weapon unlock it
       unlock = {stat = "contract", n = n}  n daily tasks finished unlock it
       pass = true                        a season pass reward (Catalog ▸ Pass)
       pack + marks / crowns              sold with the pack, on the days it is in the store
       marks / crowns alone               the store's WEAPONS shelf, on the days it is offered
       drop = "<id>"                      hidden until that drop of Catalog ▸ Calendar is live
       limited = n                        only n are ever made, each numbered (#1..n)
       claim = "<id>"                     a free gift while that Calendar claim is open (numbered)
       founder = true                     given to everyone who plays before Calendar.founders ends
     LOOKS:
       blade / grip   tints for parts with attribute SkinPart = "Blade" / "Grip"
       trim     the shape change (ReplicatedStorage ▸ SkinTrims): wrap rivets rings fuller
                studs notch laurel feather spikes flame frost runes royal crown halo
                bone serpent wave thunder. Bows and crossbows have their own set, fitted to
                their limbs / prod: bands fletch horn thorn crystal wing ember frost runic
                skull gilded storm venom blood void dragon halo
       accent / glow  the trim's metal and its Neon (defaults by rarity)
       fx       an aura (ReplicatedStorage ▸ SkinFX): embers frost holy shadow storm toxic
                petals gold blood.
       arrow    (bows, crossbows) what its arrows wear in flight and burst with where they
                land (ReplicatedStorage ▸ ArrowFX): fire frost shadow holy storm toxic gold blood void
                spirit. Epic and Legendary skins also leave a swing trail
                (trail = false to opt out, trail = true to opt in below Epic)
       look     the Forge theme (blender/themes.py): the skin's own mesh, built by
                blender/forge.py and welded on from Cosmetics ▸ Skins ▸ <weapon> ▸ <name>
                (without the model in Studio the tints + trim below stand in)
       model    optional Model in Cosmetics ▸ Skins ▸ <weapon> ▸ <model or name> that
                replaces the Tool's visible parts (welded by offset from its Handle) ]]
local C = Color3.fromRGB
return {"""

def gen_catalog_skins():
    import re
    lines = [SKINS_HEADER]
    lines.append('\t-- HAND-WRITTEN (scripts/skins_handmade.part): the four original weapons')
    with open(os.path.join(os.path.dirname(__file__), "skins_handmade.part"), encoding="utf-8") as f:
        hand = f.read().rstrip("\n")
    lines.extend(hand.splitlines())
    handWeapons = set(re.findall(r'weapon = "(\w+)"', hand))
    lines.append('\t-- GENERATED: crate / kill skins for every other weapon')
    for (wid, name, *_rest) in WEAPONS:
        if wid in EXISTING or wid in handWeapons: continue
        for skin, crate in skins_for(wid):
            d = TINTS[skin]
            if skin == "Veteran":
                lines.append('\t{weapon = "%s", name = "Veteran", rarity = "Epic", crate = "earned", kills = 100, %s},' % (wid, looks(d)))
                continue
            if crate and skin in CRATE_PICKS and wid not in CRATE_PICKS[skin]:
                c = SHELF_PRICE[d["rarity"]]          # (not in the crate: on the WEAPONS shelf instead)
            else:
                c = 'crate = "%s"' % crate if crate else 'marks = 600'
            lines.append('\t{weapon = "%s", name = "%s", rarity = "%s", %s, %s},' % (wid, skin, d["rarity"], c, looks(d, skin)))
    lines.append('\t-- GENERATED: the WEAPONS shelf of the daily store (two per weapon)')
    for i, (wid, name, *_rest) in enumerate(WEAPONS):
        for style in SHOP_PAIRS[i % len(SHOP_PAIRS)]:
            d = SHOP_STYLES[style]
            price = ", ".join(x for x in (("marks = %d" % d["marks"]) if d.get("marks") else "", ("crowns = %d" % d["crowns"]) if d.get("crowns") else "") if x)
            lines.append('\t{weapon = "%s", name = "%s", rarity = "%s", %s, %s},' % (wid, style, d["rarity"], price, looks(d, style)))
    lines.append('\t-- GENERATED: season pass skins (Catalog > Pass gives them out)')
    for (wid, sname, rar, d) in PASS_SKINS:
        lines.append('\t{weapon = "%s", name = "%s", rarity = "%s", pass = true, %s},' % (wid, sname, rar, looks(d, sname)))
    lines.append('\t-- GENERATED: task skins (finish daily tasks to earn them)')
    for (wid, sname, rar, n, d) in TASK_SKINS:
        lines.append('\t{weapon = "%s", name = "%s", rarity = "%s", unlock = {stat = "contract", n = %d}, %s},' % (wid, sname, rar, n, looks(d, sname)))
    lines.append('\t-- GENERATED: the weekly drops (Catalog > Calendar); hidden until their drop goes live')
    for (wid, sname, rar, src, look, fx) in DROP_SKINS:
        lines.append('\t{weapon = "%s", name = "%s", rarity = "%s", %s, look = "%s"%s},' % (wid, sname, rar, src, look, (', fx = "%s"' % fx) if fx else ""))
    lines.append('}')
    # every skin wears its Forge look (by name), unless it already names one
    for i, ln in enumerate(lines):
        m = re.search(r'name = "([^"]+)"', ln)
        if m and 'look = "' not in ln and m.group(1) in LOOK:
            lines[i] = ln.rstrip().rstrip("},").rstrip() + ', look = "%s"},' % LOOK[m.group(1)]
    write(os.path.join(ROOT, "ReplicatedStorage", "Catalog", "Skins.lua"), "\n".join(lines) + "\n")

# (unused) armor sets used to be generated here; the 12 release sets are hand-written in
# roblox/ServerStorage/Armor/<Set>/Config.lua and their bodies come from Build/Armor.lua
SETS = {
 "MarshWarden": ("Light",  "Marsh Warden",  "MarshWardens", "Rare",   600,  30, ["Hair"],          "Hooded and cloaked in fen green. Light leather, quiet boots."),
 "Brigand":     ("Light",  "Brigand",       "Outlaws",      "Rare",   600,  30, [],                "Studded leather and a red bandana. Dressed to rob, not to parade."),
 "Woodsman":    ("Light",  "Woodsman",      "Starter_Light","Common", 0,    0,  [],                "A feathered cap and a belted tunic. The forest's own."),
 "GildedCourt": ("Medium", "Gilded Court",  "GildedCourt",  "Epic",   900,  45, ["Hair"],          "A quilted gambeson stitched with gold under a gold-rimmed kettle hat."),
 "Sergeant":    ("Medium", "Sergeant",      "Garrison",     "Common", 400,  20, ["Hair"],          "Mail coif and riveted brigandine. Twenty years of garrison duty."),
 "Freelancer":  ("Medium", "Freelancer",    "Garrison",     "Rare",   700,  35, ["Hair"],          "An open sallet over mail and a plain surcoat. Fights for whoever pays."),
 "IronCrow":    ("Heavy",  "Iron Crow",     "IronCrow",     "Epic",   1200, 60, ["Hair", "Face"],  "Black iron plate and a beaked bascinet. The Crow company's harness."),
 "Templar":     ("Heavy",  "Templar",       "HolyOrder",    "Rare",   900,  45, ["Hair", "Face"],  "A great helm and a white tabard with the red cross over full plate."),
 "RoyalGuard":  ("Heavy",  "Royal Guard",   "RoyalGuard",   "Legendary", 1800, 90, ["Hair"],       "Bright plate with gold trim and a plumed armet. Nobody outranks you on the field."),
}
SET_CONFIG = '''-- ServerStorage/Armor/{id}/Config — the clothing models are built from
-- Build ▸ Armor.{id} when this folder has none (replace them by hand any time).
return {{
	Name        = "{name}",
	Description = "{desc}",
	Type        = "{type}",       -- Light | Medium | Heavy (the only stats source: Catalog ▸ Weights)
	Pack        = "{pack}",
	Rarity      = "{rarity}",
	PriceMarks  = {marks},
	PriceCrowns = {crowns},
	Covers      = {{{covers}}},
}}
'''
def gen_sets():
    for sid, (typ, name, pack, rar, marks, crowns, covers, desc) in SETS.items():
        d = os.path.join(ROOT, "ServerStorage", "Armor", sid)
        write(os.path.join(d, "Config.lua"), SET_CONFIG.format(id=sid, name=name, desc=desc, type=typ, pack=pack, rarity=rar, marks=marks, crowns=crowns,
              covers=", ".join(f'"{c}"' for c in covers)))
        write(os.path.join(d, "init.meta.json"), json.dumps({"ignoreUnknownInstances": True}, indent=2) + "\n")

if __name__ == "__main__":
    import sys
    if "--skins" in sys.argv:
        gen_catalog_skins(); print("generated Catalog/Skins.lua")
    else:
        gen_tools(); gen_catalog_weapons(); gen_catalog_skins()
        print("generated", len([w for w in WEAPONS if w[0] not in EXISTING]), "tools")
