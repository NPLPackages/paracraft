--[[
Title: keepwork.quest
Author(s): leio
Date: 2020/12/8
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.quest.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/3662
-- 获取用户任务进度记录
--[[
return {
  {
    createdAt="2020-12-09T09:25:14.000Z",
    data={
      quest_targets="[{\"value\":1,\"id\":\"60003_1\"},{\"value\":\"ABC\",\"id\":\"60003_2\"},{\"value\":5,\"id\":\"60003_3\"}]" 
    },
    gsId=60003,
    id=1,
    updatedAt="2020-12-09T09:44:32.000Z",
    userId=572 
  } 
}
--]]
HttpWrapper.Create("keepwork.questitem.list", "%MAIN%/core/v0/users/taskRecords", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3657
-- 用户任务进度记录
HttpWrapper.Create("keepwork.questitem.save", "%MAIN%/core/v0/users/taskRecords", "POST", true)

