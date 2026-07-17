--[[
Title: Player Skins
Author(s): LiXizhi
Date: 2014/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
PlayerSkins:Init();
PlayerSkins:GetSkinsById(filename, skinId)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")

local last_index = 1;

-- models that has custom skin
local models_has_skin = {
	["character/CC/02human/actor/actor.x"] = true,
	["character/CC/01char/char_male.x"] = true,
	["character/CC/01char/MainChar/MainChar.x"] = true,
}
local models_default_skins = {
	["character/CC/02human/actor/actor.x"] = "Texture/blocks/human/boy_worker01.png",
	["character/CC/01char/char_male.x"] = "Texture/blocks/human/boy_blue_shirt01.png",
	["character/CC/01char/MainChar/MainChar.x"] = "Texture/blocks/human/boy_blue_shirt01.png",
}

local defaultModelFile = "character/CC/02human/actor/actor.x";

-- mapping from group name to array of skins
local skinGroups = {};
-- mapping from filename to model, which is mapping from skinid to skins
local models = {};
local noSkinModels = {};
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
		for groupNode in commonlib.XPath.eachNode(root, "/PlayerSkins/groups/group") do
			local groupName = groupNode.attr.name;
			local group = {tag = groupNode.attr.tag}
			skinGroups[groupName] = group;

			for node in commonlib.XPath.eachNode(groupNode, "/skin") do
				local attr = node.attr;
				if(attr and attr.filename) then
					attr.name = L(attr.name);
					group[#group+1] = attr;
					if(attr.alias and attr.alias~="") then
						skin_alias_map[attr.alias] = attr;
						skin_string_to_id[attr.alias] = id;
					end
					skin_string_to_id[attr.filename] = id;
					attr.id = tostring(id);
					id = id + 1;
				end
			end
		end
		for modelNode in commonlib.XPath.eachNode(root, "/PlayerSkins/models/model") do
			
			local model = {};
			for _, skinidNode in ipairs(modelNode) do
				local skin = skinidNode.attr;
				local id = tonumber(skin.id);
				local group = skinGroups[skin.group]
				if(id and group) then
					model[id] = group;
				end
			end
			local filter = modelNode.attr.filter
			for filename in filter:gmatch("[^;]+") do
				models[filename] = model;
			end
		end
		
		LOG.std(nil, "info", "PlayerSkins", "%d skins loaded from %s", id, filename);
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

-- deprecated: whether a given model has skin
function PlayerSkins:CheckModelHasSkin(asset_filename)
	if(asset_filename and models_has_skin[asset_filename]) then
		return true;
	end
end

function PlayerSkins:GetDefaultSkinForModel(filename)
	return models_default_skins[filename];
end

-- deprecated: 
-- @param id: integer
function PlayerSkins:GetSkinByID(id)
	local skins = self:GetSkinsById(defaultModelFile, 2)
	if(skins and id) then
		id = ((id) % (#skins)) + 1;
		local skin = skins[id];
		if(skin) then
			return skin.filename;
		end
	end
end

-- deprecated: 
function PlayerSkins:GetNextSkin(bPreviousSkin)
	if(bPreviousSkin) then
		last_index = last_index-1;
	else
		last_index = last_index+1;
	end
	return self:GetSkinByID(last_index);
end

-- deprecated: 
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

-- deprecated: use GetSkinsById instead
function PlayerSkins:GetSkinDS()
	self:Init();
	return self:GetSkinsById(defaultModelFile, 2);
end

-- return nil or a table mapping from skin id to array of replaceable skins. 
function PlayerSkins:GetModel(filename)
	if(models[filename]) then
		return models[filename];
	elseif(noSkinModels[filename]) then
		return;
	else
		for filter, model in pairs(models) do
			if (filename:match(filter)) then
				models[filename] = model;
				return model;
			end
		end
		noSkinModels[filename] = true;
	end
end

-- @param skinId: default to 2
-- @return array of replaceable skins. 
function PlayerSkins:GetSkinsById(filename, skinId)
	local model = self:GetModel(filename);
	return model and model[skinId or 2];
end

-- @param tag: such as "eye|mouth|body|hair|leg|foot|head"
-- @return skins, skinId: array of replaceable skins.
function PlayerSkins:GetSkinsByTag(filename, tag)
	local model = self:GetModel(filename);
	if(model) then
		for skinId, skins in pairs(model) do
			if(skins.tag == tag) then
				return skins, skinId;
			end
		end
	end
end

-- open the skin editor for the given entity
-- @param entity: the entity to edit skin for.
-- @param callbackFunc: function(bSucceed) end
function PlayerSkins:OpenEditor(entity, callbackFunc)
	if(entity) then
		local assetFilename = entity:GetMainAssetPath();
		if entity.GetSkin then
			local old_value = entity:GetSkin();
		end

		if(entity.IsCustomModel and entity:IsCustomModel()) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/EditCCSTask.lua");
			local EditCCSTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCCSTask");
			EditCCSTask:ShowPage(entity, function(ccsString)
				if(ccsString ~= old_value) then
					entity:SetSkin(ccsString);
					if(callbackFunc) then
						callbackFunc(true, ccsString, old_value);
					end
					-- GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
					-- 	if(isVip) then
					-- 		entity:SetSkin(ccsString);
					-- 		if(callbackFunc) then
					-- 			callbackFunc(true);
					-- 		end
					-- 	end
					-- end)
				end
			end);
		elseif(entity.HasCustomGeosets and entity:HasCustomGeosets()) then
			local old_value = entity:GetSkin()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
			local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
			CustomSkinPage.ShowPage(function(filename, skin)
				if (filename and skin~=old_value) then
					entity:SetSkin(skin);
					if(callbackFunc) then
						callbackFunc(true, skin, old_value);
					end
				end
			end, old_value,assetFilename);
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
			local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
			assetFilename = PlayerAssetFile:GetNameByFilename(assetFilename)
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
			local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
			EditSkinPage.ShowPage(function(result)
				if(result and result~=old_value) then
					entity:SetSkin(result);
					if(callbackFunc) then
						callbackFunc(true, result, old_value);
					end
					-- GameLogic.IsVip("ChangeAvatarSkin", true, function(isVip) 
					-- 	if(isVip) then
					-- 		entity:SetSkin(result);
					-- 		if(callbackFunc) then
					-- 			callbackFunc(true);
					-- 		end
					-- 	end
					-- end)
				end
			end, old_value, "", assetFilename)
		end
	end
end
