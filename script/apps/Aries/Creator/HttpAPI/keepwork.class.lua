--[[
Title: keepwork.class
Author(s): chenjinxian
Date: 2020/8/9
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.class.lua");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/25/interface/api/2622
HttpWrapper.Create("keepwork.classes.get", "%MAIN%/accounting/org/classes", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2652
HttpWrapper.Create("keepwork.classroom.post", "%MAIN%/accounting/org/classroom", "POST", true)

--http://yapi.kp-para.cn/project/25/interface/api/2667
HttpWrapper.Create("keepwork.classroom.get", "%MAIN%/accounting/org/classroom", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2692
HttpWrapper.Create("keepwork.info.get", "%MAIN%/accounting/org/classroom/info", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2697
HttpWrapper.Create("keepwork.dismiss.post", "%MAIN%/accounting/org/classroom/dismiss", "POST", true)

--http://yapi.kp-para.cn/project/25/interface/api/612
HttpWrapper.Create("keepwork.userOrgInfo.get", "%MAIN%/accounting/org/userOrg", "GET", true)
