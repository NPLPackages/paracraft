# Applications Catalog

All first-class applications under `script/apps/`. Each app typically has:

- `main_loop.lua` or app entry — bootstrap
- `bootstrapper.xml` — engine bootstrap config
- `IP.xml` — app registration manifest
- `readme.txt` — TWiki-style documentation

## Summary table

| App | Type | Status in main_script | Description |
|-----|------|----------------------|-------------|
| **[Aries](haqi-aries.md)** | Client | ✅ Included | Haqi MMO + Paracraft Creator |
| [Aquarius](haqi-aries.md) | Client | ❌ Excluded | Alternate Pala5-era client |
| [GameServer](game-server-and-networking.md) | Server | ✅ Partial | GSL virtual world server |
| [DBServer](game-server-and-networking.md) | Server | ❌ Excluded | Database router |
| [NPLRouter](game-server-and-networking.md) | Server | ❌ Excluded | Inter-state message router |
| [WebServer](game-server-and-networking.md) | Server | ❌ Excluded | NPL HTTP server + admin wiki — [apps/webserver.md](apps/webserver.md) |
| [IMServer](game-server-and-networking.md) | Server | ❌ Excluded | IM broker (client stub used by Haqi) |
| [PayServer](#payserver) | Server | ❌ Excluded | Payment processing |
| [HelloChat](#hellochat) | Demo | ❌ Excluded | 3D chat tutorial (KongFuChat) |
| [HelloWorld](#helloworld) | Demo | ❌ Excluded | Minimal app template |
| [Taurus](#taurus) | Client | ❌ Excluded | CAD/engineering client variant |
| [orion](#orion) | Client | ❌ Excluded | Kids World client |
| [Poke](#poke) | Client | ❌ Excluded | Experimental |
| [sample](#sample) | Demo | ❌ Excluded | Sample code |

---

## Aries

**Primary product.** See [Haqi / Aries](haqi-aries.md) and [Paracraft](paracraft.md).

```
Entry: script/apps/Aries/main_loop.lua
Bootstrapper: script/apps/Aries/bootstrapper.xml
~2000+ files, 53 feature modules
```

---

## Aquarius

Alternate client application (Pala5 era). **Full doc:** [apps/aquarius.md](apps/aquarius.md)

```
script/apps/Aquarius/main_loop.lua
script/apps/Aquarius/bootstrapper.xml
script/apps/Aquarius/readme.txt
```

Features: Login, Quest, Inventory, Profile, Desktop — similar module layout to Aries but separate product.

---

## GameServer

Virtual world server. See [Game Server and Networking](game-server-and-networking.md).

```
script/apps/GameServer/GSL_system.lua
script/apps/GameServer/readme.txt
~81 files
```

Services: Lobby, Battlefield, Trade, Block, Log

---

## DBServer

Database access layer for GameServer.

```
script/apps/DBServer/readme.txt
script/apps/DBServer/DAL/
script/apps/DBServer/TableDAL/
```

---

## NPLRouter

Routes messages between NPL runtime states and native DLLs.

```
script/apps/NPLRouter/readme.txt
script/apps/NPLRouter/table_nid_config.xml
```

---

## WebServer

Embedded HTTP server with CMS admin panel.

```
script/apps/WebServer/readme.txt
script/apps/WebServer/npl_script_handler.lua
script/apps/WebServer/admin/          # Large wp-content wiki CMS
```

Admin wiki includes packages management UI (`admin/wp-content/pages/wiki/mod/packages/`).

Links Paracraft official site in readme.

---

## IMServer

Instant messaging server. Haqi client loads `IMserver_client.lua` to replace Jabber.

```
script/apps/IMServer/IMServer.lua
script/apps/IMServer/readme.txt
```

---

## PayServer

Payment web handler.

```
script/apps/PayServer/web/HttpPayHandle.lua
```

---

## HelloChat

**Recommended tutorial** for building MMORPG-style apps on ParaWorld.

```
script/apps/HelloChat/main_loop.lua
script/apps/HelloChat/bootstrapper.xml
script/apps/HelloChat/readme.txt
```

Demonstrates: chat, character customization, animations, social features.

External URL scheme: `paraworldviewer://worlds/MyWorlds/KongFuChat;movie=...`

---

## HelloWorld

Minimal standalone app template created via DeveloperApp.

```
script/apps/HelloWorld/main_loop.lua
script/apps/HelloWorld/IP.xml
script/apps/HelloWorld/readme.txt
```

---

## Taurus

Engineering/CAD-oriented client variant.

```
script/apps/Taurus/main_loop.lua
Art package: packages/redist/art_model_char_Taurus-1.0.txt
Installer: script/installer/config_taurus_release_zhCN.txt
```

GameServer readme references `File.EnterTaurusWorld` for local server testing.

---

## Orion

"Kids World" client.

```
script/apps/orion/main_loop.lua  (case: orion/)
script/apps/orion/readme.txt
```

Same ParaWorldCore bootstrap pattern as HelloChat.

---

## Poke

Experimental client (excluded from all main packages).

---

## sample

Sample/template code for developers.

```
script/apps/sample/IP.xml
```

---

## Creating a new app

1. Use DeveloperApp **New Package** dialog, or
2. Copy HelloWorld template (`IP.xml` + `main_loop.lua`), or
3. Use `script/ide/ProjectTemplates/Templates/InstallApps/`

Register programmatically:

```lua
local app = System.App.Registration.InstallApp(
    {app_key="MyApp_GUID"},
    "script/apps/MyApp/IP.xml",
    true
);
```

---

## See also

- [Overview](overview.md)
- [ParaWorld Platform](paraworld-platform.md)
- [Main Package](main-package.md) — which apps ship in production
