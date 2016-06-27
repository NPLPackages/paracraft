--[[
Title: aimod base
Author(s): LiXizhi
Date: 2010/2/9
Desc: this is a standard ai module. It can be used as an example of how to write ai module. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/SimpleTalk.lua");
-- do the self registration
MyCompany.Aries.Creator.AI.SimpleTalk.main();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")

local SimpleTalk = commonlib.gettable("MyCompany.Aries.Creator.AI.SimpleTalk")

SimpleTalk.name = "SimpleTalk";

-- virtual function
-- register with AI module. 
function SimpleTalk.main()
	-- register the ai module base with the local NPC. 
	LocalNPC:RegisterAIMod(SimpleTalk.name, SimpleTalk);
end

-- virtual function
-- invoke editor UI for this ai module, which is usually an mcml page. 
-- @param npc: npc is ParaObject representing the character to be edited. 
-- @param ai_data: the npc data table. it may be nil if it is the first time that this ai module is applied to the npc. 
function SimpleTalk.InvokeEditor(npc, ai_data)
	-- we will display an mcml page for editing this npc. 
	
	local npc_name = npc.name;
	NPL.load("(gl)script/apps/Aries/Creator/AI/SimpleTalkEditPage.lua");
	if(ai_data)then
		ai_data.text = ai_data.text or {};
		local args = {
			text =  ai_data.text,
		}
		MyCompany.Aries.Creator.AI.SimpleTalkEditPage.ShowPage(args);
	end
end

-- virtual function: apply AI to the npc using the given ai_data
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table. it may be nil if it is the first time that this ai module is applied to the npc. 
-- @return: ai_data it should the new ai_data. Usually it is the input ai_data or a default one if input is nil. 
function SimpleTalk.ApplyAI(npc, ai_data)
	ai_data = ai_data or { curIndex = 1, text = {}, };
	
	-- TODO: apply ai_data to npc. 
	
	return ai_data;
end

-- virtual function(callback): This function is called whenever the user clicks on this character. 
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc. 
-- @return simple talk
function SimpleTalk.OnClick(npc, ai_data)
	if(ai_data)then
		local text = ai_data.text;
		local index = ai_data.curIndex;
		if(text and type(text) == "table")then
			local v = text[index];--当前要说的话
			if(v and v~= "") then
				headon_speech.Speek(npc.name, headon_speech.GetBoldTextMCML(v), 5, true);
				
				ai_data.curIndex = ai_data.curIndex + 1;
				v = text[ai_data.curIndex];
				if(not v or v=="" or ai_data.curIndex > 5)then
					ai_data.curIndex = 1;
				end
			else
				ai_data.curIndex = 1;
			end	
		end
	end
end

-- get the next talk text
-- @param index: the talk index to begin with. if nil, it will be the next talk and loop. 
function SimpleTalk.GetNextTalkText(npc, ai_data, index)
	if(ai_data)then
		local text = ai_data.text;
		local index = index or ai_data.curIndex;
		if(text and type(text) == "table")then
			local v = text[index];--当前要说的话
			if(v and v~= "") then
				ai_data.curIndex = index + 1;
				local v_ = text[ai_data.curIndex];
				if(not v_ or v_=="" or ai_data.curIndex > 5)then
					ai_data.curIndex = 1;
				end
				return v;
			else
				ai_data.curIndex = 1;
			end	
		end
	end
end

-- virtual function: remove AI from the given npl
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc. 
function SimpleTalk.RemoveAI(npc, ai_data)
	-- TODO: remove any hooks or events, etc. 
end

-- virtual function: deserialize(Load) current npc with ai_data loaded from xml. 
-- this function should call ApplyAI(npc, ai_data) if need to apply it immediately at load time. 
-- @param npc: npc is ParaObject representing the character. 
-- @return output: it should return parsed ai_data. if nil, the npc ai module will be removed. 
function SimpleTalk.Deserialize(npc, ai_data)
	-- TODO: one may hook to events of npc and load ai_data. 
	ai_data	= ai_data or {};
	SimpleTalk.ApplyAI(npc, ai_data);
	return ai_data;
end

-- virtual function: serialize(Save) current npc ai data to a pure non-recursive table object. 
-- @param npc: npc is ParaObject representing the character. 
-- @param ai_data: the npc data table for the npc.  it may be nil. 
-- @return output: it should return output data table. if nil, the npc ai module will not be saved to disk. 
function SimpleTalk.Serialize(npc, ai_data)
	-- TODO: one may need to remove recursive and unused fields or just use output to save. 
	if(ai_data) then
		-- this ensure it always begins with the first sentence. 
		ai_data.curIndex = 1;
	end	
	return ai_data;
end