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

function ExternalRegion:GetRegionAttr()
	local attrRegion = ParaTerrain.GetBlockAttributeObject():GetChild(format("region_%d_%d", self.regionX, self.regionY))
	if(attrRegion:IsValid()) then
		
	else
		-- TODO: create region first
	end
	return attrRegion;
end

-- clear all region blocks and block entities
function ExternalRegion:ClearRegion()
	local attrRegion = self:GetRegionAttr()
	attrRegion:CallField("DeleteAllBlocks");
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
	self:ClearRegion()
	local attrRegion = self:GetRegionAttr()
	self:PrepareSearchPath()
	attrRegion:SetField("LoadFromFile", self.regionRawFilename);
end

function ExternalRegion:Save()
	local attrRegion = self:GetRegionAttr()
	attrRegion:SetField("SaveToFile", self.regionRawFilename);
	self.regionContainer:SaveToFile();
	-- TODO: we need to find a way to save bmax files to dest directory during Block template saving
end
