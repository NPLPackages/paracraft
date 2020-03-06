--[[
Title: Lock Desktop
Author(s): LiXizhi
Date: 2020/3/5
Desc: it will always bring window to front as well

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/LockDesktop.lua");
local LockDesktop = commonlib.gettable("MyCompany.Aries.Game.Tasks.LockDesktop");
LockDesktop.ShowPage(true, 5, "window is locked");
-------------------------------------------------------
]]
local LockDesktop = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.LockDesktop"));

local page;

LockDesktop.timeLeft = 0;
function LockDesktop.OnInit()
	page = document:GetPageCtrl();
end

-- @param duration: in seconds
function LockDesktop.ShowPage(bShow, duration, text)
	LockDesktop.duration = duration or 10;
	LockDesktop.text = text;
	LockDesktop.timer = LockDesktop.timer or commonlib.Timer:new({callbackFunc = function(timer)
		LockDesktop.OnTimer(timer)
	end})
	if(bShow) then
		LockDesktop.timeLeft = LockDesktop.duration
		LockDesktop.timer:Change(1000, 1000);
	else
		LockDesktop.timer:Change()
	end

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/LockDesktop.html", 
			name = "LockDesktopTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			bShow = bShow,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1000,
			allowDrag = false,
			isTopLevel = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		});
end

function LockDesktop.OnTimer(timer)
	LockDesktop.timeLeft = LockDesktop.timeLeft - 1;
	if(LockDesktop.timeLeft < 0) then
		timer:Change();
		if(page) then
			page:CloseWindow();
		end
	else
		page:SetValue("timeLeft", tostring(LockDesktop.timeLeft));
		ParaEngine.GetAttributeObject():CallField("BringWindowToTop");
	end
end
