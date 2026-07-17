# PETools and Entity Pipeline

**PETools** (`script/PETools/`) bridges **C# entity design tools** in Visual Studio / ParaEngine SDK with **NPL entity XML** used at runtime by Haqi and Paracraft.

~54 files. IPC binding: `script/ide/IPCBinding/`.

## Structure

```
script/PETools/
├── EntityTemplate.xml           # Base entity template
├── Common/NPLDocument/          # NPL function list generation
│   ├── NPLfunclist.table
│   └── NPLfuncGenXml.lua
├── Aries/                       # Haqi/Paracraft entities
│   ├── Card.entity.xml / .cs    # Combat cards
│   ├── Mob.entity.xml / .cs     # Monsters
│   ├── NPC.entity.xml / .cs     # NPCs
│   ├── GameObject.entity.xml    # Generic objects
│   ├── Wisp.entity.xml          # Wisp effects
│   ├── Arena.entity.xml         # Arena scenes
│   ├── Sound.entity.xml         # Audio sources
│   ├── AudioSource.entity.xml
│   ├── MobTemplate.entity.xml   # Mob templates
│   ├── MobCardsEditor.lua/html  # In-engine mob card editor
│   ├── ObjectInstancesEditor.*  # Object instance editor
│   └── ObjectTransformEditor.*
├── Buildin/                     # Engine builtins
│   ├── Scene.entity.xml / .cs
│   ├── Camera.entity.xml
│   ├── Terrain.entity.xml
│   ├── Sky.entity.xml
│   ├── Ocean.entity.xml
│   └── GlobalSettings.entity.xml
└── Taurus/
    └── EnvironmentPresets.entity.xml
```

## Entity file pairs

Each entity type typically has:

| File | Purpose |
|------|---------|
| `*.entity.xml` | Runtime entity schema (properties, scripts, assets) |
| `*.cs` | C# design-time class for PETools designer |
| `*.newinstance.html` | MCML wizard for creating new instances |
| `*.newinstance.html` + `.lua` | Editors (MobCardsEditor, ObjectInstancesEditor) |

## Haqi combat entities

Combat system entities:

```
PETools/Aries/Card.entity.xml     → Combat cards
PETools/Aries/Mob.entity.xml      → Combat mobs
PETools/Aries/MobTemplate.entity.xml
```

Referenced from:

- `script/apps/Aries/Combat/`
- `script/ide/MotionEx/MotionRender_SpellCastViewer.lua` (mob model paths like `character/v5/10mobs/HaqiTown/`)

## Code block storage

Paracraft code blocks store logic in **entity XML** attached to movie blocks in world files — not as separate `.lua` files. PETools defines the entity schemas that hold this data.

See [Code Blocks](code-blocks-and-visual-programming.md).

## IPC binding

`script/ide/IPCBinding/`:

- `Framework.lua` — IPC framework
- `EntityDesign.lua` — Entity design bridge
- `EntitySampleTemplate.cs` — Sample C# template

Allows Visual Studio NPL tools (`script/VisualStudioNPL/`) to edit entities and sync with runtime.

## NPL function documentation generation

`PETools/Common/NPLDocument/NPLfuncGenXml.lua` generates function lists from NPL sources — related to `Documentation/NplDocumentation.xml`.

## Buildin scene entities

`Buildin/` entities represent engine-level scene objects:

- Scene root, Camera, Terrain, Sky, Ocean
- Used across all apps, not just Aries

## See also

- [Haqi Client Features](aries/client-features.md) — Combat, NPCs
- [API Reference Docgen](api-reference-docgen.md)
- [IDE Framework](ide-framework.md) — IPCBinding
