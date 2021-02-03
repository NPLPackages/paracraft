--[[
Title: minimap UI window
Author(s): 
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/QRCodeWnd.lua");
local QRCodeWnd = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.MacroCodeCamp.QRCodeWnd");
QRCodeWnd:Show();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Window = commonlib.gettable("System.Windows.Window");
local QRCodeWnd = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.MacroCodeCamp.QRCodeWnd"))

function QRCodeWnd:Show(parent)
	local width = 192;
	local height = 192;
	if(not self.window) then
		local window = Window:new();
		window:EnableSelfPaint(true);
		self.window = window;
	end
	
	self.window:Show({
		name="QRCodeWnd", 
		url="script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/QRCodeWnd.html",
		alignment="_ct", left=-112, top=-126, width = width, height = height, zorder = 3,
		parent = parent,
	});
end

function QRCodeWnd:Hide()
	if self.window then
		self.window:CloseWindow(true);
		self.window = nil
	end	
end
