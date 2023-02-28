--[[
Title: Paralife startup logo
Author(s): LiXizhi
Date: 2022/2/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeLogo.lua");
local ParaLifeLogo = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeLogo")
ParaLifeLogo.ShowPage(true)
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeLogo = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeLogo")

local page;
local self = ParaLifeLogo;
function ParaLifeLogo.OnInit()
	page = document:GetPageCtrl();
	local canvas = page:FindControl("ParaLifeLogoCanvas")
	if(canvas) then
		canvas:PlayMovieFile("script/apps/Aries/Creator/Game/Tasks/ParaLife/ParacraftLogoAnim.blocks.xml")
	end
	commonlib.TimerManager.SetTimeout(function()  
		ParaLifeLogo.OnClickClose()
	end, 6000)
end

function ParaLifeLogo.OnClickClose()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

function ParaLifeLogo.ShowPage(bShow)
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeLogo.html", 
			name = "ParaLifeLogo.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow~=false,
			cancelShowAnimation = true,
			zorder = 101,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
