# Updated scripts: the dungeon game looks like the rest of the game, our own prompts, clear ways out, no battle class screen

- **The dungeon lobby wears the game's look**: FredokaOne headings, Gotham type, outlined white text, dark-glass rounded panels, chunky glossy buttons, a blue pill under the chosen tab, with Dark and Darker's layouts and a gold accent. The raid's own screens (DarkUI) follow.
- **Nobody is naked**: a mannequin's empty armour slot takes its class's plain piece. The PLAY scene shows your party standing before the table, facing you, lit warm.
- **Our own prompts** instead of Roblox's default "V" box: a glass card with a key cap, the action, the thing, a hold bar; loot tinted by its rarity (new Prompts client script).
- **Ways out, always clear**: WALK AROUND [M] and TO THE COURTYARD (asked once) in the lobby; a small bar at the top of the Gilded Rat while you walk about (LOBBY / TO THE COURTYARD); signs over the gate, the door home and your stash.
- **No battle class screen in the Gilded Rat, Deadvault or the Depths**: you go in as your lobby class. Falling mid-raid shows the dungeon game's own YOU FELL / DOWN screen (SPECTATE, BACK TO THE GILDED RAT).
- **A raid's end**: no map vote; your own end screen (YOU GOT OUT / YOU FELL); everyone goes back to the Gilded Rat, each party together.
- **Fixes found while testing**: a 0-second intermission waited forever (Studio couldn't leave the Gilded Rat); the lobby stayed open over a raid; the gold label covered a tab; the hotbar showed through the lobby; prompt cards and the lobby's name tags vanished after a respawn; the top line read "THE GILDED RAT · THE GILDED RAT".
- **Checked in Play**: Tavern arrival (no class screen, lobby opened, each tab looked at), walk-around bar and signs, into Deadvault with no spawn press, fell, YOU FELL screen, BACK TO THE GILDED RAT ended the raid with YOU FELL and returned to the Tavern with a body; a respawn in the Tavern kept prompt cards working; compile of every touched script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [DarkUI.lua](ReplicatedStorage/DarkUI.lua) | ReplicatedStorage | ModuleScript | the game's look |
| [DungeonMenu.client.lua](StarterPlayerScripts/DungeonMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | restyle, ways out, Tavern bar, DOWN screen, scene, fixes |
| [Prompts.client.lua](StarterPlayerScripts/Prompts.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout | Script | ownSpawn: no class screen, "Down" |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | ownSpawn on Tavern, Deadvault, Depths |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | Script | no endless 0 s break; no map vote after a raid |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | toTavern; everyone home after a raid |
| [Deadvault.lua](ServerScriptService/Game/Modes/Deadvault.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | RaidFate; leaving ends it in Studio; wording |
| [Depths.lua](ServerScriptService/Game/Modes/Depths.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | leaving ends it in Studio |
| [Tavern.lua](ServerScriptService/Game/Modes/Tavern.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | signs |
| [RoundResult.client.lua](StarterPlayerScripts/RoundResult.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the dungeon game's end screen |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | no double name; BACK TO THE GILDED RAT |
| [Spectate.client.lua](StarterPlayerScripts/Spectate.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | BACK instead of CLASS / SPAWN in the dungeon game |
| [DeathScreen.client.lua](StarterPlayerScripts/DeathScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the dungeon game's next-step lines |
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | steps aside for the lobby |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | mannequins never naked |
| [README.md](README.md) | | doc | |

---

## Before that: dawn burns the dead; the dragon's last flight

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
