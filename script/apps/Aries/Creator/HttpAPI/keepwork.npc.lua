--[[
Title: keepwork.npc
Author(s): chenjinxian
Date: 2020/11/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.npc.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/32/interface/api/3542
-- 获取paraNpcs
HttpWrapper.Create("keepwork.npc.list", "%MAIN%/core/v0/paraConfig/paraNpcs", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3547
-- 获取paraTasks
HttpWrapper.Create("keepwork.npc.tasks", "%MAIN%/core/v0/paraConfig/paraTasks", "GET", true)

