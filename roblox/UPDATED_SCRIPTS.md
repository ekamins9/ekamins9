# Updated scripts: Horde, and the Colosseum

- **HORDE** (a new door on the PLAY board): you and your party against waves of bots. Each wave
  is bigger and better trained, with a Warlord every fifth. The fallen come back between waves,
  and the round ends when everyone is down at once. Each wave beaten pays everyone, kills pay the
  killer, and your best wave is kept. The HUD shows the wave, the foes left and the countdown, and
  a banner announces each wave and each one beaten.
- **The Colosseum:** a desert arena with a podium wall, four tiers of stands, a two-storey
  arcade, awnings, four gates where the horde comes in, and a dais and columns on the floor. It's
  also in the Lists, Last Team Standing, FFA and King of the Hill rotations.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Horde.lua](ServerScriptService/Game/Modes/Horde.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Horde | ModuleScript | **new**: waves, the Warlord, the breather, wave pay |
| [MapColosseum.lua](ServerScriptService/Build/MapColosseum.lua) | ServerScriptService ▸ Build ▸ MapColosseum | ModuleScript | **new**: the arena |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | the Colosseum |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | the Horde mode and door; the Colosseum in five modes |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | the Horde door (a Friends server for your party) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | the HORDE tile and its scene |
| [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Objectives | LocalScript | the Horde HUD and banners |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua), [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ReplicatedStorage ▸ Catalog, ServerScriptService | ModuleScript / Script | `wave` pay |

**Studio-only:** `ServerStorage ▸ Maps ▸ Colosseum` is new. Save the place.
