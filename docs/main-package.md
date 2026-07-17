# Main Package

The **main package** is the primary script bundle shipped with ParaEngine/Paracraft executables. In this repo it is defined by **redist manifest files** under `packages/redist/`, not by a single folder.

## Package system overview

ParaEngine loads content as versioned zip/pkg archives. The NPL package system (`script/ide/package/package.lua`) manages four kinds:

| Type | Folder | When loaded |
|------|--------|-------------|
| **startup** | `packages/startup/` | At engine start via `commonlib.package.Startup()` |
| **lib** | `packages/` | On demand via `commonlib.package.require("name", "1.0")` |
| **installer** | `packages/installer/` | Prompts user at first run |
| **redist** | `packages/redist/` | Source manifests for building zips (not auto-loaded) |

Zip naming: `[PackageName]-[version].zip` (e.g. `main_script-1.0.zip`).

At runtime, `ParaWorldCore.lua` calls `commonlib.package.Startup()` which scans `packages/` and loads startup packages.

Paracraft additionally loads external packages from the install directory:

```lua
NPL.load("npl_packages/paracraft/");
```

This happens in `script/apps/Aries/main_loop.lua` and `Creator/Game/main.lua` when not in dev mode.

## Main script manifests

The core script bundle is **`main_script`** version **1.0**. Multiple manifest variants exist for different product builds:

| Manifest file | Build target |
|---------------|--------------|
| `packages/redist/main_script-1.0.txt` | Standard Haqi/Aries client (excludes many apps) |
| `packages/redist/main_script-1.0.teen.txt` | Teen locale variant |
| `packages/redist/main_script_paracraft-1.0.txt` | **Paracraft-focused** build (Creator + Aries, tighter excludes) |
| `packages/redist/main_script_complete-1.0.txt` | Full script tree |
| `packages/redist/main_script_complete_mobile-1.0.txt` | Mobile complete build |
| `packages/redist/main_script_append-1.0.txt` | Append/incremental overlay |
| `packages/redist/main_commonlib.txt` | Commonlib subset |
| `packages/redist/source_script.txt` | Source distribution list |

### Manifest format

Each `.txt` manifest uses INI-like sections:

```ini
[packageName]=main_script
[packageVersion]=1.0
[packagePath]=packages/redist
[filterList]=*.*

[exclude]script/apps/HelloChat/*.*
[exclude1]bin/script/kids/main.o
```

- `[exclude]` — exclude path and all subdirectories
- `[exclude1]` — exclude only files in that directory (no recursion)
- `[exclude3]` — exclude with max depth 3

Compiled `.o` files under `bin/script/` are the bytecode output included in shipping builds; source `.lua` lives under `script/`.

## What `main_script-1.0.txt` includes vs excludes

**Included (core product):**

- `script/ide/` — Full IDE framework
- `script/kids/` — ParaWorld platform (partial bytecode in bin)
- `script/apps/Aries/` — Haqi + Paracraft client
- `script/apps/GameServer/` — Game server (partial; LobbyService excluded)
- `script/AI/`, `script/lang/`, parts of `script/network/`

**Excluded (dev, samples, alternate apps):**

| Excluded path | Reason |
|---------------|--------|
| `script/apps/HelloChat`, `HelloWorld`, `Orion`, `Aquarius`, `Taurus` | Sample/alternate clients |
| `script/apps/Aries/Pipeline`, `Debug` | Internal dev tools |
| `script/apps/DBServer`, `IMServer`, `NPLRouter`, `PayServer` | Server infra (separate deploy) |
| `script/test/`, `script/templates/`, `script/demo/` | Development |
| `script/kids/3DMapSystemNetwork/` (bin) | Legacy network stack bytecode trimmed |
| `bin/script/kids/BCS`, `CCS`, `Ui` | Legacy UI modules |

## Paracraft manifest differences

`main_script_paracraft-1.0.txt` is optimized for **Paracraft Creator**:

- Excludes obsolete Creator config: `config/Aries/creator/bom/`, `buildingtask/`, `blocktemplates/`
- Excludes teen-specific sources: `script/*.teen.*`
- Trims more `script/kids/` legacy modules
- Keeps `script/apps/Aries/Creator/Game/` intact

## Companion asset packages

Script is only part of the product. Related redist manifests (assets, not in this repo's file tree):

| Package | Manifest | Contents |
|---------|----------|----------|
| Textures | `main_texture-1.0.txt` | UI and world textures |
| Characters | `art_model_char_Aries-1.0.txt` | Haqi character models |
| Characters (Taurus) | `art_model_char_Taurus-1.0.txt` | Taurus app models |
| Mobile resources | `main_mobile_res-1.0.txt` | Mobile-specific assets |
| Map models | `map model-1.0.txt` | Map/terrain models |
| AB test resources | `ab_res-1.0.txt` | A/B SDK resources |

## Pipeline exclusions

`packages/redist/Aries/main_pkg_pipeline.txt` lists files stripped at build pipeline stage (debug HTML, Pipeline tools, Combat debug assets):

```
script/apps/Aries/Pipeline/*
script/apps/Aries/Debug/*
script/apps/Aries/Combat/*.html
```

## Startup flow

```
ParaEngine starts
    │
    ▼
commonlib.package.Startup()
    │  scans packages/startup/*.zip
    │  opens archives via ParaAsset.OpenArchive
    ▼
ParaWorldCore.lua (PostLoad)
    │  NPL.load IDE, System, Debugger
    │  loads 3DMapSystem modules
    ▼
App main_loop.lua (e.g. Aries/main_loop.lua)
    │  optional: NPL.load("npl_packages/paracraft/")
    │  System.init(), theme, login
    ▼
Game running
```

## Dev mode vs shipping

When developing from source tree (not zip packages):

| Flag | Effect |
|------|--------|
| `isDevEnv="true"` | Skips `npl_packages/paracraft/` auto-load |
| `src_paraworldapp` set | Skips paracraft package load |
| Source paths `(gl)script/...` | Loads `.lua` directly from disk |

## Building packages

Historical workflow (from HelloChat readme):

```lua
NPL.load("(gl)script/installer/BuildParaWorld.lua");
commonlib.BuildParaWorld.BuildParaWorldViewer()
```

The AssetsApp **PackageMaker** tool (in full SDK) creates redistributable zips from `packages/redist/` manifests.

Installer NSI scripts live in `script/installer/` (e.g. `MSI.nsh`, `config_taurus_release_zhCN.txt`).

## See also

- [Packages and Build](packages-and-build.md)
- [Overview](overview.md)
- [Paracraft](paracraft.md)
- Source: `script/ide/package/package.lua`
