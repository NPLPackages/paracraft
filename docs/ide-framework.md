# IDE Framework (`script/ide/`)

The **`script/ide/`** directory is the shared **framework layer** for all ParaEngine/NPL applications. ~1,100 files covering commonlib, UI, database, networking utilities, animation, and tooling.

Every app includes this via `ParaWorldCore.lua` → `IDE.lua` → `System.lua`.

## Bootstrap chain

```
commonlib.lua          # Core utilities, gettable, inherit, logging
    │
IDE.lua                # IDE integration, editors
    │
System/System.lua      # System.* namespace (apps, UI, database, scene)
    │
Subsystems (loaded on demand)
```

## Major subdirectories

```
script/ide/
├── commonlib.lua              # ★ Foundation — always load first
├── IDE.lua                    # IDE shell integration
├── NPLExtension.lua           # NPL language extensions
├── ParaEngineExtension.lua    # Engine API wrappers
│
├── System/                    # ★ Largest subsystem
│   ├── System.lua             # Root System table
│   ├── Core/                  # Scene, Event, ToolBase
│   ├── Database/              # DB abstraction, IOThread
│   ├── UI/                    # GGS UI (Blockly, Vue, Window, Editor)
│   │   ├── Blockly/           # Visual programming engine
│   │   ├── Vue/               # Vue-style HTML UI framework
│   │   ├── Window/            # Window framework elements
│   │   ├── Editor/            # In-engine editors
│   │   └── Page/              # Page macros
│   ├── Windows/               # MCML v1 implementation
│   │   └── mcml/              # Elements, CSS, layout
│   ├── Scene/                 # Cameras, viewports, WebXR
│   ├── Compiler/              # NPL/DSL compiler
│   ├── nplcmd/                # NPL command-line tool
│   ├── os/                    # WebView, OS abstractions
│   ├── Plugins/               # Plugin base classes
│   ├── Util/                  # xgettext, DarkNet, StrongString
│   └── localserver/           # Embedded HTTP cache/stores
│
├── package/                   # Zip package system
├── ObjectOriented/            # OOP compiler helpers
├── Debugger/                  # IPC debugger, NPL profiler
├── Animation/                 # Keyframe animation system
├── Motion/, MotionEx/         # Tweening, spell cast rendering
├── Display/, Display2D/, Display3D/  # 2D/3D display objects
├── Director/                  # Movie rendering (MCML, script, text)
├── Storyboard/                # Storyboard parser
├── AudioEngine/               # Sound manager
├── IPCBinding/                # C# ↔ NPL IPC for tools
├── mysql/, sqlite bindings
├── math/                      # Point, AABB, vectors
├── STL/                       # List, Queue, RingBuffer, …
├── ProjectTemplates/          # App template generators
└── UnitTest/                  # Unit test framework
```

## commonlib patterns

### Module loading

```lua
NPL.load("(gl)script/ide/commonlib.lua");
local MyMod = commonlib.gettable("MyCompany.MyMod");
```

### Inheritance

```lua
local MyClass = commonlib.inherit(
    commonlib.gettable("ParentClass"),
    commonlib.gettable("MyCompany.MyClass")
);

function MyClass:ctor() end
function MyClass:Init(param)
    return self;  -- chaining
end
```

### Logging

```lua
LOG.std(nil, "debug", "ModuleName", "message %s", var)
commonlib.echo(data)
echo("text")
```

## System.UI — GGS framework

Documented in `script/ide/System/UI/Readme.md`:

> GGS UI framework is based on low level NPL rendering API like mcml v2, and mainly used by Code Blockly Control in paracraft.

Sub-frameworks:

| Framework | Path | Used by |
|-----------|------|---------|
| MCML v1 | `System/Windows/mcml/` | Haqi UI, legacy ParaWorld |
| MCML v2 / Window | `System/UI/Window/` | Modern window elements |
| Vue UI | `System/UI/Vue/` | GGS GI apps, HTML-style pages |
| Blockly | `System/UI/Blockly/` | Paracraft code blocks, GI |
| Markdown | `System/UI/Markdown/` | Rich text rendering |

Default Paracraft window design size: **1280×720** (per UI Readme).

## MCML v1 (`System/Windows/mcml/`)

Core MCML implementation for ParaWorld/Haqi:

- `Elements/` — `pe_button`, `pe_gridview`, `pe_treeview`, `pe_if`, …
- `css/` — StyleColor, StyleLength, stylesheet
- `ElementLayout.lua` — Layout engine

See [MCML UI](mcml-ui.md).

## Blockly (`System/UI/Blockly/`)

Shared visual programming engine used by:

- Paracraft Creator code blocks
- GGS GI tutorials and apps
- CAD block configs in `Blocks/LanguageConfigs/`

Components: `Block.lua`, `BlocklyBlock.lua`, `ShadowBlock.lua`, `Sandbox/`, field editors.

## Compiler (`System/Compiler/`)

NPL/DSL compilation including code block yield injection. See `readme.md` in that folder.

## Database

| Module | Backend |
|--------|---------|
| `System/Database/` | Abstract DB layer |
| `ide/mysql/` | MySQL |
| `script/sqlite/` | SQLite (separate tree) |

## Animation & motion

- `ide/Animation/` — Keyframe animations, movie clips
- `ide/Motion/` — Tweens (Color, Rotate, Bezier)
- `ide/MotionEx/` — Spell cast viewer (uses Haqi mob models)
- `ide/Director/` — Movie render pipeline

## IPC & tools

`IPCBinding/` — Bind NPL to C# entity tools (`PETools/`). Framework for entity design in Visual Studio.

## Package system

`ide/package/package.lua` — See [Main Package](main-package.md).

## Localization

Use `L"string"` for translatable text. Language files: `script/lang/IDE-enUS.lua`, `IDE-zhCN.lua`.

## Project templates

`ProjectTemplates/Templates/InstallApps/` — Generates `app_main.lua` + `IP.xml` for new ParaWorld apps (used by HelloWorld tutorial).

## See also

- [NPL and Modules](npl-and-modules.md)
- [MCML UI](mcml-ui.md)
- [Code Blocks](code-blocks-and-visual-programming.md)
- [Overview](overview.md)
