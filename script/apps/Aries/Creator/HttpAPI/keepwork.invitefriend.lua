--[[
Title: keepwork.invitefriend
Author(s): pbb
Date: 2021/3/9
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.invitefriend.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 生成用户邀请码
--http://yapi.kp-para.cn/project/32/interface/api/3937
HttpWrapper.Create("keepwork.invitefriend.invitationCode", "%MAIN%/core/v0/users/invitationCode", "POST", true)



-- 获取用户邀请的信息
--http://yapi.kp-para.cn/project/32/interface/api/3942
HttpWrapper.Create("keepwork.invitefriend.invitationInfo", "%MAIN%/core/v0/users/invitationInfo", "GET", true)



-- 使用用户邀请码
--http://yapi.kp-para.cn/project/32/interface/api/3952
HttpWrapper.Create("keepwork.invitefriend.useInvitationCode", "%MAIN%/core/v0/users/useInvitationCode", "POST", true)



-- 用户兑换邀新奖励
--http://yapi.kp-para.cn/project/32/interface/api/3957
HttpWrapper.Create("keepwork.invitefriend.inviteReward", "%MAIN%/core/v0/users/inviteReward", "POST", true)