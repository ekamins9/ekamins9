# Roblox scripts

Folder layout mirrors where each script lives in Studio.

| File | Studio location | Type |
|---|---|---|
| `ReplicatedStorage/MovementConfig.lua` | `ReplicatedStorage` → `MovementConfig` | ModuleScript |
| `ReplicatedStorage/DebugFlags.lua` | `ReplicatedStorage` → `DebugFlags` | ModuleScript |
| `ReplicatedStorage/Modifiers.lua` | `ReplicatedStorage` → `Modifiers` | ModuleScript |
| `ReplicatedStorage/Sounds.lua` | `ReplicatedStorage` → `Sounds` | ModuleScript |
| `ReplicatedStorage/SoundConfig.lua` | `ReplicatedStorage` → `SoundConfig` | ModuleScript |
| `ReplicatedStorage/RigPose.lua` | `ReplicatedStorage` → `RigPose` | ModuleScript |
| `ReplicatedStorage/Combat/CombatClient.lua` | `ReplicatedStorage` → `Combat` (Folder) → `CombatClient` | ModuleScript |
| `ServerScriptService/WalkSpeedGovernor.server.lua` | `ServerScriptService` → `WalkSpeedGovernor` | Script |
| `ServerScriptService/CharacterSystems.server.lua` | `ServerScriptService` → `CharacterSystems` | Script |
| `ServerScriptService/PoseRelay.server.lua` | `ServerScriptService` → `PoseRelay` | Script |
| `ServerScriptService/Combat/CombatServer.lua` | `ServerScriptService` → `Combat` (Folder) → `CombatServer` | ModuleScript |
| `ServerScriptService/Combat/Injury.lua` | `ServerScriptService` → `Combat` → `Injury` | ModuleScript |
| `ServerScriptService/Combat/Ragdoll.lua` | `ServerScriptService` → `Combat` → `Ragdoll` | ModuleScript |
| `StarterPlayerScripts/RigReplicator.client.lua` | `StarterPlayer` → `StarterPlayerScripts` → `RigReplicator` | LocalScript |
| `StarterCharacterScripts/CameraRig.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript |
| `StarterCharacterScripts/InjuryFX.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `InjuryFX` | LocalScript |
| `StarterCharacterScripts/HUD.client.lua` | `StarterPlayer` → `StarterCharacterScripts` → `HUD` | LocalScript |
| `Tools/Pitchfork/Config.lua` | inside the Tool → `Config` | ModuleScript |
| `Tools/Pitchfork/Server.server.lua` | inside the Tool → `Server` | Script |
| `Tools/Pitchfork/Client.client.lua` | inside the Tool → `Client` | LocalScript |

Nothing gets inserted into a Tool automatically — create `Config`, `Server` and `Client`
inside each weapon by hand. `CombatServer` / `CombatClient` live once, in the folders above.
Note `RigReplicator` goes in **StarterPlayerScripts** (not StarterCharacterScripts): it
tracks everyone *else* and must survive your respawns.

## Making a new weapon

Duplicate the Pitchfork tool's three scripts into the new Tool and edit **only `Config`**:
animations, `ATTACKS` (each with `kind = "slash"` or `"stab"`), `CYCLE_ORDER`, `REACH`,
`SPEED_MULT`, `TWO_HANDED`, its weight (`SpeedMult` / `ClunkMult`, 1 = no effect) and
`SOUNDS`. Any key from `CombatServer.DEFAULTS` or `CombatClient.DEFAULTS` can be overridden
there too (e.g. `PARRY_WINDOW`, `HEAD_DAMAGE_MULT`, `KEYS`, `TRAIL_COLOR`).

The Tool needs a box `Part` named `Hitbox` whose longest axis runs along the blade.
Optional: a `workspace.NPCs` folder of humanoid models — kicks, ragdoll, and bleeding
work on them too.

## Controls

LMB cycle attack · Q/E/F/X specific attacks · RMB block (feint during windup) ·
G kick · **LeftControl crouch** (hold) · scroll zoom (all the way in = first person)

## Combat rules (Mordhau-ish)

- **Phases**: windup → release (blade live) → recovery. All scale with `SPEED_MULT`.
- **Physical blocking**: while holding RMB your weapon's `GuardHull` is raycast-visible.
  The incoming blade must touch it *before* a body part (a body hit whose point lies inside
  the hull also counts), and you must face the attacker within `BLOCK_CONE_DEG`.
  From behind / off-side / under the guard = clean hit.
- **Parry**: block raised within `PARRY_WINDOW` → attacker stunned, you get a riposte
  (`RIPOSTE_SPEED` tempo for `RIPOSTE_DURATION`). Re-tapping block spams no new windows.
- **Feint**: RMB during windup cancels the attack into a block (`FEINT_COST`).
- **Combo**: press a *different* attack during release/recovery to chain it, skipping recovery.
- **Kick (G)**: unblockable, staggers a held block. Needs your right leg.
- **Crouch (LeftControl)**: torso drops `CROUCH_DROP`, `SpeedMult_Crouch` slows you. Other
  players see it, so ducking under a high swing or leaning back from a stab is a real dodge.
- **Stamina** (`BlockMeter`): attacks, feints, kicks, blocks drain it. Hits 0 from a
  block → guard break stun. Guard hit while already at 0 → **weapon flies out of your hand**.
- **Head**: `HEAD_DAMAGE_MULT` × damage (2× by default) — no automatic kill.
- **Kills**: a lethal **slash** severs the limb it hit (arm, leg, or head → decapitation);
  with `BLEED_OUT_CHANCE` an arm/leg victim survives on `BLEED_HP` and bleeds out instead.
  A lethal **stab** leaves the weapon run through the body (`IMPALE`) until the corpse despawns.
  Lose the right arm → weapon dropped, can't wield. Lose the left arm → dropped only if
  `TWO_HANDED`. Trying to block one-armed flings the weapon. Each lost leg multiplies speed
  by `LEG_SPEED` and clunk by `LEG_CLUNK`.
- **Ragdoll**: leg hits knock you down for `KNOCKDOWN_TIME`; death ragdolls for good.
- **Death cam**: first person from inside your head wherever it rolls, then fade to black.
- **Disarmed weapons** land as real pickups; walk over one to grab it (after 2s).

## Pose replication

`CameraRig` computes your body pose (aim bend, lean, bob, kick, crouch, arm sway) with
`RigPose` and sends the 9 inputs ~20×/s over `PoseRemote` (an UnreliableRemoteEvent).
`PoseRelay` forwards them to every other player; their `RigReplicator` runs the same
`RigPose` math on your character, smoothed. Nothing is applied on the server. Pose shape
constants (`NECK_PITCH`, `CROUCH_DROP`, `KICK_ANGLE`, …) live in `RigPose.CONFIG` so
everyone renders the same body.

## Debug flags (live, no code changes)

Attributes on `ReplicatedStorage.Debug` — created automatically at startup. Toggle in
Studio via Properties → Attributes, or from the F9 console:

```lua
-- Server tab: everyone sees it. Client tab: only you (fine for Rays).
game.ReplicatedStorage.Debug:SetAttribute("Rays", true)
```

| Flag | Default | Effect |
|---|---|---|
| `Logs` | true | `print()` chatter from combat scripts |
| `Rays` | false | draw blade sweep rays (green miss / red hit) |
| `GuardHull` | true | show the block hull around weapons (brighter while blocking) |
| `Hitbox` | false | show weapon `Hitbox` parts |
| `TurnCap` | false | print when the camera turn cap engages |

## Sound slots

All default to `rbxassetid://0` (silent). Per weapon, in `Config.SOUNDS`: `Equip`,
`Swing`, `Hit`, `Block`, `Parry`, `Kick`. Global, in `SoundConfig`: `Footstep`,
`Heartbeat`, `Death`, `Dismember`, `Impale`, `Bleed`, `Disarm`, `BodyFall`.

## Movement modifiers (composable)

Anything that scales speed or footstep clunk writes **one attribute per source** on the
character and clears it (`nil`) when done. Consumers multiply every attribute with the
prefix, so sources stack and never overwrite each other:

```lua
character:SetAttribute("SpeedMult_Armor", 0.7)   -- plate armor: 30% slower
character:SetAttribute("ClunkMult_Armor", 1.8)   -- …and 80% heavier steps
character:SetAttribute("SpeedMult_Armor", nil)   -- unequip
```

| Attribute | Set by |
|---|---|
| `SpeedMult_Weapon`, `ClunkMult_Weapon` | CombatServer (from the weapon `Config`) |
| `SpeedMult_Swing` | CombatServer while attacking or kicking |
| `SpeedMult_Crouch` | PoseRelay while crouched |
| `SpeedMult_Limbs`, `ClunkMult_Limbs` | Injury, per lost leg |
| `SpeedMult_Armor`, `ClunkMult_Armor` | your future armor system |
| bare `SpeedMult` / `ClunkMult` | you, by hand in Properties, for testing |

## Other character attributes

| Attribute | Set by | Read by | Meaning |
|---|---|---|---|
| `Blocking`, `BlockStoppedAt`, `ParryUntil`, `BlockMeter`, `BlockMax`, `StunnedUntil`, `FastUntil` | CombatServer | CombatServer (other players' tools), HUD | combat state; `BlockMeter` is stamina |
| `Crouching` | PoseRelay | anything | holding crouch |
| `LimbLost_LeftArm` … `LimbLost_Head`, `Bleeding`, `BleedDPS` | Injury | CombatServer, InjuryFX, HUD | injuries; a bandage system clears `Bleeding` |
| `KnockedDownUntil` | Ragdoll | Ragdoll | knockdown timer |
| `HitTick`, `HitDir` | CombatServer | CameraRig, InjuryFX | victim feedback (flinch, flash) |
| `TurnCapUntil` | CombatServer | server only | **server clock** — never compare on the client |
| `LocalTurnCapUntil` | CombatClient | CameraRig | turn cap deadline on the **client clock** |
| `LocalKickAt`, `LocalKickRise` | CombatClient | CameraRig | procedural leg kick |
| `LocalImpactAt`, `LocalImpactKind` | CombatClient | CameraRig | attacker feedback (impact kick) |
