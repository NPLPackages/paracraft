# GI Sample Apps

Sample games built on **Game Inventor (GI)** in `Mod/GeneralGameServerMod/GI/App/`.

Framework: [mods.md](mods.md) | GGS: [ggs-deep.md](ggs-deep.md)

## GI stack recap

- Vue HTML/CSS/Lua UI
- Blockly visual programming
- Aggregated world APIs (build, network, entities)

## Sample apps

| App | Path | Description |
|-----|------|-------------|
| **sunzibingfa** | `GI/App/sunzibingfa/` | Sun Tzu strategy game — 28 levels, wolves, tigers, hunters, arrow towers |
| **lajifenlei** | `GI/App/lajifenlei/` | Garbage sorting education game |
| **PVZ** | `GI/App/PVZ/` | Plants vs Zombies style demo |
| **ParaLife** | `GI/App/ParaLife/` | Life simulation (codeblock, entertainment) |
| **AI** | `GI/App/AI/` | AI teaching with Lua Blockly editor |

## sunzibingfa (孙子兵法)

Largest sample (~30 level files):

```
sunzibingfa/
├── main.lua
├── Readme.md
├── GoodsConfig.lua
├── Entity/     Entity.lua, EntityWolf, EntityTiger, EntityHunter, EntitySunBin, EntityArrowTower
└── Level/      Level1.lua … Level28.lua, LevelN.lua, API.lua
```

Entry: `GI/App/sunzibingfa/main.lua`

## lajifenlei (垃圾分类)

Garbage classification education:

- `main.lua`, `Garbage.lua`, `Trash.lua`, `Config.lua`, `Net.lua`
- UI: `ui/start.html`
- Readme: `Readme.md`

## PVZ

- `main.lua`, `Entity.lua`, `Config.lua`
- UI: `pvz.html`, `tip.html`

## ParaLife

- `main.lua`, `codeblock.lua`, `entertainment.lua`

## AI app

- `main.lua`, `LuaBlocklyEditor.lua`
- UI: `UI/BlocklyEditor.html`, `UI/Console.html`
- Readme: `Readme.md`, `Lua.md`

## GI Independent lib

Reusable without full GGS server:

```
GI/Independent/
├── Lib/        GGS.lua, Entity.lua, API.lua, RPC.lua
├── API/        PlayerAPI.lua
└── Example/    UI.lua, Movie.lua, API.lua
```

## Running samples

Typically via GGS tutorial environment (`Tutorial/readme.md`) after `upgrade.sh`.

## See also

- [Code System](../../aries/code-system.md)
- [IDE Framework](../ide-framework.md) — Vue, Blockly
