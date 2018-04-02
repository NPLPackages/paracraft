--[[
Title: all design related tags.
Author(s): LiXizhi
Date: 2008/2/15
Desc: pe:dialog, pe:tabs, pe:tab-item(onclick=""), pe:canvas3d, pe:slide (interval=3 order="sequence"|"random"), pe:filebrowser(rootfolder="script" filter="*.lua;*.txt"), pe:treeview and pe:treenode

---++ pe:tabs
This is a collection of tab pages.  Sub page content is created on demand and cached during page switching. One can also use it as an advanced radio box with buttons and text support. 

addtional display attribute. 
| *property* | *description* |
| SelectedMenuItemBG |  |
| UnSelectedMenuItemBG |  |
| MouseOverItemBG |  |
| TabPosition | if nil or "top", tab buttions are display on top. if "bottom", tab buttons are displayed at bottom. if "left" or "right", buttons are displayed vertically. 
	if "left", padding_left is the tab width.  if "right", padding_right is the control width |
| SelectedTextColor |  |
| TextShadowQuality | 4,8 |
| TextShadowColor | such as "#2a2a2e27" |
| TextOffsetY | such as -1 |
| ItemSpacing | spacing between menu item |
| TextColor |  |
| TextFont | text font, such as "System;12;norm" |
| ItemStyle | if empty it is text. if "ButtonOnly", it will display buttons |
| DefaultIconSize | default to 16. if one sets ItemStyle to "ButtonOnly", one usually needs to modify this as well | 
| DefaultIconPadding | default to 2, distance from icon to bg tab button border | 
| DefaultNodeHeight | default menu item node height. Mostly used in "left" or "right" TabPosition |
| style | css "padding-top" is the menu item height. The width is auto sized according to the item text, "padding-left" is the distance from the left boarder to the first menu. background is the container bg.  |
| onclick | a function(tabitem_name, tabitem_mcmlNode) end. The first parameter is the clicked tab item name. This function is invoked when the user clicks on the tab button |

Attributes of pe:tab-item
| *property* | *description* |
| SelectedMenuItemBG |  default to parent tabs |
| UnSelectedMenuItemBG | default to parent tabs  |
| MouseOverItemBG | default to parent tabs  |
| TextColor | default to parent tabs  |
| SelectedTextColor | default to parent tabs  |
| width | width of the tab button, default to parent tabs  |
| height | height of the tab button, default to parent tabs  |
| icon | this is only used when SelectedMenuItemBG and UnSelectedMenuItemBG are not specified. |
| condition | true or false. We can programmatically control the visibility of a given node.  |
<verbatim> 
	 <pe:tabs name="LoginSettings">
		<pe:tab-item text="ABC" selected="true">
		</pe:tab-item>
		<pe:tab-item text="EFG">
		</pe:tab-item>
	</pe:tabs>
	
	<pe:tabs name="LoginSettings" ItemStyle="ButtonOnly" DefaultIconSize="32" DefaultIconPadding="2">
		<pe:tab-item icon="a.png" text="ABC" selected="true">
		</pe:tab-item>
		<pe:tab-item icon="a.png" text="EFG">
		</pe:tab-item>
	</pe:tabs>
</verbatim>

---++ pe:filebrowser

File browser sample code: 
<verbatim> 
	 <pe:script>
        function TestFileBrowser_onclick(name, filepath)
          local filepath = document:GetPageCtrl():SetUIValue("filepath", filepath);
        end
        
        function TestFileBrowser_OnDoubleClick(name, filepath)
          _guihelper.MessageBox(tostring(filepath));
        end
     </pe:script>
     <input name="filepath">Please select from below</input><br/>
     <pe:filebrowser name="myFileBrowser" filter="*.lua;*.txt" rootfolder="script" onclick="TestFileBrowser_onclick()" ondoubleclick="TestFileBrowser_OnDoubleClick()"></pe:filebrowser>
     <pe:filebrowser name="myFileBrowser" style_mode="FileView" filter="*.x" ItemsPerRow="4" rootfolder="script" onclick="TestFileBrowser_onclick()" ondoubleclick="TestFileBrowser_OnDoubleClick()"></pe:filebrowser>
</verbatim>

addtional attributes and events: For more information, please see FileViewCtrl and FileExplorerCtrl.
 
| *property* | *description* |
| rootfolder| root folder |
| style_mode | if nil, it defaults to "TreeView". If "FileView", it will display items as icon. Once set it can not be changed. |
| onclick | function(name,filepath) end |
| ondoubleclick | function(name,filepath) end |
| oncreatenode | function(name,treeNode, filepath) end |
| oncheck | function(name,treeNode, filepath) end |
| onprerendernode | function(name,treeNode, filepath) end |
| AllowFolderSelection | bool |
| DisableFolderExpand | bool |
| HideFolder | bool |
| SelectedBG |  |
| DefaultFileIcon |  |
| FolderOpenIcon |  |
| FolderBackward |  |
| FolderIcon |  |
| ItemsPerRow | |
| DefaultNodeWidth |  |
| DefaultNodePadding |  |
| DefaultNodeHeight |  |
| DefaultIconSize |  |
| ShowFileName | bool |
| ShowUpFolder | bool |

---++ pe:canvas3d
*properties* src or value, miniscenegraphname, RenderTargetSize, rotSpeed, autoRotateSpeed, panSpeed, maxLiftupAngle, minLiftupAngle, maxZoomDist, minZoomDist, value

| value | this can be a table string like inner text in the example. It support embedded code. |
| autoRotateSpeed | such as 0.12 |
| miniscenegraphname | the render target name. if not set, a default render target is used. this default render target are the same for pe:canvas3d objects |
| ExternalSceneName | if not nil, it will render into miniscenegraphname; if not nil, object will be rendered into an external mini scene graph with this name. | 
| IgnoreExternalCamera | if not provided, it means "false". if true and ExternalSceneName is provided, we will set the external mini scene's camera according to this node's settings.  | 
| ExternalOffsetX | in case ExternalSceneName is provided, this is the offset used for displaying the object.  | 
| ExternalOffsetY | in case ExternalSceneName is provided, this is the offset used for displaying the object.  | 
| ExternalOffsetZ | in case ExternalSceneName is provided, this is the offset used for displaying the object.  | 
| DefaultCameraObjectDist | number |
| DefaultLiftupAngle | |
| DefaultRotY | |
| FieldOfView | defaults to 3.14/6 (60 degrees)|
| MaskTexture | alpha mask texture |
| RenderTargetSize | such as 128, 256 |
| objectbinding | "selection",  it binds to System.obj.GetObjectParams(objectbinding); |
| cameraName  |   model config camera name  --clayman
| value | table or table string of inner text |
Canvas3d sample code:      
<verbatim> 
	 <pe:canvas3d name="canvas1">
        {
			name= "test model",
			AssetFile= "model/05plants/01flower/01flower/flower10_v_a.x",
			x=0,y=0,z=0,
        }
     </pe:canvas3d>
</verbatim>

---++ pe:canvas3dui
3D UI that is rendered to the main scene after UI is rendered. 
@note: Do not refresh the page too often, because it will cause any 3D scene contents to be reloaded. 

| miniscenegraphname | default to "DefaultCanvas3DUI" |
| LookAtX, LookAtY, LookAtZ | camera look at position |
| RotY, LiftupAngle, CameraObjectDist | camera eye position |
| originX, originY, originZ | relative origion in NPC db or world onload script, such as 255, 0, 255|
| OnLoadNPCDB | npc database to load with origion (originX, originY, originZ), such as "worlds/myworlds/arieslogin/arieslogin.npc.db" |
| OnLoadSceneScript | world onload script to load with origion (originX, originY, originZ), such as "worlds/myworlds/arieslogin/script/arieslogin_0_0.onload.lua"|

Canvas3dui sample code:      
<verbatim> 
	<pe:canvas3dui name="MyTestCanvas3DUI" miniscenegraphname="DefaultCanvas3DUI" 
        LookAtX="0" LookAtY="2" LookAtZ="0"
        RotY="1.57" LiftupAngle="0.3" CameraObjectDist="15" 
        originX="255" originY="0" originZ="255"
        OnLoadSceneScript = "worlds/myworlds/arieslogin/script/arieslogin_0_0.onload.lua"
        OnLoadNPCDB = "worlds/myworlds/arieslogin/arieslogin.npc.db" />
     <pe:canvas3d name="Avatar1" miniscenegraphname="Avatar1" 
        ExternalSceneName="DefaultCanvas3DUI" ExternalOffsetX="0" ExternalOffsetY="0" ExternalOffsetZ="0">
        {
            name= "test model",
            AssetFile= "model/05plants/01flower/01flower/flower10_v_a.x",
            x=0,y=0,z=0,
        }
     </pe:canvas3d>
</verbatim>

---++ pe:slide 
for images or text. It just changes a different page at a given interval. 

*properties*: interval=10 order="sequence"|"random"

---++ pe:progressbar 
a progress bar with onstep callback. One can use SetUIValue and GetUIValue to modify the current progress. 
Usually, one needs to call ParaEngine.ForceRender() in onstep callback. 

*properties*: Minimum = "0" Maximum = "100" Value = "0" Step = "10" onstep="AnyFunction"
| onstep | only called when step is reached. type of function(step) end |
| block_bg_autosize | "true" to enable auto image sizing to prevent image stretching. |
| isshowtooltip | "true" to enable. |
| Color | color string |
| Value | number value | 
| Minimum | number value | 
| Maximum | number value | 
| miniblockwidth | default to 21 pixels |
| Step | number value | 
| is_vertical | boolean | 
| block_overlay_bg | a texture that is uv animated from one direction to another. This must be a tilable texture of 2^n size.  |
| uv_speed | uv_speed number: pixel per second.  | 

*sample code*
<verbatim> 
	<pe:progressbar name="MyProgress" onstep="MyFunction()"/>
	<pe:progressbar name="MyProgress" Minimum = "0" Maximum = "100" Value = "0" Step = "10"/>
	<pe:progressbar name="MyProgress" blockimage="Texture/3DMapSystem/Loader/progressbar_bg.png" background="Texture/3DMapSystem/Loader/progressbar_filled.png" Color="255 0 0"/>
	<pe:progressbar name="progressbar_autosized"  isshowtooltip = "true" 
	        background = "Texture/Aries/Loader/progressbar_bg_32bits.png;0 0 215 9" 
            blockimage = "Texture/Aries/Loader/progressbar_overlay_32bits.png;0 0 215 9" 
            block_bg_autosize = "true" style="margin:6px;width:215px;height:9px;" Minimum = "0" Maximum = "100" Value = "50"/>
</verbatim> 

---++ pe:numericupdown
a numeric up down control is a text text plus spin buttons for inputing numeric values. 
One can use SetUIValue and GetUIValue to modify the current value. 

*properties*: 
| min		| default to 0 |
| max		| default to 100 |
| min_step	| default to nil, the minimum step value |
| value		| default to nil |
| valueformat| such as "%.1f" |
| style.background | background of slider bar, it also includes the spin buttons.|
| button_width | spin button width, default to 16 (pixels). |

*events* 
| onchange | onchange event, it can be nil, a string to be executed or a function of type void ()(value) |

*sample code*
<verbatim> 
	<pe:numericupdown name="MyNumber" onchange="MyFunction()" min="0" max="100" min_step="1" value="0" valueformat="%.3f"/>
</verbatim> 


---++ pe:sliderbar 
a slider bar control using a button and a container: both vertical and horizontal slider is provided
One can use SetUIValue and GetUIValue to modify the current value. 

*properties*: 
| min		| default to 0 |
| max		| default to 100 |
| min_step	| default to nil, the minimum step value |
| value		| default to nil |
| direction | nil, "vertical" or "horizontal". If nil it will deduce from the width and height.|
| style.background | background of slider bar. |
| button_bg | slider button background |
| button_width | default to 16 (pixel). |
| button_height | default to 16 (pixel). |
| IsShowEditor | boolean: whether to show an editor next to it. default to false.|
| tooltip | tooltip to display when mouse over |
| EditorFormat | string, such as "%.1f"|
| EditorWidth | int, default to 40 |


*events* 
| onchange | onchange event, it can be nil, a string to be executed or a function of type void ()(value) |

*sample code*
<verbatim> 
	<pe:sliderbar name="MySlider" onchange="MyFunction()" min="0" max="100" value="0"/>
	<pe:sliderbar name="MySlider1" onchange="MyFunction()" min="0" max="100" value="0" style="background:url(Texture/3DMapSystem/common/ThemeLightBlue/slider_background_16.png#4 8 4 7)" button_bg="Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png" button_width="16" button_height="16"/>
</verbatim> 


---++ pe:colorpicker
colorpicker control displays a color edit control with 3 sliderbars to adjust R,G,B value 
One can use SetUIValue and GetUIValue to modify the current RGB value. 

*properties*: 
| value		| can be in format "255 255 255" or "#FFFFFF", default to "255 255 255" |
| style.background | background of slider bar. |
| style.width | default to 182 |
| style.height | default to 72 |

*events* 
| onchange | onchange event, it can be nil, a string to be executed or a function of type void ()(red, green, blue) |

*sample code*
<verbatim> 
	<pe:colorpicker name="MyColorpicker" onchange="MyFunction()" value="128 64 255"/>
</verbatim> 

---++ pe:preloader
This tag can be inserted at any position(usually the end of page for z-ordering) in a MCML page. It will display a loading animation at any specified position
during the lifetime of the page, if the asset files in its inner text was not fully downloaded. 
More information, please see the "script/ide/AssetPreloader.lua"

| *properties* | *desc* |
| onprogress | callback of function(nItemLeft, loader) end |

*sample code*
<verbatim> 
	your other code that uses image files can be here. 
	<pe:preloader name="" onprogress="" text="Loading..." style="width:64px;height:64px;background:url(Texture/RotatingLoaderImage.png)">
		<textures>
			Texture/a.png;
			Texture/b.png;
			Texture/c.png;
		</textures>	
		<LoaderUITemplate>
			<img src="Texture/Alphadot.dds" width="32" height="32"/><br/>
			Loading, please stand by...
		</LoaderUITemplate>
	</pe:preloader>
</verbatim> 

---++ TODO: (not implemented) pe:dropdown
this is a control containing a standard mode display and a popup window mode display. This pe:dropdown can be used to create customizable dropdown list control. 
*sample code*
<verbatim> 
	your other code that uses image files can be here. 
	<pe:dropdown name="my_dropdown" value="selected_value">
		<normal_template>
			<%=Page:GetNodeValue("my_dropdown")%>
			this is normal mode display
			<input name="expand" value="Click to show popup"/>
		</normal_template>	
		<popup_template>
			this is displayed in the popup panel
		</popup_template>
	</pe:dropdown>
</verbatim> 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_design.lua");
-------------------------------------------------------
]]

local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");

-----------------------------------
-- pe:dialog control
-----------------------------------
local pe_dialog = commonlib.gettable("Map3DSystem.mcml_controls.pe_dialog");

function pe_dialog.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	width = width or mcmlNode:GetNumber("width")
	height = height or mcmlNode:GetNumber("height");
	
	-- create the dialog 
	_guihelper.ShowDialogBox(mcmlNode:GetAttribute("title"), mcmlNode:GetNumber("x"), mcmlNode:GetNumber("y"), width, height, 
		function(_parent)
			-- create each child node. 
			left, top = 5, 5
			width,height = width - 5, height-5
			local myLayout = mcml_controls.layout:new();
			myLayout:reset(left, top, width, height);
			
			local childnode;
			for childnode in mcmlNode:next() do
				local left, top, width, height = myLayout:GetPreferredRect();
				mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, myLayout)
			end
		end,
		mcmlNode:GetAttribute("onclick"));
end


-----------------------------------
-- pe:tabs control:
-- attribute <pe:tab-item onclick=""> where onclick is a function (tabpagename) end
-----------------------------------
local pe_tabs = commonlib.gettable("Map3DSystem.mcml_controls.pe_tabs");


-- tab pages are only created when clicked. 
function pe_tabs.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:tabs"] or mcml_controls.pe_html.css["pe:tabs"]) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height
		end
	end
	parentLayout:AddObject(width-left, height-top);
	parentLayout:NewLine();
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	
	local IconSize = mcmlNode:GetNumber("DefaultIconSize");
	local IconPadding = mcmlNode:GetNumber("DefaultIconPadding") or 2;
	if(IconSize and (IconSize+IconPadding*2)>padding_top) then
		padding_top = IconSize+IconPadding*2;
	end
		
	local buttonStyle = mcmlNode:GetAttribute("ButtonStyle");
	local tabPosition = mcmlNode:GetAttribute("TabPosition");
	local UnSelectedMenuItemBG = mcmlNode:GetString("UnSelectedMenuItemBG")
	local SelectedMenuItemBG = mcmlNode:GetString("SelectedMenuItemBG")
	-- the tab page container and background
	local background_overdraw = tonumber(css["background_overdraw"] or 0);
	local IsVertical;
	local instName = mcmlNode:GetInstanceName(rootName);
	local menu_left, menu_top, menu_width, menu_height;
	local cont_left, cont_top, cont_width, cont_height;
	if(not tabPosition or tabPosition=="top") then
		-- tab buttons are on top
		UnSelectedMenuItemBG = UnSelectedMenuItemBG or css.UnSelectedMenuItemBG
		SelectedMenuItemBG = SelectedMenuItemBG or css.SelectedMenuItemBG

		menu_left, menu_top, menu_width, menu_height = left+padding_left, top, width-left, padding_top;
		cont_left, cont_top, cont_width, cont_height = left, top+padding_top-background_overdraw, width-left-padding_right, height-top-padding_top-padding_bottom+background_overdraw;
	elseif(tabPosition=="bottom") then
		-- tab buttons are on bottom
		UnSelectedMenuItemBG = UnSelectedMenuItemBG or css.UnSelectedMenuItemBottomBG
		SelectedMenuItemBG = SelectedMenuItemBG or css.SelectedMenuItemBottomBG

		menu_left, menu_top, menu_width, menu_height = left+padding_left, height-padding_top, width-left, padding_top;
		cont_left, cont_top, cont_width, cont_height = left, top-background_overdraw, width-left-padding_right, height-top-padding_top-padding_bottom+background_overdraw;
	elseif(tabPosition=="left") then
		-- tab buttons are on left top
		UnSelectedMenuItemBG = UnSelectedMenuItemBG or css.UnSelectedMenuItemBG
		SelectedMenuItemBG = SelectedMenuItemBG or css.SelectedMenuItemBG

		menu_left, menu_top, menu_width, menu_height = left, top, padding_left, height-top-padding_top-padding_bottom;
		cont_left, cont_top, cont_width, cont_height = left+padding_left-background_overdraw, top, width-left-padding_left+background_overdraw, height-top-padding_top-padding_bottom;
		IsVertical = true;
	elseif(tabPosition=="right") then	
		-- tab buttons are on right top
		UnSelectedMenuItemBG = UnSelectedMenuItemBG or css.UnSelectedMenuItemBG
		SelectedMenuItemBG = SelectedMenuItemBG or css.SelectedMenuItemBG

		menu_left, menu_top, menu_width, menu_height = width-padding_right, top, padding_right, height-top-padding_top-padding_bottom;
		cont_left, cont_top, cont_width, cont_height = left, top, width-left-padding_right+background_overdraw, height-top-padding_top-padding_bottom;
		IsVertical = true;
	end

	local _this = ParaUI.CreateUIObject("container", instName.."_pageCont", "_lt", cont_left, cont_top, cont_width, cont_height)

	if(css and css.background) then
		_this.background = css.background;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		end
	else	
		_this.background = "";
	end
	local uiobject_id = _this.id;
	_parent:AddChild(_this);

	-- tab buttons 
	NPL.load("(gl)script/ide/MainMenu.lua");
	
	local ctl = CommonCtrl.MainMenu:new{
		name = instName,
		alignment = "_lt",
		left = menu_left,
		top = menu_top,
		width = menu_width,
		height = menu_height,
		parent = _parent,
		IsVertical = IsVertical,
		--SelectedTextColor = "190 118 0",
		ItemStyle = mcmlNode:GetString("ItemStyle"),
		ItemSpacing = mcmlNode:GetNumber("ItemSpacing") or css.ItemSpacing,
		TextColor = mcmlNode:GetString("TextColor") or css.TextColor,
		font = mcmlNode:GetString("TextFont") or css.TextFont,
		SelectedTextColor = mcmlNode:GetString("SelectedTextColor") or css.SelectedTextColor or "0 0 0",
		TextShadowColor = mcmlNode:GetString("TextShadowColor") or css.TextShadowColor,
		TextOffsetY = mcmlNode:GetNumber("TextOffsetY") or tonumber(css.TextOffsetY),
		TextShadowQuality = mcmlNode:GetNumber("TextShadowQuality") or tonumber(css.TextShadowQuality),
		MouseOverItemBG = mcmlNode:GetString("MouseOverItemBG") or css.MouseOverItemBG or "",
		DefaultNodeHeight = mcmlNode:GetNumber("DefaultNodeHeight") or css.DefaultNodeHeight,
		UnSelectedMenuItemBG = UnSelectedMenuItemBG,
		SelectedMenuItemBG = SelectedMenuItemBG,
		DefaultIconSize = IconSize,
		DefaultIconPadding = IconPadding,
	};

	local node = ctl.RootNode;
	-- search any tab items
	local selectedIndex;
	local childnode;
	
	for childnode in mcmlNode:next("pe:tab-item") do
		if(childnode:GetAttributeWithCode("condition", true, true)) then
			local tab_item_css = childnode:GetStyle(mcml_controls.pe_css.default["pe:tab-item"] or mcml_controls.pe_html.css["pe:tab-item"]) or {};
			local tab = node:AddChild(CommonCtrl.TreeNode:new({Name = "tab", 
				Text = childnode:GetAttributeWithCode("text",nil,true), 
				tooltip = childnode:GetAttributeWithCode("tooltip"),
				Icon = childnode:GetAttribute("icon"), 
				SelectedTextColor = childnode:GetString("SelectedTextColor"),
				TextShadowColor = childnode:GetString("TextShadowColor"),
				TextOffsetY = childnode:GetNumber("TextOffsetY"),
				TextShadowQuality = childnode:GetNumber("TextShadowQuality"),
				MouseOverItemBG = childnode:GetString("MouseOverItemBG"),
				UnSelectedMenuItemBG = childnode:GetString("UnSelectedMenuItemBG"),
				SelectedMenuItemBG = childnode:GetString("SelectedMenuItemBG"),
				TextColor = childnode:GetString("TextColor"),
				width = childnode:GetNumber("width") or tab_item_css.width,
				max_width = tab_item_css["max-width"],
				min_width = tab_item_css["min-width"],
				height = childnode:GetNumber("height"),
				onclick = pe_tabs.OnClickTab}));
			tab.rootName = rootName;
			tab.tabsName = instName;
			tab.uiobject_id = uiobject_id;
			tab.mcmlNode = childnode;
			--childnode.tab_treenode = tab;
			tab.mcmlNode.parent_style = style;
			tab.bindingContext = bindingContext;
			if(childnode:GetAttributeWithCode("selected", false, true)) then
				selectedIndex = tab.index;
			end
		end
	end
	ctl:Show(true);
	mcmlNode.control = ctl;
	-- switch to the seleted tab page. 
	if(selectedIndex) then
		mcmlNode.is_rendering = true;
		-- pass true to turn on silient mode, so that no onclick event is fired. 
		CommonCtrl.MainMenu.OnClickTopLevelMenuItem(ctl, selectedIndex);
		mcmlNode.is_rendering = false;
	end	
end

-- user clicks the tab button
function pe_tabs.OnClickTab(treeNode)
	local _parent = ParaUI.GetUIObject(treeNode.uiobject_id or ""); --  or (treeNode.tabsName.."_pageCont")
	if(_parent:IsValid()) then
		local nPageCount = treeNode.parent:GetChildCount();
		local i 
		for i = 1, nPageCount do
			local _page = _parent:GetChild(tostring(i));
			if(i == treeNode.index) then
				if(not _page:IsValid()) then
					-- create sub controls only on demand. 
					local css = treeNode.mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:tab-item"] or mcml_controls.pe_html.css["pe:tab-item"]) or {};
					local padding_left, padding_top, padding_bottom, padding_right = 
						(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
						(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);

					_page = ParaUI.CreateUIObject("container", tostring(i), "_fi", 0,0,0,0)
					_page.background = css.background or "";
					_parent:AddChild(_page);
					
					css = treeNode.mcmlNode.parent_style or css;
					mcml_controls.create(treeNode.rootName, treeNode.mcmlNode, treeNode.bindingContext, _page, padding_left, padding_top, _parent.width-padding_right, _parent.height-padding_bottom,
						{display=css["display"], color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["base-font-size"] = css["base-font-size"]});
				else	
					_page.visible = true;
				end
				if(treeNode.mcmlNode) then
					local onclick = treeNode.mcmlNode:GetAttribute("onclick") or treeNode.mcmlNode:GetParent():GetAttribute("onclick");
					if(onclick) then
						if(not treeNode.mcmlNode:GetParent().is_rendering) then
							mcml_controls.OnPageEvent(treeNode.mcmlNode, onclick, treeNode.mcmlNode:GetAttribute("name"), treeNode.mcmlNode)
						end
					end
				end
			else
				if(_page:IsValid()) then
					_page.visible = false;
				end
			end
		end
		pe_tabs.SetValue(treeNode.mcmlNode:GetParent(), treeNode.index)
	end
end

-- get the MCML value on the node. value is is the node name or text or index of the tab item node. 
function pe_tabs.GetValue(mcmlNode)
	local childnode;
	local i=1;
	for childnode in mcmlNode:next("pe:tab-item") do
		if(childnode:GetAttributeWithCode("condition", true)) then
			if(childnode:GetAttribute("selected")) then
				return childnode:GetString("name") or childnode:GetString("text") or i;
			end
			i = i + 1;
		end
	end
end

-- set the MCML value on the node. value is is the node name or text or index of the tab item node. 
function pe_tabs.SetValue(mcmlNode, value)
	local hasValue;
	local childnode;
	local i,index = 1, tonumber(value);
	for childnode in mcmlNode:next("pe:tab-item") do
		if(childnode:GetAttributeWithCode("condition", true)) then
			local text = childnode:GetString("name") or childnode:GetString("text");
			if(text == value or i==index) then
				childnode:SetAttribute("selected", "true")
				hasValue = true;
			else
				if(childnode:GetAttribute("selected")) then
					childnode:SetAttribute("selected", nil)
				end
			end
			i = i + 1;
		end
	end
	if(not hasValue) then
		-- add a new item if no value matches.
		log("warning: trying to set a value to pe:tabs whose tab item does not exist")
	end
end

-- get the UI value on the node, value is the node name or text or index of the tab item node. 
function pe_tabs.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl();
	if(ctl) then
		if(type(ctl)=="table" and type(ctl.GetSelectedIndex) == "function") then
			local index = ctl:GetSelectedIndex();
			local i=1;
			local childnode, value;
			
			for childnode in mcmlNode:next("pe:tab-item") do
				if(childnode:GetAttributeWithCode("condition", true)) then
					if(i==index) then
						value = childnode:GetString("name") or childnode:GetString("text");
					end
					i = i+1;
				end
			end
			return value or index;
		end	
	end
end

-- set the UI value on the node
function pe_tabs.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(type(ctl)=="table" and type(ctl.SetSelectedIndex) == "function") then
			local selected_node;
			local i,index = 1, tonumber(value);
			for childnode in mcmlNode:next("pe:tab-item") do
				if(childnode:GetAttributeWithCode("condition", true)) then
					local text = childnode:GetString("name") or childnode:GetString("text");
					if(text == value or i==index) then
						ctl:SetSelectedIndex(i);
						-- change page node as well.
						childnode:SetAttribute("selected", "true")
						selected_node = childnode;
					else
						if(childnode:GetAttribute("selected")) then
							childnode:SetAttribute("selected", nil)
						end
					end
					i = i + 1;
				end
			end
			--if(selected_node and selected_node.tab_treenode) then
				--pe_tabs.OnClickTab(elected_node.tab_treenode);
			--end
		end	
	end
end

-----------------------------------
-- pe:slide control: slide show control: for images or text
-- attribute: interval=10 order="sequence"|"random"
-----------------------------------
local pe_slide = commonlib.gettable("Map3DSystem.mcml_controls.pe_slide");

function pe_slide.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	local instName = mcmlNode:GetInstanceName(rootName);
	local css = mcmlNode:GetStyle(mcml_controls.pe_html.css["pe:slide"]) or {};
	local alignment = "_lt";
	if(css.float == "right") then
		if(css["vertical-align"] and css["vertical-align"] == "bottom") then
			alignment = "_rb";
		else
			alignment = "_rt";
		end
	else
		if(css["vertical-align"] and css["vertical-align"] == "bottom") then
			alignment = "_lb";
		end
	end
	
	local myLayout = parentLayout:clone();
	myLayout:SetUsedSize(0,0);
	local left, top, width, height = myLayout:GetPreferredRect();
	myLayout:SetPos(left,top);
	
	local padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	if(css.width) then
		myLayout:IncWidth(left+margin_left+margin_right+css.width-width)
	end
	
	if(css.height) then
		myLayout:IncHeight(top+margin_top+margin_bottom+css.height-height)
	end	
	
	-- for inner control preferred size
	myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
	myLayout:IncWidth(-margin_right-padding_right)
	myLayout:IncHeight(-margin_bottom-padding_bottom)	
	
	-- create editor container
	local parent_left, parent_top, parent_width, parent_height = myLayout:GetPreferredRect();
	
	parent_left = parent_left-padding_left;
	parent_top = parent_top-padding_top;
	parent_width = parent_width + padding_right
	parent_height = parent_height + padding_bottom
	local _this = ParaUI.CreateUIObject("container", instName, alignment, parent_left, parent_top, parent_width-parent_left,parent_height-parent_top)
	_parent:AddChild(_this);
	_this.onframemove = string.format(";Map3DSystem.mcml_controls.pe_slide.onframemove(%q, %q);", instName, rootName);
	_parent = _this;
	Map3DSystem.mcml.SetNode(instName, mcmlNode);
	
	if(css and css.background) then
		_this.background = css.background;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		end
	end
	
	--
	-- create the first slide 
	--
	pe_slide.onframemove(instName, rootName)
	
	-- calculate used size
	local left, top = parentLayout:GetAvailablePos();
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	end
	
	-- resize container
	_parent.height = height-top-margin_top-margin_bottom;
	_parent.width = width-left-margin_right-margin_left;
	
	if(alignment == "_lt") then
		parentLayout:AddObject(width-left, height-top);
	elseif(alignment == "_rt") then
		_parent.x = - _parent.width- margin_left - margin_right;
	elseif(alignment == "_rb") then
		_parent.x = - _parent.width- margin_left - margin_right;
		_parent.y = - _parent.height- margin_top - margin_bottom;
	elseif(alignment == "_lb") then
		_parent.y = - _parent.height- margin_top - margin_bottom;
	end	
end

-- event handler
function pe_slide.onframemove(instName, rootName)
	local slideNode = Map3DSystem.mcml.GetNode(instName);
	local _parent = ParaUI.GetUIObject(instName);
	if(table.getn(slideNode)==0 or not slideNode or not _parent:IsValid()) then
		return
	end
	
	local interval = slideNode:GetNumber("interval") or 0;
	if(interval == 0) then
		return
	end
	
	if(not slideNode.elapsed_time) then
		slideNode.elapsed_time = interval
	else
		slideNode.elapsed_time = slideNode.elapsed_time + deltatime
	end
	if(slideNode.elapsed_time < interval) then
		return
	end
	slideNode.elapsed_time = 0;
	local order = slideNode:GetString("order") or "sequence";
	local index;
	if(order == "sequence") then
		-- in sequence
		index = slideNode.currentindex or 0;
		index = index + 1;
		if(index>table.getn(slideNode)) then
			index = 1;
		end
	else
		-- randomly pick one
		index = math.floor(ParaGlobal.random()*table.getn(slideNode))+1;
		if(index >table.getn(slideNode)) then
			index = table.getn(slideNode);
		end
	end
	slideNode.currentindex = index;
	local childNode = slideNode:GetChild(index);
	if(childNode) then
		local css = slideNode:GetStyle(mcml_controls.pe_html.css["pe:slide"]) or {};
		local padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
		
		local contentLayout = mcml_controls.layout:new();
		contentLayout:reset(padding_left, padding_top, _parent.width-padding_left-padding_right, _parent.height-padding_top-padding_bottom);
		
		mcml_controls.pe_slide.refresh(rootName, childNode, nil, _parent, 
			{color = css.color, ["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], ["text-align"] = css["text-align"]}, contentLayout)
	end
end

-- refresh the inner controls. 
-- @param mcmlNode: the node content to be displayed in side the slide. This is usually one of the child nodes of the pe_slide. 
function pe_slide.refresh(rootName, mcmlNode, bindingContext, _parent, style, contentLayout)
	-- clear this container
	_parent:RemoveAll();
	local left, top, width, height = contentLayout:GetPreferredRect();
	mcml_controls.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, contentLayout)
end


-----------------------------------
-- pe:filebrowser control: 
-- node properties: onclick, onselect, oncheck, oncreatenode, filter, rootfolder, AllowFolderSelection, DisableFolderExpand, HideFolder,CheckBoxes
-----------------------------------
local pe_filebrowser = commonlib.gettable("Map3DSystem.mcml_controls.pe_filebrowser");

-- this control will fill entire client area
function pe_filebrowser.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_html.css["pe:filebrowser"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height
		end
	end
	
	parentLayout:AddObject(width-left, height-top);
	parentLayout:NewLine();
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	-- file explorer control. 
	local instName = mcmlNode:GetInstanceName(rootName);
	
	local editorInstName;
	if(bindingContext) then
		editorInstName = bindingContext.editorInstName or ""
	end
	
	local ctl = CommonCtrl.GetControl(instName);
	
	local style = mcmlNode:GetString("style_mode");
	if(style and style == "FileView") then
		NPL.load("(gl)script/ide/FileViewCtrl.lua");
		-- using file view control
		if(not ctl) then
			ctl = CommonCtrl.FileViewCtrl:new{
				name = instName,
				alignment = "_lt",
				left = left,
				top = top,
				width = width - left,
				height = height - top,
				parent = _parent,
				ItemsPerRow = mcmlNode:GetNumber("ItemsPerRow"),
				SelectedBG = mcmlNode:GetAttribute("SelectedBG"),
				DefaultFileIcon = mcmlNode:GetAttribute("DefaultFileIcon"),
				FolderOpenIcon = mcmlNode:GetAttribute("FolderOpenIcon"),
				FolderBackward = mcmlNode:GetAttribute("FolderBackward"),
				FolderIcon = mcmlNode:GetAttribute("FolderIcon"),
				DefaultNodeHeight = mcmlNode:GetNumber("DefaultNodeHeight"),
				DefaultNodeWidth = mcmlNode:GetNumber("DefaultNodeWidth"),
				DefaultNodePadding = mcmlNode:GetNumber("DefaultNodePadding"),
				DefaultIconSize = mcmlNode:GetNumber("DefaultIconSize"),
				ShowFileName = mcmlNode:GetBool("ShowFileName"),
				ShowUpFolder = mcmlNode:GetBool("ShowUpFolder"),
			};
		else
			ctl.parent = _parent;
		end	
	else
		-- using file explorer
		NPL.load("(gl)script/ide/FileExplorerCtrl.lua");
		if(not ctl) then
			ctl = CommonCtrl.FileExplorerCtrl:new{
				name = instName,
				alignment = "_lt",
				left = left,
				top = top,
				width = width - left,
				height = height - top,
				parent = _parent,
			};
		else
			ctl.parent = _parent;
		end	
	end	
	
	-- FileExplorerCtrl
	ctl.AllowFolderSelection = mcmlNode:GetBool("AllowFolderSelection");
	ctl.DisableFolderExpand = mcmlNode:GetBool("DisableFolderExpand");
	ctl.HideFolder = mcmlNode:GetBool("HideFolder");
	ctl.rootfolder = mcmlNode:GetAttributeWithCode("rootfolder", nil, true);
	ctl.filter = mcmlNode:GetAttribute("filter");
	ctl.CheckBoxes = mcmlNode:GetAttribute("CheckBoxes");
	if(css.background) then
		ctl.container_bg = css.background;
	end

	local name, onclick, ondoubleclick, oncheck, oncreatenode, onprerendernode  = mcmlNode:GetString("name") or "", mcmlNode:GetString("onclick") or mcmlNode:GetString("onselect"), mcmlNode:GetString("ondoubleclick"), mcmlNode:GetString("oncheck"), mcmlNode:GetString("oncreatenode"), mcmlNode:GetString("onprerendernode");
	if(onclick) then
		ctl.OnSelect = function (filepath)
			mcml_controls.OnPageEvent(mcmlNode, onclick, name,filepath)
		end
	end
	if(ondoubleclick) then
		ctl.OnDoubleClick = function (filepath)
			mcml_controls.OnPageEvent(mcmlNode, ondoubleclick, name, filepath)
		end
	end
	if(oncheck) then
		ctl.OnCheck = function (treeNode, filepath, Checked)
			mcml_controls.OnPageEvent(mcmlNode, oncheck, name, treeNode, filepath, Checked)
		end
	end
	if(oncreatenode) then
		ctl.OnCreateNode = function (treeNode, filepath)
			mcml_controls.OnPageEvent(mcmlNode, oncreatenode, name, treeNode, filepath)
		end
	end
	if(onprerendernode) then
		ctl.OnPreRenderNode = function (treeNode, filepath)
			mcml_controls.OnPageEvent(mcmlNode, onprerendernode, name, treeNode, filepath)
		end
	end
	
	ctl:Show(true);
end

-- get the UI value on the node
function pe_filebrowser.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(type(ctl)=="table" and type(ctl.GetValue) == "function") then
		return ctl:GetValue();
	end	
end

-----------------------------------
-- pe:canvas3dui control: 
-----------------------------------
local pe_canvas3dui = commonlib.gettable("Map3DSystem.mcml_controls.pe_canvas3dui");

-- this control will fill entire client area
function pe_canvas3dui.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	NPL.load("(gl)script/ide/Canvas3DUI.lua");
	local ctl = CommonCtrl.Canvas3DUI:new{
		name = mcmlNode:GetString("name"),
		miniscenegraphname = mcmlNode:GetAttributeWithCode("miniscenegraphname"),
		parent = _parent,
	};
	ctl:Show(true);
	local fLookAtX, fLookAtY, fLookAtZ = mcmlNode:GetAttributeWithCode("LookAtX"), mcmlNode:GetAttributeWithCode("LookAtY"), mcmlNode:GetAttributeWithCode("LookAtZ")
	local fRotY, fLiftupAngle, fCameraObjectDist = mcmlNode:GetAttributeWithCode("RotY"), mcmlNode:GetAttributeWithCode("LiftupAngle"), mcmlNode:GetAttributeWithCode("CameraObjectDist")
	ctl:CameraSetLookAtPos(tonumber(fLookAtX) or 0, tonumber(fLookAtY) or 0, tonumber(fLookAtZ) or 0);
	ctl:CameraSetEyePosByAngle(tonumber(fRotY) or 0, tonumber(fLiftupAngle) or 0, tonumber(fCameraObjectDist) or 0);
	
	local originX, originY, originZ = mcmlNode:GetAttributeWithCode("originX"), mcmlNode:GetAttributeWithCode("originY"), mcmlNode:GetAttributeWithCode("originZ")
	local OnLoadSceneScript = mcmlNode:GetAttributeWithCode("OnLoadSceneScript");
	local OnLoadNPCDB = mcmlNode:GetAttributeWithCode("OnLoadNPCDB");
	
	if(OnLoadSceneScript or OnLoadNPCDB) then
		ctl:ClearScene();
	end
	if(OnLoadSceneScript) then
		ctl:LoadFromOnLoadScript(OnLoadSceneScript, tonumber(originX) or 0, tonumber(originY) or 0, tonumber(originZ) or 0)
	end
	if(OnLoadNPCDB) then
		ctl:LoadFromOnNPCdb(OnLoadNPCDB, tonumber(originX) or 0, tonumber(originY) or 0, tonumber(originZ) or 0)
	end
	
	mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-----------------------------------
-- pe:canvas3d control: 
-- node properties: src or value, rotSpeed, autoRotateSpeed, panSpeed, maxLiftupAngle, minLiftupAngle, maxZoomDist, minZoomDist, RenderTargetSize,cameraName
-----------------------------------
local pe_canvas3d = commonlib.gettable("Map3DSystem.mcml_controls.pe_canvas3d");

-- this control will fill entire client area
function pe_canvas3d.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:canvas3d"] or mcml_controls.pe_html.css["pe:canvas3d"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
		end
		width = left + css.width + margin_left + margin_right
	end
	if(css.height) then
		height = top + css.height + margin_top + margin_bottom
	end
	
	parentLayout:AddObject(width-left, height-top);
	parentLayout:NewLine();
	
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	-- file explorer control. 
	local instName = mcmlNode:GetInstanceName(rootName);
	local IsActiveRendering = mcmlNode:GetBool("IsActiveRendering")
	if(IsActiveRendering == nil) then
		IsActiveRendering = true;
	end
	
	local IsInteractive = mcmlNode:GetBool("IsInteractive")
	if(IsInteractive == nil) then
		IsInteractive = true;
	end
	
	local autoRotateSpeed = mcmlNode:GetNumber("autoRotateSpeed")
	if(autoRotateSpeed == nil) then
		autoRotateSpeed = 0;
	end
	
	local IsPortrait = mcmlNode:GetBool("IsPortrait")
	if(IsPortrait == nil) then
		IsPortrait = false;
	end
	
	NPL.load("(gl)script/ide/Canvas3D.lua");
	
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = mcmlNode:GetAttributeWithCode("miniscenegraphname"),
		ExternalSceneName = mcmlNode:GetAttributeWithCode("ExternalSceneName"),
		FieldOfView = mcmlNode:GetNumber("FieldOfView"),
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	CommonCtrl.AddControl(instName,ctl);
	
	ctl.zorder = mcmlNode:GetNumber("zorder");
	ctl.rotSpeed = mcmlNode:GetNumber("rotSpeed");
	ctl.panSpeed = mcmlNode:GetNumber("panSpeed");
	ctl.rotSpeed = mcmlNode:GetNumber("rotSpeed");
	ctl.cameraName = mcmlNode:GetString("cameraName");
	ctl.maxLiftupAngle = mcmlNode:GetNumber("maxLiftupAngle");
	ctl.maxZoomDist = mcmlNode:GetNumber("maxZoomDist");
	ctl.minZoomDist = mcmlNode:GetNumber("minZoomDist");
	ctl.RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize");
	ctl.DefaultCameraObjectDist = mcmlNode:GetNumber("DefaultCameraObjectDist");
	ctl.DefaultLiftupAngle = mcmlNode:GetNumber("DefaultLiftupAngle");
	ctl.DefaultRotY = mcmlNode:GetNumber("DefaultRotY");
	ctl.LookAtHeight = mcmlNode:GetNumber("LookAtHeight");
	ctl.ExternalOffsetX	= tonumber(mcmlNode:GetAttributeWithCode("ExternalOffsetX"));
	ctl.ExternalOffsetY	= tonumber(mcmlNode:GetAttributeWithCode("ExternalOffsetY"));
	ctl.ExternalOffsetZ	= tonumber(mcmlNode:GetAttributeWithCode("ExternalOffsetZ"));
	ctl.background_color = _guihelper.ConvertColorToRGBAString(css["background-color"]);
	ctl.background = css.background;
	ctl.IgnoreExternalCamera = mcmlNode:GetAttribute("IgnoreExternalCamera") == "true";
	ctl.mask_texture = mcmlNode:GetAttributeWithCode("MaskTexture");
	ctl:Show(true);
	local objParamsStr = pe_canvas3d.GetValue(mcmlNode);
	if(type(objParamsStr) == "table") then
		ctl:ShowModel(objParamsStr);
	elseif(objParamsStr and NPL.IsPureData(objParamsStr) and objParamsStr~="") then
		-- TODO: security check.
		local objParams = commonlib.LoadTableFromString(objParamsStr);
		if(objParams) then
			ctl:ShowModel(objParams)
		end
	else
		local objbinding = mcmlNode:GetString("objectbinding");
		if(objbinding and objbinding~="") then
			local objParams = Map3DSystem.obj.GetObjectParams(objbinding);
			if(objParams~=nil) then
				ctl:ShowModel(objParams)
				-- set the camera position to take portait view of avatar
				if(IsPortrait == true) then
					-- TODO: get the portait shot camera setting from the character or model asset description
					-- take the portrait shot of the avatar
					if(objParams.IsCharacter == true) then
						if(string.find(objParams.AssetFile, "can")) then
							ctl:CameraSetLookAtPos(0, 0.9654281139374, 0);
							ctl:CameraSetEyePosByAngle(2.7281620502472, 0.31596618890762, 3.5371053218842);
						else
							if(string.find(objParams.AssetFile, "ElfFemale.xml")) then
								--ctl:CameraSetLookAtPos(0, 1.4654281139374, 0);
								--ctl:CameraSetEyePosByAngle(2.7281620502472, 0.31596618890762, 2.5371053218842);
								ctl:CameraSetLookAtPos(0, 0.75053763389587, 0);
								ctl:CameraSetEyePosByAngle(-1.6270221471786, 0.10000000149012, 3.0698845386505);
							end
						end
					end
				end
			end
		else
			if(ctl.miniscenegraphname) then
				ctl:ShowMiniscene(ctl.miniscenegraphname)	
			end
		end
	end
	
	-- set the mask texture
	--[[ local MaskTexture = mcmlNode:GetAttributeWithCode("MaskTexture");
	if(MaskTexture ~= nil and MaskTexture ~= "") then
		if(not ctl.resourceName) then
			ctl.resourceName = ctl.miniscenegraphname;
		end
		ctl:SetMaskTexture(MaskTexture);
	end]]
end

-- get the MCML value on the node
function pe_canvas3d.GetValue(mcmlNode)
	return mcmlNode:GetAttributeWithCode("value", nil, true) or mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_canvas3d.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value)
	else
		mcmlNode:SetInnerText(nil);
	end	
end
-----------------------------------
-- pe:progressbar control
-----------------------------------
local pe_progressbar = commonlib.gettable("Map3DSystem.mcml_controls.pe_progressbar");

-- these theme can be changed externally
pe_progressbar.Default_blockimage = "Texture/3DMapSystem/Loader/progressbar_filled.png: 7 7 13 7"
pe_progressbar.Default_background = "Texture/3DMapSystem/Loader/progressbar_bg.png:7 7 6 6"
pe_progressbar.Default_color = "255 255 255"
pe_progressbar.Default_height = 32

-- create pager control for navigation
function pe_progressbar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();

	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:progressbar"] or mcml_controls.pe_html.css["pe:progressbar"], style) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	width	= width-left-margin_left-margin_right
	if(css.width and css.width<width) then
		width = css.width
	end
	if(css.height and css.height<height) then
		height = css.height;
	else
		height = pe_progressbar.Default_height;
	end	
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
	left=left+margin_left;
	top=top+margin_top;
		
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/progressbar.lua");
	local	ctl = CommonCtrl.progressbar:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width,
		height = height,
		parent = _parent,
		block_bg_autosize = mcmlNode:GetBool("block_bg_autosize"),
		isshowtooltip = mcmlNode:GetBool("isshowtooltip"),
		is_vertical = mcmlNode:GetBool("is_vertical"),
		uv_speed = mcmlNode:GetNumber("uv_speed"),
	};
	
	ctl.block_bg = mcmlNode:GetString("blockimage") or css["blockimage"] or pe_progressbar.Default_blockimage;
	ctl.container_bg = mcmlNode:GetString("background") or css["background"]  or pe_progressbar.Default_background; 
	ctl.block_color = mcmlNode:GetString("Color") or css["Color"]  or pe_progressbar.Default_color;
	ctl.block_overlay_bg = mcmlNode:GetString("block_overlay_bg") or css["block_overlay_bg"]  or pe_progressbar.block_overlay_bg;
	
	local Minimum = mcmlNode:GetAttributeWithCode("Minimum", 0);
	ctl.Minimum = tonumber(Minimum) or 0;

	local Maximum = mcmlNode:GetAttributeWithCode("Maximum", 100, true);
	ctl.Maximum = tonumber(Maximum) or 100;

	ctl.miniblockwidth = mcmlNode:GetNumber("miniblockwidth");
	
	local Value = mcmlNode:GetAttributeWithCode("Value", 0, true);
	ctl.Value = tonumber(Value);

	local Step = mcmlNode:GetAttributeWithCode("Step", 10);
	ctl.Step = mcmlNode:GetNumber("Step") or 10;
	
	local onstep = mcmlNode:GetString("onstep");
	if(onstep)then
		ctl.onstep = function (step)
			mcml_controls.OnPageEvent(mcmlNode, onstep, step);
		end
	end
	
	ctl:Show(true);
end

-- get the UI value on the node
function pe_progressbar.GetUIValue(mcmlNode, pageInstName)
	local progressbar = mcmlNode:GetControl(pageInstName);
	if(progressbar) then
		return progressbar.Value;
	end
end

-- set the UI value on the node
function pe_progressbar.SetUIValue(mcmlNode, pageInstName, value)
	local progressbar = mcmlNode:GetControl(pageInstName);
	if(progressbar) then
		if(type(value) == "string") then
			value = tonumber(value);
		elseif(type(value) == "table") then
			return
		end 
		if(type(progressbar)=="table") then
			progressbar:SetValue(value);
		end	
	end
end

-- get the MCML value on the node
function pe_progressbar.GetValue(mcmlNode)
	return mcmlNode:GetNumber("Value");
end

-- set the MCML value on the node
function pe_progressbar.SetValue(mcmlNode, value)
	value = tonumber(value);
	if(value) then
		mcmlNode:SetAttribute("Value", value)
	else
		mcmlNode:SetAttribute("Value", nil)
	end	
end

-----------------------------------
-- pe:sliderbar control
-----------------------------------
local pe_sliderbar = commonlib.gettable("Map3DSystem.mcml_controls.pe_sliderbar");

-- create pager control for navigation
function pe_sliderbar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();

	local css = mcmlNode:GetStyle(mcml_controls.pe_html.css["pe:sliderbar"], style) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	width	= width-left-margin_left-margin_right
	if(css.width and css.width<width) then
		width = css.width
	end
	if(css.height) then
		height = math.min(height, css.height);
	else
		height = 20;
	end	
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
	left=left+margin_left;
	top=top+margin_top;
		
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/SliderBar.lua");
	local ctl = CommonCtrl.SliderBar:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width,
		height = height,
		parent = _parent,
	};

	ctl.show_step_button = mcmlNode:GetBool("show_step_button", false);
	
	ctl.button_bg = mcmlNode:GetString("button_bg");
	ctl.step_left_button_bg = mcmlNode:GetString("step_left_button_bg");
	ctl.step_right_button_bg = mcmlNode:GetString("step_right_button_bg");
	ctl.background = mcmlNode:GetString("background") or css.background; 
	ctl.button_width = tonumber(mcmlNode:GetAttributeWithCode("button_width"));
	ctl.button_height = tonumber(mcmlNode:GetAttributeWithCode("button_height"));
	
	ctl.editor_width = mcmlNode:GetNumber("EditorWidth");
	ctl.editor_format = mcmlNode:GetString("EditorFormat");
	ctl.IsShowEditor = mcmlNode:GetBool("IsShowEditor");
	ctl.no_value_check = mcmlNode:GetBool("no_value_check");
	ctl.min = mcmlNode:GetNumber("min") or ctl.min;
	ctl.max = tonumber(mcmlNode:GetAttributeWithCode("max")) or ctl.max;
	ctl.value = tonumber(mcmlNode:GetAttributeWithCode("value"));
	ctl.direction = mcmlNode:GetNumber("direction");
	ctl.min_step = mcmlNode:GetNumber("min_step");
	ctl.tooltip = mcmlNode:GetAttributeWithCode("tooltip");
	ctl.buttontext_color = mcmlNode:GetString("buttontext_color");
	ctl.buttontext_format = mcmlNode:GetString("buttontext_format");
	
	local onchange = mcmlNode:GetString("onchange");
	if(onchange)then
		ctl.onchange = function (value)
			mcml_controls.OnPageEvent(mcmlNode, onchange, value);
		end
	end
	
	ctl:Show(true);
	mcmlNode.control = ctl;

	local name = mcmlNode:GetString("name");
	if(bindingContext and name) then
		bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.IDE_sliderbar, "value")
	end
end

-- get the UI value on the node
function pe_sliderbar.GetUIValue(mcmlNode, pageInstName)
	local sliderbar = mcmlNode:GetControl(pageInstName);
	if(sliderbar) then
		return sliderbar:GetValue();
	end
end

-- set the UI value on the node
function pe_sliderbar.SetUIValue(mcmlNode, pageInstName, value)
	local sliderbar = mcmlNode:GetControl(pageInstName);
	if(type(sliderbar)=="table") then
		value = tonumber(value)
		if(type(value)=="number") then
			sliderbar:SetValue(value);
		end	
	end
end


-- get the MCML value on the node
function pe_sliderbar.GetValue(mcmlNode)
	return mcmlNode:GetNumber("value");
end

-- set the MCML value on the node
function pe_sliderbar.SetValue(mcmlNode, value)
	value = tonumber(value);
	if(value) then
		mcmlNode:SetAttribute("value", value)
	else
		mcmlNode:SetAttribute("value", nil)
	end	
end

-----------------------------------
-- pe:numericupdown control
-----------------------------------
local pe_numericupdown = commonlib.gettable("Map3DSystem.mcml_controls.pe_numericupdown");

-- create pager control for navigation
function pe_numericupdown.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local left, top, width, height = parentLayout:GetPreferredRect();

	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:numericupdown"] or mcml_controls.pe_html.css["pe:numericupdown"], style) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	width = width-left-margin_left-margin_right
	if(css.width and css.width<width) then
		width = css.width
	end
	if(css.height and css.height<height) then
		height = css.height;
	end	
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
	left=left+margin_left;
	top=top+margin_top;
		
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/NumericUpDown.lua");
	local ctl = CommonCtrl.NumericUpDown:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width,
		height = height,
		parent = _parent,
	};
	
	ctl.background = mcmlNode:GetString("background") or css.background or ctl.background; 
	ctl.button_width = mcmlNode:GetNumber("button_width") or ctl.button_width;
	
	ctl.min = mcmlNode:GetNumber("min") or ctl.min;
	ctl.max = mcmlNode:GetNumber("max") or ctl.max;
	ctl.value = mcmlNode:GetNumber("value") or ctl.min;
	ctl.valueformat = mcmlNode:GetString("valueformat");
	ctl.min_step = mcmlNode:GetNumber("min_step");
	local canDrag =  mcmlNode:GetString("canDrag");
	if(canDrag == "false")then
		ctl.canDrag = false;
	end
	local onchange = mcmlNode:GetString("onchange");
	if(onchange)then
		ctl.onchange = function (value)
			mcml_controls.OnPageEvent(mcmlNode, onchange, value);
		end
	end
	
	ctl:Show(true);
	
	local name = mcmlNode:GetString("name");
	if(bindingContext and name) then
		bindingContext:AddBinding(bindingContext.values, name, instName, commonlib.Binding.ControlTypes.IDE_numeric, "value")
	end
end

-- get the UI value on the node
function pe_numericupdown.GetUIValue(mcmlNode, pageInstName)
	local sliderbar = mcmlNode:GetControl(pageInstName);
	if(sliderbar) then
		return sliderbar:GetValue();
	end
end

-- set the UI value on the node
function pe_numericupdown.SetUIValue(mcmlNode, pageInstName, value)
	local sliderbar = mcmlNode:GetControl(pageInstName);
	if(type(sliderbar)=="table") then
		value = tonumber(value)
		if(type(value)=="number") then
			sliderbar:SetValue(value);
		end	
	end
end


-- get the MCML value on the node
function pe_numericupdown.GetValue(mcmlNode)
	return mcmlNode:GetNumber("value");
end

-- set the MCML value on the node
function pe_numericupdown.SetValue(mcmlNode, value)
	value = tonumber(value);
	if(value) then
		mcmlNode:SetAttribute("value", value)
	else
		mcmlNode:SetAttribute("value", nil)
	end	
end

-----------------------------------
-- pe:colorpicker control
-----------------------------------
local pe_colorpicker = commonlib.gettable("Map3DSystem.mcml_controls.pe_colorpicker");

-- create pager control for navigation
function pe_colorpicker.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();

	local css = mcmlNode:GetStyle(mcml_controls.pe_html.css["pe:colorpicker"], style) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
		
	local left, top, width, height = parentLayout:GetPreferredRect();
	width	= width-left-margin_left-margin_right
	if(css.width and css.width<width) then
		width = css.width
	end
	if(css.height and css.height<height) then
		height = css.height;
	else
		height = 20;
	end	
	parentLayout:AddObject(width+margin_left+margin_right, margin_top+margin_bottom+height);
	left=left+margin_left;
	top=top+margin_top;
		
	local instName = mcmlNode:GetInstanceName(rootName);
	local version = mcmlNode:GetNumber("version");
	NPL.load("(gl)script/ide/colorpicker.lua");
	local ctl = CommonCtrl.ColorPicker:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		background = mcmlNode:GetString("background") or css.background,
		width = width,
		height = height,
		parent = _parent,
		textcolor = css.color,
		version = version,
	};
	ctl:SetValue(mcmlNode:GetString("value"), true);
	
	local onchange = mcmlNode:GetString("onchange");
	if(onchange)then
		ctl.onchange = function (sCtrlName, red, green, blue)
			mcml_controls.OnPageEvent(mcmlNode, onchange, red, green, blue);
		end
	end
	
	ctl:Show(true);
end

-- get the UI value on the node
function pe_colorpicker.GetUIValue(mcmlNode, pageInstName)
	local colorpicker = mcmlNode:GetControl(pageInstName);
	if(colorpicker) then
		return colorpicker:GetValue();
	end
end

-- set the UI value on the node
function pe_colorpicker.SetUIValue(mcmlNode, pageInstName, value)
	
	local colorpicker = mcmlNode:GetControl(pageInstName);
	if(type(colorpicker)=="table") then
		if(type(value)=="string") then
			colorpicker:SetValue(value);
		end	
	end
end

-- get the MCML value on the node
function pe_colorpicker.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("value");
end

-- set the MCML value on the node
function pe_colorpicker.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetAttribute("value", value)
	else
		mcmlNode:SetAttribute("value", nil)
	end	
end


-----------------------------------
-- pe:preloader control
-----------------------------------

local pe_preloader = commonlib.gettable("Map3DSystem.mcml_controls.pe_preloader");

-- create pager control for navigation
function pe_preloader.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	parentLayout:NewLine();
	local left, top, width, height = parentLayout:GetPreferredRect();

	
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/AssetPreloader.lua");
	local loader = commonlib.AssetPreloader:new();
	
	local texturesNode = mcmlNode:GetChild("textures");
	if(texturesNode) then
		local text = texturesNode:GetInnerText();
		if(text) then
			local file;
			for file in string.gmatch(text, "[^ ;\r\n]+") do
				loader:AddAssets(ParaAsset.LoadTexture("",file,1));
			end
		end
	end
	
	if(loader:GetAssetsCount() > 0) then
		-- let us create the loader interface first
		
		local css = mcmlNode:GetStyle(mcml_controls.pe_css.default["pe:preloader"] or mcml_controls.pe_html.css["pe:preloader"], style) or {};
		local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
			
		local left, top, width, height = parentLayout:GetPreferredRect();
		width = width-left-margin_left-margin_right
		if(css.width) then
			width = css.width
		end
		if(css.height) then
			height = css.height;
		end	
		left=left+margin_left;
		top=top+margin_top;
	
		local _this=ParaUI.GetUIObject(instName);
		if(_this:IsValid() == false) then
			_this = ParaUI.CreateUIObject("container",instName,"_lt",left,top,width,height);
			_this.background = mcmlNode:GetString("background") or css.background;
			_this.zorder = 1; -- make it stay above other UI object. 
			_parent:AddChild(_this);
			local loaderUITemplateNode = mcmlNode:GetChild("LoaderUITemplate");
			if(loaderUITemplateNode) then
				local myLayout = mcml_controls.layout:new();
				myLayout:reset(0, 0, width, height);
				mcml_controls.create(rootName, loaderUITemplateNode, bindingContext, _this, 0, 0, width, height, nil, myLayout);
			end
		end
		local loader_ui_id = _this.id;
	
		-- add the event handler
		local onprogress = mcmlNode:GetString("onprogress");
		if(onprogress)then
			loader.callbackFunc = function(nItemsLeft, loader)
				-- delete UI if all items are finished. 
				if(nItemsLeft == 0) then
					ParaUI.Destroy(loader_ui_id);
				end
				mcml_controls.OnPageEvent(mcmlNode, onprogress, nItemsLeft, loader);
			end
		end
		
		loader:Start();
	end	
end
