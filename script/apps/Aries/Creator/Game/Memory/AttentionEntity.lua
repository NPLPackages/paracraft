--[[
Title: Attention Block
Author(s): LiXizhi
Date: 2017/6/3
Desc: A single entity that caught our attention in the vision context. 
It can be a model entity or NPC entity.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/AttentionEntity.lua");
local AttentionEntity = commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionEntity");
-------------------------------------------------------
]]
local AttentionEntity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionEntity"));
AttentionEntity:Property("Name", "AttentionEntity");

function AttentionEntity:ctor()
end

function AttentionEntity:init(bx, by, bz)
	self.bx, self.by, self.bz = bx, by, bz;
end
