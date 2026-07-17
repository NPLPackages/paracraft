# Creator Login & Education

Login, updates, education flows, and mobile onboarding in Creator.

Parent: [creator.md](creator.md)

## Login (`Game/Login/` — 84 files)

Creator-specific login (distinct from Haqi `Aries/Login/`):

| Component | Role |
|-----------|------|
| `MainLogin.lua` | Creator login flow |
| `ClientUpdater430.lua` | Client version updater |
| `PrepareApp.lua` | App preparation / first-run |
| `YellowCodeLimitPage.lua` | Content rating limits |
| `TeacherAgent/` | Knowledge-engine teaching agent |
| Mobile login HTML | Various `*MobileLogin.html` |

Teacher agent readme: uses Keepwork knowledge engine to teach Paracraft.

## Educate (`Game/Educate/` — 68 files)

Education-specific flows:

- School login pages
- Student/teacher modes
- Certificate integration with Community tasks

Pairs with `Tasks/SchoolCenter/`, `Tasks/RedSummerCamp/`, `Tasks/Exam/`.

## Mobile (`Game/Mobile/` — 48 files)

| File | Role |
|------|------|
| `MobileUIRegister.lua` | Register mobile UI pages |
| `UserProtocolPre.lua` | User agreement pre-screen |

See also [mobile-paracraft.md](../mobile-paracraft.md) for `script/mobile/`.

## AutoUpdateLoader (`AutoUpdateLoader/` — 3 files)

Client patch download and apply before login.

## NplExtensionsUpdater (3 files)

Updates NPL extension packages.

## Tasks integration

| Task module | Login/education tie-in |
|-------------|------------------------|
| `Community/Login/` | Community register/password scripts |
| `Community/Setting/PrepareAppPage` | Prepare app |
| `Community/Setting/CertificateCommunity` | Certificates |
| `RealNameTip` | Real-name verification |
| `ContactTeacher` | Teacher contact |
| `HomeWork`, `Exam` | Assignments |
| `ParacraftLearningRoom` | Classroom mode |

## WorldShare cellar

Pre-Creator login handled by [worldshare-cellar.md](../worldshare-cellar.md) (`cellar/MainLogin/`).

Creator `Game/Login/` handles in-app re-login and updates.

## See also

- [creator-httpapi.md](creator-httpapi.md)
- [creator-tasks.md](creator-tasks.md)
- [Haqi Login](../haqi-aries.md) — `Aries/Login/` for MMO
