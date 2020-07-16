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

--http://yapi.kp-para.cn/project/32/interface/api/cat_97
HttpWrapper.Create("keepwork.user.login", "%MAIN%/core/v0/users/login", "POST", false)

--http://yapi.kp-para.cn/project/32/interface/api/492
HttpWrapper.Create("keepwork.user.profile", "%MAIN%/core/v0/users/profile", "GET", true)


--http://yapi.kp-para.cn/project/32/interface/api/2552
HttpWrapper.Create("keepwork.user.getinfo", "%MAIN%/core/v0/users/:id/detail", "GET", true, nil,
-- PreProcessor
HttpWrapper.default_prepFunc,
-- Post Processor
HttpWrapper.default_postFunc
)
