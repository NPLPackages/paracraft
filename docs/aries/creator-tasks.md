# Creator Tasks (`Game/Tasks/`)

893 files across **62 task modules**. Tasks plug into `GameLogic` as feature units — UI wizards, game modes, education flows, seasonal events.

Namespace: `MyCompany.Aries.Game.Tasks.*` (varies per task)

Parent: [creator.md](creator.md)

## Task base

| File | Role |
|------|------|
| `Task.lua` | Base task class |
| `UndoManager.lua` | Undo/redo for block edits |
| `TransformBlocksTask.lua` | Block transform |
| `SelectBlocksTask.lua` | Multi-block selection |
| `ReplaceBlockTask.lua` | Find/replace blocks |
| `DestroyBlockTask.lua` | Bulk destroy |
| `FollowBlocksTask.lua` | Follow-camera blocks |
| `BlockFileMonitorTask.lua` | Watch external block files |
| `AutoSaveTask.lua` | Autosave scheduler |
| `FindBlockTask.html` | Find block UI |

## All task modules

| Module | Purpose |
|--------|---------|
| **EasyBuilder** | Guided building + **Copilot** AI agent (`Copilot/AgentRouter`, `ToolSandbox`, `DigitalHumanWebView`) |
| **MiniGame** | Mini-game hub: maps, bags, pets, daily recommend, costumes, camera |
| **ParaLife** | Life-simulation mode + `ParaLifeAPI` |
| **ParaWorld** | Community world sharing, admin seat, code list |
| **Community** | Community login, projects, notifications, AIGC skins, settings |
| **BuildReplay** | Record/replay building (`ReplayManager`, `RecordUserPath`, `NplBlockly.html`) |
| **EditCodeActor** | In-world code block editor |
| **EditModel** | 3D model manipulation |
| **EditLight** | Light editing |
| **EditCCS** | Character customization editor |
| **World2In1** | Dual-world / lesson integration (`CodeLessonTip`, `LessonBoxTip`) |
| **VisualScene** | Visual scene editor (`Components/Script.lua`, `UI/Editor`) |
| **ParametricMake** | Parametric CAD generation + tests |
| **Lesson** | Course evaluation, suggestions |
| **Course** | Course content flows |
| **TeachingQuest** | Teaching quest mode |
| **Quest** | Creator-side quest rewards/pages |
| **SchoolCenter** | School student pages |
| **SchoolRank** | School rankings |
| **RedSummerCamp** | Red summer camp courses |
| **SummerCamp** | Summer camp notices |
| **MacroCodeCamp** | Macro programming camp, QR awards |
| **ParacraftLearningRoom** | Learning room mode |
| **ChatGPTTask** | ChatGPT integration task |
| **Exam** | Exam upload/video |
| **HomeWork** | Homework submission |
| **ContactTeacher** | Teacher contact |
| **Friend** | Friend chat in Creator |
| **InviteFriend** | Invite flows |
| **ShareWorld** | Share world from Creator |
| **WorldShare** | WorldShare integration task |
| **WorldKey** | World key / license keys (`WorldKeyManager`) |
| **OnlineStore** | Online store |
| **NplGit** | Git integration for worlds |
| **Rank** | Project ranking, World2In1 up-rank |
| **Race** | Race game mode |
| **RailCar** | Rail car editor page |
| **TerrainBrush** | Terrain painting |
| **BoneBlock** | Bone block tools |
| **BlockMaterial** | Block material picker |
| **SelectColor** | Color picker dialog |
| **Dock** | Creator dock extensions |
| **Notice** / **NoticeV2** | In-app notifications |
| **MsgCenter** | Message center |
| **DailyTask** | Daily task rewards |
| **User** | User info, skin exchange, VIP page |
| **VipToolTip** | VIP code exchange |
| **CreateReward** | Like/distribute rewards |
| **Help** | Help pages |
| **Email** | Email integration |
| **Activity** | Generic activity framework |
| **Act51Ask** | May 1st event |
| **ActDragonBoatFestival** | Dragon boat festival |
| **ActLantern** | Lantern festival |
| **ActLuckyDraw** | Lucky draw |
| **ActRedhat** | Red hat event exchange |
| **ActTeacher** | Teacher appreciation |
| **ActWeek** | Weekly activity |
| **AskPop** | Ask popup |
| **RealNameTip** | Real-name verification tip |
| **TurnTable** | Turntable lottery |

## Notable deep trees

### EasyBuilder + Copilot

```
Tasks/EasyBuilder/
├── EasyEditableWorld.lua, EasyMap.lua, EasyChar.html
├── EasyBuilderTaskVerify.lua
└── Copilot/
    ├── AgentRouter.lua
    ├── ToolSandbox.lua
    ├── DigitalHumanWebView.lua
    └── workspace/eduagent/   # skills, config (SKILL.md)
```

AI-assisted building for education.

### MiniGame

Hub for user-generated mini-games: `MiniGameMgr.lua`, `MiniGamePage`, maps, virtual/temp bags, pet manager, skin draw, MaisiAPI.

### Community

Keepwork community: login scripts, project components, notifications, certificate, PrepareApp.

### BuildReplay

Session recording for tutorials and CI — pairs with `ParacraftCI`.

## Registering tasks

Tasks are typically started from `game_logic.lua` or mode switches. Pattern:

```lua
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua");
```

## See also

- [creator-game-subsystems.md](creator-game-subsystems.md)
- [creator-login-education.md](creator-login-education.md)
- [worldshare-cellar.md](../worldshare-cellar.md)
