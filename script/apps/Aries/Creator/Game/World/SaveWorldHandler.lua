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

local EncryptWorld = NPL.load("(gl)script/apps/EncryptWorld/EncryptWorld.lua");

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
	local world_path = self.world_path;
	world_path = string.gsub(world_path, "[/\\]$", "");
	local file = ParaIO.open(world_path .. "/tag.xml", "w");

	if (world_path ~="" and file:IsValid()) then
		local tagData = '';

		if (EncryptWorld) then
			local privateKey = '';
	
			if (node[1].attr) then
				privateKey = node[1].attr.privateKey;
			else
				-- zip file
				privateKey = node[1][1].attr.privateKey;
			end
	
			if (privateKey and type(privateKey) == 'string' and #privateKey > 20) then
				tagData = EncryptWorld:EncodeFile(commonlib.Lua2XmlString(node, true, true));
			else
				tagData = commonlib.Lua2XmlString(node, true, true);
			end
		else
			tagData = commonlib.Lua2XmlString(node, true, true);
		end

		-- create the tag.xml file under the world root directory. 
		file:WriteString(tagData);
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
	local world_path = self.world_path;
	world_path = string.gsub(world_path, "[/\\]$", "");
	local tag_path = world_path .. "/tag.xml";
	local xmlRoot;

	if (EncryptWorld) then
		local file = ParaIO.open(tag_path, "r");

		if (file:IsValid()) then
			local head_line = file:readline();

			if (head_line == 'encode') then
				local originData = EncryptWorld:DecodeFile(file:GetText(0, -1))

				xmlRoot = ParaXML.LuaXML_ParseString(originData);
			else
				local data = file:GetText(0, -1);

				xmlRoot = ParaXML.LuaXML_ParseString(data);
			end

			file:close();
		end
	else
		xmlRoot = ParaXML.LuaXML_ParseFile(tag_path);
	end

	if (xmlRoot) then
		return xmlRoot;
	end
end