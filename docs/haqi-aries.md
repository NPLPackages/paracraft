# 魔法哈奇 (Haqi) — Aries Client

**魔法哈奇 (Magic Haqi / Haqi)** is a kids MMO game whose client code lives in **`script/apps/Aries/`**. The project started March 2009. Since March 2011, two concurrent UI versions share one codebase:

| Version | Audience | CLI flag |
|---------|----------|----------|
| **Kids** | Ages 7–14 | `version="kids"` |
| **Teen** | General audience | `version="tean"` (note spelling in code) |

Empty `version=""` shows a version selection dialog. Users can switch versions in-game.

Source: `script/apps/Aries/readme.txt`

## Product relationship

```
script/apps/Aries/
├── Haqi MMO features          ← Login, Combat, Quest, NPCs, Shop, …
├── Creator/                   ← Paracraft (see paracraft.md)
└── Shared backend logic       ← Player, Scene, Items, Network (~99% shared)
```

Launch Haqi client:

```
bootstrapper="script/apps/Aries/bootstrapper.xml"
```

Entry loop: `script/apps/Aries/main_loop.lua`

## Kids vs teen programming model

Both versions share **~99% of code**. Differences are mostly UI assets and MCML pages.

### Runtime flags

```lua
System.options.isKid      -- boolean
System.options.version    -- "kids" or "teen"
```

### UI file naming conventions

| Pattern | Usage |
|---------|--------|
| `Page.html` | Kids (default) |
| `Page.teen.html` | Teen variant |
| `Page.kids.html` | Explicit kids variant |
| `Texture/Aries/Common/ThemeTean/` | Shared teen theme textures |

### Code patterns

**Simple branch:**

```lua
if System.options.isKid then
    -- kids UI/logic
else
    -- teen UI/logic
end
```

**MCML page selection:**

```lua
local url = if_else(System.options.isKid, "mcml_page.html", "mcml_page.teen.html")
```

**In MCML:**

```html
<pe:if condition='<%=System.options.isKid%>'>
    kids version
</pe:if>
<pe:if condition='<%=not System.options.isKid%>'>
    teen version
</pe:if>
```

**Performance:** For hot paths (>100 calls/sec), cache `local isKid = System.options.isKid` at file scope (loses runtime toggle).

### 3D asset paths

| Asset | Kids | Teen |
|-------|------|------|
| Main character | `character/v3/Elfteen/` (teen elf model) | Same path for teen |
| Other characters | `character/v5/` (shared) | Shared |
| Terrain | `Texture/tileset/generic/` (shared) | Shared |

## Aries module map (53 top-level folders)

| Module | Description |
|--------|-------------|
| **Login** | Account login, registration, gateway, Keepwork token |
| **Desktop** | In-game HUD, dock, notifications, character frame |
| **Scene** | World scene management, day-of-week helpers |
| **Player** | Player state, attributes |
| **Combat** | Card-based combat system |
| **CombatRoom** | Combat instances, lobby chat |
| **CombatPet** | Combat pets |
| **Quest** | Quest tracking, chains, goals |
| **NPCs** | Dialog trees, shops, dragons, magic school |
| **Inventory** | Bags, cards, skills, apparel |
| **Items** | Item definitions and handlers |
| **UserBag** | Extended bag UI |
| **Friends** | Friend list, blacklist |
| **Family**, **FamilyServer** | Family/guild social system |
| **Mail** | In-game mail |
| **Chat**, **BBSChat** | Chat windows, battle chat |
| **HaqiShop** | In-game cash shop (kids/teen variants) |
| **Trade** | Player trading |
| **Pet** | Companion pets |
| **Profile**, **NewProfile** | Character profiles |
| **Registration** | New user registration |
| **Map** | World map UI |
| **Instance** | Dungeon/instance management |
| **Movie**, **Animation** | In-game cinematics |
| **Books** | In-game magazines (Times Magazine, etc.) |
| **VIP**, **Gift** | VIP privileges, gifts |
| **GoldRankingList** | Leaderboards |
| **BigEvents** | Seasonal events |
| **DealDefend** | Trade lock / fraud defense |
| **ApparelTranslation** | Gem/apparel translation UI |
| **Help** | Help system |
| **SlashCommand** | Chat slash commands |
| **Team** | Party/team system |
| **Roles** | Character roles/classes |
| **Plats** | Platform-specific code |
| **Partners** | Partner integrations |
| **RedPaperMail** | Red envelope mail events |
| **CrazyTower** | Mini-game tower mode |
| **Service** | Background services |
| **ServerObjects** | Server-side object refs |
| **ThemeView** | Theme preview |
| **EmuUsers** | Emulated users (dev) |
| **Dialog** | Generic dialog system |
| **Creator** | Paracraft (see [paracraft.md](paracraft.md)) |
| **ParacraftCI** | CI integration |
| **Pipeline**, **Debug** | Dev tools (excluded from shipping) |
| **mcml** | Aries-specific MCML extensions |

See [Client Features](aries/client-features.md) for subsystem details.

## HaqiShop (魔法商城)

`script/apps/Aries/HaqiShop/` — Main in-game shop UI.

```lua
NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.lua");
MyCompany.Aries.HaqiShop.ShowMainWnd()
```

Loads kids or teen implementation:

```lua
if System.options.isKid then
    NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.kids.lua")
else
    NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.teen.lua")
end
```

Related: `NPCShopProvider.lua`, `AuctionHouse.lua`, textures under `Texture/Aries/HaqiShop/`.

## Main loop initialization (Haqi-specific)

`main_loop.lua` performs Haqi-specific setup before the game loop:

1. Optional IMServer client replacement (`imserver="game"`)
2. Load `ParaWorldCore.lua`
3. Load `npl_packages/paracraft/` (unless dev mode)
4. Set `System.options.mc`, `channelId`, `keepworktoken`
5. Load default theme (`DefaultTheme.lua` / `DefaultTheme.teen.lua`)
6. Install Aries app via `IP.xml`
7. Configure login/world load commands
8. Start desktop / login flow

### Notable command-line params (Aries)

| Param | Purpose |
|-------|---------|
| `world` | Direct world load path |
| `gateway` | Force gateway (debug) |
| `channelId` | Distribution channel (e.g. `"431"`) |
| `isSchool` | Disable games and URL protocol install |
| `visit_url` | `"nid@slot_id"` deep link |
| `browser_debug` | Enable WebView2 debug |
| `resolution` | Open window resolution |

## IM integration

By default, Haqi replaces the Jabber IM client with the game-server-based IM:

```lua
if ParaEngine.GetAppCommandLineByParam("imserver", "game") == "game" then
    NPL.load("(gl)script/apps/IMServer/IMserver_client.lua");
    JabberClientManager = commonlib.gettable("IMServer.JabberClientManager");
end
```

Skipped when `mc="true"` (Paracraft mode).

## Logging

Client log files may be used for user behavior analysis (per readme).

## Namespace

Haqi modules typically use:

```
MyCompany.Aries.*
MyCompany.Aries.HaqiShop
MyCompany.Aries.Scene
MyCompany.Aries.Player
```

## See also

- [Client Features](aries/client-features.md)
- [Paracraft](paracraft.md)
- [Game Server and Networking](game-server-and-networking.md)
- [Main Package](main-package.md) — Aries included in `main_script`
- Original: `script/apps/Aries/readme.txt`
