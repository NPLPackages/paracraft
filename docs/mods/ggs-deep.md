# GGS Deep Dive (`GeneralGameServerMod`)

Extended reference for `Mod/GeneralGameServerMod/` (~400+ files). Overview: [mods.md](mods.md).

## Directory map

```
GeneralGameServerMod/
├── config.xml
├── Core/
│   ├── Server/     GeneralGameServer.lua, World.lua, QuadTree.lua, Track.lua
│   ├── Client/     BlockManager.lua, EntityOtherPlayer.lua
│   └── Common/     Packets.lua
├── CommonLib/      RPC, Connection, Broadcast, VirtualConnection, EventEmitter
├── App/            Sample GGS applications
│   ├── Client/     Client-side app samples
│   ├── Server/     Server-side handlers
│   ├── View/       View layer
│   └── ui/         HTML/Vue UI samples
├── Server/         HTTP server, MySQL (Expr.lua)
├── FileSync/       NetServerHandler, FileSyncBackUp
├── Command/        PluginManager, Lan/LockScreen, ProxyServer/FileCache
├── GI/             Game Inventor (see gi-sample-apps.md)
├── Tutorial/       Setup tutorial (upgrade.sh workflow)
└── Test/           test.lua
```

## Core server (`Core/Server/`)

| Class | Role |
|-------|------|
| `GeneralGameServer.lua` | Main GGS server singleton |
| `World.lua` | World state on server |
| `QuadTree.lua` | Spatial indexing (like GameServer GSL) |
| `Track.lua` | Player/entity tracking |

## Core client (`Core/Client/`)

| Class | Role |
|-------|------|
| `BlockManager.lua` | Client block sync with server |
| `EntityOtherPlayer.lua` | Other player entity rendering |

## CommonLib

| Module | Role |
|--------|------|
| `RPC.lua` | Remote procedure calls |
| `Connection.lua` | Connection management |
| `Broadcast.lua` | Event broadcast |
| `VirtualConnection.lua` | Virtual connection abstraction |

## App layer

Sample full-stack GGS apps demonstrating client+server+ui pattern. See [GI Readme](../Mod/GeneralGameServerMod/GI/Readme.md) for philosophy.

## FileSync

Synchronize world files between client and server:

- `NetServerHandler.lua`
- `FileSyncBackUp.lua`

## Server HTTP

`Server/Http/Readme.md` — embedded HTTP for GGS admin/API.

`Server/MySql/` — MySQL expression builder.

## Tutorial deployment

`Tutorial/readme.md`:

1. Install Paracraft to test dir
2. Copy `upgrade.sh` to `npl_packages/`
3. `bash upgrade.sh` pulls GGS mod from GitHub

## Integration with Paracraft

- Loaded via `npl_packages/paracraft/` or `upgrade.sh`
- Uses same Blockly/UI framework as Creator (`ide/System/UI/`)
- TunnelService in Creator can connect to GGS worlds

## See also

- [GI Sample Apps](gi-sample-apps.md)
- [Creator Network](../aries/creator-network.md)
- [Mods](mods.md)
