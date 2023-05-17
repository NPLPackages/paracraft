--[[
    author:{pbb}
    time:2023-03-11 09:17:55
    uselib:
        local AssessmentQueue = NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/AssessmentQueue.lua")
]]
--https://keepwork.com/deng123456/assessment/114362
--https://keepwork.com/deng123456/assessment/113623
NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/Assessment.lua")
local Assessment = commonlib.gettable("MyCompany.Aries.Creator.Game.Tutorial.Assessment")
NPL.load("(gl)script/ide/math/StringUtil.lua");
local StringUtil = commonlib.gettable("mathlib.StringUtil");
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
local AssessmentQueue = NPL.export()
local self = AssessmentQueue
local AssessmentData = {}
function AssessmentQueue.Init(courseId,strProjects)
    self.courseId = courseId
    self.strProjects = strProjects
    self.assessmentCode = ""
    self.assessmentWorlds = {}
    self.assessmentIndex = 0
    echo(self.courseId)
    echo(self.strProjects)
    print("init==================")
    AssessmentQueue.RegisterEvent()
    AssessmentQueue.InitData()
end

function AssessmentQueue.InitData()
    if self.strProjects then
        self.assessmentWorlds = commonlib.split(self.strProjects,",") or {}
        for k,v in pairs(self.assessmentWorlds) do
            v = tonumber(StringUtil.trim(v))
        end
    end
    if self.courseId then
        local baseUrl = "https://keepwork.com/deng123456/assessment/"
        baseUrl = baseUrl .. self.courseId
        KeepWork.GetRawFile(baseUrl, function(err, msg, data)
            if err == 200 then
                self.assessmentCode  = data
                AssessmentQueue.BeginCurAssessment()
            end
        end)
    end
end

function AssessmentQueue.RegisterEvent()
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", AssessmentQueue.OnLoadingProgressFinish)
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", AssessmentQueue.OnLoadingProgressFinish);

    GameLogic:Disconnect("WorldLoaded", AssessmentQueue, AssessmentQueue.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", AssessmentQueue, AssessmentQueue.OnWorldLoaded, "UniqueConnection");

    GameLogic:Disconnect("WorldUnloaded", AssessmentQueue, AssessmentQueue.OnWorldUnload, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", AssessmentQueue, AssessmentQueue.OnWorldUnload, "UniqueConnection");
end

function AssessmentQueue.OnWorldLoaded() 
    AssessmentQueue.RegisterEvent()
    AssessmentQueue.IsWorldLoaded = true
    AssessmentQueue.StartCheckAssessment()
end

function AssessmentQueue.OnWorldUnload()
    self.IsWorldLoaded = false
    self.IsSwfLoadingFinished = false
    GameLogic:Disconnect("WorldUnloaded", AssessmentQueue, AssessmentQueue.OnWorldUnload, "UniqueConnection");
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", AssessmentQueue.OnLoadingProgressFinish)
end

function AssessmentQueue.OnLoadingProgressFinish()
    AssessmentQueue.IsSwfLoadingFinished = true
    AssessmentQueue.StartCheckAssessment()

    return true
end

function AssessmentQueue.BeginCurAssessment()
    self.assessmentIndex = self.assessmentIndex + 1
    local worldId = self.assessmentWorlds[self.assessmentIndex]
    if worldId and tonumber(worldId) > 0 then
        local commandStr = string.format("/loadworld -s -auto %s", worldId)
        GameLogic.RunCommand(commandStr)
    end
end

function AssessmentQueue.IsFinishQueue()
    return self.assessmentWorlds and self.assessmentIndex and self.assessmentIndex >= #self.assessmentWorlds
end

function AssessmentQueue.FinishCurAssessment()
    local count,reviews = Assessment:GetWorkMark()
    if self.assData then
        self.assData.count = count
        self.assData.reviews = reviews
        AssessmentData[#AssessmentData + 1] = commonlib.copy(self.assData)
        self.assData = nil
    end
    print("AssessmentQueue.FinishCurAssessment=============",self.assessmentIndex,#self.assessmentWorlds,self.IsFinishQueue())
    if self.IsFinishQueue() then
        --评分结束了
        GameLogic.AddBBS(nil,"评分结束了")
        echo(AssessmentData,true)
        return
    end
    self.assessmentIndex = self.assessmentIndex + 1
    local worldId = self.assessmentWorlds[self.assessmentIndex]
    if worldId and tonumber(worldId) > 0 then
        local commandStr = string.format("/loadworld -s -auto %s", worldId)
        GameLogic.RunCommand(commandStr)
    end
end

function AssessmentQueue.StartCheckAssessment()
    if not self.IsWorldLoaded or not self.IsSwfLoadingFinished then
        return 
    end
    if self.assessmentWorlds and  self.assessmentIndex <= #self.assessmentWorlds then
        local worldId = self.assessmentWorlds[self.assessmentIndex]
        if worldId and tonumber(worldId) > 0 then
            keepwork.project.get({
                router_params = {
                    id = tonumber(worldId),
                },
            },function(err,msg,data)
                if err == 200 then
                    local assData = {}
                    local tag = data.tag or {}
                    assData.clientversion = tag.clientversion or "0.0.0"
                    assData.name = data.name or "default_name"
                    assData.username = data.username
                    assData.userId = data.userId
                    assData.fileSize = data.world and data.world.fileSize or 0
                    self.assData = assData
                    if self.assessmentCode then
                        NPL.DoString(self.assessmentCode);
                    end
                else
                    self.FinishCurAssessment()
                end
            end)
        end
    end
end
-- /checkworldassessment 114362 1114556,79969,45625,14568,1184365,96325,69542,66625,78956






