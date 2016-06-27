--[[
Title: Collectable entity
Author(s): LiXizhi
Date: 2013/7/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCollectable.lua");
local EntityCollectable = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollectable")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local entity = MyCompany.Aries.Game.EntityManager.EntityCollectable:new({x,y,z,radius});
EntityManager.AddObject(entity)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local math_abs = math.abs;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollectable"));


-- persistent object by default. 
Entity.is_persistent = true;
-- class name
Entity.class_name = "collectable";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

-- true to auto rotate
Entity.auto_rotate = nil;
Entity.obj_rotate_speed = 1;
Entity.framemove_interval = 2;

local next_id = 1;
local function GetNextName()
	next_id = next_id + 1;
	return tostring(next_id)
end

function Entity:EnableAutoRotate()
	self.auto_rotate = true;
	self.framemove_interval = 0.03;
end

-- @param Entity: the half radius of the object. 
function Entity:init()
	local item;
	if(self.item_id and self.item_id>0) then
		item = ItemClient.GetItem(self.item_id);
	end
	if(item) then
		local x, y, z = self:GetPosition();

		local obj = ObjEditor.CreateObjectByParams({
			name = self.name or self.class_name,
			IsCharacter = true,
			AssetFile = item:GetAssetFile(),
			x = x,
			y = y + item:GetOffsetY(),
			z = z,
			scaling = item:GetScaling(),
			IsPersistent = false,
			
		});
		if(obj) then
			obj:SetField("GroupID", item.group_id or GameLogic.SentientGroupIDs.Collectable);
		
			obj:MakeGlobal(false);
			-- no perceptive radius
			--obj:SetAttribute(16, false);

			self:SetInnerObject(obj);
			ParaScene.Attach(obj);	
		end
		
		self.offset_y = item.offset_y;

		if(item.auto_rotate) then
			self:EnableAutoRotate();
		end

		item:UpdateInWorldCount(1);

		self:UpdateBlockContainer();

		return self;
	end
end

-- when the body of the player hit this entity. 
function Entity:OnCollideWithPlayer(entity, bx,by,bz)
	if(GameLogic.CanCollectItem()) then
		local item;
		if(self.item_id and self.item_id>0) then
			item = ItemClient.GetItem(self.item_id);
			if(item) then
				if(item.can_pick) then
					GameLogic.events:DispatchEvent({type = "OnCollectItem" , block_id = self.item_id, count = 1});
					item:CreateBlockPieces(self.bx, self.by, self.bz);
					self:Destroy();
				end

				if(item.auto_equip) then
					-- equip in right hand
					EntityManager.GetPlayer().inventory:EquipSingleItem(self.item_id);
				end
			end
		end
	end
end

function Entity:Destroy()
	self:DestroyInnerObject();
	
	local item;
	if(self.item_id and self.item_id>0) then
		item = ItemClient.GetItem(self.item_id);
	end
	if(item) then
		item:UpdateInWorldCount(-1);
	end
	Entity._super.Destroy(self);
end

function Entity:FallDown(deltaTime)
	-- do not fall down
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(self.auto_rotate) then
		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetFacing(obj:GetFacing() + deltaTime * self.obj_rotate_speed);
		end
	end
	Entity._super.FrameMove(self, deltaTime);
end