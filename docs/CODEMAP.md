# Code Map — path → documentation

**For LLMs/agents:** given a file or folder path, use this table to open the right wiki page. Start from the longest matching prefix.

Wiki home: [README.md](README.md) · Topics: [TOPIC-INDEX.md](TOPIC-INDEX.md) · Repo agent entry: [/AGENTS.md](../AGENTS.md)

## How to use

1. Match the file’s directory against the **Code path** column (longest prefix wins).
2. Open the linked doc; follow “See also” there for deeper pages.
3. If editing that tree, also read the nearest `AGENTS.md` (listed in the Agent column).

---

## Repository roots

| Code path | Doc | Agent hub |
|-----------|-----|-----------|
| `/` (repo) | [overview.md](overview.md) | [AGENTS.md](../AGENTS.md) |
| `docs/` | [README.md](README.md) (this wiki) | — |
| `packages/` | [packages-and-build.md](packages-and-build.md), [main-package.md](main-package.md) | — |
| `Documentation/` | [api-index.md](api-index.md), [api-reference-docgen.md](api-reference-docgen.md) | — |
| `Mod/` | [mods.md](mods.md) | [Mod/AGENTS.md](../Mod/AGENTS.md) |
| `config/` (install-time) | [config-and-environment.md](config-and-environment.md) | — |

---

## `script/` — application code

| Code path | Doc | Agent hub |
|-----------|-----|-----------|
| `script/` | [overview.md](overview.md), [npl-and-modules.md](npl-and-modules.md) | [script/AGENTS.md](../script/AGENTS.md) |
| `script/ide/` | [ide-framework.md](ide-framework.md), [ide-subsystems.md](ide-subsystems.md) | [script/ide/AGENTS.md](../script/ide/AGENTS.md) |
| `script/ide/System/` | [ide-subsystems.md](ide-subsystems.md) § System | [script/ide/System/AGENTS.md](../script/ide/System/AGENTS.md) |
| `script/ide/System/UI/` | [ide-framework.md](ide-framework.md) § System.UI | System AGENTS |
| `script/ide/System/UI/Blockly/` | [aries/code-system.md](aries/code-system.md), [code-blocks-and-visual-programming.md](code-blocks-and-visual-programming.md) | System AGENTS |
| `script/ide/System/Windows/mcml/` | [mcml-ui.md](mcml-ui.md) | System AGENTS |
| `script/ide/System/Compiler/` | [npl-and-modules.md](npl-and-modules.md), code-system | System AGENTS |
| `script/kids/` | [paraworld-platform.md](paraworld-platform.md), [kids-subsystems.md](kids-subsystems.md) | [script/kids/AGENTS.md](../script/kids/AGENTS.md) |
| `script/apps/` | [applications-catalog.md](applications-catalog.md) | [script/apps/AGENTS.md](../script/apps/AGENTS.md) |
| `script/network/` | [legacy-client-networking.md](legacy-client-networking.md) | — |
| `script/mobile/` | [mobile-paracraft.md](mobile-paracraft.md) | — |
| `script/installer/` | [packages-and-build.md](packages-and-build.md) | — |
| `script/AI/` | [ai-npc-templates.md](ai-npc-templates.md) | — |
| `script/PETools/` | [petools-and-entities.md](petools-and-entities.md) | — |
| `script/sqlite/`, `tutorials/`, `demo/`, `EBook/`, `lang/`, `test/`, `npl_mod/` | [supporting-modules.md](supporting-modules.md) | — |

---

## `script/apps/` — products & servers

| Code path | Doc | Agent hub |
|-----------|-----|-----------|
| `script/apps/Aries/` | [haqi-aries.md](haqi-aries.md), [aries/modules-reference.md](aries/modules-reference.md) | [Aries/AGENTS.md](../script/apps/Aries/AGENTS.md) |
| `script/apps/Aries/Creator/` | [aries/creator.md](aries/creator.md), [paracraft.md](paracraft.md) | [Creator/AGENTS.md](../script/apps/Aries/Creator/AGENTS.md) |
| `script/apps/Aries/Creator/Game/` | [aries/creator-game-engine.md](aries/creator-game-engine.md), [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md) | [Game/AGENTS.md](../script/apps/Aries/Creator/Game/AGENTS.md) |
| `script/apps/Aries/Quest/` | [aries/quest-system.md](aries/quest-system.md) | Aries AGENTS |
| `script/apps/Aries/Combat/` | [aries/combat-system.md](aries/combat-system.md) | Aries AGENTS |
| `script/apps/Aries/Desktop/`, `NPCs/`, `Friends/`, … | [aries/client-features.md](aries/client-features.md), [aries/modules-reference.md](aries/modules-reference.md) | Aries AGENTS |
| `script/apps/GameServer/` | [game-server-and-networking.md](game-server-and-networking.md), [networking-stacks.md](networking-stacks.md) | apps AGENTS |
| `script/apps/WebServer/` | [apps/webserver.md](apps/webserver.md) | apps AGENTS |
| `script/apps/DBServer/`, `IMServer/`, `PayServer/`, `NPLRouter/` | [apps/backend-servers.md](apps/backend-servers.md), [game-server-and-networking.md](game-server-and-networking.md) | apps AGENTS |
| `script/apps/Aquarius/` | [apps/aquarius.md](apps/aquarius.md) | apps AGENTS |
| `script/apps/HelloChat/`, `HelloWorld/`, `Taurus/`, `orion/`, `Poke/`, `sample/` | [applications-catalog.md](applications-catalog.md) | apps AGENTS |

---

## `script/apps/Aries/Creator/Game/` — Paracraft engine

| Code path | Doc |
|-----------|-----|
| `Game/` (core files) | [creator-game-engine.md](aries/creator-game-engine.md) |
| `Game/blocks/` | [creator-blocks.md](aries/creator-blocks.md) |
| `Game/Entity/` | [creator-entities.md](aries/creator-entities.md) |
| `Game/Tasks/` | [creator-tasks.md](aries/creator-tasks.md) |
| `Game/Code/` | [code-system.md](aries/code-system.md), [code-blocks-and-visual-programming.md](code-blocks-and-visual-programming.md) |
| `Game/Network/` | [creator-network.md](aries/creator-network.md), [networking-stacks.md](networking-stacks.md) |
| `Game/Areas/`, `GUI/`, `mcml/`, `mcml2/` | [creator-ui-areas.md](aries/creator-ui-areas.md), [mcml-ui.md](mcml-ui.md) |
| `Game/Login/`, `Educate/`, `Mobile/` | [creator-login-education.md](aries/creator-login-education.md), [mobile-paracraft.md](mobile-paracraft.md) |
| `Game/Memory/`, `Neuron/` | [memory-and-neuron.md](memory-and-neuron.md) |
| `Game/Movie/`, `Mqtt/`, `Shaders/`, platform hooks | [creator-integrations.md](aries/creator-integrations.md) |
| `Game/Commands/`, `World/`, `Physics/`, … | [creator-game-subsystems.md](aries/creator-game-subsystems.md) |
| `Creator/HttpAPI/` | [creator-httpapi.md](aries/creator-httpapi.md) |

Full 49-directory index: [creator-game-subsystems.md](aries/creator-game-subsystems.md).

---

## `Mod/` — runtime mods

| Code path | Doc | Agent hub |
|-----------|-----|-----------|
| `Mod/WorldShare/` | [worldshare-cellar.md](worldshare-cellar.md), [mods.md](mods.md) | [Mod/AGENTS.md](../Mod/AGENTS.md) |
| `Mod/GeneralGameServerMod/` | [mods/ggs-deep.md](mods/ggs-deep.md) | Mod AGENTS |
| `Mod/GeneralGameServerMod/GI/` | [mods/gi-sample-apps.md](mods/gi-sample-apps.md) | Mod AGENTS |
| `Mod/ExplorerApp/` | [mods/explorer-app.md](mods/explorer-app.md) | Mod AGENTS |

---

## Config & data (often outside this repo)

| Logical path | Doc |
|--------------|-----|
| `config/Aries/creator/` | [config/aries-creator.md](config/aries-creator.md) |
| `config/Aries/` (Haqi) | [config/aries-haqi-data.md](config/aries-haqi-data.md) |
| All config locations | [config-and-environment.md](config-and-environment.md) |

---

## Networking (cross-cutting)

| Concern | Doc |
|---------|-----|
| Which stack to use | [networking-stacks.md](networking-stacks.md) |
| GSL / GameServer / REST | [game-server-and-networking.md](game-server-and-networking.md) |
| JGSL | [jgsl-networking.md](jgsl-networking.md) |
| Legacy `script/network/` | [legacy-client-networking.md](legacy-client-networking.md) |
| Creator TCP packets | [creator-network.md](aries/creator-network.md) |
| GGS mod | [mods/ggs-deep.md](mods/ggs-deep.md) |

---

## Coverage status

See [SCAN_LOG.md](SCAN_LOG.md). If a path is missing here, add a row when documenting it.
