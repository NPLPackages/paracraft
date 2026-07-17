--[[
    author(s): pbb
    date: 2024/01/08
    uselib:
        local UpdatePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdate/UpdatePage.lua");
        UpdatePage.ShowPage(latestVer,curVer,gamename,OnClickUpdate,allowSkip)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local UpdatePage = NPL.export()
local edu_url = {
    ONLINE = "official/docs/changelog/palakaedu",
    STAGE = "deng123457/docs/changelog/palakaedu",
    RELEASE = ""
}
    
local plaka_url = {
    ONLINE = "official/docs/changelog/paracraft",
    STAGE = "deng123457/docs/changelog/paracraft",
    RELEASE = ""
}

local default_notice = [[
    【零基础可学】自研的方块建模以及图形化编程，通过寓教于乐的教学方式，满足零基础孩子学习。<br/>
    【3D沉浸式学习体验】通过提供一种自由探索的生态环境，让孩子通过主动的探究，进行自主式学习。<br/>
    【动画+编程的有机结合】注重设计创造和构思的动画电影，和逻辑思维的抽象化构建理性的编程。<br/>
    【丰富的PBL项目式学习】项目式教学，让孩子在项目学习中提升问题解决力和创新思考力。<br/>
]]

local page
function UpdatePage:OnInit()
    page = document:GetPageCtrl();
end

function UpdatePage.ShowPage(latestVer,curVer,gamename,OnClickUpdate,allowSkip,bShow)
    if page then
        page:CloseWindow()
        page = nil
    end
    MainLogin:CheckMoreProcess(function(result,processData)
        if latestVer == nil or curVer == nil or gamename == nil then
            GameLogic.AddBBS(nil, L"更新失败了，数据异常") -- 本地版本文件不存在了
            LOG.std(nil,"info","UpdatePage","latestVer or curVer or gamename is nil")
            return
        end
        if result then
            UpdatePage.OnClickUpdate = OnClickUpdate
            local bAllowSkip = allowSkip == true
            allowSkip = tostring(bAllowSkip)
            local view_width = 0
            local view_height = 0
            local params = {
                url = format("script/apps/Aries/Creator/Game/Login/ClientUpdate/UpdatePage.html?latestVersion=%s&curVersion=%s&curGame=%s&allowSkip=%s", latestVer,curVer, gamename,allowSkip), 
                name = "UpdatePage.ShowPage", 
                isShowTitleBar = false,
                DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
                style = CommonCtrl.WindowFrame.ContainerStyle,
                zorder = 10000,
                enable_esc_key = true,
                allowDrag = false,
                isTopLevel = true,
                directPosition = true,
                    align = "_fi",
                    x = -view_width/2,
                    y = -view_height/2,
                    width = view_width,
                    height = view_height,
            }

            if not bAllowSkip then
                if UpdatePage.OnClickUpdate and type(UpdatePage.OnClickUpdate) == "function" then
                    UpdatePage.OnClickUpdate()
                end
                return 
            end
            if bShow then
                System.App.Commands.Call("File.MCMLWindowFrame",params)
            end
        else
            local appName = L"帕拉卡社区版"
            if System.options.channelId_431 then
                appName = L"智慧教育客户端"
            end
            if System.options.isShenzhenAi5 then
                appName = L"深教AI4客户端"
            end
			_guihelper.MessageBox(L"更新失败了，"..appName..L"开了多个窗口了，请关闭其他窗口后再试。(如果正在编辑世界，请保存)");
        end
    end)
end

function UpdatePage.RefreshPage()
    if page then
        page:Refresh(0.1)
    end
end

function UpdatePage.GetNotice()
    if not UpdatePage.change_log_str then
        NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
        local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
        local update_url = System.options.isEducatePlatform and edu_url or plaka_url
        local env = HttpWrapper.GetDevVersion()
        local url = update_url[env]
        if url and url ~= "" then
            KeepWork.GetRawFileByPath(url, function(err, msg, data)
                if err == 200 then
                    UpdatePage.change_log_str = data
                    UpdatePage.RefreshPage()
                end
            end, "access plus 10 seconds")
        end
    end
    return UpdatePage.change_log_str or default_notice
end

