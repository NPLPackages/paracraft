# Aquarius Application

Alternate ParaWorld client app (Pala5 era). `script/apps/Aquarius/` — structurally similar to Aries but separate product.

Excluded from `main_script` shipping package.

## Entry

```
script/apps/Aquarius/main_loop.lua
script/apps/Aquarius/bootstrapper.xml
script/apps/Aquarius/readme.txt
```

## Module layout (mirrors Aries)

| Module | Role |
|--------|------|
| `Login/` | Avatar registration, login pages |
| `Desktop/` | Logged-in home, dock, local map, quick launch |
| `Quest/` | Quest UI (CMB, Telecom specials) |
| `Inventory/` | Bags, character slots |
| `Profile/` | Basic info, interests, privacy, house |
| `Roles/` | Character edit tabs |

## vs Aries/Haqi

| | Aquarius | Aries |
|---|----------|-------|
| Status | Legacy/alternate | Primary (Haqi + Paracraft) |
| Combat | Limited/absent | Full card combat |
| Creator | No Paracraft Creator | Full Creator/Game |
| Package | Excluded | Included |

## Bootstrap pattern

Same as other ParaWorld apps:

```lua
NPL.load("(gl)script/kids/ParaWorldCore.lua");
-- Install Aquarius app via IP.xml
```

## See also

- [Applications Catalog](applications-catalog.md)
- [Haqi / Aries](../haqi-aries.md)
- [ParaWorld Platform](../paraworld-platform.md)
