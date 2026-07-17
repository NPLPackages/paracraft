# MCML UI Framework

**MCML (Markup Control Markup Language)** is ParaEngine's XML/HTML-like UI system. Haqi and ParaWorld use **MCML v1**; Paracraft Creator also uses **MCML v2** extensions.

Agent-specific instructions: `script/.github/instructions/mcml.instructions.md`

## Two implementations

| Version | Location | Used by |
|---------|----------|---------|
| **MCML v1** | `script/ide/System/Windows/mcml/` | Haqi, ParaWorld, most `.html` pages in Aries |
| **MCML v2 / Window** | `script/ide/System/UI/Window/` | Creator `mcml2/`, GGS modern UI |
| **Vue-style** | `script/ide/System/UI/Vue/` | GGS GI HTML pages |

Haqi pages are typically `*.html` files containing MCML markup (not plain HTML).

## Basic page structure

```html
<pe:mcml>
<script type="text/npl" src="Page.lua"><![CDATA[
]]></script>

<style type='text/mcss'>
{
    ['close_btn'] = {
        position = 'relative',
        width = 56,
        height = 56,
        background = 'Texture/player/close.png',
    },
}
</style>

<div style="width:100px">
    <input type="button" name="btn" class="close_btn" onclick="OnClick"/>
</div>
</pe:mcml>
```

### Key elements

- `<pe:mcml>` — Root element
- `<script type="text/npl">` — Lua code for page logic
- `<style type='text/mcss'>` — Styles as Lua table (not CSS)
- `onclick="HandlerName"` — Binds to Lua function in page script

## Conditional rendering (kids/teen)

```html
<pe:if condition='<%=System.options.isKid%>'>
    kids content
</pe:if>
<pe:if condition='<%=not System.options.isKid%>'>
    teen content
</pe:if>
```

## Common MCML elements

| Element | Purpose |
|---------|---------|
| `<pe:if>` | Conditional blocks |
| `<pe:gridview>` | Grid list |
| `<pe:treeview>` | Tree list |
| `<pe:repeat>` | Data-bound repetition |
| `<input type="button">` | Button |
| `<pe:textbox>` | Text input |

v1 element implementations: `script/ide/System/Windows/mcml/Elements/`

ParaWorld custom elements: `script/kids/3DMapSystemApp/mcml/`

Creator v2: `script/apps/Aries/Creator/Game/mcml2/mcml.lua`

## Page controller pattern

Lua file paired with HTML:

```lua
local Page = commonlib.gettable("MyCompany.Aries.Desktop.MyPage");

function Page:OnClick()
    -- handle click
end

function Page:Update()
    local page = self:GetPage();
    page:Refresh();  -- required after data changes
end
```

Access controls: `document:GetPageCtrl()`, `self:GetNodeByName("btn")`

## Styling (mcss)

MCSS uses Lua tables, not CSS files:

```lua
{
    ['my_class'] = {
        width = 100,
        height = 50,
        ['margin-left'] = 10,
        background = 'Texture/Aries/Common/button.png:5 5 5 5',  -- 9-slice
        ['background-color'] = '#ff2240',
    },
}
```

Nine-slice backgrounds: `texture.png:left top right bottom`

## File naming (Haqi)

| File | Version |
|------|---------|
| `Page.html` | Default (usually kids) |
| `Page.teen.html` | Teen UI |
| `Page.kids.html` | Explicit kids |

Selection in Lua:

```lua
local url = if_else(System.options.isKid, "Page.html", "Page.teen.html");
```

## Texture paths

UI textures typically under:

```
Texture/Aries/Common/ThemeTean/     # Teen theme
Texture/Aries/Desktop/              # Desktop widgets
Texture/Aries/HaqiShop/             # Shop UI
```

3D assets referenced in MCML use engine asset paths (`character/v5/...`).

## MCML in movies

`ide/Director/MovieRender_Mcml.lua` renders MCML as movie frames.

## Window framework (v2)

`script/ide/System/UI/Window/readme.md` documents the newer window element system with proper event propagation (`ActivateEvent`, etc.).

## UI design guidelines (Paracraft/GGS)

From `script/ide/System/UI/Readme.md`:

- Default design canvas: **1280×720** (Paracraft main window)
- UI should scale for different resolutions
- Blockly controls integrate with this framework

## Debugging MCML

- Missing refresh → stale UI: call `page:Refresh()`
- Test pages: `script/kids/3DMapSystemApp/mcml/test/`, `script/test/MCMLV2/`
- F12 console for Lua errors in page scripts

## See also

- [Haqi / Aries](haqi-aries.md) — kids/teen UI conventions
- [IDE Framework](ide-framework.md)
- [Paracraft](paracraft.md) — Creator mcml2
