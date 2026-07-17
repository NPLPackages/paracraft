--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local MiniGameBeanHelp = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameBeanHelp.lua")
        MiniGameBeanHelp.ShowBeanHelp()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local env

local base_url = "https://keepwork.com/api/raw/maisi/maisi/webgames/data/msplanet_coin_guide"


local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGameBeanHelp = NPL.export()

function MiniGameBeanHelp.ShowBeanHelp()
    local url = base_url
    MiniGamePage.OpenBrowser(url,function() end)
end

function MiniGameBeanHelp.CloseBeanHelp()
    MiniGamePage.ClosePage()
end