--[[
Title: Agent Entity Movie Clip
Author(s): LiXizhi
Date: 2021/3/8
Desc: a fake movie block entity that only resides in memory or agent world, not in the real world. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Agent/AgentEntityMovieClip.lua");
local AgentEntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityMovieClip");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.AgentEntityMovieClip"));

function Entity:ctor()
end

function Entity:GetNearByCodeEntity(cx, cy, cz)
end

function Entity:SetLastCommandResult(last_result)
end

function Entity:OnBlockTick()
end