# Kids Platform Subsystems

Deep breakdown of `script/kids/` (~1,117 files). Overview: [paraworld-platform.md](paraworld-platform.md).

## 3DMapSystemApp (`3DMapSystemApp/`)

Application shell and public APIs.

| Subdir | Role |
|--------|------|
| `AppManager.lua` | Install/uninstall/register apps |
| `AppCommands.lua` | Default command handlers |
| `API/` | `paraworld.*` Lua APIs (worlds, auction, map, power, email) |
| `API/test/` | API unit tests |
| `Login/` | Platform login app |
| `mcml/` | MCML controls (PageCtrl, pe_motion, StyleItem) |
| `Assets/` | Asset manifest UI |
| `Developers/` | Dev tools (PrintArtPipeline) |
| `profiles/` | User profile pages |
| `BlueprintApp/` | Blueprint save (SaveBom) |
| `RoomHostApp/` | Room hosting service |
| `Translator/` | Translation app |
| `worlds/` | saveworld.lua |
| `DebugApp/`, `EditApps/` | Debug and edit app IP.xml |

## 3DMapSystemUI (`3DMapSystemUI/`)

Largest subtree — all in-world UI.

| Subdir | Role |
|--------|------|
| `Desktop/` | Platform desktop, logo page |
| `Map/` | 2D/3D map browser, tile edit, land detail |
| `CCS/` | Character customization UI |
| `HomeLand/` | Player housing (indoor, plants, energy) |
| `Creator/` | Legacy in-world creator |
| `Movie/` | Movie editor property panels |
| `InGame/` | In-game editors (NPC talk, items, status) |
| `MiniGames/` | FireFly, SnowBall, LuckyDial, FireMaster |
| `Settings/` | Common settings |
| `MiniMap/` | Minimap position log |
| `HomeZone/` | Home zone app |
| `MyDesktop/` | Personal desktop app |
| `PENote/` | PE note widget |
| `Inventor/` | Inventor gears/transform |
| `Env/` | Sky settings |
| `_obsoleted/` | Deprecated UI |

## 3DMapSystemData (`3DMapSystemData/`)

| Content | Role |
|---------|------|
| `AnimationData.lua` | Animation definitions |
| `user_db.lua` | User database |
| `options.lua` | Data options |
| `MainBarData.lua`, `MainPanelData.lua` | UI bar data |
| `_obsoleted/` | Old assets |

## 3DMapSystemItem (`3DMapSystemItem/`)

Item type scripts — see platform [paraworld-platform.md](paraworld-platform.md).

Key: `PowerItemManager.lua` (quest persistence), `Item_CombatCard.lua`, `Item_Apparel.lua`, `Item_MountPet_Medal.lua`

## 3DMapSystemQuest (`3DMapSystemQuest/`)

| Content | Role |
|---------|------|
| `forms/` | Quest editor forms (goals, chains) |
| `Quest_Server_Loop.lua` | Quest server main loop |
| Loaded by | `Aries/Quest/main.lua` |

## 3DMapSystemNetwork (`3DMapSystemNetwork/`)

JGSL — full doc: [jgsl-networking.md](jgsl-networking.md)

## 3DMapSystemAnimation (`3DMapSystemAnimation/`)

`AnimationManager.lua` — loaded by ParaWorldCore.

## Legacy UI helpers

| Dir | Role |
|-----|------|
| `BCS/` | Body customization system data |
| `CCS/` | CCS data (separate from UI/CCS) |
| `Ui/`, `ui/` | Shared UI helpers |
| `RightClick/` | Right-click context menus (`RCP.lua`) |
| `EnvironmentSet/` | Environment presets |

## Root files

| File | Role |
|------|------|
| `ParaWorldCore.lua` | **Platform include** |
| `3DMapSystem_main.lua` | Legacy main loop |
| `3DMapSystem_Data.lua` | Core data init |
| `kids_db.lua`, `db_*.lua` | Embedded DBs |
| `loadworld.lua`, `saveworld.lua` | World I/O |

## See also

- [Quest System](../aries/quest-system.md)
- [JGSL Networking](jgsl-networking.md)
- [Applications Catalog](applications-catalog.md)
