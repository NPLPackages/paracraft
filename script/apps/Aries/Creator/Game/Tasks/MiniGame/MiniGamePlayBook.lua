--[[
    author: copilot
    date: 2026-01-05
    useLib: 
        local MiniGamePlayBook = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePlayBook.lua")
        MiniGamePlayBook.ShowPlayBook()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
-- https://keepwork.com/api/raw/maisi/maisi/webgames/playbook/playbook.html
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/playbook&gameName=playbook.html&%s=true",env)

local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGamePlayBook = NPL.export()

function MiniGamePlayBook.ShowPlayBook()
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    local url = base_url .. "&userId=" .. userId
    local token = Mod.WorldShare.Store:Get('user/token') or ""
    if token ~= "" then
        url = url .. "&token=" .. token
    end
    MiniGamePage.OpenBrowser(url,function()
        
    end)
end

function MiniGamePlayBook.ClosePlayBook()
    MiniGamePage.ClosePage()
end
