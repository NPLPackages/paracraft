--[[
Title: entity region container
Author(s): LiXizhi, big
CreateDate: 2013.12.14
ModifyDate: 2021.08.25
Desc: a container for regional(512*512) entities
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/RegionContainer.lua");
local RegionContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.RegionContainer");
local region = EntityManager.GetRegionContainer(regionX*512, regionY*512)
region:LoadRegion(callbackFunc)
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
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

function RegionContainer:RemoveAll()
	local allEntities = {}
	for entity, _ in pairs(self.entities) do
		allEntities[#allEntities+1] = entity;
	end
	for _, entity in ipairs(allEntities) do
		entity:Destroy()
	end
	self.entities = {};
end

-- set modified and dirty
-- region container is set modified when region is loaded. 
function RegionContainer:SetModified()
	self.is_dirty = true;
end

function RegionContainer:IsModified()
	return self.is_dirty;
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

function RegionContainer:IsFromExternalWorld()
	return self.externalRegion ~= nil;
end

function RegionContainer:GetExternalRegion()
	return self.externalRegion;
end

function RegionContainer:SetExternalRegion(externalRegion)
	self.externalRegion = externalRegion;
end

function RegionContainer:GetWorldDirectory()
	return self.externalRegion and self.externalRegion:GetWorldDirectory() or GameLogic.GetWorldDirectory();
end


-- @param filename: if nil, we will use default name under blockWorld.lastsave folder. 
function RegionContainer:SetRegionFileName(filename)
	if(not filename) then
		filename = format("%sblockWorld.lastsave/%d_%d.region.xml", ParaWorld.GetWorldDirectory(), self.region_x, self.region_z);
	end
	self.filename = filename;
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

function RegionContainer:SaveToAnotherRegion(filename, regionX, regionY)
	if(not filename or filename == self:GetRegionFileName() or not regionX or not regionY) then
		return
	end
	if(self.region_x == regionX and self.region_z == regionY and (not filename or filename == self:GetRegionFileName())) then
		return self:SaveToFile(filename)
	end

	local offsetX = (regionX - self.region_x) * 512;
	local offsetZ = (regionY - self.region_z) * 512;
	local offsetXReal = offsetX * BlockEngine.blocksize;
	local offsetZReal = offsetZ * BlockEngine.blocksize;

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

			-- for movie blocks
			if(entity.OffsetActorPositions) then
				entity:OffsetActorPositions(offsetX, 0, offsetZ);
			end

			entity:SaveToXMLNode(node, true);

			if(entity.OffsetActorPositions) then
				entity:OffsetActorPositions(-offsetX, 0, -offsetZ);
			end
			
			x, y, z = entity:GetBlockPos();
			x = x + offsetX;
			z = z + offsetZ;

			if(entity:IsBlockEntity()) then
				node.attr.bx = x;
				node.attr.bz = z;
			elseif(node.attr.x) then
				node.attr.x = node.attr.x + offsetXReal;
				node.attr.z = node.attr.z + offsetZReal;
				if(node.attr.bx) then
					node.attr.bx = x;
					node.attr.bz = z;
				end
			end

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
	
	local bSucceed = self:SaveXMLDataToFile(root, filename)
	return bSucceed;
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

	local bSucceed = self:SaveXMLDataToFile(root, filename)
	if bSucceed then
		GameLogic.GetFilters():apply_filters("OnSaveBlockRegion", true, self.region_x, self.region_z, "region.xml");
	end
end

-- return true if succeed
function RegionContainer:SaveXMLDataToFile(xmlRoot, filename)
	local bSucceed = false;
	if(xmlRoot) then
		local privateKey = WorldCommon.GetWorldTag("privateKey");
		if(privateKey) then
			xmlRoot.attr = xmlRoot.attr or {};
			xmlRoot.attr.privateKey = privateKey;
		end
		
		local xml_data = commonlib.Lua2XmlString(xmlRoot, true, true) or "";

		if (#xml_data >= 10240 or privateKey) then
			local writer = ParaIO.CreateZip(filename, "");
			if (writer:IsValid()) then
				writer:ZipAddData("data", xml_data);
				writer:close();

				if(privateKey) then
					NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
					local ZipFile = commonlib.gettable("System.Util.ZipFile");
					if(not ZipFile.GeneratePkgFile(filename, filename)) then
						LOG.std(nil, "warn", "RegionContainer",  "failed to encode file: %s", filename);
					end
				end
				bSucceed = true;
			end
		else
			local file = ParaIO.open(filename, "w");
			if(file:IsValid()) then
				file:WriteString(xml_data);
				file:close();

				bSucceed = true;
			end
		end
	end
	return bSucceed;
end

-- tag is a string that is saved along with the region's raw block file. 
function RegionContainer:GetRawRegionFileTag()
	if(not self.tag) then
		local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.region_x, self.region_z))
		self.tag = attRegion:GetField("Tag", "");
	end
	return self.tag;
end

-- tag is a string that is saved along with the region's raw block file. 
function RegionContainer:SetRawRegionFileTag(tag)
	if(self.tag ~= tag) then
		self.tag = tag;
		local attRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.region_x, self.region_z))
		attRegion:SetField("Tag", self.tag);
	end
end

function RegionContainer:LoadFromFile(filename)
	filename = filename or self:GetRegionFileName();

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	local privateKey = WorldCommon.GetWorldTag("privateKey");

	if (xmlRoot and privateKey and type(privateKey) == "string" and privateKey ~= "") then
		if (xmlRoot[1] and xmlRoot[1].attr and xmlRoot[1].attr.privateKey ~= privateKey) then
			return;
		end
	end
	local tag = self:GetRawRegionFileTag();
	-- TODO: check if tag equals private key, here
	

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

-- @param callbackFunc: this function is called when region is loaded and not locked. if nil, we will not create region if it does not exist
function RegionContainer:LoadRegion(callbackFunc)
	local attrRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.region_x, self.region_z))
	if(not attrRegion:IsValid()) then
		-- create region first
		ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), self.region_x * 512, 0, self.region_z * 512);
		attrRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.region_x, self.region_z))
	end
	if(callbackFunc and attrRegion:IsValid()) then
		if(attrRegion:GetField("IsLocked", false)) then
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				if(not attrRegion:IsValid() or not attrRegion:GetField("IsLocked", false)) then
					timer:Change()
					callbackFunc(true)
				end
			end})
			mytimer:Change(50, 100)
		else
			callbackFunc(true)
		end
	end
end