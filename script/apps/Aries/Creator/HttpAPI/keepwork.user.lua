--[[
Title: keepwork.user
Author(s): leio
Date: 2020/4/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");

--http://yapi.kp-para.cn/project/32/interface/api/cat_97
HttpWrapper.Create("keepwork.user.login", "%MAIN%/core/v0/users/login", "POST", false, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.user.login.post")
end,
-- Post Processor
function(self, err, msg, data)
     return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.user.login.post", callbackFunc); 
end)

--http://yapi.kp-para.cn/project/32/interface/api/492
HttpWrapper.Create("keepwork.user.profile", "%MAIN%/core/v0/users/profile", "GET", true, nil,
-- PreProcessor
function(self, inputParams, callbackFunc, option)
   return HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, "keepwork.user.profile.get")
end,
-- Post Processor
function(self, err, msg, data)
     return HttpWrapper.default_postFunc(self, err, msg, data, "keepwork.user.profile.get", callbackFunc); 
end)
