# Haqi Quest System

MMO-style quest system in `script/apps/Aries/Quest/`. Built on GSL game server, global store item templates, and the platform item API.

Namespace: `MyCompany.Aries.Quest.*`

Source: `script/apps/Aries/Quest/readme.txt` (LiXizhi, 2010)

## Architecture

```
Global store item templates (quest gsid + data field)
        ↓
QuestProvider  (read templates, build graph indexes)
        ↓
QuestLogics  (business rules: available/completed quests)
        ↓
QuestPlayer  (per-nid player quest state)
        ↓
QuestClient / QuestServer  (client/server facades)
        ↓
PowerItemManager → PowerAPI → GameServer.rest_local
```

## Layer responsibilities

| Class | File | Role |
|-------|------|------|
| **QuestProvider** | `QuestProvider.lua` | Low-level access to quest templates from global store; builds indexable tables with graph refs |
| **QuestLogics** | `QuestLogics.lua` | High-level rules: given player state → available tasks, completed tasks |
| **QuestPlayer** | `QuestPlayer.lua` | Per-player (nid) quest item data; persistence via PowerItemManager |
| **QuestPlayerManager** | `QuestPlayerManager.lua` | Manager for QuestPlayer instances |
| **QuestClient** | `QuestClient.lua` | Client-side quest operations |
| **QuestServer** | `QuestServer.lua` | Server-side quest operations |
| **QuestClientLogics** | `QuestClientLogics.lua` | Client-specific business rules |

## Entry point

```lua
-- script/apps/Aries/Quest/main.lua
-- Bootstraps quest; loads kids/3DMapSystemQuest/Main.lua
NPL.load("(gl)script/apps/Aries/Quest/main.lua");
```

## NPCs and world objects

| File | Role |
|------|------|
| `NPC.lua` | NPC entity logic |
| `NPCList.lua` | NPC registry |
| `GameObject.lua` | Quest world objects |
| `QuestPathFinder.lua` | Pathfinding for quest targets |
| `WaypointProvider.lua` | Waypoint data |

NPCs combine: appearance, AI scripts, item bags, MCML FSM dialog pages.

## Product hooks (kids/teen)

| File | Role |
|------|------|
| `HaqiQuestHooks.lua` | Shared hooks |
| `HaqiQuestHooks.kids.lua` | Kids-specific |
| `HaqiQuestHooks.teen.lua` | Teen-specific |

## UI

| File | Role |
|------|------|
| `QuestPane.lua` | Quest journal pane |
| `QuestTrackerPane.lua` | On-screen tracker |
| `QuestTrackerPage.html` | Tracker MCML |
| `QuestDialogPage.html` | NPC dialog |
| `QuestDetailPage.html` | Quest detail view |
| Medal/dragon status pages | Various `.html` |

## Platform integration

Quest system depends on platform layers:

```lua
-- Item persistence (server)
NPL.load("(gl)script/kids/3DMapSystemItem/PowerItemManager.lua");
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");

-- Server item API
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.PowerAPI.lua");

-- REST on game server
NPL.load("(gl)script/apps/GameServer/rest_webservice_wrapper.lua");
NPL.load("(gl)script/apps/GameServer/rest_local.lua");
```

## Quest template data

Quest templates stored in **global store item `data` fields** — both client and server see synchronized copies (potentially thousands of quests).

Each template has:

- Unique **gsid** in global store
- Requirements, goals, rewards
- Start NPC, finish NPC
- `next_request_chain` for quest chains

Data files (formats not fully documented in-repo):

- `QuestRelationList.txt`
- `ExtendedCostList.txt`

## Platform quest editor

`script/kids/3DMapSystemQuest/` — quest form editors, quest server loop.

## See also

- [Haqi Client Features](client-features.md)
- [ParaWorld Platform](../paraworld-platform.md) — 3DMapSystemQuest, items
- [Game Server and Networking](../game-server-and-networking.md) — GSL, REST
- [JGSL Networking](../jgsl-networking.md)
