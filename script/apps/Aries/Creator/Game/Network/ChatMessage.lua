--[[
Title: ChatMessage
Author(s): LiXizhi
Date: 2014/6/30
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ChatMessage.lua");
local ChatMessage = commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage");
local char_msg = ChatMessage:new():Init("any string", any_data);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");

local ChatMessage = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.ChatMessage"));

function ChatMessage:ctor()
end

function ChatMessage:Init(text, data)
	self:SetText(text, data);
	return self;
end

function ChatMessage:SetText(text, data)
	self.text = text;
	self.data = data;
	return self;
end

function ChatMessage:ToString()
	local text = "";
	if(self.text) then
		text = self.text;
		if(self.data) then
			text = text..commonlib.serialize_compact(self.data);
		end
	end
	return text;
end


