--[[
Title: YellowCodeLimitPage
Author(s): hyz
Date: 2022/6/7
Desc:  黄码用户阻断弹窗
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/YellowCodeLimitPage.lua");
local YellowCodeLimitPage = commonlib.gettable("MyCompany.Aries.Game.YellowCodeLimitPage");
YellowCodeLimitPage.ShowPage("2023-10-30T06:52:43.000Z")
YellowCodeLimitPage.CheckShow()
--]]

local YellowCodeLimitPage = commonlib.gettable("MyCompany.Aries.Game.YellowCodeLimitPage");
local page;

function YellowCodeLimitPage.OnInit()
	page = document:GetPageCtrl();
    page.OnClose = YellowCodeLimitPage.OnClosed;
    page.OnCreate = YellowCodeLimitPage.OnCreated;
end

function YellowCodeLimitPage.OnCreated()
    
end

function YellowCodeLimitPage.OnClosed()
    page = nil 
end

function YellowCodeLimitPage.OnBecomeVip()
    YellowCodeLimitPage.ClosePage()
end

function YellowCodeLimitPage.CheckShow()
    if System.options.isEducatePlatform or System.options.isPapaAdventure then --智慧教育版，屏蔽黄码弹窗
        return
    end
    GameLogic.IsVip("SkipYellowCode",true,function(result)
        if not result then
            keepwork.checkYellowCodeLimit({},function(err, msg, data)           
                print("err",err)
                if(err ~= 200)then
                    return
                end
        
                local data = data.data
                if data and data.limit then
                    YellowCodeLimitPage.ShowPage(data.deadline)
                end
            end)
        end
    end)
end

function YellowCodeLimitPage.CheckShowImpl()

end

function YellowCodeLimitPage.ShowPage(deadline)
    if System.options.isEducatePlatform or System.options.isPapaAdventure or System.options.channelId_tutorial then --智慧教育版，屏蔽黄码弹窗
        return
    end
    YellowCodeLimitPage.deadlineStramp = commonlib.timehelp.GetTimeStampByDateTime(deadline)
    YellowCodeLimitPage.deadlineDesc = os.date("%Y-%m-%d %H:%M",YellowCodeLimitPage.deadlineStramp)

    local params = {
        url = "script/apps/Aries/Creator/Game/Login/YellowCodeLimitPage.html", 
        name = "YellowCodeLimitPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        -- enable_esc_key = false,
        bShow = true,
        click_through = false, 
        zorder = 10000,
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -700/2,
            y = -392/2,
            width = 700,
            height = 392,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    GameLogic.GetFilters():remove_filter("became_vip", YellowCodeLimitPage.OnBecomeVip);
    GameLogic.GetFilters():add_filter("became_vip", YellowCodeLimitPage.OnBecomeVip);

end

function YellowCodeLimitPage.OnClickExchange()
    local VipCodeExchange = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VipToolTip/VipCodeExchange.lua") 
    VipCodeExchange.ShowView()
end

function YellowCodeLimitPage.ClosePage()
    if page then
        page:CloseWindow()
    end
end

function YellowCodeLimitPage.OnExit()
    local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
    KeepworkServiceSession:Logout(nil, function()
        ParaGlobal.ExitApp();
        ParaGlobal.ExitApp();
    end)
end