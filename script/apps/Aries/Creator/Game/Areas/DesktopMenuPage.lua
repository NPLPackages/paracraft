--[[
Title: System menu page
Author(s): LiPeng, LiXizhi
Date: 2014/11/13
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
DesktopMenuPage.ActivateMenu(true);
DesktopMenuPage.ShowPage(true);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu");
local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");

local page;
-- whether the menu is pinned to the desktop. 
DesktopMenuPage.IsPinned = false;

function DesktopMenuPage.OnInit()
	page = document:GetPageCtrl();
	DesktopMenu.Init();
	GameLogic.GetEvents():AddEventListener("game_mode_change", DesktopMenuPage.OnGameModeChanged, DesktopMenuPage, "DesktopMenuPage");
end

function DesktopMenuPage.OnGameModeChanged()
	DesktopMenuPage.Refresh();
end

function DesktopMenuPage.Refresh(nTime)
	if(page) then
		page:Refresh(nTime or 0.1);
	end
end

function DesktopMenuPage.GetCurrentMenu()
	return DesktopMenu.GetCurrentMenu();
end

function DesktopMenuPage.OnClickToggleGameMode()
	if(GameLogic.ToggleGameMode()) then
		DesktopMenuPage.Refresh();
	end
end

function DesktopMenuPage.TogglePinned()
	DesktopMenuPage.IsPinned = not DesktopMenuPage.IsPinned;
	DesktopMenuPage.Refresh();
	if(not DesktopMenuPage.IsPinned) then
		DesktopMenuPage.ActivateMenu(false);
	end
end

-- inventory and esc key will activate/deactivate the menu. 
function DesktopMenuPage.ActivateMenu(bActivate)
	if(bActivate == nil) then
		bActivate = not DesktopMenuPage.IsActivated;
	end
	DesktopMenuPage.IsActivated = bActivate;
	if(bActivate) then
		if(not page or not page:IsVisible()) then
			DesktopMenuPage.ShowPage(true);
		end
	else
		if(not DesktopMenuPage.IsPinned) then
			if(page and page:IsVisible()) then
				DesktopMenuPage.ShowPage(false);
			end
		end
	end
end

-- show/hide
function DesktopMenuPage.ShowPage(bShow)
	if(System.options.IsMobilePlatform) then
		return
	end
	if(bShow and not DesktopMenuPage.IsActivated) then
		return;
	end
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.html", 
			name = "DesktopMenuPage.ShowDesktopMenuPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			zorder = 1,
			click_through = true,
			directPosition = true,
				align = "_mt",
				x = 0,
				y = 0,
				width = 0,
				height = 70,
		});
	GameLogic.GetEvents():DispatchEvent({type = "DesktopMenuShow" , bShow = bShow,});	
end
