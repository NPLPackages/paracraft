# Legacy Client Networking

Pre-Aries client networking in `script/network/` (~37 files) plus minimal servers in `script/server/`.

Part of the original **Kids Movie Online** / ParaWorld world-sharing stack. Largely superseded by Aries Creator Network and WorldShare, but code remains for world browser and legacy flows.

See [Networking Stacks Overview](networking-stacks.md).

## Bootstrap

```lua
-- script/network/ClientServerIncludes.lua
-- Loads chat, creation, init client+server modules
```

## Message registry

`KMNetMsg.lua` — defines network message types for kids online world sharing.

## World sync

| File | Role |
|------|------|
| `KM_WorldDownloader.lua` | Download worlds |
| `KM_WorldUploader.lua` | Upload worlds |
| `KM_HostAndJoinWorld.lua` | Host/join sessions |

## Game server (embedded)

| File | Role |
|------|------|
| `gameserver_mainloop.lua` | Server loop |
| `gameserver_mainUI.lua` | Server UI |
| `gameserver_loadworld.lua` | Load world on server |
| `gameserver_hostworld.lua` | Host world |

## World/map browser

| File | Role |
|------|------|
| `explorer.lua`, `explorerWnd.lua` | World explorer |
| `MapExplorerWnd.lua` | Map explorer window |
| `PersonalWorldExplorerWnd.lua` | Personal worlds |
| `mapBrowser.lua` | Map browser core |
| `mapBrowserMediator.lua` | Mediator pattern |
| `mapBrowserMidBar.lua`, `mapBrowserSideBar.lua` | Browser chrome |
| `myWorldWnd.lua` | My worlds window |
| `mapSearchWnd.lua` | Search |

## 3D map views

| File | Role |
|------|------|
| `map3D.lua`, `map3DManager.lua` | 3D map manager |
| `map3D_2D.lua`, `map3D_3D.lua` | 2D/3D views |
| `Map3DCanvas.lua` | Canvas rendering |
| `map3d_mapSet.lua`, `mapSet.lua` | Map sets |
| `mapMarkWnd.lua`, `mapMark_db.lua` | Map marks (uses SQLite) |
| `markInfo.lua`, `markProvider.lua` | Mark data |

## Instant messaging

| File | Role |
|------|------|
| `IM_Main.lua` | IM main |
| `IM_ChatWnd.lua` | Chat window |
| `IM_TreeView.lua` | Contact tree |

## Login / upload UI

| File | Role |
|------|------|
| `LoginWnd.lua`, `LoginBox.lua` | Login dialogs |
| `NetworkPannel.lua` | Network settings panel |
| `UploadArtwork.lua` | Artwork upload |

## Minimal servers (`script/server/`)

| File | Role |
|------|------|
| `init_server.lua` | Server bootstrap, version, pure-server mode, statistics |
| `chat_server.lua` | Chat relay |
| `creation_server.lua` | Creation/object sync |

Pairs with `script/client/` (via `ClientServerIncludes.lua`) for minimal multiplayer demos.

## See also

- [Networking Stacks Overview](networking-stacks.md)
- [ParaWorld Platform](paraworld-platform.md)
- [SQLite](supporting-modules.md#sqlite)
- [Applications Catalog](applications-catalog.md)
