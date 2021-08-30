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
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");

local EncryptWorld = NPL.load("(gl)script/apps/EncryptWorld/EncryptWorld.lua");

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
		local xml_data = commonlib.Lua2XmlString(xmlRoot, true, true) or "";

		if (EncryptWorld) then
			local privateKey = WorldCommon.GetWorldTag("privateKey")
	
			if (privateKey and type(privateKey) == "string" and #privateKey > 20) then
				xml_data = EncryptWorld:EncodeFile(xml_data, privateKey)
			end
		end

		if (#xml_data >= 10240) then
			local writer = ParaIO.CreateZip(filename, "");
			if (writer:IsValid()) then
				writer:ZipAddData("data", xml_data);
				writer:close();
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

function RegionContainer:LoadFromFile(filename)
	filename = filename or self:GetRegionFileName();

	local xmlRoot

	if (EncryptWorld) then
		local privateKey = WorldCommon.GetWorldTag("privateKey");
	
		local file = ParaIO.open(filename, "r");
	
		if (file:IsValid()) then
			local head_line = file:readline();
	
			if (head_line == 'encode') then
				local originData = EncryptWorld:DecodeFile(file:GetText(0, -1), privateKey);
				xmlRoot = ParaXML.LuaXML_ParseString(originData);
			else
				local zipFile = ParaIO.open(filename, "r")
	
				local o = {}
				local fileType = nil
	
				if (zipFile:IsValid()) then
					zipFile:ReadBytes(2, o)
		
					if (o[1] and o[2]) then
						fileType = o[1] .. o[2]
					end
				end
	
				if (fileType and fileType == "8075") then
					local zipFilename = filename:gsub(".xml", ".zip");
	
					ParaIO.CopyFile(filename, zipFilename, true)
	
					ParaAsset.OpenArchive(zipFilename, true);
	
					local data = "";
					local output = {};
	
					commonlib.Files.Find(output, "", 0, 100, ":data", zipFilename);
	
					local parentPath = zipFilename:gsub("[^/\\]+$", "")
	
					if #output ~= 0 then
						local unZipFile = ParaIO.open(parentPath .. output[1].filename, "r");
	
						if unZipFile:IsValid() then
							data = unZipFile:GetText(0, -1);
							unZipFile:close();
						end
					end
	
					ParaAsset.CloseArchive(zipFilename);
					ParaIO.DeleteFile(zipFilename);
	
					local originData = EncryptWorld:DecodeFile(data, privateKey);
	
					xmlRoot = ParaXML.LuaXML_ParseString(originData);
				else
					local data = file:GetText(0, -1);
	
					xmlRoot = ParaXML.LuaXML_ParseString(data);
				end
			end
	
			file:close();
		end
	else
		xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	end


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
