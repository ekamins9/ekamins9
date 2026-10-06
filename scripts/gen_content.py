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
 ("Shortsword",  "Shortsword",        "OneHanded", False, True,  0.45, 4.0, 20, 20, 1.0, 1.0, 1.1, None, {"free": True}, 0),
 ("Pitchfork",   "Pitchfork",         "Polearm",   True,  False, 0.5,  9.0, 15, 22, 1.0, 1.0, 1.15, None, {"free": True}, 0),
 ("Greatsword",  "Greatsword",        "TwoHanded", True,  False, 0.4,  9.0, 30, 30, 1.1, 1.1, 1.0, None, {"free": True}, 0),
 ("Hammer",      "War Hammer",        "OneHanded", False, True,  0.45, 4.0, 20, 20, 1.0, 1.0, 1.0, None, {"free": True}, 0),
 ("ArmingSword", "Arming Sword",      "OneHanded", False, True,  0.5,  5.0, 22, 20, 1.0, 1.0, 1.05, "The knight's sidearm: a straight cut-and-thrust blade that is quick in the hand and honest about its reach.", {"free": True}, 0),
 ("Dagger",      "Rondel Dagger",     "OneHanded", False, True,  0.75, 3.2, 14, 18, 1.0, 0.9, 1.15, "A hand's breadth of steel. Useless at range, deadly inside it: the stab goes through mail.", {"level": 2}, 500),
 ("Longsword",   "Longsword",         "TwoHanded", True,  False, 0.5,  6.5, 26, 24, 1.05, 1.05, 1.0, "Hand-and-a-half and fast for a two-hander. The fencer's weapon: feints, chambers, ripostes.", {"level": 3}, 900),
 ("Mace",        "Flanged Mace",      "OneHanded", False, True,  0.46, 4.6, 26, 14, 1.0, 1.05, 0.9, "Flanges that bite through plate. Slow to thrust, but a hit is a hit no matter what they're wearing.", {"level": 4}, 900),
 ("Cleaver",     "Cleaver",           "OneHanded", False, True,  0.52, 4.0, 24, 8,  1.0, 1.0, 0.8, "Taken from a butcher's block. Heavy chop, no point to speak of.", {"level": 4}, 600),
 ("Falchion",    "Falchion",          "OneHanded", False, True,  0.48, 4.8, 26, 12, 1.0, 1.0, 0.9, "A broad, forward-weighted blade. Cuts like an axe, swings like a sword.", {"level": 6}, 1000),
 ("BattleAxe",   "Battle Axe",        "TwoHanded", True,  False, 0.4,  7.0, 32, 14, 1.05, 1.15, 0.8, "A great bearded axe. The swing takes a moment; whatever it meets takes longer.", {"level": 7}, 1300),
 ("MorningStar", "Morning Star",      "OneHanded", False, False, 0.44, 5.0, 28, 16, 1.0, 1.1, 0.9, "A spiked ball on a haft. Blunt and sharp at once; nobody blocks it comfortably.", {"level": 8}, 1200),
 ("Halberd",     "Halberd",           "Polearm",   True,  False, 0.38, 10.0, 32, 26, 1.1, 1.15, 1.0, "Axe, spike and hook on a long pole. The infantry's answer to everything, if you can keep them at the end of it.", {"level": 8}, 1600),
 ("Messer",      "Kriegsmesser",      "OneHanded", False, False, 0.46, 5.8, 27, 18, 1.0, 1.05, 0.95, "A long single-edged knife with a nagel to guard the hand. Reach of a longsword, speed of a sword.", {"level": 9}, 1300),
 ("Maul",        "Maul",              "TwoHanded", True,  False, 0.3,  7.5, 40, 14, 0.9, 1.3, 0.7, "A sledge for men. One clean hit ends an argument; one miss ends you.", {"level": 10}, 1800),
 ("Billhook",    "Billhook",          "Polearm",   True,  False, 0.42, 9.5, 26, 22, 1.05, 1.1, 1.0, "The farmer's hedge tool, lengthened and sharpened. Its hook pulls riders and shields alike.", {"level": 10}, 1200),
 ("Estoc",       "Estoc",             "TwoHanded", True,  False, 0.46, 7.0, 14, 32, 1.0, 1.0, 1.1, "A blade with no edge, only a point, meant to find the gaps in plate. Thrust, don't swing.", {"level": 11}, 1500),
 ("Rapier",      "Rapier",            "OneHanded", False, True,  0.6,  6.0, 12, 24, 1.0, 0.95, 1.2, "Long, light and precise. The thrust arrives before the wind-up is noticed.", {"level": 12}, 1500),
 ("Glaive",      "Glaive",            "Polearm",   True,  False, 0.4,  10.0, 30, 20, 1.05, 1.1, 0.95, "A sword blade on a pole. Sweeps that reach the second rank.", {"level": 13}, 1600),
 ("Poleaxe",     "Poleaxe",           "Polearm",   True,  False, 0.4,  9.5, 30, 24, 1.1, 1.15, 1.0, "Hammer head, fluke and top spike: the knight's own polearm for fighting other knights.", {"level": 14}, 1800),
 ("Bardiche",    "Bardiche",          "TwoHanded", True,  False, 0.36, 8.5, 34, 18, 1.1, 1.2, 0.85, "A long crescent blade bound to a long haft. Few things cut deeper.", {"level": 15}, 1800),
 ("Zweihander",  "Zweihander",        "TwoHanded", True,  False, 0.36, 9.5, 34, 28, 1.15, 1.15, 1.0, "The great two-hander of the Landsknechte, with rings and a leather ricasso. Every swing is a wall of steel.", {"level": 16}, 2200),
 ("Executioner", "Executioner's Sword","TwoHanded", True, False, 0.38, 8.0, 36, 10, 1.1, 1.15, 0.6, "Broad, flat-tipped, built for one job. No point, all edge.", {"level": 18}, 2400),
 ("WarAxe",      "War Axe",           "OneHanded", False, True,  0.48, 4.8, 26, 10, 1.0, 1.05, 0.8, "A one-handed axe, light enough to carry as a sidearm and heavy enough to open a helm.", {"free": True}, 0),
 ("Spear",       "Spear",             "Polearm",   True,  False, 0.5,  10.5, 12, 26, 1.0, 1.0, 1.15, "The oldest weapon there is. Keep the point between you and them.", {"free": True}, 0),
 ("Quarterstaff","Quarterstaff",      "Polearm",   True,  False, 0.62, 8.0, 14, 14, 1.0, 0.9, 1.0, "Iron-shod oak. It kills nobody quickly, and nobody gets near you either.", {"free": True}, 0),
]
EXISTING = {"Shortsword", "Pitchfork", "Greatsword", "Hammer"}   # hand-made Tools: don't regenerate their folders

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
                            speed=speed, stabSpeed=ss, reach=reach, two=lua_bool(two), sec=lua_bool(sec), speedMult=sm, clunkMult=cm,
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
             '       family    "OneHanded" | "TwoHanded" | "Polearm"   (kill counts and crates group by it)',
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
    lines.append('}')
    write(os.path.join(ROOT, "ReplicatedStorage", "Catalog", "Weapons.lua"), "\n".join(lines) + "\n")

# skin palettes: name -> (rarity, blade rgb, grip rgb)
TINTS = {
 "Blackened":  ("Rare",      (58, 61, 68),    (42, 42, 42)),
 "Bluesteel":  ("Rare",      (138, 168, 216), (42, 42, 74)),
 "Pitted":     ("Common",    (154, 154, 138), (74, 58, 42)),
 "Oiled":      ("Common",    (120, 126, 136), (58, 42, 26)),
 "Bronzed":    ("Common",    (176, 120, 72),  (74, 42, 26)),
 "Crowfeather":("Epic",      (42, 42, 48),    (201, 154, 72)),
 "Bloodrust":  ("Epic",      (120, 48, 40),   (40, 30, 26)),
 "Gilded":     ("Legendary", (242, 226, 176), (201, 154, 72)),
 "Frostbite":  ("Legendary", (200, 236, 255), (60, 90, 140)),
 "Ember":      ("Rare",      (216, 106, 58),  (58, 42, 26)),
 "Verdigris":  ("Rare",      (96, 160, 140),  (74, 58, 42)),
 "Royal":      ("Epic",      (226, 232, 240), (70, 90, 200)),
}
SWORDS = {"Shortsword", "Greatsword", "ArmingSword", "Dagger", "Longsword", "Falchion", "Messer", "Estoc", "Rapier", "Zweihander", "Executioner", "Cleaver"}
# per weapon: list of (skin, crate) ; crate None = shop skin (marks), "earned" = kill skin
def skins_for(wid):
    if wid in SWORDS:
        base = [("Pitted", "Bladesmith"), ("Blackened", "Bladesmith"), ("Bluesteel", "Bladesmith"), ("Crowfeather", "Bladesmith"), ("Gilded", "Royal"), ("Veteran", "earned")]
    else:
        base = [("Oiled", "Hafted"), ("Bronzed", "Hafted"), ("Ember", "Hafted"), ("Bloodrust", "Hafted"), ("Frostbite", "Royal"), ("Veteran", "earned")]
    if wid in ("Longsword", "Zweihander", "Halberd", "Poleaxe", "Rapier", "ArmingSword"): base.insert(4, ("Royal", "Royal"))
    if wid in ("Spear", "Quarterstaff", "Pitchfork", "Shortsword", "WarAxe", "ArmingSword"): base.append(("Verdigris", None))
    return base

def gen_catalog_skins():
    lines = ['--[[ WEAPON SKINS — looks for a weapon; never stats. GENERATED by',
             '     scripts/gen_content.py: the four original weapons are hand-written in',
             '     scripts/skins_handmade.part, the rest come from TINTS + skins_for. Every weapon gets a free',
             '     "Default" skin automatically, so only extras are listed.',
             '       weapon   the weapon id       name    unique within the weapon',
             '       rarity   Common | Rare | Epic | Legendary',
             '       crate    which crate rolls it ("Bladesmith" / "Hafted" / "Royal"), "earned"',
             '                for kill-count skins, or nil = sold in the shop for `marks` / `crowns`',
             '       kills    for crate = "earned": kills with that weapon that unlock it',
             '       blade / grip   Color3 tints for parts with attribute SkinPart = "Blade" / "Grip"',
             '       model    optional Model in Cosmetics ▸ Skins ▸ <weapon> ▸ <model or name> that',
             '                replaces the Tool\'s visible parts (welded by offset from its Handle) ]]',
             'local C = Color3.fromRGB', 'return {']
    lines.append('\t-- HAND-WRITTEN (scripts/skins_handmade.part): the four original weapons')
    with open(os.path.join(os.path.dirname(__file__), "skins_handmade.part"), encoding="utf-8") as f: lines.append(f.read().rstrip("\n"))
    lines.append('\t-- GENERATED for every other weapon')
    for (wid, name, *_rest) in WEAPONS:
        if wid in EXISTING: continue
        for skin, crate in skins_for(wid):
            if skin == "Veteran":
                lines.append(f'\t{{weapon = "{wid}", name = "Veteran", rarity = "Epic", crate = "earned", kills = 100, blade = Color3.fromRGB(184, 192, 200), grip = Color3.fromRGB(106, 42, 42)}},')
                continue
            rar, b, g = TINTS[skin]
            c = f'crate = "{crate}"' if crate else 'marks = 600'
            lines.append(f'\t{{weapon = "{wid}", name = "{skin}", rarity = "{rar}", {c}, blade = Color3.fromRGB{b}, grip = Color3.fromRGB{g}}},')
    lines.append('}')
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
    gen_tools(); gen_catalog_weapons(); gen_catalog_skins()
    print("generated", len([w for w in WEAPONS if w[0] not in EXISTING]), "tools")
