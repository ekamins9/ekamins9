# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Last change:** Greatsword config brought up to date; its sounds copied into the Pitchfork config.

## New files (create these)

| File | Roblox Studio location | Type |
|---|---|---|
| [Tools/Greatsword/Config.lua](Tools/Greatsword/Config.lua) | `ServerStorage` → `Weapons` → `Greatsword` (Tool) → `Config` | ModuleScript |
| [Tools/Greatsword/Server.server.lua](Tools/Greatsword/Server.server.lua) | inside the Greatsword Tool → `Server` (same 2-line loader as the Pitchfork's — skip if you already have it) | Script |
| [Tools/Greatsword/Client.client.lua](Tools/Greatsword/Client.client.lua) | inside the Greatsword Tool → `Client` (same as the Pitchfork's — skip if you already have it) | LocalScript |

## Updated files (replace the whole script)

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [Tools/Pitchfork/Config.lua](Tools/Pitchfork/Config.lua) | `ServerStorage` → `Weapons` → `Pitchfork` (Tool) → `Config` | ModuleScript | `SOUNDS` filled with your Greatsword sound IDs (+ `KickHit`) |
| [README.md](README.md) | not a Studio object | — | Greatsword rows added to the placement table |

## Other Studio steps

- [ ] Both Tools live in `ServerStorage` → `Weapons` now, not StarterPack
