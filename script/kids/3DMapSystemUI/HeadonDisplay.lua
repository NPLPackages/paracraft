--[[
Title: Headon Display Text style for characters 
Author(s): LiXizhi, WangTian
Date: 2007/9/4
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/HeadonDisplay.lua");
local HeadonDisplay = commonlib.gettable("Map3DSystem.UI.HeadonDisplay")
-- one can overwrite HeadonDisplay.headon_style before InitHeadOnTemplates is called.
HeadonDisplay.InitHeadOnTemplates(bForceReload);
------------------------------------------------------------
]]
local HeadonDisplay = commonlib.gettable("Map3DSystem.UI.HeadonDisplay")
local type = type;
local string_match = string.match;

-- head on display UI style, edit it here or change via Map3DSystem.headon_style
local headon_style = {
	-- some background
	-- text_bg = "Texture/3DMapSystem/HOD_Selected.png; 0 0 24 24: 11 11 11 11", -- some background
	text_bg = "",
	default_font = "System;18;bold",
	-- text color
	text_color = "0 160 0",
	-- whether there is text shadow
	use_shadow = true,
	-- any text scaling
	scaling = 1.2,
	
	-- Theame brighter: this is brighter as suggested by artist
	--default_font = "System;13;bold",
	--use_shadow = true,
	--scaling = 1.3,
	
	spacing = 2,
	height = 22,
	height_offset = -5,
}
HeadonDisplay.headon_style = HeadonDisplay.headon_style or headon_style;


-- get the approaprite character head on text 
-- @param obj: paraUIObject
function Map3DSystem.GetHeadOnText(obj) 
	local text = obj:GetAttributeObject():GetDynamicField("name", nil);
	if(text == nil) then
		text = obj.name;
		if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
			if(string.find(obj.name, ".x")) then
				text = "";
				obj:GetAttributeObject():SetDynamicField("name", "");
			end
		end
	end
	return text;
end
	
-- @param bShow: show or hide the head on display
-- @param obj: if obj is a table it's a obj_param table, 
--				if obj is a user data, it's a paraobject data
-- @param text: text, if bShow is false, text can be any thing
--				NOTE: updated 2010/1/11 if the text is of format "{%family%}+{%name%}", family and name, it will be displayed in double line. 
-- @param color: color such as "0 160 0". if nil, the default color is used. 
-- @param offset: nil or a table of {x=0,y=0.3,z=0}. Offset in meters
function Map3DSystem.ShowHeadOnDisplay(bShow, obj, text, color, offset, colorTopLine)
	local o;
	local playerChar;
	
	-- get the object
	if(type(obj) == "table") then
		o = ObjEditor.GetObjectByParams(obj);
	elseif(type(obj) == "userdata") then
		o = obj;
	else
		log("error: obj not table or userdata value.\n");
		return;
	end
	
	if(o:IsValid() == true) then
		
		if(bShow == false) then
			o:ShowHeadOnDisplay(false,0);
			o:ShowHeadOnDisplay(false,2);
			return;
		else
			o:ShowHeadOnDisplay(true,0);
			if(text==nil) then
				o:ShowHeadOnDisplay(true,2);
				return;
			end
		end

		local style = headon_style;
		-- calculate the text width
		local headon_text = "";
		local family, name = string_match(text, "^{(.*)}%+{(.*)}$");
		
		if(family and name) then
			o:ShowHeadOnDisplay(true,2);
			o:SetHeadOnUITemplateName("HOD_Selected_SecondLine",2);
			o:SetHeadOnText(name,2);
			o:SetHeadOnTextColor(color or style.text_color, 2);
			if(offset) then
				o:SetHeadOnOffset(offset.x or 0, offset.y or 0, offset.z or 0, 2);
			end
			color = colorTopLine or color;
			headon_text = family;
			o:SetHeadOnUITemplateName("HOD_Selected_DoubleLine",0);
		else
			o:ShowHeadOnDisplay(false,2);
			headon_text = text;
			o:SetHeadOnUITemplateName("HOD_Selected_SingleLine",0);
		end
		
		o:SetHeadOnText(headon_text,0);
		o:SetHeadOnTextColor(color or style.text_color,0);
		
		if(offset) then
			o:SetHeadOnOffset(offset.x or 0, offset.y or 0, offset.z or 0, 0);
		end
	end
end

-- create all character head on templates that shall may be used by the game
-- @param bForceReload: true to reload
function HeadonDisplay.InitHeadOnTemplates(bForceReload)
	ParaScene.ShowHeadOnDisplay(true);

	local style = HeadonDisplay.headon_style;
	local top = style.height_offset - style.height;
	
	local _parent = ParaUI.GetUIObject("dummy_headon_templates");
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container","dummy_headon_templates", "_lt",-10,-10,1,1);
		_parent.visible = false;
		_parent.enabled = false;
		_parent:AttachToRoot();
	end

	-- selected: HOD_Selected_DoubleLine
	if(bForceReload or ParaUI.GetUIObject("HOD_Selected_DoubleLine"):IsValid() == false) then
		ParaUI.Destroy("HOD_Selected_DoubleLine");
		local _this=ParaUI.CreateUIObject("text","HOD_Selected_DoubleLine", "_lt",-100,top-20,200,style.height);
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
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end
	
	if(bForceReload or ParaUI.GetUIObject("HOD_Selected_SingleLine"):IsValid() == false) then
		ParaUI.Destroy("HOD_Selected_SingleLine");
		local _this=ParaUI.CreateUIObject("text","HOD_Selected_SingleLine", "_lt",-60,top,120,style.height);
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
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end
	
	if(bForceReload or ParaUI.GetUIObject("HOD_Selected_SecondLine"):IsValid() == false) then
		ParaUI.Destroy("HOD_Selected_SecondLine");
		local _this=ParaUI.CreateUIObject("text","HOD_Selected_SecondLine", "_lt",-60,top,120,style.height);
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
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end
	
	-- OPC
	if(bForceReload or ParaUI.GetUIObject("HOD_OPC"):IsValid() == false) then
		ParaUI.Destroy("HOD_OPC");
		local _this=ParaUI.CreateUIObject("text","HOD_OPC", "_lt",-100,-20,200,15);
		_this.visible = false;
		_this.autosize = false;
		_this:GetFont("text").color = "0 0 255";
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end	
	
	-- 3D cursor help 
	if(bForceReload or ParaUI.GetUIObject("CursorHelp"):IsValid() == false) then
		ParaUI.Destroy("CursorHelp");
		local _this=ParaUI.CreateUIObject("text","CursorHelp", "_lt",-100,-20,200,15);
		_this.visible = false;
		_this.autosize = false;
		_this:GetFont("text").color = "0 255 0";
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end	
	
	
	-- normal
	local _this = ParaUI.GetUIObject("_HeadOnDisplayText_");
	if(bForceReload or _this:IsValid() == false) then
		ParaUI.Destroy("_HeadOnDisplayText_");
		-- user can also change the default head on display text here
		_this=ParaUI.CreateUIObject("text","HOD_OPC", "_lt",-100,-20,200,15);
		_this.visible = false;
		_this.autosize = false;
		_this:GetFont("text").color = "0 255 0";
		_this:GetFont("text").format = 1+256; -- center and no clip
		_parent:AddChild(_this);
	end
	
end	
