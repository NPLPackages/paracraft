--[[
Title: Paralife main 
Author(s): LiXizhi
Date: 2021/12/31
Desc: ParaLife is a kids movie creator game. 
It can run directly inside a standard paracraft world with `/show paralife` command. 
In editor mode, it will show nothing, in game mode, it will show paralife based UI. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
ParaLife:SetEnabled(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local ParaLife = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife"));

ParaLife:Property({"bEnabled", nil, "IsEnabled", "SetEnabled"});

function ParaLife:ctor()
end

function ParaLife:Init()
	if(self.isInited) then
		return
	end
	self.isInited = true

	GameLogic.GetFilters():add_filter("DesktopModeChanged", function(mode)
		return self:OnChangeDesktopMode(mode);
	end);
end

-- virtual: called when a desktop mode is changed such as from game mode to edit mode. 
-- return true to prevent further processing.
function ParaLife:OnChangeDesktopMode(mode)
	if(self:IsEnabled()) then
		if(mode == "game") then
			if(not self:IsVisible()) then
				self:Show();
			end
		elseif(mode == "editor") then
			if(self:IsVisible()) then
				self:Hide();
			end
		end
	end
end

-- automatically show or hide according to game mode. 
function ParaLife:SetEnabled(bEnabled)
	if(bEnabled) then
		self:Init();
	end
	self.bEnabled = bEnabled;
	if(self.visible and not bEnabled) then
		self:Hide();
	elseif(not self.visible and bEnabled) then
		if(not GameLogic.GameMode:IsEditor()) then
			self:Show();
		end
	end
end

function ParaLife:IsEnabled()
	return self.bEnabled
end

function ParaLife:Show()
	self:Init()
	self.visible = true;
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
    ParalifeLiveModel.ShowView()

	if(not self.context) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeContext.lua");
		local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
		self.context = ParalifeContext:new():Register("ParalifeContext");
		self.originalPlayContext = AllContext:GetContext("play")
	end
	AllContext:SetContext("play", self.context)
	GameLogic.RunCommand("/show playertouch")
	GameLogic.RunCommand("/hide player")
	GameLogic.RunCommand("/speedscale 1")
	GameLogic.RunCommand("/clearbag")
	GameLogic.RunCommand("/hide quickselectbar")
	GameLogic.RunCommand("/camera -roomview")
	GameLogic.RunCommand("/cameradist 8")
end

function ParaLife:IsVisible()
	return self.visible;
end

function ParaLife:Hide()
	self.visible = false;
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
    ParalifeLiveModel.ClosePage()

	if(self.originalPlayContext) then
		AllContext:SetContext("play", self.originalPlayContext)
	end
	GameLogic.RunCommand("/hide playertouch")
	GameLogic.RunCommand("/show player")
	GameLogic.RunCommand("/show quickselectbar")
	GameLogic.RunCommand("/camera")
end

ParaLife:InitSingleton()