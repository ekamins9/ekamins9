# Updated scripts: skin effects, kill effects, emotes

- **Skin effects**: Epic and Legendary skins leave a swing trail in their glow colour, and
  every Legendary sheds an aura around the blade (embers, frost, holy light, shadow, storm,
  toxic, petals, gold, blood). The menu names them on the skin ("Trail · Embers").
- **Kill effects**: when you land the killing blow, the body does your equipped effect for
  everyone: Shatter (free), Confetti Pop, Gold Rush, Crow Swarm, Inferno, Frozen Solid,
  Thunderstrike, Ascension (Relic Crate), Shadow Rift and Royal Decree (season pass).
- **Emotes**: **B** opens the emote wheel (six slots, 1–6 or click). There are 14: Salute,
  Bow, Cheer and the sword-twirling Flourish are free. Wave, Shrug, Beckon, Kneel, Laugh, Jig,
  Blade Toss and Champion come from the Relic Crate, and War Cry and Windmill from the pass.
  Everyone sees them, and moving or attacking ends one.
- **Relic Crate** (80 Crowns): kill effects and emotes only. The crates screen shows each item
  its own way: a skin turns on its weapon, an effect or emote plays on you.
- **ARMORY** has two new tabs. **KILL FX** loops each effect on you, with EQUIP. **EMOTES**
  loops each emote on you and edits the wheel.
- **Season pass**: tier 8 premium is Shadow Rift, tier 12 free is War Cry, tier 18 premium is
  Windmill, and tier 28 premium is Royal Decree.
- Looks only: nothing here changes damage, speed or any stat.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua) | ReplicatedStorage ▸ SkinFX | ModuleScript | **new**: trails and auras on skinned weapons; `describe` for the menu |
| [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage ▸ KillFX | ModuleScript | **new**: the ten kill effects (world + menu preview) |
| [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage ▸ Emotes | ModuleScript | **new**: the 14 emote motions, the weapon spin, preview posing |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage ▸ Catalog ▸ KillFX | ModuleScript | **new**: names, rarities, sources |
| [Catalog/Emotes.lua](ReplicatedStorage/Catalog/Emotes.lua) | ReplicatedStorage ▸ Catalog ▸ Emotes | ModuleScript | **new**: names, rarities, sources |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `KILLFX` / `EMOTES` maps, `itemSource`, `crateItems`, reward checks |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | the Relic Crate |
| [Catalog/Pass.lua](ReplicatedStorage/Catalog/Pass.lua) | ReplicatedStorage ▸ Catalog ▸ Pass | ModuleScript | four tiers now give the pass-only effects and emotes |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | regenerated: Legendary skins carry an `fx` aura |
| [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua) | ReplicatedStorage ▸ SkinTrims | ModuleScript | the old Legendary sparkle moved to SkinFX |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | applies SkinFX; preview weapon welds remember their grip (for emote spins) |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | an emote's pose is layered over the combat pose |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | the Emote key (B) |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | **new**: `FxEvent` / `EmoteRemote`, ownership checks, `_G.KillFxHook` |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | **new**: plays kill effects and emotes; the emote wheel |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | a kill calls the kill-effect hook |
| [TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | ServerScriptService ▸ TestDummies | Script | a dummy kill calls it too |
| [Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService ▸ Economy ▸ Economy | ModuleScript | crates roll any item kind; pass rewards can be `killfx` / `emote` |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | owned / equipped kill effect and emote wheel |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | `Equip "killfx"` and `Equip "emotes"` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | ARMORY ▸ KILL FX / EMOTES, live previews on you, crates of any item kind, pass cards for effects / emotes, skin effect tags |
| [gen_content.py](../scripts/gen_content.py), [skins_handmade.part](../scripts/skins_handmade.part) | (repo only) | generator | `FX_BY_NAME` auras on Legendary skins |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md), [README.md](README.md) | (docs) | | skin effects, kill effects, emotes, the Relic Crate |

Nothing to do by hand in Studio: the remotes are made by `Hub ▸ Cosmetics` at start.
