--[[
Title: Animation for destroy blocks
Author(s): LiXizhi
Date: 2013/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockPiece.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local entity = MyCompany.Aries.Game.EntityManager.EntityBlockPiece:new({x,y,z,radius, texture, AnimFrame, speed_x, speed_y, speed_z});
EntityManager.AddObject(entity)
-------------------------------------------------------
]]
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local math_abs = math.abs;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockPiece"));

Entity.is_dynamic = true;
Entity.lifetime = 2;
Entity.fade_out_time = 1;
Entity.radius = 0.2;
Entity.is_dummy = true;

-- @param x,y,z: initial real world position. 
-- @param Entity: the half radius of the object. 
function Entity:ctor()
	self.physic_obj = PhysicsWorld.DynamicObject:new():Init(self.x, self.y, self.z, self.radius, self.speed_x, self.speed_y, self.speed_z);
	self.physic_obj:Attach();

	local scene = ParaScene.GetMiniSceneGraph("block_particles");

	local obj = ObjEditor.CreateObjectByParams({
		name = "",
		IsCharacter = true,
		AssetFile = "character/v6/09effect/Block_Piece/Block_piece.x",
		ReplaceableTextures = {[2] = self.texture}, -- can be nil
		x = self.x,
		y = self.y,
		z = self.z,
		scaling = self.radius*2,
	});
	if(obj) then
		self:SetInnerObject(obj);
		--obj:SetField("UseGlobalTime", true);
		--obj:SetField("AnimID", 0);
		obj:SetField("AnimFrame", self.AnimFrame or 0);
		obj:SetField("IsAnimPaused", true);
		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);
	
		if(self.fade_out_time) then
			local params = obj:GetEffectParamBlock();
			params:SetFloat("g_opacity", 1);
		end
		scene:AddChild(obj);
	end
end


function Entity:Destroy()
	self.physic_obj:Destroy();

	local scene = ParaScene.GetMiniSceneGraph("block_particles");
	local obj = self:GetInnerObject();
	if(obj) then
		scene:DestroyObject(obj);
	end
	Entity._super.Destroy(self);
end


-- called every frame
function Entity:FrameMove(deltaTime)
	-- local obj = self:GetInnerObject();
	local obj = self.obj; -- for speed 
	if(obj) then
		obj:SetPosition(self.physic_obj.x, self.physic_obj.y, self.physic_obj.z);
		obj:SetField("AnimFrame", self.AnimFrame or 0);
		obj:SetField("IsAnimPaused", true);

		if(self.fade_out_time) then
			-- this does not work. 
			if(self.lifetime < self.fade_out_time) then
				local params = obj:GetEffectParamBlock();
				opacity = self.lifetime/self.fade_out_time;
				params:SetFloat("g_opacity", opacity);
			end
		end
	else
		self:SetDead();
	end
	Entity._super.FrameMove(self, deltaTime);
end