--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local MiniGameVip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameVip.lua")
        MiniGameVip.ShowVipPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGameVip = NPL.export()
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
function MiniGameVip.ShowVipPage()
    GameLogic.CheckSignedIn(L"请先登录", function(result)
        if result then
            local userId = Mod.WorldShare.Store:Get('user/userId')
            if not userId then
                GameLogic.AddBBS(nil,L"登陆失败，请重试")
                return
            end
            local url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&%s=true&gameName=vip&userId=%s".."&date="..os.time(), env, userId)
            MiniGameVip.ShowBrowserPage(url)
        end
    end)
end

function MiniGameVip.CloseVipPage()
    MiniGamePage.ClosePage()
end

function MiniGameVip.ShowBrowserPage(url)
    MiniGamePage.OpenBrowser(url,function()
        MiniGameVip.CloseBrowserPage()
    end);
end

function MiniGameVip.CloseBrowserPage()
    local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
    KeepWorkItemManager.LoadProfile(true)
    MiniGameMgr:LoadUserInfo()
end