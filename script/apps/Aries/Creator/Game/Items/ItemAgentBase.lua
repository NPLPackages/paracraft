--[[
Title: Base class for a ItemAgent extension
Author(s): LiXizhi
Date: 2022/6/3
Desc: see AgentDemo for examples
use the lib:
------------------------------------------------------------
local YourAgent = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentBase"), NPL.export());
function YourAgent:ctor()
end
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local ItemAgent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentBase"));
ItemAgent:Property("Name", "ItemAgentBase");

function ItemAgent:ctor()
end

function ItemAgent:Init(name)
	self.name = name;
	return self;
end

-- virtual function:
function ItemAgent:GetIcon(itemStack)
end

-- virtual function:
function ItemAgent:OnSelect(itemStack)
end
-- virtual function:
function ItemAgent:OnDeSelect()
end
-- virtual function:
function ItemAgent:OnClickInHand(itemStack, entityPlayer)
end

-- virtual function:
function ItemAgent:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
end

-- virtual function:
function ItemAgent:CreateAgentFromEntity(parentEntity, itemStack)
end

-- virtual function: this function is called when the item is placed inside an entity, as one of its bag item(component). 
-- this function is ALSO called when the parent entity is loaded from disk. 
function ItemAgent:OnLoadInEntity(parentEntity, itemStack)
end
-- virtual function:
function ItemAgent:OnUnloadInEntity(parentEntity, itemStack)
end
-- virtual function:
function ItemAgent:OnEntityEvent(itemStack, entity, event)
end

-- virtual function:
function ItemAgent:OnTickEntity(itemStack, entity)
end

-- virtual function:
function ItemAgent:OnEntityClick(itemStack, entity, event)
end

-- virtual function:
function ItemAgent:DispatchAgentEvent(itemStack, entity, eventName, msg)
end

