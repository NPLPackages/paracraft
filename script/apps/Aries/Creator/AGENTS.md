# AGENTS.md — `script/apps/Aries/Creator/`

**Paracraft Creator shell** — toolbar, world helpers, Keepwork HttpAPI — plus the `Game/` simulation engine.

Master index: [aries/creator.md](../../../../docs/aries/creator.md) · Product: [paracraft.md](../../../../docs/paracraft.md) · [CODEMAP](../../../../docs/CODEMAP.md)

## Most important child

**[`Game/AGENTS.md`](Game/AGENTS.md)** — Paracraft simulation root (GameLogic / BlockEngine / Entity / Tasks / Code / Network).

## This folder (shell)

| Path | Role | Doc |
|------|------|-----|
| `Game/` | Simulation engine | [creator-game-engine.md](../../../../docs/aries/creator-game-engine.md) |
| `HttpAPI/` | Keepwork semantic HTTP | [creator-httpapi.md](../../../../docs/aries/creator-httpapi.md) |
| `MainToolBar*`, `MainSideBar*` | Creator chrome | [creator-ui-areas.md](../../../../docs/aries/creator-ui-areas.md) |
| `WorldCommon.lua` | Shared world path helpers | creator.md |
| `Pages/`, `Env/`, root `*.html` | Standalone pages / env | creator-ui-areas |

## Where to put work

| Change | Prefer |
|--------|--------|
| Gameplay / voxels / entities / tasks | `Game/` (see Game AGENTS) |
| Keepwork API wrappers | `HttpAPI/` |
| Top-level editor chrome | Root shell files here |
| Shared Blockly UI framework | `script/ide/System/` |

Parent: [Aries/AGENTS.md](../AGENTS.md)
