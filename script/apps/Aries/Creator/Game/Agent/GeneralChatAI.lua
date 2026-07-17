--[[
Title: General LLM chat AI
Author(s): LiXizhi
Date: 2024/11/22
Desc: it handles all keepwork chat messages and some messages from paracraft copilots if no other experts are specified.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/GeneralChatAI.lua");
local GeneralChatAI = commonlib.gettable("MyCompany.Aries.Game.Agent.GeneralChatAI");
GeneralChatAI:GetSingleton():Init();
GeneralChatAI:GetSingleton():SendChat("hi", function(msg) end);
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GeneralChatAI = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Agent.GeneralChatAI"));

function GeneralChatAI:ctor()
end

function GeneralChatAI:Init()
	if(self.inited) then
		return;
	end
	self.inited = true;

	if System.os.IsEmscripten() then
		local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua")
		Emscripten:OnMsg("@webparacraft_Chat", function(msg)
			self:handleKeepworkChat(msg);
		end)
	end
end

function GeneralChatAI.formatMsgContent(content)
    local formatContent = content:gsub("#+ ", "")
    formatContent = formatContent:gsub("%* ", "")
    formatContent = formatContent:gsub("%*%*%*([^%*]+)%*%*%*", "%1")
    formatContent = formatContent:gsub("%*%*([^%*]+)%*%*", "%1")
    formatContent = formatContent:gsub("%*([^%*]+)%*", "%1")
    formatContent = formatContent:gsub("\n", "<br/>")
    return formatContent
end


function GeneralChatAI:SendChat(text, callback)
end

-- handles all messages from keepwork chat
-- @param msg: {agentName, responseText, messages}
function GeneralChatAI:handleKeepworkChat(msg)
	if msg.agentName then
        local text = msg.responseText
        if not text or text == "" then
            self.inChat = true
            -- self.messages = msg.messages
            for index, message in ipairs(self.messages) do
                if index == 1 then
                    if msg.firstMessageContent and msg.referenceContent then
                        message.content = msg.firstMessageContent
                        --self.referenceContent = msg.referenceContent
                    end
                end
                message.index = index
                -- message.content = self.formatMsgContent(message.content)
            end
        else
            if text == "服务器内部错误" then
                return
            end
        end
    end
end

function GeneralChatAI:GetSingleton()
	if(not GeneralChatAI.instance) then
		GeneralChatAI.instance = GeneralChatAI:new();
        GeneralChatAI.instance:Init();
	end
	return GeneralChatAI.instance;
end

