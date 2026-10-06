# Updated scripts: footsteps, a short jump, seats, bot legs, terrain fixed, a grander Courtyard

- **Footsteps by material** with the sounds you gave (Grass, Metal, Pebble, Wood, Plastic, Sand,
  Rock); every other material borrows the closest (stone sounds like Rock, mud like Grass, snow
  like a low Sand). **The pitter-patter that went on after you stopped is gone:** each step used
  to play Roblox's looping run clip (a whole run of little steps, about 2 s long) and they piled
  up. Each step is now one short sound, cut at 0.45 s, and Roblox's own run loop is muted.
  Other players' and bots' steps play too (from what's under them, heard within 70 studs).
- **Bots walk again.** Their leg animator gave up after waiting 60 s for the bot folder, and in
  the Courtyard that folder only appears with the first bot. It now looks for it every frame.
- **A short jump on Space** (about 2 studs, 6 stamina, 0.9 s cooldown; not while attacking,
  blocking or crouched). **Dodge moved to F** (and double-tap A / D / S, which can be turned off
  in settings: Double-tap dodge). Saved settings that had dodge on Space move it to F.
- **Seats:** Space stands you up and steps you off the front of the seat, so it doesn't catch
  you again. A "SPACE to stand up" hint shows while seated. The fountain's and the tavern's
  seats faced backwards; they face the fountain and the tables now.
- **Maps sunk into terrain, fixed.** Millfield's hill was far too big (its top was about 25 studs
  above the windmill's base), so it's now a plateau exactly at the windmill's foot. Sandpit's
  dunes reached over its walls, so they're pushed out past them. And the Training Yard's and
  Courtyard's backdrop hills spilled outside their terrain boxes, which left about 9,000 stray
  terrain cells in the place under every map. Those are archived
  (`ServerStorage ▸ _RetiredMaps ▸ StrayTerrain`) and cleared, and MapKit now undoes any spill
  so it can't happen again.
- **The Courtyard, grander:** a tiered fountain on a stepped platform (about 18 studs to its gilded
  spire, two bowls, falling water, a spray), big oaks in raised planters (about 22 studs), taller
  lamps, pale flagstone paths (a ring round the fountain, roads to the Hall, the gates, the
  Hatchery and the stone circle), tall footings on the walls, towers and keep, and paving right up
  to the walls (no grass sprouting along their feet).
- An old kill-effect test bench floating at y = 610 (`FxPreview`) moved out of the world into
  `_RetiredMaps`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Footsteps.lua](ReplicatedStorage/Footsteps.lua) | ReplicatedStorage ▸ Footsteps | ModuleScript | **new**: sounds per material, one step, the ground under a body |
| [Footsteps.client.lua](StarterPlayerScripts/Footsteps.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Footsteps | LocalScript | **new**: other players' and bots' steps; mutes Roblox's run loop |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | your steps through Footsteps; no more jump switch-off here |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | finds the bot folder whenever it appears; stride from root movement, eased |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | the hop, standing up from seats (+ hint), double-tap dodge |
| [MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | ServerScriptService ▸ MovementServer | Script | "Jump" costs stamina |
| [MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | ReplicatedStorage ▸ MovementConfig | ModuleScript | `JUMP_POWER`, `JUMP_COST`, `JUMP_COOLDOWN`, `DODGE_TAP` (`NO_JUMP` gone) |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Jump bind (Space), Dodge on F, Double-tap dodge setting, old-save fix |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | JumpPower from config |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | a jump ends an emote |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TravelScreen | LocalScript | the dodge tip names F |
| [MapKit.lua](ServerScriptService/Build/MapKit.lua) | ServerScriptService ▸ Build ▸ MapKit | ModuleScript | terrain spill undone; tall wall footings (`baseH`, `baseW`); tower footings (`base`) |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | `mound`; Millfield's hill and Sandpit's dunes fixed; windmill sails shortened |
| [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua), [MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build | ModuleScript | terrain boxes hold their hills; Courtyard fountain, oaks, lamps, paths, footings, seats |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | controls, footsteps, terrain, seats |

**Studio-only:** all four built maps (Courtyard, Training Yard, Millfield, Sandpit) were rebuilt
into `ServerStorage ▸ Maps`; the stray terrain and the test bench are in `_RetiredMaps`. Save the
place.
