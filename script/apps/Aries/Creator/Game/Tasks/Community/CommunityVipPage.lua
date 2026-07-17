--[[
    author: pbb
    date: 2024-04-12
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipPage.lua")
        local CommunityVipPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityVipPage")
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityAPI.lua");
local CommunityAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityAPI");
local CommunityVipPage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Creator.Game.Tasks.Community.CommunityVipPage"))

NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");

CommunityVipPage.default_window_name = "NplBrowserWindow_Instance";
CommunityVipPage.default_url = "www.keepwork.com";
CommunityVipPage.browser_name = "community_nplbrowser_instance"
function CommunityVipPage:Init()
    self.curBrowserName = ""
    self.pageCtrl  = nil
end

function CommunityVipPage:InitUI()
    self.pageCtrl = document:GetPageCtrl()
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function CommunityVipPage:OnWorldUnloaded()
end

function CommunityVipPage:Show(name, url,callback)
    self:Init()
    url = url or self.default_url;
    name = name or self.default_window_name;

    self.name = name;
    self.url = url;
    self.withControl = false;
    self.callback = callback;
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipPage.html", 
        name = "CommunityVipPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 100,
        directPosition = true,
        click_through = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        -- DesignResolutionWidth = 1280,
        -- DesignResolutionHeight = 720,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);
    System.Windows.Screen:Connect("sizeChanged", self, self.OnResize, "UniqueConnection");
    GameLogic.GetFilters():add_filter("nplbrowser_checked", self.OnResize);
end

local function GetTruePixel(px)
    if (System.os.GetPlatform() == "win32" or
        System.os.GetPlatform() == "ios" or
        System.os.GetPlatform() == "mac" or
        System.os.GetPlatform() == "android") then
        local uiScales = System.Windows.Screen:GetUIScaling(true);

        if (uiScales[1] ~= 1 or uiScales[2] ~= 1) then
            px = math.floor(px * uiScales[1]);
        end

        return px;
    else
        return px;
    end
end

function CommunityVipPage:CloseWindow()
    if self.pageCtrl then
        self.pageCtrl:CloseWindow(true);
        self.pageCtrl = nil;
    end
end

function CommunityVipPage.OnResize()
    if (CommunityVipPage.pageCtrl) then
        BackgroundMusic:Silence()
        local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
        local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
        NplBrowserPlugin.ChangePosSize({
            id = CommunityVipPage.browser_name,
            x = 0,
            y = 0,
            width = screenWidth,
            height = screenHeight,
        });
    end
end

function CommunityVipPage:GotoUrl(name,url,callback)
    if System.options.isHideVip then
        CommunityVipPage.ShowHideVipPage()
        return
    end
    self:RegisterEvent();
    self.url = url;
    self:Show(name, url, callback);
    CommunityAPI:Init(self.browser_name);
end

function CommunityVipPage.ShowHideVipPage()
    local view_width, view_height = 0,0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/CommunityVipEmptyPage.html",
        name = "CommunityVipEmptyPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder=11,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CommunityVipPage:OpenUrl(url)
    if self.pageCtrl then
        self.url = url;
        self.pageCtrl:CallMethod(self.browser_name, "Reload", self.url)
    end
end

function CommunityVipPage:GotoEmpty()
    if self.pageCtrl then
        self.pageCtrl:CallMethod(self.browser_name, "Reload", NplBrowserPlugin.about_blank_url);
    end
end

function CommunityVipPage:OpenBrowser(name,url,callback)
    if (System.options.enable_npl_brower and not NplBrowserLoaderPage.IsLoaded() and not System.os.IsWindowsXP()) then
		if (not CommunityVipPage.isLoading) then
			CommunityVipPage.isLoading = true;
			NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
			local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
            NplBrowserLoaderPage.Check(function(bLoaded)
				if (bLoaded) then
                    self:GotoUrl(name,url,callback)
                else
                    _guihelper.MessageBox(L"加载内置浏览器失败，请重启！");
				    CommunityVipPage.isLoading = false
				end
			end)
		else
			_guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		end

		return;
    end

    self:GotoUrl(name,url,callback)
end

function CommunityVipPage:RegisterEvent()
    if self.register then
        return
    end

    self.register = true;
    
    CommunityAPI:Connect("displayModeChanged", self, self.OnDisplayModeChange, "UniqueConnection");
end

function CommunityVipPage:OnDisplayModeChange(mode)
    if mode == "hide" then
        self:CloseWindow()
    end
end

function CommunityVipPage:Goto(url)
    if(not name)then
        return
    end
    self.url = url
    self:Reload(self.url)
end


function CommunityVipPage:Reload(url)
    url = url or self.url
    if(self.pageCtrl)then
        self.pageCtrl:CallMethod(self.browser_name, "Reload", url); 
    end
    self.url = url
end

-- 初始化成单列模式
CommunityVipPage:InitSingleton();