--[[
    author: pbb
    date: 2025-04-08
    useLib: 
        local MiniGameSummary = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSummary.lua")
        MiniGameSummary.ShowPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")  
 
local MiniGameSummary = NPL.export()

function MiniGameSummary.ShowPage()

end