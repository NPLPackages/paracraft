--[[
    author(s): pbb
    date: 2024/01/08
    uselib:
        local UpdateResultDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ClientUpdate/UpdateResultDialog.lua");
        UpdateResultDialog.ShowPage(type,callback)
]]

local UpdateResultDialog = NPL.export()
local page
function UpdateResultDialog:OnInit()
    page = document:GetPageCtrl();
end

function UpdateResultDialog.ShowPage(pagetype,callback)
    UpdateResultDialog.OnClose()
    UpdateResultDialog.page_type = pagetype
    UpdateResultDialog.callback = callback
    local view_width = 0
    local view_height = 0
    local params = {
        url = format("script/apps/Aries/Creator/Game/Login/ClientUpdate/UpdateResultDialog.html"), 
        name = "UpdateResultDialog.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = zorder or 10000,
        enable_esc_key = pagetype ~= "success",
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

function UpdateResultDialog.OnClickRestart()
	if UpdateResultDialog.callback and type(UpdateResultDialog.callback) == "function" then
		UpdateResultDialog.callback()
	end
    UpdateResultDialog.OnClose()
end

--重新走更新流程
function UpdateResultDialog.OnClickRetry()
    UpdateResultDialog.OnClose()
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:set_step({IsLoginModeSelected = true})
    MyCompany.Aries.Game.MainLogin:next_step({IsUpdaterStarted = false})
end

function UpdateResultDialog.OnClickOpen()
    UpdateResultDialog.OnClose()
    ParaGlobal.ShellExecute("open","https://palaka.cn/download", "", "", 1)
end

function UpdateResultDialog.OnClose()
    if(page) then
        page:CloseWindow()
        page = nil
    end
end

