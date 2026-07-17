# Creator Integrations

Platform bridges, media, IoT, and runtime extensions in `Creator/Game/`.

Parent: [creator.md](creator.md)

## Platform (`Android/`, `iOS/`, `Mobile/`)

| Path | Role |
|------|------|
| `Android/Android.lua` | Android-specific hooks |
| `iOS/iOS.lua` | iOS-specific hooks |
| `Mobile/` | Mobile UI — [creator-login-education.md](creator-login-education.md) |
| `Emscripten/` | WebAssembly build (7 files) |
| `WasmClang/` | WASM clang toolchain bridge |

## IoT — Mqtt (`Mqtt/` — 30 files)

| File | Role |
|------|------|
| `MqttApi.lua` | MQTT device API |
| `Dialog/MqttCreateDevice.html` | Create device UI |
| `Dialog/MqttDeleteDevice.lua` | Delete device |

Integrates physical IoT devices with code blocks.

## Movie (`Movie/` — 70 files)

| Component | Role |
|-----------|------|
| `VideoRecorder.lua` | Record in-engine video |
| Movie timeline | Pairs with `script/movie/movielib.lua` |
| Code blocks | Movie clips anchor CodeBlock actors |

## Shaders (`Shaders/` — 29 files)

Custom rendering effects:

- `mrt_bmax_model.fx` — multi-render-target bmax models
- Used by block models and CAD export

## Sound & Effects

| Path | Role |
|------|------|
| `Sound/SoundManager.lua` | Audio playback |
| `Effects/EntityAnimation.lua` | Entity animation effects |

## NodeJsRuntime (4 files)

Bridge to Node.js for external tooling.

## NplBrowser (14 files)

Embedded browser for web content in Creator.

## GameMarket (16 files)

In-game marketplace (non-Keepwork-mall).

## PapaAdventures (13 files)

"Papa Adventures" branded content/game mode.

## NodeJs / Website

| Path | Role |
|------|------|
| `Website/` | Embedded website helpers (2 files) |
| `NplMod/` | In-world mod nodes (4 files) |

## Mod (`Mod/` — 2 files)

`ModManager.lua` — load external NPL mods; pairs with `npl_packages/`.

## Agent (`Agent/` — 14 files)

AI agent support code; main Copilot UI in `Tasks/EasyBuilder/Copilot/`.

## See also

- [code-system.md](code-system.md) — Arduino, MicroPython hardware blocks
- [mobile-paracraft.md](../mobile-paracraft.md)
- [movie library](../supporting-modules.md)
