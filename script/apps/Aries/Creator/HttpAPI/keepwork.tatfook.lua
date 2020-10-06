--[[
Title: keepwork.tatfook
Author(s): leio
Date: 2020/9/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.tatfook.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--大富科技中秋抽奖活动

--http://yapi.kp-para.cn/project/32/interface/api/3222
-- 获取当前活动正在报名的抽奖
HttpWrapper.Create("keepwork.tatfook.lucky_load", "%MAIN%/core/v0/lotteries/current", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3227
-- 获取已结束的抽奖活动的中奖情况
HttpWrapper.Create("keepwork.tatfook.lucky_awards", "%MAIN%/core/v0/lotteries/awards", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3232
-- 用户参与抽奖
HttpWrapper.Create("keepwork.tatfook.lucky_push", "%MAIN%/core/v0/lotteries/join", "POST", true)

--http://yapi.kp-para.cn/project/32/interface/api/3237
-- 用户是否参加这次抽奖
HttpWrapper.Create("keepwork.tatfook.lucky_check", "%MAIN%/core/v0/lotteries/hasJoined", "GET", true)

--http://yapi.kp-para.cn/project/32/interface/api/3267
-- 获取活动信息
HttpWrapper.Create("keepwork.tatfook.lucky_info", "%MAIN%/core/v0/activities/nationalDay", "GET", true)

-- 获取灯谜活动信息
HttpWrapper.Create("keepwork.tatfook.lucky_lantern_info", "%MAIN%/core/v0/activities/lamp", "GET", true)