--[[
Title: Base class for LLM based coder
Author(s): LiXizhi
Date: 2025/1/21
Desc: Coder is a special agent that use large language model to generate code for various situations.
We normally derive from this class to create a special coder agent. 
E.g. NPLCodeBlockCoder is a coder that can generate NPL code for a given code block entity.
Each coder has its own context, which may includes its parent coders, child coders and any user or AI generated prompt at its own level.

references: https://github.com/Aider-AI/aider/blob/main/aider/coders/base_coder.py
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/BaseCoder.lua");
local Coder = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Coder");
local coder = Coder:new():Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/ChatChunks.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/BasePrompt.lua");
local Prompt = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Prompt");
local ChatChunks = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.ChatChunks");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Coder = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Coder"));

function wrap_fence(name)
    return string.format("<%s>", name), string.format("</%s>", name)
end
local all_fences = {
    {"```", "```"}, -- default triple-backtick
    {"````", "````"},
    {wrap_fence("source")},
    {wrap_fence("code")},
    {wrap_fence("pre")},
    {wrap_fence("codeblock")},
    {wrap_fence("sourcecode")},
}

function Coder:ctor()
	self.fence = all_fences[1];
end

function Coder:Init()
	self.gpt_prompts = self.gpt_prompts or Prompt:new();
	return self;
end

-- get all summaries from all of its parents coder. 
-- Parent summaries are usually used to provide more context to the AI model.
function Coder:GetParentSummaries()
	local parent = self.parent;
	local summaries;
	while(parent) do
		local parentSummary = parent:GetSummary();
		if(parentSummary and parentSummary ~= "") then
			summaries = parentSummary.."\n"..(summaries or "")
		end
		parent = parent.parent;
	end
	return summaries
end

-- summary should be provided in a way that can be used as context to the AI model.
-- it may or may not include the LLM result. 
function Coder:GetSummary()
	return self.summary;
end

function Coder:GetRepoMessages()
	return {};
end

function Coder:GetReadOnlyFilesMessages()
	return {};
end

-- this is the file content that AI should work with or modify in reply. 
function Coder:GetChatFilesMessages()
	return {};
end

function Coder:GetChatMessages()
	return {};
end

function Coder:GetImageMessages()
	return {};
end

function Coder:GetUserLanguage()
end

function Coder:ShowUserEditor()
end

-- assemble request from current context and send to LLM/GPT model. When the response is received, 
-- we will usually call ApplyUpdates() and Run() to apply the changes and re-run the code.
function Coder:Send()
	local chunks = ChatChunks:new();
	chunks.system = {
		{role="user", content=self.gpt_prompts.main_system},
		{role="assistant", content="Ok."},
	}
	chunks.repo = self:GetRepoMessages()
	chunks.readonly_files = self:GetReadOnlyFilesMessages()
	chunks.chat_files = self:GetChatFilesMessages()

	local curMessages = {};
	local summaries = self:GetParentSummaries();
	if(summaries) then
		curMessages[#curMessages+1] = {role="user", content=summaries}
		curMessages[#curMessages+1] = {role="assistant", content=self.gpt_prompts.summary_assistant_reply}
	end
	chunks.cur = curMessages;

	local msg = chunks:GetAllMessages()
	-- TODO: send message
	return msg;
end

-- virtual function: extract and apply received code changes, this could be generating the actual commands, 
-- or updating codeblock text. 
function Coder:ApplyUpdates()
end

-- virtual function: (re) run the code. this could be running the actual commands, or run the associated codeblock entity.
function Coder:Run(onFinishedCallback)
end
