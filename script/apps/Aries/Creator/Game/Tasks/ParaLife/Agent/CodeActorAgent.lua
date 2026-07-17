--[[
Title: "CodeActorAgent"  AgentItem
Author(s): LiXizhi
Date: 2022/6/19
Desc: This represents an agent that is controlled by a code block.
use the lib:
------------------------------------------------------------
local CodeActorAgent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/CodeActorAgent.lua");
local demo = CodeActorAgent:new():Init()

-- in codeblock, we can invoke
local actor = GetEntity("boy1"):GetAgent("CodeActorAgent")
if(actor) then
    actor:SayHello()
end
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/AgentActorBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentBase"), NPL.export());


function ItemAgent:ctor()
end

-- virtual function:
function ItemAgent:CreateAgentFromEntity(parentEntity, itemStack)
	local codeblockName = parentEntity:GetTagField("codeblock");
	local actor;
	if(codeblockName) then
		actor = CodeActor:new():Init()
	else
		if(itemStack) then
			local actorName = itemStack:GetDataField("actorName")
			if(actorName) then
				actor = GameLogic.GetCodeGlobal():GetActorByName(actorName);
				if(actor) then
					if(actor:GetEntity() ~= parentEntity) then
						actor = nil;
					end
				end
				if(actor == nil) then
					local item = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1);
					actor = CodeActor:new():Init(item);
					if(not actor:IsAgent()) then
						actor:SetName(actorName);
					end
					GameLogic.GetCodeGlobal():AddActor(actor);
				end
			end
		end
		if(not actor) then
			local item = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1);
			actor = CodeActor:new():Init(item);
		end
		actor:BecomeAgent(parentEntity)
	end
	return actor;
end

-- virtual function: this function is called when the item is placed inside an entity, as one of its bag item(component). 
-- this function is ALSO called when the parent entity is loaded from disk. 
function ItemAgent:OnLoadInEntity(parentEntity, itemStack)
	-- a demo of display a headon health bar on top of the entity. 
end