# Creator Game Engine

Deep dive into `script/apps/Aries/Creator/Game/` — the Paracraft simulation engine (~2000 files).

Entry: `main.lua` → `Game.Start()` → `GameLogic`

## Core singletons

| Module | Namespace | File |
|--------|-----------|------|
| GameLogic | `MyCompany.Aries.Game.GameLogic` | `game_logic.lua` |
| BlockEngine | `MyCompany.Aries.Game.BlockEngine` | `block_engine.lua` |
| EntityManager | `MyCompany.Aries.Game.EntityManager` | `Entity/EntityManager.lua` |
| block_types | `MyCompany.Aries.Game.block_types` | `blocks/block_types.lua` |
| GameDesktop | `MyCompany.Aries.Creator.Game.Desktop` | `GameDesktop.lua` |
| PlayerController | `MyCompany.Aries.Game.PlayerController` | `PlayerController.lua` |

## BlockEngine

Voxel grid manager. Coordinates two spaces:

```lua
local bx, by, bz = BlockEngine:block(x, y, z);   -- block coords
local rx, ry, rz = BlockEngine:real(bx, by, bz); -- world coords

local blockId = BlockEngine:GetBlock(bx, by, bz);
BlockEngine:SetBlock(bx, by, bz, blockId);
```

### Block types (`blocks/`)

Each block type is a Lua class:

| Block | File | Notes |
|-------|------|-------|
| Base | `block.lua` | Base block class |
| Chest | `BlockChest.lua` | Storage |
| Memory | `BlockMemory.lua` | Memory block (MOP) |
| Electric light | `BlockElectricLight.lua` | Redstone-like |
| Rail detector | `BlockRailDetector.lua` | Rail logic |
| … | 50+ files | See `blocks/` directory |

Block registry: `block_types.lua` maps IDs to classes.

Texture packing: `TextureAtlasRectPacker.lua`

## Entity system (`Entity/`)

| Entity | Purpose |
|--------|---------|
| `Entity.lua` | Base entity |
| `EntityManager.lua` | Registry, spawn, query |
| `EntityPlayer` | Player avatar |
| `EntityNPC` | NPCs |
| `EntityCamera` | Cameras for code blocks |
| `EntitySnowEffect` | Weather effects |
| `PlayerAssetFile.lua` | Player model assets |
| `PlayerSkins.lua` | Skin definitions |
| `CustomCharItems.lua` | Customization items |

```lua
local player = EntityManager:GetPlayer();
local npc = EntityManager:GetEntity("my_npc_name");
```

Entity data persists in world XML and `GameLevel.xml`.

## Game loop

`game_logic.lua` orchestrates:

- Task scheduling (`Tasks/`)
- Input handling
- Save/autosave
- Mode switching (edit, play, network)
- Frame updates

`Game.OnStaticInit()` in `main.lua` initializes physics, sounds, skins, animations once at startup.

## World access (`World/`)

| File | Role |
|------|------|
| `WorldBlockAccess.lua` | Block read/write permissions |
| Camera controllers | `Code/CameraBlocklyDef/Cameras.lua` |

Default terrain height: `ParaTerrain` default `-1000` (set in main.lua).

## Items (`Items/`)

In-world item entities (distinct from Haqi inventory):

- `ItemLight.lua`, `ItemInvisibleBlock.lua`
- `ItemAgent.lua`, `ItemTimeSeriesLight.lua`

## Physics (`Physics/`)

- `DamageSource.lua` — Damage system static init

## Commands (`Commands/`)

- `CommandDetect.lua` — Command block detection

## GUI (`GUI/`)

Creator overlay controls:

- `Transform3DController.lua`
- `OpenAssetFileDialog.html`

## Shaders (`Shaders/`)

Custom effects e.g. `mrt_bmax_model.fx`

## Settings

- `Setting/ServerSetting.lua` — Server configuration UI

## Tasks subsystem (`Tasks/`)

Feature modules plugged into GameLogic:

| Directory | Feature |
|-----------|---------|
| `EasyBuilder/` | Guided building |
| `ParaLife/` | Life simulation mode |
| `ParaWorld/` | Community/world sharing |
| `MiniGame/` | Mini-game hub |
| `BuildReplay/` | Session recording |
| `Community/` | Community features |
| `EditCodeActor/` | Code block editor in world |
| `EditModel/` | 3D model manipulation |
| `AutoSaveTask/` | Autosave |
| `BlockFileMonitorTask/` | File watch |
| `DestroyBlockTask/` | Block destruction |
| `FollowBlocksTask/` | Follow-camera blocks |
| `NoticeV2/` | Notifications |
| `Friend/` | Friend chat in Creator |

## Network integration

See [Game Server and Networking](../game-server-and-networking.md).

Key: `Network/Packets/PacketBlockMultiChange.lua` for voxel sync.

## Memory / Neuron (AI)

Advanced AI subsystems:

- `Memory/readme.md` — Memory-oriented programming (MOP), Hippocampus metaphor
- `Neuron/` — Neural cell blocks (`Cell/CellBlock.lua`)
- `Neuron/readme.txt`, `Neuron/Cell/readme.txt`

## Educate / Login

- `Educate/Login/` — Mobile login pages for education
- `Login/` — Creator login flow, `ClientUpdater430.lua`, `PrepareApp.lua`

## Android / MQTT / IoT

- `Android/Android.lua` — Android-specific
- `Mqtt/MqttApi.lua` — MQTT device integration

## Macros

- `Macros/MacroPlayerMove.lua` — Player movement macros
- `Macros/ConvertToWebMode/` — Web export

## Static init sequence

From `main.lua` `Game.OnStaticInit()`:

1. DamageSource static init
2. PlayerAssetFile, PlayerSkins, CustomCharItems
3. SoundManager
4. EntityAnimation effects
5. Terrain default height

## World paths

Default user worlds: `worlds/DesignHouse/userworlds/`

Command-line world: `world="worlds/DesignHouse/test"`

## See also

- [Paracraft](../paracraft.md)
- [Code Blocks](../code-blocks-and-visual-programming.md)
- [NPL and Modules](../npl-and-modules.md)
- `Creator/readme.txt` — GameLevel.xml, mob spawning rules
