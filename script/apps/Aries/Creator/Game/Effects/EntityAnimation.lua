--[[
Title: Entity Animation
Author(s): LiXizhi
Date: 2014/3/6
Desc: predefined character animations goes here
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
EntityAnimation.Init();
EntityAnimation.PlayAnimation(entity, "lie")
EntityAnimation.PlayAnimation(entity, {"lie", 0,"sit"})
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");

-- @Note: id should be unique. id must be larger than 20000 
local anim_map = {
	["lie"] = {"character/Animation/CC/char_male_liedown.x", 20001},
	["sit"] = {"character/Animation/CC/char_male_sitdown.x", 20002},
	["sel"] = {"character/Animation/CC/CreatObjects.x", 20003},
	["SelectObject"] = {"character/Animation/CC/CreatObjects.x", 20003},
	["break"] = 71, 
	["create"] = 71, 
	["Break"] = 71, 
	["Create"] = 71, 
}

-- this is only used in haqi, intead of PC character. 
local anim_map_haqi = {
	["lie"] = {"character/Animation/v3/Sleep.x", 20001},
	["sit"] = {"character/Animation/v5/ElfFemale_sit.x", 20002},
	["sel"] = {"character/Animation/v3/SelectObjects.x", 20003},
	["SelectObject"] = {"character/Animation/v3/SelectObjects.x", 20003},
	["break"] = {"character/Animation/v5/ElfFemale_Break.x"}, 
	["create"] = {"character/Animation/v5/ElfFemale_Break.x"}, 
	["Break"] = {"character/Animation/v5/ElfFemale_Break.x"}, 
	["Create"] = {"character/Animation/v5/ElfFemale_Break.x"}, 
}

local anim_map_default;

function EntityAnimation.Init()
	if(EntityAnimation.isInited) then
		return
	end
	
	EntityAnimation.isInited = true;
	-- TODO: load anim_map from XML file?
	for name, data in pairs(anim_map) do
		if(type(data) == "table" and data[2] and data[2]>10000) then
			ParaAsset.CreateBoneAnimProvider(data[2], data[1], data[1], false);
		end
	end

	if(not System.options.mc) then
		for name, data in pairs(anim_map_haqi) do
			if(type(data) == "table" and data[2] and data[2]>10000) then
				ParaAsset.CreateBoneAnimProvider(data[2], data[1], data[1], false);
			end
		end
	end

	if(System.options.mc) then
		anim_map_player = anim_map;
	else
		anim_map_player = anim_map_haqi;
	end
end

-- create get animation id by filename
-- @param filename: must be string. 
-- @param entity: if not nil, we will fetch according to its type. 
function EntityAnimation.CreateGetAnimId(filename, entity)
	if(type(filename) == "number") then
		return filename;
	elseif(type(filename) =="string" and filename:match("^(%d+)$")) then
		return tonumber(filename);
	else
		if(entity) then
			local asset_file = entity:GetMainAssetPath();
			if(asset_file) then
				filename = anim_map_player[filename] or filename;
			else
				filename = anim_map[filename] or filename;
			end
		else
			filename = anim_map[filename] or filename;
		end
		
		local anim_id = -1;
		if(type(filename) == "table") then
			anim_id = filename[2] or -1;
			filename = filename[1];
		elseif(type(filename) == "number") then
			return filename;
		end
		return ParaAsset.CreateBoneAnimProvider(anim_id, filename, filename, false);
	end
end

