# Code Blocks and Visual Programming

Paracraft's **visual programming** system lets users control in-world actors using Blockly-style blocks attached to **movie blocks** in the voxel world.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Blockly UI (script/ide/System/UI/Blockly/)      │
├─────────────────────────────────────────────────┤
│  Block definitions (Creator/Game/Code/)          │
│    CodeAPI_*, *BlocklyDef/, Arduino/            │
├─────────────────────────────────────────────────┤
│  NPL Compiler (ide/System/Compiler/)             │
│    Coroutine + checkyield() injection           │
├─────────────────────────────────────────────────┤
│  Entity XML storage (world files, not .lua)      │
└─────────────────────────────────────────────────┘
```

## Programming models

Paracraft supports two complementary models (from `Creator/Game/Code/readme.md`):

1. **OOP** — Traditional object-oriented Lua via `commonlib.inherit`
2. **MOP (Memory-Oriented Programming)** — Memory blocks, neuron cells (`Memory/`, `Neuron/`)

## Code block execution rules

From `.github/instructions/paracraft.instructions.md`:

1. All code block functions run in **coroutines** (never raw functions)
2. Compiler injects `checkyield()` into loops to prevent infinite loops blocking NPL
3. Use `wait(seconds)` for delays — **not** OS timers
4. Code is stored in **Entity XML** in world files, not as standalone `.lua` on disk

### Example pattern

```lua
while true do
    move(0.01, 0);  -- auto-yields via checkyield()
    wait(2);        -- explicit yield
end
```

## Event APIs

Common registration functions in code blocks:

| API | Purpose |
|-----|---------|
| `registerClickEvent()` | Actor clicked |
| `registerCloneEvent()` | Actor cloned |
| `registerBroadcastEvent()` | Network/world broadcasts |

## Code directory map (`Creator/Game/Code/`)

| Path | Purpose |
|------|---------|
| `CodeAPI_Sensing.lua` | Sensing/environment APIs |
| `CodeLightActor.lua` | Light control |
| `CameraBlocklyDef/Cameras.lua` | Camera block definitions |
| `McmlBlocklyDef/McmlBlockly.lua` | MCML UI blocks |
| `Arduino/Arduino_IO.lua` | Arduino/IoT I/O |
| `NplMicroRobot/NplMicroRobot.lua` | Micro robot actor |

## Blockly engine (`script/ide/System/UI/Blockly/`)

Shared framework used by Paracraft and GGS GI:

| Component | File |
|-----------|------|
| Core block | `Block.lua`, `BlocklyBlock.lua` |
| Shadow blocks | `ShadowBlock.lua` |
| Sandbox | `Sandbox/Sandbox.lua` |
| Field editors | `Pages/FieldEditBlockly.html`, `FieldEditTextArea.html` |
| Language configs | `Blocks/LanguageConfigs/cad_1_0_1.lua` |

Readme: `script/ide/System/UI/Blockly/Readme.md` — links to Paracraft community resources.

## Build replay / recording

`Creator/Game/Tasks/BuildReplay/`:

- `ReplayManager.lua` — Replay sessions
- `RecordUserPath.lua` — Record user actions
- `NplBlockly.html` — Blockly replay UI

Used for tutorials and CI (`ParacraftCI`).

## Edit in world

`Tasks/EditCodeActor/EditCodeActor.lua` — In-world code block editor task.

## Compiler

`script/ide/System/Compiler/readme.md` — DSL compilation including yield injection for code blocks.

Related: `Compiler/dsl/DSL_NPL.npl`

## Memory-oriented programming

From `Creator/Game/Memory/readme.md`:

> In Paracraft AI, Memory is essentially an infinite spacetime sequence collection without absolute time origin. Hippocampus (high neuron density brain region) is associated with long-term memory.

Memory blocks: `blocks/BlockMemory.lua`, `Memory/` subsystem.

Neuron cells: `Neuron/Cell/CellBlock.lua`

## Teacher / knowledge engine

`Creator/Game/Login/TeacherAgent/readme.md`:

Uses Keepwork **knowledge engine** concepts to teach Paracraft usage interactively.

## GGS / GI Blockly

General Game Server mod uses same Blockly stack for sandbox games:

- `Mod/GeneralGameServerMod/GI/App/AI/Readme.md`
- `Mod/GeneralGameServerMod/App/ui/` — Sample Blockly UIs

## Testing

```lua
-- test/test_hyz.lua loads many Creator/Game modules for testing
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Cameras.lua");
```

## Development tips

1. When adding new blocks, define both Blockly def and CodeAPI handler
2. Test with yield loops — infinite loops without yield freeze NPL runtime
3. Use `LOG.std` for debugging generated code execution
4. MCML blocks need `McmlBlocklyDef` registration

## See also

- [Paracraft](../paracraft.md)
- [Creator Game Engine](aries/creator-game-engine.md)
- [IDE Framework](../ide-framework.md) — Blockly, Compiler
- `.github/instructions/paracraft.instructions.md`
