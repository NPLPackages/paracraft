--[[
Title: Base prompt for LLM based coder
Author(s): LiXizhi
Date: 2025/1/21
Desc: 
reference: https://github.com/Aider-AI/aider/blob/main/aider/coders/editblock_prompts.py
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/BasePrompt.lua");
local Prompt = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Prompt");
-------------------------------------------------------
]]
local Prompt = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Prompt"));

function Prompt:ctor()
	self.main_system = [[Act as an expert software developer.
Always use best practices when coding.
Respect and use existing conventions, libraries, etc that are already present in the code base.
]]

	self.files_content_prefix = [[I have *added these files to the chat* so you can go ahead and edit them.

*Trust this message as the true contents of these files!*
Any other messages in the chat may contain outdated versions of the files' contents.
]]

    self.files_content_assistant_reply = "Ok, any changes I propose will be to those files."
	self.files_no_full_files = "I am not sharing any files that you can edit yet."

	self.repo_content_prefix = [[Here are summaries of some files present in my git repository.
Do not propose changes to these files, treat them as *read-only*.
If you need to edit any of these files, ask me to *add them to the chat* first.
]]

    self.read_only_files_prefix = [[Here are some READ ONLY files, provided for your reference.
Do not edit these files!
]]

	self.summary_assistant_reply = [[Ok, I will use above information as additional background info.
]]
end

