# Roblox scripts

Folder layout mirrors where each script lives in Studio.

| File | Studio location | Type |
|---|---|---|
| `ReplicatedStorage/MovementConfig.lua` | `ReplicatedStorage` → `MovementConfig` | ModuleScript |
| `ServerScriptService/WalkSpeedGovernor.server.lua` | `ServerScriptService` | Script |
| `StarterCharacterScripts/CameraRig.client.lua` | `StarterPlayer` → `StarterCharacterScripts` | LocalScript |
| `Tools/Pitchfork/PitchforkServer.server.lua` | inside the Pitchfork `Tool` | Script |
| `Tools/Pitchfork/PitchforkClient.client.lua` | inside the Pitchfork `Tool` | LocalScript |

## Character attributes (the wiring between scripts)

| Attribute | Set by | Read by | Meaning |
|---|---|---|---|
| `SpeedMult` | gear / buffs (server) | WalkSpeedGovernor | WalkSpeed multiplier, `1` = base |
| `ClunkMult` | gear / buffs (server) | CameraRig | footstep weight multiplier, `1` = base |
| `Swinging`, `SwingSlow` | weapon server | WalkSpeedGovernor | slow while attacking |
| `Blocking`, `BlockStoppedAt`, `ParryUntil`, `BlockMeter`, `StunnedUntil`, `FastUntil` | weapon server | weapon server (other players' tools) | combat state; `BlockMeter` is stamina |
| `TurnCapUntil` | weapon server | server only | **server clock** — never compare on the client |
| `LocalTurnCapUntil` | weapon client | CameraRig | turn cap deadline on the **client clock** |
| `LocalKickAt`, `LocalKickRise` | weapon client | CameraRig | procedural leg kick |

Tool requirements: a box `Part` named `Hitbox` whose longest axis runs along the blade.
Optional: a `workspace.NPCs` folder of humanoid models for kicks to hit.
