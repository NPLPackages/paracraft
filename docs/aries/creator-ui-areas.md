# Creator UI (Areas, GUI, Shell)

In-world and editor UI for Paracraft Creator.

Parent: [creator.md](creator.md)

## Creator shell (root `Creator/`)

| File | Role |
|------|------|
| `MainToolBar.lua` / `.html` | Top toolbar (save, play, share, …) |
| `MainSideBar.lua` | Block palette sidebar |
| `GameDesktop.lua` | In-game desktop overlay |
| `Pages/OpenWorldPage.html` | Open world browser |
| `Pages/*` | Additional standalone pages |

## Areas (`Game/Areas/` — 108 files)

In-world panel UI embedded in creator/play mode:

| Area | Examples |
|------|----------|
| Chat system | `ChatSystem/ChatWindow`, `PrivateChatManager`, `ChatChannelPage` |
| Settings | `SystemSettingsPage.html`, `TextureModPage` |
| World modes | `World2In1FramePage`, `OpenWorldPage` |
| Creator tools | `CreatorMachine.lua`, `SpecialBlockBuilder` |
| Community chat | `ChatSystem/ChatWindow.community.html` |

Pattern: paired `.lua` controller + `.html` MCML page.

## GUI (`Game/GUI/` — 83 files)

3D editor controls and dialogs:

| Component | Role |
|-----------|------|
| `Transform3DController.lua` | 3D gizmo manipulation |
| `OpenAssetFileDialog.html` | Asset picker |
| Various manipulators | Model/block transform in edit mode |

Works with `Tasks/EditModel/`, `SceneContext/SelectionManager`.

## MCML elements

| Path | Version |
|------|---------|
| `Game/mcml/` | Creator-specific v1 (`pe_mc_block`, `pe_mc_slot`) |
| `Game/mcml2/` | MCML v2 elements |

See [mcml-ui.md](../mcml-ui.md).

## Setting (`Game/Setting/`)

- `ServerSetting.lua` — multiplayer server config UI

## SceneContext (`Game/SceneContext/` — 18 files)

Edit mode context switching:

| Class | Role |
|-------|------|
| `SelectionManager` | Current selection state |
| `BaseContext` | Context base class |

Docgen: [api-index.md](../api-index.md)

## Pages/ (Creator root)

Standalone wizards outside Game/Areas:

- World creation, photo sharing, embed pages

## See also

- [creator-tasks.md](creator-tasks.md) — task UI modules
- [mcml-ui.md](../mcml-ui.md)
- [creator-game-subsystems.md](creator-game-subsystems.md)
