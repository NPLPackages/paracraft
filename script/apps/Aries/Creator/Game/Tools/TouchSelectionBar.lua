--[[
Title: Touch selections
Author(s): LiXizhi
Date: 2014/9/30
Desc: manages all blocks being selected in the touch controller. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelectionBar.lua");
local TouchSelectionBar = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelectionBar");
TouchSelectionBar:InitSingleton();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
NPL.load("(gl)script/ide/System/Core/Action.lua");
local Action = commonlib.gettable("System.Core.Action");
local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TouchSelectionBar = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelectionBar"));

TouchSelectionBar:Property("Name", "TouchSelectionBar");
TouchSelectionBar:Property("Visible", false, "IsVisible");

TouchSelectionBar:Signal("EditSelection", function() end);
TouchSelectionBar:Signal("ExtrudeSelection", function(dx, dy, dz) end);
TouchSelectionBar:Signal("DeleteSelection", function() end);

function TouchSelectionBar:ctor()
	-- TODO: replace this with Action objects in future. 
	self.Connect(self, "EditSelection", TouchSelection, TouchSelection.EditSelection);
	self.Connect(self, "ExtrudeSelection", TouchSelection, TouchSelection.ExtrudeSelection);
	self.Connect(self, "DeleteSelection", TouchSelection, TouchSelection.DeleteAllBlocks);
end

function TouchSelectionBar:OnInit()
	self.page = document:GetPageCtrl();
end

-- slot:
-- @param nCount: number of objects currently being selected. 
function TouchSelectionBar:OnSelectionChanged(nCount)
	if(not nCount or nCount == 0) then
		if(self:IsVisible()) then
			self:HidePage();
		end
	else
		if(not self:IsVisible()) then
			self:ShowPage();
		end
	end
end

function TouchSelectionBar:ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Tools/TouchSelectionBar.html", 
		name = "SelectBlocks.ShowMobilePage", 
		isShowTitleBar = false,
		DestroyOnClose = false,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		zorder = -1,
		click_through = true,
		directPosition = true,
			align = "_rt",
			x = -95,
			y = 87,
			width = 95,
			height = 300,
	});
	self:SetVisible(true);
end

function TouchSelectionBar:HidePage()
	if(self.page) then
		self.page:CloseWindow();
	end
	self:SetVisible(false);
end
