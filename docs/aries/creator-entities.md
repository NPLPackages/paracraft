# Creator Entity Types

Entity classes in `Creator/Game/Entity/` (~54 `Entity*.lua` files + support files).

Registry: `EntityManager.lua` | Namespace: `MyCompany.Aries.Game.EntityManager.*`

Parent: [creator.md](creator.md)

## Manager & support

| File | Role |
|------|------|
| `EntityManager.lua` | Spawn, query, tick all entities |
| `Entity.lua` | Base entity class |
| `EntityPool.lua` | Object pooling |
| `PlayerAssetFile.lua` | Player model assets |
| `PlayerSkins.lua` | Skin definitions |
| `CustomCharItems.lua` | Customization items |

## Player entities

| Entity | Role |
|--------|------|
| `EntityPlayer` | Local player |
| `EntityPlayerMP` | Multiplayer player (server) |
| `EntityPlayerMPClient` | MP player (client) |
| `EntityPlayerMPOther` | Other players |
| `EntityPlayerGSL` | GSL-connected player |
| `EntityPlayerCCS` | CCS customization player |
| `EntityDesktop` | Desktop overlay entity |

## NPCs & mobs

| Entity | Role |
|--------|------|
| `EntityNPC` | NPC actors |
| `EntityMob` | Hostile/neutral mobs |
| `EntityMovable` | Physics-movable objects |
| `EntityAnimCharacter` | Animated characters |
| `EntityLiveModel` | Live animated models |

## Code & logic

| Entity | Role |
|--------|------|
| `EntityCode` | Code block actor |
| `EntityBlockCodeBase` | Code block base |
| `EntityCommandBlock` | Command block |
| `EntityMemory` | Memory AI entity |
| `EntityMovieClip` | Movie clip host |
| `EntityCadEditor` | NPL CAD editor |
| `EntityNplCadEditor` | CAD editor variant |

## World objects

| Entity | Role |
|--------|------|
| `EntityChest` | Chest storage |
| `EntitySign` | Sign text |
| `EntityNote` | Note block |
| `EntityMusicBox` | Music box |
| `EntityItem` | Dropped items |
| `EntityItemFrame` | Item frame display |
| `EntityImage` | Image plane |
| `EntityBlockModel` | Block-based model |
| `EntityBlockPiece` | Block piece |
| `EntityBlockBone` | Bone block |
| `EntityBlockDynamic` | Dynamic block entity |
| `EntityRailcar` | Rail cart |

## Sensors & interaction

| Entity | Role |
|--------|------|
| `EntityCollisionSensor` | Collision trigger |
| `EntityInvisibleClickSensor` | Invisible click zone |
| `EntityCheckpoint` | Checkpoint |
| `EntityHomePoint` | Spawn/home point |
| `EntityUserPoint` | User waypoint |
| `EntityAgentSign` | Agent sign |
| `EntityCollectable` | Collectible pickup |
| `EntityThrowBall` | Throwable ball |

## Camera & environment

| Entity | Role |
|--------|------|
| `EntityCamera` | Code block cameras |
| `EntitySky` | Sky dome |
| `EntityLight` | Point light |
| `EntityLightChar` | Character light |
| `EntityOverlay` | Screen overlay |
| `EntitySnowEffect` | Snow weather |
| `EntityRainEffect` | Rain weather |
| `EntityWeatherEffect` | Weather base |

## Edit mode

| Entity | Role |
|--------|------|
| `Entity.EditModel` | Model edit manipulator |

## API

```lua
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local player = EntityManager:GetPlayer();
local ent = EntityManager:GetEntity("name");
```

Docgen: [api-index.md](../api-index.md) — EntityManager, Entity

## Network sync

Entities replicate via packets 4–5, 19–29, 33–35, 45–48 in [creator-network.md](creator-network.md).

## See also

- [creator-blocks.md](creator-blocks.md)
- [PETools](../petools-and-entities.md)
