# Updated scripts: playtime gifts, the Hatchery, companions

Cosmetic things to do in the Courtyard, from the retention research: reasons to come back
(offline incubation, daily gifts) and reasons to stay (AFK at the Hatchery). Nothing changes
combat.

- **Playtime gifts** — six a day for minutes played on any server (5, 10, 20, 30, 45 and 60
  minutes: Marks, a Speckled Egg, a free crate open, a Mossy Egg, Crowns). A chip at the top
  left counts down and claims; the lobby has a panel too.
- **The Hatchery** — a thatched pavilion with three nests, built into the Courtyard's open
  square. Eggs incubate in real time, even while you're offline or in a match. Standing by the
  Hatchery doubles the speed. Your own eggs sit in the nests with timers; press E to hatch.
- **Eggs:** Speckled (30 min, 400 Marks), Mossy (2 h, 1,200 Marks), Ember (6 h, 60 Crowns) and
  Royal (12 h; gifts, login days and the pass only). HATCH NOW skips the wait for Crowns.
- **Companions** — 21 creatures built from parts: birds, beasts, hoppers, wisps and drakes,
  from a sparrow to a griffin. They follow you around, and duplicates add stars (five stars
  sparkle). The Iron Hound is a season pass reward.
- **HATCHERY screen** (new dock tile with a ready-egg badge): NESTS and COMPANIONS (the
  collection, silhouettes for the ones not found yet, take along / send home).
- **Login days** no longer restart after a missed day; they pause. Login days 2 and 6 and pass
  tiers 6, 16, 19, 21 and 26 now give eggs or the Iron Hound.
- **SETTINGS:** Companions All / Mine / None.
- **Studio cheats:** `/egg <Id> [n]`, `/ripen`, `/playtime <minutes>`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/Gifts.lua](ReplicatedStorage/Catalog/Gifts.lua) | ReplicatedStorage ▸ Catalog ▸ Gifts | ModuleScript | **new**: the six daily gifts |
| [Catalog/Eggs.lua](ReplicatedStorage/Catalog/Eggs.lua) | ReplicatedStorage ▸ Catalog ▸ Eggs | ModuleScript | **new**: nests, boost, the Hatchery's spot, the four eggs |
| [Catalog/Companions.lua](ReplicatedStorage/Catalog/Companions.lua) | ReplicatedStorage ▸ Catalog ▸ Companions | ModuleScript | **new**: 21 companions |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `GIFTS` / `EGG` / `COMPANION`, `eggPool`, `companionSource`, checks |
| [Catalog/Login.lua](ReplicatedStorage/Catalog/Login.lua), [Catalog/Pass.lua](ReplicatedStorage/Catalog/Pass.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | eggs and the Iron Hound as rewards |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | **new**: builds and animates companions and eggs |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | the Companions choice |
| [Pastimes.lua](ServerScriptService/Economy/Pastimes.lua) | ServerScriptService ▸ Economy ▸ Pastimes | ModuleScript | **new**: gifts, eggs, nests, hatching, companions |
| [Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService ▸ Economy ▸ Economy | ModuleScript | egg / companion rewards; login runs pause |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | play, eggs, nests, companion, stars |
| [Pastimes.server.lua](ServerScriptService/Hub/Pastimes.server.lua) | ServerScriptService ▸ Hub ▸ Pastimes | Script | **new**: the playtime clock, the Hatchery (built in the Courtyard), player attributes |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | ops GiftClaim, Hatchery, EggBuy, EggPlace, Hatch, Companion; state carries gifts + hatchery |
| [Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua) | ServerScriptService ▸ Hub ▸ Cheats | Script | `/egg`, `/ripen`, `/playtime` |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Pastimes | LocalScript | **new**: companions following, the gift chip, your eggs in the nests, hatching in the world |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | HATCHERY screen and dock tile, lobby gifts panel, egg / companion reward cards |
| [ui_icons.py](../blender/ui_icons.py) | (repo only) | Blender script | the Hatchery icon (a nest with two eggs) |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | (docs) | | pastimes, eggs, companions, gifts |

Studio-only: `ReplicatedStorage ▸ Cosmetics ▸ Icons ▸ Hatchery` (the dock icon decal). Save the
place so it stays.
