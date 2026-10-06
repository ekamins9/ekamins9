# Updated scripts: skin rules, the daily WEAPONS shelf, skin trims

Skins are never sold at will any more. A skin comes from a crate, is earned (kills with
the weapon, or daily tasks finished), comes with a pack on the days that pack is in the
store, or is one of the day's **WEAPONS shelf** offers (4 a day, one Epic or Legendary
headliner first). Skins also change shape now: every skin names a **trim**, parts added
around the weapon (winged guards, gems, thorns, flames, frost, a halo, a crown, a serpent,
lightning, …) fitted to each weapon from its own Blade / Grip regions.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua) | ReplicatedStorage ▸ SkinTrims | ModuleScript | **new**: 19 trim builders, `apply` / `clear` / `frame` |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | `applySkin` builds the trim (and clears it for Default) |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `skinSource`, `skinOffers(day)`, `skinOnSale`; kill skins become unlocks; task stat words; duplicate / trim checks |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | regenerated: 242 skins, all with trims; duplicates on the four original weapons removed; 52 WEAPONS shelf skins; 8 task skins |
| [Catalog/Store.lua](ReplicatedStorage/Catalog/Store.lua) | ReplicatedStorage ▸ Catalog ▸ Store | ModuleScript | `skinSlots`, `skinPins`, `skinRetired` |
| [Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService ▸ Economy ▸ Economy | ModuleScript | a skin sells only if `Catalog.skinOnSale` |
| [Stats.lua](ServerScriptService/Economy/Stats.lua) | ServerScriptService ▸ Economy ▸ Stats | ModuleScript | each finished task counts `stats.contract`; announces task skins |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | skins with an `unlock` are owned once it is met |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | the store info carries today's skin offers |
| [gen_content.py](../scripts/gen_content.py) | (repo only) | script | `TINTS` with trims, `SHOP_STYLES`, `TASK_SKINS`; `--skins` regenerates the skins only |
| [skins_handmade.part](../scripts/skins_handmade.part) | (repo only) | data | trims for the four original weapons' skins |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | (docs) | | the skin sources and trims |
