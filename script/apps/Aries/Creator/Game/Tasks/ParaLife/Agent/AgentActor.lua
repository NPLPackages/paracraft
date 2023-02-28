--[[
Title: Base class for a agent item (component of entity)
Author(s): LiXizhi
Date: 2022/6/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Agent/AgentComponent.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Agent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Agents.AgentComponent"));

Agent:Property("Name", "UnnamedAgent");

function Agent:ctor()
end

function Agent:Init(entity)
	self.entity = entity
	return self;
end