--[[
Title: a pool of particle id
Author(s): LiXizhi
Date: 2014/7/3
Desc: TODO:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ParticlePool.lua");
local ParticlePool = commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePool");
ParticlePool:FrameMove(deltaTime)
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local ParticlePool = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.ParticlePool"));


function ParticlePool:ctor()
	self.used_ids = {};
	self.free_ids = {};
end

function ParticlePool:Init(miniScenename, assetfile, isCharacter)
end

function ParticlePool:CreateNewId()
end

function ParticlePool:Clear()
end

function ParticlePool:GetFreeId()
end