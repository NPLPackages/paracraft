--[[
Title: random spawn
Author(s): LiXizhi
Date: 2015/7/28
Desc: random spawn
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEvent.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

-----------------------------
-- spawn objects. 
-----------------------------
local Spawner = commonlib.inherit(nil);

-- max number of items to spawn.
Spawner.max_count = 6;

function Spawner:ctor()
	-- array of entities
	self.entities = {};
end

local function CanSpawnFilter(itemStack)
	if(itemStack and itemStack:GetItem():CanSpawn()) then
		return true;
	end
end

function Spawner:init(parentEntity)
	self.parentEntity = parentEntity;

	if(parentEntity.inventory) then
		local nTotalCount = parentEntity.inventory:GetItemCount(nil, nil, nil, CanSpawnFilter);
		if(nTotalCount >= 1) then
			self:SetMaxCount(nTotalCount);
		end
	end
	return self;	
end

function Spawner:SetMaxCount(nCount)
	self.max_count = nCount;
end

function Spawner:GetMaxCount()
	return self.max_count;
end

function Spawner:GetCount()
	return #(self.entities);
end

-- get the index and distance square that is farthest to the given point
-- @param centerX, centerY, centerZ: the point in block space. 
-- @return entityIndex, entityDistSq
function Spawner:GetFarthestEntityTo(centerX, centerY, centerZ)
	local lastIndex;
	local lastDist = -1;
	-- destroy farthest entity, and spawn new one. 
	for i, entity in ipairs(self.entities) do
		local dist = entity:DistanceSqTo(centerX, centerY, centerZ);
		if(lastDist < dist) then
			lastDist = dist;
			lastIndex = i;
		end
	end
	return lastIndex, lastDist;
end

-- spawn an item.
-- @param checkedRadiusSq: if not nil, we will not spawn if max entities count is reached and all existing ones are already within radius. 
-- otherwise we will spawn and remove the farthest one. 
function Spawner:Spawn(item_id, itemStack, targetEntity, x,y,z, bPersistent, checkedRadiusSq)
	local item = ItemClient.GetItem(item_id);
	if(item) then
		local lastIndex, lastDist;
		if(self:GetCount() >= self:GetMaxCount()) then
			local centerX, centerY, centerZ = x, y, z;
			if(targetEntity) then
				centerX, centerY, centerZ = targetEntity:GetBlockPos();
			end
			lastIndex, lastDistSq = self:GetFarthestEntityTo(centerX, centerY, centerZ);
			if(checkedRadiusSq and lastDistSq and lastDistSq < checkedRadiusSq) then
				-- we will not spawn if max entities count is reached and all existing ones are already within radius. 
				return;
			end
		end

		local bUsed, entityCreated = item:TryCreate(itemStack, targetEntity, x,y,z);
		if(entityCreated) then
			entityCreated:SetPersistent(bPersistent == true);
			if(lastIndex) then
				self.entities[lastIndex]:Destroy();
				self.entities[lastIndex] = entityCreated;
			else
				self.entities[#self.entities+1] = entityCreated;
			end
		end
	end
end


Commands["spawn"] = {
	name="spawn", 
	quick_ref="/spawn [@entityname] [item_id] [-radius number] [-p x y z (dx dy dz)] [-s|persistent] [-name string]", 
	desc=[[ spawn the given item. 
The max number of objects that can be spawned is the same as the total item count in the containing command block
Entities that are farther way are destroyed when new entity is spawned. 
@param entityname: if [-p] is not specified, it means near which player to spawn (default to current player). 
@param item_id: the item_id to spawn, if not specified, we will randomly find one from the containing command block. 
@param [-radius 3]: specify a radius, default to 1.
@param [-p x y z (dx dy dz)]: specify a location or cubic region to spawn (may be relative to containing block). if not specified, it uses entityname's position.
@param [-s|persistent]: if the spawned object is persistent, default to false.
@param [-name string]: give a name to the entity
Examples:
/spawn    : spawn randomly near the current player using items in the command block.
/spawn -p ~ ~1 ~     : spawn on top of the command block.
/spawn -p ~5 ~-1 ~-8 (3 0 4)	: in a cubic region relative to the command block.
]], 
	category="logic",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local targetEntity, item_id, radius, option, x,y,z, dx, dy, dz, bPersistent, itemStack, checkedRadiusSq, name;
		targetEntity, cmd_text = CmdParser.ParsePlayer(cmd_text, fromEntity);
		item_id, cmd_text = CmdParser.ParseNumber(cmd_text);
		
		while(true) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);	
			if(not option) then
				break;
			elseif(option == "radius") then
				radius, cmd_text = CmdParser.ParseNumber(cmd_text);		
			elseif(option == "p") then
				x,y,z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
				if(z) then
					dx, dy, dz, cmd_text = CmdParser.ParsePosInBrackets(cmd_text);
				end
			elseif(option == "persistent" or option == "s") then
				bPersistent = true;
			elseif(option == "name") then
				name, cmd_text = CmdParser.ParseString(cmd_text);
			end
		end
		if(not targetEntity) then
			targetEntity = EntityManager.GetPlayer();
		end

		if(not item_id and fromEntity and fromEntity.inventory) then
			itemStack = fromEntity.inventory:GetRandomItem(true, CanSpawnFilter);
			if(itemStack) then
				item_id = itemStack.id;
			end
		end
		if(not radius and not dx) then
			radius = 1;
		end
		if(not x) then
			x, y, z = targetEntity:GetBlockPos();
			checkedRadiusSq = radius*radius*3;
		end

		if(item_id) then
			if(x and y and z) then
				if(dx and dy and dz) then
					x = x + math.floor(math.random()*dx);
					y = y + math.floor(math.random()*dy) + 1; -- make it 1 block higher
					z = z + math.floor(math.random()*dz);
				elseif(radius and radius>1)  then
					x = x + math.random(-radius, radius);
					y = y + math.random(-radius, radius);
					z = z + math.random(-radius, radius);
				end

				if(fromEntity) then
					fromEntity.m_spawner = fromEntity.m_spawner or Spawner:new():init(fromEntity);
					fromEntity.m_spawner:Spawn(item_id, itemStack, targetEntity, x,y,z, bPersistent, checkedRadiusSq);
				end
			end
		end
	end,
};
