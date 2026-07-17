# Code System (`Creator/Game/Code/`)

Complete reference for Paracraft's visual programming stack (~198 files). Namespace: `MyCompany.Aries.Game.Code.*`

See also [Code Blocks and Visual Programming](../code-blocks-and-visual-programming.md) for execution model.

## Architecture

```
Blockly UI definitions (*Def/, *BlocklyDef/)
        ↓
CodeBlock.lua / CodeActor.lua  (actor-bound scripts)
        ↓
CodeAPI.lua  →  CodeAPI_*.lua  (sandbox APIs)
        ↓
CodeCompiler.lua / CodeCoroutine.lua  (yield injection)
        ↓
Entity XML in world  ←→  PacketCodeBlockEvent (network id 53)
```

## Core runtime files

| File | Role |
|------|------|
| `CodeBlock.lua` | Code block unit bound to movie blocks |
| `CodeActor.lua` | Actor script host |
| `CodeActorItemStack.lua` | Item stack integration |
| `CodeAPI.lua` | Loads all API modules into sandbox |
| `CodeAPIMultiThreaded.lua` | Multi-threaded execution API |
| `CodeCompiler.lua` | Compile user code with yields |
| `CodeCoroutine.lua` | Coroutine management |
| `CodeEvent.lua` | Event dispatch |
| `CodeGlobals.lua` | Global code state |
| `CodeLibrary.lua` | Reusable module loader |
| `CodeLibraryManager.lua` | Library registry |
| `LanguageConfigurations.lua` | Blockly language configs |
| `FindCodeBlock.lua` | Search code in world |
| `readme.md` | OOP + MOP overview |

## CodeAPI modules

| Module | Domain |
|--------|--------|
| `CodeAPI_Events.lua` | Click, clone, broadcast events |
| `CodeAPI_MotionLooks.lua` | Movement, appearance |
| `CodeAPI_Sensing.lua` | Environment sensing |
| `CodeAPI_Sound.lua` | Audio |
| `CodeAPI_Data.lua` | Variables, lists |
| `CodeAPI_Control.lua` | Control flow helpers |
| `CodeAPI_Microbit.lua` | micro:bit hardware |

Load pattern:

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
-- CodeAPI internally loads all CodeAPI_* modules
```

## Code libraries

`CodeLibrary` loads reusable modules from:

1. `[world_dir]/Code/lib/<name>/`
2. System `Code/lib/` (e.g. `lib/war/simulation.lua`)

## Blockly language packs (21 subdirectories)

Each `*Def/` folder defines Blockly blocks for a target language/platform:

| Directory | Target |
|-----------|--------|
| `CodeBlocklyDef/` | Core Scratch-like Paracraft blocks (Events, Looks, Data, Operators) |
| `CameraBlocklyDef/` | Camera/viewport control |
| `McmlBlocklyDef/` | MCML UI blocks |
| `TeacherBlocklyDef/` | Teacher-mode simplified blocks |
| `NplCad/` | NPL CAD modeling + export tools |
| `NplMicroRobot/` | Micro-robot programming |
| `NplMicrobit/` | NPL micro:bit variant |
| `Microbit/` | BBC micro:bit blocks |
| `MicroPython/` | MicroPython WiFi/control |
| `Arduino/` | Arduino I/O |
| `Craft2d/` | 2D craft blocks |
| `CppDef/` | C++ std blocks |
| `clangDef/` | C/C++ include defs |
| `CommandsDef/` | Command/language plugins |
| `CommonDefs/` | Shared math/loop |
| `HaqiDef/` | Haqi arena-specific |
| `JiHRobot/` | JiH robot hardware |
| `BlockPenDef/` | Block pen painter |
| `SerialPort/` | Serial connector UI |
| `NplPPT/` | Presentation blocks |
| `TextToWorld/` | Text-to-world generation |
| `lib/cad/` | CAD library scripts |

Key entry files:

- `CodeBlocklyDef/ParacraftCodeBlockly.lua` — main Paracraft block set
- `CodeBlocklyDef/CodeBlocklyJunior.lua` — junior/simplified set
- `NplCad/NplCadDef/*` — skeleton, data, control defs
- `HaqiDef/Haqi.lua` — Haqi integration blocks

## Editor UI (HTML)

| File | Purpose |
|------|---------|
| `CodeBlockWindow.html` / `.lua` | Main code editor window |
| `CodeIntelliSense.html` | IntelliSense popup |
| `CodeHelpWindow.lua` | Help browser |
| `CodeBlockList.html` | Block list panel |
| `CodePyToNplPage.lua` | Python-to-NPL converter |
| `NplCadLibPage.html` | CAD library browser |
| `CameraBlocklyDef/CodeBlockWindowCamera.html` | Camera block editor |

## Examples

`Examples/HelloLanguage.npl` — sample NPL code block script.

## Relationship to other AI systems

| System | Location | Relationship |
|--------|----------|----------------|
| **CodeBlock** | This folder | User-facing visual programming on movie blocks |
| **Neuron** | `../Neuron/` | Spatial graph of script blocks with axon/dendrite wiring |
| **Memory** | `../Memory/` | AI brain replaying memory clips for autonomous animation |

CodeBlock = primary teaching tool. Neuron = advanced spatial scripting. Memory = AI-driven animation research.

## Network sync

Code block events replicate via `PacketCodeBlockEvent` (packet ID 53) in `Network/Packets/`.

## See also

- [Code Blocks](../code-blocks-and-visual-programming.md)
- [Creator Network](creator-network.md)
- [Memory and Neuron](../memory-and-neuron.md)
- [API Index](../api-index.md)
