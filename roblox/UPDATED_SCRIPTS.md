# Updated scripts: dawn burns the dead; the dragon's last flight

- **Plague Night**: when the clock runs out with anyone living, the sun comes up and the dead burn away where they stand.
- **Dragonfall**: at a fifth of its health left (enraged), Cindermaw takes to the sky one last time: man the ballistae again to bring it down for good.
- **Checked in Play**: the dragon enraged at a third, took off again at 18%, the ballistae lit up, three bolts crashed it; compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Plague.lua](ServerScriptService/Game/Modes/Plague.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | dawn burns the dead away |
| [Dragon.lua](ServerScriptService/Combat/Dragon.lua) | ServerScriptService ▸ Combat | ModuleScript | a last flight near the end |
| [README.md](README.md) | | doc | |

---

## Before that: spoils of war in the Invasions; no stray team scores

- **Invasions: spoils of war.** Every third wave beaten, a gilded chest stands by what you defend, one for each of you: a relic rolled for your class (better the deeper you are) that stays yours for the whole run (it comes back with you after a fall), and a healing draught.
- **No more "CROWN 0 — 0 IRON"** on top of Plague Night: a mode with its own HUD hides the team score row.
- **Checked in Play**: an Invasion (Goblin Raid) with the wave set to 3: the spoils chest stood by the hoard, two openings gave two relics, and they were back on after dying and coming back; compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Invasion.lua](ServerScriptService/Game/Modes/Invasion.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | spoils of war |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | no team scores under an OwnHud |
| [README.md](README.md) | | doc | |

---

## Before that: Dragonfall, a dragon raid for you and your party

- **Dragonfall** (new mode, a party door on the Play menu's Adventures page, 1 – 6): **Cindermaw, the Ashen Wyrm**, in its burning caldera.
  - **The Ashen Caldera** (new CalderaMap, built fresh): cracked basalt with glowing seams round an old paved ring, black cliffs with lava running down them into pools, lava pools on the floor (they burn), six ward stones with glowing runes, four ballistae on platforms, the bones of something huge, the swords and shields of those who came before, ash falling, a burning dusk. Vote picture: MapShots ▸ Caldera.
  - **The fight**: on the ground it bites, claws, sweeps its tail, beats its wings, stomps, charges and breathes fire across the ground. At two thirds it **takes to the sky** (strafing fire, fireballs) and its **brood** climbs out of the lava; **man the ballistae** (hold to fire; guides over them) and three bolts bring it **crashing down**, open to everyone. Under a third it's **enraged**, fire rains, and its **Inferno** burns whoever it can see: get behind a **ward stone** (they light up and are marked as it winds up).
  - **Win**: everyone there is paid (`dragon_slain`), counted, and your fastest kill kept. The clock (14 min) runs out first: it holds the caldera.
- **The dragon's body on your screen** (new Dragon client script): its walk, wingbeats, tail whips, jaw, head tracking you, and fire streaming from its mouth, all from what the server says it's doing. Ragdolls, corpses and kill effects leave it alone.
- **The Depths' floors get the dungeon grime too** (cracks, rubble, cobwebs, damp, cages, candles, dust).
- **Checked in Play**: the caldera built (561 parts); the dragon came down, walked, charged, took to the sky at two thirds, its brood came out of the lava, three ballista bolts crashed it, it lay downed, enraged at a third, rose for an Inferno with the ward stones marked, died, and the fight was won; the Play menu's Dragonfall tile opens it (no longer "coming soon"); compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dragonfall.lua](ServerScriptService/Game/Modes/Dragonfall.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [CalderaMap.lua](ServerScriptService/Game/CalderaMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Dragon.lua](ServerScriptService/Combat/Dragon.lua) | ServerScriptService ▸ Combat | ModuleScript | new: the dragon |
| [Dragon.client.lua](StarterPlayerScripts/Dragon.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new: its joints and fire |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService | Script | a CustomBody gets no ragdoll setup |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub | Script | no kill effect on a CustomBody |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | the dragon's still copy for the menu |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS / MODES Dragonfall, its map title, the Adventures order |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `dragon_slain` |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | guides over Map ▸ Ballistae / Wards (GuideText) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Dragonfall tile's scene |
| [Dungeon.lua](ServerScriptService/Game/Dungeon.lua) | ServerScriptService ▸ Game | ModuleScript | grime on every floor |
| [README.md](README.md) | | doc | |

Studio-only: ReplicatedStorage ▸ MapShots ▸ Caldera (the vote picture) — save the place to keep it.
