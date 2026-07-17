--[[
Title: educate Competition api
Author(s): pbb
Date: 2023/6/9
Desc: 
Use Lib:
-------------------------------------------------------
local CompetitionApi =  NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionApi.lua")
CompetitionApi.InitCompeteApi()
-------------------------------------------------------
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local CompetitionApi = NPL.export()


--[[
    HttpWrapper.Create("keepwork.burieddata.sendSingleBuriedData", "%MAIN%/event-gateway/events/send", "POST", true)
]]
--http://api-dev.kp-para.cn/ "%MAIN%/push-manage/v0/email/:id"
function CompetitionApi.InitCompeteApi()
    if not CompetitionApi.InitApi then

        --获取临时存储token
        --http://yapi.kp-para.cn/project/151/interface/api/4512
        -- HttpWrapper.Create("keepwork.shareBlock.getToken", "%MAIN%/ts-storage/files/:id/tokenByPublicTemporary", "GET", true)

        --提交比赛答题记录，上报单选题成绩
        --http://yapi.kp-para.cn/project/2666/interface/api/6806
        HttpWrapper.Create("keepwork.compete.submitChoiceRecord", "%MAIN%/paracraft-compete/v0/answerRecords", "POST", true)

        --提交比赛答题记录，上报创作题url
        --http://yapi.kp-para.cn/project/2666/interface/api/6794
        HttpWrapper.Create("keepwork.compete.submitCreateRecord", "%MAIN%/paracraft-compete/v0/workSubmitRecords", "POST", true)

        --上面的接口暂时是废弃的

        --获取比赛内容接口
        --http://yapi.kp-para.cn/project/2666/interface/api/6682
        HttpWrapper.Create("keepwork.compete.getCompeteInfo", "%MAIN%/paracraft-compete/v0/competeContent/:id", "GET", true)

         --添加答卷记录，上报此次答题记录，一般进入世界或者打开试卷就上报
        --http://yapi.kp-para.cn/project/2666/interface/api/6790
        HttpWrapper.Create("keepwork.compete.postCompeteRecord", "%MAIN%/paracraft-compete/v0/answerSheetRecords", "POST", true)

        --修改答卷状态
        --http://yapi.kp-para.cn/project/2666/interface/api/6786
        HttpWrapper.Create("keepwork.compete.updateCompeteRecord", "%MAIN%/paracraft-compete/v0/answerSheetRecords/:id", "PUT", true)

        --用户总的提交答卷
        --http://yapi.kp-para.cn/project/2666/interface/api/6786
        HttpWrapper.Create("keepwork.compete.submitTotalRecord", "%MAIN%/paracraft-compete/v0/enrolments/:id", "PUT", true)

        --我的比赛列表
        --http://yapi.kp-para.cn/project/2666/interface/api/6750
        HttpWrapper.Create("keepwork.compete.mineRaces", "%MAIN%/paracraft-compete/v0/enrolments/competes/query", "POST", true)

        --客户端获取试卷
        --http://yapi.kp-para.cn/project/2666/interface/api/7325
        HttpWrapper.Create("keepwork.compete.getCompetePaper", "%MAIN%/paracraft-compete/v0/competePapers/:id/clientPaper", "GET", true)

        --客户端上报成绩
        --http://yapi.kp-para.cn/project/2666/interface/api/7301
        HttpWrapper.Create("keepwork.compete.submitAnswer", "%MAIN%/paracraft-compete/v0/answerRecords/bulkUpsert", "POST", true)

        --获取试卷
        --https://yapi.kp-para.cn/project/2666/interface/api/7223
        HttpWrapper.Create("keepwork.compete.getCompetePaperList", "%MAIN%/paracraft-compete/v0/competePapers/:id", "GET", true)

        --重新上报答题记录,一般是从浏览器拉起客户端压缩世界后上传
        --https://yapi.kp-para.cn/project/2666/interface/api/8047
        HttpWrapper.Create("keepwork.compete.reSubmitAnswerRecord", "%MAIN%/paracraft-compete/v0/answerRecords/retryUpsert", "PUT", true)

        --上报单个题目的答题记录,用来记录单个题目的答题开始时间或者其他数据
        --https://yapi.kp-para.cn/project/2666/interface/api/8052
        HttpWrapper.Create("keepwork.compete.postSingleAnswerRecord", "%MAIN%/paracraft-compete/v0/answerRecords/initLog", "POST", true)

        CompetitionApi.InitApi = true
    end
end

function CompetitionApi.GetCompeteInfo(params,callback)
    keepwork.compete.getCompeteInfo(params,callback)
end

function CompetitionApi.PostCompeteRecord(params,callback) --上报答卷记录
    keepwork.compete.postCompeteRecord(params,callback)
end

function CompetitionApi.UpdateCompeteRecord(params,callback) --修改答卷记录
    keepwork.compete.updateCompeteRecord(params,callback)
end

function CompetitionApi.SubmitTotalRecord(params,callback) --总成绩提交
    keepwork.compete.submitTotalRecord(params,callback)
end

--新增接口
function CompetitionApi.GetMineRaceList(params,callback)
    keepwork.compete.mineRaces(params,callback)
end

function CompetitionApi.GetRacePaperList(params,callback)
    keepwork.compete.getCompetePaper(params,callback)
end

function CompetitionApi.SubmitAnswerRecord(params,callback)
    keepwork.compete.submitAnswer(params,callback)
end

function CompetitionApi.GetProjectInfo(params,callback)
    keepwork.project.get(params,callback)
end

function CompetitionApi.GetCompetePaperList(params,callback)
    keepwork.compete.getCompetePaperList(params,callback)
end

function CompetitionApi.ReSubmitAnswerRecord(params,callback)
    keepwork.compete.reSubmitAnswerRecord(params,callback)
end

function CompetitionApi.PostSingleAnswerRecord(params,callback)
    keepwork.compete.postSingleAnswerRecord(params,callback)
end