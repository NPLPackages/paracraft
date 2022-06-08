--[[
Title: Agent Entity Code
Author(s): LiXizhi
Date: 2021/3/8
Desc: a fake Code block entity that only resides in memory or agent world, not in the real world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentEntityCode.lua");
local AgentEntityCode = commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityCode");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCode"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityCode"));

function Entity:ctor()
end

function Entity:ScheduleRefresh(x,y,z)
	-- dummy
end

function Entity:updateTick(x,y,z)
	-- dummy
end

function Entity:SetLastCommandResult(last_result)
	-- dummy
end

