--[[
Title: 
Author(s): yangguiyi
Date: 2021/9/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/lessons_ppt/difficult.lua");
local difficult = commonlib.gettable("MyCompany.Aries.Game.mcml.difficult");
-------------------------------------------------------
]]
local difficult = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.difficult");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
function difficult.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	if RedSummerCampPPtPage.GetIsFullPage() then
		difficult.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	else
		difficult.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	end
	
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function difficult.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, difficult.render_callback);
end

function difficult.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local num = mcmlNode:GetString("value") or 0;
	local type_name = mcmlNode:GetString("type_name")
	type_name = type_name and type_name .. ":" or ""
	local step_height = 32
	css.height = step_height
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left + 27, top, width-left, step_height);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local word_width = ParaMisc.GetUnicodeCharNum(type_name) * 13
	local type_name_text = ParaUI.CreateUIObject("text", "lessonppt_type_name_text", "_lt", 0, 12, word_width, 20);
	_guihelper.SetFontColor(type_name_text, "#000000");
	type_name_text.font = "System;13;norm"
	type_name_text.text = type_name;
	_this:AddChild(type_name_text);

	local star_start_pos = word_width + 7
	for index = 1, tonumber(num) do
		local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", star_start_pos, 12, 15, 16);
		step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/xingxing_15x16_32bits.png;0 0 15 16";
		_this:AddChild(step_icon);

		star_start_pos = star_start_pos + 15 + 7
	end

	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

function difficult.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local num = mcmlNode:GetString("value") or 0;
	local type_name = mcmlNode:GetString("type_name")
	type_name = type_name and type_name .. ":" or ""
	local step_height = 32
	css.height = step_height
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left + 27, top, width-left, step_height);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local word_width = ParaMisc.GetUnicodeCharNum(type_name) * 13
	local type_name_text = ParaUI.CreateUIObject("text", "lessonppt_type_name_text", "_lt", 0, 12, word_width, 20);
	_guihelper.SetFontColor(type_name_text, "#000000");
	type_name_text.font = "System;13;norm"
	type_name_text.text = type_name;
	_this:AddChild(type_name_text);

	local star_start_pos = word_width + 7
	for index = 1, tonumber(num) do
		local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", star_start_pos, 12, 15, 16);
		step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/xingxing_15x16_32bits.png;0 0 15 16";
		_this:AddChild(step_icon);

		star_start_pos = star_start_pos + 15 + 7
	end

	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end