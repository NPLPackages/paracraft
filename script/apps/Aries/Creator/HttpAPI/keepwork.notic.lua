--[[
Title: keepwork.notic
Author(s): yangguiyi
Date: 2020/11/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.notic.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--公告系统

--http://yapi.kp-para.cn/project/32/interface/api/3632
-- 获取当前活动正在报名的抽奖
HttpWrapper.Create("keepwork.notic.announcements", "%MAIN%/core/v0/announcements", "GET", true)

-- http://yapi.kp-para.cn/project/32/interface/api/3637
-- -- 用户点击活动图片
HttpWrapper.Create("keepwork.notic.click", "%MAIN%/core/v0//announcements/:id/click", "POST", true)
