"""THEMES for the Forge (blender/forge.py): every weapon skin's look, by id.
Catalog ▸ Skins names one with `look = "<id>"`. Colours are 0..255.

  palette   role -> colour: steel bright edge fuller face darksteel iron blackiron
            leather darkleather wood darkwood brass gold red rope wire;
            pattern_b = the pattern's second colour
  pattern   damascus rust blued frost scales stripes stars filigree embers bark
            knotwork waves camo sheen
  edge      serrate jag nicks wave barb        guard / pommel / wrap / ornaments: see forge.py
  glow      {"color": (r, g, b), "kinds": [runes cracks veins core stars halo crystals]}
  detail    blade rings per ring of the plain weapon (pattern resolution; default 4)
"""


def C(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


def T(id_, **kw):
    pal = {k: C(*v) for k, v in kw.pop("palette", {}).items()}
    th = {"id": id_, "palette": pal}
    for k, v in kw.items():
        if k in ("guard_color", "horn_color", "bone_color", "fur_color", "serpent_color", "chain_color",
                 "feather_color", "tassel_color", "ribbon_color", "stone_color") and isinstance(v, tuple):
            v = C(*v)
        if k == "glow":
            v = {"color": C(*v[0]), "kinds": list(v[1])}
        th[k] = v
    return th


BONE = (222, 210, 182)
L = []

# ---------------------------------------------------------------- COMMON: finishes
L += [
    T("pitted", palette=dict(steel=(150, 150, 140), bright=(176, 174, 164), face=(150, 150, 140), fuller=(110, 108, 100), edge=(206, 204, 196),
                             leather=(96, 74, 52), pattern_b=(112, 78, 54)), pattern="rust"),
    T("notched", palette=dict(steel=(160, 160, 152), face=(160, 160, 152), edge=(214, 212, 204), pattern_b=(118, 108, 98)), pattern="rust", edge="nicks"),
    T("whetted", palette=dict(steel=(214, 218, 224), bright=(240, 242, 246), face=(214, 218, 224), edge=(255, 255, 255), leather=(150, 110, 70),
                              darkleather=(110, 78, 50), pattern_b=(250, 251, 253)), pattern="sheen"),
    T("oiled", palette=dict(steel=(110, 116, 126), face=(110, 116, 126), fuller=(70, 74, 82), edge=(196, 200, 208), wood=(70, 48, 30),
                            pattern_b=(168, 176, 188)), pattern="sheen"),
    T("bronzed", palette=dict(steel=(176, 120, 72), face=(176, 120, 72), bright=(214, 160, 100), fuller=(130, 86, 50), edge=(236, 196, 140),
                              iron=(150, 100, 60), darksteel=(130, 86, 50), pattern_b=(222, 172, 112)), pattern="sheen"),
    T("greyiron", palette=dict(steel=(128, 132, 136), face=(128, 132, 136), fuller=(96, 98, 104), edge=(186, 188, 192), pattern_b=(94, 94, 98)), pattern="rust"),
    T("tarred", palette=dict(steel=(52, 50, 48), face=(52, 50, 48), fuller=(34, 32, 30), edge=(150, 150, 140), wood=(40, 30, 24), iron=(46, 44, 42),
                             pattern_b=(96, 72, 50)), pattern="rust"),
    T("dented", palette=dict(steel=(118, 114, 108), face=(118, 114, 108), edge=(170, 168, 160), pattern_b=(84, 80, 76)), pattern="rust", edge="nicks"),
    T("hunter", palette=dict(steel=(110, 116, 104), face=(110, 116, 104), fuller=(80, 86, 74), edge=(180, 184, 170), leather=(60, 80, 48),
                             darkleather=(44, 58, 34), pattern_b=(66, 92, 50)), pattern="camo"),
    T("ashen", palette=dict(steel=(156, 154, 152), face=(156, 154, 152), fuller=(110, 108, 106), edge=(214, 212, 210), leather=(70, 70, 72),
                            darkleather=(46, 46, 48), pattern_b=(58, 58, 60)), pattern="stars"),
    T("hayfork", palette=dict(steel=(140, 130, 110), face=(140, 130, 110), edge=(180, 170, 150), wood=(156, 124, 82), pattern_b=(108, 80, 54)), pattern="rust"),
]

# ---------------------------------------------------------------- RARE: finishes with a little shape
L += [
    T("blackened", palette=dict(steel=(52, 54, 60), face=(52, 54, 60), bright=(90, 94, 104), fuller=(30, 30, 34), edge=(222, 226, 234),
                                leather=(32, 32, 34), darkleather=(20, 20, 22), brass=(66, 66, 72), pattern_b=(92, 96, 108)), pattern="sheen",
      pommel="spike", guard_color="darksteel"),
    T("bluesteel", palette=dict(steel=(110, 140, 200), face=(110, 140, 200), fuller=(70, 90, 150), edge=(226, 234, 255), leather=(42, 42, 74),
                                darkleather=(28, 28, 52), brass=(170, 180, 210), steel_=(0, 0, 0), pattern_b=(56, 74, 168)), pattern="blued"),
    T("verdigris", palette=dict(steel=(96, 160, 140), face=(96, 160, 140), fuller=(70, 120, 104), edge=(200, 226, 214), brass=(90, 170, 120),
                                pattern_b=(150, 120, 80)), pattern="rust", wrap="rope"),
    T("ember", palette=dict(steel=(70, 54, 46), face=(70, 54, 46), fuller=(40, 30, 26), edge=(255, 196, 120), pattern_b=(255, 120, 40)), pattern="embers"),
    T("duelist", palette=dict(steel=(226, 228, 232), face=(226, 228, 232), edge=(255, 255, 255), brass=(232, 184, 74), pattern_b=(255, 255, 255)),
      pattern="sheen", wrap="red", pommel="ring", guard_color="gold"),
    T("heraldic", palette=dict(steel=(200, 206, 220), face=(200, 206, 220), fuller=(60, 100, 200), leather=(74, 98, 168), darkleather=(50, 66, 120),
                               brass=(232, 184, 74), pattern_b=(64, 104, 204)), pattern="stripes", twist=0.0, freq=7, tassel_color=(60, 100, 200),
      ornaments=["tassel"]),
    T("damascus", palette=dict(steel=(120, 124, 132), face=(120, 124, 132), edge=(230, 232, 236), pattern_b=(214, 218, 224)), pattern="damascus"),
    T("wyrmscale", palette=dict(steel=(70, 110, 80), face=(70, 110, 80), fuller=(50, 80, 56), edge=(232, 210, 120), leather=(40, 60, 40),
                                pattern_b=(150, 190, 120)), pattern="scales", guard="horns", horn_color=(60, 90, 60)),
    T("marshreed", palette=dict(steel=(120, 140, 100), face=(120, 140, 100), edge=(190, 200, 170), leather=(70, 90, 50), pattern_b=(84, 106, 66)),
      pattern="waves", wrap="rope"),
    T("riverstone", palette=dict(steel=(110, 130, 140), face=(110, 130, 140), edge=(210, 226, 232), leather=(58, 92, 110), pattern_b=(168, 198, 210)),
      pattern="waves"),
    T("sellsword", palette=dict(steel=(176, 170, 150), face=(176, 170, 150), edge=(220, 216, 200), leather=(110, 84, 58), pattern_b=(140, 120, 90)),
      pattern="rust", pommel="ring"),
    T("crowblack", palette=dict(steel=(40, 40, 44), face=(40, 40, 44), fuller=(24, 24, 28), edge=(180, 180, 190), leather=(106, 77, 42),
                                pattern_b=(76, 76, 90)), pattern="sheen", guard="wings", guard_color="darksteel"),
    T("tourneygilt", palette=dict(steel=(200, 170, 100), face=(200, 170, 100), edge=(255, 236, 170), leather=(128, 58, 58), pattern_b=(255, 230, 150)),
      pattern="filigree", ornaments=["ribbon"]),
    T("ironclad", palette=dict(steel=(150, 154, 164), face=(150, 154, 164), edge=(210, 214, 222), leather=(46, 46, 54), pattern_b=(110, 112, 120)),
      pattern="rust", guard="spikes"),
    T("crownspike", palette=dict(steel=(150, 154, 164), face=(150, 154, 164), leather=(90, 30, 30), pattern_b=(232, 190, 90)), pattern="filigree",
      guard="crown"),
    T("ironoath", palette=dict(steel=(176, 180, 188), face=(176, 180, 188), leather=(60, 40, 30), pattern_b=(220, 224, 230)), pattern="sheen", pommel="ring"),
    T("squiresoath", palette=dict(steel=(236, 238, 244), face=(236, 238, 244), leather=(60, 80, 150), pattern_b=(255, 255, 255)), pattern="sheen",
      guard="laurel"),
    T("wayfarer", palette=dict(steel=(220, 224, 232), face=(220, 224, 232), leather=(60, 90, 110), pattern_b=(250, 250, 252)), pattern="sheen",
      wrap="rope", ornaments=["tassel"], tassel_color=(60, 90, 110)),
    T("bone", palette=dict(steel=BONE, face=BONE, bright=(240, 232, 210), fuller=(170, 156, 130), edge=(246, 240, 226), leather=(80, 60, 44),
                           pattern_b=(160, 140, 110)), pattern="rust", pommel="skull", bone_color=BONE),
    T("gravedigger", palette=dict(steel=(84, 84, 80), face=(84, 84, 80), edge=(160, 160, 150), wood=(70, 54, 40), pattern_b=(110, 84, 60)),
      pattern="rust", edge="nicks", pommel="ring"),
    T("pumpkin", palette=dict(steel=(232, 118, 30), face=(232, 118, 30), fuller=(40, 30, 24), edge=(255, 200, 120), leather=(30, 26, 22),
                              pattern_b=(36, 28, 22)), pattern="stripes", twist=0.0, freq=9, pommel="pumpkin"),
    T("foundry", palette=dict(steel=(60, 60, 64), face=(60, 60, 64), edge=(255, 170, 90), fuller=(36, 36, 40), pattern_b=(150, 90, 50)),
      pattern="embers", guard="spikes"),
    T("huntsman", palette=dict(steel=(120, 126, 110), face=(120, 126, 110), leather=(96, 70, 44), pattern_b=(80, 100, 60)), pattern="camo",
      guard="antlers", horn_color=(150, 116, 80), wrap="fur"),
    T("runecarved", palette=dict(steel=(150, 160, 170), face=(150, 160, 170), edge=(220, 228, 236), leather=(70, 54, 40), pattern_b=(90, 100, 112)),
      pattern="knotwork", wrap="rope"),
    T("rime", palette=dict(steel=(200, 224, 240), face=(200, 224, 240), edge=(255, 255, 255), leather=(60, 90, 140), pattern_b=(140, 180, 230)),
      pattern="frost"),
    T("candycane", palette=dict(steel=(240, 236, 230), face=(240, 236, 230), fuller=(200, 30, 40), edge=(255, 255, 255), pattern_b=(206, 34, 44)),
      pattern="stripes", twist=1.4, freq=11, wrap="candy"),
    T("gingerbread", palette=dict(steel=(166, 104, 56), face=(166, 104, 56), fuller=(120, 70, 36), edge=(250, 246, 240), pattern_b=(250, 246, 240)),
      pattern="stripes", twist=0.0, freq=14, wrap="candy", pommel="star"),
    T("cutthroat", palette=dict(steel=(170, 160, 130), face=(170, 160, 130), brass=(200, 160, 80), leather=(80, 50, 34), pattern_b=(120, 104, 80)),
      pattern="rust", wrap="rope", pommel="skull"),
    T("saltworn", palette=dict(steel=(110, 150, 140), face=(110, 150, 140), brass=(80, 150, 120), edge=(200, 220, 210), pattern_b=(200, 200, 186)),
      pattern="rust", wrap="rope", guard="anchor", guard_color="brass"),
]

# ---------------------------------------------------------------- EPIC: forms
L += [
    T("crowfeather", palette=dict(steel=(42, 42, 48), face=(42, 42, 48), fuller=(24, 24, 28), edge=(170, 170, 180), pattern_b=(84, 84, 100)),
      pattern="sheen", guard="wings", guard_color="blackiron", pommel="claw", wrap="gilt", ornaments=["feathers"], feather_color=(26, 26, 32)),
    T("royal", palette=dict(steel=(226, 232, 240), face=(226, 232, 240), edge=(255, 255, 255), leather=(70, 90, 200), pattern_b=(232, 190, 90)),
      pattern="filigree", guard="crown", guard_color="gold", pommel="jewel", glow=((80, 140, 255), ["runes"])),
    T("veteran", palette=dict(steel=(184, 192, 200), face=(184, 192, 200), edge=(230, 234, 240), pattern_b=(140, 130, 120)), pattern="rust",
      edge="nicks", guard="laurel", guard_color="gold", wrap="red", ornaments=["ribbon"]),
    T("bloodrust", palette=dict(steel=(120, 48, 40), face=(120, 48, 40), fuller=(70, 30, 26), edge=(200, 120, 100), pattern_b=(64, 26, 22)),
      pattern="rust", edge="serrate", guard="spikes", pommel="spike"),
    T("thornguard", palette=dict(steel=(46, 40, 36), face=(46, 40, 36), edge=(190, 150, 110), leather=(120, 80, 40), pattern_b=(92, 66, 44)),
      pattern="bark", edge="barb", guard="thorns", ornaments=["thornwrap"]),
    T("nightfall", palette=dict(steel=(30, 30, 44), face=(30, 30, 44), fuller=(18, 18, 28), edge=(200, 200, 240), leather=(60, 40, 90),
                                pattern_b=(230, 230, 255)), pattern="stars", guard="crescent", guard_color="bright", pommel="ring",
      glow=((150, 120, 255), ["stars"])),
    T("executioner", palette=dict(steel=(60, 56, 60), face=(60, 56, 60), edge=(200, 196, 196), pattern_b=(100, 96, 100)), pattern="sheen",
      wrap="red", guard="spikes", pommel="skull", ornaments=["chains"]),
    T("bloodletter", palette=dict(steel=(150, 44, 44), face=(150, 44, 44), fuller=(90, 20, 20), edge=(240, 160, 150), leather=(40, 24, 24),
                                  pattern_b=(90, 18, 18)), pattern="damascus", edge="serrate", guard="spikes", glow=((255, 40, 40), ["cracks"])),
    T("reaper", palette=dict(steel=(40, 40, 42), face=(40, 40, 42), edge=(200, 200, 200), pattern_b=(70, 70, 76)), pattern="sheen", guard="bones",
      wrap="bone", pommel="skull"),
    T("skullsplitter", palette=dict(steel=(150, 44, 44), face=(150, 44, 44), edge=(220, 200, 190), pattern_b=(40, 40, 40)), pattern="rust",
      guard="horns", pommel="skull"),
    T("bronzeking", palette=dict(steel=(200, 138, 74), face=(200, 138, 74), edge=(240, 200, 150), iron=(170, 110, 60), pattern_b=(240, 190, 120)),
      pattern="sheen", guard="sunburst", guard_color="brass"),
    T("gilthilt", palette=dict(steel=(224, 220, 208), face=(224, 220, 208), edge=(255, 255, 255), pattern_b=(250, 248, 240)), pattern="sheen",
      guard="laurel", guard_color="gold", pommel="jewel", wrap="gilt"),
    T("boarspear", palette=dict(steel=(170, 40, 40), face=(170, 40, 40), edge=(240, 180, 170), pattern_b=(100, 24, 24)), pattern="damascus",
      edge="barb", ornaments=["tassel"], tassel_color=(170, 40, 40)),
    T("blackguard", palette=dict(steel=(24, 24, 26), face=(24, 24, 26), edge=(160, 150, 150), pattern_b=(80, 20, 20)), pattern="rust", wrap="bone",
      pommel="skull", guard="spikes", guard_color="blackiron"),
    T("ironbark", palette=dict(steel=(110, 80, 50), face=(110, 80, 50), edge=(200, 200, 190), pattern_b=(68, 48, 30)), pattern="bark", wrap="rope",
      guard="thorns"),
    T("crownguard", palette=dict(steel=(200, 204, 212), face=(200, 204, 212), leather=(110, 24, 30), pattern_b=(232, 190, 90)), pattern="filigree",
      guard="crown", guard_color="gold"),
    T("ironlion", palette=dict(steel=(110, 112, 120), face=(110, 112, 120), edge=(200, 200, 210), pattern_b=(160, 162, 170)), pattern="sheen",
      guard="laurel", guard_color="gold", pommel="claw"),
    T("irontines", palette=dict(steel=(96, 100, 108), face=(96, 100, 108), pattern_b=(60, 62, 70)), pattern="rust", edge="serrate", guard="spikes"),
    T("kingsguard", palette=dict(steel=(196, 200, 210), face=(196, 200, 210), leather=(120, 20, 30), pattern_b=(232, 190, 90)), pattern="filigree",
      guard="crown", guard_color="gold", ornaments=["tassel"], tassel_color=(140, 20, 30)),
    T("crownsfang", palette=dict(steel=(180, 184, 192), face=(180, 184, 192), leather=(30, 30, 36), pattern_b=(120, 124, 132)), pattern="damascus",
      ornaments=["serpent"], serpent_color=(150, 154, 164), glow=((255, 50, 50), [])),
    T("oathbound", palette=dict(steel=(240, 242, 248), face=(240, 242, 248), edge=(255, 255, 255), pattern_b=(200, 214, 240)), pattern="sheen",
      guard="wings", guard_color="bright", glow=((140, 200, 255), ["runes"])),
    T("ironvow", palette=dict(steel=(210, 214, 222), face=(210, 214, 222), pattern_b=(150, 154, 164)), pattern="damascus", guard="knot", wrap="rope"),
    T("lionheart", palette=dict(steel=(246, 230, 180), face=(246, 230, 180), edge=(255, 250, 230), pattern_b=(255, 214, 120)), pattern="sheen",
      guard="sunburst", guard_color="gold", wrap="red"),
    # the drops
    T("ossuary", palette=dict(steel=BONE, face=BONE, fuller=(160, 140, 110), edge=(246, 240, 226), pattern_b=(150, 128, 100)), pattern="rust",
      edge="serrate", guard="ribs", wrap="bone", pommel="skull"),
    T("gravewood", palette=dict(steel=(60, 52, 46), face=(60, 52, 46), edge=(150, 140, 120), pattern_b=(34, 30, 28)), pattern="bark", edge="jag",
      guard="thorns", ornaments=["web"]),
    T("candlewax", palette=dict(steel=(236, 228, 206), face=(236, 228, 206), fuller=(200, 190, 160), edge=(255, 250, 240), leather=(60, 30, 50),
                                pattern_b=(210, 196, 160)), pattern="rust", ornaments=["candles"], glow=((255, 180, 80), [])),
    T("ironclad2", palette=dict(steel=(70, 72, 78), face=(70, 72, 78), edge=(200, 204, 210), pattern_b=(110, 112, 120)), pattern="rust",
      guard="spikes", pommel="spike", ornaments=["chains"]),
    T("stagheart", palette=dict(steel=(150, 140, 120), face=(150, 140, 120), edge=(220, 214, 200), pattern_b=(100, 120, 80)), pattern="camo",
      guard="antlers", wrap="fur", pommel="acorn"),
    T("longship", palette=dict(steel=(150, 160, 170), face=(150, 160, 170), edge=(230, 236, 240), pattern_b=(200, 160, 80)), pattern="knotwork",
      guard="knot", guard_color="brass", pommel="dragon", wrap="fur"),
    T("seawolf", palette=dict(steel=(90, 140, 150), face=(90, 140, 150), edge=(220, 240, 244), leather=(40, 60, 70), pattern_b=(170, 210, 216)),
      pattern="waves", guard="horns", horn_color=(230, 230, 220), wrap="fur", fur_color=(160, 160, 160)),
    T("glacier", palette=dict(steel=(190, 226, 250), face=(190, 226, 250), edge=(255, 255, 255), pattern_b=(110, 160, 220)), pattern="frost",
      edge="jag", guard="crescent", guard_color="bright", glow=((180, 230, 255), ["crystals"])),
    T("evergreen", palette=dict(steel=(60, 120, 70), face=(60, 120, 70), edge=(230, 240, 220), leather=(150, 24, 30), pattern_b=(40, 80, 46)),
      pattern="damascus", guard="holly", guard_color="gold", wrap="red", glow=((255, 60, 60), [])),
    T("kraken", palette=dict(steel=(70, 60, 110), face=(70, 60, 110), edge=(200, 200, 230), pattern_b=(120, 160, 160)), pattern="scales",
      ornaments=["serpent"], serpent_color=(110, 60, 120), glow=((120, 255, 220), [])),
    T("jackgrin", palette=dict(steel=(40, 34, 30), face=(40, 34, 30), edge=(255, 170, 60), pattern_b=(232, 118, 30)), pattern="embers",
      pommel="pumpkin", edge="jag", glow=((255, 150, 40), [])),
]

# ---------------------------------------------------------------- LEGENDARY: forms + glow
L += [
    T("gilded", palette=dict(steel=(242, 214, 140), face=(242, 214, 140), fuller=(200, 160, 80), edge=(255, 250, 230), pattern_b=(160, 106, 34)),
      pattern="filigree", guard="crown", guard_color="gold", pommel="jewel", wrap="gilt", glow=((255, 60, 80), ["runes"])),
    T("frostbite", palette=dict(steel=(200, 236, 255), face=(200, 236, 255), fuller=(140, 190, 240), edge=(255, 255, 255), leather=(60, 90, 140),
                                pattern_b=(110, 160, 230)), pattern="frost", edge="jag", guard="crescent", guard_color="bright", pommel="jewel",
      glow=((170, 230, 255), ["crystals", "veins"])),
    T("saintsmercy", palette=dict(steel=(244, 240, 226), face=(244, 240, 226), edge=(255, 255, 255), leather=(201, 154, 72), pattern_b=(255, 236, 170)),
      pattern="filigree", guard="wings", guard_color="bright", pommel="star", wrap="gilt", glow=((255, 236, 170), ["halo", "core"])),
    T("hundredfold", palette=dict(steel=(96, 112, 128), face=(96, 112, 128), edge=(220, 236, 255), leather=(17, 17, 17), pattern_b=(150, 170, 196)),
      pattern="sheen", edge="jag", guard="spikes", pommel="claw", glow=((170, 210, 255), ["veins"])),
    T("sunforged", palette=dict(steel=(255, 214, 120), face=(255, 214, 120), edge=(255, 250, 220), pattern_b=(255, 244, 200)), pattern="sheen",
      guard="sunburst", guard_color="gold", glow=((255, 220, 120), ["core", "halo"])),
    T("flamberge", palette=dict(steel=(216, 200, 170), face=(216, 200, 170), edge=(255, 250, 240), leather=(90, 42, 90), pattern_b=(160, 140, 120)),
      pattern="damascus", edge="wave", guard="laurel", guard_color="gold", glow=((255, 170, 210), ["runes"])),
    T("oathkeeper", palette=dict(steel=(230, 236, 244), face=(230, 236, 244), edge=(255, 255, 255), leather=(47, 63, 110), pattern_b=(190, 210, 240)),
      pattern="filigree", guard="wings", guard_color="bright", pommel="jewel", glow=((120, 180, 255), ["runes", "halo"])),
    T("serpenttine", palette=dict(steel=(90, 160, 90), face=(90, 160, 90), edge=(220, 255, 200), pattern_b=(50, 100, 50)), pattern="scales",
      ornaments=["serpent"], serpent_color=(60, 130, 60), guard="horns", horn_color=(232, 184, 74), glow=((120, 255, 120), ["cracks"])),
    T("peasantspride", palette=dict(steel=(232, 184, 74), face=(232, 184, 74), edge=(255, 240, 180), wood=(90, 75, 60), pattern_b=(255, 230, 150)),
      pattern="filigree", guard="crown", guard_color="gold", glow=((80, 220, 120), ["runes"])),
    T("kingsbane", palette=dict(steel=(232, 184, 74), face=(232, 184, 74), edge=(255, 240, 200), leather=(90, 42, 90), pattern_b=(110, 50, 160)),
      pattern="filigree", guard="crown", guard_color="gold", pommel="jewel", glow=((170, 80, 255), ["cracks"])),
    T("thunderhead", palette=dict(steel=(138, 168, 216), face=(138, 168, 216), edge=(230, 240, 255), leather=(17, 17, 17), pattern_b=(70, 90, 140)),
      pattern="sheen", edge="jag", guard="spikes", glow=((150, 210, 255), ["veins"])),
    T("sunsteel", palette=dict(steel=(255, 224, 150), face=(255, 224, 150), edge=(255, 252, 230), leather=(180, 120, 50), pattern_b=(255, 246, 210)),
      pattern="sheen", guard="sunburst", guard_color="gold", pommel="star", glow=((255, 220, 120), ["core"])),
    T("hellforged", palette=dict(steel=(40, 30, 28), face=(40, 30, 28), fuller=(24, 18, 16), edge=(255, 140, 60), leather=(90, 20, 10),
                                 pattern_b=(150, 40, 10)), pattern="embers", edge="jag", guard="horns", horn_color=(30, 24, 22), pommel="skull",
      bone_color=(40, 30, 28), glow=((255, 120, 40), ["cracks"])),
    T("lastlight", palette=dict(steel=(236, 238, 244), face=(236, 238, 244), edge=(255, 255, 255), leather=(40, 40, 52), pattern_b=(255, 248, 220)),
      pattern="sheen", guard="wings", guard_color="bright", glow=((255, 244, 210), ["core", "halo"])),
    T("anvilofkings", palette=dict(steel=(70, 72, 80), face=(70, 72, 80), edge=(200, 200, 210), pattern_b=(232, 190, 90)), pattern="filigree",
      guard="crown", guard_color="gold", glow=((255, 200, 90), ["runes"])),
    T("ironcrown", palette=dict(steel=(140, 144, 154), face=(140, 144, 154), edge=(220, 224, 232), leather=(30, 30, 36), pattern_b=(90, 92, 100)),
      pattern="damascus", guard="crown", guard_color="darksteel", pommel="jewel", glow=((255, 50, 60), ["runes"])),
    T("wardensvow", palette=dict(steel=(236, 240, 250), face=(236, 240, 250), edge=(255, 255, 255), pattern_b=(170, 210, 240)), pattern="filigree",
      guard="wings", guard_color="bright", glow=((120, 230, 255), ["runes", "halo"])),
    T("dawnbringer", palette=dict(steel=(255, 240, 200), face=(255, 240, 200), edge=(255, 255, 255), pattern_b=(255, 210, 140)), pattern="blued",
      guard="sunburst", guard_color="gold", glow=((255, 200, 120), ["core", "halo"])),
    T("lastbastion", palette=dict(steel=(225, 228, 236), face=(225, 228, 236), edge=(255, 255, 255), pattern_b=(150, 160, 180)), pattern="damascus",
      guard="knot", guard_color="bright", glow=((120, 170, 255), ["runes"])),
    # the drops
    T("cryptlight", palette=dict(steel=(30, 32, 30), face=(30, 32, 30), edge=(170, 220, 180), pattern_b=(70, 90, 74)), pattern="sheen",
      guard="bones", pommel="skull", wrap="bone", glow=((120, 255, 170), ["runes"])),
    T("witchlight", palette=dict(steel=(40, 30, 54), face=(40, 30, 54), edge=(220, 190, 255), leather=(60, 30, 80), pattern_b=(90, 60, 130)),
      pattern="stars", guard="crescent", guard_color="blackiron", ornaments=["web"], glow=((190, 110, 255), ["runes", "stars"])),
    T("slagheart", palette=dict(steel=(34, 32, 32), face=(34, 32, 32), edge=(255, 150, 70), pattern_b=(110, 50, 20)), pattern="embers",
      guard="spikes", pommel="spike", ornaments=["chains"], glow=((255, 120, 30), ["cracks"])),
    T("thornwild", palette=dict(steel=(54, 70, 44), face=(54, 70, 44), edge=(190, 230, 160), pattern_b=(90, 70, 46)), pattern="bark", edge="barb",
      guard="thorns", ornaments=["thornwrap"], glow=((140, 255, 120), ["veins"])),
    T("skald", palette=dict(steel=(170, 180, 190), face=(170, 180, 190), edge=(240, 244, 250), pattern_b=(232, 190, 90)), pattern="knotwork",
      guard="knot", guard_color="gold", pommel="dragon", wrap="gilt", glow=((255, 210, 110), ["runes"])),
    T("starlight", palette=dict(steel=(24, 30, 60), face=(24, 30, 60), edge=(240, 240, 255), leather=(150, 24, 30), pattern_b=(255, 236, 170)),
      pattern="stars", guard="sunburst", guard_color="gold", pommel="star", glow=((255, 226, 140), ["stars"])),
    T("frostgift", palette=dict(steel=(220, 236, 250), face=(220, 236, 250), edge=(255, 255, 255), leather=(150, 24, 30), pattern_b=(206, 34, 44)),
      pattern="stripes", twist=1.2, freq=9, guard="holly", guard_color="gold", wrap="candy", glow=((150, 220, 255), ["crystals"])),
    T("blackflag", palette=dict(steel=(28, 28, 30), face=(28, 28, 30), edge=(220, 210, 190), brass=(200, 160, 80), pattern_b=(70, 60, 50)),
      pattern="rust", guard="anchor", guard_color="brass", pommel="skull", wrap="rope", glow=((255, 60, 50), ["cracks"])),
]

# ---------------------------------------------------------------- MYTHIC: one per drop, the whole works
L += [
    T("founders", palette=dict(steel=(24, 24, 30), face=(24, 24, 30), fuller=(14, 14, 18), edge=(255, 240, 200), leather=(30, 30, 36),
                               pattern_b=(232, 190, 90)), pattern="filigree", guard="wings", guard_color="gold", pommel="jewel", wrap="gilt",
      glow=((255, 236, 190), ["core", "halo", "runes"])),
    T("marrowking", palette=dict(steel=BONE, face=BONE, fuller=(150, 130, 100), edge=(250, 246, 236), pattern_b=(130, 110, 84)), pattern="rust",
      edge="serrate", guard="bones", wrap="bone", pommel="skull", ornaments=["chains"], chain_color=(70, 70, 66),
      glow=((120, 255, 170), ["cracks", "runes"])),
    T("hollowheadsman", palette=dict(steel=(22, 20, 20), face=(22, 20, 20), fuller=(12, 10, 10), edge=(255, 160, 60), pattern_b=(130, 50, 10)),
      pattern="embers", edge="jag", guard="horns", horn_color=(26, 22, 20), pommel="pumpkin", ornaments=["chains", "candles"],
      glow=((255, 140, 40), ["cracks", "runes"])),
    T("hornedking", palette=dict(steel=(54, 62, 44), face=(54, 62, 44), edge=(200, 240, 170), pattern_b=(110, 84, 54)), pattern="bark",
      guard="antlers", horn_color=(200, 186, 150), wrap="fur", pommel="acorn", ornaments=["thornwrap"], glow=((150, 255, 120), ["veins", "runes"])),
    T("jarlsbane", palette=dict(steel=(170, 180, 190), face=(170, 180, 190), edge=(240, 250, 255), pattern_b=(232, 190, 90)), pattern="knotwork",
      guard="knot", guard_color="gold", pommel="dragon", wrap="fur", fur_color=(120, 110, 100), glow=((120, 200, 255), ["runes", "veins"])),
    T("rimeheart", palette=dict(steel=(180, 220, 250), face=(180, 220, 250), edge=(255, 255, 255), leather=(40, 60, 110), pattern_b=(80, 130, 210)),
      pattern="frost", edge="jag", guard="crescent", guard_color="bright", pommel="jewel", glow=((150, 230, 255), ["crystals", "veins", "halo"])),
    T("krampus", palette=dict(steel=(30, 28, 28), face=(30, 28, 28), edge=(220, 60, 60), pattern_b=(90, 20, 20)), pattern="embers", edge="barb",
      guard="horns", horn_color=(60, 40, 30), wrap="fur", fur_color=(50, 40, 36), ornaments=["chains"], glow=((255, 40, 40), ["cracks"])),
    T("forgefather", palette=dict(steel=(36, 34, 34), face=(36, 34, 34), edge=(255, 170, 80), leather=(60, 30, 20), pattern_b=(160, 60, 16)),
      pattern="embers", guard="crown", guard_color="gold", pommel="spike", ornaments=["chains"], glow=((255, 130, 40), ["cracks", "runes"])),
    T("firstlight", palette=dict(steel=(250, 246, 236), face=(250, 246, 236), edge=(255, 255, 255), leather=(230, 230, 240), pattern_b=(255, 214, 140)),
      pattern="filigree", guard="sunburst", guard_color="gold", pommel="star", wrap="gilt", glow=((255, 236, 180), ["core", "stars", "halo"])),
    T("davyjones", palette=dict(steel=(40, 70, 70), face=(40, 70, 70), edge=(180, 255, 230), brass=(160, 140, 80), pattern_b=(90, 140, 120)),
      pattern="waves", guard="anchor", guard_color="brass", pommel="skull", ornaments=["serpent", "chains"], serpent_color=(70, 50, 90),
      glow=((90, 255, 210), ["cracks", "runes"])),
]

THEMES = {t["id"]: t for t in L}
