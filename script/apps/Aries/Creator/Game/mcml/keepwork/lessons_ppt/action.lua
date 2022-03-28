--[[
Title: 
Author(s): yangguiyi
Date: 2021/9/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/lessons_ppt/action.lua");
local action = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.action");
-------------------------------------------------------
]]
local action = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.action");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
function action.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	if RedSummerCampPPtPage.GetIsFullPage() then
		action.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	else
		action.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	end
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function action.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	if mcmlNode:GetAttribute("type") == "dailyVideo" then
		style.float = "left"
		style.height = 100
	end

	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, action.render_callback);
end

function action.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local parent_width, parent_height = w, h;
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	


	local action_type = mcmlNode:GetString("type");
	if action_type == "explore" then
		local root_y = 30
		local root_height = 45
		
		local _this = ParaUI.CreateUIObject("container", "action_explore_type", "_lt", left, top + root_y, 330, root_height);
		-- _this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		css.height = root_y + root_height

		_this = ParaUI.CreateUIObject("container", "action_explore_bg", "_lt", 0, 0, 322, 45);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/5_32bits.png;0 0 32 32:8 8 8 8";
		_parent:AddChild(_this);
		

		local projectid = mcmlNode:GetString("projectid");
		local projectid_text = ParaUI.CreateUIObject("text", "lessonppt_projectid_text", "_lt", 10, 8, 232, 42);
		_guihelper.SetFontColor(projectid_text, "#5e5e5e");
		projectid_text.font = "System;24;norm"
		projectid_text.text = "项目 ID:"
		_parent:AddChild(projectid_text);

		local projectid_id_text = ParaUI.CreateUIObject("text", "lessonppt_projectid_id_text", "_lt", 110, 8, 232, 42);
		_guihelper.SetFontColor(projectid_id_text, "#000000");
		projectid_id_text.font = "System;24;norm"
		projectid_id_text.text = string.format("%s", projectid);
		_parent:AddChild(projectid_id_text);

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end

		_this = ParaUI.CreateUIObject("button", "action_explore_bt", "_lt", 242, -2, 90, 50);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/works/works_32bits.png;205 112 86 46";
		_this.font = "System;24;norm"
		_this.text = "打开"
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type)
				GameLogic.RunCommand(string.format("/loadworld -s -auto %s", projectid))
			end
		end);
		
		_parent:AddChild(_this);

		parentLayout:NewLine();
	elseif action_type == "dailyVideo" then
		local root_y = 20
		local root_x = 0
		local root_height = 100
		local root_width = 100
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		local course_id = mcmlNode:GetString("id");
		if course_id and course_id ~= "" then
			local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
			
			local _this = ParaUI.CreateUIObject("button", "action_dailyVideo_icon", "_lt", 20, 10, 60, 57);
			_this.background = "Texture/Aries/Creator/keepwork/LearningDailyCheck/play_gray2_32bits.png;0 0 60 57";
			_this:SetScript("onclick", function()
				if course_id then
					RedSummerCampPPtPage.OnClickAction(action_type)
					ParacraftLearningRoomDailyPage.OnOpenWeb(tonumber(course_id),true)
				end
			end);
			_parent:AddChild(_this);

			if tonumber(course_id) > 16 then
				local vip_icon = ParaUI.CreateUIObject("container", "action_dailyVideo_vip_icon", "_lt", 10, -4, 35, 35);
				vip_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/main/zi2_48X53_32bits.png;0 0 48 53";
				_parent:AddChild(vip_icon);
			end

			local dailyVideo_title = ParaUI.CreateUIObject("text", "action_dailyVideo_title", "_ct", -39, 18, 80, 40);
			_guihelper.SetFontColor(dailyVideo_title, "#000000");
			_guihelper.SetUIFontFormat(dailyVideo_title, 17);
			dailyVideo_title.font = "System;14;norm"
			ParacraftLearningRoomDailyPage.LoadLessonsConfig()
			local title = ParacraftLearningRoomDailyPage.lessons_title[tonumber(course_id)]
			RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
			dailyVideo_title.text = course_id .. "." .. title;
			_parent:AddChild(dailyVideo_title);

			
		end

		-- css.height = root_y + root_height
		css.width = root_width
	elseif action_type == "button" then
		local text_value = mcmlNode:GetString("value");
		local root_y = 10
		local root_height = 46
		-- local root_width = 174
		local projectid = mcmlNode:GetString("projectid");
		if(projectid) then
			if(text_value) then
				text_value = text_value.." "..projectid;
			else
				text_value = L"项目ID: "..projectid;
			end
		end
		local padding = 13
		local fontName = "System;18;norm";
		local root_width = _guihelper.GetTextWidth(text_value, fontName) + padding * 2
		if root_width > 274 then
			root_width = 274
			root_height = 67
		end

		local sendevent= mcmlNode:GetString("sendevent")
		
		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 50, top + root_y - 7, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/b1_32X46_32bits.png;0 0 32 46:8 8 8 8";
		_this.tooltip = string.format("点击打开世界：%s", projectid)
		_parent:AddChild(_this);
		-- _guihelper.SetFontColor(_this, "#853a0d");
		-- _this.font = fontName
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type)
				local commandStr = string.format("/loadworld -s -auto %s", projectid)
				if sendevent and sendevent ~= "" then
					commandStr = string.format("/loadworld -s -auto -inplace %s  | /sendevent %s", projectid,sendevent)
				end
				GameLogic.RunCommand(commandStr)
			end
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x, _this.y + 10, root_width, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#853a0d");
		_guihelper.SetUIFontFormat(button_text, 17);

		_parent:AddChild(button_text);
		
		-- _this.text = text_value;
		-- _this:GetAttributeObject():SetField("TextOffsetY", -1)

		_parent = _this;

		if root_width >= 258 then
			css.width = 300
		end
		
		-- local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", padding + 7, 10, root_width, 40);
		-- _guihelper.SetFontColor(button_title, "#853a0d");
		-- button_title.font = "System;18;norm"
		-- button_title.text = text_value;
		-- _parent:AddChild(button_title);

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)

			-- local _this = ParaUI.CreateUIObject("button", "action_button_icon", "_lt", 20, 10, root_width, root_height);
			-- _this.background = "";
			-- _this:SetScript("onclick", function()
			-- 	if projectid then
			-- 		GameLogic.RunCommand(string.format("/loadworld -s -auto %s", projectid))
			-- 	end
			-- end);
			-- _parent:AddChild(_this);

		end

		css.height = root_y + root_height

	elseif action_type == "loadworld" then
		local text_value = mcmlNode:GetString("value");
		local root_y = 10
		local root_height = 46
		-- local root_width = 174

		local padding = 13
		local word_len = ParaMisc.GetUnicodeCharNum(text_value)
		local fontName = "System;18;norm";
		local root_width = _guihelper.GetTextWidth(text_value, fontName) + padding * 2

		RedSummerCampPPtPage.SetSaveWorldStepValue(parentLayout.step_num)

		local _this = ParaUI.CreateUIObject("button", "action_loadworld_type", "_lt", left + 50, top + root_y - 7, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/b1_32X46_32bits.png;0 0 32 46:8 8 8 8";
		_parent:AddChild(_this);
		_guihelper.SetFontColor(_this, "#853a0d");
		_this.font = "System;18;norm"
		_this.text = text_value;
		_this:GetAttributeObject():SetField("TextOffsetY", -1)
		_this:SetScript("onclick", function()
			RedSummerCampPPtPage.OnClickAction(action_type)
			local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
			Opus:Show()
		end);
		_parent = _this;

		
		if root_width >= 258 then
			css.width = 300
		end
		-- local loadworld_title = ParaUI.CreateUIObject("text", "action_loadworld_title", "_lt", padding + 7, 10, root_width, 40);
		-- _guihelper.SetFontColor(loadworld_title, "#853a0d");
		-- loadworld_title.font = "System;18;norm"
		-- loadworld_title.text = text_value;
		-- _parent:AddChild(loadworld_title);

		-- local _this = ParaUI.CreateUIObject("button", "action_loadworld_icon", "_lt", 20, 10, root_width, root_height);
		-- _this.background = "";
		-- _this:SetScript("onclick", function()
		-- 	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
		-- 	Opus:Show()
		-- end);
		-- _parent:AddChild(_this);

		css.height = root_y + root_height
	elseif action_type == "saveAndShare" then
		RedSummerCampPPtPage.SetSyncWorldStepValue(parentLayout.step_num)
		local root_y = 10
		local word_font = 18

		local root_height = 44
		local root_width = 264

		local _this = ParaUI.CreateUIObject("container", "action_button_type", "_lt", left + 40, top + root_y - 7, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;

		
		local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", 7, 10, root_width, root_height);
		_guihelper.SetFontColor(button_title, "#e17a15");
		button_title.font = "System;18;bold"
		button_title.text = "保存作品Ctrl+S，上传分享";
		_parent:AddChild(button_title);


		css.height = root_y + root_height
	end

	if css.height then
		parent_height = parent_height + css.height
		parentLayout:SetSize(parent_width, parent_height)
	end
	
-- print("fffffffffffffxx", parent_width, parent_height, css.height, parentLayout)
-- echo(css, true)

end

function action.create_full_page(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local w = mcmlNode:GetNumber("width") or (width-left);
	local default_height = mcmlNode:GetNumber("height")
	local h = default_height or (height-top);
	local parent_width, parent_height = w, h;
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	


	local action_type = mcmlNode:GetString("type");
	if action_type == "explore" then
		local root_y = 30
		local root_height = 68
		
		local _this = ParaUI.CreateUIObject("container", "action_explore_type", "_lt", left, top + root_y, 500, root_height);
		-- _this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		css.height = root_y + root_height

		_this = ParaUI.CreateUIObject("container", "action_explore_bg", "_lt", 0, 0, 493, 68);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/5_32bits.png;0 0 32 32:8 8 8 8";
		_parent:AddChild(_this);
		

		local projectid = mcmlNode:GetString("projectid");
		local projectid_text = ParaUI.CreateUIObject("text", "lessonppt_projectid_text", "_lt", 10, 8, 361, 68);
		_guihelper.SetFontColor(projectid_text, "#5e5e5e");
		projectid_text.font = "System;37;norm"
		projectid_text.text = "项目 ID:"
		_parent:AddChild(projectid_text);

		local projectid_id_text = ParaUI.CreateUIObject("text", "lessonppt_projectid_id_text", "_lt", 160, 8, 361, 68);
		_guihelper.SetFontColor(projectid_id_text, "#000000");
		projectid_id_text.font = "System;37;norm"
		projectid_id_text.text = string.format("%s", projectid);
		_parent:AddChild(projectid_id_text);

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end

		_this = ParaUI.CreateUIObject("button", "action_explore_bt", "_lt", 365, -2, 138, 74);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/works/works_32bits.png;205 112 86 46";
		_this.font = "System;36;norm"
		_this.text = "打开"
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type)
				GameLogic.RunCommand(string.format("/loadworld -s -auto %s", projectid))
			end
		end);
		
		_parent:AddChild(_this);

		parentLayout:NewLine();
	elseif action_type == "dailyVideo" then
		local root_y = 45
		local root_x = 0
		local root_height = 150
		local root_width = 150
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;

		local course_id = mcmlNode:GetString("id");
		if course_id and course_id ~= "" then
			local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
			
			local _this = ParaUI.CreateUIObject("button", "action_dailyVideo_icon", "_lt", 30, 15, 90, 85);
			_this.background = "Texture/Aries/Creator/keepwork/LearningDailyCheck/play_gray2_32bits.png;0 0 60 57";
			_this:SetScript("onclick", function()
				if course_id then
					RedSummerCampPPtPage.OnClickAction(action_type)
					ParacraftLearningRoomDailyPage.OnOpenWeb(tonumber(course_id),true)
				end
			end);
			_parent:AddChild(_this);
			if tonumber(course_id) > 16 then
				local vip_icon = ParaUI.CreateUIObject("container", "action_dailyVideo_vip_icon", "_lt", 15, -6, 52, 52);
				vip_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/main/zi2_48X53_32bits.png;0 0 48 53";
				_parent:AddChild(vip_icon);
			end

			local dailyVideo_title = ParaUI.CreateUIObject("text", "action_dailyVideo_title", "_ct", -58, 27, 120, 60);
			_guihelper.SetFontColor(dailyVideo_title, "#000000");
			_guihelper.SetUIFontFormat(dailyVideo_title, 17);
			dailyVideo_title.font = "System;20;norm"
			ParacraftLearningRoomDailyPage.LoadLessonsConfig()
			local title = ParacraftLearningRoomDailyPage.lessons_title[tonumber(course_id)]
			RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
			dailyVideo_title.text = course_id .. "." .. title;
			_parent:AddChild(dailyVideo_title);

			
		end
		css.width = root_width
	elseif action_type == "button" then
		local text_value = mcmlNode:GetString("value");
		local root_y = 15
		local root_height = 69
		-- local root_width = 174

		local projectid = mcmlNode:GetString("projectid");
		if(projectid) then
			if(text_value) then
				text_value = text_value.." "..projectid;
			else
				text_value = L"项目ID: "..projectid;
			end
		end

		local padding = 24
		local fontName = "System;26;norm";
		local root_width = _guihelper.GetTextWidth(text_value, fontName) + padding * 2

		if root_width > 384 then
			root_width = 384
			root_height = 96
		end
		
		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 80, top + root_y - 13, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/b1_32X46_32bits.png;0 0 32 46:8 8 8 8";
		_parent:AddChild(_this);
		_guihelper.SetFontColor(_this, "#853a0d");
		-- _this.font = fontName
		-- _this.text = text_value;
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type)
				GameLogic.RunCommand(string.format("/loadworld -s -auto %s", projectid))
			end
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x, _this.y + 16, root_width, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#853a0d");
		_guihelper.SetUIFontFormat(button_text, 17);

		_parent:AddChild(button_text);
		
		_parent = _this;

		if root_width >= 387 then
			css.width = 450
		end
		
		-- local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", padding + 10, 17, root_width, 60);
		-- _guihelper.SetFontColor(button_title, "#853a0d");
		-- button_title.font = "System;26;norm"
		-- button_title.text = text_value;
		-- _parent:AddChild(button_title);

		
		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)

			-- local _this = ParaUI.CreateUIObject("button", "action_button_icon", "_lt", 30, 15, root_width, root_height);
			-- _this.background = "";
			-- _this:SetScript("onclick", function()
			-- 	if projectid then
			-- 		GameLogic.RunCommand(string.format("/loadworld -s -auto %s", projectid))
			-- 	end
			-- end);
			-- _parent:AddChild(_this);

		end

		css.height = root_y + root_height

	elseif action_type == "loadworld" then
		local text_value = mcmlNode:GetString("value");
		local root_y = 15
		local root_height = 69
		-- local root_width = 174

		local padding = 24
		local word_len = ParaMisc.GetUnicodeCharNum(text_value)
		local fontName = "System;27;norm";
		local root_width = _guihelper.GetTextWidth(text_value, fontName) + padding * 2

		RedSummerCampPPtPage.SetSaveWorldStepValue(parentLayout.step_num)

		local _this = ParaUI.CreateUIObject("button", "action_loadworld_type", "_lt", left + 80, top + root_y - 13, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/b1_32X46_32bits.png;0 0 32 46:8 8 8 8";
		_parent:AddChild(_this);
		_guihelper.SetFontColor(_this, "#853a0d");
		_this.font = "System;26;norm"
		_this.text = text_value;
		_this:SetScript("onclick", function()
			RedSummerCampPPtPage.OnClickAction(action_type)
			local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
			Opus:Show()
		end);
		_parent = _this;

		
		if root_width >= 387 then
			css.width = 450
		end
		-- local loadworld_title = ParaUI.CreateUIObject("text", "action_loadworld_title", "_lt", padding + 10, 17, root_width, 60);
		-- _guihelper.SetFontColor(loadworld_title, "#853a0d");
		-- loadworld_title.font = "System;26;norm"
		-- loadworld_title.text = text_value;
		-- _parent:AddChild(loadworld_title);

		-- local _this = ParaUI.CreateUIObject("button", "action_loadworld_icon", "_lt", 30, 15, root_width, root_height);
		-- _this.background = "";
		-- _this:SetScript("onclick", function()
		-- 	local Opus = NPL.load("(gl)Mod/WorldShare/cellar/Opus/Opus.lua")
		-- 	Opus:Show()
		-- end);
		-- _parent:AddChild(_this);

		css.height = root_y + root_height
	elseif action_type == "saveAndShare" then
		RedSummerCampPPtPage.SetSyncWorldStepValue(parentLayout.step_num)
		local root_y = 15
		local word_font = 26

		local root_height = 66
		local root_width = 396

		local _this = ParaUI.CreateUIObject("container", "action_button_type", "_lt", left + 60, top + root_y - 10, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;

		
		local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", 10, 15, root_width, root_height);
		_guihelper.SetFontColor(button_title, "#e17a15");
		button_title.font = "System;26;bold"
		button_title.text = "保存作品Ctrl+S，上传分享";
		_parent:AddChild(button_title);


		css.height = root_y + root_height
	end

	if css.height then
		parent_height = parent_height + css.height
		parentLayout:SetSize(parent_width, parent_height)
	end
	
-- print("fffffffffffffxx", parent_width, parent_height, css.height, parentLayout)
-- echo(css, true)

end