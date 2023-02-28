--[[
Title: keepwork.update
Author(s): hyz
Date: 2022/3/15
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.update.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--获取版本更新相关的minVersion
HttpWrapper.Create("keepwork.update.min_version", "%MAIN%/core/v0/versionControls/:appid", "GET", true)
