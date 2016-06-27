--[[
Title: SaveWorldHandler
Author(s): LiXizhi
Date: 2014/6/30
Desc: for saving/loading world info and other related data
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SaveWorldHandler.lua");
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local saveworldhandler = SaveWorldHandler:new():Init(world_path);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SavePlayerHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldInfo.lua");
local WorldInfo = commonlib.gettable("MyCompany.Aries.Game.WorldInfo")
local SavePlayerHandler = commonlib.gettable("MyCompany.Aries.Game.SavePlayerHandler")
local SaveWorldHandler = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler"));

function SaveWorldHandler:ctor()
end

-- @param world_path: if "", it will be a null handler 
function SaveWorldHandler:Init(world_path)
	self.world_path = world_path or ParaWorld.GetWorldDirectory();
	self.playerSaveHandler = SavePlayerHandler:new():Init(self);
	return self;
end

function SaveWorldHandler:GetPlayerSaveHandler()
	return self.playerSaveHandler;
end

function SaveWorldHandler:GetWorldPath()
	return self.world_path;
end

-- save world info to tag.xml under the world_path
function SaveWorldHandler:SaveWorldInfo(world_info)
	if(not world_info) then
		return false;
	end
	local world_path = self.world_path;
	world_path = string.gsub(world_path, "[/\\]$", "");
	local file = ParaIO.open(world_path.."/tag.xml", "w");
	if(world_path~="" and file:IsValid()) then
		-- create the tag.xml file under the world root directory. 
		local node = {name="pe:mcml",
			[1] = world_info:SaveToXMLNode(nil),
		}
		file:WriteString(commonlib.Lua2XmlString(node, true));
		file:close();
		LOG.std(nil, "info", "WorldInfo",  "saved");
		-- save success
		return true;
	else
		return false, "创建tag.xml出错了";	
	end
end

-- load world info from tag.xml under the world_path
function SaveWorldHandler:LoadWorldInfo()
	local world_info = WorldInfo:new();
	local world_path = self.world_path;
	world_path = string.gsub(world_path, "[/\\]$", "");

	local xmlRoot = ParaXML.LuaXML_ParseFile(world_path.."/tag.xml");
	if(xmlRoot) then
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
			world_info:LoadFromXMLNode(node);
			break;
		end
	end
	return world_info;
end

