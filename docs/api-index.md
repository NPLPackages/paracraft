# Paracraft API Index

Quick reference to documented APIs in `Documentation/paracraft.docgen.xml`. For full signatures and parameter docs, read the docgen XML or source files.

**Full docgen:** `Documentation/paracraft.docgen.xml` (~6300 lines)

## Documented modules

| Module | Source file | Domain |
|--------|-------------|--------|
| **BlockEngine** | `Creator/Game/block_engine.lua` | Voxel grid, regions, block get/set |
| **GameLogic** | `Creator/Game/game_logic.lua` | Game loop singleton |
| **CmdParser** | `Creator/Game/Commands/CmdParser.lua` | Command parsing |
| **CommandManager** | `Creator/Game/Commands/CommandManager.lua` | Command dispatch |
| **EntityManager** | `Creator/Game/Entity/EntityManager.lua` | Entity registry, spawn |
| **Entity** | `Creator/Game/Entity/Entity.lua` | Base entity class |
| **ItemClient** | `Creator/Game/Items/ItemClient.lua` | Client item handling |
| **Item** | `Creator/Game/Items/Item.lua` | Item base class |
| **ItemStack** | `Creator/Game/Items/ItemStack.lua` | Item stacks |
| **block_types** | `Creator/Game/blocks/block_types.lua` | Block type registry |
| **block_model** | `Creator/Game/blocks/block_types.lua` | Block models |
| **block** | `Creator/Game/blocks/block.lua` | Base block class |
| **Files** | `Creator/Game/Common/Files.lua` | File I/O helpers |
| **World** | `Creator/Game/World/World.lua` | World management |
| **SelectionManager** | `Creator/Game/SceneContext/SelectionManager.lua` | Editor selection |
| **BaseContext** | `Creator/Game/SceneContext/BaseContext.lua` | Scene context base |

## BlockEngine key methods (sample)

From docgen — see source for complete list:

| Method | Purpose |
|--------|---------|
| `SetGameLogic(game_logic)` | Attach game logic |
| `Connect()` | Connect to engine block terrain |
| `OnBeforeLoadBlockRegion()` | Hook before async region load |
| `OnSaveBlockRegion()` | Region save hook |
| `IsRegionLoaded(x,y)` | Region load state |
| `SetRegionLoaded(x,y, loaded)` | Set region state |
| `OnLoadBlockRegion()` | Region loaded callback |
| `GetBlock(x,y,z)` / `SetBlock(...)` | Voxel access |

## Namespace quick reference

```lua
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Entity = commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local World = commonlib.gettable("MyCompany.Aries.Game.World");
```

## CodeAPI modules (not in docgen — see Code System)

| Module | File |
|--------|------|
| CodeAPI | `Code/CodeAPI.lua` |
| Events | `Code/CodeAPI_Events.lua` |
| Motion/Looks | `Code/CodeAPI_MotionLooks.lua` |
| Sensing | `Code/CodeAPI_Sensing.lua` |
| Sound | `Code/CodeAPI_Sound.lua` |
| Data | `Code/CodeAPI_Data.lua` |
| Control | `Code/CodeAPI_Control.lua` |

## Other docgen configs

| File | Scope |
|------|-------|
| `Documentation/NplDocumentation.xml` | General NPL API |
| `Documentation/npl_package_main.docgen.xml` | Main package APIs |
| `Documentation/NplPageDoc.xml` | Page-level docs |

## PETools function list

`script/PETools/Common/NPLDocument/NPLfuncGenXml.lua` generates callable NPL function lists for tool integration.

## See also

- [API Reference Docgen](api-reference-docgen.md)
- [Creator Game Engine](aries/creator-game-engine.md)
- [Code System](aries/code-system.md)
- `.github/instructions/paracraft.instructions.md`
