--[[
Title: keepwork.testpaper
Author(s): hyz
Date: 2022/6/7
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.testpaper.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--湖北赛事，考试测评相关

--http://yapi.kp-para.cn/project/158/interface/api/5055
-- 用户生成试卷
HttpWrapper.Create("keepwork.exampaper.generatePaper", "%MAIN%/online-quiz/v0/examination/userTestPapers", "POST", true)

--http://yapi.kp-para.cn/project/158/interface/api/5057
-- 查询题目
HttpWrapper.Create("keepwork.exampaper.getQuestion", "%MAIN%/online-quiz/v0/examination/questions/query", "POST", true)

--http://yapi.kp-para.cn/project/158/interface/api/5059
-- 更新答案
HttpWrapper.Create("keepwork.exampaper.commitAnswer", "%MAIN%/online-quiz/v0/examination/userTestPapers/:pid/answers", "PUT", true)

--http://yapi.kp-para.cn/project/158/interface/api/5061
-- 交卷
HttpWrapper.Create("keepwork.exampaper.commitPaper", "%MAIN%/online-quiz/v0/examination/userTestPapers/:pid/finish", "POST", true)