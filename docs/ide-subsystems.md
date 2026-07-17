# IDE Subsystems

Deep index of `script/ide/` (~1,100 files). Overview: [ide-framework.md](ide-framework.md).

## System/ (core framework)

| Path | Role |
|------|------|
| `System/System.lua` | Root `System.*` namespace |
| `System/Core/` | Scene, Event, ToolBase, ActionGroup |
| `System/Database/` | DB abstraction, IOThread |
| `System/Compiler/` | NPL/DSL compiler, yield injection |
| `System/Plugins/` | PluginBase |
| `System/os/` | WebView, OS abstractions |
| `System/Scene/` | Cameras, Viewports, WebXR |
| `System/Util/` | xgettext, DarkNet, StrongString |
| `System/localserver/` | WebCacheDB, ManagedResourceStore |
| `System/nplcmd/` | NPL CLI (`cmd.npl`, README) |
| `System/Windows/` | MCML v1 window system, Controls, Events |

## System/UI/ (GGS UI)

| Path | Role |
|------|------|
| `UI/Readme.md` | GGS UI design guidelines (1280×720) |
| `UI/Blockly/` | Visual programming engine |
| `UI/Vue/` | Vue-style HTML UI |
| `UI/Window/` | MCML v2 window elements |
| `UI/Editor/` | In-engine editors |
| `UI/Page/` | Page macros |
| `UI/Markdown/` | Markdown renderer |
| `UI/MatataLab/` | MatataLab toolbox |
| `UI/Blockly/Sandbox/` | Blockly sandbox |

## Top-level ide modules

| Path | Role |
|------|------|
| `commonlib.lua` | Foundation — gettable, inherit, log |
| `IDE.lua` | IDE shell |
| `package/package.lua` | Zip package system |
| `Debugger/` | IPCDebugger, NPLProfiler |
| `Animation/` | Keyframes, MovieClip, PreLoader |
| `Motion/`, `MotionEx/` | Tweens, spell cast viewer |
| `Director/` | MovieRender (Mcml, Script, Text) |
| `Storyboard/` | StoryboardParser, KeyFrame |
| `Display/`, `Display2D/`, `Display3D/` | Display object hierarchy |
| `AudioEngine/` | SoundManager |
| `IPCBinding/` | C# ↔ NPL IPC |
| `ObjectOriented/` | OOP compiler |
| `mysql/` | MySQL + sqlite3 bindings |
| `math/` | Point, AABB, vectors |
| `STL/` | List, Queue, RingBuffer, OrderedArraySet |
| `ProjectTemplates/` | App template generators |
| `UnitTest/` | Test framework |
| `AI.lua` | AI helpers |
| `DataBinding.lua` | UI data binding |
| `Json.lua` | JSON parse/serialize |
| `Locale.lua` | Preferred over deprecated `lang/lang.lua` |
| `loadworld.lua` | World loading helper |
| `WindowFrame.lua` | Window frame chrome |
| `ContextMenu.lua`, `ContextMenu2.lua` | Context menus |

## MCML v1 elements (`System/Windows/mcml/Elements/`)

`pe_button`, `pe_gridview`, `pe_treeview`, `pe_if`, `pe_radio`, `pe_script`, layout, css/

## Compiler DSL

`System/Compiler/dsl/DSL_NPL.npl` — NPL domain-specific language.

## Config

`ide/config/NPLStateConfig.lua` — NPL runtime state configuration.

## Used by

| Consumer | IDE modules used |
|----------|------------------|
| Paracraft Creator | Blockly, Window, Compiler, MCML |
| Haqi | MCML v1, commonlib, Animation |
| GGS/GI | Vue, Blockly, Window |
| PETools | IPCBinding |

## See also

- [mcml-ui.md](mcml-ui.md)
- [npl-and-modules.md](npl-and-modules.md)
- [Code System](../aries/code-system.md)
