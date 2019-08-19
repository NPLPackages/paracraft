--[[
Title: OnlineStore
Author(s): LiXizhi
Date: 2019/8/13
Desc: online store at: https://keepwork.com/p/comp/system?port=8099

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/OnlineStore/OnlineStore.lua");
local OnlineStore = commonlib.gettable("MyCompany.Aries.Game.Tasks.OnlineStore");
local task = OnlineStore:new():Init();
task:Run();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local OnlineStore = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.OnlineStore"));

-- this is always a top level task. 
OnlineStore.is_top_level = true;
OnlineStore.portNumber = "8099"
function OnlineStore:ctor()
end

function OnlineStore:Init()
	return self;
end

function OnlineStore.GetOnlineStoreUrl()
	return format("https://keepwork.com/p/comp/system?port=%s", tostring(OnlineStore.portNumber or 8099));
end

local page;
function OnlineStore.InitPage(Page)
	page = Page;
end

-- get current instance
function OnlineStore.GetInstance()
	return curInstance;
end

function OnlineStore:RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function OnlineStore:Run()
	self.finished = true;
	self:ShowPage(true);
end


function OnlineStore:ShowPage(bShow)
	if(false) then
		if(bShow) then
			GameLogic.RunCommand(format("/open -name OnlineStore -title %s -width 1020 -height 680 -alignment _ct %s", L"元件库", OnlineStore.GetOnlineStoreUrl()));
		end
		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
    local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
    NplBrowserLoaderPage.Check()
    if(not NplBrowserLoaderPage.IsLoaded())then
		ParaGlobal.ShellExecute("open", OnlineStore.GetOnlineStoreUrl(), "", "", 1);
		return
	end

	-- use mcml window
	if(not page) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
		local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
		local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
			if(bStarted) then
				OnlineStore.portNumber = site_url:match("%:(%d+)") or OnlineStore.portNumber;

				GameLogic.GetFilters():add_filter("OnShowEscFrame", OnlineStore.OnShowEscFrame);
				GameLogic.GetFilters():add_filter("ShowExitDialog", OnlineStore.OnClose);
				GameLogic.GetFilters():add_filter("OnInstallModel", OnlineStore.OnClose);

				NPL.load("(gl)script/ide/System/Windows/Screen.lua");
				local Screen = commonlib.gettable("System.Windows.Screen");
				local alignment, x, y, width, height = "_fi", 20, 30, 20, 64;
				if(Screen:GetWidth() >= 1020 and Screen:GetHeight() >= 720) then
					alignment, width, height = "_ct", 1020, 680;
					x, y = -width/2, -height/2;
				end
				local params = {
						url = "script/apps/Aries/Creator/Game/Tasks/OnlineStore/OnlineStore.html", 
						name = "OnlineStore.ShowPage", 
						isShowTitleBar = false,
						DestroyOnClose = true,
						bToggleShowHide=false, 
						style = CommonCtrl.WindowFrame.ContainerStyle,
						allowDrag = true,
						enable_esc_key = true,
						bShow = bShow,
						click_through = false, 
						zorder = 10,
						app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
						directPosition = true,
							align = alignment,
							x = x,
							y = y,
							width = width,
							height = height,
					};
				System.App.Commands.Call("File.MCMLWindowFrame", params);
				if(params._page) then
					params._page.OnClose = function()
						if(page) then
							page:CallMethod("nplbrowser_instance", "SetVisible", false); 
						end
						page = nil;
					end
				end
			end
		end)
	else
		if(bShow == false) then
			page:CloseWindow();
		else
			page:Refresh(0.1);
		end
	end
end

function OnlineStore.OnShowEscFrame(bShow)
	if(bShow ~= false) then
		OnlineStore.OnClose()
	end
end

function OnlineStore.OnClose()
	if(page) then
		page:CloseWindow();
	end
end
