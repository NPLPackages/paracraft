--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local MiniGameDailyRecommend = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameDailyRecommend.lua")
        MiniGameDailyRecommend.ShowRecommend()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=ms_games_list&%s=true",env)
local games = "games=%s,%s,%s"

local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGameDailyRecommend = NPL.export()

function MiniGameDailyRecommend.ShowRecommend()
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    MiniGameMgr:LoadTodayGameConfig(function(gameData)
        local gameConfig = gameData
        if gameConfig and gameConfig.selectedGames then
            local gameList = gameConfig.selectedGames
            local gameStr = ""
            if gameList and gameList[1] then
                gameStr = string.format(games,gameList[1].title,gameList[2].title,gameList[3].title)
            end
            local url = base_url .. "&" .. gameStr .. "&userId=" .. userId
            MiniGamePage.OpenBrowser(url,function()
                
            end)
        end
    end)
end

function MiniGameDailyRecommend.CloseRecommend()
    MiniGamePage.ClosePage()
end