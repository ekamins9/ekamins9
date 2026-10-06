# Updated Scripts

Rewritten after every change — only what the **last** change touched. Links open the file.

**Synced with Rojo:** run `~/.local/bin/rojo.exe serve default.project.json` in the repo and press
Rojo ▸ Connect in Studio ([ROJO_SETUP.md](ROJO_SETUP.md)). Edits made during a Play session show
up on the next Play.

**Last change: security cleanup, the Peasant set, Robux bundles with art.**

1. **A counterfeit plugin was planting backdoors.** The `require(6523905017).weld()` scripts
   that kept coming back come from Creator Store plugin **6542422966**, a copy of *Studio Build
   Suite* (SBS) with an injector added: every time Studio opens a place it hides one such
   Script in a random Workspace descendant. The required asset is down right now, so they only
   threw errors, but they are a backdoor. **Uninstall it: Plugins ▸ Manage Plugins ▸ Studio
   Build Suite ▸ Uninstall** (and check other places you opened while it was installed). The
   place was cleaned in edit mode; the cleanup snippet is in
   [docs/HANDOFF.md](../docs/HANDOFF.md) §4b. All your other plugins checked clean.
2. **Peasant (free Light starter) remade** as a full set: straw hat, rope-belted tunic with a
   pouch, rolled sleeves, hose with shin wraps and turnshoes — meshes in `ServerStorage ▸ Armor ▸
   PeasantSkin`.
3. **Converter fix:** blueprint cylinders were built on the wrong axis, so kettle-hat brims and
   the Sun Knights' sun disc came out as slabs. Fixed in `blender/parts2mesh.py`; the
   Sellswords and Gambeson kettle hats, the Sun Knights tabard and the Bloodied Kettle earned
   helm were rebuilt.
4. **Quiet by default:** `DebugFlags` Logs and GuardHull are off (the translucent block hull
   was showing in normal play); CameraRig's startup prints follow Logs. Turn them on from
   `ReplicatedStorage ▸ Debug` attributes when you need them.
5. **Crown bundles are live Developer Products** — *100 / 550 / 1200 / 2600 Crowns* at
   *99 / 499 / 999 / 1999 R$*, made through Open Cloud by `scripts/dev_products.py` with art
   rendered by `blender/icons.py`. The server links them by name at start
   (`[Economy] 4 / 4 Crown bundles linked`) and now also takes each bundle's live price and
   icon from the dashboard, so changing a price there needs no code.
6. **GET CROWNS** is a screen of bundle cards (art, bonus ribbon, tier-coloured border, Robux
   price button) plus the Crowns › Marks exchange. The wallet pills show a coin and a crown
   icon (Decals in `ReplicatedStorage ▸ Cosmetics ▸ Icons`, made in Studio — no ids in code).

## Studio notes

- Enable **Game Settings ▸ Security ▸ Allow Studio access to API services** to save profiles
  in Studio; it is the only thing left in the Output on Play.
- Test hooks on `PlayerGui ▸ HubMenu`: attributes `Tab`, `ShopTab`, `OpenCrowns`.

## New files

| File | Roblox Studio location | Type | What it is |
|---|---|---|---|
| [blender/icons.py](../blender/icons.py) | — (repo tooling) | python (Blender) | renders the bundle art and the Crowns / Marks icons (Cycles + ink outline) |
| [scripts/dev_products.py](../scripts/dev_products.py) | — (repo tooling) | python | lists / creates / updates the Developer Products |

## Replaced files

| File | Roblox Studio location | Type | What changed |
|---|---|---|---|
| [ServerScriptService/Economy/EconomyServer.server.lua](ServerScriptService/Economy/EconomyServer.server.lua) | `ServerScriptService` → `Economy` → `EconomyServer` | Script | keeps each bundle's live price and icon |
| [ServerScriptService/Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | `ServerScriptService` → `Hub` → `HubServer` | Script | `"Products"` op for the bundle cards |
| [ServerScriptService/Sanitize.server.lua](ServerScriptService/Sanitize.server.lua) | `ServerScriptService` → `Sanitize` | Script | documents the plugin; disables a caught script before deleting it |
| [ServerScriptService/Build/Armor.lua](ServerScriptService/Build/Armor.lua) · [Builder.lua](ServerScriptService/Build/Builder.lua) | `ServerScriptService` → `Build` | ModuleScript | the Peasant set; `STRAW` colour |
| [ServerStorage/Armor/PeasantSkin/Config.lua](ServerStorage/Armor/PeasantSkin/Config.lua) | `ServerStorage` → `Armor` → `PeasantSkin` → `Config` | ModuleScript | names, covers hair |
| [ReplicatedStorage/DebugFlags.lua](ReplicatedStorage/DebugFlags.lua) | `ReplicatedStorage` → `DebugFlags` | ModuleScript | quiet defaults |
| [StarterCharacterScripts/CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | `StarterPlayer` → `StarterCharacterScripts` → `CameraRig` | LocalScript | startup prints behind Logs |
| [StarterPlayerScripts/HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | `StarterPlayer` → `StarterPlayerScripts` → `HubMenu` | LocalScript | GET CROWNS cards, wallet icons, modal width, `OpenCrowns` hook |
