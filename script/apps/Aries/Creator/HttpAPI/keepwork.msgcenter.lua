--[[
Title: keepwork.msgcenter
Author(s): yangguiyi
Date: 2020/11/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.msgcenter.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/165/interface/api
--消息中心

-- 获取消息中心消息
HttpWrapper.Create("keepwork.msgcenter.all", "%MAIN%/push-manage/v0/messages/all", "GET", true)

-- 获取某个类型的消息
HttpWrapper.Create("keepwork.msgcenter.byType", "%MAIN%/push-manage/v0/messages/byType", "GET", true)

--全部类型的消息未读数
HttpWrapper.Create("keepwork.msgcenter.unReadCount", "%MAIN%/push-manage/v0/messages/unReadCount", "GET", true)

--消息置为已读
HttpWrapper.Create("keepwork.msgcenter.status", "%MAIN%/push-manage/v0/messages/status", "PUT", true)

--都某个项目是否处理
HttpWrapper.Create("keepwork.msgcenter.pro_search", "%MAIN%/core/v0/applies/search", "POST", true)
