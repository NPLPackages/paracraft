--[[
Title: "Examples/AgentDemo"  AgentItem
Author(s): LiXizhi
Date: 2022/6/2
Desc: agent name is automatically set by folder and file name.
use the lib:
------------------------------------------------------------
local AgentDemo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/Examples/AgentDemo.lua");
local demo = AgentDemo:new():Init()

-- in codeblock, we can invoke
local actor = GetEntity("boy1"):GetAgent("Examples/AgentDemo")
if(actor) then
    actor:SayHello()
end
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/AgentActorBase.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentBase"), NPL.export());

---------------------------------------
-- Agent Actor Class
---------------------------------------
local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Agents.AgentActorBase"), nil);

function Actor:ctor()
end

function Actor:SayHello()
	self:GetEntity():Say("hello");
end

---------------------------------------
-- Item Agent Class
---------------------------------------
function ItemAgent:ctor()
end

-- virtual function:
function ItemAgent:OnSelect(itemStack)
	GameLogic.AddBBS(nil, "you selected "..self.name);
end

-- virtual function:
function ItemAgent:CreateAgentFromEntity(parentEntity, itemStack)
	return Actor:new():Init(parentEntity, itemStack)
end


-- virtual function: this function is called when the item is placed inside an entity, as one of its bag item(component). 
-- this function is ALSO called when the parent entity is loaded from disk. 
function ItemAgent:OnLoadInEntity(parentEntity, itemStack)
	-- a demo of display a headon health bar on top of the entity. 
	local mcmlCode = [[<pe:mcml><div style="background-color:red;width:50px;height:5px;margin-left:-25px;margin-top:-10px;">
<pe:progressbar style="width:50px;height:5px" Minimum="0" Maximum="100" value='<%=getHealth()%>' getter="value" />
</div></pe:mcml>]]
	parentEntity:SetHeadOnDisplay({
		url = ParaXML.LuaXML_ParseString(mcmlCode),
		pageGlobalTable = {
			-- get health value of the entity
			getHealth = function()
				return tonumber(parentEntity:GetTagField("health") or 90)
			end,
		},
		-- is3D = true, facing = -1.57,
	})
end

-- virtual function:
function ItemAgent:OnEntityClick(itemStack, entity, event)
	local health = tonumber(entity:GetTagField("health") or 90)
	health = (health - 10) % 100
	entity:SetTagField("health", health)
end