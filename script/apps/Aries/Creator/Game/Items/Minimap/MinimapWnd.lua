--[[
Title: minimap UI window
Author(s): LiXizhi
Date: 2015/5/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Minimap/MinimapWnd.lua");
local MinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap.MinimapWnd");
MinimapWnd:Show();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Minimap/MinimapSurface.lua");
local MinimapSurface = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap.MinimapSurface");
local Window = commonlib.gettable("System.Windows.Window");
local MinimapWnd = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Items.ItemMinimap.MinimapWnd"));

function MinimapWnd:Show()
	if(not self.window) then
		local window = Window:new();
		window:EnableSelfPaint(true);
		window:SetAutoClearBackground(false);
		self.window = window;
	end
	
	self.window:Show({
		name="MinimapWnd", 
		url="script/apps/Aries/Creator/Game/Items/Minimap/MinimapWnd.html",
		alignment="_ct", left=-256, top=-256, width = 512, height = 512,
	});
end