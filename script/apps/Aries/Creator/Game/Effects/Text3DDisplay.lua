--[[
Title: Text 3D Display
Author(s): LiXizhi
Date: 2013/12/21
Desc: Headon 3d text for static models. Characters currently does not support real 3d text. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");
Text3DDisplay.ShowText3DDisplay(bShow, obj, "Line1\nLine2", color, offset, facing)
Text3DDisplay.InitHeadOnTemplates(true)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");

-- head on display UI style, edit it here or change via Text3DDisplay.headon_style
local headon_style = {
	-- some background
	-- text_bg = "Texture/3DMapSystem/HOD_Selected.png; 0 0 24 24: 11 11 11 11", -- some background
	text_bg = "",
	--default_font = "System;18;bold",
	-- text color
	text_color = "0 160 0",
	-- whether there is text shadow
	-- use_shadow = true,
	-- any text scaling
	-- scaling = 1.2,

	spacing = 2,
	height = 22,
}

Text3DDisplay.headon_style = Text3DDisplay.headon_style or headon_style;

-- get the approaprite character head on text 
-- @param obj: paraUIObject
function Text3DDisplay.GetHeadOnText(obj) 
	return obj:GetAttributeObject():GetDynamicField("headontext", nil);
end

-- @param bShow: show or hide the head on display
-- @param obj: must be mesh object. character not supported yet. 
-- @param text: text, if bShow is false, text can be any thing
-- @param offset: nil or a table of {x=0,y=0.3,z=0}. Offset in meters
function Text3DDisplay.ShowText3DDisplay(bShow, obj, text, color, offset, facing)
	local o;
	local playerChar;
	
	-- get the object
	if(type(obj) == "userdata") then
		o = obj;
	else
		log("error: obj not userdata value.\n");
		return;
	end
	
	if(o:IsValid()) then
		
		if(bShow == false) then
			o:ShowHeadOnDisplay(false,0);
			return;
		else
			o:ShowHeadOnDisplay(true,0);
			if(text==nil) then
				return;
			end
		end

		local style = headon_style;
		-- calculate the text width
		o:SetHeadOnText(text,0);
		o:SetHeadOnTextColor(color or style.text_color,0);
		o:SetHeadOnUITemplateName("3DTextDefault",0);

		if(offset) then
			o:SetHeadOnOffset(offset.x or 0, offset.y or 0, offset.z or 0, 0);
		end

		-- this line will enable both 3d text display and 3d facing. 
		o:SetField("HeadOn3DFacing", facing or 0);
	end
end

-- create all character head on templates that shall may be used by the game
-- @param bForceReload: true to reload
function Text3DDisplay.InitHeadOnTemplates(bForceReload)
	local style = Text3DDisplay.headon_style;
	local _parent = ParaUI.GetUIObject("headon_templates_cont");
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container","headon_templates_cont", "_lt",0,0,1,1);
		_parent.visible = false;
		_parent.enabled = false;
		_parent:AttachToRoot();
	end

	-- selected: HOD_Selected_DoubleLine
	if(bForceReload or ParaUI.GetUIObject("3DTextDefault"):IsValid() == false) then
		ParaUI.Destroy("3DTextDefault");
		local _this=ParaUI.CreateUIObject("text","3DTextDefault", "_lt",-150, 0,300,style.height);
		_this.visible = false;
		_this.autosize = false;
		if(style.use_shadow) then
			_this.shadow = style.use_shadow;
		end
		if(style.scaling) then
			_this.scalingx = style.scaling;
			_this.scalingy = style.scaling;
		end
		_this.font = style.default_font;
		_this.background = style.text_bg;
		_this:GetFont("text").color = style.text_color;
		_this.spacing = style.spacing;
		_this:GetFont("text").format = 1+16+256; -- center and no clip and word break
		_parent:AddChild(_this);
	end
end	
