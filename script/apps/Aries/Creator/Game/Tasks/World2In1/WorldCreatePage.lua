--[[
Title: WorldCreatePage
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
local WorldCreatePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.lua")
WorldCreatePage.Show();
--]]
local WorldCreatePage = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local server_time = 0
local page
function WorldCreatePage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = WorldCreatePage.CloseView
end

function WorldCreatePage.Show()
    WorldCreatePage.FlushProjectList(WorldCreatePage.ShowView)
end

function WorldCreatePage.FlushProjectList(cb)
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    world_id = world_id or 0
    keepwork.world2in1.project_list({
		parentId=world_id,
        ["x-per-page"] = 200,
        ["x-page"] = 1,
    }, function(err, msg, data)
        -- print("iiiiiiiiiiiiiiiiiiiiiiii", err)
        -- echo(data, true)
        if err == 200 then
            WorldCreatePage.WorldListData = data.rows
            -- WorldCreatePage.WorldListData = {}
            for index, v in ipairs(WorldCreatePage.WorldListData) do
                v.limit_name = WorldCreatePage.GetLimitLabel(v.name)
                v.time_desc = WorldCreatePage.GetTimeDesc(v.updatedAt)
            end

            -- for index = 1, 20 do
            --     local tab = commonlib.copy(WorldCreatePage.WorldListData[#WorldCreatePage.WorldListData])
            --     WorldCreatePage.WorldListData[#WorldCreatePage.WorldListData + 1] = tab
            -- end
            if cb then
                cb()
            end
        end
    end)
end

function WorldCreatePage.ShowView()
    if #WorldCreatePage.WorldListData == 0 then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/NotItemPage.lua").Show();
        return
    end

	if not WorldCreatePage.BindFilter then
		GameLogic.GetFilters():add_filter("became_vip", function()
            if page then
                WorldCreatePage.HandleData()
                page:Refresh(0)
            end
        end);
		WorldCreatePage.BindFilter = true
	end

    if page and page:IsVisible() then
        return
    end
    WorldCreatePage.HandleData()
    
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/WorldCreatePage.html",
        name = "WorldCreatePage.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,
        
        align = "_ct",
        x = -754/2,
        y = -573/2,
        width = 754,
        height = 573,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function WorldCreatePage.FreshView()
    -- local parent  = page:GetParentUIObject()
end

function WorldCreatePage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
    WorldCreatePage.FreshView()
end

function WorldCreatePage.CloseView()
    WorldCreatePage.ClearData()
end

function WorldCreatePage.Close()
    if page then
        page:CloseWindow()
        WorldCreatePage.CloseView()
    end
end

function WorldCreatePage.ClearData()
    WorldCreatePage.WorldListData = nil
    World2In1.SetEnterCreateRegionCb(nil)
end

function WorldCreatePage.HandleData()
end

function WorldCreatePage.OnClickCreate()
    if #WorldCreatePage.WorldListData > 0 and not GameLogic.IsVip() then
        GameLogic.IsVip("world2In1_create_mini", true, function(result)
            if result then
                --Page:Refresh(0)
            end
        end);       
        return
    end

    if page then
        page:CloseWindow()
        WorldCreatePage.CloseView()
    end
    local world_id = WorldCommon.GetWorldTag("kpProjectId");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/CreateModulPage.lua").Show(nil, world_id, function()
        WorldCreatePage.Show();
    end);
end

function WorldCreatePage.SetWorldListData(data)
    WorldCreatePage.WorldListData = data
end

function WorldCreatePage.OnClickSelect(index)
    if WorldCreatePage.WorldListData == nil then
        return
    end
    if WorldCreatePage.InGetServerData then
        return
    end

    WorldCreatePage.InGetServerData = true
    local world_data = WorldCreatePage.WorldListData[index]
    if world_data then
        keepwork.world2in1.select_project({
            projectId = world_data.id
        }, function(err, msg, data)
            WorldCreatePage.InGetServerData = false
            if err == 200 then
                local enter_create_region_cb = World2In1.GetEnterCreateRegionCb()
                if page then
                    page:CloseWindow(0)
                    WorldCreatePage.CloseView()
                end
                local name = world_data.name
                World2In1.SetCreatorWorldName(name)
                
                local parentId = world_data.parentId
                local cur_world_id = WorldCommon.GetWorldTag("kpProjectId");
                if enter_create_region_cb then
                    World2In1.SetEnterCreateRegionCb(enter_create_region_cb)
                end
                if parentId ~= cur_world_id then
                    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
                    CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_data.id))
                else
                    CommandManager:RunCommand(format([[/createworld -name "%s" -parentProjectId %d -update]], name, parentId))
                end
            end
        end)
    end
end

function WorldCreatePage.GetDesc1()
    -- body
    local world_name = WorldCommon.GetWorldTag("name")
    
    return string.format("请选择你要入驻至《%s》课程世界的迷你地块", world_name)
end

function WorldCreatePage.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 17;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function WorldCreatePage.GetTimeDesc(updatedAt)
	local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(updatedAt)
	local date_desc = os.date("%Y-%m-%d", time_stamp)
	local time_desc = os.date("%H:%M", time_stamp)
	local desc = string.format("%s %s", date_desc, time_desc)
    return desc
end

function WorldCreatePage.OnClickDelete(index)
    if WorldCreatePage.project_file_path == nil then
        WorldCreatePage.project_file_path = ParaIO.GetWritablePath() .. "worlds/DesignHouse/"
    end

    local world_data = WorldCreatePage.WorldListData[index]
    if world_data == nil or world_data.name == nil then
        return
    end

    local project_name = world_data.name or ""
    project_name = commonlib.Encoding.Utf8ToDefault(project_name)
    local worldpath = WorldCreatePage.project_file_path .. project_name
    _guihelper.MessageBox(string.format("是否要删除《%s》迷你地块", world_data.name), function()	
        KeepworkServiceProject:RemoveProject(
            world_data.id,
            function(data, err)
                if err == 200 then
                    if ParaIO.DoesFileExist(worldpath, true) then
                        commonlib.Files.DeleteFolder(worldpath)
                    end

                    WorldCreatePage.FlushProjectList(function()
                        -- World2In1.UnLoadcurrentWorldListByName(project_name)
                        WorldCreatePage.OnRefresh()
                    end)
                end
            end
        )
    end)
end

function WorldCreatePage.JoinVip()
    GameLogic.IsVip("world2In1_create_mini", true, function(result)
        if result then
            --page:Refresh(0)
        end
    end);       
end