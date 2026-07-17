# WorldShare Cellar UI

**Cellar** is the pre-world shell UI for Paracraft desktop — login, world management, cloud sync, and sharing. Lives in `Mod/WorldShare/cellar/` (~37 flow modules).

Entry hub: `cellar.lua` — wires sub-modules.

Namespace: `Mod.WorldShare.cellar.*` (plus some `MyCompany.Aries.Game.MainLogin.*`)

API config: `Mod/WorldShare/config/Config.lua` (env: ONLINE, STAGE, RELEASE, LOCAL)

## User journey

```
MainLogin / LoginModal
    → RegisterModal (new users)
    → Create / CreateWorld (new world)
    → CommonLoadWorld (open by project ID)
    → [in-world Paracraft Creator]
    → Sync (cloud save)
    → ShareWorld (publish)
    → WorldExitDialog (exit + grade)
```

## Flow modules

### Authentication

| Module | Files | Purpose |
|--------|-------|---------|
| **MainLogin** | `MainLogin/MainLogin.lua`, `Theme/*` | Login, register, mobile login, password update, parent gate |
| **LoginModal** | `LoginModal/` | Modal login, third-party bind |
| **RegisterModal** | `RegisterModal/` | Registration, privacy |
| **ForgetPassword** | `ForgetPassword/` | Password recovery |
| **OfflineAccount** | `OfflineAccount/` | Offline activation |

Theme HTML supports locales: `Theme/MainLogin.en.html`, `MainLoginLoginNew.html`, etc.

### World lifecycle

| Module | Purpose |
|--------|---------|
| **Create** | New world wizard |
| **CreateWorld** | World creation + embed editor |
| **CommonLoadWorld** | Load by project ID; `ShareTypeWorld`, `VipTypeWorld` gating |
| **DeleteWorld** | Delete world |
| **Sync** | Cloud sync; conflict resolution (`UseLocal`, `BeyondVolume`) |
| **ShareWorld** | Publish to datasource (`Theme/ShareWorld.en.html`) |
| **WorldExitDialog** | Exit prompt + grading (`Grade.lua`) |

### Portfolio & media

| Module | Purpose |
|--------|---------|
| **Opus** | Portfolio gallery |
| **OpusSetting** | Project settings |
| **Panorama** | 360° create/preview/share |

### Education & compliance

| Module | Purpose |
|--------|---------|
| **MySchool** | School/institute join |
| **Certificate** | Certification + SMS verification |
| **Beginner** | Onboarding |
| **PreventIndulge** | Anti-addiction (防沉迷) compliance |

### VIP & membership

| Module | Purpose |
|--------|---------|
| **Vip** | VIP by activation code |
| **VipNotice** | VIP notifications |

### Collaboration

| Module | Purpose |
|--------|---------|
| **MemberManager** | Project collaborators |
| **HistoryManager** | Edit history |
| **Permission** | Access control |

### System

| Module | Purpose |
|--------|---------|
| **Menu** | Main cellar menu |
| **Server** | Server hosting page |
| **ClientUpdateDialog** | Update prompts |
| **VersionChange** | Version migration |
| **JumpAppStoreDialog** | App store redirect |
| **Common/MsgBox, KickOut** | Shared dialogs |

## Sync conflict handling

`Sync/Theme/UseLocal.html` — user chooses local vs cloud version when conflict detected.

`Sync/Progress/` — progress UI during sync.

## Backend services

Cellar UI calls services in `Mod/WorldShare/service/`:

- `KeepworkService/` — projects, permissions, panorama
- `GitService/` — version control
- `SyncService/` — compare/merge
- `SocketService.lua` — realtime
- `NPLServerService.lua`

API clients in `Mod/WorldShare/api/Keepwork/`, `Accounting/`, `Lesson/`, `Qiniu/`.

## See also

- [Mods](mods.md) — WorldShare overview
- [Paracraft](paracraft.md) — Creator integration
- [Config and Environment](config-and-environment.md)
- [Networking Stacks Overview](networking-stacks.md)
