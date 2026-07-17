# Documentation Scan Log

**Last updated:** 2026-07-14 (iteration 6 — agent wiki hubs)

## Status: COMPLETE

All major code areas documented. Runtime `config/Aries/` data documented from code references (not present in script repo).

**LLM wiki layer:** [README.md](README.md) · [CODEMAP.md](CODEMAP.md) · [TOPIC-INDEX.md](TOPIC-INDEX.md) · nested `AGENTS.md` under major code roots.

## Coverage matrix

| Area | Status | Primary doc |
|------|--------|-------------|
| `Creator/` shell | `[x]` | aries/creator.md |
| `Creator/Game/` (49 subdirs) | `[x]` | aries/creator-game-subsystems.md |
| `Creator/Game/Tasks/` (62 modules) | `[x]` | aries/creator-tasks.md |
| `Creator/Game/blocks/` (54 types) | `[x]` | aries/creator-blocks.md |
| `Creator/Game/Entity/` (54 types) | `[x]` | aries/creator-entities.md |
| `Creator/HttpAPI/` | `[x]` | aries/creator-httpapi.md |
| `Creator/Game/Code/` | `[x]` | aries/code-system.md |
| `Creator/Game/Network/` | `[x]` | aries/creator-network.md |
| `Creator/Game/Memory, Neuron` | `[x]` | memory-and-neuron.md |
| `Creator/Game/Areas, GUI, Login, …` | `[x]` | creator-ui-areas, login-education, integrations |
| `script/apps/Aries/` (53 modules) | `[x]` | haqi-aries, modules-reference, quest, combat |
| `script/kids/` (12 subdirs) | `[x]` | kids-subsystems.md |
| `script/ide/` | `[x]` | ide-subsystems.md |
| `script/apps/` (14 apps) | `[x]` | applications-catalog + apps/* |
| `Mod/` (3 mods + GI apps) | `[x]` | mods/*, worldshare-cellar |
| Networking (4 stacks) | `[x]` | networking-stacks.md + 4 pages |
| `script/network/`, `server/`, `movie/` | `[x]` | legacy-client-networking, supporting-modules |
| `script/AI/`, `PETools/` | `[x]` | ai-npc-templates, petools-and-entities |
| `packages/`, `installer/` | `[x]` | main-package, packages-and-build |
| `Documentation/` docgen | `[x]` | api-index.md |
| `tutorials/`, `sqlite/`, `lang/`, `EBook/`, `demo/` | `[x]` | supporting-modules.md |
| `test/`, `npl_mod/`, `VisualStudioNPL/` | `[x]` | supporting-modules.md |
| `script/bin/` | `[x]` | packages-and-build.md (build artifacts) |
| `.github/instructions/` | `[x]` | README references |
| **`config/Aries/creator/`** | `[x]` | config/aries-creator.md (from code refs) |
| **`config/Aries/` (Haqi)** | `[x]` | config/aries-haqi-data.md |

## Wiki inventory (47 pages)

### Root (18)
README, SCAN_LOG, overview, main-package, paracraft, haqi-aries, paraworld-platform, ide-framework, ide-subsystems, kids-subsystems, npl-and-modules, mcml-ui, packages-and-build, config-and-environment, networking-stacks, game-server-and-networking, jgsl-networking, legacy-client-networking, applications-catalog, mods, worldshare-cellar, memory-and-neuron, code-blocks, api-index, api-reference-docgen, petools, ai-npc-templates, mobile-paracraft, supporting-modules

### aries/ (16)
creator, creator-game-subsystems, creator-tasks, creator-blocks, creator-entities, creator-game-engine, code-system, creator-network, creator-httpapi, creator-ui-areas, creator-login-education, creator-integrations, client-features, quest-system, combat-system, modules-reference

### apps/ (3)
webserver, aquarius, backend-servers

### mods/ (3)
ggs-deep, gi-sample-apps, explorer-app

### config/ (2)
aries-creator, aries-haqi-data

## Out of repo scope (file bytes not in repo)

| Item | Reason |
|------|--------|
| External art/texture packages | Referenced in packages/redist manifests |
| Per-packet binary field layouts | 53 files; IDs in creator-network.md |
| NSIS main `.nsi` entry | Not in script/installer/ |
| `config/EmuUsersDB.xml` | Runtime install |
| Actual XML content of `config/Aries/` | Lives in product install; **structure documented** in config/ |

## Iteration history

| Iter | Focus |
|------|-------|
| 1 | Core architecture, main package, Haqi, Paracraft overview |
| 2 | PETools, AI templates, mobile, docgen intro |
| 3 | Networking stacks, Quest, Combat, cellar, SCAN gaps |
| 4 | **Full Creator/ tree**, kids/ide deep indexes, apps/mods completion |
| 5 | **`config/Aries/creator/`** + Haqi config from code cross-refs |
| 6 | **Wiki for LLMs:** CODEMAP, TOPIC-INDEX, README portal, nested AGENTS.md hubs |

## Iteration 5 scanned

- All `grep config/Aries/creator` references (~40 source files)
- `block_types.lua`, `PlayerAssetFile.lua`, `ItemClient.lua`, `BuildQuestProvider.lua`
- `packages/redist/main_script_paracraft-1.0.txt` include/exclude rules
- `xgettext.lua` translatable file list
