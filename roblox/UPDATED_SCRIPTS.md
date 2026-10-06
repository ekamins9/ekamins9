# Updated scripts: the admin panel

- **Staff roles:** Owner (you, the game's creator, always; everything), Admin, Moderator, Helper.
  Each has a rank and a list of permissions in `Admin ▸ Roles` (edit it to change them). A role
  acts only on players and staff below it and gives only roles below it.
- **F2 (or the ADMIN · F2 button, top right) opens the panel** for staff:
  - **PLAYERS:** everyone here, or look anyone up by name or id: kick, ban (hours, or for good),
    unban, go to, bring, freeze, heal, kill, give / take Marks and Crowns, set level, give / take
    any item, unlock everything, wipe saved data.
  - **SERVER:** end the round now, the next mode and map, announcements (this server or every
    server), spawn / clear bots, shut down.
  - **STAFF** (give and take roles), **BANS** (unban), **LOG** (every staff action).
- Everything is decided on the server, which re-checks your role, the permission and your rank
  on every request. Changes to a player in another server, or offline, reach them there or when
  they next join. Bans kick across servers and are checked as players join. Announcements show
  as a banner for everyone.
- **In Studio,** "Enable Studio Access to API Services" is off right now, so roles, bans and the
  log save for that test server only (the panel says so). Live servers save them.

| File | Studio location | Type | Change |
|---|---|---|---|
| [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService ▸ Admin ▸ AdminServer | Script | **new**: roles, permissions, every action, bans, the queue, the log |
| [Roles.lua](ServerScriptService/Admin/Roles.lua) | ServerScriptService ▸ Admin ▸ Roles | ModuleScript | **new**: the roles and what each may do |
| [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ AdminPanel | LocalScript | **new**: the panel and the announcement banner |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `Profile.reset` |
| [Game.lua](ServerScriptService/Game/Game.lua), [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game | ModuleScript / Script | staff can end the round and pick the next map |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | the admin panel; staff roles |
