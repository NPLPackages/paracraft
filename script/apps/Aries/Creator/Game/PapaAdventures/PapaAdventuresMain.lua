--[[
Title: Papa API with external webview
Author(s): PBB, LiXizhi, big
CreateDate: 2023.3.25
ModifyDate: 2023.4.3
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.lua");
local PapaAdventuresMain = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/Lessons/Creation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local Creation = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Lessons.Creation");
local PapaWorldLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/PapaWorldLogic.lua");
local PapaAPI = commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.PapaAPI")
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");
local Encoding = commonlib.gettable("System.Encoding");

local PapaAdventuresMain = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Creator.Game.PapaAdventures.Main"))

PapaAdventuresMain.default_window_name = "NplBrowserWindow_Instance";
PapaAdventuresMain.default_url = "www.keepwork.com";
PapaAdventuresMain.browser_name = "papa_nplbrowser_instance"
function PapaAdventuresMain:Init()
    self.curBrowserName = ""
    self.pageCtrl  = nil
    self.displayMode = nil
end

function PapaAdventuresMain:InitUI()
    self.pageCtrl = document:GetPageCtrl()
    PapaWorldLogic.RegisterEvent()
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function PapaAdventuresMain:OnWorldUnloaded()
    self.displayMode = nil
end

function PapaAdventuresMain:CheckNumber(v)
    if(v == nil)then
        return
    end
    if(type(v) == "string")then
        v = tonumber(v);
    end
    return v;
end

function PapaAdventuresMain:ShowEscPage()
    
end

function PapaAdventuresMain:Show(name, url,callback)
    self:Init()
    url = url or self.default_url;
    name = name or self.default_window_name;

    self.name = name;
    self.url = url;
    self.withControl = false;
    self.callback = callback;

    local params = {
        url = "script/apps/Aries/Creator/Game/PapaAdventures/PapaAdventuresMain.html", 
        name = name, 
        isShowTitleBar = false,
        DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory
        bToggleShowHide = true,
        enable_esc_key = false,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        zorder = 10001,
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
    self.params = params;

    local pageCtrl = params._page;

    if (pageCtrl) then
        self.pageCtrl = pageCtrl;

        pageCtrl.OnClose = function()
            self:SetVisible(false)
        end
    end
    --ParaEngine.GetAttributeObject():SetField("LockWindowSize", true);
    ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", false);
    -- 添加退出应用逻辑
    GameLogic.GetFilters():add_filter("OnCloseAppWindow", function()
        --ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
        PapaAPI:CloseAppWindow()
    end);
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

function PapaAdventuresMain.OnResize()
    if (PapaAdventuresMain.pageCtrl) then
        if (PapaAdventuresMain.displayMode and
            PapaAdventuresMain.displayMode.callback) then
                PapaAdventuresMain.displayMode.callback();
            return;
        end
        BackgroundMusic:Silence()
        PapaAdventuresMain:SetContainerVisible(true)
        local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
        local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
        NplBrowserPlugin.ChangePosSize({
            id = PapaAdventuresMain.browser_name,
            x = 0,
            y = 0,
            width = screenWidth,
            height = screenHeight,
        });
    end
end

function PapaAdventuresMain:GotoUrl(name,url,callback)
    self.url = url;
    self:RegisterEvent();

    self:Show(name, url, callback);

    PapaAPI:Init(self.browser_name);
end

function PapaAdventuresMain:OpenUrl(url)
    if self.pageCtrl then
        self.url = url;
        self.pageCtrl:CallMethod("papa_nplbrowser_instance", "Reload", self.url)
    end
end

function PapaAdventuresMain:OpenBrowser(name,url,callback)
    if (System.options.enable_npl_brower and not NplBrowserLoaderPage.IsLoaded() and not System.os.IsWindowsXP()) then
		if (not PapaAdventuresMain.isLoading) then
			PapaAdventuresMain.isLoading = true;
			NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
			local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
            NplBrowserLoaderPage.Check(function(bLoaded)
				if (bLoaded) then
                    self:GotoUrl(name,url,callback)
                else
                    _guihelper.MessageBox(L"加载内置浏览器失败，请重启！");
				    PapaAdventuresMain.isLoading = false
				end
			end)
		else
			_guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		end

		return;
    end

    self:GotoUrl(name,url,callback)
end

function PapaAdventuresMain:RegisterEvent()
    if self.register then
        return
    end

    self.register = true;
    
    PapaAPI:Connect("displayModeChanged", self, self.OnDisplayModeChange, "UniqueConnection");
    PapaAPI:Connect("onSaveFileChanged", self, self.OnSaveFile, "UniqueConnection");
    GameLogic.GetFilters():add_filter("DesktopModeChanged", function(mode)
        local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
        if not IsMobileUIEnabled then
            self:OnChangeDesktopMode(mode);
        end
        return mode
    end);
end

function PapaAdventuresMain:OnChangeDesktopMode(mode)
    if not self.mode or self.mode ~= "mini" or not mode or mode == "" then
        return
    end
    if mode == "movie" then
        self:HideBrowser(true);
    else
        self:HideBrowser(false);
    end
end

function PapaAdventuresMain:OnDisplayModeChange(mode)
    self.mode = mode
    Creation:ShowInGameButton(false)
    if (mode == "mini") then
        BackgroundMusic:Recover()
        self:HideBrowser(false)
        self.displayMode = {
            mode = "mini",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
                local containerWidth = GetTruePixel(160);
                local containerHeight = GetTruePixel(90);

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = GetTruePixel(28),--screenWidth - containerWidth - GetTruePixel(20),
                    y = screenHeight - containerHeight - GetTruePixel(28),
                    width = containerWidth,
                    height = containerHeight,
                });
                self:SetContainerVisible(false)
            end
        };

        self.displayMode.callback();
    elseif (mode == "ingame") then
        BackgroundMusic:Silence()
        self:HideBrowser(false);
        self.displayMode = {
            mode = "ingame",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = 0,
                    y = 0,
                    width = screenWidth,
                    height = screenHeight,
                });
                self:SetContainerVisible(true)
            end
        };

        self.displayMode.callback();
    elseif (mode == "max") then
        BackgroundMusic:Silence()
        self:HideBrowser(false);
        self.displayMode = {
            mode = "max",
            callback = function()
                local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
                local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
                local containerWidth = GetTruePixel(1155);
                local containerHeight = GetTruePixel(650);

                NplBrowserPlugin.ChangePosSize({
                    id = self.browser_name,
                    x = (screenWidth - containerWidth) / 2,
                    y = (screenHeight - containerHeight) / 2,
                    width = containerWidth,
                    height = containerHeight,
                });
                self:SetContainerVisible(false)
            end
        };

        self.displayMode.callback();
    elseif (mode == "hide") then
        BackgroundMusic:Recover()
        self.displayMode = nil;
        PapaAdventuresMain.OnResize();
        self:HideBrowser(true);
    elseif (mode == "show") then
        BackgroundMusic:Silence()
        self.displayMode = nil;
        PapaAdventuresMain.OnResize();
        self:HideBrowser(false);
    elseif(mode == "button") then
        BackgroundMusic:Recover()
        self.displayMode = nil;
        PapaAdventuresMain.OnResize();
        self:HideBrowser(true);
        Creation:ShowInGameButton(true)
    end
end

function PapaAdventuresMain:SetContainerVisible(bShow)
    local container = ParaUI.GetUIObject("papa_container")
    if container and container:IsValid() then
        container.visible = bShow == true
    end
end

function PapaAdventuresMain:HideBrowser(bHide)
    -- local parent = self.pageCtrl and self.pageCtrl:GetParentUIObject() or nil
    -- if parent then
    --     parent.visble = not bHide
    -- end
    self:SetContainerVisible(not bHide)
    self:SetVisible(not bHide);
end

function PapaAdventuresMain:CloseBrowser()
    if (self.pageCtrl) then
        self.pageCtrl:CloseWindow();
    end

    self:SetVisible(false);
end

function PapaAdventuresMain:GetWebStatus()
    return self.mode or "ingame"
end

function PapaAdventuresMain:Goto(url)
    if(not name)then
        return
    end
    self.url = url
    self:Reload(self.url)
end

function PapaAdventuresMain:Reload(url)
    url = url or self.url
    print("url========",url)
    if(self.pageCtrl)then
        self.pageCtrl:CallMethod(self.browser_name, "Reload", url); 
    end
    self.url = url
end

function PapaAdventuresMain:SetVisible(b)
    if (self.pageCtrl) then
        self.pageCtrl:CallMethod(self.browser_name, "SetVisible", b); 
    end
end

function PapaAdventuresMain:Close()
	self:SetVisible(false)
    if(self.pageCtrl)then
		self.pageCtrl:CloseWindow(); 
    end
    if(self.callback)then
        self.callback();
    end
end

function PapaAdventuresMain:SaveDir()
    if System.os.GetPlatform() == "win32" then
        return ParaIO.GetCurDirectory(13)
    end
    return "temp/"
end

function PapaAdventuresMain:OnSaveFile(msg)
    if (not msg or not msg.base64) then
        return;
    end
    local fileStr = Encoding.unbase64(msg.base64);
    if (not fileStr) then
        return;
    end

    if (System.os.GetPlatform() == "android" or
        System.os.GetPlatform() == "ios") then

        local jsonStr = commonlib.Json.Encode(msg)
        ParaEngine.GetAttributeObject():SetField("SaveImageToGallery", jsonStr);
        return;
    end

    local filepath = "temp.png";
    if (msg.paraFilePath) then
        filepath = commonlib.Encoding.url_decode(msg.paraFilePath);
    end

    filepath = self:SaveDir() .. filepath:match("[^/\\]+$")
    
    if (ParaIO.DoesFileExist(filepath)) then
        ParaIO.DeleteFile(filepath)
    end
    ParaIO.CreateDirectory(filepath);

    local file = ParaIO.open(filepath, "w");

    if (file and file:IsValid()) then
        file:WriteString(fileStr, #fileStr);
        file:close();
    end

    if (msg.isOpenFolder) then
        Map3DSystem.App.Commands.Call(
            'File.WinExplorer',
            {
                filepath = self:SaveDir(),
                silentmode = true
            }
        );
    end
end

-- 初始化成单列模式
PapaAdventuresMain:InitSingleton();