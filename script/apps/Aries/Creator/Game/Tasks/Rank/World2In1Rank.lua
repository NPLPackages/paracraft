--[[
Title: World2In1Rank
Author(s): yangguiyi
Date: 2021/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/World2In1Rank.lua").Show();
--]]
local page
local World2In1Rank = NPL.export();
local Rank = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/Rank.lua")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
World2In1Rank.TypeBtData = {
    {type = "all", background="Texture/Aries/Creator/keepwork/rank/zi1_62X15_32bits.png#0 0 78 15"},       
    {type = "school", background="Texture/Aries/Creator/keepwork/rank/zi2_62X15_32bits.png#0 0 78 15"},    
    {type = "grade", background="Texture/Aries/Creator/keepwork/rank/zi3_78X16_32bits.png#0 0 78 15"},    
}

World2In1Rank.RankData = {}
World2In1Rank.MyRankData = {}
function World2In1Rank.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = World2In1Rank.CloseView
end

function World2In1Rank.CloseView()
    -- body
end

function World2In1Rank.Show(parent_id)

    World2In1Rank.parent_id = parent_id or GameLogic.options:GetProjectId()
    
    World2In1Rank.world_name = WorldCommon.GetWorldTag("name")
    World2In1Rank.select_type_index = 1
    World2In1Rank.ShowView()
end

function World2In1Rank.ShowView()
    if page and page:IsVisible() then
        return
    end
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Rank/World2In1Rank.html",
        name = "World2In1Rank.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -812/2,
        y = -613/2,
        width = 812,
        height = 613,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    World2In1Rank.SelectType(World2In1Rank.select_type_index)
end

function World2In1Rank.SelectType(index)
    World2In1Rank.select_type_index = index
    page:Refresh(0)
    local data = World2In1Rank.TypeBtData[index]
    local type = data.type
    World2In1Rank.RankData = {}
    keepwork.rank.world2in1_ranklist({
        type=type,
        parentId = World2In1Rank.parent_id or 0,
        limit = 200,
    },function(err, msg, data)
        -- print("oxxxxxxxxxxxxxxxxxxx", err)
        -- echo(data, true)
        if err == 200 then
            for i, v in ipairs(data.ranks) do
                v.tool_name = v.user.username
                v.username = Rank.GetLimitLabel(v.tool_name)
                if v.tool_name == System.User.username then
                    v.is_my_rank = true
                end
                
                v.score = v.star
                v.tool_projectname = v.name
                v.projectname = Rank.GetLimitLabel(v.name, 22)
                World2In1Rank.RankData[#World2In1Rank.RankData + 1] = v
            end

            -- for index = 2, 6 do
            --     World2In1Rank.RankData[index] = commonlib.copy(World2In1Rank.RankData[1])
            --     World2In1Rank.RankData[index].is_my_rank = false
            -- end

            
            local my_rank = data.selfRank and data.selfRank._rank or 0
            local my_rank_data = World2In1Rank.RankData[my_rank] or {}
            World2In1Rank.MyRankData = {}
            if my_rank > 0  then
                World2In1Rank.MyRankData.rank = my_rank > 0 and my_rank or "-"
                World2In1Rank.MyRankData.tool_name = my_rank_data.tool_name or ""
                World2In1Rank.MyRankData.username = my_rank_data.username or ""
                World2In1Rank.MyRankData.id = my_rank_data.id
                World2In1Rank.MyRankData.score = my_rank_data.score or 0
                World2In1Rank.MyRankData.tool_projectname = my_rank_data.tool_projectname or ""
                World2In1Rank.MyRankData.projectname = my_rank_data.projectname or "-"

                page:Refresh(0)
            else
                local parent_id = GameLogic.options:GetProjectId() or 0
                keepwork.world2in1.project_list({
                    parentId=parent_id,
                    ["x-per-page"] = 200,
                    ["x-page"] = 1,
                }, function(err, msg, data)
                    -- print("iiiiiiiiiiiiiiiiiiiiiiii", err)
                    -- echo(data, true)
                    if err == 200 then
                        if #data.rows == 0 then
                            World2In1Rank.MyRankData.rank = my_rank > 0 and my_rank or "-"
                            World2In1Rank.MyRankData.tool_name = my_rank_data.tool_name or ""
                            World2In1Rank.MyRankData.username = my_rank_data.username or ""
                            World2In1Rank.MyRankData.id = my_rank_data.id
                            World2In1Rank.MyRankData.score = my_rank_data.score or 0
                            World2In1Rank.MyRankData.tool_projectname = my_rank_data.tool_projectname or ""
                            World2In1Rank.MyRankData.projectname = my_rank_data.projectname or "-"
                        else
                            local project_data = data.rows[1]
                            -- WorldCreatePage.OnClickSelect(1)
                            World2In1Rank.MyRankData.rank = 0
                            World2In1Rank.MyRankData.tool_name = System.User.username or ""
                            World2In1Rank.MyRankData.username = Rank.GetLimitLabel(System.User.username)
                            World2In1Rank.MyRankData.id = project_data.id
                            World2In1Rank.MyRankData.score = project_data.star or 0
                            World2In1Rank.MyRankData.tool_projectname = project_data.name or ""
                            World2In1Rank.MyRankData.projectname = Rank.GetLimitLabel(project_data.name , 22) or "-"
                        end

                        page:Refresh(0)
                    end
                end)
            end
        end
    end)
end

function World2In1Rank.GetRecudedNumberDesc(number)
    return Rank.GetRecudedNumberDesc(number)
end

function World2In1Rank.OnClickApply()
    ParaGlobal.ShellExecute("open", "https://keepwork.com/cp/xichuanactivity", "", "", 1); 
end

function World2In1Rank.ShowRankHelp()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Rank/World2In1UpRank.lua").Show(World2In1Rank.MyRankData);
end

function World2In1Rank.ToWorld(index)
    local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");    
    local select_type_data = World2In1Rank.TypeBtData[World2In1Rank.select_type_index]
    local select_rank_data = World2In1Rank.RankData[index]

    World2In1.OnEnterRegionByProjectName(select_type_data.type, select_rank_data.name)
    World2In1Rank.Close()
end

function World2In1Rank.Close()
    if page and page:IsVisible() then
        page:CloseWindow(0)
        World2In1Rank.CloseView()
    end
end