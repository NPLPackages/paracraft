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
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SceneViewport.lua");
local SceneViewport = commonlib.gettable("MyCompany.Aries.Game.Common.SceneViewport")
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
	GameLogic:Connect("WorldLoaded", DesktopMenuPage, DesktopMenuPage.OnWorldLoaded, "UniqueConnection");
	GameLogic:Connect("WorldUnloaded", DesktopMenuPage, DesktopMenuPage.OnWorldUnloaded, "UniqueConnection");
end

function DesktopMenuPage.OnWorldUnloaded()
	DesktopMenuPage.ActivateMenu(false,true);
end

function DesktopMenuPage.GetProjectText()
    if(GameLogic.options:GetProjectId()) then
        return format(L"项目ID:%s", tostring(GameLogic.options:GetProjectId()));
    else
        return L"上传世界";
    end
end

function DesktopMenuPage.OnClickProjectId()
	if(GameLogic.options:GetProjectId()) then
		local url = format("https://keepwork.com/pbl/project/%s", tostring(GameLogic.options:GetProjectId()))
		if(url) then
			GameLogic.GetFilters():apply_filters('open_keepwork_url', url)
		end
	else
		GameLogic.RunCommand("/file.uploadworld")
	end
end

function DesktopMenuPage.OnWorldLoaded()
	if(page) then
		page:SetValue("projectId", DesktopMenuPage.GetProjectText())
	end
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

	NPL.load("(gl)script/ide/System/Windows/Screen.lua");
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local Screen = commonlib.gettable("System.Windows.Screen");
	local viewport = ViewportManager:GetSceneViewport();
	if(DesktopMenuPage.IsPinned) then
		local height = 32;
		SceneViewport.SetVirtualMarginTop(0)
		if(viewport:GetMarginTopHandler() == nil) then
			viewport:SetTop(math.floor(32 * (Screen:GetUIScaling()[2])));
			viewport:SetMarginTopHandler(DesktopMenuPage);
		end
	else
		viewport:SetTop(0);
		if(viewport:GetMarginTopHandler() == DesktopMenuPage) then
			viewport:SetMarginTopHandler(nil);
		end
	end

	if(not DesktopMenuPage.IsPinned) then
		DesktopMenuPage.ActivateMenu(false);
	end
end

-- inventory and esc key will activate/deactivate the menu. 
function DesktopMenuPage.ActivateMenu(bActivate,bForce)
	if(bActivate == nil) then
		bActivate = not DesktopMenuPage.IsActivated;
	end
	DesktopMenuPage.IsActivated = bActivate;
	if(bActivate) then
		-- GameLogic.GetFilters():apply_filters("user_event_stat", "inventory", "browse", nil, nil);

		if(not page or not page:IsVisible()) then
			DesktopMenuPage.ShowPage(true);
		end
		SceneViewport.SetVirtualMarginTop(32)
	else
		if(not DesktopMenuPage.IsPinned or bForce) then
			if(page and page:IsVisible()) then
				DesktopMenuPage.ShowPage(false);
			end
			SceneViewport.SetVirtualMarginTop(0)
		end
	end
end

-- show/hide
function DesktopMenuPage.ShowPage(bShow)

	if GameLogic.GetFilters():apply_filters("DesktopMenuPage.ShowPage", false, bShow) then
		return;
	end

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
