# Updated scripts: corpses and kill-effect remains, better blade-on-wall sounds, quicker clean-up

- **The dead stay on the field.** A body is laid out where it fell (a still copy of the fighter,
  armor and all; the real body is hidden so the death camera keeps working), and the limbs it
  lost join it, so the body and its limbs fade together after 30 s (at most 8 bodies; the oldest
  go first).
- **Kill effects leave remains.** Crow Swarm leaves a skeleton picked clean among black
  feathers; Inferno a charred skeleton in a smoking heap of ash; Thunderstrike a blackened,
  smoking body; Royal Decree a golden statue with a crown; Shatter rubble in the body's colours;
  Gold Rush a heap of coins; Confetti Pop confetti; Frozen ice shards; Shadow Rift a scorched
  ring; Ascension a few glowing feathers. The remains appear as the effect hides the body, and
  with everything but a body or a statue the severed limbs go too (bones, for a skeleton).
- **Severed limbs and dropped weapons don't linger**: limbs on their own fade after 15 s (at
  most 10), dropped weapons after 25 s (at most 8), thrown heads after 18 s.
- **A blade hitting the world sounds like it.** Stone: steel striking stone with a short ring,
  over a gritty knock. Wood: iron biting oak (solid thunks) with a chop. Ground: a hard chop into
  earth. Metal: a manhole-cover clang.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Combat/Corpses.lua](ServerScriptService/Combat/Corpses.lua) | ServerScriptService ▸ Combat ▸ Corpses | ModuleScript | **new**: lays out the dead; skeletons, ash, statues, coins… |
| [Combat/Janitor.lua](ServerScriptService/Combat/Janitor.lua) | ServerScriptService ▸ Combat ▸ Janitor | ModuleScript | a Corpse kind; shorter lives for limbs, heads, weapons |
| [Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat ▸ Injury | ModuleScript | a severed limb carries its owner's corpse id |
| [Combat/Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | dropped weapons last 25 s |
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | a bot's body is laid out before the bot is cleared |
| [Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | wall sounds in two layers |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | every death goes to Corpses |
| [Hub/Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | a kill effect books its remains |
| [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ReplicatedStorage ▸ SoundBank | ModuleScript | new wall takes; `SoundBank.WALL` layers |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage ▸ Catalog ▸ KillFX | ModuleScript | `remains` / `remainsAt` per effect |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | corpses, remains, wall sounds |
