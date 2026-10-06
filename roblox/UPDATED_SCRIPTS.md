# Updated scripts: name tags and titles, kill effect sounds, livelier skin effects

- **Name tags:** Roblox's overhead names are gone. A name shows only when you look right at
  someone near enough (your aim on their body within 45 studs, a clear line of sight) or they're
  right next to you; in the Courtyard everyone within 24 studs shows. Tags carry a level badge, a
  staff badge in the role's colour, a gold crown and shimmering gold name for season pass holders,
  team colours in team modes, and bots show their rank.
- **Titles** show under your name tag, after your name on the Tab board, and in the kill feed when
  you get a kill (the free Recruit is left out). Pass holders get a crown on the board and in the feed.
- **Kill effects have sounds**, timed to each one (ice creaking then shattering, a zap and a
  thunderclap, a choir, a fanfare, a raven and wing bursts…), from Roblox's licensed libraries. The
  menu preview plays them once. Bots and dummies no longer get the effect twice.
- **Skin effects, much livelier:** Epic and Legendary skins leave a double trail (a bright core
  and a wide glow; Legendary trails shimmer). Auras are denser and layered, light up the blade,
  flare while the blade swings, throw sparks off the tip, and each has a swing sound.

| File | Studio location | Type | Change |
|---|---|---|---|
| [NameTags.client.lua](StarterPlayerScripts/NameTags.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NameTags | LocalScript | **new**: aim-and-distance name tags with titles, badges, the pass's gold |
| [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ SkinFX | LocalScript | **new**: auras flare, sparks fly, lights swell and swings sound while a blade moves |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua) | ReplicatedStorage ▸ SkinFX | ModuleScript | double trails, layered auras, blade light, tip sparks, swing sounds (`SWING`), the `SkinFX` tag |
| [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage ▸ KillFX | ModuleScript | timed sounds for every effect (`opts.sound` for previews) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | kill effect previews play their sound on the first loop |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | titles and the pass's crown in the kill feed and on the board |
| [Hub/Pastimes.server.lua](ServerScriptService/Hub/Pastimes.server.lua) | ServerScriptService ▸ Hub ▸ Pastimes | Script | publishes Title, Level, PassHolder on each player |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | Roblox's overhead name and health bar off for players |
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | overhead name off (TagName for the tags); no second kill effect |
| [TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | ServerScriptService ▸ TestDummies | Script | no second kill effect |

No Studio-only changes.
