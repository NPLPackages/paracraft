# Backend Server Applications

Server-side apps excluded from client `main_script` but documented for full-stack understanding.

## DBServer (`script/apps/DBServer/`)

Database router — game server REST requests route through NPLRouter to DB worker threads.

```
DBServer/
├── readme.txt
├── DAL/
│   └── MySqlServerObjectProvider.lua
└── TableDAL/
    └── readme.txt
```

**Flow:** Client → GameServer:rest → NPLRouter → DBServer → C# `url_handler.cs` (worker threads) → response

See [Game Server and Networking](../game-server-and-networking.md).

## NPLRouter (`script/apps/NPLRouter/`)

Inter-runtime-state message router (native DLL bridge).

| File | Role |
|------|------|
| `readme.txt` | Router overview |
| `table_nid_config.xml` | NID routing table |
| `server_info_config.xml` | Server registry |

## IMServer (`script/apps/IMServer/`)

Instant messaging broker.

| File | Role |
|------|------|
| `IMServer.lua` | Server |
| `IMserver_client.lua` | **Client stub** loaded by Haqi `main_loop.lua` |
| `readme.txt` | Overview |

Haqi replaces Jabber with game-server IM when `imserver="game"`.

## PayServer (`script/apps/PayServer/`)

Payment processing.

```
PayServer/web/HttpPayHandle.lua
```

Separate deployment; not in client package.

## GameServer services (included partially)

Full detail: [game-server-and-networking.md](../game-server-and-networking.md)

| Service | Path |
|---------|------|
| Lobby | `GameServer/LobbyService/` |
| Battlefield | `GameServer/BattlefieldService/` |
| Trade | `GameServer/TradeService/` |
| Block | `GameServer/BlockServer/` |
| Log | `GameServer/LogService/` |

## See also

- [Applications Catalog](applications-catalog.md)
- [Networking Stacks](../networking-stacks.md)
