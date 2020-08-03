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
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
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

-- for haqi players
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
local assetNameToAnimMap = {
	["character/v3/Elf/Female/ElfFemale.xml"] = anim_map_haqi,
}

-- id to name are also read from this xml file.
local modelAnimNamesFilename = "config/Aries/creator/modelAnim.xml";
local id_to_names = {
	[0] = L"待机", 
	[1] = L"倒下", 
	[4] = L"走路", 
	[5] = L"跑步", 
	[13] = L"向后走", 
	[37] = L"向上跳的起始动作", 
	[38] = L"跳动中，在空中的动作", 
	[39] = L"落地的动作", 
	[41] = L"游泳（水中）的待机", 
	[42] = L"向前游动", 
	[43] = L"向左游动", 
	[44] = L"向右游动", 
	[45] = L"向后游动", 
	[91] = L"缺省的坐骑", 
	[135] = L"飞行", 
	[153] = L"随机待机1", 
	[154] = L"随机待机2", 
	[155] = L"随机待机3", 
	[156] = L"随机待机4", 
	[20001] = L"躺下", 
	[20002] = L"坐下", 
	[20003] = L"选择", 
}

local assetNameToAnims = {};

function EntityAnimation.Init()
	if(EntityAnimation.isInited) then
		return
	end
	EntityAnimation.isInited = true;
end

function EntityAnimation.GetAnimMapByAssetFile(filename)
	local animMap = filename and assetNameToAnimMap[filename] or anim_map;
	if(not animMap.isLoaded__) then
		animMap.isLoaded__ = 1;
		for name, data in pairs(animMap) do
			if(type(data) == "table" and data[2] and data[2]>10000) then
				ParaAsset.CreateBoneAnimProvider(data[2], data[1], data[1], false);
			end
		end
	end
	return animMap
end

-- public 
-- @param id: animation id
-- @param assetfile: some well known asset file name, such as "actor" or ""
function EntityAnimation.GetAnimTextByID(id, assetfile)
	local idToNames = EntityAnimation.GetIdNameMapByAssetfile(assetfile) or id_to_names;
	idToNames = idToNames or id_to_names;
	local text = idToNames[id or -1];
	if(text) then
		text = format("%d (%s)", id, text);
	end
	return text;
end

-- return nil or anim id to name map table for the given asset file
function EntityAnimation.GetIdNameMapByAssetfile(assetfile)
	if(assetfile) then
		EntityAnimation.InitAnimNames();
		return assetNameToAnims[assetfile];
	end
end

function EntityAnimation.InitAnimNames()
	if(EntityAnimation.initedAnimNames) then
		return
	end
	EntityAnimation.initedAnimNames = true;
	local xmlRoot = ParaXML.LuaXML_ParseFile(modelAnimNamesFilename);
	if(xmlRoot) then
		for node in commonlib.XPath.eachNode(xmlRoot, "/anims/model") do
			if(node.attr and node.attr.text) then
				local idNameMap = {};
				
				if(node.attr.path) then
					assetNameToAnims[node.attr.path] = idNameMap;
				end
				if(node.attr.name) then
					assetNameToAnims[node.attr.name] = idNameMap;
					local path = PlayerAssetFile:GetFilenameByName(node.attr.name)
					if(path) then
						assetNameToAnims[path] = idNameMap;
					end
				end
				if(node.attr.name2) then
					assetNameToAnims[node.attr.name2] = idNameMap;
					local path = PlayerAssetFile:GetFilenameByName(node.attr.name2)
					if(path) then
						assetNameToAnims[path] = idNameMap;
					end
				end

				for itemnode in commonlib.XPath.eachNode(node, "/anim") do
					if(itemnode.attr and itemnode.attr.id and itemnode.attr.desc) then
						local id = tonumber(itemnode.attr.id)
						if(id) then
							idNameMap[id] = L(itemnode.attr.desc)
						end
					end
				end
			end
		end
	else
		LOG.std(nil, "warn", "EntityAnimation", "failed to load from %s", modelAnimNamesFilename);
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
			filename = EntityAnimation.GetAnimMapByAssetFile(asset_file)[filename] or filename;
		else
			filename = EntityAnimation.GetAnimMapByAssetFile(nil)[filename] or filename;
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

