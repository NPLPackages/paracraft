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


---------------------------
---------新增好友系统V1--------
---------------------------

-- 申请好友
-- https://yapi.kp-para.cn/project/32/interface/api/8073
HttpWrapper.Create("keepwork.friend.applyFriend", "%MAIN%/core/v0/friendApply", "POST", true)

-- 处理好友申请
-- https://yapi.kp-para.cn/project/32/interface/api/8074
HttpWrapper.Create("keepwork.friend.updateFriendApplys", "%MAIN%/core/v0/friendApply/:applyId", "PUT", true)

-- 获取好友申请列表
-- https://yapi.kp-para.cn/project/32/interface/api/8081
HttpWrapper.Create("keepwork.friend.getFriendApplys", "%MAIN%/core/v0/friendApply", "GET", true)

-- 获取好友列表
-- https://yapi.kp-para.cn/project/32/interface/api/8075
HttpWrapper.Create("keepwork.friend.friendsList", "%MAIN%/core/v0/friendships", "GET", true)

-- 更新好友信息(备注)
-- https://yapi.kp-para.cn/project/32/interface/api/8076
HttpWrapper.Create("keepwork.friend.updateFriend", "%MAIN%/core/v0/friendships/:friendId", "PUT", true)

-- 删除好友
-- https://yapi.kp-para.cn/project/32/interface/api/8077
HttpWrapper.Create("keepwork.friend.deleteFriend", "%MAIN%/core/v0/friendships/:friendId", "DELETE", true)

-- 添加黑名单
-- https://yapi.kp-para.cn/project/32/interface/api/8078
HttpWrapper.Create("keepwork.friend.addBlacklist", "%MAIN%/core/v0/friendBlacklists", "POST", true)

-- 移除黑名单
-- https://yapi.kp-para.cn/project/32/interface/api/8080
HttpWrapper.Create("keepwork.friend.removeBlacklist", "%MAIN%/core/v0/friendBlacklists/:friendId", "DELETE", true)

-- 获取黑名单列表
-- https://yapi.kp-para.cn/project/32/interface/api/8079
HttpWrapper.Create("keepwork.friend.getBlacklist", "%MAIN%/core/v0/friendBlacklists", "GET", true)

-- 举报聊天记录
-- https://yapi.kp-para.cn/project/32/interface/api/8084
HttpWrapper.Create("keepwork.chat.reportChatRecord", "%MAIN%/core/v0/users/chatReports", "POST", true)

--发送自定义消息，key == "msg"
local baseHosts = {
	STAGE = "http://socket-dev.kp-para.cn",
	RELEASE = "http://socket.kp-para.cn",
	ONLINE = "https://socket.keepwork.com"
}
local host = baseHosts[HttpWrapper.GetDevVersion()]
HttpWrapper.Create("keepwork.chat.msg", host.."/api/v0/app/msg", "POST", true)

