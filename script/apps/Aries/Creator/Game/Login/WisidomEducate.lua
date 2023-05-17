--[[
Title: 智慧教育平台
Author(s): pbb
Date: 2023.1.30
use the lib:
------------------------------------------------------------
local WisidomEducate = NPL.load('(gl)script/apps/Aries/Creator/Game/Login/WisidomEducate.lua')
------------------------------------------------------------
]]
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local WisidomEducate = NPL.export()
WisidomEducate.toWorldPath = nil
WisidomEducate.toWorldData = nil
function WisidomEducate.RegisterEvent()
    if not WisidomEducate.IsRegister then
        GameLogic.GetFilters():add_filter("save_world_info",function(ctx, node)
            WisidomEducate.EnterWorld()
            return ctx, node
        end)

        GameLogic.GetFilters():add_filter("SyncWorldFinish",function()
            WisidomEducate.UpdateEduData()
        end)
        WisidomEducate.IsRegister = true
    end
end

function WisidomEducate.SetWorldPath(worldPath)
    WisidomEducate.toWorldPath = worldPath
end

function WisidomEducate.SetWorldData(worldData)
    WisidomEducate.toWorldData = worldData
end

function WisidomEducate.ClearData()
    WisidomEducate.toWorldPath = nil
    WisidomEducate.toWorldData = nil
end

function WisidomEducate.EnterWorld()
    if WisidomEducate.toWorldPath then
        local to_path = WisidomEducate.toWorldPath
        WisidomEducate.toWorldPath = nil
        if to_path then
            GameLogic.RunCommand(string.format('/loadworld %s', to_path))
        end
        WisidomEducate.UpdateWorldTag(to_path)
    end
end

function WisidomEducate.RunEduCommands(cmdLineWorld)
    local preCmd = cmdLineWorld
    cmdLineWorld = cmdLineWorld:gsub("edu_do_works/","")
    if cmdLineWorld:find('single="true"') then
        cmdLineWorld = cmdLineWorld:gsub('single="true"','')
    end
    local jsonStr = commonlib.Encoding.unbase64(cmdLineWorld)
    local workData = commonlib.Json.Decode(jsonStr)
    if type(workData) == "table" then
        WisidomEducate.SetWorldData(workData)
        local createTime = workData.classAt or "2023-01-13T02:21:26.552Z"
        local sectionContentId = workData.sectionContentId or 1
        local fromProjectId = tonumber((workData.forkProjectId or 0)) or 0
        local year, month, day, hour, min, sec = createTime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
        local worldName = year..string.format("%.2d",month)..string.format("%.2d",day).."_"..string.format("%.2d",hour)..string.format("%.2d",min).."_"..string.format("%.2d",sectionContentId)
        if fromProjectId and fromProjectId > 0 then
            ---/createworld -name "默认名字26666" -parentProjectId 0 -update -fork 73304
            --/createworld -name "20230113_0226_01" -parentProjectId 0 -update -fork 21032
            -- /createworld -name "默认名字233" -parentProjectId 0 -update -fork 73304
            local  str = format([[/createworld -name "%s" -parentProjectId %d -update -fork %d]], worldName,0, fromProjectId)
            if System.options.isDevMode then
                print(preCmd)
                print("cmdLineWorld===========",cmdLineWorld)
                echo(workData,true)
                print("world share str======",str)
                print("worldName======",worldName,fromProjectId)
            end
            GameLogic.RunCommand(str)
            local project_file_path
            if GameLogic.GetFilters():apply_filters('is_signed_in') then
                project_file_path = GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path')
            else
                project_file_path = "worlds/DesignHouse"
            end
            local name = commonlib.Encoding.Utf8ToDefault(worldName)
            local world_path = project_file_path .. "/" .. name
            WisidomEducate.SetWorldPath(world_path)
        elseif fromProjectId == 0 then
            WisidomEducate.CreatePlatWorld(worldName)
        end
    end
    System.options.cmdline_world = nil
end

--20230314_1002_876 20230314_1029_876 20230314_1053_876
function WisidomEducate.CreatePlatWorld(worldName)
    if not worldName or worldName == "" then
        return 
    end
    local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
    local project_file_path = "worlds/DesignHouse"
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        project_file_path = GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path')
    end
    local name = commonlib.Encoding.Utf8ToDefault(worldName)
    local world_path = project_file_path .. "/" .. name
    local full_path = ParaIO.GetWritablePath()..world_path
    full_path = string.gsub(full_path, "[/\\%s+]+$", "")
    full_path = string.gsub(full_path, "%s+", "")
    local is_file_exist = ParaIO.DoesFileExist(full_path, true)
    if is_file_exist then
        GameLogic.RunCommand(string.format('/loadworld %s', project_file_path .. "/" .. worldName))
        return
    end
    WisidomEducate.SetWorldPath(world_path)
    local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
    CreateWorld:CreateWorldByName(worldName, "superflat",true)
end

function WisidomEducate.UpdateWorldTag(worldPath)
    commonlib.TimerManager.SetTimeout(function ()
        local tag = LocalService:GetTag(worldPath)
        if not tag and type(tag) ~= 'table' then
            return
        end
        if WisidomEducate.toWorldData then
            tag.classroomId = WisidomEducate.toWorldData.classroomId or ""
            tag.lessonName = WisidomEducate.toWorldData.lessonName or ""
            tag.lessonPackageName = WisidomEducate.toWorldData.lessonPackageName or ""
            tag.materialName = WisidomEducate.toWorldData.materialName or ""
            tag.sectionContentId = WisidomEducate.toWorldData.sectionContentId or ""
            tag.isHomeWorkWorld = false
            LocalService:SetTag(worldPath, tag)
        end
        WisidomEducate.toWorldData = nil
    end,0)
end

function WisidomEducate.UpdateEduData()
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
    local classroomId = tonumber((WorldCommon.GetWorldTag("classroomId") or 0))
    local sectionContentId = tonumber((WorldCommon.GetWorldTag("sectionContentId") or 0))
    local project_id = 0
    local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
    if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
        project_id = world_data.kpProjectId
    end
    if classroomId and classroomId > 0 and sectionContentId and sectionContentId > 0 and project_id and project_id > 0 then
        keepwork.edu.updateSectionContents({
            classroomId = classroomId,
            sectionContentId = sectionContentId,
            status = 1,
            projectId = project_id,
        },function (err, msg, data)
            if System.options.isDevMode then
                print("err==========",err)
                echo(data,true)
            end
        end)
    end
end