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

--http://yapi.kp-para.cn/project/32/interface/api/3872
-- ai课程目录
HttpWrapper.Create("keepwork.quest_course_catalogs.get", "%MAIN%/core/v0/ai/catalogs", "GET", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3877
-- ai课程列表
HttpWrapper.Create("keepwork.quest_course.get", "%MAIN%/core/v0/ai/courses", "GET", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3882
-- 已完成的ai课程列表
HttpWrapper.Create("keepwork.quest_all_complete_course.get", "%MAIN%/core/v0/ai/learntCourseIds", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3887
-- ai课程作业
HttpWrapper.Create("keepwork.quest_work_list.get", "%MAIN%/core/v0/ai/homeworks", "GET", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3892
-- 完成ai课程
HttpWrapper.Create("keepwork.quest_complete_course.set", "%MAIN%/core/v0/ai/userAiCourse", "PUT", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3897
-- 完成ai课程作业
HttpWrapper.Create("keepwork.quest_complete_homework.set", "%MAIN%/core/v0/ai/userAiHomework", "PUT", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3902
-- 查询ai课程
HttpWrapper.Create("keepwork.quest_complete_course.get", "%MAIN%/core/v0/ai/userAiCourse", "GET", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3907
-- 查询ai作业
HttpWrapper.Create("keepwork.quest_complete_homework.get", "%MAIN%/core/v0/ai/userAiHomework", "GET", true)
