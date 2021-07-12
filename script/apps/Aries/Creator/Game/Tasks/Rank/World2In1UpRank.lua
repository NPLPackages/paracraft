--[[
Title: World2In1UpRank
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/World2In1UpRank.lua").Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local WorldCreatePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua")
local World2In1Rank = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/World2In1Rank.lua")
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local World2In1UpRank = NPL.export();

local server_time = 0
local page
function World2In1UpRank.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = World2In1UpRank.CloseView
end

function World2In1UpRank.Show(data)
    World2In1UpRank.MyProjectData = data
    World2In1UpRank.ShowView()
end

function World2In1UpRank.ShowView()
    if page and page:IsVisible() then
        return
    end
    World2In1UpRank.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/World2In1UpRank.html",
        name = "World2In1UpRank.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -632/2,
        y = -443/2,
        width = 632,
        height = 443,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function World2In1UpRank.FreshView()
    local parent  = page:GetParentUIObject()
end

function World2In1UpRank.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    World2In1UpRank.FreshView()
end

function World2In1UpRank.CloseView()
    World2In1UpRank.ClearData()
end

function World2In1UpRank.ClearData()
end

function World2In1UpRank.HandleData()
end

function World2In1UpRank.GoNow()
    if true then
        _guihelper.MessageBox("7月24号正式开通该功能");
        return
    end

    World2In1UpRank.Close()
    World2In1Rank.Close()
    
    local my_project_data = World2In1UpRank.MyProjectData

    local parent_id = GameLogic.options:GetProjectId() or 0
    keepwork.world2in1.project_list({
        parentId=parent_id,
        ["x-per-page"] = 200,
        ["x-page"] = 1,
    }, function(err, msg, data)
        -- print("iiiiiiiiiiiiiiiiiiiiiiii", err)
        -- echo(data, true)
        if err == 200 then
            WorldCreatePage.SetWorldListData(data.rows)
            if #data.rows == 0 then
                WorldCreatePage.Show()
            else
                -- WorldCreatePage.OnClickSelect(1)
                WorldCreatePage.Show()
                World2In1.SetEnterCreateRegionCb(function()
                    commonlib.TimerManager.SetTimeout(function()  
                        GameLogic.RunCommand("/share")
                    end,500);
                end)
                -- if my_project_data.rank > 200 then
                --     WorldCreatePage.OnClickSelect(1)
                -- else
                --     for k, v in pairs(data.rows) do
                --         if v.id == my_project_data.id then
                --             WorldCreatePage.OnClickSelect(k)
                --             World2In1.SetEnterCreateRegionCb(function()
                --                 commonlib.TimerManager.SetTimeout(function()  
                --                     GameLogic.RunCommand("/share")
                --                 end,1000);
                --             end)
                --         end
                --     end
                -- end
            end
        end
    end)
end

function World2In1UpRank.ToCreate()
    World2In1UpRank.Close()
    World2In1Rank.Close()
    -- GameLogic.GetFilters():apply_filters('show_create_page');
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua").Show();
end

function World2In1UpRank.Close()
    if page and page:IsVisible() then
        page:CloseWindow(0)
        World2In1UpRank.CloseView()
    end
end