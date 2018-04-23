--[[
Title: chat data on Map 3D system
Author(s): WangTian
Date: 2007/10/12
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/ChatData.lua");
------------------------------------------------------------

]]
if(not Map3DSystem.UI.Chat) then Map3DSystem.UI.Chat = {} end
if(not Map3DSystem.UI.Chat.ChatWnd) then Map3DSystem.UI.Chat.ChatWnd = {} end
Map3DSystem.UI.Chat.JabberClientName = "default";
Map3DSystem.UI.Chat.UserJID = "";

Map3DSystem.UI.Chat.UserStatus = {
	"在线", "接受聊天", "忙碌", "离开", "离线", -- TODO: translate
}

Map3DSystem.UI.Chat.LastConnectionTime = 0;

Map3DSystem.UI.Chat.IsInit = false;

Map3DSystem.UI.Chat.MainWndObj = nil;


Map3DSystem.UI.Chat.MainWndContactsPosX = 5;
Map3DSystem.UI.Chat.MainWndContactsPosY = 63;

Map3DSystem.UI.Chat.MainWndAdsHeight = 8; -- original value: 55

Map3DSystem.UI.Chat.ChatWnd.CreationCount = 0;

-- e.g. Map3DSystem.UI.Chat.ChatWnd.LastMessageSpeaker[self.wndName] = "andy"
Map3DSystem.UI.Chat.ChatWnd.LastMessageSpeaker = {};

-- store the <userJID, status> pairs
-- ***.JIDList.["andy@paraweb3d.com"] = "personalMSG"
Map3DSystem.UI.Chat.JIDList = {};

-- Groups store jc:GetRosterGroups() string
-- Names stroe jc:GetRosterItems() string
-- UserDetails stores each jc:GetRosterItemDetail(userJID) table
-- UserDetails["andy@paraweb3d.com"] = {}, ...
Map3DSystem.UI.Chat.RosterHistory = {
	Groups = "",
	Names = "",
	UserDetails = {},
	};

-- chatting tab structure containing the active windows icon like Windows
Map3DSystem.UI.Chat.ChattingTab = {
	-- SAMPLE: [1] = "andy@paraweb3d.com", ...
	-- SAMPLE: [2] = "lixizhi@paraweb3d.com", ...
	};



--Map3DSystem.UI.Chat.ContactList = {
	--DefaultGroup = {},
	--};

--Map3DSystem.UI.Chat.MSGPool;
--
--Map3DSystem.UI.Chat;