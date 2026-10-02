# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Now synced with Rojo:** `git pull` + `rojo serve` on your PC puts all of this into Studio by itself — see [ROJO_SETUP.md](ROJO_SETUP.md).

**Last change: the first-release catalog, cross-server invites, the queue-size error, earned gear.**
- **Content:** 12 paid armor packs (3 tiers × Marks / Crowns pricing), 9 earned pieces, 40 weapon
  skins (crate · shop · in-pack · Royal Armoury · kill-earned), a third crate, 10 hairs, 7 beards,
  6 faces, 11 hair colors, 25 armor colors, 12 earned titles, 24 contracts. Every model to build is
  listed in **[RELEASE_CONTENT.md](RELEASE_CONTENT.md)**.
- **Earned gear:** pieces and titles can carry an `unlock` (level / kills / wins / any stat); one
  shared check (`Catalog.unlocked`) serves the server and the menu. The shop has an EARNED IN
  BATTLE panel with progress; locked pieces and titles show 🔒 with the requirement.
- **Cross-server invites:** a friend in another server gets the invite through MessagingService;
  accepting teleports them to the leader's server where they are seated in the party. Friend rows
  offer INVITE · JOIN; the invite picker lists friends elsewhere.
- **Queue:** FIND MATCH with a party bigger than the bracket shows a clear popup (with a button to
  switch bracket) instead of silently failing; server refusals show as a popup too.

## Changed files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript | earned items, queue popup, invite rows, pack skins, EARNED panel |
| [ServerScriptService/Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | `ServerScriptService` → `Hub` → `HubServer` | Script | cross-server invites (MessagingService + TeleportData.joinParty) |
| [ServerScriptService/Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | `ServerScriptService` → `Loadout` → `Profile` | ModuleScript | `has` uses `Catalog.unlocked` for pieces, weapons, titles |
| [ReplicatedStorage/Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | `ReplicatedStorage` → `Catalog` | ModuleScript | `unlocked / unlockProgress / unlockText`, `isFree` excludes earned |
| [ReplicatedStorage/Catalog/Packs.lua](ReplicatedStorage/Catalog/Packs.lua) | `Catalog` → `Packs` | ModuleScript | 12 release packs + `Earned` |
| [ReplicatedStorage/Catalog/Pieces.lua](ReplicatedStorage/Catalog/Pieces.lua) | `Catalog` → `Pieces` | ModuleScript | 9 earned pieces |
| [ReplicatedStorage/Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | `Catalog` → `Skins` | ModuleScript | 40 skins |
| [ReplicatedStorage/Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | `Catalog` → `Crates` | ModuleScript | Royal Armoury |
| [ReplicatedStorage/Catalog/Body.lua](ReplicatedStorage/Catalog/Body.lua) | `Catalog` → `Body` | ModuleScript | more hair / beards / faces / colors, `earnedTitles` |
| [ReplicatedStorage/Catalog/Palette.lua](ReplicatedStorage/Catalog/Palette.lua) | `Catalog` → `Palette` | ModuleScript | 25 colors |
| [ReplicatedStorage/Catalog/Contracts.lua](ReplicatedStorage/Catalog/Contracts.lua) | `Catalog` → `Contracts` | ModuleScript | 24 contracts |
| `ServerStorage/Armor/<12 sets>/Config.lua` | `ServerStorage` → `Armor` → `<Set>` | ModuleScript in a Model | one scaffold Model per release pack |

## Studio

Rojo creates 12 empty set Models under `ServerStorage ▸ Armor` (each with its Config). Build the
clothing Models inside them. Everything else to make is in [RELEASE_CONTENT.md](RELEASE_CONTENT.md).
Cross-server invites need a published game (MessagingService + teleports do nothing in Studio).
