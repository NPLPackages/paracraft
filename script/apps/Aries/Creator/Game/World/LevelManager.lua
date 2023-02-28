--[[
Title: Level manager
Author(s): yangguiyi
Date: 2022/6/16
Desc: saving and loading data of a given region to temp folder
-----------------------------------------------
local LevelManager = NPL.load("(gl)script/apps/Aries/Creator/Game/World/LevelManager.lua");
LevelManager.Save()
LevelManager.Load()
-----------------------------------------------
]]
local LevelManager = NPL.export();
NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");
--[[
	options={
		region ={x=37,y=37},
		exclude_region = {x=37,y=37},
		with={"bag","pos","camera","time","sky"}
	}
]]

LevelManager.temp_path = "temp/savelevels/"
function LevelManager.Save(level_name, options)
	level_name = level_name or "lastsave"
	options = options or {}
	
	local local_path = LevelManager.GetLocalFilePath(level_name)
	
	if LevelManager.Check(level_name) then
		ParaIO.DeleteFile(local_path);
	end
	ParaIO.CreateDirectory(local_path)

	-- 地块和entity处理
	LevelManager.SaveRegion(local_path, options.region, options.exclude_region)
	
	options.with = options.with or {"bag","pos","camera","time","sky"}
	local with_t = {}
	for index = 1, #options.with do
		with_t[options.with[index]] = true
	end

	-- 用户数据处理
	LevelManager.SaveUser(local_path, with_t)

	-- 天空盒处理
	if with_t.sky then
		LevelManager.SaveSky(local_path)
	end
end

function LevelManager.Load(level_name)
	level_name = level_name or "lastsave"	
	local local_path = LevelManager.GetLocalFilePath(level_name)
	if not ParaIO.DoesFileExist(local_path) then
		return false
	end

	-- 地块和entity处理
	LevelManager.LoadRegion(local_path)

	-- 人物属性处理 包括背包信息， 主角位置，摄影机方向，时间
	LevelManager.LoadUser(local_path)

	-- 天空盒
	LevelManager.LoadSky(local_path)
	return true
end

function LevelManager.Check(level_name)
	local local_path = LevelManager.GetLocalFilePath(level_name)
	return ParaIO.DoesFileExist(local_path)
end

function LevelManager.GetLevels()
	local filesOut = {};
	local parentDir = LevelManager.GetLocalFilePath()
	commonlib.Files.Find(filesOut, parentDir, 0, 1000, "*");

	local fileCount = 0;
	local level_name_list = {}
	-- print all files in zip file
	for i = 1,#filesOut do
		local item = filesOut[i];
		level_name_list[i] = item.filename
	end

	return level_name_list
end

function LevelManager.SaveRegion(local_path, region, exclude_region)
	if not local_path then
		return
	end

	local full_path = ParaIO.GetWritablePath() .. local_path
	if region then
		if region.x and region.y then
			local region = ExternalRegion:new():Init(full_path, region.x, region.y);
			region:Save();
		end
	else
		local worldAtt = ParaBlockWorld.GetBlockAttributeObject(GameLogic.GetBlockWorld());

		local exclude_region_x = exclude_region and exclude_region.x
		local exclude_region_y = exclude_region and exclude_region.y
		for i = 0, worldAtt:GetChildCount() - 1 do
			local regionAtt = worldAtt:GetChildAt(i);
			local x, y = regionAtt:GetField("RegionX"), regionAtt:GetField("RegionZ")
			local create_flag = x and y
			if create_flag and exclude_region_x and exclude_region_y then
				create_flag = exclude_region_x ~= x and exclude_region_y ~= y
			end

			if create_flag then
				local region = ExternalRegion:new():Init(full_path, x, y);
				region:Save();
			end
		end			
	end
end

-- 位置 背包 摄像机
function LevelManager.SaveUser(local_path, with_t)
	if not local_path then
		return
	end

	-- 人物属性处理 包括背包信息， 主角位置，摄影机方向，时间
	local file_name = local_path .. "player.entity.xml"
	local entity = GameLogic.GetPlayer()
	ParaIO.CreateDirectory(file_name);
	local file = ParaIO.open(file_name, "w");
	if(file:IsValid()) then
		local node = {name='entity', attr={}};
		entity:SaveToXMLNode(node);
		if not with_t.pos then
			node.attr.bx, node.attr.by, node.attr.bz = nil, nil, nil
		end
		if not with_t.pos then
			for i=1, #node do
				if node[i].name == "inventory" then
					node[i] = nil
				end
			end
		end
		if with_t.camera then
			node.attr.camera_dist = GameLogic.options:GetCameraObjectDistance();
			node.attr.camera_pitch = ParaCamera.GetAttributeObject():GetField("CameraLiftupAngle");
			node.attr.camera_facing = ParaCamera.GetAttributeObject():GetField("CameraRotY");
		end

		if with_t.time then
			node.attr.time = GameLogic.GetSim():GetTimeOfDayStd()
		end
		file:WriteString(commonlib.Lua2XmlString(node,true, true) or "");
		file:close();
	end
end

-- 天空盒
function LevelManager.SaveSky(local_path)
	if not local_path then
		return
	end

	local file_name = local_path .. "sky.entity.xml"
	local entity = GameLogic.GetSkyEntity()
	ParaIO.CreateDirectory(file_name);
	local file = ParaIO.open(file_name, "w");
	if(file:IsValid()) then
		local node = {name='entity', attr={}};
		entity:SaveToXMLNode(node);
		node.attr.weater = GameLogic.options:GetWeather()
		file:WriteString(commonlib.Lua2XmlString(node,true, true) or "");
		file:close();
	end
end

-- 加载地块
function LevelManager.LoadRegion(local_path)
	if not ParaIO.DoesFileExist(local_path .. "blockWorld.lastsave") then
		return
	end

	local full_path = ParaIO.GetWritablePath() .. local_path
	local worldAtt = ParaBlockWorld.GetBlockAttributeObject( GameLogic.GetBlockWorld());
	local count = worldAtt:GetChildCount();

	for i = 0, count - 1 do
		local regionAtt = worldAtt:GetChildAt(i);
		local region = ExternalRegion:new():Init(full_path, regionAtt:GetField("RegionX"), regionAtt:GetField("RegionZ"));
		region:Load();
	end	
end


function LevelManager.LoadUser(local_path)
	local player = GameLogic.GetPlayer()
	local file_name = local_path .. "player.entity.xml"
	local xmlRoot = ParaXML.LuaXML_ParseFile(file_name);
	if(xmlRoot and xmlRoot[1]) then
		local attr = xmlRoot[1].attr or {}
		attr.skin = nil;
		attr.model_filename = nil;
		player:LoadFromXMLNode(xmlRoot[1]);
		player:SetBlockPos(tonumber(attr.bx), tonumber(attr.by), tonumber(attr.bz))

		-- 摄像机
		if attr.camera_dist then
			GameLogic.options:SetCameraObjectDistance(tonumber(attr.camera_dist))
			local att = ParaCamera.GetAttributeObject();
			att:SetField("CameraLiftupAngle", tonumber(attr.camera_pitch));
			att:SetField("CameraRotY", tonumber(attr.camera_facing));
		end
		if attr.time then
			GameLogic.GetSim():SetTimeOfDayStd(tonumber(attr.time));
		end
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
	local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
	QuickSelectBar.Refresh()
end

function LevelManager.LoadSky(local_path)
	local file_name = local_path .. "sky.entity.xml"
	local xmlRoot = ParaXML.LuaXML_ParseFile(file_name);
	if(xmlRoot and xmlRoot[1]) then
		local sky_entity = GameLogic.GetSkyEntity()
		if sky_entity then
			local weater = xmlRoot[1].attr.weater
			if weater and GameLogic.options:GetWeather() ~= weater then
				GameLogic.options:SetWeather(xmlRoot[1].attr.weater)
			end

			sky_entity:LoadFromXMLNode(xmlRoot[1]);
			sky_entity:RefreshSky()
		end
	end
end

function LevelManager.GetLocalFilePath(level_name)
	local id = GameLogic.options:GetWorldOption("kpProjectId")
	local project_name = GameLogic.options:GetWorldOption("name") or "savelevel"
	if id and id ~= "" and id ~= 0 then
		project_name = id
	end

	local path = string.format("%s%s/%s/", LevelManager.temp_path, System.User.keepworkUsername or "all", project_name)
	if not level_name then
		return path
	end
	return string.format("%s%s/", path, level_name)
end