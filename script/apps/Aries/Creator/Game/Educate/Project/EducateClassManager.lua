--[[
    @Author: pbb
    @Date: 2024-03-19
    @Last Modified by:   pbb
    @Use Lib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateClassManager.lua");
        local EducateClassManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager");
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local KpChatChannel = NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua')
local EducateProjectManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateProjectManager.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua")
local EducateClassManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager"));

function EducateClassManager:Init()
    self.isWorldLoaded = false
    self.isSwfpageClosed = false
    EducateProjectManager.Init()
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  EducateClassManager.OnSwfLoadingCloesed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  EducateClassManager.OnSwfLoadingCloesed);

    GameLogic:Disconnect("WorldLoaded", EducateClassManager, EducateClassManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", EducateClassManager, EducateClassManager.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetFilters():add_filter("OnWorldCreate",  function(worldPath)
        self.CurrentCreateWorldName = worldPath
        return worldPath
    end)

    GameLogic.GetFilters():remove_filter("SyncWorldFinish", EducateClassManager.OnSyncWorldFinish);
    GameLogic.GetFilters():add_filter("SyncWorldFinish", EducateClassManager.OnSyncWorldFinish);

    GameLogic.GetEvents():RemoveEventListener("createworld_callback",EducateClassManager.CreateWorldCallback, EducateClassManager, "EducateClassManager")
    GameLogic.GetEvents():AddEventListener("createworld_callback", EducateClassManager.CreateWorldCallback, EducateClassManager, "EducateClassManager");

    GameLogic.GetFilters():add_filter(
        'save_world_info',
        function(ctx, node)
            self:SaveWorldInfo(ctx, node)
            return ctx,node
        end
    )

    GameLogic.GetFilters():add_filter(
        'load_world_info',
        function(ctx, node)
            self:LoadWorldInfo(ctx, node)
            return ctx,node
        end
    )
end

function EducateClassManager:SaveWorldInfo(ctx, node)

end

function EducateClassManager:LoadWorldInfo(ctx, node)

end

function EducateClassManager.SetClassData(class_data)
    EducateClassManager.class_data = class_data
    EducateClassManager:Init()
    
end

function EducateClassManager.JoinClassRoom()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","EducateClassManager","课堂socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__platformClassroom_EDU_"..classId.."__"
            if KpChatChannel.client then
                KpChatChannel.client:Send("app/join",{ rooms = { room }, });
            end
            EducateClassManager.SendJoinRecord()
        end,5*1000)
        return
    end

    local room = "__platformClassroom_EDU_"..classId.."__"
    if KpChatChannel.client then
        KpChatChannel.client:Send("app/join",{ rooms = { room }, });
    end
end 

function EducateClassManager.LeaveClassRoom()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    if not KpChatChannel.client or not KpChatChannel.IsConnected() then
        LOG.std(nil,"info","EducateClassManager","课堂socket网络链接失败")
        KpChatChannel.TryToConnect()
        commonlib.TimerManager.SetTimeout(function()
            local room = "__platformClassroom_EDU_"..classId.."__"
            if KpChatChannel.client then
                KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
            end
        end,5*1000)
        return
    end
    local room = "__platformClassroom_EDU_"..classId.."__"
    if KpChatChannel.client then
        KpChatChannel.client:Send("app/leave",{ rooms = { room }, });
    end
end


function EducateClassManager.SendJoinRecord()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local classId = EducateClassManager.class_data.id or 0
    --上报加入课堂的记录
    keepwork.classrooms.signin({
        classroomId = (data and data.id) and data.id or 0,
    },function(err,msg,data)
        if err == 200 then 
            -- 上报成功，发送socket通知教师端
            commonlib.TimerManager.SetTimeout(function()
                
            end,2*1000)
        end
    end)
end


local EDU_CONFIG = {
    STAGE = "http://edu-dev.kp-para.cn/",
    RELEASE = "http://edu-rls.kp-para.cn/",
    ONLINE = "https://edu.palaka.cn/",
}
function EducateClassManager.OpenClassWeb()
    if not EducateClassManager.class_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
    end
    local userToken = GameLogic.GetFilters():apply_filters("store_get", "user/token")
    userToken = userToken or System.User.keepworktoken
	local http_env = HttpWrapper.GetDevVersion()
    local baseUrl = EDU_CONFIG[http_env]
    local lessonId = EducateClassManager.class_data.lessonId
    local lessonPackageId = EducateClassManager.class_data.lessonPackageId
    local classroomId = EducateClassManager.class_data.id or "0"
    local classroomName = (EducateClassManager.class_data.orgClass and EducateClassManager.class_data.orgClass.name) and EducateClassManager.class_data.orgClass.name or ""
    local openUrl = baseUrl.."?token="..userToken.."&redirect="..Mod.WorldShare.Utils.EncodeURIComponent("/study?lessonId="..lessonId.."&packageId="..lessonPackageId.."&classroomId="..classroomId.."&className="..classroomName)
    if System.options.isShenzhenAi5 then
        openUrl = baseUrl.."ai5?token="..userToken.."&redirect="..Mod.WorldShare.Utils.EncodeURIComponent("/study?lessonId="..lessonId.."&packageId="..lessonPackageId.."&classroomId="..classroomId.."&className="..classroomName)
    end
    if System.os.IsWin32() or System.os.IsEmscripten() then
        GameLogic.RunCommand("/open "..openUrl);
        return
    end
    GameLogic.RunCommand("/open -e "..openUrl)
    
end

--edu web 端
-- command create
function EducateClassManager.CreateWorldCallback(_, event)
    local worldPath = event.world_path
    local paths = commonlib.split(worldPath,"/")
    local worldName = paths[#paths]
    if worldName and worldName ~= "" then
        EducateClassManager.CurrentCreateWorldName = worldName
    end
    GameLogic.RunCommand(string.format('/loadworld %s', worldPath))
end

function EducateClassManager:OnWorldLoaded()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        self.isWorldLoaded = true
        EducateClassManager:CheckEducateStatus()
    end,0)
end

function EducateClassManager.OnSwfLoadingCloesed()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        EducateClassManager.isSwfpageClosed = true
        EducateClassManager:CheckEducateStatus()
        
    end,0)
end

function EducateClassManager.OnSyncWorldFinish()
    EducateClassManager.UpdateEduData()
end

function EducateClassManager:CheckEducateStatus()

end

function EducateClassManager.ClearEducateData()
    EducateClassManager.class_data = nil
    EducateClassManager.educate_data = nil
end

function EducateClassManager.GetWorldName(educate_data,callback)
    local homeworkName = (educate_data.projectName and educate_data.projectName ~= "") and educate_data.projectName or "课堂作业世界"
    local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
    Compare:GetNewWorldName(homeworkName,callback)
end

function EducateClassManager.SetVisibility()
    if not EducateClassManager.educate_data then
        return
    end
    
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end
    local params = {}
    if EducateClassManager.educate_data.isVisibility then
        local value = EducateClassManager.educate_data.isVisibility == 1
        if value then
            params.visibility = 1
        else
            params.visibility = 0
        end
    end
    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, "255 0 0")
        end
        if System.options.isDevMode then
            print("SetVisibility--err==========",err)
            echo(data,true)
        end
    end)
end

function EducateClassManager.SetEducateData(educate_data)
    if not educate_data then
        GameLogic.AddBBS(nil,L"课堂数据为空")
        commonlib.TimerManager.SetTimeout(function()
            System.options.cmdline_world = nil
            Game.MainLogin:next_step({IsLoginModeSelected = false})
        end,1000)
        return
    end
    echo(educate_data,true)
    if educate_data and (educate_data.isSelf == true or educate_data.isSelf == "true") then --加载个人世界
        local project_id = tonumber((educate_data.projectId or 0)) or 0
        local projectName = educate_data.projectName or ""
        if project_id and project_id > 0 and projectName and projectName ~= "" then 
            --加载现有世界
            local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
            LoginModal:CheckSignedIn('请先登录', function(bSucceed)
                KeepworkServiceProject:GetMembers(project_id, function(members, err)
                    if not members or
                       type(members) ~= 'table' or
                       #members == 0 then
                        return
                    end

                    local username = Mod.WorldShare.Store:Get('user/username')
                    local beExist = false

                    for key, item in ipairs(members) do
                        if item and
                           type(item) == 'table' and
                           item.username == username then
                            beExist = true
                        end
                    end

                    if not beExist then --当前用户不在世界的成员列表中
                        GameLogic.RunCommand(string.format("/loadworld -s -auto -lesson %s ", project_id))
                        return
                    end
                    GameLogic.RunCommand(string.format('/loadworld -s -personal %d', project_id))
                end)
            end)
            return
        end
        return
    end

    EducateClassManager.educate_data = educate_data
    

    local createTime = educate_data.classAt or "2023-01-13T02:21:26.552Z"
    local sectionContentId = educate_data.sectionContentId or 1
    local fromProjectId = tonumber((educate_data.forkProjectId or 0)) or 0
    local projectName = educate_data.projectName or ""
    local project_id = tonumber((educate_data.projectId or 0)) or 0
    local year, month, day, hour, min, sec = createTime:match("^(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)") 
    local devStr = year..string.format("%.2d",month)..string.format("%.2d",day).."_"..string.format("%.2d",hour)..string.format("%.2d",min).."_"..string.format("%.2d",sectionContentId)
    print("SetEducateData==================",devStr)
    if project_id and project_id > 0 and projectName and projectName ~= "" then 
        --加载现有世界
        GameLogic.RunCommand(string.format('/loadworld -s -personal %d', project_id))
        return
    end

    EducateClassManager.GetWorldName(educate_data,function(worldName,worldPath,last_world_name)
        GameLogic.GetFilters():add_filter("OnBeforeLoadWorld", EducateClassManager.OnBeforeLoadWorld); 
        if fromProjectId and fromProjectId > 0 then
            EducateClassManager.ForkWorld(worldName,fromProjectId)
        else
            EducateClassManager.CreatePlatWorld(worldName)
        end
    end)
end

function EducateClassManager.GetWorldPath(worldName)
    if not worldName or worldName == "" then
        return ""
    end
    local project_file_path = "worlds/DesignHouse"
    if GameLogic.GetFilters():apply_filters('is_signed_in') then
        project_file_path = GameLogic.GetFilters():apply_filters('service.local_service_world.get_user_folder_path')
    end
    local name = commonlib.Encoding.Utf8ToDefault(worldName)
    local world_path = project_file_path .. "/" .. name
    return world_path
end

function EducateClassManager.ForkWorld(worldName,parentId)
    if not worldName or worldName == "" then
        return 
    end
    local commandStr = string.format('/createworld -name "%s" -parentProjectId %d -update -fork %d -mode admin', worldName,parentId,parentId)
    if System.options.isDevMode then
        print("world share str======",commandStr)
        print("worldName======",worldName,parentId)
    end
    GameLogic.RunCommand(commandStr)
    EducateClassManager.educate_data.worldPath = EducateClassManager.GetWorldPath(worldName) or ""
end

--20230314_1002_876 20230314_1029_876 20230314_1053_876
function EducateClassManager.CreatePlatWorld(worldName)
    if not worldName or worldName == "" then
        return 
    end
    local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
    local world_path = EducateClassManager.GetWorldPath(worldName)
    local full_path = ParaIO.GetWritablePath()..world_path
    full_path = string.gsub(full_path, "[/\\%s+]+$", "")
    full_path = string.gsub(full_path, "%s+", "")
    local is_file_exist = ParaIO.DoesFileExist(full_path, true)
    if is_file_exist then
        GameLogic.RunCommand(string.format('/loadworld %s', world_path))
        return
    end
    EducateClassManager.educate_data.worldPath = world_path
    local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
    CreateWorld:CreateWorldByName(worldName, "superflat",true)
end

function EducateClassManager.OnBeforeLoadWorld()
    EducateClassManager.UpdateWorldTag()
    GameLogic.GetFilters():remove_filter("OnBeforeLoadWorld",EducateClassManager.OnBeforeLoadWorld);
end

function EducateClassManager.UpdateWorldTag()
    if not EducateClassManager.educate_data then
        return
    end
    local worldPath = EducateClassManager.educate_data.worldPath or ""
    local tag = LocalService:GetTag(worldPath)
    if not tag and type(tag) ~= 'table' then
        return
    end
    local data = EducateClassManager.educate_data
    tag.classroomId = data.classroomId or ""
    tag.lessonName = data.lessonName or ""
    tag.lessonPackageName = data.lessonPackageName or ""
    tag.materialName = data.materialName or ""
    tag.sectionContentId = data.sectionContentId or ""
    tag.isHomeWorkWorld = false
    tag.channel = 1
    tag.visibility = 0
    local isVisibility = data.isVisibility or 0
    if isVisibility == 1 then
        tag.hasCopyright = true
        tag.visibility = 1
    end

    

    LocalService:SetTag(worldPath, tag)
end

function EducateClassManager.UpdateEduData()
    local classroomId = tonumber((WorldCommon.GetWorldTag("classroomId") or 0))
    local sectionContentId = tonumber((WorldCommon.GetWorldTag("sectionContentId") or 0))
    local project_id = 0
    local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
    if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
        project_id = world_data.kpProjectId
    end
    if classroomId and classroomId > 0 and sectionContentId and sectionContentId > 0 and project_id and project_id > 0 then
        local params = {
            classroomId = classroomId,
            sectionContentId = sectionContentId,
            status = 1,
            projectId = project_id,
        }
        echo(params,true)
        keepwork.edu.updateSectionContents(params,function (err, msg, data)
            if System.options.isDevMode then
                print("UpdateEduData err==========",err)
                echo(data,true)
            end
        end)
    end
    EducateClassManager.SetVisibility()
    EducateClassManager.SendMsgToJS()
end

function EducateClassManager.SendMsgToJS()
    if (type(System.os.IsEmscripten) == "function" and System.os.IsEmscripten()) then 
        local classroomId = tonumber((WorldCommon.GetWorldTag("classroomId") or 0))
        local sectionContentId = tonumber((WorldCommon.GetWorldTag("sectionContentId") or 0))
        local isVisibility = tonumber((WorldCommon.GetWorldTag("visibility") or 0))
        local lessonName = WorldCommon.GetWorldTag("lessonName") or ""
        local lessonPackageName = WorldCommon.GetWorldTag("lessonPackageName") or ""
        local materialName = WorldCommon.GetWorldTag("materialName") or ""
        local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
        local project_id = 0
        local project_name = ""
        local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
        if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
            project_id = world_data.kpProjectId
            project_name = world_data.name
            local sendMsg = {
                projectId = project_id,
                projectName = project_name,
                classroomId = classroomId,
                sectionContentId = sectionContentId,
                lessonName = lessonName,
                lessonPackageName = lessonPackageName,
                materialName = materialName,
                isVisibility = isVisibility,
            }
            Emscripten:SendMsg("SyncWorldFinish", sendMsg , nil , nil ,"external");
            LOG.std(nil,"info","EducateClassManager","SendMsgToJS SyncWorldFinish msg send success,msg is"..commonlib.serialize_compact(sendMsg)) 
            return
        end 
        LOG.std(nil,"info","EducateClassManager","SendMsgToJS SyncWorldFinish project_id is nil") 
    end
end