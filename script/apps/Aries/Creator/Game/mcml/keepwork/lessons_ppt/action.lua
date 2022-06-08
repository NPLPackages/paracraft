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

	local action_type = mcmlNode:GetAttribute("type")
	if action_type == "dailyVideo" or action_type == "dailyVideoLink" then
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
		local root_y = 18
		local root_height = 139
		
		local _this = ParaUI.CreateUIObject("container", "action_explore_type", "_lt", left, top + root_y, 225, root_height);
		_this.background = ""
		_parent:AddChild(_this);
		_parent = _this;
		css.height = root_y + root_height

		local projectid = mcmlNode:GetString("projectid");

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end

		local project_data = RedSummerCampPPtPage.GetProjectData(projectid)
		local img_url = project_data.imageUrl or ""
		_this = ParaUI.CreateUIObject("container", "action_explore_bg", "_lt", 10, 8, 211, 106);
		_this.background = img_url;
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "action_explore_bt", "_lt", 0, 0, 225, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/baidi_52x74_32bits.png;0 0 52 74:24 24 24 45"
		-- _this.font = "System;24;norm"
		-- _this.text = "打开"
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type, projectid)
			end
		end);
		_parent:AddChild(_this);
		
		local project_name = ParaUI.CreateUIObject("text", "lessonppt_project_name", "_lt", 0, 113, 225, 25);
		_guihelper.SetFontColor(project_name, "#333333");
		_guihelper.SetUIFontFormat(project_name, 3);
		project_name.font = "System;14;norm"

		local title = RedSummerCampPPtPage.GetStepTitle() or project_data.worldTagName
		project_name.text = title or ""
		_parent:AddChild(project_name);
	elseif action_type == "dailyVideo" then
		local root_y = 20
		local root_x = -20
		local root_height = 110
		local root_width = 110
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		local course_id = mcmlNode:GetString("id");
		if course_id and course_id ~= "" then
			local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
			
			local _this = ParaUI.CreateUIObject("button", "action_dailyVideo_icon", "_lt", 20, 0, 83, 85);
			_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/neibushiping_83x85_32bits.png;0 0 83 85";
			_this:SetScript("onclick", function()
				if course_id then
					RedSummerCampPPtPage.OnClickAction(action_type, course_id)
				end
			end);
			_parent:AddChild(_this);

			if tonumber(course_id) > 16 then
				local vip_icon = ParaUI.CreateUIObject("container", "action_dailyVideo_vip_icon", "_lt", 15, -4, 35, 38);
				vip_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/main/zi2_48X53_32bits.png;0 0 48 53";
				_parent:AddChild(vip_icon);
			end

			local dailyVideo_title = ParaUI.CreateUIObject("text", "action_dailyVideo_title", "_ct", -48, 30, 110, 40);
			_guihelper.SetFontColor(dailyVideo_title, "#000000");
			_guihelper.SetUIFontFormat(dailyVideo_title, 17);
			dailyVideo_title.font = "System;14;bold"
			ParacraftLearningRoomDailyPage.LoadLessonsConfig()
			local title = ParacraftLearningRoomDailyPage.lessons_title[tonumber(course_id)]
			RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
			-- dailyVideo_title.text = course_id .. "." .. title;
			dailyVideo_title.text = title;
			_parent:AddChild(dailyVideo_title);
		end

		css.height = root_y + root_height
		css.width = root_width
	elseif action_type == "dailyVideoLink" then
		local root_y = 20
		local root_x = -20
		local root_height = 110
		local root_width = 110
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		local _this = ParaUI.CreateUIObject("button", "action_dailyVideo_icon", "_lt", 20, 0, 83, 85);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/waibushiping_83x85_32bits.png;0 0 83 85";

		local link = mcmlNode:GetString("href");
		local is_external_link = mcmlNode:GetString("is_external_link") == "true";
		local title = mcmlNode:GetString("value");
		_this:SetScript("onclick", function()
			if link then
				RedSummerCampPPtPage.OnClickAction(action_type, link, is_external_link, title)
			end
		end);
		_parent:AddChild(_this);

		local dailyVideoLink_title = ParaUI.CreateUIObject("text", "action_dailyVideoLink_title", "_ct", -48, 30, 110, 40);
		_guihelper.SetFontColor(dailyVideoLink_title, "#000000");
		_guihelper.SetUIFontFormat(dailyVideoLink_title, 17);
		dailyVideoLink_title.font = "System;14;bold"
		
		dailyVideoLink_title.text = title;
		_parent:AddChild(dailyVideoLink_title);

		css.height = root_y + root_height
		css.width = root_width
	elseif action_type == "button" then
		local text_value = mcmlNode:GetString("value") or "";
		local root_y = -2
		local root_width = 278
		local root_height = 41
		-- local root_width = 174
		local projectid = mcmlNode:GetString("projectid");
		-- if(projectid) then
		-- 	if(text_value) then
		-- 		text_value = text_value;
		-- 	else
		-- 		text_value = L"项目ID: "..projectid;
		-- 	end
		-- end
		local fontName = "System;21;bold";
		

		local sendevent= mcmlNode:GetString("sendevent")
		
		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 75, top + root_y, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotianniu_278x41_32bits.png;0 0 278 41";
		-- _this.tooltip = string.format("点击打开世界：%s", projectid)
		_parent:AddChild(_this);
		-- _guihelper.SetFontColor(_this, "#853a0d");
		-- _this.font = fontName
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type, projectid, sendevent)
			end
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x + 10, _this.y + 7, root_width - 6, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#000000");

		_parent:AddChild(button_text);
		

		_parent = _this;

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end

		css.height = root_y + root_height

	elseif action_type == "loadworld" then
		local text_value = mcmlNode:GetString("value");
		local root_y = -2
		local root_width = 278
		local root_height = 41

		local word_len = ParaMisc.GetUnicodeCharNum(text_value)
		local fontName = "System;21;bold";

		RedSummerCampPPtPage.SetSaveWorldStepValue(parentLayout.step_num)

		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 75, top + root_y, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotianniu_278x41_32bits.png;0 0 278 41";
		_parent:AddChild(_this);
		_this:SetScript("onclick", function()
			RedSummerCampPPtPage.OnClickAction(action_type)
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x + 10, _this.y + 7, root_width - 6, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#000000");
		-- _guihelper.SetUIFontFormat(button_text, 17);

		_parent:AddChild(button_text);

		_parent = _this;

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

		
		local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", 40, 10, root_width, root_height);
		_guihelper.SetFontColor(button_title, "#000000");
		button_title.font = "System;18;norm"
		button_title.text = "保存作品Ctrl+S，上传分享";
		_parent:AddChild(button_title);


		css.height = root_y + root_height
	end

	if css.height then
		parent_height = parent_height + css.height
		parentLayout:SetSize(parent_width, parent_height)
	end
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
		local root_height = 208
		
		local _this = ParaUI.CreateUIObject("container", "action_explore_type", "_lt", left, top + root_y, 337, root_height);
		_this.background = ""
		_parent:AddChild(_this);
		_parent = _this;
		css.height = root_y + root_height

		local projectid = mcmlNode:GetString("projectid");
		
		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end
		local project_data = RedSummerCampPPtPage.GetProjectData(projectid)
		local img_url = project_data.imageUrl or ""
		_this = ParaUI.CreateUIObject("container", "action_explore_bg", "_lt", 10, 10, 316, 170);
		_this.background = img_url;
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "action_explore_bt", "_lt", 0, 0, 337, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/baidi_52x74_32bits.png;0 0 52 74:24 24 24 45"
		-- _this.font = "System;24;norm"
		-- _this.text = "打开"
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type, projectid)
			end
		end);
		_parent:AddChild(_this);
		
		local project_name = ParaUI.CreateUIObject("text", "lessonppt_project_name", "_lt", 0, 178, 337, 35);
		_guihelper.SetFontColor(project_name, "#333333");
		_guihelper.SetUIFontFormat(project_name, 3);
		project_name.font = "System;18;norm"
		project_name.text = project_data.worldTagName or ""
		_parent:AddChild(project_name);
	elseif action_type == "dailyVideo" then
		local root_y = 20
		local root_x = -20
		local root_height = 165
		local root_width = 165
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;
		local course_id = mcmlNode:GetString("id");
		if course_id and course_id ~= "" then
			local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
			
			local _this = ParaUI.CreateUIObject("button", "action_dailyVideo_icon", "_lt", 20, 0, 124, 127);
			_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/neibushiping_83x85_32bits.png;0 0 83 85";
			_this:SetScript("onclick", function()
				if course_id then
					RedSummerCampPPtPage.OnClickAction(action_type, course_id)
				end
			end);
			_parent:AddChild(_this);

			if tonumber(course_id) > 16 then
			-- if true then
				local vip_icon = ParaUI.CreateUIObject("container", "action_dailyVideo_vip_icon", "_lt", 8, -10, 52, 57);
				vip_icon.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/main/zi2_48X53_32bits.png;0 0 48 53";
				_parent:AddChild(vip_icon);
			end

			local dailyVideo_title = ParaUI.CreateUIObject("text", "action_dailyVideo_title", "_ct", -80, 45, 165, 60);
			_guihelper.SetFontColor(dailyVideo_title, "#000000");
			_guihelper.SetUIFontFormat(dailyVideo_title, 17);
			dailyVideo_title.font = "System;20;bold"
			ParacraftLearningRoomDailyPage.LoadLessonsConfig()
			local title = ParacraftLearningRoomDailyPage.lessons_title[tonumber(course_id)]
			RedSummerCampPPtPage.SetCurPPtCourseTitle(title)
			-- dailyVideo_title.text = course_id .. "." .. title;
			dailyVideo_title.text = title;
			_parent:AddChild(dailyVideo_title);
		end

		css.height = root_y + root_height
		css.width = root_width
	elseif action_type == "dailyVideoLink" then
		local root_y = 20
		local root_x = -20
		local root_height = 165
		local root_width = 165
		local _this = ParaUI.CreateUIObject("container", "action_dailyVideo_type", "_lt", root_x + left, top + root_y, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;

		local _this = ParaUI.CreateUIObject("button", "action_dailyVideoLink_icon", "_lt", 20, 0, 124, 127);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/waibushiping_83x85_32bits.png;0 0 83 85";

		local link = mcmlNode:GetString("href");
		_this:SetScript("onclick", function()
			if link then
				RedSummerCampPPtPage.OnClickAction(action_type, link)
			end
		end);
		_parent:AddChild(_this);

		local dailyVideoLink_title = ParaUI.CreateUIObject("text", "action_dailyVideoLink_title", "_ct", -80, 45, 165, 60);
		_guihelper.SetFontColor(dailyVideoLink_title, "#000000");
		_guihelper.SetUIFontFormat(dailyVideoLink_title, 17);
		dailyVideoLink_title.font = "System;20;bold"
		local title = mcmlNode:GetString("value");
		dailyVideoLink_title.text = title;
		_parent:AddChild(dailyVideoLink_title);

		css.height = root_y + root_height
		css.width = root_width
	elseif action_type == "button" then
		local text_value = mcmlNode:GetString("value") or "";
		local root_y = -3
		local root_width = 398
		local root_height = 58
		-- local root_width = 174
		local projectid = mcmlNode:GetString("projectid");
		-- if(projectid) then
		-- 	if(text_value) then
		-- 		text_value = text_value.." "..projectid;
		-- 	else
		-- 		text_value = L"项目ID: "..projectid;
		-- 	end
		-- end
		local fontName = "System;26;bold";
		

		local sendevent= mcmlNode:GetString("sendevent")
		
		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 112, top + root_y, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotianniu_278x41_32bits.png;0 0 278 41";
		-- _this.tooltip = string.format("点击打开世界：%s", projectid)
		_parent:AddChild(_this);
		_this:SetScript("onclick", function()
			if projectid then
				RedSummerCampPPtPage.OnClickAction(action_type, projectid, sendevent)
			end
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x + 9, _this.y + 12, root_width - 6, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#000000");
		_parent:AddChild(button_text);
		_parent = _this;

		if projectid then
			RedSummerCampPPtPage.SetStepValueToProjectId(parentLayout.step_num, projectid)
		end

		css.height = root_y + root_height

	elseif action_type == "loadworld" then
		local text_value = mcmlNode:GetString("value");
		local root_y = -3
		local root_width = 398
		local root_height = 58
		-- local root_width = 174
		local fontName = "System;26;bold";
		
		local _this = ParaUI.CreateUIObject("button", "action_button_type", "_lt", left + 112, top + root_y, root_width, root_height);
		_this.background = "Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/biaotianniu_278x41_32bits.png;0 0 278 41";
		_parent:AddChild(_this);
		_this:SetScript("onclick", function()
			RedSummerCampPPtPage.OnClickAction(action_type)
		end);

		local button_text = ParaUI.CreateUIObject("text", "action_button_text", "_lt", _this.x + 9, _this.y + 12, root_width - 6, root_height);
		button_text.text = text_value
		button_text.font = fontName
		_guihelper.SetFontColor(button_text, "#000000");
		_parent:AddChild(button_text);
		_parent = _this;

		css.height = root_y + root_height
	elseif action_type == "saveAndShare" then
		RedSummerCampPPtPage.SetSyncWorldStepValue(parentLayout.step_num)
		local root_y = 15
		local word_font = 26

		local root_height = 66
		local root_width = 396

		local _this = ParaUI.CreateUIObject("container", "action_button_type", "_lt", left + 98, top + root_y - 10, root_width, root_height);
		_this.background = "";
		_parent:AddChild(_this);
		_parent = _this;

		
		local button_title = ParaUI.CreateUIObject("text", "action_button_title", "_lt", 15, 15, root_width, root_height);
		_guihelper.SetFontColor(button_title, "#000000");
		button_title.font = "System;26;norm"
		button_title.text = "保存作品Ctrl+S，上传分享";
		_parent:AddChild(button_title);


		css.height = root_y + root_height
	end

	if css.height then
		parent_height = parent_height + css.height
		parentLayout:SetSize(parent_width, parent_height)
	end
end