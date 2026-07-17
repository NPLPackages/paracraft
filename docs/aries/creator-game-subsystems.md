# Creator Game Subsystems

Every immediate subdirectory of `Creator/Game/` (~49 folders, ~2,380 files). Namespace: `MyCompany.Aries.Game.*`

Parent: [creator.md](creator.md)

## Root-level core files

| File | Role |
|------|------|
| `main.lua` | Entry, server bootstrap, `Game.Start()` |
| `game_logic.lua` | Singleton game loop |
| `game_options.lua` | Runtime options |
| `block_engine.lua` | Voxel engine |
| `GameDesktop.lua` | In-game creator desktop |

## Subsystem index

| Directory | Files | Purpose | Doc |
|-----------|-------|---------|-----|
| **Agent** | 14 | AI agent helpers (Copilot/edu agent integration) | [creator-tasks.md](creator-tasks.md) EasyBuilder/Copilot |
| **API** | 6 | `FileDownloader` and creator HTTP helpers | [creator-httpapi.md](creator-httpapi.md) |
| **Areas** | 108 | In-world UI panels (chat, settings, machine, world2in1) | [creator-ui-areas.md](creator-ui-areas.md) |
| **Android** | 1 | `Android.lua` platform hooks | [creator-integrations.md](creator-integrations.md) |
| **AutoUpdateLoader** | 3 | Client auto-update loader | [creator-login-education.md](creator-login-education.md) |
| **blocks** | 56 | Block type classes + registry | [creator-blocks.md](creator-blocks.md) |
| **Code** | 198 | Visual programming, Blockly, CodeAPI | [code-system.md](code-system.md) |
| **Commands** | 60 | Slash commands, CmdParser, CommandManager | below |
| **Common** | 44 | Files, AnimTable, shared utilities | [api-index.md](../api-index.md) Files |
| **Effects** | 12 | EntityAnimation, visual effects | [creator-integrations.md](creator-integrations.md) |
| **Educate** | 68 | Education flows, mobile login | [creator-login-education.md](creator-login-education.md) |
| **Emscripten** | 7 | WebAssembly/emscripten build hooks | [creator-integrations.md](creator-integrations.md) |
| **Entity** | 68 | All entity classes | [creator-entities.md](creator-entities.md) |
| **GameMarket** | 16 | In-game marketplace | [creator-integrations.md](creator-integrations.md) |
| **GameRules** | 11 | Rule definitions (game modes) | below |
| **GUI** | 83 | 3D manipulators, dialogs, controllers | [creator-ui-areas.md](creator-ui-areas.md) |
| **iOS** | 1 | `iOS.lua` platform hooks | [creator-integrations.md](creator-integrations.md) |
| **Items** | 68 | Item, ItemStack, ItemClient | [api-index.md](../api-index.md) |
| **KeepWork** | 21 | Keepwork integration (non-HttpAPI) | [creator-httpapi.md](creator-httpapi.md) |
| **KeepWorkMall** | 17 | Keepwork mall UI | [creator-httpapi.md](creator-httpapi.md) |
| **Login** | 84 | Creator login, updater, PrepareApp | [creator-login-education.md](creator-login-education.md) |
| **Macros** | 31 | Macro recording/playback | below |
| **Materials** | 8 | Block material definitions | [creator-blocks.md](creator-blocks.md) |
| **mcml** | 26 | Creator MCML v1 elements (`pe_mc_block`) | [mcml-ui.md](../mcml-ui.md) |
| **mcml2** | 10 | MCML v2 elements for Creator | [mcml-ui.md](../mcml-ui.md) |
| **Memory** | 20 | MOP memory AI | [memory-and-neuron.md](../memory-and-neuron.md) |
| **Mobile** | 48 | Mobile UI register, user protocol | [mobile-paracraft.md](../mobile-paracraft.md) |
| **Mod** | 2 | Mod manager hooks | [mods.md](../mods.md) |
| **Movie** | 70 | Video recorder, in-engine movie | [creator-integrations.md](creator-integrations.md) |
| **Mqtt** | 30 | IoT MQTT devices | [creator-integrations.md](creator-integrations.md) |
| **Neuron** | 22 | Neuron block graph AI | [memory-and-neuron.md](../memory-and-neuron.md) |
| **Network** | 117 | TCP multiplayer | [creator-network.md](creator-network.md) |
| **NodeJsRuntime** | 4 | Node.js runtime bridge | [creator-integrations.md](creator-integrations.md) |
| **NplBrowser** | 14 | Embedded NPL browser | [creator-integrations.md](creator-integrations.md) |
| **NplExtensionsUpdater** | 3 | Extension updater | [creator-login-education.md](creator-login-education.md) |
| **NplMod** | 4 | In-world NPL mod nodes | [supporting-modules.md](../supporting-modules.md) |
| **PapaAdventures** | 13 | Papa Adventures content mode | [creator-tasks.md](creator-tasks.md) |
| **Physics** | 5 | DamageSource, physics world | below |
| **SceneContext** | 18 | SelectionManager, edit contexts | [api-index.md](../api-index.md) |
| **Setting** | 9 | ServerSetting UI | [creator-ui-areas.md](creator-ui-areas.md) |
| **Shaders** | 29 | Custom FX (`mrt_bmax_model.fx`, …) | [creator-integrations.md](creator-integrations.md) |
| **Sound** | 4 | SoundManager | below |
| **Tasks** | 893 | Feature task modules | [creator-tasks.md](creator-tasks.md) |
| **Test** | 5 | Creator internal tests | — |
| **Tools** | 11 | Editor tools | below |
| **Tutorial** | 2 | In-app tutorial | [creator-tasks.md](creator-tasks.md) |
| **Website** | 2 | Embedded website helpers | below |
| **WasmClang** | 1 | WASM clang bridge | [creator-integrations.md](creator-integrations.md) |
| **World** | 39 | World, AutoSaver, CameraController | below |

## Commands (`Commands/`)

| Component | File | Role |
|-----------|------|------|
| CmdParser | `CmdParser.lua` | Parse `/command` strings |
| CommandManager | `CommandManager.lua` | Register/dispatch commands |
| CommandDetect | `CommandDetect.lua` | Detect command blocks |

Docgen: [api-index.md](../api-index.md) — CmdParser, CommandManager

## World (`World/`)

| File | Role |
|------|------|
| `World.lua` | World singleton |
| `WorldSim.lua` | Simulation state |
| `WorldInfo.lua` | Metadata |
| `WorldRevision.lua` | Version/revision tracking |
| `EditableWorld.lua` | Editable world wrapper |
| `AutoSaver.lua` | Periodic save |
| `CameraController.lua` | Camera for play mode |
| `WorldBlockAccess.lua` | Block permission checks |

## Physics (`Physics/`)

- `DamageSource.lua` — damage system (`Game.OnStaticInit` calls `StaticInit()`)
- Physics world collision integration with BlockEngine

## Sound (`Sound/`)

- `SoundManager.lua` — initialized in `Game.OnStaticInit()`

## Macros (`Macros/`)

- `MacroPlayerMove.lua` — record player movement
- `ConvertToWebMode/` — export world to web
- Used with macro code camp tasks

## GameRules (`GameRules/`)

Rule sets for play modes (PvP, adventure constraints).

## Tools (`Tools/`)

Misc editor utilities (selection tools, exporters).

## See also

- [creator.md](creator.md)
- [creator-tasks.md](creator-tasks.md)
