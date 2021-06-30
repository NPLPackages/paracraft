--[[
Title: Act51AskDress
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskDress.lua").Show();
--]]
local Act51AskDress = NPL.export();

local page
function Act51AskDress.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Act51AskDress.CloseView
end

function Act51AskDress.Show()
    Act51AskDress.ShowView()
end

function Act51AskDress.ShowView()
    if page and page:IsVisible() then
        return
    end
    Act51AskDress.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskDress.html",
        name = "Act51AskDress.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -953/2,
        y = -448/2,
        width = 953,
        height = 448,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Act51AskDress.FreshView()
    local parent  = page:GetParentUIObject()
end

function Act51AskDress.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Act51AskDress.FreshView()
end

function Act51AskDress.CloseView()
    Act51AskDress.ClearData()
end

function Act51AskDress.ClearData()
end

function Act51AskDress.HandleData()
end