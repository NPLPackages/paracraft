--[[
Title: External region
Author(s): LiXizhi
Date: 2021/4/18
Desc: We can replace a region in current world with an external region in another world. 
All blocks and entities in the external region are loaded from and saved to the external world directory. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");
local region = ExternalRegion:new():Init("worlds/DesignHouse/lixizhi_main", 37, 37)
region:Load();
region:Save();
region:SaveAs(nil, 37, 38)
-----------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldFileProvider.lua");
local WorldFileProvider = commonlib.gettable("MyCompany.Aries.Game.World.WorldFileProvider");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ExternalRegion = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion"))

function ExternalRegion:ctor()
end

-- @param worldpath: if nil, it will be current working directory
function ExternalRegion:Init(worldpath, regionX, regionY)
	local fileprovider = WorldFileProvider:new():Init(worldpath);
	local baseDir = fileprovider:GetBlockWorldDirectory()
	self.worldDir = fileprovider:GetWorldDirectory()
	self.regionX = regionX
	self.regionY = regionY
	self.regionRawFilename = format("%s%d_%d.raw", baseDir, regionX, regionY)
	self.regionEntityFilename = format("%s%d_%d.region.xml", baseDir, regionX, regionY)
	self.regionContainer = EntityManager.GetRegionContainer(regionX*512, regionY*512)
	self.regionContainer:SetExternalRegion(self)
	self.regionContainer:SetRegionFileName(self.regionEntityFilename);
	return self
end

function ExternalRegion:GetWorldDirectory()
	return self.worldDir
end

-- for temporary world bmax files, this shares the same directory with the paraworld chunk generator
function ExternalRegion:GetWorldSearchPath()
	if(not self.worldSearchPath) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua");
		local ParaWorldChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator");
		self.worldSearchPath = ParaWorldChunkGenerator:GetWorldSearchPath();
	end
	return self.worldSearchPath;
end

-- @param callbackFunc: this function is called when region is loaded and not locked. if nil, we will not create region if it does not exist
function ExternalRegion:GetRegionAttr(callbackFunc)
	local attrRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.regionX, self.regionY))
	if(attrRegion:IsValid()) then
		
	elseif(callbackFunc) then
		-- create region first
		ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), self.regionX * 512, 0, self.regionY * 512);
		attrRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.regionX, self.regionY))
	end
	if(callbackFunc and attrRegion:IsValid()) then
		if(attrRegion:GetField("IsLocked", false)) then
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				if(not attrRegion:IsValid() or not attrRegion:GetField("IsLocked", false)) then
					timer:Change()
					callbackFunc(attrRegion)
				end
			end})
			mytimer:Change(50, 100)
		else
			callbackFunc(attrRegion)
		end
	end

	return attrRegion;
end

-- clear all region blocks and block entities
function ExternalRegion:ClearRegion()
	local attrRegion = self:GetRegionAttr()
	attrRegion:CallField("DeleteAllBlocks");

	for i = 0, 31 do
		for j = 0, 31 do
			local x = self.regionX * 512 + i *16 + 8;
			local y = self.regionY * 512 + j *16 + 8;
			local timeStamp = ParaTerrain.GetChunkColumnTimeStamp(x, y);
			if(timeStamp <= 0) then
				ParaTerrain.SetChunkColumnTimeStamp(x, y, 1);
			end
		end
	end
	
	self.regionContainer:RemoveAll();
	BlockEngine.SetRegionLoaded(self.regionX, self.regionY, false)
end

-- copy all bmax files from external world to search path
function ExternalRegion:PrepareSearchPath()
	local searchPath = self:GetWorldSearchPath()
	Files.AddWorldSearchPath(searchPath)

	local result = commonlib.Files.Find({}, self.worldDir, 3, 10000, "*.bmax") or {};
	for i, file in ipairs(result) do
		local src = self.worldDir..file.filename
		local dest = searchPath..file.filename
		ParaIO.CreateDirectory(dest)
		if(not ParaIO.CopyFile(src, dest, true)) then
			LOG.std(nil, "warn", "ExternalRegion", "failed copy file from %s to %s", src, dest);
		end
	end
end

function ExternalRegion:Load()
	local attrRegion = self:GetRegionAttr(function(attrRegion)
		self:ClearRegion()
		self:PrepareSearchPath()
		attrRegion:SetField("LoadFromFile", self.regionRawFilename);
	end)
end

function ExternalRegion:Save()
	local attrRegion = self:GetRegionAttr()
	attrRegion:SetField("SaveToFile", self.regionRawFilename);
	self.regionContainer:SaveToFile();
	-- TODO: we need to find a way to save bmax files to dest directory during Block template saving
end

function ExternalRegion:HasBlocks()
	if(ParaIO.DoesAssetFileExist(self.regionRawFilename, true)) then
		return true
	end
end

-- better backup the world before this
-- @param worldpath: if nil, it will be current working directory
function ExternalRegion:SaveAs(worldpath, regionX, regionY)
	if(self.regionX ~= regionX or self.regionY ~= regionY or (worldpath and worldpath~=GameLogic.GetWorldDirectory())) then
		local fileprovider = WorldFileProvider:new():Init(worldpath);
		local baseDir = fileprovider:GetBlockWorldDirectory()
		local worldDir = fileprovider:GetWorldDirectory()
		local regionRawFilename = format("%s%d_%d.raw", baseDir, regionX, regionY)
		local regionEntityFilename = format("%s%d_%d.region.xml", baseDir, regionX, regionY)
		if(self.regionContainer:SaveToAnotherRegion(regionEntityFilename, regionX, regionY)) then
			LOG.std(nil, "info", "ExternalRegion", "successfully save from %s to %s", self.regionEntityFilename, regionEntityFilename);
		end
		if(ParaIO.CopyFile(self.regionRawFilename, regionRawFilename, true)) then
			LOG.std(nil, "info", "ExternalRegion", "successfully copy from %s to %s", self.regionRawFilename, regionRawFilename);
		end
	end
end