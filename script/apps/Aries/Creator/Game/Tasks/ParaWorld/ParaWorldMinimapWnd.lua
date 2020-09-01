--[[
Title: minimap UI window
Author(s): LiXizhi
Date: 2020/8/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
ParaWorldMinimapWnd:Show();
ParaWorldMinimapWnd:Close();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local Window = commonlib.gettable("System.Windows.Window");
local ParaWorldMinimapWnd = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd"));

function ParaWorldMinimapWnd:Show()
	if(not self.window) then
		local window = Window:new();
		window:EnableSelfPaint(true);
		window:SetAutoClearBackground(false);
		self.window = window;

		self.window2 = Window:new();
	end

	self.window:Show({
		name="ParaWorldMinimapWnd", 
		url="script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.html?isSurface=true",
		alignment="_rt", left=-202, top=10, width = 192, height = 220, zorder = -12
	});

	self.window2:Show({
		name="ParaWorldMinimapWnd2", 
		url="script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.html?isSurface=false",
		alignment="_rt", left=-202, top=10, width = 192, height = 220, zorder = -11
	});
end


function ParaWorldMinimapWnd.CloseWindow()
	local self = ParaWorldMinimapWnd
	if(self.window) then
		self.window:CloseWindow(true)
		self.window = nil;

		self.window2:CloseWindow(true)
		self.window2 = nil;
	end
end

function ParaWorldMinimapWnd:Close()
	ParaWorldMinimapWnd.CloseWindow()
end

function ParaWorldMinimapWnd.GetWorldName()
    return WorldCommon.GetWorldTag("name");
end