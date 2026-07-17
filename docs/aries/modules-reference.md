# Aries Modules Reference

Index of remaining `script/apps/Aries/` modules not covered by dedicated pages. For core systems see linked docs.

## Economy & monetization

| Module | Key files | Notes |
|--------|-----------|-------|
| **HaqiShop** | `HaqiShop.lua`, `.kids.lua`, `.teen.lua` | [Haqi doc](../haqi-aries.md) |
| **Trade** | `Trade/` | Player-to-player trading |
| **VIP** | `VIP/main.lua` | VIP privileges |
| **Gift** | `Gift/` | Gift items/events |
| **GoldRankingList** | `GoldRankingList/` | Leaderboards, battlefield contest |
| **DealDefend** | `DealLockPage.*` | Trade fraud protection |

## Content & events

| Module | Notes |
|--------|-------|
| **Books** | In-game magazines — Times Magazine (v1–v120+ HTML), fashion, town history |
| **BigEvents** | Seasonal/limited-time events |
| **Movie** | Replay mode, time effects |
| **Animation** | Card content animations |
| **RedPaperMail** | Red envelope mail events |

## World & instances

| Module | Notes |
|--------|-------|
| **Map** | World map UI |
| **Instance** | Dungeon/instance management |
| **Scene** | Scene state, day-of-week (used by shop) |
| **Plats** | Platform-specific integrations |

## Account & profile

| Module | Notes |
|--------|-------|
| **Profile** | Character profile pages |
| **NewProfile** | New profile UI (`.kids.html`) |
| **Registration** | Account registration flows |
| **Roles** | Character roles/classes |

## Social (beyond Friends)

| Module | Notes |
|--------|-------|
| **Team** | Party system |
| **SlashCommand** | Chat slash commands |
| **Help** | Help system |
| **Partners** | Partner integrations |

## Apparel & translation

| Module | Notes |
|--------|-------|
| **ApparelTranslation** | Gem/apparel translation UI |

## Minigames

| Module | Notes |
|--------|-------|
| **CrazyTower** | Tower mini-game mode |

## Services & infrastructure

| Module | Notes |
|--------|-------|
| **Service** | Background client services |
| **ServerObjects** | Server-side object references |
| **ParacraftCI** | CI integration hooks |
| **mcml** | Aries-specific MCML extensions |
| **ThemeView** | Theme preview |

## Dev tools (excluded from shipping)

| Module | Notes |
|--------|-------|
| **Pipeline** | Asset pipeline — excluded from `main_script` |
| **Debug** | Config checker, DB checker, monster detail |
| **EmuUsers** | Emulated users for JGSL testing |

## Creator subsystems (see dedicated pages)

| Area | Doc |
|------|-----|
| Game engine | [creator-game-engine.md](creator-game-engine.md) |
| Code/Blockly | [code-system.md](code-system.md) |
| Network | [creator-network.md](creator-network.md) |
| Memory/Neuron | [../memory-and-neuron.md](../memory-and-neuron.md) |

### Creator/Game not yet on dedicated pages

| Subdir | Purpose |
|--------|---------|
| `Physics/` | DamageSource, physics world |
| `Mqtt/` | IoT device integration (MqttApi, device dialogs) |
| `Android/` | Android platform hooks |
| `Educate/` | Education login flows |
| `Login/` | Creator login, ClientUpdater, PrepareApp |
| `KeepWorkMall/` | Keepwork mall integration |
| `HttpAPI/` | Keepwork HTTP wrappers (in `Creator/HttpAPI/`) |
| `Shaders/` | Custom FX (e.g. `mrt_bmax_model.fx`) |
| `Sound/`, `Effects/` | Audio and visual effects |
| `Setting/` | ServerSetting and config UI |
| `NplMod/` | In-world NPL mod nodes |

## See also

- [Haqi / Aries](../haqi-aries.md) — full module table
- [Client Features](client-features.md)
- [Quest System](quest-system.md)
- [Combat System](combat-system.md)
