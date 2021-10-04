--[[
Title: keepwork.rank
Author(s): yangguiyi
Date: 2021/4/13
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rank.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/4102
HttpWrapper.Create("keepwork.rank.ranklist", "%MAIN%/core/v0/leaderBoardRanks", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/4232
HttpWrapper.Create("keepwork.rank.world2in1_ranklist", "%MAIN%/core/v0/projects/rankByParentId", "GET", true)

--明月课程排行榜

--获取爬塔记录
--http://yapi.kp-para.cn/project/32/interface/api/4452
HttpWrapper.Create("keepwork.moonrank.getrecord", "%MAIN%/core/v0/towerRecords", "GET", true);

--修改爬塔记录
--http://yapi.kp-para.cn/project/32/interface/api/4457
HttpWrapper.Create("keepwork.moonrank.updaterecord", "%MAIN%/core/v0/towerRecords", "PUT", true);

--修改爬塔排行榜
--http://yapi.kp-para.cn/project/32/interface/api/4462
HttpWrapper.Create("keepwork.moonrank.getrank", "%MAIN%/core/v0/towerRecords/rank", "GET", true); --exp --duration

