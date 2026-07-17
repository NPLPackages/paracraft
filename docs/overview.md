# Repository Overview

## What is this repo?

**paraworld** is the script and mod source tree for products built on **ParaEngine** — a 3D game engine with an embedded **NPL (Neural Parallel Language)** runtime. The two flagship products sharing this codebase are:

1. **Paracraft** — A voxel-based 3D world creation tool with visual programming (Blockly), multiplayer, and education features. Official site: [www.paracraft.cn](https://www.paracraft.cn/).
2. **魔法哈奇 (Haqi / Magic Haqi)** — A kids/teens MMO game client implemented under `script/apps/Aries/`, coexisting with Paracraft in the same application folder.

The codebase is large (~1M+ lines of Lua across the full product including external asset packages). This repo holds **scripts, mods, package manifests, and docgen configs** — not the full art/asset tree referenced at runtime.

## Top-level layout

```
paraworld/
├── script/          # All Lua/NPL application code
│   ├── ide/         # Core framework (commonlib, System, MCML, Blockly)
│   ├── kids/        # ParaWorld / 3D Map System platform
│   ├── apps/        # Client & server applications (Aries, GameServer, …)
│   ├── network/     # Shared network helpers
│   ├── mobile/      # Mobile/Paracraft protobuf layer
│   ├── installer/   # Build & NSI installer scripts
│   └── …
├── Mod/             # Runtime-loadable NPL mods (WorldShare, GGS, ExplorerApp)
├── packages/        # Package redist manifest lists (*.txt) for zip builds
├── Documentation/   # API docgen XML configs
├── test/            # Small root-level unit tests
├── npl_mod/         # Sample NPL package layout
└── docs/            # This wiki
```

## Technology stack

| Layer | Technology | Location |
|-------|------------|----------|
| Engine | ParaEngine (C++), DirectX/OpenGL | External SDK (not in this repo) |
| Script runtime | NPL + Lua | All `script/` |
| Module system | `NPL.load`, `commonlib.gettable` | `script/ide/commonlib.lua` |
| UI | MCML v1/v2 (XML/HTML-like markup) | `script/ide/System/Windows/mcml/` |
| Visual programming | Blockly + custom code blocks | `script/ide/System/UI/Blockly/`, `Creator/Game/Code/` |
| Voxel world | BlockEngine | `Creator/Game/block_engine.lua` |
| Multiplayer | GGS, TunnelService, JGSL, REST | `Mod/GeneralGameServerMod/`, `GameServer/` |
| Cloud / accounts | Keepwork, WorldShare | `Mod/WorldShare/` |

## How products map to code

```
                    ┌─────────────────────────────────────┐
                    │         ParaEngine executable        │
                    │  (ParaCraft.exe / paraworld.exe)     │
                    └─────────────────┬───────────────────┘
                                      │
              bootstrapper.xml ───────┤
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         ▼                            ▼                            ▼
  Aries/main_loop.lua      Creator/Game/main.lua          GameServer/GSL_system.lua
  (Haqi MMO + Paracraft      (Paracraft-only / headless      (Virtual world server)
   full client)               server mode)
         │                            │
         └────────────┬───────────────┘
                      ▼
            script/kids/ParaWorldCore.lua
            script/ide/System/System.lua
            commonlib.package.Startup()
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
    BlockEngine  EntityManager  GameLogic
    (voxels)     (actors)       (game loop)
```

## Entry points (most common)

| Product / mode | Bootstrapper | Main loop |
|----------------|--------------|-----------|
| Haqi + Paracraft client | `script/apps/Aries/bootstrapper.xml` | `script/apps/Aries/main_loop.lua` |
| Paracraft Creator only | `script/apps/Aries/Creator/Game/main.lua` | Same file (also headless server) |
| ParaWorld platform demo | `config/bootstrapper.xml` | `script/kids/3DMapSystem_main.lua` |
| HelloChat tutorial | `script/apps/HelloChat/bootstrapper.xml` | `script/apps/HelloChat/main_loop.lua` |
| Game server | `script/apps/GameServer/test/test_bootstrapper_gameserver.xml` | `script/apps/GameServer/GSL_system.lua` |

## Command-line parameters (shared patterns)

Many apps accept ParaEngine command-line key/value pairs:

| Parameter | Example | Purpose |
|-----------|---------|---------|
| `bootstrapper` | `"script/apps/Aries/bootstrapper.xml"` | Which app to launch |
| `mc` | `"true"` | Paracraft Creator mode (vs pure Haqi) |
| `world` | `"worlds/DesignHouse/test"` | World path to load |
| `servermode` | `"true"` | Headless server (no graphics) |
| `username`, `password`, `gateway` | auth | Login / gateway selection |
| `version` | `"kids"` / `"tean"` | Haqi kids vs teen UI |
| `keepworktoken` | token string | Keepwork SSO |
| `isDevMode`, `isDevEnv` | `"true"` | Developer flags |

See `script/apps/Aries/main_loop.lua` header for the full Aries parameter list.

## Namespace convention

Modules register under dotted namespaces, typically:

```
MyCompany.Aries.Game.BlockEngine
MyCompany.Aries.HaqiShop
Map3DSystem.UI.Desktop
System.App.AppManager
```

Retrieve with:

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
```

The `(gl)` prefix means the global main runtime state.

## Related documentation in-repo

| File | Purpose |
|------|---------|
| `.github/instructions/paracraft.instructions.md` | AI/copilot coding guide |
| `script/.github/instructions/mcml.instructions.md` | MCML-specific instructions |
| `Documentation/paracraft.docgen.xml` | Paracraft API doc generation |
| Per-folder `readme.txt` / `readme.md` | Original TWiki-style docs |

## See also

- [Main Package](main-package.md)
- [Paracraft](paracraft.md)
- [Haqi / Aries](haqi-aries.md)
- [Scan Log](SCAN_LOG.md)
