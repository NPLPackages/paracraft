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
LockDesktop.IsLocked()
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
	duration = duration or 10;
	if(duration == 0) then
		LockDesktop.DoUnlock();
		return;
	end
	if(GameLogic.IsServerWorld()) then
		if(bShow) then
			LockDesktop.isLocked = true;
		end
		if(text and text~="") then
			GameLogic.AddBBS("LockDesktop", text, math.floor(duration*1000), "255 0 0");
		end
		return
	end
	LockDesktop.duration = duration;
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

-- call this every 1 secs
function LockDesktop.DoLock()
	if(not LockDesktop.isLocked) then
		LockDesktop.isLocked = true;
		if(GameLogic.IsRemoteWorld()) then
			ParaScene.GetAttributeObject():SetField("BlockInput", true);
			ParaCamera.GetAttributeObject():SetField("BlockInput", true);
		end
	end
	if(GameLogic.IsRemoteWorld()) then
		ParaEngine.GetAttributeObject():CallField("BringWindowToTop");
	end
	if(page) then
		page:SetValue("timeLeft", tostring(LockDesktop.timeLeft));
	end
end

function LockDesktop.IsLocked()
	return LockDesktop.isLocked;
end

function LockDesktop.DoUnlock()
	LockDesktop.isLocked = false;
	ParaScene.GetAttributeObject():SetField("BlockInput", false);
	ParaCamera.GetAttributeObject():SetField("BlockInput", false);
	if(page) then
		page:CloseWindow();
		page = nil;
	end
	GameLogic.AddBBS("LockDesktop", nil, 0, "255 0 0");
	if(LockDesktop.timer) then
		LockDesktop.timer:Change();
	end
end

function LockDesktop.OnTimer(timer)
	LockDesktop.timeLeft = LockDesktop.timeLeft - 1;
	if(LockDesktop.timeLeft < 0) then
		LockDesktop.DoUnlock()
	else
		LockDesktop.DoLock()
	end
end
