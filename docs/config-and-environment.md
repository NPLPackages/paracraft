# Config and Environment

There is **no repo-root `config/` folder** in this script tree. Configuration is distributed across subsystems.

## Config locations inventory

| Path | Purpose |
|------|---------|
| `Mod/WorldShare/config/Config.lua` | WorldShare API environment (ONLINE/STAGE/RELEASE/LOCAL) |
| `Creator/Game/Network/Config/` | Server auth, ban, password lists |
| `script/ide/config/NPLStateConfig.lua` | NPL runtime state config |
| Runtime: `config/EmuUsersDB.xml` | JGSL emulated users (install dir, not in repo) |
| Runtime: `config/Aries/creator/` | Paracraft game data XML — [config/aries-creator.md](config/aries-creator.md) |
| Runtime: `config/Aries/Cards/`, `Spells/`, … | Haqi data — [config/aries-haqi-data.md](config/aries-haqi-data.md) |
| Command line | Primary runtime config mechanism |

## WorldShare environment

`Mod/WorldShare/config/Config.lua`:

```lua
-- Config.defaultEnv selects API endpoints
-- Values: ONLINE, STAGE, RELEASE, LOCAL
```

Switching env changes Keepwork/API base URLs for cellar UI flows.

## Network server ACL

`Creator/Game/Network/Config/` — Lua list files (not JSON/YAML):

| File | Content |
|------|---------|
| `ServerConfig.lua` | Server settings |
| `AuthUserList.lua` | Allowed usernames |
| `BanList.lua` | Banned users |
| `PasswordList.lua` | Room passwords |

## Command-line configuration

Most runtime behavior configured via ParaEngine CLI key/value pairs:

| Parameter | Subsystem |
|-----------|-----------|
| `bootstrapper` | App selection |
| `mc`, `servermode`, `world`, `ip`, `port` | Paracraft/Creator |
| `username`, `password`, `gateway` | Haqi auth |
| `version` (kids/tean) | Haqi UI variant |
| `keepworktoken`, `usertoken` | WorldShare SSO |
| `isDevMode`, `isDevEnv` | Developer flags |
| `channelId` | Distribution channel |
| `lang` | Localization |
| `-lang enUS` | Via lang.lua (deprecated path) |

See `script/apps/Aries/main_loop.lua` header for full Aries list.

## System.options runtime flags

Set during bootstrap in `main_loop.lua` and `ParaWorldCore.lua`:

```lua
System.options.mc              -- Paracraft creator mode
System.options.isKid           -- Haqi kids UI
System.options.version         -- "kids" or "teen"
System.options.servermode      -- Headless server
System.options.isDevMode       -- Developer mode
System.options.isAB_SDK        -- A/B SDK detection
System.options.channelId       -- Release channel
```

## Creator config (`config/Aries/creator/`)

**Full documentation:** [config/aries-creator.md](config/aries-creator.md)

Key root files: `block_types.xml`, `block_list.xml`, `PlayerAssetFile.xml`, `Commands.xml`, `paracraft_script_version.xml`

Excluded from main Paracraft zip: `bom/`, `buildingtask/`, `blocktemplates/`, `obsoleted/`

Haqi sibling data: [config/aries-haqi-data.md](config/aries-haqi-data.md)

## GGS mod config

`Mod/GeneralGameServerMod/config.xml` — GGS mod configuration.

## See also

- [WorldShare Cellar](worldshare-cellar.md)
- [Creator Network](aries/creator-network.md)
- [Main Package](main-package.md)
- [Overview](overview.md)
