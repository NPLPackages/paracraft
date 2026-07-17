# Supporting Modules

Documentation for secondary `script/` trees not covered by main product pages.

## Tutorials (`script/tutorials/` — ~24 files)

Self-contained learning projects. No README index — discover by folder.

| Project | Topic |
|---------|--------|
| `helloworld/` | **Start here** — basic NPL, chat, world load (`main.lua`, `chat_client/server.lua`, `helloworld.xml`) |
| `CYFTest/` | DB query UI (`AriesDBQuery.lua/html`), color dialog |
| `WDTest/` | CSS/HTML test |
| `explorertest/` | Explorer integration |
| `preboy/NewFilter1/` | UI filter/trade confirm exercises |
| `preboy/Test.lua` | Standalone test |

Recommended order: `helloworld/` → `CYFTest/` → `explorertest/`

## SQLite (`script/sqlite/` — 15 files)

Embedded SQLite for local apps.

```lua
NPL.load("(gl)script/sqlite/sqlite3.lua");
```

| File | Role |
|------|------|
| `sqlite3.lua` | Main wrapper |
| `luasql-sqlite3.lua`, `libluasqlite3-loader.lua` | Dynamic loader |
| `readme.txt` | Usage guide |
| `examples/` | simple, statement, aggregate, function, order, smart, tracing |
| `tests*.lua`, `lunit.lua` | Test suite |

Used by: `EBook/EBook_db.lua`, `network/mapMark_db.lua`

Based on Michael Roth's lua-sqlite3 (2005). `stmt_class.exec()` waits on busy server by default.

## Localization (`script/lang/` — 9 files)

Application string bundles. **`lang.lua` is deprecated** — prefer `script/ide/Locale.lua`.

| File | Bundle |
|------|--------|
| `IDE-{zhCN,enUS}.lua` | IDE strings |
| `ParaWorld-{zhCN,enUS}.lua` | ParaWorld strings |
| `ParaworldMCML-{zhCN,enUS}.lua` | MCML UI strings |
| `KidsUI-{zhCN,enUS}.lua` | Kids UI (EBook) |

Usage:

```lua
L = CommonCtrl.Locale("ParaWorld")
-- or in code: L"translatable string"
```

CLI: `-lang enUS` / `-lang zhCN` via `ParaEngine.SetLocale()`

## EBook (`script/EBook/` — 6 files)

In-engine e-book reader with SQLite storage.

| File | Role |
|------|------|
| `EBook.lua` | Main window `EBook.Show()` |
| `EBook_db.lua` | SQLite book database |
| `EBook_MainMenu.lua` | Main menu |
| `EBook_MediaMenu.lua` | Audio/video controls |
| `ImageViewer.lua` | Image pages |
| `PopupEditor.lua` | Inline editor |

Uses `CommonCtrl.Locale("KidsUI")`. Supports zipped books (`EBook.bIsZipBook` disables editing).

## Demo (`script/demo/` — 26 files)

Legacy ParaEngine SDK demo bar (pre-Paracraft):

| Subdir | Role |
|--------|------|
| `object/` | Object create/manage UI |
| `film/` | Movie recording (actions, spells, sounds, actors) |
| `skill/` | Magic casting demo |
| `state/` | State/skill/item forms |
| `mapediter/` | Terrain editing |
| `recorder/` | Recorder window |
| `setting/` | Settings |
| Root | `main_window.lua`, `create_player.lua`, `create_zoo.lua`, `esc.lua` |

Underpins concepts later formalized in Paracraft Creator.

## Movie library (`script/movie/` — 5 files)

Core movie timeline API used by CodeBlock movie-clip programming:

| File | Role |
|------|------|
| `movielib.lua` | `_movie` global — actors, cameras, timeline |
| `ActorMovieCtrl.lua` | Actor controller |
| `ClipMovieCtrl.lua` | Clip controller |
| `VideoPlayerCtrl.lua` | Video playback |
| `default.lua` | Default config |

Related: `ide/Director/`, `ide/Animation/`, `kids/3DMapSystemUI/Movie/`

## Installer (`script/installer/` — 15 files)

NSIS build pipeline for ParaWorld, Taurus SDK, Aries/Paracraft.

```lua
NPL.load("(gl)script/installer/BuildParaWorld.lua");
commonlib.BuildParaWorld.BuildAll()
```

Pipeline: compile NPL → `/bin` → rebuild zip packages → encrypt `.pkg` → run NSIS.

| File | Product |
|------|---------|
| `config_paraworld_release_{zhCN,enUS}.txt` | ParaWorld viewer |
| `config_taurus_release_{zhCN,enUS}.txt` | Taurus SDK |
| `config_aries_release_{zhCN,enUS}.txt` | Aries/Paracraft |
| `mainstate_paraworld_zhCN.lua` | Installer state machine |
| `MSI.nsh`, `DotNet.nsh` | NSIS includes |
| `GenVisualStudioDocProject.lua` | VS doc project |
| `License_{zhCN,enUS}.txt` | License |
| `website.html`, `haqi2.html` | Installer web assets |

## Tests

| Location | Files | Role |
|----------|-------|------|
| `test/` (repo root) | 4 | Root Lua unit tests |
| `script/test/` | ~79 | Engine/GUI/network tests |
| `script/ide/UnitTest/` | Framework | Unit test framework |
| `script/ide/test/` | Various | IDE tests |

## Visual Studio NPL (`script/VisualStudioNPL/`)

VS integration for NPL development. Excluded from shipping `main_script`.

## NPL mod sample (`npl_mod/`)

Sample NPL package layout for custom mods. Related: `Creator/Game/NplMod/NplModNode.lua`

## AI templates

See [AI NPC Templates](ai-npc-templates.md) — `script/AI/templates/`

## See also

- [Packages and Build](packages-and-build.md)
- [Legacy Client Networking](legacy-client-networking.md)
- [Overview](overview.md)
