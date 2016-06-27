--[[
Title: block pieces effect
Author(s): LiXizhi
Date: 2014/5/12
Desc: rendering large number of block piece particle efficiently
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/BlockPieceEffect.lua");
local BlockPieceEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.BlockPieceEffect");
BlockPieceEffect:CreateBlockPiece(x,y,z, radius, lifetime, speed_x, speed_y, speed_z, texture_filename)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockPiece.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BlockPieceEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.BlockPieceEffect");

-- whether to use c++ implementation of block piece effect. 
BlockPieceEffect.use_cpp_impl = true;

-- OBSOLETED: this function is not needed, this is automatically done by ParaScene.Attach() in C++
function BlockPieceEffect:GetContainer()
	local particle_container = self.particle_container;
	if(not particle_container or not particle_container:IsValid()) then
		LOG.std(nil, "info", "BlockPieceEffect", "CBlockPieceEffect created and added to scene");
		particle_container = ParaScene.CreateObject("CContainerObject", "CBlockPieceParticle",0,0,0);
		ParaScene.GetObject("<root>"):AddChild(particle_container);
		self.particle_container = particle_container;
	end
	return particle_container;
end

local tmp_vector = {};
function BlockPieceEffect:CreateBlockPiece(x,y,z, radius, lifetime, speed_x, speed_y, speed_z, texture_filename)
	if(self.use_cpp_impl) then
		local particle = ParaScene.CreateObject("BlockPieceParticle", "",x,y,z);
		tmp_vector[1], tmp_vector[2], tmp_vector[3] = speed_x, speed_y, speed_z;
		particle:SetField("Speed", tmp_vector);
		particle:SetField("lifetime", lifetime);
		particle:SetField("radius", radius);
		particle:SetField("TextureFilename", texture_filename);
		ParaScene.Attach(particle);
	else
		local entity = EntityManager.EntityBlockPiece:new({
			x=x, y=y, z=z, radius=radius, lifetime = lifetime,
			speed_x = speed_x, speed_y = speed_y, speed_z = speed_z,
			texture = texture_filename, 
			AnimFrame = math.random(1,2400),-- 80(frame)*30
		});
		EntityManager.AddObject(entity);
	end
end