--[[
Title: teacher icon
Author(s): LiXizhi
Date: 2018/9/16
Desc: that is usually shown on left top of the screen. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherIcon.lua");
local TeacherIcon = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherIcon");
TeacherIcon.Show(true)
TeacherIcon.SetBouncing(true)
TeacherIcon.SetHeadonText("hello world~")
-------------------------------------------------------
]]
local TeacherIcon = commonlib.gettable("MyCompany.Aries.Creator.Game.Teacher.TeacherIcon");


TeacherIcon.leftMin = 10;
TeacherIcon.leftMax = 128;
TeacherIcon.left = TeacherIcon.leftMin;
TeacherIcon.top = 51;
TeacherIcon.width = 400;
TeacherIcon.height = 108;

local page;
function TeacherIcon.Init()
	page = document:GetPageCtrl();
end

function TeacherIcon.Show(bShow)
	if(bShow == nil) then
		bShow = true;
	end
	
	local left = bShow and TeacherIcon.ComputeLeftPos() or TeacherIcon.left;
	local params = {
		url = "script/apps/Aries/Creator/Game/Login/TeacherAgent/TeacherIcon.html", 
		name = "TeacherAgent.TeacherIcon.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = false,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		zorder = -1,
		ClickThrough = true,
		cancelShowAnimation = true,
		directPosition = true,
			align = "_lt",
			x = left,
			y = TeacherIcon.top,
			width = TeacherIcon.width,
			height = TeacherIcon.height,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	if(TeacherIcon.left ~= left) then
		TeacherIcon.left = left;
		params._page:GetWindow():MoveWindow(TeacherIcon.left, TeacherIcon.top, TeacherIcon.width, TeacherIcon.height);
	end
end

function TeacherIcon.ComputeLeftPos()
	local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
	if not TouchVirtualKeyboardIcon then
		TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
	end

	if(TouchVirtualKeyboardIcon.IsSingletonVisible and TouchVirtualKeyboardIcon.IsSingletonVisible()) then
		local icon = TouchVirtualKeyboardIcon.GetSingleton();
		return (icon.left or 0) + (icon.width or 64) + 5;
	end
	return TeacherIcon.leftMin;
end

-- give it a visual attention
function TeacherIcon.SetBouncing(bBouncing)
	TeacherIcon.animator_bg = bBouncing and "Texture/Aries/Common/ThemeTeen/animated/btn_anim_32bits_fps10_a012.png" or "";
	if(page) then
		local _flash = ParaUI.GetUIObject("teacher_animator_");
		_flash.background = TeacherIcon.animator_bg;
	end
end

function TeacherIcon.SetTaskCount(count)
end

-- this is text that is displayed next to the icon
-- @param text: can be html text
function TeacherIcon.SetTipText(text)
	if(TeacherIcon.text ~= text) then
		TeacherIcon.text = text;
		TeacherIcon.Refresh();
	end
end

function TeacherIcon.GetTipText()
	return TeacherIcon.text or "";
end

function TeacherIcon.GetIconPosition()
	if(page) then
		local btn = page:FindControl("btnMain")
		if(btn) then
			return btn.x, btn.y;
		end
	end
end

function TeacherIcon.Refresh(delay)
	if(page) then
		page:Refresh(delay or 0.01);
	end
end

local main_button;

local button_ds = {};
-- @param buttons: ArrayMap type
function TeacherIcon.UpdateTaskButtons(buttons)
	main_button = buttons:at(1);
	table.resize(button_ds, math.max(0, buttons:size()-1));
	for i=2, buttons:size() do
		button_ds[i-1] = buttons:at(i);
	end
	TeacherIcon.Refresh();
end

function TeacherIcon.GetButtonDs(index)
	if(not index) then
		return #button_ds;
	else
		return button_ds[index];
	end
end

function TeacherIcon.GetMainCount()
	return main_button and main_button.count or 0;
end

function TeacherIcon.GetMainButton()
	return main_button;
end

function TeacherIcon.SetEmptyClickCallback(onclick)
	TeacherIcon.onclickCallback = onclick;
end

function TeacherIcon.OnClick()
	if(main_button and main_button.onclick) then
		main_button.onclick();
	elseif(TeacherIcon.onclickCallback) then
		TeacherIcon.onclickCallback();
	end
end