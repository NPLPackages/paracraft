# Creator Network (Paracraft Multiplayer)

TCP-based Minecraft-style multiplayer for Paracraft worlds. Lives in `script/apps/Aries/Creator/Game/Network/` (~117 files).

Namespace: `MyCompany.Aries.Game.Network.*`, `MyCompany.Aries.Game.Network.Packets.*`

Design: acts as a **transparent plugin** inside Creator — enable/disable at runtime via `NetworkMain`.

## Architecture

```
NetworkMain.lua
    ├── WorldServer.lua / WorldClient.lua
    ├── ServerManager.lua / ServerManagerDedicated.lua
    ├── NetHandler.lua, NetClientHandler.lua, NetServerHandler.lua
    ├── ConnectionTCP.lua
    ├── ChunkObserver.lua, EntityTracker.lua
    ├── PlayerManager.lua / PlayerManagerClient.lua
    └── Packets/* (53 packet types)
            └── TunnelService/ (NAT relay)
            └── LobbyService/ (P2P lobby)
            └── Admin/ (classroom)
            └── Config/ (auth lists)
```

## Core files

| File | Role |
|------|------|
| `NetworkMain.lua` | Entry; enable/disable network plugin |
| `WorldServer.lua` | Authoritative world simulation |
| `WorldClient.lua` | Client-side world sync |
| `ConnectionTCP.lua` | TCP connection base |
| `ChunkObserver.lua` | Chunk load/unload replication |
| `EntityTracker.lua` | Entity visibility tracking |
| `NetHandler.lua` | Packet dispatch |
| `NPLWebServer.lua` | Embedded web server for network admin |
| `readme.txt` | Module overview |

## Packet protocol

Registry: `Packets/Packet_Types.lua` — **53 packets**, IDs 1–53.

| ID | Packet | Category |
|----|--------|----------|
| 1 | PacketPing | Keepalive |
| 2 | PacketLogin | Auth |
| 3 | PacketKickDisconnect | Auth |
| 4–5 | PacketEntityPlayerSpawn, PacketEntityMobSpawn | Entity spawn |
| 6 | PacketPlayerInfo | Player |
| 7 | PacketAnimation | Entity |
| 8 | PacketSpawnPosition | Player |
| 9 | PacketPlayerLookMove | Player movement |
| 10 | PacketUpdateTime | World time |
| 11 | PacketCustomPayload | Extensibility |
| 12 | PacketChat | Chat |
| 13 | PacketMove | Movement |
| 14 | PacketLevelSound | Sound |
| 15 | PacketBlockDestroy | Blocks |
| 16–18 | PacketMapChunk, PacketMapChunks, PacketMapChunkData | Chunk streaming |
| 19–23 | RelEntityLook/Move/Teleport, EntityVelocity | Entity sync |
| 24 | PacketSleep | Player state |
| 25 | PacketPlayerInventory | Inventory |
| 26 | PacketAttachEntity | Attachment |
| 27–29 | HeadRotation, EntityEffect, DestroyEntity | Entity |
| 30 | PacketLoginClient | Client login |
| 31–32 | PacketPlayerLook, PacketPlayerPosition | Player |
| 33–35 | EntityAction, RelEntity, EntityMetadata | Entity |
| 36 | PacketUpdateAttributes | Attributes |
| 37–39 | BlockChange, BlockMultiChange, BlockPieces | **Voxel sync** |
| 40–41 | ClickEntity, ClickBlock | Interaction |
| 42 | PacketAuthUser | Auth |
| 43 | PacketUpdateEntitySign | Signs |
| 44 | PacketClientCommand | Commands |
| 45–48 | MovableSpawn, UpdateEnv, EntityFunction, EntityMove | Entity/world |
| 49 | PacketUpdateEntityBlock | Entity blocks |
| 50–51 | PacketGetFile, PacketPutFile | File transfer |
| 52 | PacketMultiple | Batch |
| 53 | PacketCodeBlockEvent | **Code block sync** |

Adding a packet: create class in `Packets/`, register in `Packet_Types:StaticInit()`.

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
```

## TunnelService (NAT traversal)

When clients cannot connect via direct TCP (NAT/firewall), use tunnel relay.

Source: `TunnelService/readme_tunnelservice.md` (LiXizhi, 2016)

### Commands

| Command | Action |
|---------|--------|
| `/tunnelserver` | Start tunnel server |
| `/startserver -tunnel room_test` | Start game server in tunnel room |
| `/connect -tunnel room_test` | Connect client through tunnel |

### Module flow

```
gateway:login
    → lobbyserver (rooms: {room_key, {nid,...}}, tunnelserver list)
        → tunnelserver (relay by room_key + virtual_nid)
            → tunnelclient (connect, sendMessage)
                → TCPConnectionBase + SetTunnelProxy filters
```

Key concepts:

- **room_key** — session key (like session_key)
- **virtual_nid** — `{room_key}_{nid}`, unique tunnel client ID

Key files:

| File | Role |
|------|------|
| `TunnelServer.lua`, `TunnelServer_main.lua` | Relay server |
| `TunnelClient.lua` | Client proxy |
| `LobbyTunnelServer.lua`, `LobbyTunnelServer_main.lua` | Lobby + tunnel |
| `RoomInfo.lua`, `LobbyRoomInfo.lua`, `LobbyRoomGroup.lua` | Room state |
| `LobbyTunnelMessageType.lua` | Message types |
| `Website/roomList.lua` | Web room list |

## LobbyService

P2P lobby for room discovery:

- `LobbyService/LobbyUserInfo.lua`
- `LobbyService/LobbyMessageType.lua`

## Admin / classroom

`Admin/ClassManager/` — teacher/student room management:

- `TeacherPanel.lua`, `TeacherPanel.html`
- `ClassListPage.html`, `StudentPanel.*`
- `ShareUrlPage.lua`, `ShareUrlContext.*`
- `TChatRoomPage.html`, `SChatRoomPage.html`

## Server config

`Config/` — Lua list files (not JSON):

| File | Purpose |
|------|---------|
| `ServerConfig.lua` | Server settings |
| `AuthUserList.lua` | Allowed users |
| `BanList.lua` | Banned users |
| `PasswordList.lua` | Room passwords |

## Headless server

Same network stack as graphical Creator:

```
servermode="true" world="worlds/DesignHouse/test" ip="0.0.0.0" port="6001"
autosave="10" mc="true" bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```

## See also

- [Networking Stacks Overview](../networking-stacks.md)
- [Game Server and Networking](../game-server-and-networking.md)
- [Code Blocks](../code-blocks-and-visual-programming.md) — PacketCodeBlockEvent (53)
- [Creator Game Engine](creator-game-engine.md)
