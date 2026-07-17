# Haqi Client Features

Subsystem guide for **`script/apps/Aries/`** modules outside Paracraft Creator. For Creator engine see [Creator Game Engine](creator-game-engine.md).

## Login (`Login/`)

Account entry, gateway selection, Keepwork SSO.

| File | Role |
|------|------|
| `MainLogin.lua` | Primary login flow |
| `MainLogin_noUI.lua` | Headless login |
| `TaoMeeRegPage.lua` | TaoMee registration partner |
| `LogoBottomBannerPage.teen.html` | Teen branding |

Command-line auth:

```
username="..." password="..." gateway="1100"
keepworktoken="..."
```

## Desktop (`Desktop/`)

In-game HUD after login.

| Component | Files |
|-----------|-------|
| Main desktop | `AriesDesktop.lua` |
| Dock | `Dock/AriesMobilePage.lua` |
| Character frame | `CombatCharacterFrame/` |
| Quest area | `QuestArea.lua` |
| Notifications | `NotificationArea/` |
| EXP buff | `EXPBuffArea.lua` |
| Magic star | `MagicStarArea.lua` |
| Tooltips | `GenericTooltip_InOne.html`, `ApparelTooltip.html` |
| Smiley selector | `SmileySelector.html` |

Teen variants: many files have `.teen.lua` / `.teen.html` siblings.

## Scene (`Scene/`)

World scene state. Used by shop and events:

```lua
MyCompany.Aries.Scene.GetDayOfWeek()  -- HaqiShop weekly rotation
```

## Player (`Player/`)

Player attributes, state machine. Namespace: `MyCompany.Aries.Player`

Loaded early in Creator `main.lua` for shared player model.

## Combat (`Combat/`)

Card-based combat system.

```
script/apps/Aries/Combat/readme.txt
script/apps/Aries/Combat/main.lua
script/apps/Aries/Combat/Battlefield/
script/apps/Aries/Combat/UI/          # MyCards, UnitStatusTip, CombatResult
```

Related:

- `CombatRoom/` — Instance lobby, team quests
- `CombatPet/` — Combat pets, `CombatPetHelper.lua`

PETools entity defs: `script/PETools/Aries/Card.entity.xml`

## Quest (`Quest/`)

```
script/apps/Aries/Quest/readme.txt
script/apps/Aries/Quest/main.lua
script/apps/Aries/Quest/QuestTrackerPage.html
```

Builds on platform quest system (`script/kids/3DMapSystemQuest/`).

## NPCs (`NPCs/`)

Dialog-driven NPCs organized by zone/feature:

| Folder | Examples |
|--------|----------|
| `Dragon/` | Wish levels, dragon totem |
| `FollowPets/` | LoliCat, GoldenHorse |
| `MagicSchool/` | Skill cards |
| `Library/` | Mystery encrypted box |
| `LifeSpring/` | Revive elixir |
| `MagicMoneyBox/` | Money box dialog |

Pattern: `[id]_[Name].lua` + `[id]_[Name]_dialog.html`

## Inventory (`Inventory/`)

| Subfolder | Content |
|-----------|---------|
| `Cards/` | Magic cards, shop |
| `Skills/` | Skill selection |
| Root | Item views, pet other player |

## Items (`Items/`)

Shared item definitions used by inventory, shop, and quests.

## Friends & social

| Module | Features |
|--------|----------|
| `Friends/` | Friend list, blacklist, add friend |
| `Family/` | Family list, members |
| `FamilyServer/` | Family server settings |
| `Mail/` | Read/send mail, templates |
| `Chat/`, `BBSChat/` | Chat windows, battle chat |
| `Team/` | Party system |

## HaqiShop (`HaqiShop/`)

In-game monetization shop. See [Haqi / Aries](../haqi-aries.md).

Related economy:

- `Trade/` — Player trading
- `VIP/` — VIP privileges
- `Gift/` — Gift items
- `GoldRankingList/` — Leaderboards
- `DealDefend/` — Trade lock protection

## Pet (`Pet/`)

Companion pets: `main.lua`, follow behaviors, UI integration with NPCs.

## Profile (`Profile/`, `NewProfile/`)

Character profiles, family profile teen pages.

## Map & instances

| Module | Role |
|--------|------|
| `Map/` | World map UI |
| `Instance/` | Dungeons/instances |

## Content & media

| Module | Role |
|--------|------|
| `Books/` | Magazines (Times Magazine web v30–v120+) |
| `Movie/` | Replay mode, time effects |
| `Animation/` | Card content animations |
| `BigEvents/` | Seasonal events |

## Help & commands

- `Help/` — Help system
- `SlashCommand/` — Chat commands

## Pipeline & Debug (dev only)

Excluded from shipping builds:

- `Pipeline/` — Asset pipeline tools
- `Debug/` — Config checker, monster detail, database checker

## PETools integration

`script/PETools/Aries/` — Entity XML templates for cards, mobs:

- `Card.entity.xml`, `Card.newinstance.html`
- `Mob.newinstance.html`

Used with `ide/IPCBinding/` for C# ↔ NPL entity editing.

## Theme

- `DefaultTheme.lua` — Kids theme loader
- `DefaultTheme.teen.lua` — Teen theme loader
- `ThemeView/` — Theme preview

## Service layer

`Service/` — Background client services (updates, sync helpers).

## Typical feature flow

```
Login → Desktop.Show → Scene.LoadWorld
    → Quest/NPC/Combat modules hook into Desktop
    → Inventory/Items backed by 3DMapSystemItem types
    → Shop/Trade via HaqiShop + server REST
```

## See also

- [Haqi / Aries](../haqi-aries.md)
- [MCML UI](../mcml-ui.md)
- [ParaWorld Platform](../paraworld-platform.md) — Item/quest base types
- [Game Server and Networking](../game-server-and-networking.md)
