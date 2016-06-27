--[[
Title: WorldFileProvider
Author(s): LiXizhi
Date: 2014/7/26
Desc: for easy accessing of all files in the world directory. Currently only disk file is supported. 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldFileProvider.lua");
local WorldFileProvider = commonlib.gettable("MyCompany.Aries.Game.World.WorldFileProvider");
local fileprovider = WorldFileProvider:new():Init();
echo(fileprovider:GetAllRegionCoords());
-----------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UniversalCoords.lua");
local UniversalCoords = commonlib.gettable("MyCompany.Aries.Game.Common.UniversalCoords");

local WorldFileProvider = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.WorldFileProvider"))

function WorldFileProvider:ctor()
	self.worldpath = "worlds/test/";
end

-- @param worldpath: if nil, it will be current working directory
function WorldFileProvider:Init(worldpath)
	worldpath = worldpath or ParaWorld.GetWorldDirectory();
	self.worldpath = self:MakeValidWorldDirectory(worldpath);
	return self;
end

-- static function: it make sure that forward slash is used. and it ends with a slash. 
function WorldFileProvider:MakeValidWorldDirectory(worldpath)
	worldpath = worldpath:gsub("\\", "/")
	if(not worldpath:match("/$")) then
		worldpath = worldpath.."/"
	end
	return worldpath;
end

function WorldFileProvider:GetWorldDirectory()
	return self.worldpath;
end

function WorldFileProvider:GetBlockWorldDirectory()
	return self:GetWorldDirectory().."blockWorld.lastsave/";
end

-- search the disk directory and locate al the block files. 
-- @return array of universal cooridinates. 
function WorldFileProvider:GetAllRegionCoords()
	local dir = self:GetBlockWorldDirectory();

	local result = commonlib.Files.Find({}, dir, 0, 500, function(item)
		local ext = commonlib.Files.GetFileExtension(item.filename);
		if(ext) then
			return (ext == "raw");
		end
	end)
	local coords = commonlib.UnorderedArray:new();
	
	for _, file in ipairs(result) do
		local regionX, regionZ = file.filename:match("(%d+)_(%d+)%.raw$");
		if(regionX and regionZ) then
			regionX, regionZ = tonumber(regionX), tonumber(regionZ)
			coords:add(UniversalCoords:new():FromRegion(regionX, regionZ));
		end
	end
	return coords;
end


