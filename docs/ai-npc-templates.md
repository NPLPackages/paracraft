# AI NPC Templates

Reusable NPC behavior templates in `script/AI/templates/`. These are **sample AI scripts** for ParaWorld/Haqi NPCs, not a full pathfinding engine.

~16 files. Included in `main_script` package.

## Template list

| Template | File | Behavior |
|----------|------|----------|
| Random walker | `RandomWalker.lua` | Random movement |
| Line walker | `SimpleLineWalker.lua` | Walk along a line |
| Follow | `SimpleFollow.lua` | Follow target |
| Say hello | `SimpleSayHello.lua` | Greet players |
| Shop keeper | `ShopKeeper.lua` | Shop NPC logic |
| Green grocer | `GreenGrocer.lua` | Vendor variant |
| Joke teller | `JokeTeller.lua` | Tell jokes |
| Ghost storyteller | `GhostStoryTeller.lua` | Story NPC |
| Summoned agent | `SummonedAgent.lua` | Summoned creature |
| AI movie player | `AIMoviePlayer.lua` | Play movie sequences |
| Simple tutorial | `SimpleTutorial.lua` | Tutorial guide |
| Tutorial text | `TutorialText/BasicTutorial_part1–5.lua` | Multi-part tutorial |

## Usage pattern

Templates are typically referenced from NPC entity definitions or quest scripts. Load with standard NPL pattern:

```lua
NPL.load("(gl)script/AI/templates/RandomWalker.lua");
```

Haqi-specific NPC dialog and logic lives primarily in `script/apps/Aries/NPCs/` — templates here are generic starting points.

## Related systems

| System | Location | Role |
|--------|----------|------|
| Aries NPCs | `apps/Aries/NPCs/` | Production Haqi NPCs with MCML dialogs |
| Neuron/Memory | `Creator/Game/Neuron/`, `Memory/` | Advanced Paracraft AI |
| PETools mobs | `PETools/Aries/Mob.entity.xml` | Mob entity definitions |
| ide/AI.lua | `script/ide/AI.lua` | Framework AI helpers |

## See also

- [Haqi Client Features](aries/client-features.md) — NPCs section
- [Creator Game Engine](aries/creator-game-engine.md) — Neuron/Memory
- [PETools and Entity Pipeline](petools-and-entities.md)
