# ParaWorld Platform (`script/kids/`)

The **ParaWorld platform** (also called **3D Map System**) is the original virtual-world framework that predates Paracraft Creator. It provides world loading, app installation, item systems, quests, and in-world UI.

Most products still bootstrap through `ParaWorldCore.lua`, which pulls in this stack.

## Entry point

```lua
NPL.load("(gl)script/kids/ParaWorldCore.lua");
```

Called from virtually every app `main_loop.lua` (Aries, HelloChat, Orion, etc.).

`ParaWorldCore.lua` loads:

1. `commonlib.lua`, `IDE.lua`, `System.lua`
2. `commonlib.package.Startup()` — zip packages
3. `3DMapSystem_Data.lua`, loadworld, WindowFrame, AnimationManager
4. Command-line user/domain processing
5. Platform helpers: `System.init()`, `System.LoadWorld()`, `System.CreateWorld()`

Legacy standalone entry: `script/kids/3DMapSystem_main.lua`

## Directory structure

```
script/kids/
├── ParaWorldCore.lua          # ★ Platform include (use this)
├── 3DMapSystem_main.lua       # Legacy main loop
├── 3DMapSystem_Data.lua       # Core data layer
├── 3DMapSystem_Misc.lua
├── kids_db.lua, db_*.lua       # Embedded databases
│
├── 3DMapSystemApp/            # Application shell & APIs
│   ├── AppManager.lua         # Install/uninstall apps
│   ├── API/                   # paraworld.* Lua APIs
│   ├── Login/                 # Platform login app
│   ├── mcml/                  # MCML page controls
│   ├── Assets/                # Asset manifest UI
│   ├── Developers/            # Dev tools
│   └── profiles/              # User profiles
│
├── 3DMapSystemUI/             # In-world UI (~largest subtree)
│   ├── Desktop/               # Platform desktop
│   ├── Map/                   # 2D/3D map browser
│   ├── CCS/                   # Character customization
│   ├── HomeLand/              # Player housing
│   ├── Creator/               # Legacy in-world creator
│   ├── Movie/                 # Movie editor panels
│   ├── InGame/                # In-game editors
│   ├── MiniGames/             # Embedded mini-games
│   └── Settings/
│
├── 3DMapSystemData/           # Data definitions, DB assets
├── 3DMapSystemItem/           # Item types (apparel, pets, skills, …)
├── 3DMapSystemQuest/          # Quest forms and quest server
├── 3DMapSystemNetwork/        # JGSL distributed server mesh
├── 3DMapSystemAnimation/        # Animation manager
│
├── BCS/                       # Body customization system
├── CCS/                       # Character customization (CCS UI data)
├── EnvironmentSet/            # Environment settings
├── RightClick/                # Right-click context menus
└── Ui/                        # Shared UI helpers
```

~1,117 files total.

## Global namespaces

| Namespace | Role |
|-----------|------|
| `Map3DSystem.*` | Core 3D map system |
| `System.*` | Unified system API (via `script/ide/System/`) |
| `paraworld.*` | Legacy global API object |

`Map3DSystem.init()` initializes the platform from `3DMapSystem_main.lua`.

## Application model

ParaWorld supports **dynamically installed applications** (packages with `IP.xml` + `app_main.lua`):

```lua
local app = System.App.AppManager.GetApp("HelloChat_GUID")
if not app then
    app = System.App.Registration.InstallApp(
        {app_key="HelloChat_GUID"},
        "script/apps/HelloChat/IP.xml",
        true
    );
end
System.UI.AppDesktop.SetDefaultApp("HelloChat_GUID", true);
```

Each app registers commands:

```lua
System.App.Commands.SetDefaultCommand("Login", "Profile.Orion.Login");
System.App.Commands.SetDefaultCommand("LoadWorld", "File.EnterHelloWorld");
```

Aries overrides these for Haqi-specific login and world entry.

## Item system (`3DMapSystemItem/`)

Item scripts define in-world object behaviors:

| Example | File pattern |
|---------|--------------|
| Apparel | `Item_Apparel.lua` |
| Combat cards | `Item_CombatCard.lua` |
| Mount pets | `Item_MountPet_Medal.lua` |
| Skills | `Item_SkillLevel.lua` |
| Pet transform | `Item_PetTransform.lua` |

Items connect Haqi gameplay to the platform inventory system.

## Quest system (`3DMapSystemQuest/`)

- Quest form editors: `forms/Quest_GoalsForm_Page.lua`, `Quest_ChainEdit_Page.lua`
- Quest server loop: `Quest_Server_Loop.lua` (activated via `questservermode`)

Haqi's `script/apps/Aries/Quest/` builds on this with game-specific UI.

## Network (`3DMapSystemNetwork/`)

**JGSL** — distributed game server mesh (contrasts with standalone GameServer GSL):

| File | Role |
|------|------|
| `JGSL_config.lua` | Configuration |
| `JGSL_clientproxy.lua` | Client-side proxy |
| `JGSL_serverproxy.lua` | Server-side proxy |
| `JGSL_grid.lua` | Spatial grid |
| `JGSL_servermode_loop.lua` | Server main loop |

Bytecode for this folder is **excluded** from standard `main_script` bin builds but source remains for reference.

## Platform APIs (`3DMapSystemApp/API/`)

Lua APIs exposed to scripters:

- `paraworld.worlds.lua` — World management
- `paraworld.auction.lua` — Auction house
- `paraworld.map.*` — Map operations

Test files under `API/test/` demonstrate usage.

## UI: MCML in kids

`3DMapSystemApp/mcml/` defines ParaWorld-specific MCML elements:

- `PageCtrl.lua` — Page controller base
- `pe_motion.lua` — Motion element
- Custom controls tested in `mcml/test/`

## Relationship to Aries/Paracraft

| Layer | kids/ | Aries/Creator/ |
|-------|-------|----------------|
| Platform bootstrap | ParaWorldCore | Uses ParaWorldCore |
| World rendering | Map3DSystem | BlockEngine (voxel) |
| UI framework | MCML v1 | MCML v1 + v2 (`mcml2/`) |
| Items/Quests | Base item/quest types | Game-specific extensions |
| Multiplayer | JGSL (legacy) | GGS + TunnelService (modern) |

Paracraft Creator largely bypasses kids UI but still depends on `System.init()` and platform services.

## See also

- [Overview](overview.md)
- [MCML UI](mcml-ui.md)
- [Game Server and Networking](game-server-and-networking.md)
- [Applications Catalog](applications-catalog.md)
