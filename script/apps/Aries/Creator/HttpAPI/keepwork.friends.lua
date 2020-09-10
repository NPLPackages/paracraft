--[[
Title: keepwork.friends
Author(s): leio
Date: 2020/9/7
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.friends.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

-- 和一个好友开始聊天
--http://yapi.kp-para.cn/project/32/interface/api/3042
HttpWrapper.Create("keepwork.friends.startChatToUser", "%MAIN%/core/v0/users/chatRoom", "POST", true)

-- 获取所有好友未读消息的number和最后一条未读消息
--http://yapi.kp-para.cn/project/165/interface/api/3027
HttpWrapper.Create("keepwork.friends.getUnReadMsgCnt", "%MAIN%/push-manage/v0/chat/unReadMsgCnt", "GET", true)


-- 获取一个好友未读消息列表
--http://yapi.kp-para.cn/project/165/interface/api/3017
HttpWrapper.Create("keepwork.friends.getUnReadMsgInRoom", "%MAIN%/push-manage/v0/chat/unReadMsg", "GET", true)

-- 对一个好友 更新最后一条已读消息的标记
-- http://yapi.kp-para.cn/project/165/interface/api/3012
HttpWrapper.Create("keepwork.friends.updateLastMsgTagInRoom", "%MAIN%/push-manage/v0/chat/lastReadMsg", "PUT", true);

