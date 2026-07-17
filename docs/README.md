# Paraworld Wiki

Knowledge base for the **paraworld** repository (ParaEngine / NPL scripts for **Paracraft** and **Haqi**).

**Coverage:** complete for major trees — see [SCAN_LOG.md](SCAN_LOG.md).

---

## For LLMs and agents (read this first)

Navigation contract:

| Goal | Open |
|------|------|
| Enter the repo | [`/AGENTS.md`](../AGENTS.md) |
| Know a **code path** → find docs | **[CODEMAP.md](CODEMAP.md)** |
| Know a **topic/keyword** → find docs | **[TOPIC-INDEX.md](TOPIC-INDEX.md)** |
| Editing a folder | Nearest **`AGENTS.md`** in that tree (see [Agent hubs](#agent-hubs)) |
| Deep detail | Pages linked from CODEMAP / TOPIC-INDEX |

**Do not** scan the whole `script/` tree hoping for README files. Use CODEMAP, then the linked page, then source.

### Agent hubs (code-colocated)

| Hub | Covers |
|-----|--------|
| [AGENTS.md](../AGENTS.md) | Whole repo |
| [script/AGENTS.md](../script/AGENTS.md) | All scripts |
| [script/ide/AGENTS.md](../script/ide/AGENTS.md) | IDE framework |
| [script/ide/System/AGENTS.md](../script/ide/System/AGENTS.md) | `System.*` (UI, MCML, Blockly, Compiler) |
| [script/kids/AGENTS.md](../script/kids/AGENTS.md) | ParaWorld / Map3DSystem |
| [script/apps/AGENTS.md](../script/apps/AGENTS.md) | All apps |
| [script/apps/Aries/AGENTS.md](../script/apps/Aries/AGENTS.md) | Haqi + Paracraft client |
| [script/apps/Aries/Creator/AGENTS.md](../script/apps/Aries/Creator/AGENTS.md) | Creator shell |
| [script/apps/Aries/Creator/Game/AGENTS.md](../script/apps/Aries/Creator/Game/AGENTS.md) | Paracraft simulation engine |
| [Mod/AGENTS.md](../Mod/AGENTS.md) | WorldShare, GGS, ExplorerApp |

When documenting new code: update **CODEMAP** + **TOPIC-INDEX**, add or extend the nearest **AGENTS.md**, then write/extend the topic page.

---

## Start here (humans)

| | |
|---|---|
| New to repo | [overview.md](overview.md) |
| Paracraft Creator | [aries/creator.md](aries/creator.md) |
| Haqi MMO | [haqi-aries.md](haqi-aries.md) |
| Pick networking stack | [networking-stacks.md](networking-stacks.md) |
| API lookup | [api-index.md](api-index.md) |

---

## Creator / Paracraft

| Page | Content |
|------|---------|
| [aries/creator.md](aries/creator.md) | **Master index** — Creator shell + Game/ map |
| [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md) | All 49 `Game/` directories |
| [aries/creator-tasks.md](aries/creator-tasks.md) | All 62 `Tasks/` modules |
| [aries/creator-blocks.md](aries/creator-blocks.md) | 54 block types |
| [aries/creator-entities.md](aries/creator-entities.md) | 54 entity types |
| [aries/creator-game-engine.md](aries/creator-game-engine.md) | GameLogic, BlockEngine core |
| [aries/code-system.md](aries/code-system.md) | Code/, Blockly, CodeAPI |
| [aries/creator-network.md](aries/creator-network.md) | 53 TCP packets, TunnelService |
| [aries/creator-httpapi.md](aries/creator-httpapi.md) | Keepwork HttpAPI |
| [aries/creator-ui-areas.md](aries/creator-ui-areas.md) | Areas/, GUI/, shell UI |
| [aries/creator-login-education.md](aries/creator-login-education.md) | Login/, Educate/, Mobile |
| [aries/creator-integrations.md](aries/creator-integrations.md) | Mqtt, Movie, Shaders, platforms |
| [paracraft.md](paracraft.md) | Product overview |
| [code-blocks-and-visual-programming.md](code-blocks-and-visual-programming.md) | Execution model |
| [memory-and-neuron.md](memory-and-neuron.md) | Memory + Neuron AI |

---

## Haqi / Aries

| Page | Content |
|------|---------|
| [haqi-aries.md](haqi-aries.md) | Client overview, kids/teen |
| [aries/client-features.md](aries/client-features.md) | Desktop, NPCs, social |
| [aries/quest-system.md](aries/quest-system.md) | Quest architecture |
| [aries/combat-system.md](aries/combat-system.md) | Card combat |
| [aries/modules-reference.md](aries/modules-reference.md) | All 53 Aries modules |

---

## Platform & IDE

| Page | Content |
|------|---------|
| [paraworld-platform.md](paraworld-platform.md) | ParaWorld overview |
| [kids-subsystems.md](kids-subsystems.md) | All kids/ subsystems |
| [ide-framework.md](ide-framework.md) | IDE overview |
| [ide-subsystems.md](ide-subsystems.md) | All ide/ subsystems |
| [npl-and-modules.md](npl-and-modules.md) | NPL patterns |
| [mcml-ui.md](mcml-ui.md) | MCML UI |

---

## Networking

| Page | Content |
|------|---------|
| [networking-stacks.md](networking-stacks.md) | Stack decision tree |
| [game-server-and-networking.md](game-server-and-networking.md) | GSL, REST, DBServer |
| [jgsl-networking.md](jgsl-networking.md) | JGSL |
| [legacy-client-networking.md](legacy-client-networking.md) | script/network/ |

---

## Apps & mods

| Page | Content |
|------|---------|
| [applications-catalog.md](applications-catalog.md) | All 14 apps |
| [apps/webserver.md](apps/webserver.md) | NPL HTTP + admin CMS |
| [apps/aquarius.md](apps/aquarius.md) | Aquarius client |
| [apps/backend-servers.md](apps/backend-servers.md) | DBServer, IMServer, PayServer |
| [mods.md](mods.md) | Mods overview |
| [mods/ggs-deep.md](mods/ggs-deep.md) | GeneralGameServerMod |
| [mods/gi-sample-apps.md](mods/gi-sample-apps.md) | GI sample games |
| [mods/explorer-app.md](mods/explorer-app.md) | ExplorerApp |
| [worldshare-cellar.md](worldshare-cellar.md) | Cellar UI flows |

---

## Build, config, tools

| Page | Content |
|------|---------|
| [main-package.md](main-package.md) | main_script packages |
| [packages-and-build.md](packages-and-build.md) | Build pipeline |
| [config-and-environment.md](config-and-environment.md) | All config locations |
| [config/aries-creator.md](config/aries-creator.md) | Paracraft game data XML tree |
| [config/aries-haqi-data.md](config/aries-haqi-data.md) | Haqi Cards/Spells/Bags config |
| [api-index.md](api-index.md) | Docgen API tables |
| [api-reference-docgen.md](api-reference-docgen.md) | Docgen XML |
| [petools-and-entities.md](petools-and-entities.md) | PETools |
| [ai-npc-templates.md](ai-npc-templates.md) | AI templates |
| [mobile-paracraft.md](mobile-paracraft.md) | Mobile layer |
| [supporting-modules.md](supporting-modules.md) | tutorials, sqlite, demo, EBook |

---

## Meta

| Page | Content |
|------|---------|
| [CODEMAP.md](CODEMAP.md) | Code path → wiki page |
| [TOPIC-INDEX.md](TOPIC-INDEX.md) | Keyword → wiki page |
| [SCAN_LOG.md](SCAN_LOG.md) | Coverage / scan history |
| [.github/instructions/paracraft.instructions.md](../.github/instructions/paracraft.instructions.md) | Copilot/NPL coding rules |
| [script/.github/instructions/mcml.instructions.md](../script/.github/instructions/mcml.instructions.md) | MCML rules |
