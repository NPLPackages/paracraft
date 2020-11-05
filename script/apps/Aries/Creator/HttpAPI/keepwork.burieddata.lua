--[[
Title: keepwork.world
Author(s): leio
Date: 2020/4/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");



--http://yapi.kp-para.cn/project/32/interface/api/2802
-- 埋点数据提交
HttpWrapper.Create("keepwork.burieddata.sendSingleBuriedData", "%MAIN%/event-gateway/events/send", "POST", true)
HttpWrapper.Create("keepwork.burieddata.sendBuriedData", "%MAIN%/event-gateway/events/bulk", "POST", true)


