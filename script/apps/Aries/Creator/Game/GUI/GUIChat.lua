--[[
Title: GUI chat
Author(s): LiXizhi
Date: 2014/7/1
Desc: chat system gui. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/GUIChat.lua");
local GUIChat = commonlib.gettable("MyCompany.Aries.Game.GUI.GUIChat");
GUIChat:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local GUIChat = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.GUI.GUIChat"))

function GUIChat:ctor()
	-- max concurrent message to display
	self.max_concorrent_msg = 5;
	self.next_id = 0;
end

function GUIChat:GetCycledId()
	self.next_id = (self.next_id + 1) % self.max_concorrent_msg;
	return self.next_id;
end

-- @param chatMsg: should be a ChatMessage class object or just string.
function GUIChat:PrintChatMessage(chatMsg)
	if(type(chatMsg) == "string") then
		chatMsg = ChatMessage:new():Init(chatMsg);
	end
	if(chatMsg) then
		-- TODO: print with more styles
		local text = chatMsg:ToString();
		BroadcastHelper.PushLabel({id="GUIChat"..tostring(self:GetCycledId()), label = text, max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		ChatChannel.AppendChat({ChannelIndex=ChatChannel.EnumChannels.NearBy, from=nil, words=text});
	end
end