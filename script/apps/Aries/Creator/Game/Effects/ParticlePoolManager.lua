--[[
Title: Particle Pool Manager
Author(s): LiXizhi
Date: 2014/7/3
Desc: TODO:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ParticlePoolManager.lua");
local ParticlePoolManager = commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePoolManager");
ParticlePoolManager:Clear();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ParticlePool.lua");
local ParticlePool = commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePool");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local ParticlePoolManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePoolManager"));

function ParticlePoolManager:ctor()
	self.pools = {}
end

-- clear all
function ParticlePoolManager:Clear()
	for name, pool in pairs(self.pools) do
		pool:Clear();
	end
end

