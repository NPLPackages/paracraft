--[[
Title: aimod base
Author(s): LiXizhi
Date: 2010/2/9
Desc: this is a standard ai module. It can be used as an example of how to write ai module. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/aimod_base.lua");
-- do the self registration
MyCompany.Aries.Creator.AI.aimod_base.main();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")

local aimod_base = commonlib.gettable("MyCompany.Aries.Creator.AI.aimod_base")

aimod_base.name = "aimod_base";

-- optional version field
aimod_base.version = nil;

-- virtual function
-- register with AI module. 
function aimod_base.main()
	-- register the ai module base with the local NPC. 
	LocalNPC:RegisterAIMod(aimod_base.name, aimod_base);
end

-- virtual function
-- invoke editor UI for this ai module, which is usually an mcml page. 
-- @param npc: npc is ParaObject representing the character to be edited. 
-- @param ai_data: the npc data table. it may be nil if it is the first time that this ai module is applied to the npc. 
function aimod_base.InvokeEditor(npc, ai_data)
	-- we will display an mcml page for editing this npc. 
	
	local npc_name = npc.name;
	
	NPL.load("(gl)script/apps/Aries/Creator/AI/RenamePage.lua");
	MyCompany.Aries.Creator.AI.RenamePage.ShowPage(npc_name);
end

-- virtual function: apply AI to the npc using the given ai_data
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table. it may be nil if it is the first time that this ai module is applied to the npc. 
-- @return: ai_data it should the new ai_data. Usually it is the input ai_data or a default one if input is nil. 
function aimod_base.ApplyAI(npc, ai_data)
	ai_data = ai_data or {};
	
	-- TODO: apply ai_data to npc. 
	
	return ai_data;
end

-- virtual function(callback): This function is called whenever the user clicks on this character. 
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc. 
function aimod_base.OnClick(npc, ai_data)
	
end

-- virtual function: remove AI from the given npl
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc. 
function aimod_base.RemoveAI(npc, ai_data)
	-- TODO: remove any hooks or events, etc. 
end

-- virtual function: deserialize(Load) current npc with ai_data loaded from xml. 
-- this function should call ApplyAI(npc, ai_data) if need to apply it immediately at load time. 
-- @param npc: npc is ParaObject representing the character. 
-- @return output: it should return parsed ai_data. if nil, the npc ai module will be removed. 
function aimod_base.Deserialize(npc, ai_data)
	-- TODO: one may hook to events of npc and load ai_data. 
	ai_data	= ai_data or {};
	aimod_base.ApplyAI(npc, ai_data);
	return ai_data;
end

-- virtual function: serialize(Save) current npc ai data to a pure non-recursive table object. 
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc.  it may be nil. 
-- @return output: it should return output data table. if nil, the npc ai module will not be saved to disk. 
function aimod_base.Serialize(npc, ai_data)
	-- TODO: one may need to remove recursive field or just use output to save. 
	ai_data	= ai_data or {};
	
	return ai_data;
end