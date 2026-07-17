--[[
Title: NPLCodeBlockCoder is used only with standard codeblock entity in paracraft.
Author(s): LiXizhi
Date: 2025/1/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/NPLCodeBlockCoder.lua");
local NPLCodeBlockCoder = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.NPLCodeBlockCoder");
local coder = NPLCodeBlockCoder:new():Init(codeEntity);
coder:Send()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/BaseCoder.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/NPLCodeBlockPrompt.lua");
local NPLCodeBlockPrompt = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.NPLCodeBlockPrompt");
local NPLCodeBlockCoder = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Coder"), commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.NPLCodeBlockCoder"));

function NPLCodeBlockCoder:ctor()
	self.gpt_prompts = NPLCodeBlockPrompt:new();
end

function NPLCodeBlockCoder:Init(codeEntity)
	NPLCodeBlockCoder._super.Init(self);
	self.codeEntity = codeEntity;
	return self;
end

-- provide all global(system) NPL function definitions, as well as functions defined in connected code blocks.
function NPLCodeBlockCoder:GetRepoMessages()
	return {};
end

function NPLCodeBlockCoder:GetFilesContent()
	if(self.codeEntity) then
		local prompt = "";
		local code = self.codeEntity:GetNPLCode();
		if(code) then
			local filename = "\n"..self.codeEntity:GetFilename().."\n";
			prompt = prompt..filename..self.fence[1].."\n";
			prompt = prompt..code.."\n"..self.fence[2].."\n";
		end
		return prompt;
	end
end

function NPLCodeBlockCoder:GetChatFilesMessages()
	local chat_files_messages = {}
	if(self.codeEntity) then
		local content = self:GetFilesContent()
		if(content) then
			local files_content = self.gpt_prompts.files_content_prefix;
			local files_reply = self.gpt_prompts.files_content_assistant_reply
			files_content = files_content..content;
			chat_files_messages[#chat_files_messages+1] = {
				{role="user", content=files_content},
				{role="assistant", content=files_reply},
			}
		end
	end
	return chat_files_messages;
end

function NPLCodeBlockCoder:GetSummary()
end

-- virtual function: extract and apply received code changes, this could be generating the actual commands, 
-- or updating codeblock text. 
function NPLCodeBlockCoder:ApplyUpdates()
	if(self.codeEntity) then
		local text = self.codeEntity:GetNPLCode();
		-- TODO: apply the text to the code block entity.
		local newText = text;

		if(newText ~= text) then
			self.codeEntity:SetNPLCode(newText or "");
		end
	end
end

-- virtual function: (re) run the code. this could be running the actual commands, or run the associated codeblock entity.
function NPLCodeBlockCoder:Run(onFinishedCallback)
	if(self.codeEntity) then
		self.codeEntity:Restart(function()
			-- TODO: in case there is error, we may want to show error message here and auto generate chat message to ask LLM to fix it.
			if(onFinishedCallback) then
				onFinishedCallback();
			end
		end);
	end
end
