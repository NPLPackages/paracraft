# NPL and Module Patterns

**NPL (Neural Parallel Language)** is ParaEngine's script runtime built on Lua with coroutine-based parallelism, file-based modules, and engine integration.

This page documents patterns used throughout paraworld. **Do not use standard Lua `require()`** in this codebase.

## Loading modules

```lua
-- Correct
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");

-- Wrong for this codebase
require("game_logic")
```

### Runtime state prefix

| Prefix | Meaning |
|--------|---------|
| `(gl)` | Global main runtime state |
| `(world1)` | Named worker state (game server) |
| `(npl)` | NPL internal |

### PostLoad deferral

Heavy initialization is deferred:

```lua
NPL.PostLoad(function()
    NPL.load("(gl)script/ide/System/System.lua");
end)
```

## Retrieving module tables

```lua
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
```

Modules register themselves by assigning to the namespace:

```lua
local GameLogic = commonlib.inherit(..., commonlib.gettable("MyCompany.Aries.Game.GameLogic"));
-- or at file end:
MyCompany.Aries.Game.GameLogic = GameLogic;
```

## Exporting modules

```lua
NPL.export("MyCompany.Aries.Game.BlockEngine");
```

## Activation (coroutine scripts)

Long-running or periodic scripts use `NPL.activate`:

```lua
local function activate()
    if main_state == 0 then
        -- idle loop
    elseif main_state == nil then
        main_state = 0;
    end
end
NPL.this(activate);
```

Game loops (`main_loop.lua`) use finite state machines with `main_state`.

## Object-oriented pattern

```lua
NPL.load("(gl)script/ide/commonlib.lua");

local Entity = commonlib.inherit(
    commonlib.gettable("System.Core.ToolBase"),
    commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity")
);

function Entity:ctor()
    self.field = 0;
end

function Entity:Init(params)
    -- setup
    return self;
end
```

## Singleton access

Many game systems are singletons accessed via gettable:

```lua
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
GameLogic:Start();
```

## Coroutines in code blocks

Visual programming code runs in coroutines. The compiler injects `checkyield()` in loops. Use `wait(seconds)` for delays — not OS timers.

```lua
while true do
    move(0.01, 0);  -- auto-yields
    wait(2);        -- explicit yield
end
```

See [Code Blocks](code-blocks-and-visual-programming.md).

## Conditional loading (kids/teen)

```lua
if System.options.isKid then
    NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.kids.lua");
else
    NPL.load("(gl)script/apps/Aries/HaqiShop/HaqiShop.teen.lua");
end
```

## Lazy load with second parameter

```lua
local ParacraftCI = NPL.load("(gl)script/apps/Aries/ParacraftCI/ParacraftCI.lua", true);
```

Second `true` argument can defer or force reload depending on context.

## Common namespaces

| Prefix | Domain |
|--------|--------|
| `MyCompany.Aries.*` | Haqi + Paracraft game code |
| `MyCompany.Aries.Game.*` | Paracraft Creator engine |
| `Map3DSystem.*` | ParaWorld platform |
| `System.*` | IDE framework |
| `commonlib.*` | Utilities |
| `IMServer.*` | IM server client |
| `GGS.*` / GI modules | General Game Server mod |

## File header convention

Most files start with a structured comment block:

```lua
--[[
Title: Block Engine
Author(s): LiXizhi
Date: 2012/10/18
Desc: Voxel world management
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/.../block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
------------------------------------------------------------
]]
```

## Debugging

```lua
-- Console
echo("debug");
commonlib.echo(table_data);

-- Structured log
LOG.std(nil, "debug", "BlockEngine", "block at %d,%d,%d", x, y, z);

-- IPC debugger (if enabled)
IPCDebugger.Start();
```

Enable via command line: `httpdebug="true"`

## Localization

```lua
local msg = L"这是中文文本";
```

## Gotchas

1. **Never `require()`** — breaks NPL module paths and runtime states
2. **UI refresh** — MCML pages don't auto-update; call `page:Refresh()` after data changes
3. **Runtime state** — server code must use correct `(worldN)` prefix
4. **Dev vs zip** — `(gl)script/...` loads source; production may load from zip archives

## See also

- [IDE Framework](ide-framework.md)
- [Overview](overview.md)
- `.github/instructions/paracraft.instructions.md`
- `script/ide/NPLExtension.lua`
