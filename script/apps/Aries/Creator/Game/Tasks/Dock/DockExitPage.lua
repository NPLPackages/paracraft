--[[
    local DockExitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockExitPage.lua")
    DockExitPage.ShowPage()
]]
local DockExitPage = NPL.export()

DockExitPage.callback = nil
local page = nil
function DockExitPage.ShowPage(callback)
    local viewwidth = 270
    local viewheight = 500
    DockExitPage.callback = callback
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Dock/DockExitPage.html",
        name = "DockExitPage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,                
        align = "_ct",
        x = -viewwidth/2,
        y = -viewheight/2,
        width = viewwidth,
        height = viewheight,
    };                
    System.App.Commands.Call("File.MCMLWindowFrame", params)   
end

function DockExitPage.OnInit()
	page = document:GetPageCtrl();
end

function DockExitPage.OnClick(id)
    if id == "server_join" then
        GameLogic.GetFilters():apply_filters('show_server_page')
    elseif id == "plugin" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SelectModulePage.lua");
        local SelectModulePage = commonlib.gettable("MyCompany.Aries.Game.MainLogin.SelectModulePage")
        SelectModulePage.ShowPage()
    elseif id == "system" then
        GameLogic.RunCommand("/menu file.settings");
    elseif id == "service" then
        ParaGlobal.ShellExecute("open", "https://keepwork.com/official/docs/FAQ/questions", "","", 1); 
    elseif id == "exit" then
        if DockExitPage.callback then
            DockExitPage.callback()
        end
        -- GameLogic.RunCommand("/menu file.exit");
    end
end

function DockExitPage.OnClose()
    if page then
        page:CloseWindow()
        DockExitPage.callback = nil
        page = nil
    end
end