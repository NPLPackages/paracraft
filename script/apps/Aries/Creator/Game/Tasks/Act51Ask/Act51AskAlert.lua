--[[
Title: Act51AskAlert
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskAlert.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Act51AskAlert = NPL.export();

local page
function Act51AskAlert.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = Act51AskAlert.CloseView
end

function Act51AskAlert.GetDesc()
    return Act51AskAlert.desc
end

function Act51AskAlert.Show(desc, callback)
    Act51AskAlert.desc = desc or "恭喜你回答正确本次所有的问题！<br/>奖励将于5月8日通过邮箱公布，请关注邮箱信息哦"
    Act51AskAlert.callback = callback
    Act51AskAlert.ShowView()
end

function Act51AskAlert.ShowView()
    if page and page:IsVisible() then
        return
    end
    Act51AskAlert.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Act51Ask/Act51AskAlert.html",
        name = "Act51AskAlert.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -474/2,
        y = -330/2,
        width = 474,
        height = 330,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Act51AskAlert.FreshView()
    local parent  = page:GetParentUIObject()
end

function Act51AskAlert.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    Act51AskAlert.FreshView()
end

function Act51AskAlert.CloseView()
    Act51AskAlert.ClearData()
end

function Act51AskAlert.ClearData()
end

function Act51AskAlert.HandleData()
end

function Act51AskAlert.OnSure()
    page:CloseWindow(0)
    Act51AskAlert.CloseView()

    if Act51AskAlert.callback then
        Act51AskAlert.callback()
    end
end

function Act51AskAlert.Check51ActState()
    local begain_time_stamp = os.time({year = 2021, month = 4, day = 30, hour=0, min=0, sec=0})
    local end_time_stamp = os.time({year = 2021, month = 5, day = 7, hour=23, min=59, sec=59})
    local cur_time_stamp = GameLogic.QuestAction.GetServerTime()
    if cur_time_stamp > end_time_stamp then
        return "act_end"
    end

    if cur_time_stamp < begain_time_stamp then
        return "act_not_start"
    end

    return "act_going"
end

function Act51AskAlert.CheckGetVipItem()
    if Act51AskAlert.Check51ActState() == "act_going" then
        local vip_gsid = 90006
        local normal_gsid = 90005
    
        local vip_exid = 30036
        local normal_exid = 30035
    
        -- 说明有正确答题过
        if System.User.isVip and KeepWorkItemManager.HasGSItem(normal_gsid) and not KeepWorkItemManager.HasGSItem(vip_gsid) then
            KeepWorkItemManager.DoExtendedCost(vip_exid, function()
            end) 
        end
    end
end