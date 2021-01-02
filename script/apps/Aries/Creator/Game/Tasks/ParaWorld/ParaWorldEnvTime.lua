--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldEnvTime = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldEnvTime.lua");
ParaWorldEnvTime.ShowPage();
-------------------------------------------------------
]]
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
NPL.load("(gl)script/mobile/paracraft/Areas/SettingPage.lua");
local SettingPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SettingPage");
local ParaWorldEnvTime = NPL.export();

local currentTime;
local page;
function ParaWorldEnvTime.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldEnvTime.ShowPage()
	--currentTime = currentTime or SettingPage.GetTimeOfDayStd();
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldEnvTime.html",
		name = "ParaWorldEnvTime.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -400 / 2,
		y = -160 / 2,
		width = 400,
		height = 160,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaWorldEnvTime.OnClose()
	if (page) then
		page:CloseWindow();
	end
end

function ParaWorldEnvTime.SetDefault()
	currentTime = SettingPage.GetTimeOfDayStd();
	local time = (currentTime/1000-0.5)*2;
	time = tostring(time);
	CommandManager:RunCommand("time", time);
	if (page) then
		page:Refresh(0);
	end
end

function ParaWorldEnvTime.OnTimeSliderChanged(value)
	if (value) then
		--currentTime = value;
		local time = (value/1000-0.5)*2;
		time = tostring(time);
		CommandManager:RunCommand("time", time);
	end	
end
