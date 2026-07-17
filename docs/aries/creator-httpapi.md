# Creator HttpAPI & Keepwork

HTTP semantic layer for Keepwork cloud backend. `Creator/HttpAPI/` (8 files) + related `Game/KeepWork/`, `Game/KeepWorkMall/`.

Parent: [creator.md](creator.md)

## HttpAPI files

| File | Role |
|------|------|
| `Keepwork.lua` | **Main facade** — user info, assets, first-login checks |
| `HttpWrapper.lua` | REST route registration (`HttpWrapper.Create`) |
| `KeepWorkItemManager.lua` | Bag/item GSID management |
| `keepwork.user.lua` | User API endpoints |
| `keepwork.site.lua` | Site API |
| `keepwork.mall.lua` | Mall API |
| `keepwork.friends.lua` | Friends API |
| `keepwork.class.lua` | Class/school API |
| `keepwork.ai.lua` | AI API |
| `keepwork.thirdparty.lua` | Third-party integrations |

## Usage

```lua
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local user = Keepwork:GetUserInfo();
local firstLogin = Keepwork:IsFirstLoginParacraft();
local assets = Keepwork:GetAllAssets();
```

## HttpWrapper pattern

Routes registered as semantic names mapped to REST paths:

```lua
HttpWrapper.Create("keepwork.school.region", "%MAIN%/core/v0/regions/:id", "GET", true);
```

`%MAIN%` resolves to Keepwork API base from WorldShare config.

## KeepWorkItemManager

Manages **bags** and **GSID** items (global store IDs):

- `GetProfile()`, `HasGSItem(gsid)`, `bags` table
- Used by mall, skins, VIP items

## Game/KeepWork/ (21 files)

Lower-level Keepwork integration inside Game engine (world sync helpers, token handling).

## Game/KeepWorkMall/ (17 files)

In-game mall UI:

- `MallPage.lua`, `MallOtherPage.html`
- Purchases via Keepwork mall API

## Game/API/ (6 files)

| File | Role |
|------|------|
| `FileDownloader.lua` | Download remote assets |

## WorldShare overlap

| Layer | Location |
|-------|----------|
| Pre-world UI (login, sync) | `Mod/WorldShare/cellar/` — [worldshare-cellar.md](../worldshare-cellar.md) |
| In-world HTTP | `Creator/HttpAPI/` (this page) |
| API env config | `Mod/WorldShare/config/Config.lua` |

## See also

- [creator-login-education.md](creator-login-education.md)
- [creator-tasks.md](creator-tasks.md) — Community, WorldShare tasks
- [config-and-environment.md](../config-and-environment.md)
