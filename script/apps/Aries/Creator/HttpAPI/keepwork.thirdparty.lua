--[[
Title: keepwork.thirdparty
Author(s): pbb
Date: 2020/12/8
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.thirdparty.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--麦思星球
HttpWrapper.Create("keepwork.maisi.oauth", "%MAIN%/core/v0/oauth_users/maisi", "POST", false)