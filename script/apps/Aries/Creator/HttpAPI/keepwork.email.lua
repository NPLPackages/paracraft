--
--[[
Title: keepwork.email
Author(s): pbb
Date: 2021/3/24
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.email.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 发送邮件
--http://yapi.kp-para.cn/project/165/interface/api/4002
HttpWrapper.Create("keepwork.email.sendEmail", "%MAIN%/push-manage/v0/email", "POST", true)

-- 获取我的邮件列表
--http://yapi.kp-para.cn/project/165/interface/api/4012
HttpWrapper.Create("keepwork.email.email", "%MAIN%/push-manage/v0/email", "GET", true)

-- 删除邮件
--http://yapi.kp-para.cn/project/165/interface/api/4017
HttpWrapper.Create("keepwork.email.delEmail", "%MAIN%/push-manage/v0/email", "DELETE", true)

-- 设置邮件已读
--http://yapi.kp-para.cn/project/165/interface/api/4022
HttpWrapper.Create("keepwork.email.setEmailReaded", "%MAIN%/push-manage/v0/email", "PUT", true)

-- 领取邮件奖励
--http://yapi.kp-para.cn/project/165/interface/api/4032
HttpWrapper.Create("keepwork.email.getEmailReward", "%MAIN%/push-manage/v0/email/rewards", "POST", true)

-- 打开邮件
--http://yapi.kp-para.cn/project/165/interface/api/4037
HttpWrapper.Create("keepwork.email.readEmail", "%MAIN%/push-manage/v0/email/:id", "GET", true)