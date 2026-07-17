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

    if System.options.isEducatePlatform then
        local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
        local start_after_seconds = 5*1000
		local elapsed_seconds = 0;
		ClientUpdateDialog.mytimer = ClientUpdateDialog.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
			if(elapsed_seconds < start_after_seconds) then
				BroadcastHelper.PushLabel({id="ClientUpdate", label = format(L"%d秒后开始更新", math.floor((start_after_seconds-elapsed_seconds)/1000)), max_duration=2000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			end
			elapsed_seconds = elapsed_seconds + timer:GetDelta();
			if(elapsed_seconds >= start_after_seconds) then
                timer:Change()
				BroadcastHelper.PushLabel({id="ClientUpdate", label = "", max_duration=0, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
                if ClientUpdateDialog.OnClickUpdate and type(ClientUpdateDialog.OnClickUpdate) == "function" then
                    ClientUpdateDialog.OnClickUpdate()
                end
			end
		end})
		ClientUpdateDialog.mytimer:Change(100, 100);
    end
end

--下载完成
function ClientUpdateDialog.SetIsDownloadFinished()
    if page then
        ClientUpdateDialog._isDownloadFinished = true
        page:Refresh(0)
    end
end

return ClientUpdateDialog