--[[
Title: Chat chunks
Author(s): LiXizhi
Date: 2025/1/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/ChatChunks.lua");
local ChatChunks = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.ChatChunks");
local chunk = ChatChunks:new();
-------------------------------------------------------
]]
local ChatChunks = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.ChatChunks"));

function ChatChunks:ctor()
	self.system = {};
    self.examples = {};
    self.done = {};
	self.repo = {};
    self.readonly_files = {};
	self.chat_files = {};
    self.cur = {};
    self.reminder = {};
end

function ChatChunks:GetAllMessages()
    local allMessages = commonlib.Array:new();
	allMessages:concat(self.system);
	allMessages:concat(self.examples);
	allMessages:concat(self.done);
	allMessages:concat(self.repo);
	allMessages:concat(self.readonly_files);
	allMessages:concat(self.chat_files);
	allMessages:concat(self.cur);
	allMessages:concat(self.reminder);
	return allMessages;
end

function ChatChunks:AddCacheControlHeaders()
	-- TODO: add cache control headers
	-- references: https://github.com/Aider-AI/aider/blob/main/aider/coders/chat_chunks.py
end