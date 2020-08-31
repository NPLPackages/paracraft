
--[[
Title: keepwork.project
Author(s): wxa
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.project.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- https://api.keepwork.com/core/v0/projects?userId=3
HttpWrapper.Create("keepwork.project.list", "%MAIN%/core/v0/projects", "GET", true);