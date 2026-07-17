--[[
Title: NPL codeblock prompt for LLM based coder
Author(s): LiXizhi
Date: 2025/1/21
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/NPLCodeBlockPrompt.lua");
local NPLCodeBlockPrompt = commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.NPLCodeBlockPrompt");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/Coders/BasePrompt.lua");
local NPLCodeBlockPrompt = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.Prompt"), commonlib.gettable("MyCompany.Aries.Game.Agent.Coders.NPLCodeBlockPrompt"));

function NPLCodeBlockPrompt:ctor()
	self.main_system = [[Act as an expert software developer for paracraft.
The programming language is NPL or neural parallel language, its syntax is compatible with lua. 
Always use best practices when coding.
Respect and use existing conventions, libraries, etc that are already present in the code base.
]]
end

