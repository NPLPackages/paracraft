--[[
Title: Paralife Home Button
Author(s): LiXizhi
Date: 2022/2/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeHomeButton.lua");
local ParaLifeHomeButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeHomeButton")
ParaLifeHomeButton.ShowPage(true)
------------------------------------------------------------
]]
local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeHomeButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeHomeButton")

local page;
local self = ParaLifeHomeButton;
function ParaLifeHomeButton.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeHomeButton, ParaLifeHomeButton.OnWorldUnload, "UniqueConnection");
	ParalifeLiveModel.ClosePage()
end

function ParaLifeHomeButton.ShowPage(bShow)
	if(not page and bShow==false) then
		return
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeHomeButton.html", 
			name = "ParaLifeHomeButton.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow~=false,
			click_through = false, 
			cancelShowAnimation = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 0,
				width = 130,
				height = 100,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ParaLifeHomeButton.OnClosed;
end

function ParaLifeHomeButton.OnClosed()
	page = nil
end

function ParaLifeHomeButton:RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function ParaLifeHomeButton.OnClickHome()
	if ParalifeLiveModel.IsRecord() then
		_guihelper.MessageBox(L"视频录制中，是否停止",function ()
			ParaLifeHomeButton.ShowFrontPage()
			ParalifeLiveModel.StopRecord()
		end)
		return 
	end
	ParaLifeHomeButton.ShowFrontPage()
end

function ParaLifeHomeButton.ShowFrontPage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeFrontPage.lua");
	local ParaLifeFrontPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeFrontPage")
	ParaLifeFrontPage.ShowPage(true)
end

function ParaLifeHomeButton.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParaLifeHomeButton, ParaLifeHomeButton.OnWorldUnload);
	ParaLifeHomeButton.ShowPage(false)
end