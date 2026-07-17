# Game Server and Networking

This repo contains multiple networking stacks spanning decades of development. Modern Paracraft multiplayer primarily uses **GGS** (`Mod/GeneralGameServerMod/`) and **Creator/Game/Network/**; legacy Haqi uses **GameServer GSL** and **JGSL**.

## Architecture overview

```
                    ┌──────────────┐
                    │   Client     │
                    │ Aries/main   │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   REST auth          World sync        Real-time
   (rest.lua)         (GSL/JGSL)        (TunnelService)
         │                 │                 │
         ▼                 ▼                 ▼
   GameServer/       GameServer/       Creator/Game/
   rest.lua          GSL_*.lua         Network/
         │                 │
         ▼                 ▼
   NPLRouter  ──────►  DBServer
```

## GameServer (GSL) — `script/apps/GameServer/`

Standalone **virtual world server** (~81 files). Each runtime state hosts world instances with quad-tree spatial indexing.

Source: `script/apps/GameServer/readme.txt` (LiXizhi, 2009)

### Key concepts

| Term | Meaning |
|------|---------|
| **World server** | One runtime state serving world requests |
| **World instance** | A loaded world path inside a server |
| **REST state** | Special state `"rest"` for auth + REST queries |
| **World ID** | Runtime state name identifying a world |

Unlike JGSL, GSL is **standalone** — one server handles all worlds on that process.

### Client boot sequence

1. `GetServerList` — get assigned game server
2. Login: `(rest):rest.lua` → `{url="login", req={username, password}}`
3. World list: `{url="worldlist", r={page=1}}`
4. Connect to world server instance

### Key files

| File | Role |
|------|------|
| `GSL_system.lua` | Server system init |
| `GSL.lua` | Client-side GSL helper |
| `GSL_clientproxy.lua` / `GSL_serverproxy.lua` | Proxies |
| `GSL_homegrid.lua` | Home grid management |
| `rest.lua` | REST endpoint handler |
| `LobbyService/` | Matchmaking lobby |
| `BattlefieldService/` | Battle instances |
| `TradeService/` | Trading |
| `BlockServer/` | Block sync |
| `LogService/` | Logging service |

### Message flow (client → DB)

```
Client → GameServer:rest.lua
       → NPLRouter.dll → DBServer
       → C# url_handler (worker threads)
       → back through NPLRouter → Client
```

### Local debug setup

**Server:**

```lua
NPL.StartNetServer("127.0.0.1", "60002");
NPL.LoadPublicFilesFromXML();
local worker = NPL.CreateRuntimeState("world1", 0);
worker:Start();
NPL.activate("(world1)script/apps/GameServer/GSL_system.lua",
    {type="restart", config={nid="localhost", ws_id="world1"}});
```

Or bootstrapper: `"script/apps/GameServer/test/test_bootstrapper_gameserver.xml"`

**Client:** Load world then activate local GSL (see readme for `test_using_local_game_server` pattern).

## DBServer — `script/apps/DBServer/`

Database router. GameServer REST requests route through **NPLRouter** to DBServer worker states executing C# DAL handlers.

```
script/apps/DBServer/DAL/MySqlServerObjectProvider.lua
script/apps/DBServer/TableDAL/
```

## NPLRouter — `script/apps/NPLRouter/`

Message router DLL bridge between runtime states:

```
script/apps/NPLRouter/table_nid_config.xml
script/apps/NPLRouter/server_info_config.xml
```

Excluded from standard client `main_script` package (server-side infra).

## JGSL — `script/kids/3DMapSystemNetwork/`

**Distributed** game server mesh (legacy ParaWorld). Multiple virtual servers cooperate.

| File | Role |
|------|------|
| `JGSL_config.lua` | Config |
| `JGSL_clientproxy.lua` | Client proxy |
| `JGSL_serverproxy.lua` | Server proxy |
| `JGSL_grid.lua` | Spatial grid |
| `JGSL_servermode_loop.lua` | Server loop |

Activated via `servermode` / `questservermode` command-line flags (partially commented in ParaWorldCore).

## Paracraft Creator Network — `Creator/Game/Network/`

Modern multiplayer for Paracraft. Acts as a **transparent plugin** inside Creator.

```
Creator/Game/Network/
├── Packets/              # BlockMultiChange, PlayerInventory, …
├── LobbyService/         # Lobby user info
├── TunnelService/        # Tunnel-based connectivity
├── Admin/                # Teacher panel
└── readme.txt
```

Headless Paracraft server uses same network stack:

```
servermode="true" world="..." ip="0.0.0.0" port="6001" mc="true"
bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```

See `Creator/Game/Network/TunnelService/readme_tunnelservice.md`.

## General Game Server Mod (GGS)

`Mod/GeneralGameServerMod/` — Primary modern multiplayer mod. See [Mods](mods.md).

Core server: `Core/Server/GeneralGameServer.lua`, `World.lua`, `QuadTree.lua`

Client: `Core/Client/BlockManager.lua`, `EntityOtherPlayer.lua`

## IMServer — `script/apps/IMServer/`

Instant messaging. Haqi replaces default Jabber with game-server IM:

```lua
NPL.load("(gl)script/apps/IMServer/IMserver_client.lua");
JabberClientManager = commonlib.gettable("IMServer.JabberClientManager");
```

## WebServer — `script/apps/GameServer/` sibling

`script/apps/WebServer/` — NPL HTTP server with admin CMS/wiki (includes packages wiki UI under `admin/wp-content/pages/wiki/mod/packages/`).

## Shared network helpers — `script/network/`

| File | Purpose |
|------|---------|
| `gameserver_mainUI.lua` | Game server UI |
| `myWorldWnd.lua` | Personal world browser |
| `PersonalWorldExplorerWnd.lua` | World explorer |
| `KM_WorldUploader.lua` | World upload |
| `markInfo.lua` | Map marks |

## PayServer — `script/apps/PayServer/`

Payment processing (`web/HttpPayHandle.lua`). Separate deploy.

## See also

- [Mods](mods.md) — WorldShare cloud sync
- [Paracraft](paracraft.md) — Creator server mode
- [ParaWorld Platform](paraworld-platform.md) — JGSL
- [Applications Catalog](applications-catalog.md)
