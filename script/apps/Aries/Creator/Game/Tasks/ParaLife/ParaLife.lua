--[[
Title: Paralife main 
Author(s): LiXizhi
Date: 2021/12/31
Desc: ParaLife is a kids movie creator game with simple drag and drop on a touch device. 
It can run directly inside a standard paracraft world with one of following commands:
- "/show paralife" no player, no front page.  
- "/show paralife -showplayer" to show the main player. 
In editor mode, it will show nothing, in game mode, it will show paralife based UI. 
if there is file called "frontpage.png" or "frontpage_32bits.png" or "frontpage.jpg" under world directory, we will use it as login background.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
ParaLife:SetEnabled(true)
-------------------------------------------------------
]]
local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local ParaLife = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife"));
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

ParaLife:Property({"bEnabled", nil, "IsEnabled", "SetEnabled"});
ParaLife:Property({"isShowPlayer", false, "SetShowPlayer", "IsShowPlayer"});

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
	self.desktopMode = mode;
	if(self:IsEnabled()) then
		if(mode == "game") then
			if(not self:IsVisible()) then
				self:Show();
			else
				self:UpdateShowViewStates()
			end
		elseif(mode == "editor") then
			if(self:IsVisible()) then
				self:Hide();
			end
			
		elseif(mode == "movie") then
			if(self:IsVisible()) then
				self:Hide();
			end
		end
	end
	self:RefreshBMaxSelectorBtn()
end

-- only show bmax btn when it is edit mode. 
function ParaLife:RefreshBMaxSelectorBtn()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorButton.lua");
	local ParaLifeBMaxSelectorButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorButton")
	local bShow = self:IsEnabled() and GameLogic.GetGameMode()=="edit"
	ParaLifeBMaxSelectorButton.ShowPage(bShow)
end

-- automatically show or hide according to game mode. 
function ParaLife:SetEnabled(bEnabled)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeHomeButton.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeFrontPage.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTipButton.lua");
	local ParaLifeTipButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTipButton")
	local ParaLifeFrontPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeFrontPage")
	local ParaLifeHomeButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeHomeButton")
	if(bEnabled) then
		self:Init();
		if(GameLogic.IsReadOnly()) then
			if(ParaLifeFrontPage.GetFrontPageImageFilename()) then
				ParaLifeFrontPage.ShowPage(true)
			end
			if(not self.isLogoShown) then
				self.isLogoShown = true
				if(GameLogic.options:GetElapsedWorldTime() < 10000) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeLogo.lua");
					local ParaLifeLogo = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeLogo")
					ParaLifeLogo.ShowPage(true)
				end
			end
		end
		ParaLifeHomeButton.ShowPage(true)
		ParaLifeTipButton.ShowPage(true)
	else
		ParaLifeFrontPage.ShowPage(false)
		ParaLifeHomeButton.ShowPage(false)
		ParaLifeTipButton.ShowPage(false)
	end
	self.bEnabled = bEnabled;

	if(self.visible and not bEnabled) then
		self:Hide();
	elseif(not self.visible and bEnabled) then
		if(not GameLogic.GameMode:IsEditor()) then
			self:Show();
		end
	end

	self:RefreshBMaxSelectorBtn()
end

function ParaLife:IsEnabled()
	return self.bEnabled
end

function ParaLife:SetShowPlayer(bIsShowPlayer)
	self.isShowPlayer = bIsShowPlayer == true;
end

function ParaLife:IsShowPlayer()
	return self.isShowPlayer;
end

function ParaLife:UpdateShowViewStates(isShow)
	GameLogic.RunCommand("/hide quickselectbar")
end

function ParaLife:Show()
	self:Init()
	self.visible = true;
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
	ParalifeLiveModel.ShowView()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
	local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")
	ParaLifeTouchController.ShowPage(true)
	
	if(not self.context) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeContext.lua");
		local ParalifeContext = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeContext")
		self.context = ParalifeContext:new():Register("ParalifeContext");
		self.originalPlayContext = AllContext:GetContext("play")
	end
	AllContext:SetContext("play", self.context)
	
	if(self:IsShowPlayer()) then
		GameLogic.RunCommand("/show player")
		-- GameLogic.RunCommand("/show playertouch")
	else
		GameLogic.RunCommand("/hide player")
	end
	GameLogic.RunCommand("/hide touch")
	GameLogic.RunCommand("/hide keyboard")
	GameLogic.RunCommand("/speedscale 1")
	GameLogic.RunCommand("/clearbag")
	GameLogic.RunCommand("/hide quickselectbar")
	GameLogic.RunCommand("/camera -roomview -restrictDist 6")
	GameLogic.RunCommand("/cameradist 6")
	GameLogic.options:SetEnableMouseLeftDrag(true)
end

function ParaLife:IsVisible()
	return self.visible;
end

function ParaLife:Hide()
	self.visible = false;
	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
    ParalifeLiveModel.ClosePage()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
	local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")
	ParaLifeTouchController.ShowPage(false)

	if(self.desktopMode ~= "movie") then
		if(self.originalPlayContext) then
			AllContext:SetContext("play", self.originalPlayContext)
		end
		-- GameLogic.RunCommand("/hide playertouch")
		GameLogic.RunCommand("/show player")
		GameLogic.RunCommand("/show quickselectbar")
		GameLogic.RunCommand("/camera")
		if(GameLogic.options:HasTouchDevice()) then
			GameLogic.RunCommand("/show touch")
			GameLogic.RunCommand("/show keyboard")
		else
			GameLogic.options:SetEnableMouseLeftDrag(false)
		end
	end
end

ParaLife:InitSingleton()