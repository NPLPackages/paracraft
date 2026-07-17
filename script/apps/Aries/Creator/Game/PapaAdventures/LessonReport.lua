--[[
    课堂报告
    Title: lesson report
    Version: 1.0
    Author(s): PBB
    CreateDate: 2023.11.16
    ModifyDate: 2023.11.16
    Desc: 

    use the lib:
    ------------------------------------------------------------
    local deleteProjectIds = {
        1323707,1350064,1382091,1408286,1430320,1444332,1299584,1299280,
        1347504,1381203,1408032,1429097,1299269,1386642,1323134,1353359,
        1384883,1408994,1429297,1444606,1461793,1465757,1186808,1221593,
        1264225,1186810,1202909,1221526,1236235,1299424,1204219,1206035,
        1217726,1186756,1202865,1221425,1265585,1395787,1347570,1395673,
        1187501,1224007,1394514,1193500,1148734,1231824,1231211,1325679,
        1157120,1187983,1160296,1178441,1194828,1212464,1233081,1264604,
        1323270,1365396,1381297,1394580,1413330,1417603,1464625,1444595,
        1248028,1381368,1221423,1275240,1390306,1402113,1381284,1401254,
        1381368,
    }
    local LessonReport = NPL.load("(gl)script/apps/Aries/Creator/Game/PapaAdventures/LessonReport.lua");
    LessonReport.Init("http://100.100.100.53:9090/",deleteProjectIds)
    LessonReport.ReqLessonTask()
    -------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/Assessment.lua")
local Assessment = commonlib.gettable("MyCompany.Aries.Creator.Game.Tutorial.Assessment")

local LessonReport = NPL.export()
local self = LessonReport
function LessonReport.Init(url,deleteProjectIds)
    self.baseUrl = url or "http://100.100.100.53:9090/"
    self.deleteProjectIds = deleteProjectIds or {
        1323707,1350064,1382091,1408286,1430320,1444332,1299584,1299280,
        1347504,1381203,1408032,1429097,1299269,1386642,1323134,1353359,
        1384883,1408994,1429297,1444606,1461793,1465757,1186808,1221593,
        1264225,1186810,1202909,1221526,1236235,1299424,1204219,1206035,
        1217726,1186756,1202865,1221425,1265585,1395787,1347570,1395673,
        1187501,1224007,1394514,1193500,1148734,1231824,1231211,1325679,
        1157120,1187983,1160296,1178441,1194828,1212464,1233081,1264604,
        1323270,1365396,1381297,1394580,1413330,1417603,1464625,1444595,
        1248028,1381368,1221423,1275240,1390306,1402113,1381284,1401254,
        1381368,
    }



    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  LessonReport.OnSwfLoadingClosed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  LessonReport.OnSwfLoadingClosed);

    GameLogic:Disconnect("WorldLoaded", LessonReport, LessonReport.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldLoaded", LessonReport, LessonReport.OnWorldLoaded, "UniqueConnection");

    GameLogic.GetFilters():remove_filter("enter_world_fail",LessonReport.onEnterWorldFail)
    GameLogic.GetFilters():add_filter("enter_world_fail",LessonReport.onEnterWorldFail)
end

function LessonReport.onEnterWorldFail(pid)
    if pid and tonumber(pid) ~= nil then
        self.deleteProjectIds[#self.deleteProjectIds + 1] = pid
        print("=======================")
        echo(self.deleteProjectIds)
        GameLogic.AddBBS("世界已删除，请重新进入")
        commonlib.TimerManager.SetTimeout(function()
            self.ReqLessonTask()
        end, 1000);
    end
    return pid
end

function LessonReport.ReqLessonTask()
    self.isWorldLoaded = false
    self.isSwfpageClosed = false
    local input = {};
    input.url = self.baseUrl.."getUnSetScheduleUsers";
    input.method = "POST";
    input.json=true
    input.form = {
        deleteProjectId = self.deleteProjectIds
    };
    print("start req==============")
    System.os.GetUrl(input, function(err, msg, data)
        print("ReqLessonTask=====",err)
        echo(data)
        if (err == 200) then
            self.lessonTask = data
            echo(data,true)
            GameLogic.RunCommand(string.format("/loadworld -s -auto %s",tostring(self.lessonTask.projectId)))
        elseif (err == 402) then
            self.ReqLessonTask()
        end
    end)
end

function LessonReport.GetLessonReportCode(callback)
    if not self.lessonTask then
        return
    end
    local url = self.lessonTask.reportUrl
    NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
	local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
    KeepWork.GetRawFile(url, function(err, msg, data)
        if err == 200 then
            local assessmentCode  = data
            if assessmentCode then
                NPL.DoString(assessmentCode);
                if callback and type(callback) == "function" then
                    callback()
                end
            end
        end
    end)
end

function LessonReport.PostLessonTask(report)
    if not self.lessonTask then
        return
    end
    self.leastonTask = nil
    self.isSwfpageClosed = false
    self.isWorldLoaded = false
    local data = self.lessonTask
    data.extra = {}
    data.extra.report = report
    if report then
        local url = self.baseUrl.."scheduleUser"
        local input = {}
        input.url = url
        input.method = "PUT"
        input.json=true
        input.form = data
        echo(data)
        System.os.GetUrl(input, function(err, msg, data1)
            print("PostLessonTask============",err)
            echo(data1)
            if (err == 200) then
                GameLogic.AddBBS(nil,"当前任务完成，请求下一个")
                commonlib.TimerManager.SetTimeout(function()
                    self.ReqLessonTask()
                end, 2000);
            end
        end)
    end
end

function LessonReport.OnSwfLoadingClosed()
    self.isSwfpageClosed = true
    self.StartLessonReport()
end

function LessonReport.OnWorldLoaded()
    self.isWorldLoaded = true
    self.StartLessonReport()
end

function LessonReport.StartLessonReport()
    if not self.isWorldLoaded or not self.isSwfpageClosed then
        return
    end
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
    self.GetLessonReportCode(function()
        local count, reviews, finishOptions,knowledges = Assessment:GetWorkMark(); --没有批改数据，或者普通世界
        -- echo({count, reviews, finishOptions,knowledges},true)
        if not count or not reviews or not finishOptions then
            GameLogic.AddBBS(nil,"作业批改异常")
            return 
        end
        local tasks = {}
        local isHave = false
        for k,v in pairs(finishOptions) do
            if v and v[1] then
                local index = string.match(v[1],"%d+")
                if index and tonumber(index) > 0 then
                    local key = "task"..index
                    tasks[key] = {}
                    tasks[key].status = 1
                    isHave = true
                end
            end
        end
        
        local comment = (reviews and reviews[1]) and reviews[1].line or ""
        local knowledge = knowledges
        local report = {
            comment = Mod.WorldShare.Utils.UrlEncode(comment),
            stepCount = count,
            createCount = WorldCommon.GetWorldTag("totalEditSeconds") or 0,
            buildCount = WorldCommon.GetWorldTag("totalSingleBlocks") or 0,
            codeCount = WorldCommon.GetWorldTag("editCodeLine") or 0,
            knowledge = Mod.WorldShare.Utils.UrlEncode(knowledge),
        }
        if isHave then
            report.tasks = tasks
        end
        
        echo(report)
        self.PostLessonTask(report)

    end)
end