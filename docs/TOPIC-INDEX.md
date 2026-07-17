# Topic Index — keyword → documentation

**For LLMs/agents:** find docs by concept, product name, or technology — not by file path. For path lookup use [CODEMAP.md](CODEMAP.md).

Wiki home: [README.md](README.md)

---

## Products & modes

| Topic | Docs |
|-------|------|
| Paracraft (product) | [paracraft.md](paracraft.md), [aries/creator.md](aries/creator.md) |
| Haqi / 魔法哈奇 / Magic Haqi | [haqi-aries.md](haqi-aries.md) |
| ParaWorld platform / 3D Map System | [paraworld-platform.md](paraworld-platform.md), [kids-subsystems.md](kids-subsystems.md) |
| `mc="true"` Creator mode | [overview.md](overview.md), [paracraft.md](paracraft.md) |
| Headless / servermode | [paracraft.md](paracraft.md), [aries/creator-game-engine.md](aries/creator-game-engine.md) |
| Mobile Paracraft | [mobile-paracraft.md](mobile-paracraft.md) |

---

## Core engine concepts

| Topic | Docs |
|-------|------|
| BlockEngine / voxels / blocks | [aries/creator-game-engine.md](aries/creator-game-engine.md), [aries/creator-blocks.md](aries/creator-blocks.md) |
| EntityManager / entities / NPCs | [aries/creator-entities.md](aries/creator-entities.md), [aries/creator-game-engine.md](aries/creator-game-engine.md) |
| GameLogic / game loop | [aries/creator-game-engine.md](aries/creator-game-engine.md) |
| World save / GameLevel.xml / AutoSaver | [paracraft.md](paracraft.md), [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md) |
| Items / inventory (Creator) | [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md), [api-index.md](api-index.md) |
| Commands / slash commands | [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md) § Commands |
| Tasks / EasyBuilder / ParaLife | [aries/creator-tasks.md](aries/creator-tasks.md) |
| Physics / damage | [aries/creator-game-subsystems.md](aries/creator-game-subsystems.md) § Physics |

---

## Visual programming & code

| Topic | Docs |
|-------|------|
| Code blocks / Blockly | [aries/code-system.md](aries/code-system.md), [code-blocks-and-visual-programming.md](code-blocks-and-visual-programming.md) |
| CodeAPI / coroutines / wait / yield | [code-blocks-and-visual-programming.md](code-blocks-and-visual-programming.md), [npl-and-modules.md](npl-and-modules.md) |
| Memory / Neuron / MOP | [memory-and-neuron.md](memory-and-neuron.md) |
| Compiler / DSL / checkyield | [ide-subsystems.md](ide-subsystems.md), [aries/code-system.md](aries/code-system.md) |
| GI / Game Inventor | [mods/gi-sample-apps.md](mods/gi-sample-apps.md), [mods/ggs-deep.md](mods/ggs-deep.md) |

---

## NPL & framework

| Topic | Docs |
|-------|------|
| NPL.load / gettable / inherit | [npl-and-modules.md](npl-and-modules.md) |
| commonlib | [ide-framework.md](ide-framework.md), [npl-and-modules.md](npl-and-modules.md) |
| System.* framework | [ide-framework.md](ide-framework.md), [ide-subsystems.md](ide-subsystems.md) |
| MCML / pe:mcml / page:Refresh | [mcml-ui.md](mcml-ui.md) |
| Vue UI / GGS Window | [ide-framework.md](ide-framework.md) § System.UI |
| Localization `L""` | [npl-and-modules.md](npl-and-modules.md) |
| Debugging / LOG / echo / httpdebug | [npl-and-modules.md](npl-and-modules.md), [.github/instructions](../.github/instructions/paracraft.instructions.md) |

---

## Networking & multiplayer

| Topic | Docs |
|-------|------|
| Pick a network stack | [networking-stacks.md](networking-stacks.md) |
| Creator TCP / packets / TunnelService | [aries/creator-network.md](aries/creator-network.md) |
| GGS / GeneralGameServerMod | [mods/ggs-deep.md](mods/ggs-deep.md), [mods.md](mods.md) |
| GSL / GameServer | [game-server-and-networking.md](game-server-and-networking.md) |
| JGSL | [jgsl-networking.md](jgsl-networking.md) |
| Legacy client network | [legacy-client-networking.md](legacy-client-networking.md) |
| REST / DBServer / IMServer | [apps/backend-servers.md](apps/backend-servers.md), [game-server-and-networking.md](game-server-and-networking.md) |
| MQTT / IoT | [aries/creator-integrations.md](aries/creator-integrations.md) |

---

## Cloud, accounts, education

| Topic | Docs |
|-------|------|
| Keepwork / HttpAPI | [aries/creator-httpapi.md](aries/creator-httpapi.md) |
| WorldShare / cellar / login UI | [worldshare-cellar.md](worldshare-cellar.md), [mods.md](mods.md) |
| Educate / schools / courses | [aries/creator-login-education.md](aries/creator-login-education.md) |
| ExplorerApp | [mods/explorer-app.md](mods/explorer-app.md) |

---

## Haqi MMO systems

| Topic | Docs |
|-------|------|
| Quest | [aries/quest-system.md](aries/quest-system.md) |
| Combat / cards | [aries/combat-system.md](aries/combat-system.md) |
| Desktop / social / NPCs | [aries/client-features.md](aries/client-features.md) |
| All Aries modules | [aries/modules-reference.md](aries/modules-reference.md) |
| Kids vs teen UI | [haqi-aries.md](haqi-aries.md), [overview.md](overview.md) |

---

## UI & tools

| Topic | Docs |
|-------|------|
| Creator toolbar / Areas / GUI | [aries/creator-ui-areas.md](aries/creator-ui-areas.md) |
| Movie / video recording | [aries/creator-integrations.md](aries/creator-integrations.md) |
| Shaders / FX | [aries/creator-integrations.md](aries/creator-integrations.md) |
| PETools / entity XML editors | [petools-and-entities.md](petools-and-entities.md) |
| AI NPC templates | [ai-npc-templates.md](ai-npc-templates.md) |
| WebServer / admin CMS | [apps/webserver.md](apps/webserver.md) |

---

## Build, packages, config, API

| Topic | Docs |
|-------|------|
| main_script packages | [main-package.md](main-package.md) |
| Build / redist / zip | [packages-and-build.md](packages-and-build.md) |
| Config / env / bootstrapper | [config-and-environment.md](config-and-environment.md) |
| Creator game data XML | [config/aries-creator.md](config/aries-creator.md) |
| Haqi Cards/Spells config | [config/aries-haqi-data.md](config/aries-haqi-data.md) |
| Docgen API tables | [api-index.md](api-index.md), [api-reference-docgen.md](api-reference-docgen.md) |
| Apps catalog | [applications-catalog.md](applications-catalog.md) |
| Supporting odds & ends | [supporting-modules.md](supporting-modules.md) |

---

## Maintenance

When adding a wiki page, add rows here and in [CODEMAP.md](CODEMAP.md). Update [SCAN_LOG.md](SCAN_LOG.md) coverage if needed.
