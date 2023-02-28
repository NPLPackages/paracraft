--[[
Title: Paralife Home Button
Author(s): LiXizhi
Date: 2022/2/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTipButton.lua");
local ParaLifeTipButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTipButton")
ParaLifeTipButton.ShowPage(true)
------------------------------------------------------------
]]
local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeTipButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTipButton")
local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")

local page;
local self = ParaLifeTipButton;
function ParaLifeTipButton.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeTipButton, ParaLifeTipButton.OnWorldUnload, "UniqueConnection");
	ParalifeLiveModel.ClosePage()
end

function ParaLifeTipButton.ShowPage(bShow)
	if(not page and bShow==false) then
		return
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTipButton.html", 
			name = "ParaLifeTipButton.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow~=false,
			click_through = true, 
			cancelShowAnimation = true,
			directPosition = true,
				align = "_lt",
				x = ParaLife:IsNoBackBtn() and 50 or 145,
				y = 15,
				zorder = 0,
				width = 80,
				height = 80,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ParaLifeTipButton.OnClosed;
end

function ParaLifeTipButton.OnClosed()
	page = nil
end

function ParaLifeTipButton.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function ParaLifeTipButton.OnClickHome()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBook.lua");
	local ParaLifeBook = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBook")
	ParaLifeBook.ShowPage(true)
end

function ParaLifeTipButton.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParaLifeTipButton, ParaLifeTipButton.OnWorldUnload);
	ParaLifeTipButton.ShowPage(false)
end

function ParaLifeTipButton.SetIcon(iconPath)
	if page then
		local btnTip = page:FindControl("btn_paratip")
		if btnTip and btnTip:IsValid() then
			
		end
	end
end