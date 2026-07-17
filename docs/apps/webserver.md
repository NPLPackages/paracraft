# WebServer Application

NPL-based HTTP server with WordPress-like admin CMS. `script/apps/WebServer/` (~249 files).

Source: `script/apps/WebServer/readme.txt` (LiXizhi, 2011)

## Implementations

| Implementation | Technology |
|----------------|------------|
| Legacy `httpd.lua` | luasocket + copas coroutines |
| **Current** | NPL async messaging (faster, recommended) |

## Starting the server

```lua
NPL.load("(gl)script/apps/WebServer/WebServer.lua");
WebServer:Start("script/apps/WebServer/test");
```

Shell loop bootstrap:

```
bootstrapper="script/apps/WebServer/shell_loop_webserver.lua"
bootstrapper="..." config="script/apps/WebServer/test/webserver.config.xml"
```

## Configuration

`webserver.config.xml` in web root (or `default.webserver.config.xml`):

- `<servers>` — host/port, `host_state_name` (NPL thread)
- Serves `*.lua`, `*.page`, static files

Example: `script/apps/WebServer/test/webserver.config.xml`

## Directory layout

```
WebServer/
├── WebServer.lua           # Main server class
├── npl_script_handler.lua  # NPL script as HTTP handler
├── npl_util.lua            # Utilities
├── log_service.lua         # Logging
├── mem_cache.lua           # Memory cache
├── httpd/                  # Legacy httpd + wsapi
│   ├── common_handlers.lua
│   └── wsapi_util.lua
├── admin/                  # ★ WordPress-like CMS (~200 files)
│   ├── index.page
│   ├── wp-config.page
│   ├── wp-settings.page
│   ├── wp-includes/        # Core (NPL.js, angular, jeasyui, blockly)
│   └── wp-content/
│       ├── pages/wiki/     # Wiki CMS modules
│       ├── themes/sensitive/
│       └── database/
└── test/                   # Test site
```

## Admin CMS (`admin/`)

WordPress-inspired `.page` template system:

| Area | Purpose |
|------|---------|
| `wp-content/pages/wiki/` | Wiki site (home, projects, user stars) |
| `mod/packages/` | Package install UI (paraworld packages wiki) |
| `mod/worldshare/` | WorldShare admin (login, opus, worlds stats) |
| `wp-includes/js/NPL.js` | Client NPL bridge |
| `wp-includes/js/blockly/` | Web Blockly |
| Themes | `themes/sensitive/` |

## Wiki modules

| Module | Path | Purpose |
|--------|------|---------|
| packages | `mod/packages/` | Package management controllers |
| worldshare | `mod/worldshare/` | World/person/opus admin pages |

## Test site

`test/` — sample pages, `sample_util.lua`, `test_include.page`

## Relationship to products

- Official Paracraft site references in admin readme
- Internal tooling / community wiki — not shipped in client `main_script`
- Excluded from standard client package

## See also

- [Applications Catalog](applications-catalog.md)
- [Packages and Build](packages-and-build.md)
- [Legacy Client Networking](legacy-client-networking.md)
