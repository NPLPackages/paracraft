# Memory and Neuron (AI Systems)

Advanced AI/scripting subsystems in `Creator/Game/Memory/` and `Creator/Game/Neuron/`. Distinct from user-facing **CodeBlocks** — see comparison below.

## Three programming models compared

| Model | Location | User level | Concept |
|-------|----------|------------|---------|
| **CodeBlock** | `Code/` | Primary (education) | Visual blocks on movie blocks; coroutine sandbox |
| **Neuron** | `Neuron/` | Advanced | Spatial graph of script blocks with axon/dendrite connections |
| **Memory** | `Memory/` | Research/AI | Time-series memory clips drive autonomous avatar animation |

```
CodeBlock  ──► user teaches actors explicit behaviors
Neuron     ──► spatial programming graph in world XML
Memory     ──► AI brain replays clips when attention patterns match
```

## Memory system (`Memory/` — 20 files)

Namespace: `MyCompany.Aries.Game.Memory.*`

From `Memory/readme.md`:

> In Paracraft AI, Memory is an infinite spacetime sequence collection without absolute time origin. Hippocampus (high neuron-density brain region) relates to long-term memory.

### Key files

| File | Role |
|------|------|
| `MemoryContext.lua` | **Entry** — per-entity AI brain |
| `MemoryClip.lua` | Single memory clip (time-series) |
| `MemoryActor.lua`, `MemoryActor*.lua` | Actor memory bindings |
| `PlayerContext.lua` | Player-specific context |
| `VisionContext.lua` | Visual attention input |
| `AttentionBase.lua`, `AttentionBlock.lua`, `AttentionEntity.lua` | Attention system |
| `Pattern.lua`, `Pattern*.lua` | Pattern matching for clip replay |
| `NormalWorld.lua`, `NormalBlock.lua` | World/block normal states |

### Concepts

- **MemoryContext** = per-entity brain; clips replay when attention patterns match
- "Movie drives reality" — movie blocks trigger real-world actions
- Emotion controls replay threshold
- Working memory decays to long-term clips
- Integrates with BlockEngine and EntityManager

Block type: `blocks/BlockMemory.lua`

## Neuron system (`Neuron/` — 22 files)

Namespace: `MyCompany.Aries.Game.Neuron.*`

From `Neuron/readme.txt`:

Neurons stored as XML `<neurons>` with position, script filename, axon/dendrite graph.

### Key files

| File | Role |
|------|------|
| `NeuronManager.lua` | Neuron registry |
| `NeuronBlock.lua` | Neuron block entity |
| `NeuronSimulator.lua` | Simulation runner |
| `NeuronAPISandbox.lua` | Isolated script scope |
| `EditNeuronBlockPage.*` | In-world editor UI |
| `CreateNewNeuronScriptFile.*` | New script wizard |
| `Cell/CellBlock.lua` | Cell block type |
| `Cell/CellBlock_Tree.lua` | Tree cell |
| `Cell/CellBlock_Terrain.lua` | Terrain cell |
| `Templates/*.lua` | Starter templates |
| `Mod/MovieText.*` | Movie text mod |

### Script storage

Scripts live at:

```
[world_dir]/scripts/block/<filename>
```

Each block has **isolated scope**. `main(msg)` called on activation. Global vars accessible by block position.

### Cell types

- `CellBlock` — generic neuron cell
- `CellBlock_Tree` — tree-structured
- `CellBlock_Terrain` — terrain-linked

UI tasks namespace: `MyCompany.Aries.Game.Tasks.*` (EditNeuron pages)

## See also

- [Code System](aries/code-system.md)
- [Code Blocks and Visual Programming](code-blocks-and-visual-programming.md)
- [Creator Game Engine](aries/creator-game-engine.md)
- Source: `Memory/readme.md`, `Neuron/readme.txt`, `Neuron/Cell/readme.txt`
