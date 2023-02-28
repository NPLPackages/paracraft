--[[
Title: 
Author(s): yangguiyi
Date: 2021/9/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/lessons_ppt/coverplayer.lua");
local coverplayer = commonlib.gettable("MyCompany.Aries.Game.mcml.coverplayer");
-------------------------------------------------------
]]
local coverplayer = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.coverplayer");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
function coverplayer.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	if RedSummerCampPPtPage.GetIsFullPage() then
		coverplayer.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	else
		coverplayer.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	end
	
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function coverplayer.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, coverplayer.render_callback);
end

function coverplayer.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	css.height = 378
	local _this = ParaUI.CreateUIObject("container", "ppt_cover_player", "_lt", left, top, width-left, 378);
	_this.background = "";
	-- _this:GetAttributeObject():SetField("ClickThrough", true);
	_parent:AddChild(_this);
	local _root = _this;


	local _this = ParaUI.CreateUIObject("button", "ppt_cover_player_bt", "_lt", 0, 0, _this.width, _this.height);
	_this.background = "";
	local link = mcmlNode:GetString("href");
	local is_external_link = mcmlNode:GetString("is_external_link") == "true";
	local title = mcmlNode:GetString("value");

	_root:AddChild(_this);
	_this:SetScript("onclick", function()
		RedSummerCampPPtPage.OpenVideoLink(link, is_external_link, title)
	end);

	local play_icon = ParaUI.CreateUIObject("container", "lessonppt_play_icon", "_lt", _this.width/2 - 51, _this.height/2 - 51, 102, 102);
	play_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/bofang_102x102_32bits.png;0 0 102 102";
	play_icon:GetAttributeObject():SetField("ClickThrough", true);
	_root:AddChild(play_icon);

	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

function coverplayer.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	css.height = 378
	local _this = ParaUI.CreateUIObject("container", "ppt_cover_player", "_lt", left, top, width-left, 378);
	_this.background = "";
	-- _this:GetAttributeObject():SetField("ClickThrough", true);
	_parent:AddChild(_this);
	local _root = _this;


	local _this = ParaUI.CreateUIObject("button", "ppt_cover_player_bt", "_lt", 0, 0, _this.width, _this.height);
	_this.background = "";
	local link = mcmlNode:GetString("href");
	local is_external_link = mcmlNode:GetString("is_external_link") == "true";
	local title = mcmlNode:GetString("value");

	_root:AddChild(_this);
	_this:SetScript("onclick", function()
		RedSummerCampPPtPage.OpenVideoLink(link, is_external_link, title)
	end);

	local play_icon = ParaUI.CreateUIObject("container", "lessonppt_play_icon", "_lt", _this.width/2 - 51, _this.height/2 - 51, 102, 102);
	play_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/bofang_102x102_32bits.png;0 0 102 102";
	play_icon:GetAttributeObject():SetField("ClickThrough", true);
	_root:AddChild(play_icon);

	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end