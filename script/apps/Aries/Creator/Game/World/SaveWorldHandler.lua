--[[
Title: SaveWorldHandler
Author(s): LiXizhi, big
CreateDate: 2014.6.30
ModifyDate: 2021.8.24
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
	if (not world_info) then
		return false;
	end

	return self:SaveWorldXmlNode(
		{
			name="pe:mcml",
			[1] = world_info:SaveToXMLNode(nil),
		}
	);
end

-- save world info to tag.xml under the world_path
function SaveWorldHandler:SaveWorldXmlNode(node)
	local worldPath = self.world_path;
	worldPath = string.gsub(worldPath, "[/\\]$", "");
	local tagPath = worldPath .. "/tag.xml";
	
	local function HasPrivateKey()
		local privateKey;	
		if (node and node[1].attr) then
			privateKey = node[1].attr.privateKey;
		elseif (node and node[1][1]) then
			privateKey = node[1][1].attr.privateKey;
		end
		if(type(privateKey) == 'string' and #privateKey > 20) then
			return true;
		end
	end

	local xml_data = commonlib.Lua2XmlString(node, true, true) or ""

	if (HasPrivateKey()) then
		local writer = ParaIO.CreateZip(tagPath, "");
		if (writer:IsValid()) then
			writer:ZipAddData("data", xml_data);
			writer:close();
			
			NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
			local ZipFile = commonlib.gettable("System.Util.ZipFile");
			if(not ZipFile.GeneratePkgFile(tagPath, tagPath)) then
				LOG.std(nil, "warn", "WorldInfo",  "failed to encode file: %s", tagPath);
			end
			return true;
		else
			return false, "创建tag.xml出错了";	
		end
	else
		local file = ParaIO.open(tagPath, "w");
		if (worldPath ~="" and file:IsValid()) then
			-- create the tag.xml file under the world root directory. 
			file:WriteString(xml_data);
			file:close();
			LOG.std(nil, "info", "WorldInfo",  "saved");
			return true;
		else
			return false, "创建tag.xml出错了";	
		end
	end
end


-- load world info from tag.xml under the world_path
function SaveWorldHandler:LoadWorldInfo()
	local xmlRoot = self:LoadWorldXmlNode();
	local world_info = WorldInfo:new();
	if(xmlRoot) then
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
			world_info:LoadFromXMLNode(node);
			break;
		end
	end

	return world_info;
end

function SaveWorldHandler:LoadWorldXmlNode()
	local worldPath = self.world_path;
	worldPath = string.gsub(worldPath, "[/\\]$", "");

	local xmlRoot = ParaXML.LuaXML_ParseFile(worldPath .. "/tag.xml");

	if (xmlRoot) then
		return xmlRoot;
	end
end