# `config/Aries/creator/` — Paracraft Game Data

Paracraft **game configuration and content data** lives at `config/Aries/creator/` beside the executable — **not in the `paraworld` script repo**. This page documents the layout, file formats, and code loaders inferred from source references.

## Where it lives

```
[ParaCraft install root]/
├── ParaCraft.exe
├── script/                    ← paraworld repo (Lua source)
├── config/
│   └── Aries/
│       ├── creator/           ← ★ this document
│       └── Audio/
│           └── CreatorSound.bank.xml   (shipped with Paracraft build)
└── worlds/
```

In development, paths resolve relative to the **working directory / install root** via `ParaIO` and `ParaXML.LuaXML_ParseFile()`.

## Relationship to this repo

| In paraworld repo | At runtime install |
|-------------------|-------------------|
| `script/apps/Aries/Creator/Game/blocks/block_types.lua` | Loads `config/Aries/creator/block_types.xml` |
| Lua block/entity classes | XML defines IDs, textures, templates |
| Package manifests list what ships | `packages/redist/main_script_paracraft-1.0.txt` |

You edit XML/MO/PO in the **installed product tree** or a separate assets repo — not under `paraworld/script/`.

## Package shipping rules

From `packages/redist/main_script_paracraft-1.0.txt`:

**Included in Paracraft build:**

```
config/Aries/creator/*.xml
config/Aries/creator/*.mo
config/Aries/Audio/CreatorSound.bank.xml
```

**Excluded from standard Paracraft zip** (dev/content pipeline only):

| Excluded path | Typical content |
|---------------|-----------------|
| `config/Aries/creator/bom/` | Bill-of-materials for build quests |
| `config/Aries/creator/buildingtask/` | Legacy building-task data |
| `config/Aries/creator/blocktemplates/` | Tutorial templates (large; separate mobile pack) |
| `config/Aries/creator/obsoleted/` | Deprecated configs |

**Mobile resource pack** (`main_mobile_res-1.0.txt`) **includes**:

```
config/Aries/creator/blocktemplates/*.xml
```

**Source distribution** (`source_script.txt`) also publishes:

```
config/Aries/creator/*.po   (translation source)
```

## Directory tree (inferred)

```
config/Aries/creator/
├── *.xml                      # Root config files (see catalog below)
├── *.mo / language/*.po       # gettext translations
├── PersonalPageTutorial.json  # Copilot tutorial config
│
├── language/
│   ├── paracraft_zhCN.po
│   ├── paracraft_enUS.po
│   └── paracraft_enUS.mo
│
├── blocktemplates/
│   └── buildingtask/          # Official tutorial themes
│       ├── MovieMaking/info.xml
│       ├── newusertutorial/info.xml
│       ├── newyearbuilding/info.xml
│       ├── circuit/info.xml
│       ├── smallstructure/info.xml
│       └── [theme]/           # Per-theme folder or .zip
│           ├── info.xml       # Theme metadata
│           └── *.bom / steps  # Build quest data
│
├── template/
│   ├── sandtable/             # Sand table block layouts
│   │   └── {name}.blocks.xml
│   └── letter/                # Letter templates
│       └── {name}.blocks.xml
│
├── Animation/Player/          # Player animation block scripts
│   ├── Send2.blocks.xml
│   └── Eat1.blocks.xml
│
├── lesson_ppt/                # Red Summer Camp course PPT
│   ├── lesson_config.xml
│   └── {course}.md.xml
│
├── email/                     # (optional) versioned email templates
│   └── email_{version}.xml
│
├── bom/                       # [excluded] BOM data
├── buildingtask/              # [excluded] legacy tasks
└── obsoleted/                 # [excluded] deprecated files
```

User world templates use a **different path**:

```
worlds/DesignHouse/blocktemplates/   # User "世界模板" (BlockTemplatePage category 1)
```

## Root XML file catalog

| File | Loaded by | Purpose |
|------|-----------|---------|
| **block_types.xml** | `block_types.LoadFromFile()` | **Master block registry** — all block IDs, textures, classes |
| **block_types_template.xml** | `block_types.LoadBlockTemplates()` | Reusable block attribute templates |
| **block_list.xml** | `ItemClient.LoadGlobalBlockList()` | Block palette categories for inventory UI |
| **block_materials.xml** | `BlockMaterialEditor` | Custom block materials |
| **PlayerAssetFile.xml** | `PlayerAssetFile:LoadFromXMLFile()` | Placeable actor/asset catalog |
| **PlayerAnimAssetFile.xml** | `PlayerAssetFile` (animations) | Player animation assets |
| **PlayerSkins.xml** | `PlayerSkins:Init()` | Player skin definitions |
| **ModelTemplatesFile.xml** | `ModelTemplatesFile:LoadFromXMLFile()` | 3D model templates |
| **CustomCharItems.xml** | `CustomCharItems:Init()` | Character customization items |
| **CustomCharList.xml** | `CustomCharItems` | Character list |
| **CustomCharSkinItems.xml** | `EditCCS/CustomCharSkinItems` | Custom skin items |
| **CustomCharSkinItems.Teen.xml** | Same (teen variant) | Teen skins |
| **StarDreamSuit.xml** | `CustomCharItems` | Star dream suit outfits |
| **Commands.xml** | `CommandManager` | Slash command definitions |
| **shortcutkey.xml** | `HelpPage` | Keyboard shortcut help |
| **modelAnim.xml** | `EntityAnimation`, `HelpPage` | Model animation name map |
| **WebTutorials.xml** | `WebTutorials:LoadAllTutorials()` | Context-sensitive tutorial hooks |
| **LoopWords.mc.xml** | `LoopTips.lua` (mc mode) | Rotating tip text |
| **LoopWords.mobile.xml** | `LoopTips.lua` (mobile) | Mobile tip text |
| **local_texture_replace.xml** | `LocalTextures` (mobile) | Block texture substitutions |
| **paracraft_script_version.xml** | `VersionSetting`, `KeepworkUsersApi`, `PapaUtils`, `ClassCodeLogin` | **Login/script version string** |
| **Original_Commands.xml** | (referenced in publish tool) | Command source before processing |

## Key file formats

### `block_types.xml`

Loaded at startup by `block_types.LoadFromFile()` in `Creator/Game/blocks/block_types.lua`.

```xml
<blocks>
  <block id="1" name="Stone" text="石头" template="cube?filename=stone"
         texture="Texture/blocks/stone.png" solid="true" class="BlockLogic"
         material="stone" ... />
</blocks>
```

Processing highlights:

- XPath: `/blocks/block`
- `template="Name?filename=..."` merges attributes from `block_types_template.xml`
- `text`, `searchkey`, `tooltip` run through `L""` localization
- Boolean attrs parsed: `solid`, `light`, `liquid`, `obstruction`, etc.
- `class` maps to Lua block class in `blocks/Block*.lua`
- IDs must be `0–65534`

Template file XPath: `/block_templates/block` in `block_types_template.xml`.

### `block_list.xml`

Inventory palette for block picker. Loaded by `ItemClient.LoadGlobalBlockList()`.

```xml
<blocklist>
  <category name="basic">
    <block id="1" uid="..." version="mc|haqi" icon="..." tooltip="..."
           block_data="..." server_data="{...}" pin_index="1"/>
  </category>
</blocklist>
```

- Filters by `System.options.mc` → version `"mc"` or `"haqi"`
- `test_sdk` blocks only when `System.options.isAB_SDK`
- Categories feed sidebar block groups

### `PlayerAssetFile.xml`

Actor/model catalog for placement.

```xml
<assets>
  <category name="common">
    <asset name="..." filename="character/..." displayname="..." category="props"/>
  </category>
</assets>
```

- Categories: `common`, `people`, `effects`, `furnitures`, `props`, `equipment`, `vehicles`, `fantasy`, `animals`
- Education platform filters out assets with `"haqi"` in name

### `blocktemplates/buildingtask/{theme}/info.xml`

Build tutorial themes (`BuildQuestProvider`):

```xml
<Theme name="新手教程" order="1"/>
```

Themes are folders or `.zip` archives under `blocktemplates/buildingtask/`. Known subfolders (from xgettext list):

- `MovieMaking`, `newusertutorial`, `newyearbuilding`, `circuit`, `smallstructure`

Each theme contains step/BOM files consumed by `BuildQuestProvider` and `BuildQuestTask`.

### `paracraft_script_version.xml`

Simple version file for login compatibility checks:

```xml
<!-- first text node read as login_version -->
```

Used by `VersionSetting.GetLoginVersion()` and Keepwork user API.

### `WebTutorials.xml`

Maps user actions to tutorial keys; wiki base URL:

```
https://keepwork.com/official/paracraft/docs/
```

### Translations (`language/`)

| File | Role |
|------|------|
| `paracraft_zhCN.po` / `paracraft_enUS.po` | gettext source (zhCN is source language) |
| `paracraft_enUS.mo` | Compiled binary loaded at runtime |

Registration:

```lua
Translation.RegisterLanguageFile("config/Aries/creator/language/paracraft", lang);
```

Extraction tool: `script/ide/System/Util/xgettext.lua` — lists all translatable XML paths.

## Subdirectory reference

### `blocktemplates/buildingtask/`

Official **新手教程** (tutorial) block templates. UI: `BlockTemplatePage` category 2.

- Save dir: `config/Aries/creator/blocktemplates/buildingtask/`
- Loader: `BuildQuestProvider.LoadFromTemplate("tutorial", path)`
- Excluded from main Paracraft zip; included in mobile res pack

### `template/sandtable/` & `template/letter/`

Pre-built block layouts for World2In1 mode:

```lua
config/Aries/creator/template/sandtable/{name}.blocks.xml
config/Aries/creator/template/letter/{name}.blocks.xml
```

### `Animation/Player/`

Block-script animations for mini-game player actions (`UserBagItemManager`).

### `lesson_ppt/`

Red Summer Camp course content:

- `lesson_config.xml` — course schedule
- `{course}.md.xml` — per-course markdown/PPT content

### `bom/` & `buildingtask/` (excluded)

Legacy build-quest BOM storage. Referenced only in package **exclude** lists — not shipped in standard client.

### `obsoleted/` (excluded)

Deprecated configs kept for reference during migration.

## Code loader index

Quick lookup: **which Lua file reads which config?**

| Config path | Source file |
|-------------|-------------|
| `block_types.xml` | `Game/blocks/block_types.lua` |
| `block_types_template.xml` | `Game/blocks/block_types.lua` |
| `block_list.xml` | `Game/Items/ItemClient.lua` |
| `block_materials.xml` | `Game/Tasks/BlockMaterial/BlockMaterialEditor.lua` |
| `PlayerAssetFile.xml` | `Game/Entity/PlayerAssetFile.lua` |
| `PlayerAnimAssetFile.xml` | `Game/Entity/PlayerAssetFile.lua` |
| `PlayerSkins.xml` | `Game/Entity/PlayerSkins.lua` |
| `ModelTemplatesFile.xml` | `Game/Entity/ModelTemplatesFile.lua` |
| `CustomChar*.xml`, `StarDreamSuit.xml` | `Game/Entity/CustomCharItems.lua` |
| `CustomCharSkinItems*.xml` | `Game/Tasks/EditCCS/CustomCharSkinItems.lua` |
| `Commands.xml` | `Game/Commands/CommandManager.lua` |
| `shortcutkey.xml`, `modelAnim.xml` | `Game/Tasks/HelpPage.lua` |
| `WebTutorials.xml` | `Game/Areas/WebTutorials.lua` |
| `LoopWords.*.xml` | `Aries/Desktop/Dock/LoopTips.lua` |
| `local_texture_replace.xml` | `Game/Materials/LocalTextures.lua` |
| `paracraft_script_version.xml` | `Game/Setting/VersionSetting.lua`, `Mod/WorldShare/api/Keepwork/KeepworkUsersApi.lua` |
| `blocktemplates/buildingtask/` | `Game/Tasks/BuildQuestProvider.lua` |
| `template/sandtable/`, `letter/` | `Game/Areas/World2In1FramePage.lua` |
| `lesson_ppt/` | `Game/Tasks/RedSummerCamp/*.lua` |
| `Animation/Player/` | `Game/Tasks/MiniGame/UserBagItemManager.lua` |
| `PersonalPageTutorial.json` | `Game/Tasks/EasyBuilder/Copilot/PersonalPageTutorial.task.lua` |
| `language/*` | `Game/Common/Translation.lua` |

## Editing workflow

1. **Locate install root** — same folder as `ParaCraft.exe`
2. **Edit XML** — use UTF-8; many `text` fields use Chinese as source for `L""` / gettext
3. **Block changes** — edit `block_types.xml`, validate ID range; restart or reload world
4. **Translations** — edit `.po`, compile to `.mo` (PoEdit or project xgettext pipeline)
5. **Tutorial themes** — add folder under `blocktemplates/buildingtask/{name}/` with `info.xml`
6. **Commands** — edit `Commands.xml`; devs can regenerate via `CommandPublishSourceScript.lua`

## Related: sibling `config/Aries/` (Haqi data)

Not under `creator/` but co-located at install root:

| Path | Purpose |
|------|---------|
| `config/Aries/Cards/` | Combat card lists (`CardList.xml`, teen variants) |
| `config/Aries/Spells/` | Combat spell animations |
| `config/Aries/BagDefine_Teen/` | Haqi inventory bag definitions |
| `config/Aries/Others/` | Mob CCS configs |
| `config/Aries/HP/` | HP level mapping |

Loaded by `script/apps/Aries/Combat/`, `Desktop/`, etc. — see [combat-system.md](../aries/combat-system.md).

## See also

- [config-and-environment.md](../config-and-environment.md)
- [creator-blocks.md](../aries/creator-blocks.md)
- [main-package.md](../main-package.md) — shipping rules
- [creator-game-engine.md](../aries/creator-game-engine.md)
- Loader source: `script/apps/Aries/Creator/Game/blocks/block_types.lua`
