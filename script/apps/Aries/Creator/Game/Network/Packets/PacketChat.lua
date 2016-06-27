--[[
Title: PacketChat
Author(s): LiXizhi
Date: 2014/6/25
Desc: base class for all packets
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketChat.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local packet = Packets.PacketChat:new():Init(username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local PacketChat = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("MyCompany.Aries.Game.Network.Packets.PacketChat"));

function PacketChat:ctor()
end

-- @param chatmsg: must be a ChatMessage object or text. 
function PacketChat:Init(chatmsg, chatdata)
	if(type(chatmsg) ~= "table") then
		chatmsg = ChatMessage:new():SetText(tostring(chatmsg), chatdata);
	end
	if(chatmsg:isa(ChatMessage)) then
		self.text = chatmsg.text;
		self.data =	chatmsg.data;
		return self;
	end
end

-- Passes this Packet on to the NetHandler for processing.
function PacketChat:ProcessPacket(net_handler)
	if(net_handler.handleChat) then
		net_handler:handleChat(self);
	end
end

-- create a chat message class object from this object. 
function PacketChat:ToChatMessage()
	return ChatMessage:new():Init(self.text, self.data);
end


