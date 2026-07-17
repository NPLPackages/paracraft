# Creator Block Types

All block classes in `Creator/Game/blocks/` (~54 files). Registry: `block_types.lua`. **XML data:** [config/Aries/creator/block_types.xml](../config/aries-creator.md).

Namespace: `MyCompany.Aries.Game.block`, `MyCompany.Aries.Game.block_types`

Parent: [creator.md](creator.md) | Engine: [creator-game-engine.md](creator-game-engine.md)

## Base classes

| File | Role |
|------|------|
| `block.lua` | Base block class |
| `block_types.lua` | ID → class registry, models |
| `BlockEntityBase.lua` | Blocks with entity counterparts |
| `BlockLogic.lua` | Logic/redstone-like blocks |
| `BlockPowered.lua` | Powered block base |
| `BlockDynamic.lua` | Dynamic blocks |
| `TextureAtlasRectPacker.lua` | Texture atlas packing |

## Block catalog

| Block class | Category |
|-------------|----------|
| `BlockGrass` | Terrain |
| `BlockSlope` | Terrain shape |
| `BlockSlab` | Half blocks |
| `BlockStair` | Stairs |
| `BlockFence` | Fence |
| `BlockCarpet` | Thin cover |
| `BlockSponge` | Sponge |
| `BlockLiquidStill`, `BlockLiquidFlow` | Fluids |
| `BlockTorch`, `BlockElectricTorch` | Light sources |
| `BlockLight`, `BlockElectricLight` | Electric lighting |
| `BlockChest` | Storage |
| `BlockSign` | Signs |
| `BlockNote`, `BlockMusicBox` | Audio blocks |
| `BlockButton`, `BlockLever`, `BlockPressurePlate` | Input |
| `BlockWire` | Redstone wire |
| `BlockRepeater` | Signal repeater |
| `BlockConductor`, `BlockConductorUp` | Conductors |
| `BlockRailBase`, `BlockRailPowered`, `BlockRailDetector` | Rails |
| `BlockPiston`, `BlockPistonMoving`, `BlockPistonExtension` | Pistons |
| `BlockTNT` | Explosives |
| `BlockTrapDoor` | Trapdoors |
| `BlockTeleportStone` | Teleport |
| `BlockCommandBlock` | Commands |
| `BlockCode` | Code block anchor |
| `BlockMemory` | Memory/MOP block |
| `BlockModel`, `BlockAnimModel` | Custom models |
| `BlockImage` | Image blocks |
| `BlockBone` | Bone rig blocks |
| `BlockPlant`, `BlockSapling`, `BlockVine`, `BlockLilypad` | Plants |
| `BlockArrow` | Arrows |
| `BlockItemFrame` | Item display |
| `BlockCollisionSensor` | Collision triggers |
| `BlockBlockUpdateDetector` | Update detectors |
| `BlockEntityBase` | Entity-linked |

## Materials (`Materials/`)

Material properties (hardness, texture mapping) used by block rendering.

## Block ↔ Entity pairing

Many blocks have matching entities in [creator-entities.md](creator-entities.md):

| Block | Entity |
|-------|--------|
| BlockChest | EntityChest |
| BlockSign | EntitySign |
| BlockCode | EntityCode / EntityBlockCodeBase |
| BlockMemory | EntityMemory |
| BlockCommandBlock | EntityCommandBlock |

## API

```lua
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local id = BlockEngine:GetBlock(x, y, z);
BlockEngine:SetBlock(x, y, z, blockId);
```

Docgen: [api-index.md](../api-index.md) — BlockEngine, block, block_types

## See also

- [code-system.md](code-system.md) — BlockCode, movie blocks
- [creator-network.md](creator-network.md) — PacketBlockChange (37)
