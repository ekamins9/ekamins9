# Updated scripts: combat sounds, stamina that rewards good fighting, human bots, clean-up

- **Combat sounds overhauled** (`SoundBank`, from Roblox's licensed library). Swings whoosh by
  weapon (sharp sword swishes for one-handers, deep whooshes for two-handers and polearms); a
  landed blow layers the cut / stab / blunt thud, bones cracking on blunt and killing blows, plate
  ringing or mail jingling when the limb was armored, and the victim's grunt. Parries ring
  bright, blocks clang dull, chambers clash and scrape; blades hitting stone, wood, metal or
  dirt each sound different. Fighters grunt as they swing and kick, cry out when cut, give a
  last cry when they die (not when beheaded), and bodies thud to the ground (plate clanks).
  Every fighter has their own voice pitch and never grunts over themselves. Dismember, impale,
  disarm and dodge have sounds now. Takes rotate, never the same twice in a row.
- **Kill effect sounds** are quieter (55 %) and fade sooner.
- **Stamina rewards fighting well.** A landed hit now refunds its cost plus 8, a kill gives
  back 35 % of your max (HUD: KILL +N), parries pay at least 10, chambers are free, and stamina
  trickles back at 35 % even mid-fight. Misses, held blocks and feints are what drain you.
- **Bots fight like people.** They move in moods (press in, circle, stand and watch, give
  ground) instead of holding a perfect distance; they carry momentum when turning; they walk a
  beat before chasing and then sprint only in bursts; and a swing they don't parry they step
  aside from (after their reaction time, briefly), or simply stand and trade. **Their legs
  walk again**: the leg animator read speed frame by frame, and a server-moved body arrives in
  jumps, so a sprinting bot looked like it stood still.
- **Clean-up** (`Combat ▸ Janitor`): severed limbs, heads and dropped weapons fade out after a
  while (20 s / 22 s / 60 s), the oldest go first past a cap (14 / 8 / 12), and the field is
  swept clean between rounds.

| File | Studio location | Type | Change |
|---|---|---|---|
| [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ReplicatedStorage ▸ SoundBank | ModuleScript | **new**: the sound pools, voices, weapon sound classes |
| [Sounds.lua](ReplicatedStorage/Sounds.lua) | ReplicatedStorage ▸ Sounds | ModuleScript | `Sounds.bank`; voices from the bank (per-fighter pitch, chance, gap) |
| [Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | bank sounds for every slot, layered hit sounds, wall sounds by family; stamina: HIT_BONUS, KILL_REFUND, COMBAT_REGEN, PARRY_REFUND 10, CHAMBER_COST_MULT 0 |
| [Combat/Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat ▸ Injury | ModuleScript | dismember / impale / disarm / bleed / head-throw sounds; limbs and heads to the Janitor |
| [Combat/Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | dropped weapons to the Janitor (60 s) |
| [Combat/Janitor.lua](ServerScriptService/Combat/Janitor.lua) | ServerScriptService ▸ Combat ▸ Janitor | ModuleScript | **new**: fades out remains by age and cap; clears between rounds |
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | footwork moods, momentum, chase beat and sprint bursts, step-aside instead of retreat; `step` / `aggression` / `hesitate` per skill |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | regen trickles in combat; death cry and body fall |
| [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage ▸ KillFX | ModuleScript | `KillFX.VOLUME` 0.55, nearer roll-off |
| [SoundConfig.lua](ReplicatedStorage/SoundConfig.lua) | ReplicatedStorage ▸ SoundConfig | ModuleScript | dodge whoosh |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | bot legs from replicated velocity / a 0.15 s window |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | sounds, voice, stamina, bots, clean-up |
