# Paracraft

**Paracraft** is a voxel-based 3D creation platform for building worlds, animations, games, and educational content. It runs on ParaEngine/NPL and shares the `script/apps/Aries/` tree with the Haqi MMO client.

- Official site: [www.paracraft.cn](https://www.paracraft.cn/)
- Core engine code: `script/apps/Aries/Creator/`
- Game simulation: `script/apps/Aries/Creator/Game/`
- Package manifest: `packages/redist/main_script_paracraft-1.0.txt`

## Paracraft vs Haqi in one executable

The same **Aries** application hosts both products. Mode is selected at launch:

| Mode | How activated | UI / behavior |
|------|---------------|---------------|
| **Paracraft Creator** | `mc="true"` on command line | Creator toolbar, block editing, code blocks, world save |
| **Haqi MMO** | Default Aries launch without `mc` | Login, combat, quests, social desktop |

`System.options.mc` is set in `main_loop.lua` from the `mc` parameter.

Paracraft-only entry (including headless server):

```
bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```

Headless dedicated server example:

```
servermode="true" world="worlds/DesignHouse/test" ip="0.0.0.0" port="6001"
autosave="10" mc="true" bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```

## Three-layer game architecture

Paracraft's simulation stack (documented in `.github/instructions/paracraft.instructions.md`):

```
┌─────────────────────────────────────────┐
│  GameLogic (singleton game loop)         │  game_logic.lua
├─────────────────────────────────────────┤
│  EntityManager (players, NPCs, physics)│  Entity/EntityManager.lua
├─────────────────────────────────────────┤
│  BlockEngine (voxel grid)              │  block_engine.lua
└─────────────────────────────────────────┘
```

### BlockEngine (voxel layer)

- Block coords: `BlockEngine:block(x,y,z)`
- World coords: `BlockEngine:real(x,y,z)`
- Access: `GetBlock`, `SetBlock`, block type registry in `blocks/`

### EntityManager (actor layer)

- Dynamic entities: players, NPCs, cameras, physics objects
- `EntityManager:GetPlayer()`, `EntityManager:GetEntity(name)`
- Entity definitions often stored as XML in world folders

### GameLogic (orchestration)

- Singleton managing tasks, modes, save/load
- Coordinates desktop UI, input, network sync

## Creator folder structure

**Full index:** [aries/creator.md](aries/creator.md) — all 49 Game/ subsystems, 62 Tasks, blocks, entities.

```
script/apps/Aries/Creator/
├── Game/                    # ★ Core simulation engine (~2000 files)
│   ├── main.lua             # Paracraft entry / server bootstrap
│   ├── game_logic.lua       # Game loop singleton
│   ├── block_engine.lua     # Voxel engine
│   ├── blocks/              # Block type implementations
│   ├── Entity/              # Entity classes
│   ├── Code/                # Visual programming & Blockly
│   ├── Network/             # Multiplayer, packets, TunnelService
│   ├── Tasks/               # Feature modules (EasyBuilder, ParaLife, …)
│   ├── Physics/             # Damage, physics world
│   ├── Movie/               # In-engine video recording
│   ├── Memory/, Neuron/     # Memory-oriented programming (MOP)
│   ├── Mqtt/                # IoT integration
│   ├── mcml2/               # MCML v2 UI for Creator
│   └── …
├── MainToolBar.lua          # Creator chrome UI
├── MainSideBar.lua
├── HttpAPI/                 # Keepwork HTTP wrappers
├── WorldCommon.lua          # Shared world utilities
└── readme.txt               # GameLevel.xml format docs
```

## Key feature areas (`Creator/Game/Tasks/`)

| Task module | Purpose |
|-------------|---------|
| `EasyBuilder/` | Simplified building mode for beginners |
| `ParaLife/` | Life-simulation gameplay mode |
| `ParaWorld/` | World sharing / community features |
| `MiniGame/` | Mini-game hub and daily recommendations |
| `BuildReplay/` | Record/replay user building sessions |
| `Community/` | Community login and social |
| `EditCodeActor/` | In-world code block editing |
| `AutoSaveTask/` | Periodic world autosave |

## Visual programming

Paracraft's **code blocks** attach to **movie blocks** in the voxel world. Code runs in **coroutines** with auto-yield injection.

See [Code Blocks and Visual Programming](code-blocks-and-visual-programming.md).

Key paths:

- `Creator/Game/Code/` — Blockly definitions, CodeAPI_*, Arduino integration
- `script/ide/System/UI/Blockly/` — Shared Blockly engine (GGS UI framework)

## Multiplayer & mods

| Component | Location |
|-----------|----------|
| In-game network plugin | `Creator/Game/Network/` |
| TunnelService | `Creator/Game/Network/TunnelService/` |
| General Game Server mod | `Mod/GeneralGameServerMod/` |
| WorldShare (cloud) | `Mod/WorldShare/` |
| External package | `npl_packages/paracraft/` (installed at runtime) |

Network acts as a transparent plugin inside the Creator environment (`Network/readme.txt`).

## GI — Game Inventor (GGS)

**GI (Game Inventor / 游戏发名家)** in `Mod/GeneralGameServerMod/GI/` is the low-code sandbox layer for building interactive worlds using:

- Vue-based HTML/CSS/Lua UI
- Blockly visual programming
- Aggregated world APIs (build, network, entities)

See [Mods](mods.md) for GGS/GI details.

## World data format

Worlds live under paths like `worlds/DesignHouse/`. Key files:

| File | Purpose |
|------|---------|
| `GameLevel.xml` | Persistent objects, mob/resource settings |
| Block chunk data | Voxel terrain (engine-managed) |
| Entity XML | Code blocks, NPCs, animations |

`GameLevel.xml` structure (from `Creator/readme.txt`):

```xml
<GameLevel>
  <settings daylength="10">
    <mobs></mobs>
    <resource></resource>
  </settings>
  <persistent>
    <object type="artifact" pos="" model_id=""/>
  </persistent>
</GameLevel>
```

## Mobile

`script/mobile/paracraft/` — ParaCraft Mobile layer (protobuf encoder, 2014+). See readme there.

## Education integrations

- **Keepwork** — Account, permissions, mall (`Creator/HttpAPI/`, `KeepWorkMall/`)
- **TeacherAgent** — Knowledge engine teaching (`Creator/Game/Login/TeacherAgent/`)
- **Educate/** — Education-specific login flows

## CI

`script/apps/Aries/ParacraftCI/ParacraftCI.lua` — Continuous integration hooks for Paracraft builds.

## Common imports pattern

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
```

## See also

- [Creator Game Engine](aries/creator-game-engine.md) — Deep dive
- [Code Blocks](code-blocks-and-visual-programming.md)
- [Haqi / Aries](haqi-aries.md) — Shared client shell
- [Main Package](main-package.md) — `main_script_paracraft` manifest
- [Mods](mods.md) — GGS, WorldShare
