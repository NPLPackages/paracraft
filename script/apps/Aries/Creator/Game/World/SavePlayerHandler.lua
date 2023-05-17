--[[
Title: SavePlayerHandler
Author(s): LiXizhi
Date: 2014/6/30
Desc: for saving/loading local or network player to disk
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/SavePlayerHandler.lua");
local SavePlayerHandler = commonlib.gettable("MyCompany.Aries.Game.SavePlayerHandler")
local world_info = SavePlayerHandler:new();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local SavePlayerHandler = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.SavePlayerHandler"));

-- x,y,z,block_id
function SavePlayerHandler:ctor()
end

function SavePlayerHandler:Init(saveWorldHandler)
	self.saveWorldHandler = saveWorldHandler;
	return self;
end

function SavePlayerHandler:GetWorldPath()
	return self.saveWorldHandler:GetWorldPath();
end

-- write player data to disk
function SavePlayerHandler:WritePlayerData(entity, parentDirectory)
	local name = entity:GetUserName() or "default";
	local filename = format("%splayers/%s.entity.xml", parentDirectory or self:GetWorldPath(), name);
	ParaIO.CreateDirectory(filename);
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		local node = {name='entity', attr={}};
		entity:SaveToXMLNode(node);
		file:WriteString(commonlib.Lua2XmlString(node,true, true) or "");
		file:close();
		LOG.std(nil,"info", "SavePlayerHandler", "saved player %s to file", name);
		return true;
	end
end

-- read player data from disk
function SavePlayerHandler:ReadPlayerData(entity)
	local name = entity:GetUserName() or "default";
	local filename = format("%splayers/%s.entity.xml", self:GetWorldPath(), name);
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot and xmlRoot[1]) then
		local node = xmlRoot[1]
		if( GameLogic.IsSocialWorld() and node.attr) then
			-- disable skin and main asset, using the social outfit for current player. 
			if(node.attr.skin) then
				node.attr.skin = nil;
			end
			if(node.attr.model_filename) then
				node.attr.model_filename = nil;
			end
		end
		entity:LoadFromXMLNode(node);
		LOG.std(nil,"info", "SavePlayerHandler", "loaded player %s from file", name);
		return node;
	end
end