--[[
Title: entity region container
Author(s): LiXizhi
Date: 2013/12/14
Desc: a container for regional(512*512) entities
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/RegionContainer.lua");
local RegionContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.RegionContainer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local RegionContainer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.EntityManager.RegionContainer"));

RegionContainer.entities = {};

-- @param x,y,z: initial real world position. 
-- @param radius: the half radius of the object. 
function RegionContainer:ctor()
	self.entities = {};
end

function RegionContainer:init(x,z, filename)
	self.region_x = x;
	self.region_z = z;
	if(filename) then
		self.filename = filename;
	end
	return self;
end

-- set modified and dirty
function RegionContainer:SetModified()
	self.is_dirty = true;
end

-- TODO: always return true for the moment
function RegionContainer:IsModified()
	return true;
end

function RegionContainer:GetEntities()
	return self.entities;
end

function RegionContainer:Add(entity)
	self.entities[entity] = true;
end

function RegionContainer:Remove(entity)
	self.entities[entity] = nil;
end

function RegionContainer:GetRegionFileName()
	if(not self.filename) then
		self.filename = format("%sblockWorld.lastsave/%d_%d.region.xml", ParaWorld.GetWorldDirectory(), self.region_x, self.region_z);
		if(not ParaIO.DoesAssetFileExist(self.filename, true)) then
			local filename = format("%sblockWorld/%d_%d.region.xml", ParaWorld.GetWorldDirectory(), self.region_x, self.region_z);
			if(ParaIO.DoesAssetFileExist(filename, true)) then
				self.filename = filename;
			end
		end
	end
	return self.filename;
end

function RegionContainer:SaveToFile(filename)
	filename = filename or self:GetRegionFileName();
	local filename = self:GetRegionFileName();
	
	if(not next(self.entities)) then
		if(not ParaIO.DoesAssetFileExist(filename, true))then
			return;
		end
	end
	
	local root = {name='entities', attr={file_version="0.1"} }
	local sortEntities = {};
	
	local x, y, z, posValue;
	for entity in pairs(self.entities) do 
		if( entity:IsPersistent() and entity:IsRegional() and not entity:IsDead()) then
			local node = {name='entity', attr={}};
			entity:SaveToXMLNode(node, true);
			x, y, z = entity:GetBlockPos();

			posValue = (x or 0) * 100000000 +  (y or 0) * 1000000 + (z or 0);

			table.insert(sortEntities, {pos = posValue, node = node});

		end
	end
	
	table.sort(sortEntities, function(a, b)
		return a.pos < b.pos;
	end);
	
	for _, entity in ipairs(sortEntities) do
		table.insert(root, entity.node);
	end

	
	local bSuccessed = false;
	if(root) then
		
		local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
		
		--NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
		--local Encoding = commonlib.gettable("System.Encoding");
		--print(Encoding.sha1(xml_data, "hex"));
		
		if (#xml_data >= 10240) then
			local writer = ParaIO.CreateZip(filename, "");
			if (writer:IsValid()) then
				writer:ZipAddData("data", xml_data);
				writer:close();
				bSuccessed = true;
			end
		else
			local file = ParaIO.open(filename, "w");
			if(file:IsValid()) then
				file:WriteString(xml_data);
				file:close();
				
				bSuccessed = true;
			end
		end
	end
	
	if bSuccessed then
		GameLogic.GetFilters():apply_filters("OnSaveBlockRegion", true, self.region_x, self.region_z, "region.xml");
	end
end

function RegionContainer:LoadFromFile(filename)
	filename = filename or self:GetRegionFileName();

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local count = 0;
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/entities/entity") do
			local attr = node.attr;
			if(attr) then
				local entity_class;
				if(attr.class) then
					entity_class = EntityManager.GetEntityClass(attr.class)
				end
				if(attr.item_id) then
					local item = ItemClient.GetItem(tonumber(attr.item_id));
					if(item) then
						if(item.entity_class and item.entity_class~=attr.class) then
							LOG.std(nil, "warn", "RegionContainer", "Loading entity item_id %d miss matching entity class from %s to %s", attr.item_id, attr.class, item.entity_class);
							entity_class = EntityManager.GetEntityClass(item.entity_class);
						end
					else
						LOG.std(nil, "warn", "RegionContainer", "Loading entity item_id %d not found", attr.item_id);
					end
				end
				
				if(entity_class) then
					local entity = entity_class:Create({}, node);
					if(entity) then
						--if(entity.item_id) then
							--local item = ItemClient.GetItem(entity.item_id);
							--if(item and item.gold_count) then
								--entity_count_stats["gold_count"] = (entity_count_stats["gold_count"] or 0) + item.gold_count;
							--end
						--end

						EntityManager.AddObject(entity);
						count = count + 1;
					else
						LOG.std(nil, "warn", "EntityLoad", "entity is not loaded. ")
					end
				end
			end
		end
		LOG.std(nil, "system", "RegionContainer", "loading %d entities from file: %s", count, filename);
		return true;
	end
end
