# `config/Aries/` — Haqi Game Data (non-Creator)

Sibling data under `config/Aries/` used by **Haqi MMO** combat, inventory, and spells — separate from [creator/](aries-creator.md) Paracraft configs.

**Not in paraworld script repo** — ships with full product install.

## Layout

```
config/Aries/
├── creator/          → see aries-creator.md
├── Cards/
│   ├── CardList.xml
│   ├── CardList.teen.xml
│   ├── CharmWardList.xml
│   └── CharmWardList.teen.xml
├── Spells/
│   ├── Player_EnterCombat_teen.xml
│   ├── Fizzle_{school}.xml
│   ├── Pickpet_{school}.xml
│   ├── DoT_{school}.xml
│   ├── HoT.xml / HoT_teen.xml
│   ├── dead.xml / dead_teen.xml
│   └── {spell_key}.xml
├── BagDefine_Teen/
│   ├── bag.xml
│   └── bag_extend.xml
├── Others/
│   ├── mob_ccs.kids.xml
│   └── mob_ccs.teen.xml
├── HP/
│   └── HP_level_mapping.xml
└── Audio/
    └── CreatorSound.bank.xml
```

## Loaders

| Config | Loaded by |
|--------|-----------|
| `Cards/CardList*.xml` | `Combat/MsgHandler.lua`, `Combat/main.lua` |
| `Cards/CharmWardList*.xml` | `Combat/MsgHandler.lua` |
| `Spells/*.xml` | `Combat/MsgHandler.lua` (spell cast animations) |
| `Others/mob_ccs.*.xml` | `Combat/MsgHandler.lua` |
| `BagDefine_Teen/bag*.xml` | `Desktop/CombatCharacterFrame/CharacterBagPage.lua` |
| `HP/HP_level_mapping.xml` | Combat (commented references) |

Kids vs teen: files switch on `System.options.isKid` / teen spell suffix `_teen.xml`.

## See also

- [combat-system.md](../aries/combat-system.md)
- [haqi-aries.md](../haqi-aries.md)
- [aries-creator.md](aries-creator.md)
