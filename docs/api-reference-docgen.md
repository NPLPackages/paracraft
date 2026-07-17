# API Reference Docgen

Machine-readable API documentation configs in `Documentation/`. Used to generate HTML/API reference from Lua source — complementary to this wiki.

## Files

| File | Purpose |
|------|---------|
| `paracraft.docgen.xml` | **Paracraft API** — BlockEngine, EntityManager, CodeAPI functions (~6300+ lines) |
| `paracraft.docgen.txt` | Text companion |
| `NplDocumentation.xml` | General NPL API documentation |
| `NplPageDoc.xml` | Page-level doc config |
| `npl_package_main.docgen.xml` | Main package API docgen |
| `npl_package_main.docgen.txt` | Text companion |

## paracraft.docgen.xml structure

XML tables map source files to documented functions:

```xml
<doc>
  <tables>
    <table name="BlockEngine" src="script/apps/Aries/Creator/Game/block_engine.lua">
      <function line="82" name="SetGameLogic">
        <summary>function BlockEngine:SetGameLogic(game_logic)
        set the current game logic to use.</summary>
        <parameter name="game_logic"/>
      </function>
      ...
    </table>
  </tables>
</doc>
```

### Documented modules (sample from docgen)

The docgen file covers major Paracraft APIs including:

- `BlockEngine` — voxel operations, region load/save
- Entity and game logic functions
- Code block APIs

For humans/AI: when exploring an API, **cross-reference** docgen summaries with actual source files — docgen may lag behind code.

## Using docgen with this wiki

| Need | Start here | Then |
|------|------------|------|
| Architecture overview | `docs/overview.md` | — |
| BlockEngine concepts | `docs/aries/creator-game-engine.md` | `paracraft.docgen.xml` BlockEngine table |
| Function signatures | `Documentation/paracraft.docgen.xml` | Source `.lua` file |
| Coding patterns | `docs/npl-and-modules.md` | `.github/instructions/paracraft.instructions.md` |

## PETools NPL function list

`script/PETools/Common/NPLDocument/NPLfuncGenXml.lua` + `NPLfunclist.table` — generates NPL callable function lists for tool integration.

## See also

- [Paracraft](paracraft.md)
- [Creator Game Engine](aries/creator-game-engine.md)
- [PETools and Entity Pipeline](petools-and-entities.md)
