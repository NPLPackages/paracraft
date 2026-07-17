# Mods (`Mod/`)

Runtime-loadable **NPL mods** extending Paracraft with cloud services, multiplayer, and explorer UI. Three mods live in this repo (~730 files).

Mods install to `npl_packages/` beside the executable (see GGS tutorial for `upgrade.sh` workflow).

## Mod overview

| Mod | Path | Doc |
|-----|------|-----|
| **WorldShare** | `Mod/WorldShare/` | [worldshare-cellar.md](worldshare-cellar.md) |
| **GeneralGameServerMod (GGS)** | `Mod/GeneralGameServerMod/` | [mods/ggs-deep.md](mods/ggs-deep.md), [mods/gi-sample-apps.md](mods/gi-sample-apps.md) |
| **ExplorerApp** | `Mod/ExplorerApp/` | [mods/explorer-app.md](mods/explorer-app.md) |

## WorldShare

Cloud and account integration for Paracraft ecosystem.

### Structure

```
Mod/WorldShare/
├── api/                    # HTTP API clients
│   ├── Keepwork/           # KeepworkMembersApi, PermissionsApi, …
│   ├── Accounting/         # VIP codes, org billing
│   ├── Es/                 # Elasticsearch base
│   ├── Lesson/             # Education lesson APIs
│   └── Qiniu/              # CDN storage
├── service/                # Background services
│   ├── KeepworkService/    # Project, panorama, permissions
│   ├── GitService/         # GitHub integration
│   ├── SocketService.lua
│   ├── SyncService/        # World sync/compare
│   └── LocalService/       # Offline history
├── cellar/                 # UI flows ("cellar" = modal wizards)
│   ├── MainLogin/          # Login themes
│   ├── LoginModal/         # Third-party login
│   ├── RegisterModal/
│   ├── ShareWorld/         # World sharing
│   ├── Create/             # World creation
│   ├── Certificate/        # Certificates
│   ├── Panorama/
│   ├── HistoryManager/
│   ├── MemberManager/
│   ├── VipNotice/
│   └── WorldExitDialog/
├── database/               # Local DB bindings
├── store/                  # State stores
├── filters/                # Service filters
└── config/Config.lua
```

### Key integrations

- **Keepwork** — User accounts, projects, permissions, schools
- **Qiniu** — Object storage/CDN
- **Git** — Version control for worlds
- **Lesson/VipCode** — Education and VIP activation

## GeneralGameServerMod (GGS)

Multiplayer game server and **GI (Game Inventor)** low-code platform.

### Structure

```
Mod/GeneralGameServerMod/
├── Core/
│   ├── Server/             # GeneralGameServer, World, QuadTree, Track
│   ├── Client/             # BlockManager, EntityOtherPlayer
│   └── Common/             # Packets
├── CommonLib/              # RPC, Connection, Broadcast, VirtualConnection
├── App/                    # Sample GGS apps (client + server + ui)
├── Server/                 # HTTP server, MySQL
├── FileSync/               # File synchronization
├── Command/                # Lan lock screen, plugin manager, proxy
├── GI/                     # ★ Game Inventor
│   ├── Independent/        # Standalone GI lib (Entity, API, RPC)
│   ├── Game/               # ParticleSystem, Event
│   └── App/                # Sample games (sunzibingfa, lajifenlei, PVZ, AI)
├── Tutorial/               # GGS tutorials
└── Test/
```

### GI (Game Inventor / 游戏发名家)

From `Mod/GeneralGameServerMod/GI/Readme.md`:

**Goal:** Rapidly build sandbox games with interactive, intelligent worlds.

**Stack:**
- HTML, CSS, Lua basics
- Vue framework (`script/ide/System/UI/Vue/`)
- Blockly visual programming
- GI aggregated APIs (build, network, entities)

**Status (from readme TODO):**
- [x] Network API, Build API, high-frequency feature aggregation
- [ ] Template worlds, quick-start docs, package mechanism

### GGS UI

Uses GGS UI framework (`script/ide/System/UI/`) — MCML v2 + Vue + Blockly.

Sample UI: `App/ui/Example/`, `App/ui/Component/User/Follow.html`

### Deployment

Tutorial (`Mod/GeneralGameServerMod/Tutorial/readme.md`):

1. Install Paracraft to test directory
2. Copy `upgrade.sh` to `npl_packages/`
3. Run `bash upgrade.sh` to pull GGS mod

## ExplorerApp

World discovery and exploration UI (~47 files).

```
Mod/ExplorerApp/
├── components/ParacraftWorld/   # World cards, award tooltips
├── pages/                       # GameProcess, Password, Sort
├── service/KeepworkEsService/   # Elasticsearch projects
├── service/KeepworkService/
├── store/ExplorerStore.lua
└── tasks/ExplorerTask.lua
```

Integrates with Keepwork ES for project search and Paracraft world browsing.

## Loading mods at runtime

```lua
-- Paracraft package (may include mods)
NPL.load("npl_packages/paracraft/");

-- In-world mod nodes
-- Creator/Game/NplMod/NplModNode.lua
```

## RPC pattern (GGS)

```lua
-- Mod/GeneralGameServerMod/CommonLib/RPC.lua
-- Mod/GeneralGameServerMod/GI/Independent/Lib/RPC.lua
```

Used for client ↔ server communication in GI apps.

## See also

- [Paracraft](paracraft.md) — Creator integration
- [Game Server and Networking](game-server-and-networking.md)
- [IDE Framework](ide-framework.md) — GGS UI, Vue, Blockly
- [Packages and Build](packages-and-build.md) — npl_packages install
