
--[[
Title: Paralife Home Button
Author(s): hyz
Date: 2022/2/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorButton.lua");
local ParaLifeBMaxSelectorButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorButton")
ParaLifeBMaxSelectorButton.ShowPage(true)
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeBMaxSelectorButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorButton")

local page;
local self = ParaLifeBMaxSelectorButton;
function ParaLifeBMaxSelectorButton.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeBMaxSelectorButton, ParaLifeBMaxSelectorButton.OnWorldUnload, "UniqueConnection");
end

function ParaLifeBMaxSelectorButton.ClosePage()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function ParaLifeBMaxSelectorButton.ShowPage(bShow)
	if(not page and bShow==false) then
		ParaLifeBMaxSelectorButton.ClosePage()
		return
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorButton.html", 
			name = "ParaLifeBMaxSelectorButton.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow~=false,
			click_through = true, 
			cancelShowAnimation = true,
			directPosition = true,
			zorder = -13,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeBMaxSelectorButton.OnClickHome()
	local IsDevEnv = false
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBMaxSelectorPage.lua",IsDevEnv);
	local ParaLifeBMaxSelectorPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBMaxSelectorPage")
	ParaLifeBMaxSelectorPage.ShowPage()
end

function ParaLifeBMaxSelectorButton.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParaLifeBMaxSelectorButton, ParaLifeBMaxSelectorButton.OnWorldUnload);
	ParaLifeBMaxSelectorButton.ShowPage(false)
end