--[[
Title: Player Skins
Author(s): LiXizhi
Date: 2014/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")

local last_index = 1;

-- array of all registered skins
local skins = {
	-- {name="", filename="Texture/blocks/human/boy_blue_shirt01.png", alias=""},
}

-- models that has custom skin
local models_has_skin = {
	["character/CC/02human/actor/actor.x"] = true,
	["character/CC/01char/char_male.x"] = true,
	["character/CC/01char/MainChar/MainChar.x"] = true,
}

local skin_alias_map = {};
local skin_string_to_id = {};

-- called only once
function PlayerSkins:Init()
	if(self.is_inited) then
		return;
	end
	self.is_inited = true;
	local filename = "config/Aries/creator/PlayerSkins.xml";
	local root = ParaXML.LuaXML_ParseFile(filename);
	if(root) then
		local id = 0;
		for node in commonlib.XPath.eachNode(root, "/PlayerSkins/skin") do
			local attr = node.attr;
			if(attr and attr.filename) then
				attr.name = L(attr.name);
				skins[#skins+1] = attr;
				if(attr.alias and attr.alias~="") then
					skin_alias_map[attr.alias] = attr;
					skin_string_to_id[attr.alias] = id;
				end
				skin_string_to_id[attr.filename] = id;
				attr.id = tostring(id);
				id = id + 1;
			end
		end
		LOG.std(nil, "info", "PlayerSkins", "%d skins loaded from %s", #skins, filename);
	else
		LOG.std(nil, "error", "PlayerSkins", "can not find file at %s", filename);
	end
end

function PlayerSkins:GetFileNameByAlias(filename)
	if(filename and skin_alias_map[filename]) then
		return skin_alias_map[filename].filename;
	else
		return Files:GetFileFromCache(filename) or filename;
	end
end

-- whether a given model has skin
function PlayerSkins:CheckModelHasSkin(asset_filename)
	if(asset_filename and models_has_skin[asset_filename]) then
		return true;
	end
end

-- @param id: integer
function PlayerSkins:GetSkinByID(id)
	id = ((id) % (#skins)) + 1;
	local skin = skins[id];
	if(skin) then
		return skin.filename;
	end
end

function PlayerSkins:GetNextSkin(bPreviousSkin)
	if(bPreviousSkin) then
		last_index = last_index-1;
	else
		last_index = last_index+1;
	end
	return self:GetSkinByID(last_index);
end

-- get skin id. or return nil if no id is found for the given filename.  
function PlayerSkins:GetSkinID(filename)
	return skin_string_to_id[filename];
end

function PlayerSkins:GetSkinByString(str)
	local skin_filename = str;
	if(str == "") then
		skin_filename = self:GetNextSkin();
	elseif(str:match("^%d+$")) then
		local skin_id = str:match("^%d+$");
		skin_id = tonumber(skin_id);
		skin_filename = self:GetSkinByID(skin_id);
	else
		skin_filename = self:GetFileNameByAlias(skin_filename or "");
		skin_filename = Files.FindFile(skin_filename, "Texture/blocks/human/");
	end
	return skin_filename;
end

function PlayerSkins:GetSkinDS()
	if(not next(skins)) then
		self:Init();
	end
	return skins;
end