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
local server_time = 0
local page

local show_all_mini_project_world = {
    [72945] = 1,
    [73156] = 1,
    [20690] = 1,
}
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
            if show_all_mini_project_world[world_id] then
                keepwork.world2in1.all_mini_projects({}, function(err2, msg2, data2)
                    if err == 200 then
                        local rows = data2.list and data2.list.rows or {}
                        if rows and #rows > 0 then
                            for index, v in ipairs(rows) do
                                data.rows[#data.rows + 1] = v
                            end
                        end
                    end

                    WorldCreatePage.WorldListData = {}
                    -- WorldCreatePage.WorldListData = {}
                    for index, v in ipairs(data.rows) do
                        v.limit_name = WorldCreatePage.GetLimitLabel(v.name, 13)
                        v.time_desc = WorldCreatePage.GetTimeDesc(v.updatedAt)
    
                        if not string.find(v.name, "_study") then
                            WorldCreatePage.WorldListData[#WorldCreatePage.WorldListData + 1] = v
                        end
                    end
        
                    if cb then
                        cb()
                    end
                end)
            else
                WorldCreatePage.WorldListData = {}
                -- WorldCreatePage.WorldListData = {}
                for index, v in ipairs(data.rows) do
                    v.limit_name = WorldCreatePage.GetLimitLabel(v.name, 13)
                    v.time_desc = WorldCreatePage.GetTimeDesc(v.updatedAt)

                    if not string.find(v.name, "_study") then
                        WorldCreatePage.WorldListData[#WorldCreatePage.WorldListData + 1] = v
                    end
                end
    
                if cb then
                    cb()
                end
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
                
                local parentId = world_data.parentId or 0

                local cur_world_id = WorldCommon.GetWorldTag("kpProjectId");
                if enter_create_region_cb then
                    World2In1.SetEnterCreateRegionCb(enter_create_region_cb)
                end
                if parentId ~= 0 and parentId ~= cur_world_id then
                    local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
                    CommandManager:RunCommand(string.format('/loadworld -force -s %s', world_data.id))
                else
                    parentId = parentId == 0 and cur_world_id or parentId
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
        WorldCreatePage.ShowDeleteAuth(function(pwd)
            if type(pwd) == "string" and pwd ~= "" then
                GameLogic.GetFilters():apply_filters("service.keepwork_service_project.remove_project",world_data.kpProjectId,pwd,function(data,err)
                    if err == 200 then
                        if ParaIO.DoesFileExist(worldpath, true) then
                            commonlib.Files.DeleteFolder(worldpath)
                        end
                        WorldCreatePage.FlushProjectList(function()
                            WorldCreatePage.OnRefresh()
                        end)
                    end
                end);
            end
        end)

        
    end)
end

function WorldCreatePage.ShowDeleteAuth(callback)
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/PasswordAuthOnDeletion.html",
        name = "WorldCreatePage.ShowDeleteAuth", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 0,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.callback = callback
end

function WorldCreatePage.JoinVip()
    GameLogic.IsVip("world2In1_create_mini", true, function(result)
        if result then
            --page:Refresh(0)
        end
    end);       
end