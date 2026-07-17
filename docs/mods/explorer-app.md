# ExplorerApp Mod

World discovery and exploration UI. `Mod/ExplorerApp/` (~47 files).

Overview: [mods.md](mods.md)

## Structure

```
ExplorerApp/
├── components/
│   └── ParacraftWorld/
│       ├── ParacraftWorldComponent.lua / .html
│       └── AwardTooltip.html
├── pages/
│   ├── GameProcess/    TimeUp, GameOver
│   ├── Password/       UpdatePassword
│   └── Sort/           Sort.html
├── service/
│   ├── KeepworkEsService/   Elasticsearch projects
│   └── KeepworkService/     Keepwork API
├── store/
│   └── ExplorerStore.lua
└── tasks/
    └── ExplorerTask.lua
```

## Components

**ParacraftWorldComponent** — card UI for browsing Paracraft worlds with award tooltips.

## Pages

| Page | Role |
|------|------|
| `GameProcess/TimeUp` | Time limit reached |
| `GameProcess/GameOver` | Game over screen |
| `Password/UpdatePassword` | Password change |
| `Sort/` | Sort/filter worlds |

## Services

| Service | Role |
|---------|------|
| `KeepworkEsService` | Elasticsearch project search |
| `KeepworkService` | Keepwork project API |

## Store

`ExplorerStore.lua` — UI state for explorer session.

## Tasks

`ExplorerTask.lua` — background task for loading/searching worlds.

## Integration

- Keepwork backend (same as WorldShare)
- Loaded as NPL mod alongside `npl_packages/paracraft/`
- UI uses GGS Vue/HTML patterns

## See also

- [WorldShare Cellar](worldshare-cellar.md)
- [Creator HttpAPI](../aries/creator-httpapi.md)
