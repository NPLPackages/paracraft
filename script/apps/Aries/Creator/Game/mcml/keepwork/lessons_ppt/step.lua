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
	local num = mcmlNode:GetString("value") or 0;

	local step_height = height - top
	if tonumber(num) == 2 then
		step_height = 180
		css.height = step_height
	end
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, width-left, step_height);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", 0, 0, 65, 36);
	step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotiditu_65x36_32bits.png;0 0 65 36";
	_this:AddChild(step_icon);

	local step_num_text = ParaUI.CreateUIObject("text", "lessonppt_step_num_text", "_lt", 18, 3, 32, 32);
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
		local check_icon = ParaUI.CreateUIObject("container", "lessonppt_check_icon", "_lt", 42, 14, 26, 24);
		check_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v_26X24_32bits.png;0 0 26 24";
		_root:AddChild(check_icon);
	end
	
	
	parentLayout.step_num = step_num
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

function step.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local num = mcmlNode:GetString("value") or 0;

	local step_height = height - top
	if tonumber(num) == 2 or tonumber(num) == 3 then
		step_height = tonumber(num) == 2 and 180 or 150
		css.height = step_height
	end
	
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, width-left, step_height);
	_this.background = "";
	_parent:AddChild(_this);
	local _root = _this;

	local step_icon = ParaUI.CreateUIObject("container", "lessonppt_step_icon", "_lt", 0, 0, 97, 54);
	step_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotiditu_65x36_32bits.png;0 0 65 36";
	_this:AddChild(step_icon);

	local step_num_text = ParaUI.CreateUIObject("text", "lessonppt_step_num_text", "_lt", 29, 5, 48, 48);
	_guihelper.SetFontColor(step_num_text, "#ffffff");
	step_num_text.font = "System;30;norm"
	step_num_text.text = num;
	step_icon:AddChild(step_num_text);

	local cur_step_num = RedSummerCampPPtPage.GetStepNumKey()
	local step_num = tonumber(num)
	if step_num == math.floor(cur_step_num) then
		step_num = cur_step_num + 0.1
	end
	RedSummerCampPPtPage.SetStepNumKey(step_num)

	if RedSummerCampPPtPage.GetStepIsComplete(step_num) then
		local check_icon = ParaUI.CreateUIObject("container", "lessonppt_check_icon", "_lt", 63, 14, 39, 36);
		check_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/v_26X24_32bits.png;0 0 26 24";
		_root:AddChild(check_icon);
	end
	
	
	parentLayout.step_num = step_num
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end