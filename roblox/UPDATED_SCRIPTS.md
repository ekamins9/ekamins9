# Updated scripts: the Forge (real skin meshes), weekly drops, Mythics, serials, finishes, trading

- **The Forge: every skin is its own mesh.**
  - `blender/forge.py` rebuilds each weapon's recipe under a theme (`blender/themes.py`, about 80 of them):
    - new edges: serrated, jagged, nicked, waved, barbed
    - new guards: wings, horns, crowns, bones, antlers, thorns, holly, sunburst…
    - new pommels: skulls, jewels, pumpkins, dragons, stars…
    - new grips: vertebrae, fur, gilt wire, candy cane
    - ornaments: a serpent, chains, candles, feathers, a web
    - patterns painted into the steel
    - Neon inlays raycast onto the flats: runes, cracks, lightning, a core line, stars, a halo, crystals
  - 364 skins were built, uploaded and assembled in `ReplicatedStorage ▸ Cosmetics ▸ Skins`.
- **The calendar** (`Catalog ▸ Calendar`, `ReplicatedStorage ▸ Drops`):
  - 13 weekly drops, 10 Oct 2026 → 2 Jan 2027: Founders' Forge, Bonewright, the Hollow Night, All Hallows' Eve, Ironclad, the Wild Hunt, Northmen, Sea-Wolves, Frostfall, Yuletide, Twelfth Night, Midwinter, Black Sails.
  - Events: Halloween, a double-XP weekend, a Horde raid weekend, Yuletide.
  - Crates and eggs rotate in and out.
  - Free numbered claims: Jack's Grin, First Light, a Yule gift a day.
  - The Founders' window.
  - Each drop goes live by itself at its time on every server.
  - Staff can release a drop early or hold one back (F2 ▸ DROPS). Studio: `/clock`, `/drop`, `/keys`.
- **Mythic rarity**, 8 new crates and 6 new themed eggs, with about 125 new skins and 26 new companions:
  - new pet styles: bat, pumpkin, skeleton, boar, reindeer, bear, kraken
  - each drop crate has one Mythic; event crates and eggs never come back (RELIC)
  - LIMITED skins have a live stock count (the Frostgift: 2,026 made)
- **Copies:**
  - Every crate or shop skin and every hatched pet is a copy with its own serial number, finish, date, source and trade count.
  - Duplicates are kept: trade them, scrap them for Marks, or forge three into a better finish.
  - Finishes: Masterwork 5% / Radiant 1%; pets Golden 4% / Spectral 1%.
  - Kill tallies per skin. Armoury rating.
- **Trading** (TRADE in the dock):
  - same server, level 5+
  - both ready → 5 s countdown → both confirm → atomic swap, both saved
  - earned, pass, claim and Founder items are bound
- **Roblox paid-random-item rules:**
  - Odds and finish chances are shown before every open.
  - The pity shows as Legendary-or-better when due.
  - Where `ArePaidRandomItemsRestricted`: crates open with earned Keys only, eggs aren't sold, and paid crates and eggs become Marks.
  - Trading honours `IsPaidItemTradingAllowed`.
- **Keys** (earned only): a Key per level-up and one for the first win of the day; more from events.
- **The shop:** a "this week" drop banner and countdown, crates in rotation with leaving timers, a weekly pop-up.
- **Fixed:** the Hafted crate could roll Legendary with nothing Legendary in it (Frostbite moved in).

| File | Studio location | Type | Change |
|---|---|---|---|
| [blender/forge.py](../blender/forge.py), [blender/themes.py](../blender/themes.py) | — | Blender | **new**: the Forge |
| [blender/weapons.py](../blender/weapons.py) | — | Blender | theme hooks (edge, guard, pommel, grip, foot) |
| [scripts/upload_skins.py](../scripts/upload_skins.py), [scripts/skin_entries.py](../scripts/skin_entries.py) | — | Python | **new**: upload + Studio entries (ids stay gitignored) |
| [scripts/gen_content.py](../scripts/gen_content.py) | — | Python | `LOOK`, `DROP_SKINS` |
| [SkinModels.lua](ServerScriptService/Build/SkinModels.lua) | ServerScriptService ▸ Build ▸ SkinModels | ModuleScript | **new**: assembles skin models |
| [Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua) | ReplicatedStorage ▸ Catalog ▸ Calendar | ModuleScript | **new**: drops, events, rotation, claims |
| [Drops.lua](ReplicatedStorage/Drops.lua) | ReplicatedStorage ▸ Drops | ModuleScript | **new**: what is live now |
| [Collection.lua](ServerScriptService/Economy/Collection.lua) | ServerScriptService ▸ Economy ▸ Collection | ModuleScript | **new**: policy, serials, stock, finishes, forge, scrap, claims, rating |
| [Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy ▸ Trading | ModuleScript | **new**: trades |
| [Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [Crates.lua](ReplicatedStorage/Catalog/Crates.lua), [Eggs.lua](ReplicatedStorage/Catalog/Eggs.lua), [Companions.lua](ReplicatedStorage/Catalog/Companions.lua), [Economy.lua](ReplicatedStorage/Catalog/Economy.lua), [init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | drops, Mythic, looks, keys, finishes, trading, rotation |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | new styles, Golden / Spectral |
| [Dresser.lua](ReplicatedStorage/Dresser.lua), [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | ReplicatedStorage / StarterPlayerScripts | Module / LocalScript | models keep their effects; Masterwork / Radiant |
| [Economy.lua](ServerScriptService/Economy/Economy.lua), [Pastimes.lua](ServerScriptService/Economy/Pastimes.lua), [Stats.lua](ServerScriptService/Economy/Stats.lua), [EconomyServer.server.lua](ServerScriptService/Economy/EconomyServer.server.lua) | ServerScriptService ▸ Economy | Module / Script | keys, crate rules, copies, event pay, tallies |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout | Module / Script | copies; your best finish in hand |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua), [Pastimes.server.lua](ServerScriptService/Hub/Pastimes.server.lua), [Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | ServerScriptService ▸ Hub | Script | Forge / Scrap / Trade ops; pet finish; `/clock` `/drop` `/keys` |
| [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [Roles.lua](ServerScriptService/Admin/Roles.lua), [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | Admin | Script / Module / LocalScript | DROPS controls |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayerScripts | LocalScript | crates, shop banner, armory story / forge / scrap, TRADE, gifts, Hatchery rotation |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | the system; how to make a drop |

**Save the place:** the 364 skin models live in `ReplicatedStorage ▸ Cosmetics ▸ Skins` (Studio only).
