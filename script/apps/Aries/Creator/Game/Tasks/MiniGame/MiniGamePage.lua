--[[
    Author: 	pbb
    Date: 	2025-04-08
    UseLib: 
        local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
        MiniGamePage.OpenBrowser(url)

        -- 使用实例,世界当中
        1.开启网页小游戏
            local game_data ={name="xiaoxiaole",url="https://keepwork.com"}
            broadcast("register_game", game_data) -- 注册小游戏
            broadcast("start_game", game_data) -- 开启小游戏
        2.开始结算
            broadcast("wanxue_submit_score", {game_id="xiaoxiaole07", score=80, difficulty = 0.6})
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserFrame = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserFrame.lua");
local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")
local MiniGamePage = NPL.export()
local brower_name = "minigame_nplbrowser_instance"
local pageCtrl = nil
MiniGamePage.isShowCloseBtn = true

function MiniGamePage.OnInit()
    pageCtrl = document:GetPageCtrl()
    pageCtrl.OnCreate = MiniGamePage.OnCreate
end

function MiniGamePage.IsTimeLimited()
    return TimeLimitPage.IsTimeLimited()
end

function MiniGamePage.ShowTimeLimitPage()
    TimeLimitPage.ShowTimeLimit()
end

function MiniGamePage.ShowPage(url)
    if not url or url == "" then
        return
    end
    MiniGamePage.isShowCloseBtn = true
    local isFirstParam = url:find("?") == nil
    local userToken = Mod.WorldShare.Store:Get("user/token")
    if userToken and userToken ~= "" then
        if isFirstParam then
            url = url .. "?"
        else
            url = url .. "&"
        end
        url = url .. "token=" .. userToken
    end
    MiniGamePage.url = url
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.html", 
        name = "MiniGamePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        enable_esc_key = false,
        --isTopLevel = true, -- make sure the page is on the top level, so that it can show on top of other top level windows.
        bShow = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        cancelShowAnimation = true,
        zorder = 100,
        directPosition = true,
        -- click_through = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
    }

    System.App.Commands.Call("File.MCMLWindowFrame", params);
    System.Windows.Screen:Connect("sizeChanged", MiniGamePage, MiniGamePage.OnResize, "UniqueConnection");
    GameLogic.GetFilters():add_filter("nplbrowser_checked", MiniGamePage.OnResize);
    
    
    MiniGamePage.IsOpenBrowser = false
    MiniGamePage.ShowBrowserPage()
    commonlib.TimerManager.SetTimeout(function()
        MiniGamePage.OnResize()
    end,100)
end

function MiniGamePage.RefreshPage()
    if pageCtrl then
        pageCtrl:Refresh(0.01);
    end
end

function MiniGamePage.IsVisible()
    return pageCtrl and pageCtrl:IsVisible()
end

function MiniGamePage.ShowBrowserPage()
    local x_pos, y_pos, width, height = MiniGamePage.GetBrowserParams()
    MiniGamePage.PauseScene()
    if (System.os.GetPlatform() == "ios") then
        MiniGamePage.url = MiniGamePage.url .. "&orientation=landscape"
    end
    NPLJS:Open(MiniGamePage.url, function()
        MiniGamePage.IsOpenBrowser = true
        if GameLogic.MiniGameMgr then
            GameLogic.MiniGameMgr:LoadWebviewFinished()
        end
    end, 
    x_pos, y_pos, width, height);
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

function MiniGamePage.ClosePage()
    if MiniGamePage.callback and type(MiniGamePage.callback) == "function" then
        MiniGamePage.callback()
        MiniGamePage.callback = nil
    end
    if pageCtrl then
        pageCtrl:CloseWindow();
        pageCtrl = nil;
        MiniGamePage.isLoading = false
        MiniGamePage.url = nil
    end
    
    GameLogic.MiniGameMgr:CloseWebview()
    MiniGamePage.ResumeScene()
    NPLJS:Close()
end

function MiniGamePage.EnableSlowRendering(bEnable, renderInterval)
    if bEnable then
        renderInterval = renderInterval or 300; -- ms
        -- throttle rendering: only enable once every 300ms, then turn off shortly after
        MiniGamePage._isPausedForMinigame = true;

        local attr = ParaEngine.GetAttributeObject();
        attr:SetField("Enable3DRendering", false);

        -- timer to turn rendering off shortly after a pulse
        if not MiniGamePage._renderOffTimer then
            MiniGamePage._renderOffTimer = commonlib.Timer:new({ callbackFunc = function(timer)
                if MiniGamePage._isPausedForMinigame then
                    attr:SetField("Enable3DRendering", false);
                else
                    timer:Change(); -- stop if no longer paused
                end
            end })
        end

        -- pulse timer: every renderInterval (300ms), briefly enable rendering, then disable after ~10ms
        if not MiniGamePage._renderPulseTimer then
            MiniGamePage._renderPulseTimer = commonlib.Timer:new({ callbackFunc = function(timer)
                if not MiniGamePage._isPausedForMinigame then
                    timer:Change(); -- stop if no longer paused
                    return;
                end
                attr:SetField("Enable3DRendering", true);
                MiniGamePage._renderOffTimer:Change(10, nil); -- disable again shortly after
            end })
        end
        MiniGamePage._renderPulseTimer:Change(0, renderInterval);
    else
        -- stop throttled rendering timers
        MiniGamePage._isPausedForMinigame = false;
        if MiniGamePage._renderPulseTimer then
            MiniGamePage._renderPulseTimer:Change();
            MiniGamePage._renderPulseTimer = nil;
        end
        if MiniGamePage._renderOffTimer then
            MiniGamePage._renderOffTimer:Change();
            MiniGamePage._renderOffTimer = nil;
        end
        ParaEngine.GetAttributeObject():SetField("Enable3DRendering", true);
    end
end

function MiniGamePage.PauseScene()
    NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/ClickToContinue.lua");
    local ClickToContinue = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ClickToContinue");
    ClickToContinue.Stop();
    System.os.options.DisableInput(true);
    ParaScene.EnableScene(false);

    MiniGamePage.EnableSlowRendering(true, 300);
end

function MiniGamePage.ResumeScene()
    NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/ClickToContinue.lua");
    local ClickToContinue = commonlib.gettable("MyCompany.Aries.Desktop.GUIHelper.ClickToContinue");
    ClickToContinue.Resume();

    MiniGamePage.EnableSlowRendering(false); 
    ParaScene.EnableScene(true);
    System.os.options.DisableInput(false);
    GameLogic.RunCommand("/sendevent resume_scene_in_paracraft_world");
end

function MiniGamePage.OnResize()
    if not pageCtrl then
        return
    end
    if not MiniGamePage.ResizePageImp then
        MiniGamePage.ResizePageImp = commonlib.debounce(function()
            MiniGamePage.RefreshPage()
            local x_pos, y_pos, width, height = MiniGamePage.GetBrowserParams()
            local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
            local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
            NPLJS:SetSize(x_pos, y_pos, width, height, true)
        end, 60)
    end
    MiniGamePage.ResizePageImp()
end

function MiniGamePage.GetBrowserParams()
    local screenWidth = GetTruePixel(System.Windows.Screen:GetWidth());
    local screenHeight = GetTruePixel(System.Windows.Screen:GetHeight());
    local scale = screenWidth/1280
    local width =  1216 * scale
    return 0, 0, width, screenHeight
end

function MiniGamePage.GotoEmpty()
    if pageCtrl then
        pageCtrl:CallMethod(brower_name, "Reload", NplBrowserPlugin.about_blank_url);
    end
end

function MiniGamePage.GotoUrl(url,closeCallback)
    MiniGamePage.callback = closeCallback
    MiniGamePage.ShowPage(url)
end

function MiniGamePage.OpenBrowser(url,callback)
    if (System.options.enable_npl_brower and not NplBrowserLoaderPage.IsLoaded() and not System.os.IsWindowsXP()) then
		if (not MiniGamePage.isLoading) then
			MiniGamePage.isLoading = true;
            NplBrowserLoaderPage.Check(function(bLoaded)
				if (bLoaded) then
                    MiniGamePage.GotoUrl(url,callback)
                else
                    _guihelper.MessageBox(L"加载内置浏览器失败，请重启！");
				    MiniGamePage.isLoading = false
				end
			end)
		else
			_guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		end
		return;
    end

    MiniGamePage.GotoUrl(url,callback)
end

function MiniGamePage.RefreshCloseBtn(bShow)
    if not pageCtrl then
        return
    end
    MiniGamePage.isShowCloseBtn = bShow == true
    local btnClose = ParaUI.GetUIObject("btn_close_minigame")
    local btnClose1 = ParaUI.GetUIObject("btn_close_minigame1")
    if btnClose and btnClose:IsValid() then
        btnClose.visible = MiniGamePage.isShowCloseBtn
    end
    if btnClose1 and btnClose1:IsValid() then
        btnClose1.visible = MiniGamePage.isShowCloseBtn
    end
end

function MiniGamePage.OnCreate()
    if not pageCtrl then
        return
    end
    if System.os.IsMobilePlatform() then
        -- make sure the close button is not too close to the screen top edge on mobile devices
        local btnClose = ParaUI.GetUIObject("btn_close_minigame")
        local btnClose1 = ParaUI.GetUIObject("btn_close_minigame1")
        if btnClose and btnClose:IsValid() then
            local posY = btnClose.y
            btnClose.y = posY + 28
        end
        if btnClose1 and btnClose1:IsValid() then
            local posY = btnClose1.y
            btnClose1.y = posY + 28
        end
    end
    
end

function MiniGamePage.OnRecvMessage(msg)
    if msg and msg.type == "setMiniGameBackgroundColor" then
        if msg.color and msg.color ~= "" then
            local obj = ParaUI.GetUIObject("minigame_container")
            if obj and obj:IsValid() then
                _guihelper.SetUIColor(obj, msg.color)
            end
        end
    end
end