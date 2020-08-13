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
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local Window = commonlib.gettable("System.Windows.Window");
local ParaWorldMinimapWnd = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd"));

function ParaWorldMinimapWnd:Show()
	if(not self.window) then
		local window = Window:new();
		window:EnableSelfPaint(true);
		window:SetAutoClearBackground(false);
		self.window = window;
	end
	
	self.window:Show({
		name="ParaWorldMinimapWnd", 
		url="script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.html",
		alignment="_rt", left=-210, top=10, width = 200, height = 200, zorder = -12
	});
end

function ParaWorldMinimapWnd:Close()
	if(self.window) then
		self.window:CloseWindow(true)
		self.window = nil;
	end
end
