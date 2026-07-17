# Haqi Combat System

Turn-based card combat in `script/apps/Aries/Combat/`. Schools: fire, ice, storm, mystic, life, death, balance.

Namespace: `MyCompany.Aries.Combat.*`, `MyCompany.Aries.Combat_Server.*`

Note: `readme.txt` is mostly a stub — this page documents structure from source scan.

## Architecture

```
main.lua  (card/rune gsid mappings, school tables)
    ├── SpellCast.lua, SpellPlayer.lua
    ├── ObjectManager.lua, MsgHandler.lua
    ├── ServerObject/
    │   ├── combat_server.lua / combat_client.lua
    │   ├── CombatService.lua
    │   ├── card_server.lua, unit_server.lua, mob_server.lua
    │   ├── arena_server.lua, arena_pvp_server.lua
    │   └── AI_Modules/ (Simple_Attacker, Deck_Attacker, Genes_Attacker)
    ├── Battlefield/BattlefieldClient.lua
    ├── Team/worldteam_client.lua, worldteam_server.lua
    └── UI/  (cards, pets, runes, HP, loot, defeat screens)
```

## Entry

```lua
NPL.load("(gl)script/apps/Aries/Combat/main.lua");
```

`main.lua` defines bidirectional **gsid ↔ cardkey** mappings and school configuration tables.

## Server/client split

| Side | Path | Role |
|------|------|------|
| Server sim | `ServerObject/combat_server.lua` | Authoritative combat state |
| Client | `ServerObject/combat_client.lua` | Client prediction/display |
| Service | `ServerObject/CombatService.lua` | Facade for combat sessions |

## Entity types (server)

| Module | Role |
|--------|------|
| `card_server.lua` | Combat cards |
| `unit_server.lua` | Combat units |
| `mob_server.lua` | Mob entities |
| `arena_server.lua` | Arena instances |
| `arena_pvp_server.lua` | PvP arena |

## AI modules

`ServerObject/AI_Modules/`:

| Module | Behavior |
|--------|----------|
| `Simple_Attacker` | Basic attack AI |
| `Deck_Attacker` | Deck-based strategy |
| `Genes_Attacker` | Genetic/evolved strategy |

## Spell system

| File | Role |
|------|------|
| `SpellCast.lua` | Spell execution pipeline |
| `SpellPlayer.lua` | Per-player spell state |

Motion rendering uses Haqi mob models via `ide/MotionEx/MotionRender_SpellCastViewer.lua` (paths like `character/v5/10mobs/HaqiTown/`).

## Battlefield & teams

| Module | Role |
|--------|------|
| `Battlefield/BattlefieldClient.lua` | Battlefield UI controller |
| `Battlefield/BattlefieldHelpPage.*` | Help UI |
| `Team/worldteam_client.lua` | Team sync (client) |
| `Team/worldteam_server.lua` | Team sync (server) |

Related app modules:

- `CombatRoom/` — combat instances, lobby chat
- `CombatPet/` — combat pets

## UI (`UI/`)

Rich MCML UI for combat:

- MyCards, unit status tips, combat results
- Pet cards, runes, HP slots
- Defeat/victory screens
- Teen variants: `*_teen.html`

## PETools entities

Combat entity schemas in `script/PETools/Aries/`:

- `Card.entity.xml`, `Card.cs`
- `Mob.entity.xml`, `MobTemplate.entity.xml`
- `Arena.entity.xml`

Editors: `MobCardsEditor.lua/html`, `ObjectInstancesEditor.*`

## Integration at startup

Combat integrates with VIP and Player systems when Aries main loop loads combat module.

## See also

- [Haqi Client Features](client-features.md)
- [PETools and Entities](../petools-and-entities.md)
- [Haqi / Aries](../haqi-aries.md)
