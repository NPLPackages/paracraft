--[[
Title: Act51AskRule
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskRule.lua").Show();
--]]
local Act51AskRule = NPL.export();

local page
function Act51AskRule.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Act51AskRule.CloseView
end

function Act51AskRule.Show()
    Act51AskRule.ShowView()
end

function Act51AskRule.ShowView()
    if page and page:IsVisible() then
        return
    end
    Act51AskRule.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskRule.html",
        name = "Act51AskRule.Show", 
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

function Act51AskRule.FreshView()
    local parent  = page:GetParentUIObject()
end

function Act51AskRule.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Act51AskRule.FreshView()
end

function Act51AskRule.CloseView()
    Act51AskRule.ClearData()
end

function Act51AskRule.ClearData()
end

function Act51AskRule.HandleData()
end