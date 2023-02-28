--[[
Title: 管理建造回放
Author(s): hyz
Date: 2022/7/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/ReplayManager.lua");
local ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");
ReplayManager:Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordBlockBuild.lua");
local RecordBlockBuild = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordBlockBuild");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordUserPath.lua");
local RecordUserPath = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordUserPath");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordCode.lua");
local RecordCode = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordCode");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorderSettings.lua");
local VideoRecorderSettings = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorderSettings");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/FileLogUtil.lua");
local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordActorBone.lua");
local RecordActorBone = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordActorBone");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityHomePoint.lua");
local EntityHomePoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityHomePoint")
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieChannel.lua");
local MovieChannel = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieChannel");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
local EntityCommandBlock = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock")
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.lua");
local MovieText = commonlib.gettable("MyCompany.Aries.Game.Mod.MovieText");
local FileLogUtil = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.FileLogUtil");

local ReplayManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager"));

local _fileLog = FileLogUtil:new({filename = "log_video_queue.txt"})

function ReplayManager:Init()
    GameLogic:Connect("WorldLoaded", ReplayManager, ReplayManager.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldSaved", ReplayManager, ReplayManager.OnWorldSaved, "UniqueConnection");
    RecordCode:OnInit()
    RecordActorBone:OnInit()
end

function ReplayManager:OnWorldLoaded()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        RecordBlockBuild:OnEnterWorld()
        RecordUserPath:OnEnterWorld()
        RecordCode:OnWorldLoaded()
        RecordActorBone:OnWorldLoaded()
        ReplayManager._isPlaying = nil
    end,0)

    GameLogic:Disconnect("WorldUnloaded", ReplayManager, ReplayManager.OnWorldUnload, "UniqueConnection");
    GameLogic.GetFilters():remove_filter("BaseContextMouseReleaseEvent", ReplayManager.OnMouseReleaseEvent)
    
    GameLogic.GetFilters():add_filter("BaseContextMouseReleaseEvent", ReplayManager.OnMouseReleaseEvent)
    GameLogic:Connect("WorldUnloaded", ReplayManager, ReplayManager.OnWorldUnload, "UniqueConnection");

    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local generatorName = WorldCommon.GetWorldTag("world_generator")
    self._IsRandomWorld = generatorName == "custom"
end

function ReplayManager:OnWorldSaved()
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        RecordBlockBuild:_saveHistory()
        RecordUserPath:_saveHistory()
        RecordCode:OnBeforeWorldSave()
        RecordActorBone:SaveWorldBoneData()
        local model_entity_num = 0
        local entities = GameLogic.EntityManager.FindEntities({category="searchable",type = GameLogic.EntityManager.EntityLiveModel.class_name});
        
        if entities then 
            for i=#entities,1,-1 do
                if entities[i]:IsOfType(GameLogic.EntityManager.EntityInvisibleClickSensor.class_name) then
                    table.remove(entities,i)
                end
            end
            model_entity_num = model_entity_num + #entities
        end
        entities = GameLogic.EntityManager.FindEntities({category="searchable",type = GameLogic.EntityManager.EntityBlockModel.class_name});
        if entities then 
            model_entity_num = model_entity_num + #entities
        end

        WorldCommon.SetWorldTag("model_entity_num",model_entity_num)
        WorldCommon.SaveWorldTag()
    end,0)
end

function ReplayManager:OnWorldUnload()
    GameLogic:Disconnect("WorldUnloaded", ReplayManager, ReplayManager.OnWorldUnload, "UniqueConnection");
    GameLogic.GetFilters():remove_filter("BaseContextMouseReleaseEvent", ReplayManager.OnMouseReleaseEvent)
    if ReplayManager._movieTimer then
        ReplayManager._movieTimer:Change()
        ReplayManager._movieTimer = nil
    end
    commonlib.TimerManager.SetTimeout(function() --即使报错，也尽量不中断程序
        -- print("ReplayManager:OnExitWorld")
        RecordBlockBuild:OnExitWorld()
        RecordUserPath:OnExitWorld()
        RecordCode:OnWorldUnloaded()
        RecordActorBone:OnWorldUnloaded()
        -- GameLogic.AddBBS(10,"离开世界")
    end,0)
end

function ReplayManager.OnMouseReleaseEvent()
    if GameLogic.GetGameMode()~="edit" then
        return
    end
    if ReplayManager._isPauseRecording then
        return
    end
    RecordBlockBuild.OnMouseReleaseEvent()
    RecordUserPath.OnMouseReleaseEvent()
end

function ReplayManager:PauseRecord()
    ReplayManager._isPauseRecording = true
end

function ReplayManager:IsRecording()
    return not ReplayManager._isPauseRecording
end

function ReplayManager:ResumeRecord()
    ReplayManager._isPauseRecording = nil
end

--[[
    返回一个table, 有各种数据统计，用于合成视频预览图封面
    例如：作者， 创作时长，鼠标点击数，打字数量， 代码行数，bmax角色数，总操作体量 等
]]
function ReplayManager:GetStats()

end

function ReplayManager:_createOrGetCamera()
    local _camera = ReplayManager._camera
    if _camera==nil then
        _camera = EntityCamera:Create({item_id = block_types.names.TimeSeriesCamera});
        ReplayManager._camera = _camera
        _camera:SetPersistent(false);
		_camera:Attach();
    end
    return _camera
end

--[[
    防止录制视频的时候有远处的方块没有渲染出来，先在每个录制点跑一遍
]]
function ReplayManager:PreLook(x,y,z,time,callback)
    local _camera = self:_createOrGetCamera()
    _camera:SetPosition(x,y,z)
    _camera:HideCameraModel()
    _camera:SetFocus()

    if ReplayManager._movieTimer then
        ReplayManager._movieTimer:Change()
        ReplayManager._movieTimer = nil
    end

    local yaw = 0
    local dist = 20
    local pitch = 25

    local tick_count = time*(ParaEngine.GetAttributeObject():GetField("FPS", 0))
    local speed_yaw = 360/tick_count
    local acc = 0
    ReplayManager._movieTimer = commonlib.Timer:new({callbackFunc=function()
        yaw = (yaw + speed_yaw)%360
        ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);
        acc = acc + 1
        if acc==tick_count then
            if ReplayManager._movieTimer then
                ReplayManager._movieTimer:Change()
                ReplayManager._movieTimer = nil
            end
            if callback then
                callback()
            end
        end
    end})
    ReplayManager._movieTimer:Change(0,1)
end

function ReplayManager.StopAllCodeBlocks()
    local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
    if(entities and #entities>0) then
        local count = 0
        for _, entity in ipairs(entities) do
            if(entity:IsCodeLoaded()) then
                entity:GetCodeBlock():Stop();
                count = count + 1
            end
        end
        GameLogic.AddBBS(nil, format("%d/%d code block is stopped", count, #entities));
    end
end

--返回的是一个default编码值
function ReplayManager.GetWorldName()
	local folder_name = WorldCommon.GetWorldTag("name")
    folder_name = commonlib.Encoding.Utf8ToDefault(folder_name)
    
	return folder_name;
end

--[[
    speed : 播放倍速,默认1
    duration : speed为空，限制播放时间
    subtitle : false|true 是否有字幕
]]
function ReplayManager:Play(options,callback,taskId)
    if ReplayManager._isPlaying then
        return
    end
    ReplayManager._isPlaying = true
    ReplayManager._playCallback = callback

    taskId = taskId or 0;
    options = options or {}
    local speed = options.speed or 1
    local maxTime = options.maxTime or 10

    local _searchTime = os.clock()
    _fileLog:output_video_log(nil, "info", "ReplayManager", "Play begin,worldId:%s",tostring(WorldCommon.GetWorldTag("kpProjectId")));
    local _buildings = RecordBlockBuild:SearchHotBuildings()
    _searchTime = os.clock()-_searchTime
    _fileLog:output_video_log(nil, "info", "ReplayManager", "Play SearchHotBuildings,#_buildings:%s,time:%s",#_buildings,_searchTime);
    if #_buildings==0 then
        ReplayManager._isPlaying = nil
        if ReplayManager._playCallback then
            ReplayManager._playCallback()
            ReplayManager._playCallback = nil
        end
        return
    end

    RecordBlockBuild.SetConfig({
        TIME_SPEED = math.min(speed,8),
        MAX_TIME = options.maxTime,
    })
    RecordUserPath.SetConfig({
        TIME_SPEED = math.max(speed,8),
        MAX_TIME = options.maxTime,
    })

    for k,v in pairs(_buildings) do
        local second,speed_block,blocks_per_tick = RecordBlockBuild:GetDefaultPlayTimeOfBlockCount(v.count,speed)
        -- print("------v.count",v.count)
        -- print("-------second,",second)
    end

    local look_num = math.min(#_buildings,3) --要录制几个建筑视频
    local _projectId = WorldCommon.GetWorldTag("kpProjectId")
    local _projectName = ReplayManager.GetWorldName()

    local floder = ParaIO.GetWritablePath().."temp/video/"..os.date("%Y-%m-%d").."/"
    if not ParaIO.DoesFileExist(floder) then
        ParaIO.CreateDirectory(floder)
    end
    VideoRecorderSettings.SetOutputFloder(floder)
    local filename = string.format("%s_%s_%s",tostring(taskId),tostring(_projectId),tostring(_projectName))
    VideoRecorderSettings.SetOutputFilename(filename)
    VideoRecorderSettings.SetPreset("auto video share");
    VideoRecorderSettings.SetFPS(60);
    local videoPath = VideoRecorderSettings.GetOutputFilepath()
    local coverPath = string.gsub(videoPath,".mp4",".jpg")

    local old_focus = GameLogic.EntityManager.GetFocus()
    local old_dist, old_pitch, old_yaw = ParaCamera.GetEyePos();
    local old_islockSize = ParaEngine.GetAttributeObject():GetField("LockWindowSize", false);
    local old_renderdist = GameLogic.options:GetRenderDist()
    local old_super_renderdist = GameLogic.options:GetSuperRenderDist()
    local old_ScreenResolution = ParaEngine.GetAttributeObject():GetField("ScreenResolution", {1280, 720}); 
    local old_BulletScreenIsOpened = KpChatChannel.BulletScreenIsOpened() 

    local new_filename = string.format("%s_%s_%s",tostring(taskId),tostring(_projectId),tostring(_projectName))
    coverPath = string.format("%s%s",floder,new_filename..".jpg") --截图文件读写都用Utf8ToDefault
    local _timeOut = nil
    
    ReplayManager._onCaptureFinish = function ()
        if _timeOut then
            _timeOut:Change()
            _timeOut = nil
        end
        System.os.options.DisableInput(false);
        -- ParaEngine.GetAttributeObject():SetField("ScreenResolution", old_ScreenResolution); 
        -- ParaEngine.GetAttributeObject():CallField("UpdateScreenMode");
        ParaEngine.GetAttributeObject():SetField("LockWindowSize", old_islockSize);
        BroadcastHelper.GetSingletonTipsStack():Show(true)
        GameLogic.RunCommand("/show player")
        KpChatChannel.SetBulletScreen(old_BulletScreenIsOpened)
        
        VideoRecorderSettings.SetOutputFilename(nil)
        if old_focus and old_focus==GameLogic.EntityManager.GetPlayer() then
            old_focus:SetFocus()
            ParaCamera.SetEyePos(old_dist, old_pitch, old_yaw)

            ReplayManager._isPlaying = nil
        end
        RecordUserPath:StopAllEntityAni()

        GameLogic.AddBBS(nil,L"视频生成完成")
        local _videoTime = ParaGlobal.timeGetTime() - VideoRecorder.start_time
        _videoTime = _videoTime/1000
        print("_videoTime",_videoTime)
        
        videoPath = string.format("%s%s",floder,new_filename..".mp4")--视频文件录制的时候以原始文件名录制，读的时候以Utf8ToDefault去读
        _fileLog:output_video_log(nil, "info", "ReplayManager", '视频生成完成,{_videoTime=%s,filename="%s",videoPath="%s",coverPath="%s",taskId=%s,projectId=%s}',_videoTime,commonlib.Encoding.DefaultToUtf8(filename),commonlib.Encoding.DefaultToUtf8(videoPath),commonlib.Encoding.DefaultToUtf8(coverPath),taskId,tostring(_projectId));
        
        if ReplayManager._playCallback then
            ReplayManager._playCallback({
                filename = filename,
                videoPath = videoPath,
                coverPath = coverPath,
                _videoTime = _videoTime,
            })
            ReplayManager._playCallback = nil
        end
        GameLogic.AddBBS(1,L"debug_off_script")
        ReplayManager:debug_off_script()
    end

    local function _playPathAndBuildings(num,cb) --num：播放几个
        num = num or #_buildings
        if num==0 then
            if cb then
                cb()
                cb = nil 
            end
            return
        end
        local idx = 0
        local _playOne;
        _playOne = function()
            idx = idx + 1
            if idx>num then
                commonlib.TimerManager.SetTimeout(function()
                    if cb then
                        cb()
                        cb = nil 
                    end
                end,0.5*1000)
                return
            end
            local v = _buildings[idx]
            local cx,cy,cz = v.meanCenter[1],v.meanCenter[2],v.meanCenter[3]
            local radius = v.radius + 20

            --播放建筑点附近的路径动画
            RecordUserPath:PlayPathAnimsNearPos(cx,cy,cz,radius,{
                withCameraOn = false
            },function()
                -- RecordBlockBuild:PlayOneBuildAni(v,_playOne)
            end)
            v.speed_yaw = 0.2
            v.animType = (idx-1)%3+1
            --播放建造动画
            RecordBlockBuild:PlayOneBuildAni(v,_playOne)
        end
        _playOne()
    end

    --预览完成，开始播放
    local function _realStartPlay()
        ReplayManager:debug_on_script()
        GameLogic.RunCommand("/hide player")
        GameLogic.RunCommand("/clearbag")
        BroadcastHelper.GetSingletonTipsStack():Show(false)
        KpChatChannel.SetBulletScreen(false)
        _fileLog:output_video_log(nil, "info", "ReplayManager", "_realStartPlay,worldId:%s",tostring(_projectId));
        
        commonlib.TimerManager.SetTimeout(function()
            System.os.options.DisableInput(true);
            VideoRecorder.BeginCaptureImp(function()
                ParaEngine.ForceRender();ParaEngine.ForceRender();
                ParaMovie.TakeScreenShot(coverPath)
                _fileLog:output_video_log(nil, "info", "ReplayManager", "开始录制BeginCaptureImp,worldId:%s",tostring(_projectId));
                _timeOut = commonlib.TimerManager.SetTimeout(function()
                    _fileLog:output_video_log(nil, "info", "ReplayManager", "录制超时");
                    _timeOut = nil
                    VideoRecorder.EndCapture()
                    RecordUserPath:StopAllEntityAni()
                    if ReplayManager._onCaptureFinish then
                        ReplayManager._onCaptureFinish()
                        ReplayManager._onCaptureFinish = nil
                    end
                end,60*1000)
                ParaEngine.GetAttributeObject():SetField("LockWindowSize", true);
                
                local xx_time = os.clock()
                -- print("1-----time",os.clock()-xx_time)
                local _onAfterCode = function()
                    -- print("3-----time",os.clock()-xx_time);xx_time = os.clock();
                    local hasCall = false --有意外调用的，防止一下
                    RecordUserPath:StopAllEntityAni()
                    RecordUserPath:PlayPathAnimsFromBorn({
                        speed = 8,
                        maxTime = 2000,
                        withCameraOn = true,
                    },function()
                        -- print("4-----time",os.clock()-xx_time);xx_time = os.clock();
                        _playPathAndBuildings(look_num,function()
                            if hasCall then
                                _fileLog:output_video_log(nil, "error", "ReplayManager", "二次回调，有误,worldId:%s",tostring(_projectId));
                                return
                            end
                            hasCall = true
                            if _timeOut then
                                _timeOut:Change()
                                _timeOut = nil
                            end
                            -- print("5-----time",os.clock()-xx_time);xx_time = os.clock();
                            _fileLog:output_video_log(nil, "info", "ReplayManager", "结束录制EndCapture,worldId:%s",tostring(_projectId));
                            VideoRecorder.EndCapture()
                            RecordUserPath:StopAllEntityAni()
                            if ReplayManager._onCaptureFinish then
                                ReplayManager._onCaptureFinish()
                                ReplayManager._onCaptureFinish = nil
                            end
                        end)
                    end)
                end
                local codePlayTime = 3
                local num = RecordCode:GenerateCode()
                if num>0 then
                    -- print("2-----time",os.clock()-xx_time,"num",num);xx_time = os.clock();
                    RecordCode:StartPlay(codePlayTime,_onAfterCode)
                else
                    _onAfterCode()
                end
                
            end)
        end,0.1)
    end

    local minPrelookTime = 10
    if self._IsRandomWorld then
        minPrelookTime = 30
    end
    local _preload; --先预览世界
    _preload = function(idx)
        if idx>look_num then
            old_focus:SetFocus()
            ParaCamera.SetEyePos(old_dist, old_pitch, old_yaw)
            _realStartPlay()
        else
            local v = _buildings[idx]
            local cx,cy,cz = v.meanCenter[1],v.meanCenter[2],v.meanCenter[3]
            local x,y,z = BlockEngine:real(cx,cy,cz)

            local time = math.max(math.ceil(minPrelookTime/look_num),2)
            self:PreLook(x,y+10,z,time,function()
                _preload(idx+1)
            end)
        end
    end

    print("_searchTime",_searchTime)
    if _searchTime<3 then
        if old_renderdist<200 then
            GameLogic.options:SetRenderDist(200,true);
        end
        if old_super_renderdist<3000 then
            GameLogic.options:SetSuperRenderDist(3000,true);
        end
    end

    -- ParaEngine.GetAttributeObject():SetField("ScreenResolution", VideoRecorderSettings.GetResolution()); 
    -- ParaEngine.GetAttributeObject():CallField("UpdateScreenMode");
    _fileLog:output_video_log(nil, "info", "ReplayManager", "_prelook,预加载建筑，估算时间:%s,worldId:%s,filename:%s",math.max(minPrelookTime,2*look_num),tostring(_projectId),commonlib.Encoding.DefaultToUtf8(filename));
    _preload(1)
    -- if ParaMovie.IsRecording() then
        VideoRecorder.EndCapture()
    -- end
    ReplayManager.StopAllCodeBlocks()
    DownloadWorld.Close();
    ParaUI.Destroy('start_old_version_button') 
    ParaUI.Destroy('IDE_HELPER_MSGBOX') 
    ParaUI.Destroy('_click_to_continue_') 
    GameLogic.RunCommand("/hide dock")
    MovieText.ShowPage("")
    if MovieText.ShowPage_old then
        MovieText.ShowPage_old("")
    end
    
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
    MyCompany.Aries.ChatSystem.ChatWindow.HideAll();
    MyCompany.Aries.ChatSystem.ChatWindow.HideEdit();
    System.options.disable_click_to_continue = true
end

function ReplayManager:debug_on_script()
    ReplayManager.StopAllCodeBlocks()
    if UserPermission.CheckCanEditBlock_old==nil then
        UserPermission.CheckCanEditBlock_old = UserPermission.CheckCanEditBlock
    end
    UserPermission.CheckCanEditBlock = function(check_type, callbackFunc)
        if(callbackFunc) then
			callbackFunc();
		end
        return true
    end
    
    if EntityHomePoint.ActivateRules_old==nil then
        EntityHomePoint.ActivateRules_old = EntityHomePoint.ActivateRules
    end
    EntityHomePoint.ActivateRules = function()
    end

    
    if(CodeBlock.Run_old==nil) then
        CodeBlock.Run_old = CodeBlock.Run
    end
    CodeBlock.Run = function()
    end

    if MovieChannel.Play_old==nil then
        MovieChannel.Play_old = MovieChannel.Play
    end
    MovieChannel.Play = function()end

    
    if EntityMovieClip.ExecuteCommand_old==nil then
        EntityMovieClip.ExecuteCommand_old = EntityMovieClip.ExecuteCommand
    end
    EntityMovieClip.ExecuteCommand = function()end  

    if EntityCommandBlock.ExecuteCommand_old==nil then
        EntityCommandBlock.ExecuteCommand_old = EntityCommandBlock.ExecuteCommand
    end
    EntityCommandBlock.ExecuteCommand = function()end  

    if _guihelper.MessageBox_old then
        _guihelper.MessageBox_old = _guihelper.MessageBox
    end
    _guihelper.MessageBox = function()end

    if MovieText.ShowPage_old then
        MovieText.ShowPage_old = MovieText.ShowPage
    end
    MovieText.ShowPage = function()end

end

function ReplayManager:debug_off_script()
    if UserPermission.CheckCanEditBlock_old then
        UserPermission.CheckCanEditBlock = UserPermission.CheckCanEditBlock_old
    end
    if (CodeBlock.Run_old) then
        CodeBlock.Run = CodeBlock.Run_old
    end
    if EntityHomePoint.ActivateRules_old then
        EntityHomePoint.ActivateRules = EntityHomePoint.ActivateRules_old
    end
    if MovieChannel.Play_old then
        MovieChannel.Play = MovieChannel.Play_old
    end
    if EntityMovieClip.ExecuteCommand_old then
        EntityMovieClip.ExecuteCommand = EntityMovieClip.ExecuteCommand_old
    end
    if EntityCommandBlock.ExecuteCommand_old then
        EntityCommandBlock.ExecuteCommand = EntityCommandBlock.ExecuteCommand_old
    end
    
    if _guihelper.MessageBox_old then
        _guihelper.MessageBox = _guihelper.MessageBox_old
    end

    if MovieText.ShowPage_old then
        MovieText.ShowPage = MovieText.ShowPage_old
    end
end

local random_angles = {0,30,60,90,120,150,180,210,240,20,300,330,360}
function ReplayManager:_getRandomAngle()
    local idx = math.random(1,#random_angles)
    return random_angles[idx]
end

function ReplayManager:checkHasBlockBetween(from,to,fMaxDistance)
	local dir = mathlib.vector3d:new_from_pool(to[1]-from[1],to[2]-from[2],to[3]-from[3])
	dir:normalize();

	local x, y, z = from[1],from[2],from[3]
	local dirX,dirY,dirZ = dir[1],dir[2],dir[3]

	--找模型
	-- local result = ParaScene.Pick(x, y, z, dirX, dirY, dirZ, fMaxDistance or 10, "point")
	-- if(result:IsValid())then
	-- 	local x, y, z = result:GetPosition();
	-- 	local blockX, blockY, blockZ = BlockEngine:block(x,y+0.1,z);
	-- 	local entityName = result:GetName();
	-- 	-- print("entityName",entityName,"blockX, blockY, blockZ",blockX, blockY, blockZ)
	-- 	if(entityName and entityName~="") then
	-- 		local entity = EntityManager.GetEntity(entityName);
	-- 		if(entity) then
	-- 			local x1, y1, z1 = result:GetPosition();
	-- 			-- return entity, x1, y1, z1;
	-- 		end
	-- 	end
	-- end

    --找方块
	local result = ParaTerrain.Pick(x, y, z, dirX, dirY, dirZ, fMaxDistance or 10,{}, 0xffffffff)
	if result.blockX then
		local blockId = BlockEngine:GetBlockId(result.blockX,result.blockY,result.blockZ)
		-- print("blockId",blockId,"x,y,z",result.blockX,result.blockY,result.blockZ)
        return blockId
	end
end

--通过camera观察目标和观察角度，获得"眼睛角度"
function ReplayManager:getEyePos(x,y,z,dist,pitch,yaw)
    while yaw<0 do
		yaw = yaw + 6.28
	end
	if yaw>=3.14 then
		yaw = yaw - 6.28
	end
	while pitch<0 do
		pitch = pitch + 6.28
	end
	if pitch>=3.14 then
		pitch = pitch - 6.28
	end
    local z2,y2,z2;
    if dist>0 then
        y2 = y + dist*math.abs(math.sin(pitch))
    else
        y2 = y - dist*math.abs(math.sin(pitch))
    end
    local d = dist*math.abs(math.cos(pitch))
	
    if yaw<=0 then
        z2 = z - math.abs(d*math.sin(yaw))
    else
        z2 = z + math.abs(d*math.sin(yaw))
    end
    if math.abs(yaw)<=1.57 then
        x2 = x - math.abs(d*math.cos(yaw))
    else
        x2 = x + math.abs(d*math.cos(yaw))
    end

    return x2,y2,z2
end
ReplayManager:InitSingleton()