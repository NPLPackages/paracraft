--[[
Title: keepwork.avatar
Author(s): chenjinxian
Date: 2020/2/2
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.avatar.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/3832
HttpWrapper.Create("keepwork.actors.list", "%MAIN%/core/v0/actors", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3837
HttpWrapper.Create("keepwork.actors.add", "%MAIN%/core/v0/actors", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/3842
HttpWrapper.Create("keepwork.actors.modify", "%MAIN%/core/v0/actors/:id", "PUT", true)

--http://yapi.kp-para.cn/project/32/interface/api/3852
HttpWrapper.Create("keepwork.actors.delete", "%MAIN%/core/v0/actors/:id", "DELETE", true)

