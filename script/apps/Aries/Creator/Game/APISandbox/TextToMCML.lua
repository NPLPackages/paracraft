--[[
Title: Convert Text to MCML code
Author(s):  LiXizhi
Company: ParaEngine
Date: 2014.3.19
Desc: Convert user friendly text to MCML code in a safe way. 
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/APISandbox/TextToMCML.lua");
local TextToMCML = commonlib.gettable("MyCompany.Aries.Game.APISandbox.TextToMCML");
echo( TextToMCML:ConvertTextWikiStyle("*bold* =border= _italic bg_") )
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local TextToMCML = commonlib.gettable("MyCompany.Aries.Game.APISandbox.TextToMCML");

-- supporting minimum number of mcml syntax. 
-- bold: *your phrase*
-- border bg: =your words= 
-- url: [[http://www.paraengine.com][paraengine]]
function TextToMCML:ConvertTextWikiStyle(text)
	if(not text) then
		return;
	end
	text = text:gsub("%*([^%*]+)%*", "<b>%1</b>");
	text = text:gsub("=([^=&;%?]+)=", "<div class='bbs_sys_text' style='float:left;padding-left:3px;'>%1</div>");
	text = text:gsub("%[%[(%S+)%]%[(%S+)%]%]", "<a href='%1'>%2</a>");
	return text;
end
