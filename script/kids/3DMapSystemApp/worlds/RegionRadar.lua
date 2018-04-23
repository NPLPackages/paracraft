--[[
Title: RegionRadar
Author(s): Leio
Date: 2009/9/28
Desc: 
 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
]]
------------------------------------------------------------
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
local format = format;
local math_floor = math.floor;
local RegionRadar = {
	duration = 100,--milliseconds 刷新周期
	min_radius = 5,--搜索最小半径
	max_radius = 1000,--搜索最大半径
	per_radius = 5,--每个周期 半径递增
	per_angle = 30,--在一个周期内 角度递增量
	is_searching = false,--是否正在搜索
	region_title = "move",
	region_color = {
		{color = "0_153_0",label = "星星游乐场",  key = "Region_StarStar", },
		{color = "204_153_0",label = "魔法学院",  key = "Region_FireCavern",},
		{color = "102_0_255",label = "火焰山洞",  key = "Region_MagmaCave", },
		{color = "255_255_152",label = "岩浆沙漠",  key = "Region_Desert", },
		{color = "102_51_0",label = "冰封雪域",  key = "Region_SnowArea3", },
		{color = "38_91_0",label = "魔法密林", key = "Region_MagicForest", },
		{color = "0_255_255",label = "生命之泉",  key = "Region_LifeSpring", },
		{color = "204_0_255",label = "牧场",  key = "Region_CommonField", },
		{color = "204_102_51",label = "跳跳农场",  key = "Region_JumpField", },
		{color = "0_102_255",label = "龙龙乐园",  key = "Region_Carnival", },
		{color = "255_0_0",label = "小镇中心区",  key = "Region_TownSquare", },
		{color = "255_255_0",label = "阳光海岸",  key = "Region_SunLine", },
		{color = "51_204_255",label = "海岸线",  key = "Region_SeaLine", },


		{color = "4_51_59",label = "未开放区域",  key = "unopen_square", isclosed = true,},
		{color = "255_255_255",label = "未开放区域",  key = "forbidden",isclosed = true,},
		{color = "0_0_0",label = "",  key = "none",},
		--{color = "204_0_255",label = "蜂窝果园",   key = "Region_Bee", },
		--{color = "102_0_255",label = "青青马场",   key = "Region_AquaHorse", },
		--{color = "0_255_255",label = "龙源密境",  key = "Region_DragonForest", },
		--{color = "204_102_51",label = "跳跳农场",  key = "Region_JumpJumpFarm", },
		--{color = "255_255_0",label = "阳光海岸",  key = "Region_SunnyBeach", },
		--{color = "255_102_0",label = "凯旋广场",  key = "Region_TriumphSquare", },
		--{color = "0_20_51",label = "雪山脚下",  key = "Region_SnowArea1", },
		--{color = "0_51_0",label = "绿野郊外",  key = "Region_WildForest", },
		--{color = "102_51_0",label = "松鼠谷",  key = "Region_SquirrelValley", },
	},
	last_x = 0,
	last_y = 0,
	last_z = 0,
	UpdateFunc = nil,
	worlds_region_color_map = nil,
} 
commonlib.setfield("Map3DSystem.App.worlds.RegionRadar",RegionRadar);
function RegionRadar:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self;
	o:Init();
	return o
end
function RegionRadar:Start()
	self:Resume();
end
function RegionRadar:Pause()
	if(self.timer)then
		self.timer:Change();
	end
end
function RegionRadar:Resume()
	if(self.timer)then
		self.timer:Change(0,self.duration);
	end
	self.cur_long_time = 0;
end
function RegionRadar:Init()
	self.events = {};
	self.timer = commonlib.Timer:new{callbackFunc = Map3DSystem.App.worlds.RegionRadar.Timer_CallBackFunc,};
	self.timer.radar = self;
	
	self.per_angle = math.min(self.per_angle,360);
	self.per_radius = math.min(self.per_radius,self.max_radius);
	
	self.cur_long_time = 0;
	self.last_x,self.last_y,self.last_z = ParaScene.GetPlayer():GetPosition();
	
end
function RegionRadar.Timer_CallBackFunc(t)
	if(t and t.radar)then
		local self = t.radar;
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		
		--检测位置
		local args = self:Update(x,y,z);
		if(self.UpdateFunc and type(self.UpdateFunc) == "function")then
			self.UpdateFunc(args);
		end
	end
end
--这个函数暂时没用
--检测是否在禁区，如果在，查找周围最近一个有效区域，把人物移动到那里
function RegionRadar:Search(x,y)
	if(not x or not y)then return end
	local old_x,old_y = x,y;
	--角度分割段
	local step_angle = math_floor(360/self.per_angle) - 1;
	--半径分割段
	local step_radius = math_floor(self.max_radius/self.per_radius) - 1;
	local start_x,start_y = x,y;
	local k_angle,k_radius;	
	
	for k_radius = 0,step_radius do
		--循环一周
		for k_angle = 0,step_angle do
			local angle = k_angle * self.per_angle;
			local radius = self.min_radius + k_radius * self.per_radius;
			local x = radius * math.cos(angle * math.pi/180) + start_x;
			local y = radius * math.sin(angle * math.pi/180) + start_y;
			
			local argb = ParaTerrain.GetRegionValue(self.region_title, x, y);
			local r,g,b = _guihelper.DWORD_TO_RGBA(argb);
			
			local rgb = format("%s_%s_%s",tostring(r) or "",tostring(g) or "",tostring(b) or "");
			--commonlib.echo(rgb);
			if(self.region_color)then
				local k,v;
				for k,v in ipairs(self.region_color) do
					local c = v["color"];
					local isclosed = v["isclosed"];
					if(c == rgb and not isclosed)then
						
						Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_TELEPORT_PLAYER, x = x or 20000, z = y or 20000});
						commonlib.echo("force move from:");
						local argb = ParaTerrain.GetRegionValue(self.region_title, old_x, old_y);
						local old_r,old_g,old_b = _guihelper.DWORD_TO_RGBA(argb);
						local old_rgb = format("%s_%s_%s",tostring(old_r) or "",tostring(old_g) or "",tostring(old_b) or "");
						commonlib.echo({old_x = old_x,old_y = old_y,old_rgb = old_rgb});
						commonlib.echo("to:");
						commonlib.echo({new_x = x,new_y = y});
						commonlib.echo("================");
						commonlib.echo(v);
						return;
					end
				end
			end
		end
	end
	--_guihelper.MessageBox("find nothing!");
	--commonlib.echo("find nothing!");
end

local default_value = {color = "0_0_0", label = "none",  key = "none", isclosed = nil,};
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
-- 注意：不要直接更改返回的值！
-- return {color = "4_51_59",label = "未开放区域",  key = "unopen_square", isclosed = true,},
-- Note: optimized by LiXizhi 2010.8.19. Duplicate input are cached, and _guihelper.DWORD_TO_RGBA is used. 
function RegionRadar:WhereIam(x,y)
	--local world_info = WorldManager:GetCurrentWorld()
	--if(world_info.name ~= "61HaqiTown") then
		--self.cur_value = default_value;
		--return default_value;
	--end

	if(self.cur_region_title == self.region_title and self.cur_x == x and self.cur_y == y) then
		return self.cur_value or default_value;
	end
	self.cur_region_title, self.cur_x, self.cur_y = self.region_title, x, y;
	-- LOG.std("", "debug", "RegionRadar", "(%.2f, %.2f)", x,y)
	local value;
	if(self.region_color)then
		local argb = ParaTerrain.GetRegionValue(self.region_title, x, y);
		local r,g,b = _guihelper.DWORD_TO_RGBA(argb);
		local rgb = format("%s_%s_%s",tostring(r) or "",tostring(g) or "",tostring(b) or "");
		--获取当前世界的region colors
        local world_path = ParaWorld.GetWorldDirectory();
        world_path = string.lower(world_path);
		local region_color;
		if(self.worlds_region_color_map)then
			local cur_world_region_color = self.worlds_region_color_map[world_path];
			if(cur_world_region_color)then
				region_color = cur_world_region_color[rgb];
				value = region_color;
			end
		end
	end
	if(self.cur_value ~= value) then
		--LOG.std("", "system", "RegionRadar", {value, x,y})
		self.cur_value = value;
	end
	return value or default_value;
end
--控制player是否可以移动
function RegionRadar:Update(x,y,z)
	if(not x or not y or not z)then return end
	local start_x,start_y,start_z = x,y,z;
	local k_angle;	
	--commonlib.echo("===============check");
	--commonlib.echo({x = x, y = y, z = z});
	local args = self:WhereIam(x,z);
	--commonlib.echo(args);
	if(args)then
		if(not args.isclosed)then
			--commonlib.echo("===============not closed");
			--commonlib.echo({x = x, y = y, z = z});
			self.last_x = x;
			self.last_y = y;
			self.last_z = z;
			return args
		end
		--if(args.isclosed)then
			----如果在禁区
			--Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_TELEPORT_PLAYER, x = self.last_x, y = self.last_y, z = self.last_z});
		--end
	end
	return args;
end
------------------------------------------------------------
--[[
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
Map3DSystem.App.worlds.Global_RegionRadar.Start()
Map3DSystem.App.worlds.Global_RegionRadar.End()
--]]
local Global_RegionRadar = commonlib.gettable("Map3DSystem.App.worlds.Global_RegionRadar");
Global_RegionRadar.radar = nil;

function Global_RegionRadar.Start()
	if(not Global_RegionRadar.radar)then
		local worlds_region_color_map = Global_RegionRadar.LoadWorldsRegion();
		Global_RegionRadar.radar = Map3DSystem.App.worlds.RegionRadar:new{
			duration = 100,--milliseconds 刷新周期
			worlds_region_color_map = worlds_region_color_map,
			UpdateFunc = function (args)
				-- call hook for OnGlobalRegionRadar
				local hook_msg = { aries_type = "OnGlobalRegionRadar", args = args, wndName = "RegionRadar"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
			end,
		}
	end
	Global_RegionRadar.radar:Start();
end
function Global_RegionRadar.End()
	if(Global_RegionRadar.radar)then
		Global_RegionRadar.radar:Pause();
	end
end
function Global_RegionRadar.WhereIam()
	if(Global_RegionRadar.radar)then
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		-- resolution of 0.1
		x, y = math_floor(x*10)/10, math_floor(z*10)/10;
		return Global_RegionRadar.radar:WhereIam(x,z);
	end
end

function Global_RegionRadar.WhereIsXZ(x, z)
	if(Global_RegionRadar.radar)then
		return Global_RegionRadar.radar:WhereIam(x,z);
	end
end
--[[
	NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
	local Global_RegionRadar = commonlib.gettable("Map3DSystem.App.worlds.Global_RegionRadar");
	local map = Global_RegionRadar.LoadWorldsRegion();
	commonlib.echo(map);
--]]
function Global_RegionRadar.LoadWorldsRegion()
	local result,result_map_id,result_map_desc = QuestHelp.GetWorldList();
	local region_color_map = {};
	if(result)then
		local k,world_node;
		for k,world_node in ipairs(result) do
			local region_color_file = world_node["region_color"];
			local desc = world_node["desc"];
			region_color_file = tostring(region_color_file);
			desc = tostring(desc);
			if(desc and region_color_file)then
				local world_color_map = {};
				local xmlRoot = ParaXML.LuaXML_ParseFile(region_color_file);
				local node;
				for node in commonlib.XPath.eachNode(xmlRoot, "/items/item") do
					local item = {};
					local kk,vv;
					for kk,vv in pairs(node.attr) do
						item[kk] = vv;
					end
					local color = node.attr.color;
					if(color)then
						world_color_map[color] = item;
					end
				end
		        desc = string.lower(desc);
				region_color_map[desc] = world_color_map;
			end
		end
	end
	return region_color_map;
end