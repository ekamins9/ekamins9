# Updated scripts: the Siege of Stormwatch, a new player's first battle

- **A brand-new player starts in a battle**: a dark, stormy night, the Iron Host at the gate of Stormwatch. They learn every move in the middle of it: swing, stab and overhead on raiders over the wall, dodging trebuchet fire, block / parry / riposte against a raider through the breach, kicking a brute's guard open, running the gauntlet of arrows to the gate, holding the gate beside the garrison, and a duel with Lord Varg, the Host's champion.
- **Cutscenes**: the opening (the storm, the camp, a fireball into a tower, Captain Hale), the ram breaking the gate, Lord Varg's entrance, dawn and the King's riders. Black bars, a flying camera, subtitles, title cards; any of them can be skipped.
- **The war all round you** (new WarFX): rain that stops under a roof, lightning and thunder, volleys of arrows arcing over the walls and sticking in the cobbles, trebuchet fire and its blasts, war cries, the battle's roar and its own score.
- **The screen**: a lesson card in your own controls, the captain's lines, a beacon over where to go (and an edge arrow when it's behind you), M to pause or skip, an end card with a welcome purse (300 Marks, 250 XP, once).
- **Fixes found while testing**: the over-the-shoulder camera pressed against a wall showed the inside of your own helmet (it now hides the head, CameraRig); a dungeon panel showed empty in other modes with their own HUD; the scoreboard strip doubled up over a mode's own top.
- **Checked in Play**: the whole story start to finish (each lesson's signal, the bombardment hurting and knocking back, the breach, the battle with the garrison, Varg's boss bar, dawn, the end card and its purse); every touched script compiled in Studio.
- **Studio-only (save the place)**: ReplicatedStorage ▸ WarAudio (the sounds), ServerStorage ▸ PrologueProps ▸ Trebuchet.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Prologue.lua](ServerScriptService/Game/Modes/Prologue.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | new |
| [StormwatchMap.lua](ServerScriptService/Game/StormwatchMap.lua) | ServerScriptService ▸ Game | ModuleScript | new |
| [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | new |
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | new |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | DOORS / MODES Prologue, Stormwatch |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the prologue's purse |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | a newcomer's training is the Prologue |
| [Intro.client.lua](StarterPlayerScripts/Intro.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | a newcomer goes straight to the siege |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | no helmet-inside view against walls |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `_G.OwnScore` |
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | hides for a cutscene |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `OwnTop` |
| [Adventure.client.lua](StarterPlayerScripts/Adventure.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | its panel only in the dungeon |
| [README.md](README.md) | | doc | the Siege of Stormwatch |

---

## Before that: the dungeon game looks like the rest of the game, our own prompts, clear ways out, no battle class screen

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
