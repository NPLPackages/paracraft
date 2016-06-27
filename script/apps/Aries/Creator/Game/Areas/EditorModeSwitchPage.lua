--[[
Title: DEPRECATED: game mode switch (new implementation in system menu)
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EditorModeSwitchPage.lua");
local EditorModeSwitchPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EditorModeSwitchPage");
EditorModeSwitchPage.ShowPage(true)
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local EditorModeSwitchPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EditorModeSwitchPage");

local page;
function EditorModeSwitchPage.OnInit()
	page = document:GetPageCtrl();
	EditorModeSwitchPage.UpdateModeUI();

	GameLogic.GetEvents():AddEventListener("game_mode_change", EditorModeSwitchPage.OnGameModeChanged, EditorModeSwitchPage, "EditorModeSwitchPage");
end

function EditorModeSwitchPage.ShowPage(bShow)
	if(System.options.IsMobilePlatform) then
		return;
	end
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/EditorModeSwitchPage.html", 
			name = "EditorModeSwitchPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			zorder = 0,
			click_through = true,
			cancelShowAnimation = true,
			directPosition = true,
				align = "_ctr",
				x = 0,
				y = 0,
				width = 32,
				height = 80,
		});
end

function EditorModeSwitchPage.OnClickUpload()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
	local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
	WorldUploadPage.ShowPage();
end

function EditorModeSwitchPage.OnClickChangeMode()
	Desktop.OnActivateDesktop();
end

function EditorModeSwitchPage.OnGameModeChanged()
	EditorModeSwitchPage.UpdateModeUI();
end

function EditorModeSwitchPage.UpdateModeUI()
	if(page) then
		local mode = GameLogic.GetMode();
		if( mode == "game") then
			local btn = page:FindControl("gamemode");
			if(btn) then
				btn.background = "Texture/player/play.png";
			end
			page:SetValue("gamemode", "游戏模式");

			-- hide save button in game mode. 
			local btn = page:FindControl("save");
			if(btn) then
				btn.visible = false;
			end
		elseif( mode == "editor") then
			local btn = page:FindControl("gamemode");
			if(btn) then
				btn.background = "Texture/player/pause.png";
			end
			page:SetValue("gamemode", "创作模式");

			-- show save button in game mode. 
			local btn = page:FindControl("save");
			if(btn) then
				btn.visible = true;
			end
		end
	end
end

function EditorModeSwitchPage.OnClickSave()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/SaveWorldPage.lua");
	local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SaveWorldPage");
	SaveWorldPage.ShowPage()
end
