--[[
Title: keepwork.quiz
Author(s): dreamanddead
Date: 2020/7/3
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.quiz.lua");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/158/interface/api/2327
-- get
HttpWrapper.Create("keepwork.quiz.submit.a.score", "%MAIN%/online-quiz/v0/activityUserScore/project", "POST", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.submit.a.score.post")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.submit.a.score.post", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/158/interface/api/2332
-- get
HttpWrapper.Create("keepwork.quiz.submit.b.score", "%MAIN%/online-quiz/v0/activityUserScore/score", "POST", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.submit.b.score.post")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.submit.b.score.post", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/158/interface/api/5320
-- get
HttpWrapper.Create("keepwork.quiz.submit.c.score", "%MAIN%/online-quiz/v0/activityUserScore/url", "POST", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.submit.c.score.post")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.submit.c.score.post", callbackFunc); 
end
)

-- http://yapi.kp-para.cn/project/158/interface/api/2322 paracraft获取自己参加的活动
HttpWrapper.Create("keepwork.quiz.getMyActivity", "%MAIN%/online-quiz/v0/activity/myActivity", "GET", true)
-- http://yapi.kp-para.cn/project/158/interface/api/2337
HttpWrapper.Create("keepwork.quiz.activity.detail", "%MAIN%/online-quiz/v0/activity/:id", "GET", true)

-- http://yapi.kp-para.cn/project/158/interface/api/2442
-- get
HttpWrapper.Create("keepwork.quiz.checkavailable", "%MAIN%/online-quiz/v0/activity/checkAvailable", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.checkavailable.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.checkavailable.get", callbackFunc); 
end
)

-- http://yapi.kp-para.cn/project/158/interface/api/2517
-- get
HttpWrapper.Create("keepwork.quiz.getactivityid", "%MAIN%/online-quiz/v0/activity/getIdByProjectId", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.getactivityid.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.getactivityid.get", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/32/interface/api/1082
-- get
HttpWrapper.Create("keepwork.quiz.getuserworld", "%MAIN%/core/v0/worlds", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.quiz.getuserworld.get")
end,
-- Post Processor
function(self, err, msg, data)
    return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.quiz.getuserworld.get", callbackFunc); 
end
)

--http://yapi.kp-para.cn/project/158/interface/api/2382
--params  username activityid
HttpWrapper.Create("keepwork.quiz.registrate", "%MAIN%/online-quiz/v0/activityUser/registrate", "POST", true)