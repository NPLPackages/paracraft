--[[
Title: Act51AskName
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskName.lua").Show();
--]]
local Act51AskName = NPL.export();


Act51AskName.Data = {{}}
local page
function Act51AskName.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Act51AskName.CloseView
end

function Act51AskName.Show()
    Act51AskName.ShowView()
end

function Act51AskName.ShowView()
    if page and page:IsVisible() then
        return
    end
    Act51AskName.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskName.html",
        name = "Act51AskName.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -960/2,
        y = -640/2,
        width = 960,
        height = 640,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Act51AskName.FreshView()
    local parent  = page:GetParentUIObject()
end

function Act51AskName.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Act51AskName.FreshView()
end

function Act51AskName.CloseView()
    Act51AskName.ClearData()
end

function Act51AskName.ClearData()
end

function Act51AskName.HandleData()
end