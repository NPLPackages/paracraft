--[[
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.lua");
local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog")
]]

local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog")

local page
function ClientUpdateDialog:OnInit()
    page = document:GetPageCtrl();
end

function ClientUpdateDialog.Show(latestVer,curVer,gamename,OnClickUpdate,allowSkip)
    ClientUpdateDialog.OnClickUpdate = OnClickUpdate
    allowSkip = tostring(not (not allowSkip))
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url = format("script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.html?latestVersion=%s&curVersion=%s&curGame=%s&allowSkip=%s", latestVer,curVer, gamename,allowSkip), 
        name = "ClientUpdateDialog", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 10000,
        allowDrag = false,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -210,
            y = -100,
            width = 420,
            height = 250,
    });
    ClientUpdateDialog._isDownloadFinished = false
end

--下载完成
function ClientUpdateDialog.SetIsDownloadFinished()
    if page then
        ClientUpdateDialog._isDownloadFinished = true
        page:Refresh(0)
    end
end

return ClientUpdateDialog