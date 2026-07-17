--[[
Title: 赛事批改的任务队列，不断从后台获取赛事批改任务
Author(s): pbb edit from videorenderqueue.lua by hyz
Date: 2024/6/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompeteAssessTasks.lua");
local CompeteAssessTasks = commonlib.gettable("MyCompany.Aries.Game.Tasks.EducateCompete.CompeteAssessTasks");
--CompeteAssessTasks:SetIgnoreTask(kpProjectId) --忽略某个世界的任务，比如当前世界批改异常或者没有批改逻辑
local competeQuestionId = {1584} --题目ID --可选，默认为空，为空时默认所有题目，否则为指定题目ID
CompeteAssessTasks:Init(GameLogic.GetWorldDirectory(),competeQuestionId)
local acc = 10
for i=1,acc do
    wait(1)
    tip((acc-i+1).."秒后开始")
end
wait(1)
tip("开始")
CompeteAssessTasks:StartRunTasks()
-------------------------------------------------------
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/FileLogUtil.lua");
local FileLogUtil = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.FileLogUtil");
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local CompeteAssessTasks = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EducateCompete.CompeteAssessTasks"));
--内部接口需要api-key验证
local API_KEYS = {
    STAGE = "c5147fb48c68bec375d6e62365264915",
    RELEASE = "a329bb7ff37114aaf6be999f1b0f0d93",
    ONLINE = "0a7ddb2debe94da94a7fb535e0ddbdce",
}

local http_env = HttpWrapper.GetDevVersion()
local api_key = API_KEYS[http_env]
local max_time = 4*60*1000 --最大单任务运行时间，超时请求下一个任务

--dev数据
local ignore_tasks = {
    {answerRecordId=26289,userId=1298,competeId=401,projectId=22886,},
    {answerRecordId=26253,userId=3244793,competeId=401,projectId=22853,},
    {answerRecordId=26268,userId=3243976,competeId=401,projectId=22858,},
    {answerRecordId=26269,userId=3243977,competeId=401,projectId=22859,},
    {answerRecordId=26281,userId=3243980,competeId=401,projectId=22882,},
    {answerRecordId=26272,userId=3243978,competeId=401,projectId=22868,},
    {answerRecordId=26296,userId=3243981,competeId=401,projectId=22889,},
    {answerRecordId=26277,userId=3243979,competeId=401,projectId=22876,},
    {answerRecordId=26705,userId=3244787,competeId=431,projectId=23091,},
    {answerRecordId=26340,userId=3243981,competeId=404,projectId=22986,},
    {answerRecordId=26488,userId=1303,competeId=403,projectId=23045,},
    {answerRecordId=26320,userId=3244793,competeId=403,projectId=22932,},
    {answerRecordId=26319,userId=3244439,competeId=403,projectId=22931,},
    {answerRecordId=26326,userId=3243976,competeId=403,projectId=22937,},
    {answerRecordId=26501,userId=3244314,competeId=415,projectId=23051,},
    {answerRecordId=26710,userId=3244147,competeId=414,projectId=23151,},
    {answerRecordId=26231,userId=1298,competeId=399,projectId=22851,},
    {answerRecordId=25416,userId=1298,competeId=272,projectId=22347,},
    {answerRecordId=26260,projectId=22855,id=4,competeId=401,userId=3243976,},
    {answerRecordId=26698,projectId=23088,id=2851,competeId=430,userId=3244787,},
    {answerRecordId=26717,projectId=23165,id=49451,competeId=430,userId=1305,},
    {answerRecordId=26718,projectId=23166,id=49452,competeId=430,userId=1304,},
    {answerRecordId=26719,projectId=23168,id=49453,competeId=430,userId=1306,},
    {answerRecordId=26720,projectId=23169,id=49454,competeId=430,userId=42399,},
    {answerRecordId=26721,projectId=23171,id=49455,competeId=430,userId=3243976,},
}

--https://yapi.kp-para.cn/project/2666/interface/api/8006
--客户端获取所有未运行/运行未完成fork世界作品的用户信息
HttpWrapper.Create("keepwork.compete.reqCompeteForkProjectTask", "%MAIN%/paracraft-compete/v0/internal/competes/retryForkProjectTask/query", "POST", true)

--https://yapi.kp-para.cn/project/2666/interface/api/8015
--客户端重新上报所有未运行/运行未完成fork世界作品的用户的得分
HttpWrapper.Create("keepwork.compete.postCompeteForkProjectScore", "%MAIN%/paracraft-compete/v0/internal/competes/retryForkProjectTask", "POST", true)

local _fileLog = FileLogUtil:new({filename = "log_compete_assess_queue.txt"})

CompeteAssessTasks._enterWorldAcc = 0; --进入世界次数
CompeteAssessTasks._competeAssessNum = 0; --批改赛事世界的次数
CompeteAssessTasks._startClock = os.clock(); --开始任务的起始时间

function CompeteAssessTasks:SetIgnoreTask(kpProjectId)
    if type(kpProjectId) == "number" then
        local ignore_task = {answerRecordId=26289,userId=1298,competeId=401,projectId=kpProjectId,} 
        ignore_tasks[#ignore_tasks+1] = ignore_task
    elseif type(kpProjectId) == "table" then
        for _,v in ipairs(kpProjectId) do
            local ignore_task = {answerRecordId=26289,userId=1298,competeId=401,projectId=v,} 
            ignore_tasks[#ignore_tasks+1] = ignore_task
        end
    end
end

function CompeteAssessTasks:UserLogin(username,password,callback)
    Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10)
    

    local function HandleLogined(bSucceed, message)
        Mod.WorldShare.MsgBox:Close()
        if callback and type(callback) == 'function' then
            callback(bSucceed)
        end
    end

    KeepworkServiceSession:Login(
        username,
        password,
        function(response, err)
            if err ~= 200 or not response then
                Mod.WorldShare.MsgBox:Close()
                if callback and type(callback) == 'function' then
                    callback(false)
                end

                return false
            end

            response.autoLogin = autoLogin
            response.rememberMe = rememberMe
            response.password = password

            KeepworkServiceSession:LoginResponse(response, err, HandleLogined)
        end
    )
end

function CompeteAssessTasks:Init(testWorldPath,competeQuestionId)
    self.assess_compete_question_ids = {}
    if type(competeQuestionId) == "number" then
        self.assess_compete_question_ids[#self.assess_compete_question_ids+1] = competeQuestionId
    elseif type(competeQuestionId) == "table" then
        for i,v in ipairs(competeQuestionId) do
            self.assess_compete_question_ids[#self.assess_compete_question_ids+1] = v
        end
    end
    CompeteAssessTasks.testWorldPath = testWorldPath --用于批改赛事世界的辅助世界，重启的时候用
    if self.is_inited then
        return
    end
    self:InitIgnoreTasks()
    self.is_inited = true
    if CompeteAssessTasks._timer then
        CompeteAssessTasks._timer:Change()
        CompeteAssessTasks._timer = nil
    end
    CompeteAssessTasks._timer = commonlib.Timer:new({callbackFunc=function()
        if not self._isRuning then 
            return
        end
        if CompeteAssessTasks:CheckRestartApp() then
            return
        end
        if self._curTask==nil then
            self:ReqTask()
        end
    end})
    CompeteAssessTasks._timer:Change(0,15*1000)
    
    CompeteAssessTasks._enterWorldAcc = 0; --进入世界次数
    CompeteAssessTasks._competeAssessNum = 0; --批改赛事世界次数
    CompeteAssessTasks._startClock = os.clock(); --开始任务的起始时间
end

function CompeteAssessTasks:InitIgnoreTasks()
    self.ignore_tasks = {}
    for _,v in ipairs(ignore_tasks) do
        self.ignore_tasks[v.projectId] = v
    end
end

function CompeteAssessTasks:IsIgnoreTask(task)
    return (task and self.ignore_tasks[task.projectId]) and true or false
end

--进入世界次数、批改赛事世界数量、或者运行时间超过限制后就重启应用
function CompeteAssessTasks:CheckRestartApp()
    local MAX_ENTER_WORLD = 30
    local MAX_VIDEO_NUM = 10
    local MAX_TIME = max_time * 1.5 * 10 -- 最大任务运行时间，防止客户端卡住，大概一个小时重启
    repeat
        if CompeteAssessTasks._enterWorldAcc>=MAX_ENTER_WORLD then
            _fileLog:output_video_log(nil, "restart", "CompeteAssessTasks", "进世界次数超限,去重启,_enterWorldAcc:%s\n\n",CompeteAssessTasks._enterWorldAcc);
            break
        end
        if CompeteAssessTasks._competeAssessNum>=MAX_VIDEO_NUM then
            _fileLog:output_video_log(nil, "restart", "CompeteAssessTasks", "批改赛事数量超限,去重启,_competeAssessNum:%s\n\n",CompeteAssessTasks._competeAssessNum);
            break
        end
        local _usedTime = os.clock() - CompeteAssessTasks._startClock;--运行时间
        if _usedTime>MAX_TIME then
            _fileLog:output_video_log(nil, "restart", "CompeteAssessTasks", "运行时间超限,去重启,_usedTime:%s\n\n",_usedTime);
            break
        end
        if CompeteAssessTasks._errorOccur then
            _fileLog:output_video_log(nil, "error|restart", "CompeteAssessTasks", "发生异常，去重启:%s\n\n",tostring(CompeteAssessTasks._errorOccur));
            break
        end
        return false
    until true
    
    
    local cmd = [[
		start %s\paraengineclient.exe world="%s" mc="true" IsDevEnv="true" isDevMode="true"
	]]
    cmd = string.format(cmd,ParaIO.GetWritablePath(),CompeteAssessTasks.testWorldPath)
	os.execute(cmd)
    ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()
	ParaGlobal.ExitApp()

    commonlib.TimerManager.SetTimeout(function()
        ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
        ParaGlobal.ExitApp()
    end,2000)

    return true
end

function CompeteAssessTasks:OnWorldLoaded()
    GameLogic:Disconnect("WorldLoaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldLoaded, "UniqueConnection");

    GameLogic:Disconnect("WorldUnloaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldUnloaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldUnloaded, "UniqueConnection");
    
    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "OnWorldLoaded:projectId:%s,task.pid:%s",GameLogic.options:GetProjectId(),(CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil"));
    
    if self._curTask then
        commonlib.TimerManager.SetTimeout(function()
            CompeteAssessTasks._isNewWorldLoaded = true

            if CompeteAssessTasks._timeoutHandler then
                CompeteAssessTasks._timeoutHandler:Change()
                CompeteAssessTasks._timeoutHandler = nil
            end
            if CompeteAssessTasks._isLoadingBarClosed and not CompeteAssessTasks._isCompeteAssessStarted then
                CompeteAssessTasks:StartCompeteAssess()
            end
        end,2*1000)
    end
    GameLogic.GetFilters():remove_filter("enter_world_fail",CompeteAssessTasks.onEnterWorldFail)

    CompeteAssessTasks._enterWorldAcc = CompeteAssessTasks._enterWorldAcc + 1
    CompeteAssessTasks:CheckRestartApp()
end

function CompeteAssessTasks.onSwf_loading_barClosed()
    -- print("=========onSwf_loading_barClosed")
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  CompeteAssessTasks.onSwf_loading_barClosed);
    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "onSwf_loading_barClosed:projectId:%s,task.pid:%s",GameLogic.options:GetProjectId(),CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil");
    GameLogic.GetCodeGlobal():RegisterTextEvent("CompeteAssessFinished", function(args,msg)
        local msg = msg.msg
        local score,isUp
        if type(msg) == "string" then
            msg = commonlib.LoadTableFromString(msg);
        end
        score,isUp = msg.score,msg.isUp
        CompeteAssessTasks:OnPostAssessTask(score)
    end)
    commonlib.TimerManager.SetTimeout(function()
        CompeteAssessTasks._isLoadingBarClosed = true

        if CompeteAssessTasks._timeoutHandler then
            CompeteAssessTasks._timeoutHandler:Change()
            CompeteAssessTasks._timeoutHandler = nil
        end

        if CompeteAssessTasks._isNewWorldLoaded and not CompeteAssessTasks._isCompeteAssessStarted then
            CompeteAssessTasks:StartCompeteAssess()
        end
    end,2*1000)
    
    return true
end

function CompeteAssessTasks:OnWorldUnloaded()
    GameLogic:Disconnect("WorldUnloaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldUnloaded, "UniqueConnection");
    
end

-- {answerRecordId=26698,projectId=23088,id=2851,competeId=430,userId=3244787,}
function CompeteAssessTasks:OnPostAssessTask(params)
    print("OnPostAssessTask============")
    echo(params,true)
    if not self._curTask then
        _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "OnPostAssessTask:projectId:%s, task err:任务为空",CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil");
        CompeteAssessTasks._isInAssessing = nil
        self:ReqNextAndSubmitNil()
        return
    end
    if params and type(params) == "table" then
        local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
        KeepworkServiceProject:GetProject(self._curTask.projectId, function(project, err)
            if err ~= 200 then
                CompeteAssessTasks._isInAssessing = nil
                fileLog:output_video_log(nil, "error", "CompeteAssessTasks", "OnPostAssessTask:projectId:%s, 获取项目信息失败:%s",self._curTask.projectId,err);
                self:ReqNextAndSubmitNil()
                return
            end
            local custom_answer_score = {}
            local score = 0
            local num = #params
            if num > 0 then
                for i = 1,num do
                    local item = params[i]
                    if item and type(item) == "table" then
                        custom_answer_score[#custom_answer_score + 1] = item
                        if score == 0 and item.isScore == true then
                            score = tonumber(item.value or 0)
                        end
                    end
                end
            else
                custom_answer_score = params
            end

            local extra = {}
            extra.customFields = custom_answer_score
            local answer = {}
            answer.item = {
                {
                    submited = true,
                    projectId = self._curTask.projectId,
                }
            }
            local commitId = (project and project.world) and project.world.commitId or ""
            local answerRecords = {
                answerRecordId = self._curTask.answerRecordId,
                answer = answer,
                projectId = self._curTask.projectId,
                commitId = commitId,
                score = score,
                extra = extra,
            }
            print("postCompeteForkProjectScore ====answerRecords==========")
            echo(answerRecords,true)
            keepwork.compete.postCompeteForkProjectScore({
                answerRecords = {answerRecords},
                headers = {
                    ["x-api-key"] = api_key,
                }
            },function(err,msg,data)
                print("postCompeteForkProjectScore=========", err)
                echo(data,true)
                CompeteAssessTasks._isInAssessing = nil
                if err == 200 then
                    --赛事成绩上报成功
                    CompeteAssessTasks._competeAssessNum = CompeteAssessTasks._competeAssessNum + 1
                    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "OnPostAssessTask:projectId:%s, 赛事成绩上报成功,score:%s",CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil",score);
                    GameLogic.AddBBS(nil,L"赛事成绩上报成功")
                    commonlib.TimerManager.SetTimeout(function()
                        self:NextTask()
                    end,2000)
                    return
                end
                GameLogic.AddBBS(nil,L"赛事成绩上报异常，错误码为："..(err or 0))
                commonlib.TimerManager.SetTimeout(function()
                    self:NextTask()
                end,2000)
                _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "OnPostAssessTask:projectId:%s, task err:%s",CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil",err);
            end)
        end)
        return 
    end
    CompeteAssessTasks._isInAssessing = nil
    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "OnPostAssessTask:projectId:%s, task err:%s",CompeteAssessTasks._curTask and CompeteAssessTasks._curTask.projectId or "nil",err);
    GameLogic.AddBBS(nil,L"赛事成绩上报异常，批改结果数据异常")
    commonlib.TimerManager.SetTimeout(function()
        self:NextTask()
    end,2000)
end

function CompeteAssessTasks:StartRunTasks()
    self:ReqTask()
    self._isRuning = true
    CompeteAssessTasks._enterWorldAcc = 0; --进入世界次数
    CompeteAssessTasks._competeAssessNum = 0; --批改赛事成绩次数
    CompeteAssessTasks._startClock = os.clock(); --开始任务的起始时间
    _fileLog:output_video_log(nil, "StartRunTasks", "CompeteAssessTasks", "\n\n>>>>>>>>>>>>>>>开始跑任务>>>>>>>>>>>>>\n\n");
end

function CompeteAssessTasks:PauseTasks()
    self._isRuning = false

end

--从服务端获取一个赛事批改任务
function CompeteAssessTasks:ReqTask()
    if self._curTask~=nil then
        local _now = os.time()
        if self._curTask.timeStramp and _now-self._curTask.timeStramp>2*60 then --超时了，可能是意外中断了，兼容一下
        else
            _fileLog:output_video_log(nil, "warning", "CompeteAssessTasks", "ReqTask 重复任务 gotoWorld:%s,taskId:%s",self._curTask.projectId,self._curTask.id);
            self:gotoWorld(self._curTask.projectId)
            return
        end
    end
    local params = {
        headers = {
            ["x-api-key"] = api_key,
        }
    }
    if self.assess_compete_question_ids and #self.assess_compete_question_ids > 0 then
        params.ids = self.assess_compete_question_ids
    end

    keepwork.compete.reqCompeteForkProjectTask(params,function(err,msg,data)
        if err ~= 200 then
            _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "keepwork.reqCompeteForkProjectTask.task失败,要去重新获取下一个任务. err:"..(err or "nil"));
            commonlib.TimerManager.SetTimeout(function()
                if self._isRuning then
                    self:ReqTask()
                end
            end,2*1000)
            return
        end
        local task = data and data[1]
        if task==nil then
            _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "当前没有批改任务了");
            BroadcastHelper.GetSingletonTipsStack():Show(true)
            GameLogic.AddBBS(nil,L"当前没有赛事批改任务了",2000)
            return
        end
        self._curTask = task
        if self:IsIgnoreTask(task) then
            _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "当前任务被忽略:%s",tostring(task.projectId));
            self:ReqNextAndSubmitNil()
            return
        end
        
        _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "ReqTask resp,projectId:%s,answerRecordId:%s",self._curTask.projectId,self._curTask.answerRecordId);
        echo(task)
        self:gotoWorld(self._curTask.projectId)
    end)
end

function CompeteAssessTasks:gotoWorld(projectId)
    if CompeteAssessTasks._isInAssessing then
        _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "projectId:%s,CompeteAssessTasks._isInAssessing：%s",projectId,tostring(CompeteAssessTasks._isInAssessing));
        return
    end
    BroadcastHelper.GetSingletonTipsStack():Show(true)
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  CompeteAssessTasks.onSwf_loading_barClosed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  CompeteAssessTasks.onSwf_loading_barClosed);

    GameLogic.GetFilters():remove_filter("enter_world_fail",CompeteAssessTasks.onEnterWorldFail)
    GameLogic.GetFilters():add_filter("enter_world_fail",CompeteAssessTasks.onEnterWorldFail)

    GameLogic:Disconnect("WorldLoaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", CompeteAssessTasks, CompeteAssessTasks.OnWorldLoaded, "UniqueConnection");

    CompeteAssessTasks._isNewWorldLoaded = false
    CompeteAssessTasks._isLoadingBarClosed = false
    CompeteAssessTasks._isCompeteAssessStarted = false
    Mod.WorldShare.Store:Set('user/token',"test_compete_assessment_token")
    Mod.WorldShare.Store:Set('user/bLoginSuccessed',true)
    local cmd = string.format("/loadworld -s -auto -lesson %s",projectId)
    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "gotoWorld:"..(cmd or "nil"));
    GameLogic.RunCommand(cmd)
    if CompeteAssessTasks._timeoutHandler then
        CompeteAssessTasks._timeoutHandler:Change()
        CompeteAssessTasks._timeoutHandler = nil
    end
    --进世界超时
    CompeteAssessTasks._timeoutHandler = commonlib.TimerManager.SetTimeout(function()
        _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "gotoWorld超时，请求下一个");
        CompeteAssessTasks:ReqNextAndSubmitNil()
    end,2*60*1000)
end

function CompeteAssessTasks.onEnterWorldFail(...)
    GameLogic.GetFilters():remove_filter("enter_world_fail",CompeteAssessTasks.onEnterWorldFail)
    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "进入世界失败 下一个");
    
    CompeteAssessTasks:ReqNextAndSubmitNil()
    return ...
end

function CompeteAssessTasks:ReqNextAndSubmitNil()
    if self._curTask then
        CompeteAssessTasks:NextTask()
    end
end

function CompeteAssessTasks:StartCompeteAssess()
    if self._curTask.projectId~=GameLogic.options:GetProjectId() then
        commonlib.TimerManager.SetTimeout(function()
            if self._curTask.projectId~=GameLogic.options:GetProjectId() then
                _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "----type(self._curTask.projectId)=%s,type(GameLogic.options:GetProjectId())=%s",type(self._curTask.projectId),type(GameLogic.options:GetProjectId()));
                CompeteAssessTasks._errorOccur = string.format("StartCompeteAssess 世界id对不上,有问题。_curTask.projectId,%s,GameLogic.options:GetProjectId():%s",self._curTask.projectId,GameLogic.options:GetProjectId())
                self:CheckRestartApp()
            else
                CompeteAssessTasks:StartCompeteAssess()
            end
        end,10*1000)
        return
    end
    
    CompeteAssessTasks._isCompeteAssessStarted = true
    if CompeteAssessTasks._timeoutHandler then
        CompeteAssessTasks._timeoutHandler:Change()
        CompeteAssessTasks._timeoutHandler = nil
    end

    _fileLog:output_video_log(nil, "info", "CompeteAssessTasks", "StartCompeteAssess,projectId:%s",GameLogic.options:GetProjectId());

    
    --赛事世界批改超时
    CompeteAssessTasks._timeoutHandler = commonlib.TimerManager.SetTimeout(function()
        _fileLog:output_video_log(nil, "warn", "CompeteAssessTasks", "StartCompeteAssess超时，");
        CompeteAssessTasks._errorOccur = "StartCompeteAssess超时，重启"
        self:CheckRestartApp()
    end,(max_time + 2000))

    BroadcastHelper.GetSingletonTipsStack():Show(false)
    local _beginTime = os.clock()

    CompeteAssessTasks._isInAssessing = true

    -- 发送赛事开始批改事件
    GameLogic.RunCommand('/sendevent edu_compete_assess_start')

end

function CompeteAssessTasks:NextTask()
    if CompeteAssessTasks:CheckRestartApp() then
        return
    end
    self._curTask = nil
    if self._isRuning then
        self:ReqTask()
    end
end


CompeteAssessTasks:InitSingleton()