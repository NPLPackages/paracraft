--[[
Title: embedded flash player window
Author(s): LiXizhi
Date: 2009/8/30
Desc: embedded flash player window. more information, please see "script/ide/FlashPlayerWindow.lua"
Because we use a real win32 window. the win32 window always stays above and may has key focus. 
TODO: we may track the visiblitity event in future. 
---++ pe:flash
| *property* | desc|
| name	| flash window name. |
| src	| flash movie path, such as "abc.swf"  |
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_flash.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:Storyboard control
-----------------------------------
local pe_flash = {};
Map3DSystem.mcml_controls.pe_flash = pe_flash;

-- TODO: add a default downloading progress bar if the inner flash is not yet downloaded. 
function pe_flash.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:flash"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	local myLayout;
	if(mcmlNode:GetChildCount()>0) then
		myLayout = parentLayout:clone();
		myLayout:SetUsedSize(0,0);
		myLayout:OffsetPos(padding_left+margin_left, padding_top+margin_top);
		myLayout:IncHeight(-padding_bottom-margin_bottom);
		myLayout:IncWidth(-padding_right-margin_right);
	end	
	
	parentLayout:AddObject(width-left, height-top);

	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/FlashPlayerWindow.lua");
	local ctl = CommonCtrl.FlashPlayerWindow:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		parent = _parent,
		flash_wnd_name = mcmlNode:GetAttributeWithCode("name"),
		FlashPlayerIndex = mcmlNode:GetNumber("FlashPlayerIndex"),
		bDisableWindowClosing = mcmlNode:GetBool("DisableWindowClosing"),
	};
	ctl:Show();
	ctl:LoadMovie(mcmlNode:GetAttributeWithCode("src"));
end
