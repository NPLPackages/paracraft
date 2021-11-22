--[[
Title: 
Author(s): yangguiyi
Date: 2021/9/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/lessons_ppt/step.lua");
local step = commonlib.gettable("MyCompany.Aries.Game.mcml.step");
-------------------------------------------------------
]]
local step = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.step");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local RedSummerCampPPtFullPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtFullPage.lua");
function step.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	if RedSummerCampPPtPage.GetIsFullPage() then
		step.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	else
		step.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	end
	
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function step.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, step.render_callback);
end

function step.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local parent_width, parent_height = w, h;
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top + 10, width-left, height - top);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", 0, 0, 32, 32);
	step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v1_32bits.png;0 0 32 32";
	_this:AddChild(step_icon);

	local num = mcmlNode:GetString("value") or 0;
	local step_num_text = ParaUI.CreateUIObject("text", "lessonppt_step_num_text", "_lt", 10, 1, 32, 32);
	_guihelper.SetFontColor(step_num_text, "#ffffff");
	step_num_text.font = "System;22;norm"
	step_num_text.text = num;
	step_icon:AddChild(step_num_text);

	local cur_step_num = RedSummerCampPPtPage.GetStepNumKey()
	local step_num = tonumber(num)
	if step_num == math.floor(cur_step_num) then
		step_num = cur_step_num + 0.1
	end
	RedSummerCampPPtPage.SetStepNumKey(step_num)

	if RedSummerCampPPtPage.GetStepIsComplete(step_num) then
		local check_icon = ParaUI.CreateUIObject("container", "lessonppt_check_icon", "_lt", 18, 20, 26, 24);
		check_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v_26X24_32bits.png;0 0 26 24";
		_root:AddChild(check_icon);
	end
	
	
	parentLayout.step_num = step_num
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

function step.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local parent_width, parent_height = w, h;
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top + 10, width-left, height - top);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", 0, 0, 48, 48);
	step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v1_32bits.png;0 0 32 32";
	_root:AddChild(step_icon);

	local num = mcmlNode:GetString("value") or 0;
	local step_num_text = ParaUI.CreateUIObject("text", "lessonppt_step_num_text", "_lt", 0, 3, 48, 48);
	_guihelper.SetFontColor(step_num_text, "#ffffff");
	_guihelper.SetUIFontFormat(step_num_text, 17);
	step_num_text.font = "System;32;norm"
	step_num_text.text = num;
	step_icon:AddChild(step_num_text);

	local cur_step_num = RedSummerCampPPtFullPage.GetStepNumKey()
	local step_num = tonumber(num)
	if step_num == math.floor(cur_step_num) then
		step_num = cur_step_num + 0.1
	end
	RedSummerCampPPtFullPage.SetStepNumKey(step_num)

	if RedSummerCampPPtPage.GetStepIsComplete(step_num) and not RedSummerCampPPtFullPage.is_expore_mode then
		local check_icon = ParaUI.CreateUIObject("container", "lessonppt_check_icon", "_lt", 25, 30, 39, 36);
		check_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v_26X24_32bits.png;0 0 26 24";
		_root:AddChild(check_icon);
	end
	
	
	parentLayout.step_num = step_num
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end