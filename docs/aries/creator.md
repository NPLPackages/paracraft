# Creator (`script/apps/Aries/Creator/`)

Master index for **Paracraft Creator** — the editor shell and `Game/` simulation engine (~2,500+ files).

Namespace root: `MyCompany.Aries.Creator.*`, `MyCompany.Aries.Game.*`

Entry: `Creator/Game/main.lua` | Bootstrap via `Aries/main_loop.lua` with `mc="true"`

**Game data (XML at install):** [config/aries-creator.md](../config/aries-creator.md)

## Top-level layout

```
Creator/
├── Game/              ★ Simulation engine (~2,380 files) — see sub-pages below
├── HttpAPI/           Keepwork HTTP semantic layer (8 files)
├── Pages/             Standalone MCML pages (open world, share photos, …)
├── Env/               Environment presets
├── WorldCommon.lua    Shared world utilities
├── MainToolBar.lua    Creator toolbar chrome
├── MainSideBar.lua    Side panel
├── readme.txt         GameLevel.xml format
└── (root *.html)      CreateOpenWorld, SharePhotos, …
```

## Documentation map

| Topic | Page |
|-------|------|
| **All Game/ subsystems (49 dirs)** | [creator-game-subsystems.md](creator-game-subsystems.md) |
| **Tasks/ feature modules (62 dirs)** | [creator-tasks.md](creator-tasks.md) |
| **Block types (54 classes)** | [creator-blocks.md](creator-blocks.md) |
| **Entity types (54 classes)** | [creator-entities.md](creator-entities.md) |
| Core engine (GameLogic, BlockEngine) | [creator-game-engine.md](creator-game-engine.md) |
| Code / Blockly | [code-system.md](code-system.md) |
| Network / packets | [creator-network.md](creator-network.md) |
| Keepwork HTTP API | [creator-httpapi.md](creator-httpapi.md) |
| UI: Areas, GUI, Desktop | [creator-ui-areas.md](creator-ui-areas.md) |
| Login, Educate, Mobile | [creator-login-education.md](creator-login-education.md) |
| Mqtt, Movie, Shaders, … | [creator-integrations.md](creator-integrations.md) |
| Memory / Neuron AI | [../memory-and-neuron.md](../memory-and-neuron.md) |

## Root shell files

| File | Role |
|------|------|
| `MainToolBar.lua` / `.html` | Primary creator toolbar |
| `MainSideBar.lua` | Block/tool sidebar |
| `WorldCommon.lua` | World path helpers, shared between shell and Game |
| `CreateOpenWorld.html` | Open world wizard |
| `SharePhotosPageStandalone*.html` | Photo sharing UI |

## HttpAPI/

Semantic Keepwork backend wrappers — [creator-httpapi.md](creator-httpapi.md)

## Pages/

Standalone MCML/HTML pages loaded by Creator shell (world browser, settings) — listed in [creator-ui-areas.md](creator-ui-areas.md).

## Relationship to Haqi

| Mode | Behavior |
|------|----------|
| `mc="true"` | Creator toolbar + Game engine active |
| Default Aries | Haqi MMO UI; Creator code still present but not primary |

Shared: `WorldCommon.lua`, `Player`, network when enabled.

## See also

- [Paracraft](../paracraft.md)
- [Haqi / Aries](../haqi-aries.md)
- [SCAN_LOG](../SCAN_LOG.md)
