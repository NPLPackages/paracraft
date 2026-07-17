--[[
    author(s): pbb
    date: 2024/01/08
    uselib:
        local DownLoadPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdate/DownLoadPage.lua");
        DownLoadPage.ShowPage(url,zorder)
]]

local DownLoadPage = NPL.export()
local page
function DownLoadPage:OnInit()
    page = document:GetPageCtrl();
end

function DownLoadPage.ShowPage(url,zorder)
    DownLoadPage.OnClose()
    local view_width = 0
    local view_height = 0
    local params = {
        url = format("script/apps/Aries/Creator/Game/Login/ClientUpdate/DownLoadPage.html"), 
        name = "DownLoadPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or 10000,
        enable_esc_key = false,
        allowDrag = false,
        isTopLevel = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    }
    System.App.Commands.Call("File.MCMLWindowFrame",params)
end

function DownLoadPage.UpdateProgress(text,percent)
	if(page) then
        local percent = percent or 0
		page:SetValue("progressText", tostring(percent).."%" or "")
        page:SetValue("update_progressbar", percent or 0)
        page:SetValue("progressSpeedText",text or "")
	end
end

function DownLoadPage.OnClose()
    if(page) then
        page:CloseWindow()
        page = nil
    end
end

