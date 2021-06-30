--[[
Title: Act51AskVip
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskVip.lua").Show();
--]]
local Act51AskVip = NPL.export();

local page
function Act51AskVip.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Act51AskVip.CloseView
end

function Act51AskVip.Show()
    Act51AskVip.ShowView()
end

function Act51AskVip.ShowView()
    if page and page:IsVisible() then
        return
    end
    Act51AskVip.HandleData()
    GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.vip.funnel.open1')
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskVip.html",
        name = "Act51AskVip.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -858/2,
        y = -612/2,
        width = 858,
        height = 612,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Act51AskVip.FreshView()
    local parent  = page:GetParentUIObject()
end

function Act51AskVip.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Act51AskVip.FreshView()
end

function Act51AskVip.CloseView()
    Act51AskVip.ClearData()
    if System.User.isVip then
        local vip_gsid = 90006
        local normal_gsid = 90005
    
        local vip_exid = 30036
        local normal_exid = 30035
        local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua")

        if not KeepWorkItemManager.HasGSItem(vip_gsid) then
            KeepWorkItemManager.DoExtendedCost(vip_exid, function()
            end)            
        end
    end
end

function Act51AskVip.ClearData()
end

function Act51AskVip.HandleData()
end