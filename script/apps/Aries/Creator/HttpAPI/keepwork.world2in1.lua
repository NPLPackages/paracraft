--[[
Title: keepwork.world2in1
Author(s): yangguiyi
Date: 2021/6/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world2in1.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/4222
HttpWrapper.Create("keepwork.world2in1.project_list", "%MAIN%/core/v0/projects/getMyByParentId", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/4227
HttpWrapper.Create("keepwork.world2in1.select_project", "%MAIN%/core/v0/projects/selectOneInParent", "PUT", true)

-- 签名墙相关
--http://yapi.kp-para.cn/project/32/interface/api/4252
-- 新增祝福语
HttpWrapper.Create("keepwork.sign_wall.post_greeting", "%MAIN%/core/v0/summerCamp/greetings", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/4257
-- 修改祝福语
HttpWrapper.Create("keepwork.sign_wall.change_greeting", "%MAIN%/core/v0/summerCamp/greetings/:id", "PUT", true)

--http://yapi.kp-para.cn/project/32/interface/api/4262
-- 获取我的祝福语
HttpWrapper.Create("keepwork.sign_wall.get_my_greeting", "%MAIN%/core/v0/summerCamp/greetings/my", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/4267
-- 获取祝福语列表
HttpWrapper.Create("keepwork.sign_wall.get_greetings", "%MAIN%/core/v0/summerCamp/greetings", "GET", true)