--[[
Title: 作品集锦视频的渲染队列，不断从后台获取视频渲染任务
Author(s): hyz
Date: 2022/8/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/VideoRenderQueue.lua");
local VideoRenderQueue = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.VideoRenderQueue");

VideoRenderQueue:Init(GameLogic.GetWorldDirectory())
local acc = 10
for i=1,acc do
    wait(1)
    tip((acc-i+1).."秒后开始")
end
wait(1)
tip("开始")
VideoRenderQueue:adminLogin("videoworker","123456",function()
    VideoRenderQueue:StartRunTasks()
end)

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/ReplayManager.lua");
local ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/FileLogUtil.lua");
local FileLogUtil = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.FileLogUtil");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/LocalVideoTaskSetting.lua");
local LocalVideoTaskSetting = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.LocalVideoTaskSetting");


local VideoRenderQueue = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.VideoRenderQueue"));

--http://yapi.kp-para.cn/project/32/interface/api/192 --管理员登录
HttpWrapper.Create("keepwork.admins.login", "%MAIN%/core/v0/admins/login", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/5210 --获取生成视频任务
HttpWrapper.Create("keepwork.projectVideoPools.task", "%MAIN%/core/v0/projectVideoPools/task", "POST", true)

--
--http://yapi.kp-para.cn/project/32/interface/api/5215 --上传7牛成功后保存视频链接
HttpWrapper.Create("keepwork.projectVideos.submitUrl", "%MAIN%/core/v0/projectVideos", "POST", true)


local _fileLog = FileLogUtil:new({filename = "log_video_queue.txt"})

VideoRenderQueue._enterWorldAcc = 0; --进入世界次数
VideoRenderQueue._videoNum = 0; --录制视频次数
VideoRenderQueue._startClock = os.clock(); --开始任务的起始时间

--使用管理员权限token初始化
function VideoRenderQueue:Init(testWorldPath)
    VideoRenderQueue.testWorldPath = testWorldPath --用于生成视频的辅助世界，重启的时候用
    if self.is_inited then
        return
    end
    if not System.options.isDevMode then
        return
    end
    self.is_inited = true
    if VideoRenderQueue._timer then
        VideoRenderQueue._timer:Change()
        VideoRenderQueue._timer = nil
    end
    VideoRenderQueue._timer = commonlib.Timer:new({callbackFunc=function()
        if not self._isRuning then 
            return
        end
        if VideoRenderQueue:CheckRestartApp() then
            return
        end
        if self._curTask==nil then
            self:ReqTask()
        end
    end})
    VideoRenderQueue._timer:Change(0,30*1000)
    
    VideoRenderQueue._enterWorldAcc = 0; --进入世界次数
    VideoRenderQueue._videoNum = 0; --录制视频次数
    VideoRenderQueue._startClock = os.clock(); --开始任务的起始时间

end

--进入世界次数、录制视频数量、或者运行时间超过限制后就重启应用
function VideoRenderQueue:CheckRestartApp()
    local MAX_ENTER_WORLD = 20
    local MAX_VIDEO_NUM = 10
    local MAX_TIME = 30*60
    repeat
        if VideoRenderQueue._enterWorldAcc>=MAX_ENTER_WORLD then
            _fileLog:output_video_log(nil, "restart", "VideoRenderQueue", "进世界次数超限,去重启,_enterWorldAcc:%s\n\n",VideoRenderQueue._enterWorldAcc);
            break
        end
        if VideoRenderQueue._videoNum>=MAX_VIDEO_NUM then
            _fileLog:output_video_log(nil, "restart", "VideoRenderQueue", "录视频数量超限,去重启,_videoNum:%s\n\n",VideoRenderQueue._videoNum);
            break
        end
        local _usedTime = os.clock() - VideoRenderQueue._startClock;--运行时间
        if _usedTime>MAX_TIME then
            _fileLog:output_video_log(nil, "restart", "VideoRenderQueue", "运行时间超限,去重启,_usedTime:%s\n\n",_usedTime);
            break
        end
        if VideoRenderQueue._errorOccur then
            _fileLog:output_video_log(nil, "error|restart", "VideoRenderQueue", "发生异常，去重启:%s\n\n",tostring(VideoRenderQueue._errorOccur));
            break
        end

        return false
    until true
    
    
    local cmd = [[
		start %s\paraengineclient.exe world="%s" mc="true" IsDevEnv="true" isDevMode="true"
	]]
    cmd = string.format(cmd,ParaIO.GetWritablePath(),VideoRenderQueue.testWorldPath)

    if VideoRenderQueue.bIsLocalMode then 
        cmd = [[
            start %s\paraengineclient.exe paracraft://protocol="paracraft" cmd/loadworld %s mc="true" IsDevEnv="true" isDevMode="true" _loginToken="%s"
        ]]
        local _token = GameLogic.GetFilters():apply_filters("store_get", "user/token")
        cmd = string.format(cmd,ParaIO.GetWritablePath(),VideoRenderQueue.testWorldPath,_token)        
    end
	os.execute(cmd)

	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()

    commonlib.TimerManager.SetTimeout(function()
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
    end,2000)

    return true
end

function VideoRenderQueue:OnWorldLoaded()
    GameLogic:Disconnect("WorldLoaded", VideoRenderQueue, VideoRenderQueue.OnWorldLoaded, "UniqueConnection");

    GameLogic:Disconnect("WorldUnloaded", VideoRenderQueue, VideoRenderQueue.OnWorldUnloaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", VideoRenderQueue, VideoRenderQueue.OnWorldUnloaded, "UniqueConnection");
    
    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "OnWorldLoaded:projectId:%s,task.pid:%s",GameLogic.options:GetProjectId(),(VideoRenderQueue._curTask and VideoRenderQueue._curTask.projectId or "nil"));
    -- print("=======OnWorldLoaded,GameLogic.options:GetProjectId()",GameLogic.options:GetProjectId())
    -- echo(self._curTask)
    if self._curTask then
        commonlib.TimerManager.SetTimeout(function()
            VideoRenderQueue._isNewWorldLoaded = true

            if VideoRenderQueue._timeoutHandler then
                VideoRenderQueue._timeoutHandler:Change()
                VideoRenderQueue._timeoutHandler = nil
            end
            -- print("------aaaaa 1 ")
            -- print("VideoRenderQueue._isNewWorldLoaded , VideoRenderQueue._isLoadingBarClosed , not VideoRenderQueue._isRecordStarted",VideoRenderQueue._isNewWorldLoaded , VideoRenderQueue._isLoadingBarClosed , not VideoRenderQueue._isRecordStarted)
            if VideoRenderQueue._isLoadingBarClosed and not VideoRenderQueue._isRecordStarted then
                VideoRenderQueue:StartRecord()
            end
        end,2*1000)
    end
    ReplayManager.StopAllCodeBlocks()
    GameLogic.GetFilters():remove_filter("enter_world_fail",VideoRenderQueue.onEnterWorldFail)

    VideoRenderQueue._enterWorldAcc = VideoRenderQueue._enterWorldAcc + 1
    VideoRenderQueue:CheckRestartApp()

    ReplayManager:debug_on_script()
end

function VideoRenderQueue.onSwf_loading_barClosed()
    -- print("=========onSwf_loading_barClosed")
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  VideoRenderQueue.onSwf_loading_barClosed);
    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "onSwf_loading_barClosed:projectId:%s,task.pid:%s",GameLogic.options:GetProjectId(),VideoRenderQueue._curTask and VideoRenderQueue._curTask.projectId or "nil");
    
    commonlib.TimerManager.SetTimeout(function()
        VideoRenderQueue._isLoadingBarClosed = true

        if VideoRenderQueue._timeoutHandler then
            VideoRenderQueue._timeoutHandler:Change()
            VideoRenderQueue._timeoutHandler = nil
        end
        -- print("------aaaaa 2 ")
        -- print("VideoRenderQueue._isNewWorldLoaded , VideoRenderQueue._isLoadingBarClosed , not VideoRenderQueue._isRecordStarted",VideoRenderQueue._isNewWorldLoaded , VideoRenderQueue._isLoadingBarClosed , not VideoRenderQueue._isRecordStarted)
        if VideoRenderQueue._isNewWorldLoaded and not VideoRenderQueue._isRecordStarted then
            VideoRenderQueue:StartRecord()
        end
    end,2*1000)
    
    return true
end

function VideoRenderQueue:OnWorldUnloaded()
    GameLogic:Disconnect("WorldUnloaded", VideoRenderQueue, VideoRenderQueue.OnWorldUnloaded, "UniqueConnection");
    
    -- print("==========CodeBlock.Run_old",CodeBlock.Run_old)
    ReplayManager:debug_off_script()
end

function VideoRenderQueue:StartRunTasks()
    if not System.options.isDevMode then
        return
    end
    self:ReqTask()
    self._isRuning = true
    VideoRenderQueue._enterWorldAcc = 0; --进入世界次数
    VideoRenderQueue._videoNum = 0; --录制视频次数
    VideoRenderQueue._startClock = os.clock(); --开始任务的起始时间
    _fileLog:output_video_log(nil, "StartRunTasks", "VideoRenderQueue", "\n\n>>>>>>>>>>>>>>>开始跑任务>>>>>>>>>>>>>\n\n");
end

function VideoRenderQueue:PauseTasks()
    self._isRuning = false

end

--从服务端获取一个视频任务
function VideoRenderQueue:ReqTask()
    if self._curTask~=nil then
        local _now = os.time()
        if self._curTask.timeStramp and _now-self._curTask.timeStramp>2*60 then --超时了，可能是意外中断了，兼容一下
        else
            -- print("=======self._curTask")
            -- echo(self._curTask,true)
            -- print('GameLogic.options:GetProjectId()',GameLogic.options:GetProjectId())
            -- if self._curTask.projectId~=GameLogic.options:GetProjectId() then
            _fileLog:output_video_log(nil, "warning", "VideoRenderQueue", "ReqTask 重复任务 gotoWorld:%s,taskId:%s",self._curTask.projectId,self._curTask.id);
                self:gotoWorld(self._curTask.projectId)
            -- end
            return
        end
    end

    local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
    local bak_sessions = SessionsData:GetSessions()
    
    local machineID = ParaEngine.GetAttributeObject():GetField('MachineID', '')
    local clientId = machineID
    if bak_sessions then
        clientId = (bak_sessions.selectedUser or "").."_"..clientId
    end
    if VideoRenderQueue.bIsLocalMode then 
        local task = LocalVideoTaskSetting.GetNextLocalTask()
        if task==nil then
            ReplayManager:debug_off_script();
            BroadcastHelper.GetSingletonTipsStack():Show(true)
            GameLogic.AddBBS(nil,L"当前没有本地视频任务了",2000)
            return
        end
        self._curTask = task
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue_local", "ReqTask resp,projectId:%s,taskId:%s",self._curTask.projectId,self._curTask.id);
        echo(task)
        self:gotoWorld(self._curTask.projectId)
        return
    end
    --暂时只生成视频在帕帕奇遇记的世界上面
    keepwork.projectVideoPools.task({
        clientId = clientId,
        platform = {
        "paracraft_papa",
        "paracraft-android_tatfook_papa",
        "paracraft-android_yingyongbao_papa",
        "paracraft-android_xiaomi_papa",
        "paracraft-android_huawei_papa",
        "paracraft-android_oppo_papa",
        "paracraft-android_vivo_papa",
        "paracraft-android_qihu360_papa",
        "paracraft-android_baidu_papa",
        "paracraft-android_meizu_papa",
        "paracraft-ios_papa",
        "paracraft-mac_papa",},
    },function(err,msg,data)
        if err==401 or err==403 then
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "keepwork.projectVideoPools.task失败,要去重新获取管理员token. err:"..(err or "nil"));
            self:adminLogin(nil,nil,function(token)
                commonlib.TimerManager.SetTimeout(function()
                    if self._isRuning then
                        self:ReqTask()
                    end
                end,2*1000)
            end)
            return
        end
        if data.task==nil then
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "当前没有视频任务了");
            ReplayManager:debug_off_script();
            BroadcastHelper.GetSingletonTipsStack():Show(true)
            GameLogic.AddBBS(nil,L"当前没有视频任务了",2000)
            return
        end
        self._curTask = data.task
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "ReqTask resp,projectId:%s,taskId:%s",self._curTask.projectId,self._curTask.id);
        echo(data.task)
        self:gotoWorld(self._curTask.projectId)
    end)
end

function VideoRenderQueue:clearToken()
    VideoRenderQueue._token = nil
    if VideoRenderQueue._oldToken then
        System.User.keepworktoken = VideoRenderQueue._oldToken
    end
end

function VideoRenderQueue:adminLogin(username,password,callback)
    if not VideoRenderQueue._oldToken then
        VideoRenderQueue._oldToken = System.User.keepworktoken
    end
    username = username or VideoRenderQueue._username
    password = password or VideoRenderQueue._password
    if username==nil or password==nil then
        GameLogic.AddBBS(nil,L"管理员用户名和密码不能为空",5000,"255 0 0")
        return
    end
    keepwork.admins.login({
        username = username,
        password = password,
    },function(err,msg,data)
        if err~=200 then
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "管理员登录失败 err"..(err or "nil"));
            echo(data,true)
            GameLogic.AddBBS(nil,L"管理员登录失败",5000,"255 0 0")
            return
        end
        VideoRenderQueue._token = data.token
        VideoRenderQueue._username = username
        VideoRenderQueue._password = password
        System.User.keepworktoken = data.token;
        if callback then
            callback(data.token)
        end
    end)
end

function VideoRenderQueue:gotoWorld(projectId)
    if VideoRenderQueue._isRecording then
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "projectId:%s,VideoRenderQueue._isRecording：%s",projectId,tostring(VideoRenderQueue._isRecording));
        return
    end
    ReplayManager:debug_on_script()
    BroadcastHelper.GetSingletonTipsStack():Show(true)
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  VideoRenderQueue.onSwf_loading_barClosed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  VideoRenderQueue.onSwf_loading_barClosed);

    GameLogic.GetFilters():remove_filter("enter_world_fail",VideoRenderQueue.onEnterWorldFail)
    GameLogic.GetFilters():add_filter("enter_world_fail",VideoRenderQueue.onEnterWorldFail)

    GameLogic:Disconnect("WorldLoaded", VideoRenderQueue, VideoRenderQueue.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", VideoRenderQueue, VideoRenderQueue.OnWorldLoaded, "UniqueConnection");

    VideoRenderQueue._isNewWorldLoaded = false
    VideoRenderQueue._isLoadingBarClosed = false
    VideoRenderQueue._isRecordStarted = false
    local cmd = string.format("/loadworld -s -force %s",projectId)
    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "gotoWorld:"..(cmd or "nil"));
    GameLogic.RunCommand(cmd)
    if VideoRenderQueue._timeoutHandler then
        VideoRenderQueue._timeoutHandler:Change()
        VideoRenderQueue._timeoutHandler = nil
    end
    --进世界超时
    VideoRenderQueue._timeoutHandler = commonlib.TimerManager.SetTimeout(function()
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "gotoWorld超时，请求下一个");
        VideoRenderQueue:ReqNextAndSubmitNil()
    end,2*60*1000)
end

function VideoRenderQueue.onEnterWorldFail(...)
    GameLogic.GetFilters():remove_filter("enter_world_fail",VideoRenderQueue.onEnterWorldFail)
    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "进入世界失败 下一个");
    
    VideoRenderQueue:ReqNextAndSubmitNil()
    return ...
end

function VideoRenderQueue:ReqNextAndSubmitNil()
    if self._curTask then
        if VideoRenderQueue.bIsLocalMode then
            LocalVideoTaskSetting.SubmitTask({
                projectId = self._curTask.projectId,
                isNoVideo = true
            })
            VideoRenderQueue:NextTask()
            return
        end
        keepwork.projectVideos.submitUrl({
            taskId = self._curTask.id,
        },function(err,msg,data)
            print("VideoRenderQueue 没视频submitUrl返回 err",err)
            if err==401 or err==403 then
                _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "keepwork.projectVideos.submitUrl失败,要去重新获取管理员token err:"..(err or "nil"));
                self:adminLogin(nil,nil,function()
                    VideoRenderQueue:NextTask()
                end)
                return
            end
            VideoRenderQueue:NextTask()
        end)
    end
end

function VideoRenderQueue:StartRecord()
    if not System.options.isDevMode then
        return
    end
    if self._curTask.projectId~=GameLogic.options:GetProjectId() then
        commonlib.TimerManager.SetTimeout(function()
            if self._curTask.projectId~=GameLogic.options:GetProjectId() then
                _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "----type(self._curTask.projectId)=%s,type(GameLogic.options:GetProjectId())=%s",type(self._curTask.projectId),type(GameLogic.options:GetProjectId()));
                VideoRenderQueue._errorOccur = string.format("StartRecord 世界id对不上,有问题。_curTask.projectId,%s,GameLogic.options:GetProjectId():%s",self._curTask.projectId,GameLogic.options:GetProjectId())
                self:CheckRestartApp()
            else
                VideoRenderQueue:StartRecord()
            end
        end,10*1000)
        return
    end
    local DockLayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer")
    if DockLayer.IsShowDockPage and DockLayer:IsShowDockPage() then
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "%s IsShowDockPage",self._curTask.id);
        VideoRenderQueue:ReqNextAndSubmitNil()
        return;
    end
    VideoRenderQueue._isRecordStarted = true
    if VideoRenderQueue._timeoutHandler then
        VideoRenderQueue._timeoutHandler:Change()
        VideoRenderQueue._timeoutHandler = nil
    end

    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "StartRecord,projectId:%s",GameLogic.options:GetProjectId());

    if ParaMovie.IsRecording() then
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "显示还在录制，有bug，重启,projectId:%s",GameLogic.options:GetProjectId());
        VideoRenderQueue._errorOccur = "此处不应该处在录制中，有问题"
        self:CheckRestartApp()
        return
    end
    --播放超时
    VideoRenderQueue._timeoutHandler = commonlib.TimerManager.SetTimeout(function()
        _fileLog:output_video_log(nil, "warn", "VideoRenderQueue", "StartRecord超时，");
        VideoRenderQueue._errorOccur = "StartRecord超时，重启"
        self:CheckRestartApp()
    end,2*60*1000)
    ReplayManager.StopAllCodeBlocks()
    BroadcastHelper.GetSingletonTipsStack():Show(false)
    local _beginTime = os.clock()

    VideoRenderQueue._isRecording = true

    local _onFinished = function(result)
        if VideoRenderQueue._timeoutHandler then
            VideoRenderQueue._timeoutHandler:Change()
            VideoRenderQueue._timeoutHandler = nil
        end
        BroadcastHelper.GetSingletonTipsStack():Show(true)
        if result==nil or result.videoPath==nil or result.coverPath==nil then
            VideoRenderQueue._isRecording = nil
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "%s 该世界没有视频数据，去下一个",self._curTask.id);
            VideoRenderQueue:ReqNextAndSubmitNil()
            return;
        end

        if result._videoTime<5 then
            VideoRenderQueue._isRecording = nil
            GameLogic.AddBBS(nil,L"视频生成完成,过短，不上传_videoTime:"..result._videoTime)
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "视频生成完成,过短，不上传_videoTime:%s",result._videoTime);
            VideoRenderQueue:ReqNextAndSubmitNil()
            return;
        end
        
        if result._videoTime>30 then
            VideoRenderQueue._isRecording = nil
            GameLogic.AddBBS(nil,L"视频生成完成,过长，不上传_videoTime:"..result._videoTime)
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "视频生成完成,过长，不上传_videoTime:%s",result._videoTime);
            -- VideoRenderQueue:ReqNextAndSubmitNil()
            VideoRenderQueue._errorOccur = "视频生成时间过长，可能有问题"
            VideoRenderQueue:CheckRestartApp()
            return;
        end
        
        VideoRenderQueue._videoNum = VideoRenderQueue._videoNum + 1
        
        local _useTime = os.clock()-_beginTime
        -- print("========videoPath",result.videoPath,"coverPath",result.coverPath)
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "videoPath:%s,coverPath%s",commonlib.Encoding.DefaultToUtf8(result.videoPath),commonlib.Encoding.DefaultToUtf8(result.coverPath));
        _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "视频录制时间：_useTime:%s,_videoTime:%s",_useTime,result._videoTime);
        if string.find(result.filename,string.format("%s_%s",self._curTask.id,self._curTask.projectId))~=1 then
            _fileLog:output_video_log(nil, "error", "VideoRenderQueue", "视频文件路径和任务世界id对不上,filename:%s,_curTask.projectId:%s,taskId=%s",commonlib.Encoding.DefaultToUtf8(result.filename),self._curTask.projectId,self._curTask.id);
            VideoRenderQueue._errorOccur = "视频文件路径和世界任务id对不上"
            self:CheckRestartApp()
            return
        end
        if VideoRenderQueue.bIsLocalMode then
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue_local", '录制成功,{projectId=%s,videoPath=%s,coverPath=%s}',self._curTask.projectId,commonlib.Encoding.DefaultToUtf8(result.videoPath),commonlib.Encoding.DefaultToUtf8(result.coverPath));
            LocalVideoTaskSetting.SubmitTask({
                projectId = self._curTask.projectId,
                filename = result.filename,
                videoPath = result.videoPath,
                coverPath = result.coverPath,
            })
        end
        local videoNameTag = "project_videos_"..System.Encoding.base64(NPL.ToJson({projectId=self._curTask.projectId}))
        local coverNameTag = "project_videos_cover_"..System.Encoding.base64(NPL.ToJson({projectId=self._curTask.projectId}))
        self:upload2Qiniu(coverNameTag,result.coverPath,function(coverUrl)
            self:upload2Qiniu(videoNameTag,result.videoPath,function(videoUrl)
                print("----videoUrl:",videoUrl,"coverUrl",coverUrl)
                if VideoRenderQueue.bIsLocalMode then
                    VideoRenderQueue._isRecording = nil
                    _fileLog:output_video_log(nil, "info", "VideoRenderQueue_local", '上传视频和封面成功,去提交 {videoUrl="%s",coverUrl="%s",taskId=%s,projectId=%s}',videoUrl,coverUrl,self._curTask.id,self._curTask.projectId);
                    LocalVideoTaskSetting.SubmitTask({
                        projectId = self._curTask.projectId,
                        filename = result.filename,
                        videoPath = result.videoPath,
                        coverPath = result.coverPath,
                        videoUrl = videoUrl,
                        coverUrl = coverUrl
                    })
                    VideoRenderQueue:DeleteExpiredTemp()
                    VideoRenderQueue:NextTask()
                    return
                end
                _fileLog:output_video_log(nil, "info", "VideoRenderQueue", '上传视频和封面成功,去提交 {videoUrl="%s",coverUrl="%s",taskId=%s,projectId=%s}',videoUrl,coverUrl,self._curTask.id,self._curTask.projectId);
                keepwork.projectVideos.submitUrl({
                    videoUrl = videoUrl,
                    coverUrl = coverUrl,
                    taskId = self._curTask.id,
                },function(err,msg,data)
                    VideoRenderQueue._isRecording = nil
                    if err==401 or err==403 then
                        _fileLog:output_video_log(nil, "error", "VideoRenderQueue", "keepwork.projectVideos.submitUrl失败,要去重新获取管理员token err:"..(err or "nil"));
                        VideoRenderQueue._errorOccur = "keepwork.projectVideos.submitUrl失败,要去重新获取管理员token"
                        self:CheckRestartApp()
                        return
                    end
                    if (err ~= 200) then
                        print("-----提交 err",err)
                        echo(data,true)
                        return
                    end
                    _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "视频url提交成功,去拉下一个任务");
                    
                    VideoRenderQueue:DeleteExpiredTemp()
                    VideoRenderQueue:NextTask()
                end)
            end)
        end)
    end
    if self._curTask.filename and result.videoPath then
        _onFinished({
            _videoTime = 20,
            filename = self._curTask.filename,
            coverPath = self._curTask.coverPath,
            videoPath = self._curTask.videoPath,
        })
        return
    end
	ReplayManager:Play({
		speed = 1
	},_onFinished,self._curTask.id)

end

function VideoRenderQueue:DeleteExpiredTemp(holdDay)
    holdDay = holdDay or 15 --只保留最近7天的视频文件
    for i=1,100 do --删除7天前到107天前的文件夹
        local time = os.time() - (holdDay+i)*24*3600
        local tmpFloder = ParaIO.GetWritablePath().."temp/video/"..os.date("%Y-%m-%d",time).."/"
        
        if ParaIO.DoesFileExist(tmpFloder) then
            _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "删除过期文件夹:%s",tmpFloder);
            ParaIO.DeleteFile(tmpFloder)
        end
    end
end

function VideoRenderQueue:NextTask()
    if VideoRenderQueue:CheckRestartApp() then
        return
    end
    self._curTask = nil
    if self._isRuning then
        self:ReqTask()
    end
end

--出错了，重试3次，还不行就算了
function VideoRenderQueue:onError()
    if self._curTask==nil then
        return
    end
    if self._curTask.errorCount==nil then
        self._curTask.errorCount = 1
    elseif self._curTask.errorCount==3 then
        self:NextTask()
        return
    end

    self._curTask.errorCount = self._curTask.errorCount + 1

    self:gotoWorld(self._curTask.projectId)
end

function VideoRenderQueue:upload2Qiniu(nameTag,videoPath,callback)
    keepwork.shareToken.get({cache_policy = "access plus 12 second", key=nameTag},function(err, msg, data)
        -- print("------shareToken err",err)
        -- echo(data,true)
        if err==401 or err==403 then
            _fileLog:output_video_log(nil, "error", "VideoRenderQueue", "keepwork.shareToken.get失败,要去重新获取管理员token. err:%s",err);
            VideoRenderQueue._errorOccur = "keepwork.shareToken.get失败,要去重新获取管理员token,重启"
            self:CheckRestartApp()
            return
        end
        if (err ~= 200 or (not data.data) or (not data.data.token) or (not data.data.key)) then
            print("------shareToken err",err)
            VideoRenderQueue._errorOccur = "keepwork.shareToken 530"
            self:CheckRestartApp()
            return;
        end

        local file_path = videoPath
        local file = ParaIO.open(file_path, "rb");
        if (not file:IsValid()) then
            file:close();
            VideoRenderQueue._errorOccur = "open file 541,filepath:"..tostring(videoPath)
            self:CheckRestartApp()
            return;
        end
        do 
            local content = file:GetText(0, -1);
            file:close();

            if not content then
                VideoRenderQueue._errorOccur = "read file 550,filepath:"..tostring(videoPath)
                self:CheckRestartApp()
                return;
            end

            local token = data.data.token;
            local key = data.data.key;
            local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(file_path));
            GameLogic.GetFilters():apply_filters(
                'qiniu_upload_file',
                token,
                key,
                file_name,
                content,
                function(result, err)
                    if err==401 or err==403 then
                        _fileLog:output_video_log(nil, "error", "VideoRenderQueue", "qiniu_upload_file失败,要去重新获取管理员token. err:%s",err);
                        VideoRenderQueue._errorOccur = "qiniu_upload_file失败,要去重新获取管理员token"
                        self:CheckRestartApp()
                        return
                    end
                
                    -- echo(result,true)
                    if err ~= 200 or result.data==nil or result.data.url==nil then
                        _fileLog:output_video_log(nil, "error", "VideoRenderQueue", "上传错误,err:%s",err);
                        VideoRenderQueue._errorOccur = "QiniuRootApi:Upload 574"
                        self:CheckRestartApp()
                        return;
                    end
                    local url = result.data.url.."?t="..os.time()
                    -- _fileLog:output_video_log(nil, "info", "VideoRenderQueue", "上传成功,url:%s",url);
                    callback(url)
                end
            )
        end
        collectgarbage("collect");
    end)
end

--任务重新提交
--[[
    projectId = 1,
    taskId = 1,
    videoPath = "",
    coverPath = "",
]]
function VideoRenderQueue:debug_resubmit_url(account,password,objArr)
    local function submitNil(obj,onSuccess,on401)
        print("----------去提交")
        echo(obj,true)
        keepwork.projectVideos.submitUrl({
            videoUrl = obj.videoUrl,
            coverUrl = obj.coverUrl,
            taskId = obj.taskId,
        },function(err,msg,data)
            VideoRenderQueue._isRecording = nil
            if err==401 or err==403 then
                if on401 then
                    on401()
                end
                print("------xxx提交错误",err)
                return
            end
            if (err ~= 200) then
                print("------提交错误",err)
                return
            end
            print("-----------重新提交成功,taskId",obj.taskId)
            if onSuccess then
                onSuccess()
            end
        end)
    end

    local _func;
    _func = function(idx)
        local obj = objArr[idx]
        if(obj==nil)then
            return
        end
        local videoNameTag = "project_videos_"..System.Encoding.base64(NPL.ToJson({projectId=obj.projectId}))
        local coverNameTag = "project_videos_cover_"..System.Encoding.base64(NPL.ToJson({projectId=obj.projectId}))
        self:upload2Qiniu(coverNameTag,obj.coverPath,function(coverUrl)
            self:upload2Qiniu(videoNameTag,obj.videoPath,function(videoUrl)
                print("xx----videoUrl:",videoUrl,"coverUrl",coverUrl)
                obj.videoUrl = videoUrl
                obj.coverUrl = coverUrl
                submitNil(obj,function()
                    _func(idx+1)
                end)
            end)
        end)
        
    end
    
    VideoRenderQueue:adminLogin(account,password,function()
        _func(1)
    end)
    
end

VideoRenderQueue:InitSingleton()