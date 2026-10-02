# Rojo setup — GitHub → your PC → Studio

Every change lands on GitHub (branch `claude/r6-unified-camera-0cpfm0`). On your PC, `git pull`
brings it down and **Rojo** pushes it into the open place in Studio, live. Your models (weapon
Tools, armor sets, maps, sounds) stay in Studio; Rojo only manages the scripts.

## One-time setup (about 10 minutes)

1. **Git + the repo.** Install Git, then in a terminal:
   ```
   git clone https://github.com/ekamins9/ekamins9.git
   cd ekamins9
   git checkout claude/r6-unified-camera-0cpfm0
   ```
2. **Rojo CLI.** Easiest with Rokit (a toolchain manager): install Rokit from
   https://github.com/rojo-rbx/rokit/releases, then in the repo folder run `rokit install`
   (reads `rokit.toml`, pins Rojo 7.7.1). Or grab the Rojo binary from
   https://github.com/rojo-rbx/rojo/releases and put it on your PATH.
3. **Rojo Studio plugin.** In the repo folder run `rojo plugin install`, or get "Rojo" from the
   Creator Store. Restart Studio; a Rojo button appears in the Plugins tab.
4. **Make Studio match the project once.** Open your place. The project maps:
   - `ReplicatedStorage`, `ServerScriptService`, `StarterPlayer ▸ StarterPlayerScripts`,
     `StarterPlayer ▸ StarterCharacterScripts` → every script there is Rojo's.
   - `ServerStorage ▸ Armor ▸ <Set> ▸ Config` and `ServerStorage ▸ Weapons ▸ <Tool>` ▸ `Config`,
     `Server`, `Client` → only those scripts; the parts, meshes, Handle stay yours.
   Scripts you made by hand that are **not in the repo** would be removed by the sync inside
   those four services (anything outside them is untouched). If you have such scripts, move
   them out, or tell me and I'll add them to the repo.
5. **Connect.** In the repo folder run `rojo serve`. In Studio press the Rojo button → Connect
   (localhost:34872). Rojo shows a **confirmation with a diff** before touching anything:
   read it. It should list script adds/updates. If it wants to *remove* a Handle, a
   HeadClothing, a mesh or a map, press Abort and send me a screenshot — the project file needs
   a tweak for that spot.

## Every day

```
git pull            (in the repo folder — gets my latest commits)
rojo serve          (leave it running)
```
Studio → Rojo → Connect. From then on, every `git pull` shows up in Studio within a second;
you never paste a script again. Save / publish the place from Studio as usual (the scripts are
inside the place file too, so a published game works without Rojo running).

## Notes

- **Armor sets are Models.** `roblox/ServerStorage/Armor/<Set>/init.meta.json` declares
  `"className": "Model"`, so Rojo syncs only the `Config` inside your existing set Models and
  leaves the clothing Models (HeadClothing, TorsoClothing, …) alone. A set that is a Folder in
  Studio would get a duplicate Model created next to it: make new sets Models.
- **Plugin version must match the CLI.** Studio's Creator Store Rojo plugin auto-updates; if
  Connect fails with an odd error (e.g. `attempt to index number with 'protocolVersion'`), the
  pinned CLI in `rokit.toml` is older than the plugin — bump the pin and `rokit install`.
- New armor set in Studio → make `roblox/ServerStorage/Armor/<Set>/Config.lua` and
  `init.meta.json` in the repo too (or just tell me the set name), so its Config syncs.
- `*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` = ModuleScript. A ModuleScript
  with children is a folder with `init.lua` (that is why `Catalog` is `Catalog/init.lua`).
- Studio changes do **not** flow back to the repo (one-way). Edit scripts on GitHub / through me,
  not in Studio, or the next pull overwrites them.
