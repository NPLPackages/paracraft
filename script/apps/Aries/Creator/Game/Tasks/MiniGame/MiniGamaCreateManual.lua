--[[
    author: pbb
    date: 2025-10-21
    useLib: 
        local MiniGamaCreateManual = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamaCreateManual.lua")
        MiniGamaCreateManual.ShowCreateManual()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=my_skill_books_dev&%s=true",env)

local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGamaCreateManual = NPL.export()

function MiniGamaCreateManual.ShowCreateManual()
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    local url = base_url .. "&userId=" .. userId
    local token = Mod.WorldShare.Store:Get('user/token') or ""
    if token ~= "" then
        url = url .. "&token=" .. token
    end
    MiniGamePage.OpenBrowser(url,function()
        
    end)
end

function MiniGamaCreateManual.CloseCreateManual()
    MiniGamePage.ClosePage()
end