# Packages and Build

How script/asset **packages** are defined, built, and deployed for ParaEngine products.

## Package types

Defined in `script/ide/package/package.lua`:

| Type | Directory | Behavior |
|------|-----------|----------|
| Startup | `packages/startup/` | Auto-loaded at `commonlib.package.Startup()` |
| Lib | `packages/` | Loaded on demand: `commonlib.package.require("name", "1.0")` |
| Installer | `packages/installer/` | User prompt on first run |
| Redist | `packages/redist/` | **Build manifests only** — source lists for zip creation |

## Zip file naming

```
packages/[subdir]/[PackageName]-[version].zip
```

Optional encrypted format: `.pkg` (official builds; zip takes precedence if both exist).

Startup script (optional):

```
[PackageName]-[version].zip.startup.lua
```

Example in repo: `packages/test-2.0.zip.startup.lua`

## Redist manifests (`packages/redist/`)

Text files listing what goes into each zip. See [Main Package](main-package.md) for the full manifest list.

Build pipeline helper:

```
packages/redist/Aries/main_pkg_pipeline.txt  — files stripped at pipeline stage
packages/redist/locale_exclude_list.teen.txt — teen locale exclusions
packages/redist/excel_xml_list.teen.txt      — teen Excel/XML data lists
```

## Runtime package loading

### At engine start

```lua
-- In ParaWorldCore.lua
commonlib.package.Startup();
```

Scans `packages/` (depth 1), registers zips, opens archives via `ParaAsset.OpenArchive()`.

### Paracraft external packages

Installed beside executable:

```
npl_packages/paracraft/
```

Loaded from Aries when not in dev mode:

```lua
if ParaEngine.GetAppCommandLineByParam("isDevEnv", "") == ""
   and ParaEngine.GetAppCommandLineByParam("src_paraworldapp", "") == "" then
    NPL.load("npl_packages/paracraft/");
end
```

GGS mod upgrade script (external): `GeneralGameServerMod/dev/upgrade.sh` → installed to `npl_packages/`.

## Building ParaWorld viewer

From HelloChat/Aries readme tradition:

```lua
NPL.load("(gl)script/installer/BuildParaWorld.lua");
commonlib.BuildParaWorld.BuildParaWorldViewer()
```

Then compile NSI: `parawroldviewer_installer_v1.nsi` → output in `[sdkroot]/release/`.

## Installer configs

`script/installer/`:

| File | Purpose |
|------|---------|
| `MSI.nsh` | NSIS installer script |
| `config_taurus_release_zhCN.txt` | Taurus zhCN release config |
| `config_taurus_release_enUS.txt` | Taurus enUS release config |
| `License_zhCN.txt` | License text |

## Bytecode vs source

Shipping builds compile Lua to `.o` bytecode under `bin/script/`. Manifests reference both:

```
script/apps/Aries/...     → source (development)
bin/script/apps/Aries/... → bytecode (shipping)
```

Manifest `[exclude]` rules often target `bin/script/` paths.

## Asset manifests (FTP uploader)

```
packages/redist/_coremanifest.ftp.uploader.txt
packages/redist/_assetmanifest.ftp.uploader.txt
```

Used for asset deployment pipelines (textures, models — external to this repo).

## NPL mod sample

`npl_mod/sample_mod/` — Example layout for custom NPL packages.

Paracraft in-world mods: `Creator/Game/NplMod/NplModNode.lua`

## Versioning

Multiple versions can coexist. `commonlib.package.require("name")` picks latest unless version specified.

Authors should write version-aware code when breaking changes occur.

## Dev workflow summary

| Mode | Packages | Script source |
|------|----------|---------------|
| SDK development | Optional zips | Direct `(gl)script/...` |
| `isDevEnv="true"` | Skips npl_packages/paracraft | Source tree |
| Production install | All startup + paracraft zips | Bytecode in zips |

## See also

- [Main Package](main-package.md)
- [Overview](overview.md)
- `script/ide/package/package.lua`
- `Mod/GeneralGameServerMod/Tutorial/readme.md` — GGS test environment setup
