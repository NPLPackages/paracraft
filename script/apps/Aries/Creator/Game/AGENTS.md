# AGENTS.md — `script/apps/Aries/Creator/Game`

**Most important root for Paracraft.** This folder is the voxel simulation engine (~2,000+ files): game loop, blocks, entities, code blocks, network, tasks, and in-world UI.

Wiki: [aries/creator.md](../../../../../docs/aries/creator.md) · [paracraft.md](../../../../../docs/paracraft.md) · [CODEMAP](../../../../../docs/CODEMAP.md) · [TOPIC-INDEX](../../../../../docs/TOPIC-INDEX.md)

Parent hubs: [Creator/AGENTS.md](../AGENTS.md) · [repo AGENTS.md](../../../../../AGENTS.md)

Namespace: **`MyCompany.Aries.Game.*`** (shell UI also uses `MyCompany.Aries.Creator.*`)

## Entry & architecture

```
main.lua → Game.Start() → GameLogic
```

Three-layer stack (keep changes in the right layer):

```
GameLogic     game_logic.lua          orchestration, tasks, modes, save
EntityManager Entity/EntityManager.lua  players, NPCs, cameras, physics actors
BlockEngine   block_engine.lua        voxel grid
```

| Module | Namespace | File |
|--------|-----------|------|
| GameLogic | `MyCompany.Aries.Game.GameLogic` | `game_logic.lua` |
| BlockEngine | `MyCompany.Aries.Game.BlockEngine` | `block_engine.lua` |
| EntityManager | `MyCompany.Aries.Game.EntityManager` | `Entity/EntityManager.lua` |
| block_types | `MyCompany.Aries.Game.block_types` | `blocks/block_types.lua` |

Launch: `bootstrapper="script/apps/Aries/Creator/Game/main.lua"` or Aries client with `mc="true"`.

## Critical coding patterns

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
```

1. **Never `require()`** — only `NPL.load("(gl)...")`.
2. Block vs world coords: `BlockEngine:block(x,y,z)` / `BlockEngine:real(bx,by,bz)`; `GetBlock` / `SetBlock`.
3. Entities: `EntityManager:GetPlayer()`, `EntityManager:GetEntity(name)`.
4. OOP: `commonlib.inherit(...)`; match existing Entity/block class style.
5. User strings: `L"..."`.
6. Logging: `LOG.std(nil, "debug", "Module", "msg %s", v)` or `echo` / `commonlib.echo`.

### Code blocks (`Code/`)

- Run in **coroutines**; compiler injects `checkyield()` — do not fight that model.
- Delays: `wait(seconds)`, not OS timers.
- Events: `registerClickEvent`, `registerCloneEvent`, `registerBroadcastEvent`, …
- Logic often stored on **entity XML** in the world, not standalone scripts.
- Shared Blockly engine: `script/ide/System/UI/Blockly/` ([System AGENTS](../../../../ide/System/AGENTS.md)).

### MCML

- Creator UI: `Areas/`, `GUI/`, `mcml/`, `mcml2/`.
- After data changes: `page:Refresh()`. Details: [docs/mcml-ui.md](../../../../../docs/mcml-ui.md).

## Where to put new work

| Kind of change | Prefer |
|----------------|--------|
| Feature / mode / campaign UI | `Tasks/<Name>/` ([creator-tasks.md](../../../../../docs/aries/creator-tasks.md)) |
| New block type | `blocks/` + register in `block_types` ([creator-blocks.md](../../../../../docs/aries/creator-blocks.md)) |
| New entity | `Entity/` ([creator-entities.md](../../../../../docs/aries/creator-entities.md)) |
| Slash command | `Commands/` |
| Multiplayer packet | `Network/` ([creator-network.md](../../../../../docs/aries/creator-network.md)) |
| Visual programming API | `Code/` ([code-system.md](../../../../../docs/aries/code-system.md)) |
| Keepwork HTTP | Parent `Creator/HttpAPI/` ([creator-httpapi.md](../../../../../docs/aries/creator-httpapi.md)) |
| Shared framework / Blockly UI | `script/ide/System/` — not duplicated here |

Do not dump one-off features into `game_logic.lua` or `main.lua` unless they are truly core lifecycle.

## Important subtrees (49 dirs)

Full table: [docs/aries/creator-game-subsystems.md](../../../../../docs/aries/creator-game-subsystems.md).

| Dir | Purpose |
|-----|---------|
| `blocks/`, `Entity/`, `Items/` | Voxel + actors + items |
| `Code/` | Blockly / CodeAPI / cameras |
| `Network/` | TCP packets, TunnelService |
| `Tasks/` | Feature modules (EasyBuilder, ParaLife, …) |
| `Areas/`, `GUI/` | In-world panels & manipulators |
| `World/` | World singleton, AutoSaver, camera |
| `Login/`, `Educate/`, `Mobile/` | Auth, education, mobile |
| `Movie/`, `Mqtt/`, `Memory/`, `Neuron/` | Recording, IoT, MOP AI |
| `Commands/`, `SceneContext/`, `Physics/` | Commands, selection, damage |

## Sibling Creator shell (outside `Game/`)

`../MainToolBar.lua`, `../MainSideBar.lua`, `../WorldCommon.lua`, `../HttpAPI/` — Creator chrome and Keepwork wrappers. Prefer Game/ for simulation; shell for editor chrome.

## Docs map

| Topic | Doc |
|-------|-----|
| All Game/ dirs | [creator-game-subsystems.md](../../../../../docs/aries/creator-game-subsystems.md) |
| Engine deep dive | [creator-game-engine.md](../../../../../docs/aries/creator-game-engine.md) |
| Tasks (62) | [creator-tasks.md](../../../../../docs/aries/creator-tasks.md) |
| Blocks / entities | [creator-blocks.md](../../../../../docs/aries/creator-blocks.md), [creator-entities.md](../../../../../docs/aries/creator-entities.md) |
| Network | [creator-network.md](../../../../../docs/aries/creator-network.md) |
| Code system | [code-system.md](../../../../../docs/aries/code-system.md) |
| Game data XML | [docs/config/aries-creator.md](../../../../../docs/config/aries-creator.md) |
| Copilot rules | [`.github/instructions/paracraft.instructions.md`](../../../../../.github/instructions/paracraft.instructions.md) |

## Reminder

This is a mature domain-specific engine. Prefer extending existing Tasks/Entity/block patterns over introducing new frameworks, package managers, or alien module systems.
