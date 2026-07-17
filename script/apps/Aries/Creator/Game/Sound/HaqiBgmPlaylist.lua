--[[
Title: HaqiBgmPlaylist
Author(s): onedou
Date: 2026/6/24
Desc: Haqi(魔法哈奇) 客户端的区域背景音乐播放器。

背景:
  Haqi mc="false", 不使用方块, 区域判断完全依赖 region 掩码图层。
  Windows 上的哈奇依赖区域掩码机制来切换 BGM:
    RegionRadar -> ParaTerrain.GetRegionValue(title, x, y) 读
    地形上挂载的 regions/*.png region 图层 -> 颜色 RGB -> 经
    worlds_region_color_map 查表得 region key -> OnGlobalRegionRadar 钩子 ->
    Scene.PlayRegionBGMusic -> bg_sound_maps[key] -> 实际 wav/ogg。

  注意: GetRegionValue 这个 C++ API 在 cp_old 上是可用的, 失效的真因是**资源缺失**:
    (1) 本地哈奇跑在 _emptyworld, 这个空世界没有任何 regions/*.png 区域图层, 也
        没把任何 PNG 挂到 CurrentRegionFilepath 上, 所以 GetRegionValue 永远返回 0。
    (2) 即使切到 worlds/MyWorlds/61HaqiTown/, RegionRadar 还需要从
        config/Aries/Quests/worlds_list.xml 拿到对应世界的 region_color 表,
        而本旧 trunk 里该 xml 不存在。

  因此本播放器采用两层降级:
    [1] 优先: 走区域掩码。运行时探测当前世界是否有挂载可读的 region 图层
        (ParaTerrain.GetRegionValue("move", x, z) 在监督点能返回非 0 颜色)。
        能读到则直接按 PNG 原始 RGB 解析出 region key,
        再用 regionKeyToArea 映射到具体曲目。BGM 这里刻意不优先走
        worlds_region_color_map, 避免旧配置把 0_0_0 空白像素误映射成 forbidden。
    [2] 兜底: 掩码不可用时, 降到多曲随机播放列表, 保证一定有声音。

  另提供 HaqiBgmPlaylist.Diagnostics() 把每一步的实际状态打印出来,
  方便定位资源缺失 (启动世界 / region PNG / worlds_list.xml / 音频文件)。

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/HaqiBgmPlaylist.lua");
local HaqiBgmPlaylist = commonlib.gettable("MyCompany.Aries.Game.Sound.HaqiBgmPlaylist");
HaqiBgmPlaylist:Start();
HaqiBgmPlaylist:Stop();
HaqiBgmPlaylist:PauseForReplace();
HaqiBgmPlaylist:ResumeForReplace();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");
NPL.load("(gl)script/ide/FileLoader.lua");
local FileLoader = commonlib.gettable("CommonCtrl.FileLoader");
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");

local HaqiBgmPlaylist = commonlib.gettable("MyCompany.Aries.Game.Sound.HaqiBgmPlaylist");

-- 区域 -> BGM 文件映射 (对齐 Windows 版 Scene.main.lua 的 bg_sound_maps)
HaqiBgmPlaylist.regionToMusic = {
	town       = "Audio/Haqi/AriesRegionBGMusics/Area_Christmas.ogg",
	forest     = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
	snow       = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
	beach      = "Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg",
	farm       = "Audio/Haqi/AriesRegionBGMusics/Area_Farm.ogg",
	carnival   = "Audio/Haqi/AriesRegionBGMusics/Area_Carnival.ogg",
	firecavern = "Audio/Haqi/AriesRegionBGMusics/Area_FireCavern.ogg",
};

-- 与 Windows 版 Scene.main.lua 的 bg_sound_maps 完全一致:
-- RegionRadar 解析出来的 region key (Region_xxx) -> BGM 曲目名(Area_xxx)。
-- mask 路径成功取出 region key 后, 用这张表得到具体曲目, 再经 regionToMusic
-- 映射到 ogg 路径; 与原版的体验完全等价。
HaqiBgmPlaylist.regionKeyToArea = {
	Region_MagicForest   = "forest",
	Region_LifeSpring    = "forest",
	Region_DragonForest  = "forest",
	Region_WildForest    = "forest",
	Region_SnowArea1     = "snow",
	Region_SquirrelValley= "snow",
	Region_SnowArea3     = "snow",
	Region_FireCavern    = "firecavern",
	Region_Desert        = "firecavern",
	Region_Bee           = "town",
	Region_AquaHorse     = "town",
	Region_Carnival      = "town",
	Region_TownSquare    = "town",
	Region_TriumphSquare = "town",
	Region_JumpJumpFarm  = "farm",
	Region_JumpField     = "farm",
	Region_WatermelonField = "farm",
	Region_CommonField   = "farm",
	Region_StarStar      = "town",
	Region_SunnyBeach    = "beach",
	Region_SeaLine       = "beach",
	Region_SunLine       = "beach",
	Region_MagmaCave     = "firecavern",
	-- 61haqitown 实际 PNG 中存在的颜色
	Region_DeepSea       = "beach",
	Region_GreenPlain    = "forest",
};

-- 世界目录名 (ParaWorld.GetWorldDirectory() 取出的最后一段, 大小写不敏感)
-- -> 区域 BGM key (town/forest/...).
-- 在 region PNG 图层 + worlds_list.xml 缺失的旧 trunk 上, 这是唯一可靠的
-- 区域判定途径: 每个哈奇岛屿本身就是一个主地形区域, 玩家切岛屿 = 切区域。
HaqiBgmPlaylist.worldDirToRegion = {
	["61haqitown"]          = "town",        -- 哈奇主城 (含广场/农场/海岸多个 PNG 区, 但默认主城调)
	["frostroarisland"]     = "snow",        -- 霜吼岛 -> 雪区
	["flamingphoenixisland"]= "firecavern",  -- 火凤岛 -> 火山/沙漠
	["darkforestisland"]    = "forest",      -- 暗黑森林岛
	["ancientegyptisland"]  = "firecavern",  -- 古埃及岛 -> 沙漠/火山
	["darkforestsnowisland"]= "snow",        -- (部分版本名) 雪区
};
-- 多区域岛屿 (61HaqiTown 主城) 里, 玩家落在不同坐标应播不同曲:
-- 这里不做 PNG 解析也不可能做, 折中: 主城用 "town"。如果将来 PNG/颜色表恢
-- 复, regionKeyToArea 链路优先, 会自动覆盖此映射。

-- 区域掩码相关参数
-- RegionRadar 读哪个 region title (即 CurrentRegionName / region 图层名)。
-- Windows 哈奇的区域雷达用 "move"。如果你为本地世界自己生成了 region PNG 图层,
-- 改成对应图层名即可。
HaqiBgmPlaylist.regionTitle = "move";
-- 是否优先尝试区域掩码链路; 关掉则一律走兜底随机播放
HaqiBgmPlaylist.useRegionMask = true;

-- 哈奇主城局部地图的 region tile 索引范围。见 pe:worldmap 的
-- StartIndex/EndIndex: 35..39, tile world size: 533.33。
HaqiBgmPlaylist.regionTileSize = 533.33;
HaqiBgmPlaylist.regionTileStartIndex = 35;
HaqiBgmPlaylist.regionTileEndIndex = 39;
HaqiBgmPlaylist.regionAssetManifest = "apps/haqi/assets_manifest.txt";

HaqiBgmPlaylist.worldDirToRegionMaskWorldPath = {
	["61haqitown"] = "worlds/MyWorlds/61HaqiTown",
	["61haqitown_teen"] = "worlds/MyWorlds/61HaqiTown_teen",
	["flamingphoenixisland"] = "worlds/MyWorlds/FlamingPhoenixIsland",
	["flamingphoenixisland_teen"] = "worlds/MyWorlds/FlamingPhoenixIsland_teen",
	["frostroarisland"] = "worlds/MyWorlds/FrostRoarIsland",
	["frostroarisland_teen"] = "worlds/MyWorlds/FrostRoarIsland_teen",
	["darkforestisland"] = "worlds/MyWorlds/DarkForestIsland",
	["darkforestisland_teen"] = "worlds/MyWorlds/DarkForestIsland_teen",
};

-- 61HaqiTown 的 region PNG 在 mac/cp_old 下读取不可靠时, 使用 LocalMap.html
-- 中各地图点的 AvatarPosition 做最近点兜底。坐标来自
-- script/apps/Aries/Desktop/WorldMaps/LocalMap.html。
HaqiBgmPlaylist.haqiTownPositionAreas = {
	{x = 19909.43, z = 20101.18, region = "forest", name = "magicforest"},
	{x = 19927.48, z = 19991.50, region = "forest", name = "dragonorien"},
	{x = 19997.70, z = 20007.54, region = "forest", name = "lifespring"},
	{x = 19739.62, z = 20077.70, region = "forest", name = "rockyforest"},
	{x = 19532.13, z = 20116.49, region = "forest", name = "forestogre"},

	{x = 19812.81, z = 20172.52, region = "snow", name = "snowarea1"},
	{x = 20031.93, z = 20310.85, region = "snow", name = "squirrelvalley"},
	{x = 19755.04, z = 20382.95, region = "snow", name = "snowarea3"},
	{x = 19949.96, z = 20460.89, region = "snow", name = "snowarea4"},

	{x = 19908.72, z = 19898.07, region = "farm", name = "farmhousechick"},
	{x = 19784.04, z = 19881.61, region = "farm", name = "watermelonfield"},
	{x = 19698.51, z = 19845.02, region = "farm", name = "seedfield"},
	{x = 19682.05, z = 19994.02, region = "farm", name = "starrylane"},
	{x = 19956.92, z = 19804.40, region = "farm", name = "watermill"},

	{x = 20034.55, z = 19631.83, region = "beach", name = "adventure"},
	{x = 20207.55, z = 19609.29, region = "beach", name = "sunshinestation"},
	{x = 20429.79, z = 19607.93, region = "beach", name = "timeportal"},

	{x = 20193.87, z = 19990.38, region = "firecavern", name = "cyandragon"},
	{x = 20372.44, z = 20139.88, region = "firecavern", name = "fireogre"},
	{x = 20355.18, z = 20294.25, region = "firecavern", name = "blazingdesert"},

	{x = 20001.36, z = 19879.09, region = "town", name = "carnival"},
	{x = 20069.58, z = 19741.63, region = "town", name = "townsquare"},
	{x = 20168.90, z = 19711.97, region = "town", name = "shoppingzone"},
	{x = 20076.73, z = 19829.40, region = "town", name = "park"},
	{x = 20139.68, z = 19794.05, region = "town", name = "triumphsquare"},
	{x = 20251.64, z = 19752.83, region = "town", name = "library"},
	{x = 20306.58, z = 19737.48, region = "town", name = "familymanagement"},
	{x = 20313.94, z = 19839.36, region = "town", name = "starcarnival"},
	{x = 20259.41, z = 19790.60, region = "town", name = "relaxarea"},
	{x = 20142.29, z = 19909.12, region = "town", name = "aquahorse"},
	{x = 20034.04, z = 19818.38, region = "town", name = "policestation"},
};

-- 区域掩码可用性缓存: nil=未探测, true=可用, false=不可用(返回 0/无图层)
HaqiBgmPlaylist.maskAvailable = nil;

-- 区域曲目全部缺失时的兜底随机播放列表 (原行为)
-- 注: 本地 _emptyworld 无 region PNG, 区域掩码不可用, 走此兜底列表。
HaqiBgmPlaylist.fallbackPlaylist = {
	"Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
	"Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg",
	"Audio/Haqi/AriesRegionBGMusics/Area_Carnival.ogg",
	"Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
	"Audio/Haqi/AriesRegionBGMusics/Area_Farm.ogg",
	"Audio/Haqi/keepwork/common/bigworld_bgm.ogg",
};

-- 检测参数
HaqiBgmPlaylist.updateInterval = 1000;   -- 区域检测周期 (毫秒)
HaqiBgmPlaylist.cooldownTime   = 4000;   -- 切换冷却, 防止区域边界抖动频繁切歌
HaqiBgmPlaylist.verboseMaskLog = false;  -- true 时打印每个 mask probe 结果
-- mac cp_old 上底层 Ogg/OpenAL 在同一帧 stop+play 时可能直接退出进程,
-- Lua 层没有机会捕获。切歌时先停旧源, 延迟一点再播放新源。
HaqiBgmPlaylist.enableAudioPlayback = true;
HaqiBgmPlaylist.audioSwitchDelay = 200;

-- 内部状态
HaqiBgmPlaylist.isPlaying        = false;
HaqiBgmPlaylist.curRegion        = nil;  -- 当前正在播放的区域 key
HaqiBgmPlaylist.curSrc           = nil;  -- 当前播放的音频源
HaqiBgmPlaylist.timer            = nil;
HaqiBgmPlaylist.cooldown         = 0;

-- 兜底随机播放列表状态 (仅当区域曲目全部缺失时启用)
HaqiBgmPlaylist.fallbackActive   = false;
HaqiBgmPlaylist.fallbackIndex    = 0;
HaqiBgmPlaylist.seeded           = false;

-- 用于被 Scene.ReplaceBGMusic 临时打断 (例如战斗音乐) 后恢复
HaqiBgmPlaylist.pausedForReplace = false;

local function BgmLogDebug(fmt, ...)
	LOG.debug("[HaqiBgm] "..fmt, ...);
end

local function BgmLogInfo(fmt, ...)
	LOG.info("[HaqiBgm] "..fmt, ...);
end

local function GetPlayerPos()
	local player = ParaScene.GetPlayer();
	if(player and player.IsValid and player:IsValid()) then
		return player:GetPosition();
	end
end

-- Haqi mc="false" 不使用方块, 区域判断完全依赖 region 掩码图层.
-- 以下所有方块采样相关函数已移除, 保留区域掩码作为唯一的区域检测手段.

---------------- 区域掩码 (region mask) 链路 ----------------

-- 安全读取区域颜色值. 返回 argb (number) 或 nil (API 不可用 / 出错)。
-- @param title: region 图层名, 默认 self.regionTitle
local function GetRegionValue(title, x, y)
	if(not (ParaTerrain and ParaTerrain.GetRegionValue)) then return nil; end
	local ok, val = pcall(ParaTerrain.GetRegionValue, title, x, y);
	if(ok) then return val; end
	return nil;
end

local function GetRegionRgb(title, x, y)
	local val = GetRegionValue(title, x, y);
	if(not val) then return nil; end
	local r, g, b = _guihelper.DWORD_TO_RGBA(val);
	return val, string.format("%s_%s_%s", tostring(r), tostring(g), tostring(b)), r, g, b;
end

-- 从当前世界目录解析区域 key (town/forest/...), 失败返回 nil。
-- 用于 region PNG + worlds_list.xml 缺失时的可靠降级:
-- ParaWorld.GetWorldDirectory() 形如 "worlds/MyWorlds/61HaqiTown/"
local function GetRegionByWorldDir()
	if(not ParaWorld or not ParaWorld.GetWorldDirectory) then return nil; end
	local ok, dir = pcall(ParaWorld.GetWorldDirectory);
	if(not ok or not dir or dir == "") then return nil; end
	-- 取目录最后一段, 大小写不敏感匹配
	local leaf = dir:match("([^/\\]+)/?$") or dir;
	leaf = string.lower(leaf);
	return HaqiBgmPlaylist.worldDirToRegion[leaf];
end

local function GetWorldDirLeaf()
	if(not ParaWorld or not ParaWorld.GetWorldDirectory) then return nil; end
	local ok, dir = pcall(ParaWorld.GetWorldDirectory);
	if(not ok or not dir or dir == "") then return nil; end
	return string.lower(dir:match("([^/\\]+)/?$") or dir);
end

local function NormalizeRegionAssetPath(path)
	if(not path) then return nil; end
	path = string.lower(path:gsub("\\", "/"));
	path = path:gsub("^%%world%%/regions/", string.lower(HaqiBgmPlaylist:GetRegionMaskWorldPath()).."/regions/");
	path = path:gsub("%.p$", "");
	return path;
end

function HaqiBgmPlaylist:DetectRegionByTownPosition()
	local leaf = GetWorldDirLeaf();
	if(leaf ~= "61haqitown" and leaf ~= "61haqitown_teen") then
		return nil;
	end
	local px, _, pz = GetPlayerPos();
	if(not px) then return nil; end

	local best, bestDistSq;
	for _, item in ipairs(self.haqiTownPositionAreas) do
		local dx = px - item.x;
		local dz = pz - item.z;
		local distSq = dx * dx + dz * dz;
		if(not bestDistSq or distSq < bestDistSq) then
			best = item;
			bestDistSq = distSq;
		end
	end
	if(best and best.region) then
		BgmLogDebug("DetectRegion: town position fallback -> region=%s, nearest=%s, dist=%s", best.region, tostring(best.name), tostring(math.sqrt(bestDistSq or 0)));
		return best.region;
	end
end

function HaqiBgmPlaylist:GetRegionMaskWorldPath()
	local leaf = GetWorldDirLeaf();
	local path = leaf and self.worldDirToRegionMaskWorldPath[leaf];
	if(path) then
		return path;
	end
	-- cp_old haqi runs in _emptyworld; use the public town region mask as the
	-- coordinate source so RegionRadar can still resolve sub regions.
	if(System.options.version == "teen") then
		return "worlds/MyWorlds/61HaqiTown_teen";
	end
	return "worlds/MyWorlds/61HaqiTown";
end

function HaqiBgmPlaylist:GetRegionTileName(x, z)
	local size = self.regionTileSize;
	local tileX = math.floor((x or 0) / size);
	local tileZ = math.floor((z or 0) / size);
	local startIndex = self.regionTileStartIndex;
	local endIndex = self.regionTileEndIndex;
	tileX = math.max(startIndex, math.min(endIndex, tileX));
	-- MiniMap region generation stores z in reverse order inside 35..39.
	local tileY = startIndex + endIndex - tileZ;
	tileY = math.max(startIndex, math.min(endIndex, tileY));
	return string.format("%s_%d_%d.png", self.regionTitle, tileY, tileX), tileX, tileY;
end

function HaqiBgmPlaylist:GetRegionTileCandidates(x, z)
	local size = self.regionTileSize;
	local tileX = math.floor((x or 0) / size);
	local tileZ = math.floor((z or 0) / size);
	local startIndex = self.regionTileStartIndex;
	local endIndex = self.regionTileEndIndex;
	tileX = math.max(startIndex, math.min(endIndex, tileX));

	local reverseY = startIndex + endIndex - tileZ;
	reverseY = math.max(startIndex, math.min(endIndex, reverseY));
	local directY = math.max(startIndex, math.min(endIndex, tileZ));

	local candidates = {
		{
			name = string.format("%s_%d_%d.png", self.regionTitle, reverseY, tileX),
			tileX = tileX,
			tileY = reverseY,
			mode = "reverse",
		},
	};
	if(directY ~= reverseY) then
		candidates[#candidates + 1] = {
			name = string.format("%s_%d_%d.png", self.regionTitle, directY, tileX),
			tileX = tileX,
			tileY = directY,
			mode = "direct",
		};
	end
	return candidates;
end

function HaqiBgmPlaylist:GetRegionTileFilepath(tileName)
	local worldPath = self:GetRegionMaskWorldPath();
	return string.format("%s/regions/%s", worldPath, tileName);
end

function HaqiBgmPlaylist:GetRegionTileFilepaths(tileName)
	local paths = {};
	local pathMap = {};
	local function AddPath(path)
		if(path and not pathMap[path]) then
			pathMap[path] = true;
			paths[#paths + 1] = path;
		end
	end
	-- Native region layer paths are world-relative. Keep this first so the
	-- engine can resolve the current world's asset/macro path exactly like the
	-- old MiniMap/MapHelper code did.
	AddPath(string.format("%%WORLD%%/regions/%s", tileName));

	local worldPath = self:GetRegionMaskWorldPath();
	AddPath(string.format("%s/regions/%s", worldPath, tileName));
	AddPath(string.format("%s/regions/%s", string.lower(worldPath), string.lower(tileName)));
	return paths;
end

function HaqiBgmPlaylist:GetRegionManifestItem(path)
	local normalized = NormalizeRegionAssetPath(path);
	if(not normalized) then return nil; end
	local key = normalized..".p";
	if(not self.regionManifestMap) then
		self.regionManifestMap = {};
		local file = ParaIO.open(self.regionAssetManifest, "r");
		if(file and file:IsValid()) then
			local text = file:GetText();
			file:close();
			for line in string.gmatch(text or "", "([^\r\n]+)") do
				local filename, hash, size = line:match("^([^,]+),([^,]+),(%d+)");
				if(filename and hash and size and filename:match("/regions/")) then
					self.regionManifestMap[string.lower(filename)] = {
						filename = string.lower(filename),
						hash = hash,
						size = size,
					};
				end
			end
		else
			BgmLogInfo("Region manifest missing: %s", tostring(self.regionAssetManifest));
		end
	end
	return self.regionManifestMap[key];
end

function HaqiBgmPlaylist:GetRegionAssetCachePath(path)
	local item = self:GetRegionManifestItem(path);
	if(item and item.hash and item.size) then
		return string.format("temp/cache/%s/%s%s", string.sub(item.hash, 1, 1), item.hash, item.size);
	end
end

function HaqiBgmPlaylist:GetRegionLocalCachePath(path)
	if(path) then
		local tileName = path:gsub("\\", "/"):match("([^/]+)$");
		if(tileName) then
			tileName = tileName:gsub("%.p$", "");
			return string.format("%s/regions/%s", self:GetRegionMaskWorldPath(), tileName);
		end
	end
end

function HaqiBgmPlaylist:PrepareRegionTileLocalFile(path)
	local localPath = self:GetRegionLocalCachePath(path);
	if(not localPath) then return nil; end
	if(ParaIO.DoesFileExist(localPath, true)) then
		return localPath;
	end
	local cachePath = self:GetRegionAssetCachePath(path);
	if(cachePath and ParaIO.DoesFileExist(cachePath, true)) then
		ParaIO.CreateDirectory(localPath);
		if(ParaIO.CopyFile(cachePath, localPath, true)) then
			if(self.regionImageCache) then
				self.regionImageCache[localPath] = nil;
			end
			BgmLogDebug("Region tile cache copied: %s -> %s", cachePath, localPath);
			return localPath;
		else
			BgmLogInfo("Region tile cache copy failed: %s -> %s", cachePath, localPath);
		end
	end
	return nil;
end

function HaqiBgmPlaylist:GetRegionImageData(path)
	if(not (path and ImageFile and ImageFile.open)) then
		return nil;
	end
	self.regionImageCache = self.regionImageCache or {};
	if(self.regionImageCache[path] ~= nil) then
		return self.regionImageCache[path] or nil;
	end
	local ok, file = pcall(ImageFile.open, path);
	if(ok and file and file:IsValid()) then
		local img = file:GetImageData(nil, nil, "rgb");
		file:close();
		if(img and img.width and img.height and img.data) then
			self.regionImageCache[path] = img;
			BgmLogDebug("Region image opened: %s, size=%sx%s", path, tostring(img.width), tostring(img.height));
			return img;
		end
	elseif(file and file.close) then
		file:close();
	end
	return nil;
end

function HaqiBgmPlaylist:ReadRegionImageRgb(path, x, z)
	local img = self:GetRegionImageData(path);
	if(not (img and img.width and img.height and img.data and x and z)) then
		return nil;
	end
	local size = self.regionTileSize;
	local tileX = math.floor((x or 0) / size);
	local tileZ = math.floor((z or 0) / size);
	local localX = (x or 0) - tileX * size;
	local localZ = (z or 0) - tileZ * size;
	local px = math.floor(localX / size * img.width) + 1;
	local py = math.floor(localZ / size * img.height) + 1;
	px = math.max(1, math.min(img.width, px));
	py = math.max(1, math.min(img.height, py));
	local idx = (py - 1) * img.width * 3 + (px - 1) * 3 + 1;
	local r, g, b = img.data[idx], img.data[idx + 1], img.data[idx + 2];
	if(r and g and b) then
		return r * 65536 + g * 256 + b, string.format("%s_%s_%s", tostring(r), tostring(g), tostring(b)), r, g, b, px, py;
	end
end

function HaqiBgmPlaylist:GetRegionSamplePosition(x, z)
	local size = self.regionTileSize;
	local tileZ = math.floor((z or 0) / size);
	local localZ = (z or 0) - tileZ * size;
	-- Haqi region PNGs are generated in image space. On non-win32 the terrain
	-- region sampler reads them without the vertical flip used by the old
	-- Windows path, so mirror inside the current tile before reading colors.
	local mirroredLocalZ = math.max(0, math.min(size - 0.001, size - localZ));
	local sampleZ = tileZ * size + mirroredLocalZ;
	return x, sampleZ;
end

function HaqiBgmPlaylist:ClearRegionRadarCache()
	local radar = commonlib.gettable("Map3DSystem.App.worlds.Global_RegionRadar");
	radar = radar and radar.radar;
	if(radar) then
		radar.cur_region_title = nil;
		radar.cur_x = nil;
		radar.cur_y = nil;
		radar.cur_value = nil;
	end
end

function HaqiBgmPlaylist:MountRegionTileAt(x, z, tileName, mode, filepath)
	if(not (ParaTerrain and ParaTerrain.GetAttributeObjectAt)) then return; end
	if(not x or not z) then return; end
	tileName = tileName or self:GetRegionTileName(x, z);
	filepath = filepath or self:GetRegionTileFilepath(tileName);
	local mountPath = self:PrepareRegionTileLocalFile(filepath) or filepath;
	local manifestItem = self:GetRegionManifestItem(filepath);
	local loadPath = manifestItem and manifestItem.filename or filepath;
	self.regionTileLoadState = self.regionTileLoadState or {};
	if(not self.regionTileLoadState[loadPath] and FileLoader and FileLoader.AsyncLoadAsset) then
		self.regionTileLoadState[loadPath] = "loading";
		FileLoader.AsyncLoadAsset(loadPath, function(bSucceed)
			self.regionTileLoadState[loadPath] = bSucceed and "loaded" or "failed";
			local status = ParaIO and ParaIO.CheckAssetFile and ParaIO.CheckAssetFile(loadPath);
			local exists = ParaIO and ParaIO.DoesAssetFileExist and ParaIO.DoesAssetFileExist(filepath, true);
			if(bSucceed) then
				BgmLogDebug("Region tile asset load %s: %s, mountSource=%s, status=%s, exists=%s", tostring(bSucceed), loadPath, filepath, tostring(status), tostring(exists));
			else
				BgmLogInfo("Region tile asset load %s: %s, mountSource=%s, status=%s, exists=%s", tostring(bSucceed), loadPath, filepath, tostring(status), tostring(exists));
			end
			self:PrepareRegionTileLocalFile(filepath);
			-- Re-probe after async load; the next OnTimer can then read real colors.
			self.maskAvailable = nil;
			self.lastMountedRegionTile = nil;
			self:ClearRegionRadarCache();
		end);
	end
	local cacheKey = string.format("%s:%s:%.1f:%.1f", self.regionTitle, mountPath, x, z);
	if(self.lastMountedRegionTile == cacheKey) then
		return mountPath;
	end
	local ok, att = pcall(ParaTerrain.GetAttributeObjectAt, x, z);
	if(ok and att) then
		att:SetField("CurrentRegionIndex", 0);
		att:SetField("CurrentRegionName", self.regionTitle);
		att:SetField("CurrentRegionFilepath", mountPath);
		self.lastMountedRegionTile = cacheKey;
		self:ClearRegionRadarCache();
		if(self.verboseMaskLog) then
			BgmLogDebug("MountRegionTileAt: %s source=%s mode=%s at (%s,%s)", mountPath, filepath, tostring(mode or "primary"), tostring(x), tostring(z));
		end
		return mountPath;
	end
end

function HaqiBgmPlaylist:MountRegionTilePairAt(x, z, sampleX, sampleZ, tileName, mode, filepath)
	local mountPath = self:MountRegionTileAt(x, z, tileName, mode, filepath);
	if(sampleX and sampleZ and (math.abs(sampleX - x) > 0.001 or math.abs(sampleZ - z) > 0.001)) then
		mountPath = self:MountRegionTileAt(sampleX, sampleZ, tileName, mode, filepath) or mountPath;
	end
	return mountPath;
end

-- 一次性探测: 当前世界有没有可用的 region 掩码图层。
-- 思路: GetRegionValue("move", 玩家位置) 在有图层时返回非 0 颜色 argb;
--       _emptyworld/未挂图层的世界则恒为 0 或 nil。在玩家附近采几个样点,
--       只要有一个非 0 即认为掩码可用。
function HaqiBgmPlaylist:ProbeMaskAvailable()
	if(not self.useRegionMask) then
		BgmLogDebug("ProbeMaskAvailable: useRegionMask=false, skipping");
		self.maskAvailable = false;
		return false;
	end
	local px, py, pz = GetPlayerPos();
	if(not px) then
		BgmLogDebug("ProbeMaskAvailable: player pos unavailable");
		self.maskAvailable = false;
		return false;
	end
	local title = self.regionTitle;
	-- 在玩家及其 8 个方向各采一点, 避免正好站在边界外的空白处
	local probes = {
		{0, 0}, {64, 0}, {-64, 0}, {0, 64}, {0, -64},
		{64, 64}, {64, -64}, {-64, 64}, {-64, -64},
	};
	for _, d in ipairs(probes) do
		local x, z = px + d[1], pz + d[2];
		local candidates = self:GetRegionTileCandidates(x, z);
		local sampleX, sampleZ = self:GetRegionSamplePosition(x, z);
		for _, candidate in ipairs(candidates) do
			for _, filepath in ipairs(self:GetRegionTileFilepaths(candidate.name)) do
				local mountPath = self:MountRegionTilePairAt(x, z, sampleX, sampleZ, candidate.name, candidate.mode, filepath);
				local val = GetRegionValue(title, sampleX, sampleZ);
				local source = "terrain";
				if((not val or val == 0) and mountPath) then
					local imageVal = self:ReadRegionImageRgb(mountPath, sampleX, sampleZ);
					if(imageVal) then
						val = imageVal;
						source = "image";
					end
				end
				BgmLogDebug("ProbeMaskAvailable: probe=(%s,%s) sample=(%s,%s) tile=%s path=%s mountPath=%s source=%s = %s", tostring(x), tostring(z), tostring(sampleX), tostring(sampleZ), candidate.name, filepath, tostring(mountPath), source, tostring(val));
				if(val and val ~= 0) then
					self.maskAvailable = true;
					return true;
				end
			end
		end
	end
	self.maskAvailable = false;
	return false;
end

local function IsClosedRegionKey(key)
	return key == "unopen_square" or key == "forbidden";
end

local function IsUsableMaskRegionKey(key)
	return key and key ~= "none" and not IsClosedRegionKey(key);
end

function HaqiBgmPlaylist:GetRegionInfoByRgb(rgb)
	if(not rgb) then return nil; end
	if(not self.regionRgbToInfo) then
		self.regionRgbToInfo = {};
		NPL.load("(gl)script/kids/3DMapSystemApp/worlds/RegionRadar.lua");
		local RegionRadar = commonlib.gettable("Map3DSystem.App.worlds.RegionRadar");
		local regionColor = RegionRadar and RegionRadar.region_color;
		if(regionColor) then
			for _, item in ipairs(regionColor) do
				if(item.color and not self.regionRgbToInfo[item.color]) then
					self.regionRgbToInfo[item.color] = item;
				end
			end
		end
		-- Keep these canonical values local so BGM detection is not affected by
		-- worlds_list.xml entries that may map empty pixels differently.
		self.regionRgbToInfo["0_0_0"] = {color = "0_0_0", label = "none", key = "none"};
		self.regionRgbToInfo["255_255_255"] = {color = "255_255_255", label = "未开放区域", key = "forbidden", isclosed = true};
		self.regionRgbToInfo["4_51_59"] = {color = "4_51_59", label = "未开放区域", key = "unopen_square", isclosed = true};
	end
	return self.regionRgbToInfo[rgb];
end

function HaqiBgmPlaylist:GetRegionProbeOffsets()
	return {
		{0, 0},
		{64, 0}, {-64, 0}, {0, 64}, {0, -64},
		{64, 64}, {64, -64}, {-64, 64}, {-64, -64},
		{128, 0}, {-128, 0}, {0, 128}, {0, -128},
	};
end

function HaqiBgmPlaylist:ReadMaskRegionKeyAt(radar, x, z)
	local closedKey;
	local lastEmptyInfo;
	local candidates = self:GetRegionTileCandidates(x, z);
	local sampleX, sampleZ = self:GetRegionSamplePosition(x, z);
	for _, candidate in ipairs(candidates) do
		for _, filepath in ipairs(self:GetRegionTileFilepaths(candidate.name)) do
			local mountPath = self:MountRegionTilePairAt(x, z, sampleX, sampleZ, candidate.name, candidate.mode, filepath);
			local val, rgb = GetRegionRgb(self.regionTitle, sampleX, sampleZ);
			local source = "terrain";
			local pixelX, pixelY;
			if((not val or val == 0) and mountPath) then
				local imageVal, imageRgb, _, _, _, px, py = self:ReadRegionImageRgb(mountPath, sampleX, sampleZ);
				if(imageVal) then
					val, rgb = imageVal, imageRgb;
					source = "image";
					pixelX, pixelY = px, py;
				end
			end
			local info = self:GetRegionInfoByRgb(rgb);
			local key = info and info.key;
			if(key) then
				if(self.verboseMaskLog or IsUsableMaskRegionKey(key)) then
					BgmLogDebug("DetectRegionByMask: probe=(%s,%s) sample=(%s,%s) tile=%s path=%s mountPath=%s mode=%s source=%s pixel=(%s,%s) color=%s (%s) key=%s", tostring(x), tostring(z), tostring(sampleX), tostring(sampleZ), candidate.name, filepath, tostring(mountPath), tostring(candidate.mode), source, tostring(pixelX), tostring(pixelY), tostring(val), tostring(rgb), tostring(key));
				end
				if(IsUsableMaskRegionKey(key)) then
					return key;
				end
				if(IsClosedRegionKey(key)) then
					BgmLogDebug("DetectRegionByMask: closed key=%s, source=%s, color=%s (%s), probe=(%s,%s), sample=(%s,%s), pixel=(%s,%s), tile=%s, path=%s, mountPath=%s", tostring(key), source, tostring(val), tostring(rgb), tostring(x), tostring(z), tostring(sampleX), tostring(sampleZ), tostring(pixelX), tostring(pixelY), candidate.name, filepath, tostring(mountPath));
					closedKey = closedKey or key;
				end
				if(key == "none") then
					lastEmptyInfo = "source="..source..", color="..tostring(val).." ("..tostring(rgb).."), tile="..candidate.name..", path="..filepath..", mountPath="..tostring(mountPath)..", pixel=("..tostring(pixelX)..","..tostring(pixelY)..")";
				end
			elseif(val and val ~= 0) then
				BgmLogInfo("DetectRegionByMask: unknown color=%s (%s), source=%s, probe=(%s,%s), sample=(%s,%s), pixel=(%s,%s), tile=%s, path=%s, mountPath=%s", tostring(val), tostring(rgb), source, tostring(x), tostring(z), tostring(sampleX), tostring(sampleZ), tostring(pixelX), tostring(pixelY), candidate.name, filepath, tostring(mountPath));
			elseif(not val and radar and radar.WhereIsXZ) then
				local args = radar.WhereIsXZ(sampleX, sampleZ);
				if(args and args.key) then
					if(self.verboseMaskLog or IsUsableMaskRegionKey(args.key)) then
						BgmLogDebug("DetectRegionByMask: radar fallback probe=(%s,%s) sample=(%s,%s) tile=%s path=%s mountPath=%s mode=%s key=%s", tostring(x), tostring(z), tostring(sampleX), tostring(sampleZ), candidate.name, filepath, tostring(mountPath), tostring(candidate.mode), tostring(args.key));
					end
					if(IsUsableMaskRegionKey(args.key)) then
						return args.key;
					end
					if(IsClosedRegionKey(args.key)) then
						closedKey = closedKey or args.key;
					end
				end
			else
				lastEmptyInfo = "source="..source..", color="..tostring(val).." ("..tostring(rgb).."), tile="..candidate.name..", path="..filepath..", mountPath="..tostring(mountPath)..", pixel=("..tostring(pixelX)..","..tostring(pixelY)..")";
			end
		end
	end
	if(not closedKey and lastEmptyInfo) then
		BgmLogDebug("DetectRegionByMask: no usable color, %s", lastEmptyInfo);
	end
	return nil, closedKey;
end

-- 用区域掩码解析当前 region key (Region_xxx), 失败返回 nil。
-- 先直接读取 region PNG 的 RGB, 再按 RegionRadar.region_color 的硬编码颜色表
-- 解析。这里不优先使用 worlds_region_color_map, 因为旧资源包里可能把 0_0_0
-- 这类空白像素映射成 forbidden, 导致 BGM 误判为未开放区域。
function HaqiBgmPlaylist:DetectRegionByMask()
	if(not self.useRegionMask) then return nil; end
	local px, _, pz = GetPlayerPos();
	if(not px) then return nil; end

	local ok, radar = pcall(function()
		return commonlib.gettable("Map3DSystem.App.worlds.Global_RegionRadar");
	end);
	radar = ok and radar or nil;
	local closedKey;
	for _, offset in ipairs(self:GetRegionProbeOffsets()) do
		local key, currentClosedKey = self:ReadMaskRegionKeyAt(radar, px + offset[1], pz + offset[2]);
		if(key) then
			return key;
		end
		closedKey = closedKey or currentClosedKey;
	end
	return closedKey;
end

-- 当前用于采样的 region 掩码是否是 61哈奇镇(主城)的掩码。
-- RegionRadar.region_color 是主城专属颜色表; 各岛屿的 region PNG 颜色含义
-- 不同(worlds_list.xml 缺失, 没有 per-world 颜色表), 同一 RGB 会撞色误判
-- (如霜吼岛的 0_255_255 撞上主城的 生命之泉 Region_LifeSpring)。
-- 因此只有主城掩码才能用该表解析 mask 颜色。
function HaqiBgmPlaylist:IsTownMaskWorld()
	local path = self:GetRegionMaskWorldPath();
	return path ~= nil and string.lower(path):find("61haqitown", 1, true) ~= nil;
end

-- 主区域推断. 返回 region key (town/forest/...) 或 nil (无法判定)。
-- Haqi mc="false" 不使用方块, 区域判断完全依赖 region 掩码图层.
-- 掩码不可用时返回 nil, 由上层走兜底随机播放。
function HaqiBgmPlaylist:DetectRegion()
	if(not self.useRegionMask) then return nil; end

	-- 区域掩码: 直接按 region PNG 的 RGB 得到 Region_xxx key。
	-- 仅当掩码来源是主城时才信任 mask 解析(见 IsTownMaskWorld); 其它岛屿
	-- 每岛就是单一区域, 直接走下方 worldDirToRegion 的世界目录映射。
	if(self:IsTownMaskWorld()) then
		local key = self:DetectRegionByMask();
		if(key) then
			BgmLogDebug("DetectRegion: mask detected key=%s", key);
			if(key == "none" or key == "unopen_square" or key == "forbidden") then
				-- 非 BGM 区域 / region tile 未就绪时常见的误读。不要在这里直接返回,
				-- 否则会阻断下面的世界目录兜底, 导致进场后没有区域 BGM。
				key = nil;
			elseif(key == "homeland") then
				return "town";   -- 家园退到主城调
			else
				local fileKey = self.regionKeyToArea[key];
				if(fileKey) then
					return fileKey;
				end
				key = nil;   -- 未知 Region_xxx key, 继续走兜底
			end
		else
			BgmLogDebug("DetectRegion: mask returned nil (no region PNG or color map)");
		end
	end

	local posKey = self:DetectRegionByTownPosition();
	if(posKey) then
		return posKey;
	end

	-- 降级: region PNG / worlds_list.xml 缺失时, 用世界目录名判断
	-- (每个哈奇岛屿 = 一个主地形区域, 玩家切岛屿 = 切区域)
	local wdKey = GetRegionByWorldDir();
	if(wdKey) then
		BgmLogDebug("DetectRegion: world dir fallback -> region=%s", wdKey);
		return wdKey;
	end

	return nil;
end

-- 取区域对应可播放音源 (找不到返回 nil)
function HaqiBgmPlaylist:GetRegionMusic(region)
	if(not region) then return nil; end
	local filename = self.regionToMusic[region];
	if(not filename) then return nil; end
	return BackgroundMusic:GetMusic(filename);
end

function HaqiBgmPlaylist:GetHttpMusic(url, callbackFunc)
	HttpFiles.GetHttpFilePath(url, function(err, diskfilename)
		if(err or not diskfilename or diskfilename == "") then
			callbackFunc(err or true);
			return;
		end

		local sound = BackgroundMusic:GetMusic(diskfilename);
		if(sound) then
			callbackFunc(nil, sound, diskfilename);
		else
			callbackFunc("GetMusic failed", nil, diskfilename);
		end
	end);
end

function HaqiBgmPlaylist:IsAudioPlaybackEnabled(filename)
	if(not self.enableAudioPlayback) then
		BgmLogInfo("audio playback disabled, skip file=%s", tostring(filename));
		return false;
	end
	return true;
end

function HaqiBgmPlaylist:IsPlayableSound(sound, filename)
	if(not sound) then
		BgmLogInfo("sound source missing, skip file=%s", tostring(filename));
		return false;
	end
	if(sound.IsValid and not sound:IsValid()) then
		BgmLogInfo("sound source invalid, skip file=%s, resolved=%s", tostring(filename), tostring(sound.file));
		return false;
	end
	if(not sound.file or sound.file == "") then
		BgmLogInfo("sound source has empty file, skip file=%s", tostring(filename));
		return false;
	end
	return true;
end

function HaqiBgmPlaylist:StopCurrentSound()
	if(self.curSrc) then
		pcall(function() self.curSrc:SetPlayEndCb(nil); end);
		pcall(function() self.curSrc:stop(); end);
		self.curSrc = nil;
	end
end

function HaqiBgmPlaylist:SafePlaySound(sound, filename, region, loop)
	if(not self:IsAudioPlaybackEnabled(filename)) then
		self.curSrc = nil;
		return false;
	end
	if(not self:IsPlayableSound(sound, filename)) then
		self.curSrc = nil;
		return false;
	end

	self:StopCurrentSound();
	sound.loop = loop == true;
	self.curSrc = sound;
	self.curRegion = region or self.curRegion;
	self.audioPlayToken = (self.audioPlayToken or 0) + 1;
	local token = self.audioPlayToken;
	local delay = self.audioSwitchDelay or 0;
	BgmLogDebug("SafePlaySound: scheduled region=%s, file=%s, resolved=%s, delay=%s", tostring(region), tostring(filename), tostring(sound.file), tostring(delay));

	commonlib.TimerManager.SetTimeout(function()
		if(self.audioPlayToken ~= token or self.curSrc ~= sound or not self.isPlaying) then
			BgmLogDebug("SafePlaySound: canceled region=%s, file=%s", tostring(region), tostring(filename));
			return;
		end

		BgmLogDebug("SafePlaySound: start region=%s, file=%s", tostring(region), tostring(filename));
		local ok, err = pcall(function()
			BackgroundMusic:PlayBackgroundSound(sound);
		end);
		if(ok) then
			BgmLogDebug("SafePlaySound: play returned region=%s, file=%s", tostring(region), tostring(filename));
			return;
		end

		BgmLogInfo("SafePlaySound: play failed region=%s, file=%s, err=%s", tostring(region), tostring(filename), tostring(err));
		if(self.curSrc == sound) then
			self.curSrc = nil;
		end
	end, delay);
	return true;
end

-- 切换并播放指定区域
function HaqiBgmPlaylist:PlayRegion(region)
	if(region == self.curRegion) then return; end

	local filename = self.regionToMusic[region];
	if(not filename) then
		-- 该区域曲目缺失 -> 兜底随机播放
		BgmLogInfo("PlayRegion: region=%s, music file MISSING, starting fallback", region);
		self:StartFallback();
		self.curRegion = region;   -- 仍记录, 避免每帧重试
		return;
	end

	-- HTTP URL: 先下载到本地, 再用本地路径创建音频源
	if(filename:match("^https?://")) then
		-- 立即标记 curRegion, 防止异步下载期间 OnTimer 重复触发 PlayRegion
		self.curRegion = region;
		self.regionDownloading = true;
		BgmLogDebug("PlayRegion: downloading HTTP file for region=%s: %s", region, filename);
		self:GetHttpMusic(filename, function(err, sound, diskfilename)
			self.regionDownloading = false;
			-- 如果区域已切换, 放弃这次下载
			if(self.curRegion ~= region) then return; end
			if(err or not sound) then
				BgmLogInfo("PlayRegion: HTTP download failed: %s, starting fallback", tostring(err));
				self.curRegion = nil;
				self:StartFallback();
				return;
			end
			BgmLogDebug("PlayRegion: downloaded to: %s for region=%s", diskfilename, region);
			self:StopFallback();
			pcall(function() sound:SetPlayEndCb(nil); end);
			BgmLogDebug("PlayRegion: playing region=%s, file=%s", region, diskfilename);
			if(not self:SafePlaySound(sound, diskfilename, region, true)) then
				self.curRegion = region;
			end
		end);
	else
		-- 本地文件: 直接创建音频源
		local sound = self:GetRegionMusic(region);
		if(not sound) then
			BgmLogInfo("PlayRegion: region=%s, music file MISSING, starting fallback", region);
			self:StartFallback();
			self.curRegion = region;
			return;
		end

		self:StopFallback();
		pcall(function() sound:SetPlayEndCb(nil); end);
		BgmLogDebug("PlayRegion: playing region=%s, file=%s", region, tostring(self.regionToMusic[region]));
		if(not self:SafePlaySound(sound, self.regionToMusic[region], region, true)) then
			self.curRegion = region;
		end
	end
end

---------- 兜底随机播放列表 ----------
function HaqiBgmPlaylist:StopFallback()
	if(not self.fallbackActive) then return; end
	self.fallbackActive = false;
	self.fallbackDownloading = false;
	self:StopCurrentSound();
end

function HaqiBgmPlaylist:StartFallback()
	if(self.fallbackActive) then return; end
	self.fallbackActive = true;
	self.fallbackDownloading = false;
	if(not self.seeded) then
		math.randomseed(ParaGlobal.timeGetTime());
		self.seeded = true;
	end
	self:PlayFallbackNext();
end

function HaqiBgmPlaylist:PlayFallbackNext()
	if(not self.fallbackActive) then return; end
	local n = #self.fallbackPlaylist;
	if(n == 0) then return; end

	if(self.curSrc) then
		self.curSrc:SetPlayEndCb(nil);
	end

	-- 选取下一首曲目索引
	local idx;
	if(n > 1) then
		repeat
			idx = math.random(1, n);
		until idx ~= self.fallbackIndex;
		self.fallbackIndex = idx;
	else
		self.fallbackIndex = 1;
		idx = 1;
	end

	local url = self.fallbackPlaylist[idx];

	-- HTTP URL: 先下载到本地, 再用本地路径创建音频源
	-- (C++ AudioEngine 无法直接加载 HTTP URL, 必须等文件下载完成后再 play2d)
	if(url and url:match("^https?://")) then
		self.fallbackDownloading = true;
		BgmLogDebug("PlayFallbackNext: downloading HTTP file: %s", url);
		self:GetHttpMusic(url, function(err, sound, diskfilename)
			self.fallbackDownloading = false;
			if(not self.fallbackActive) then return; end
			if(err or not sound) then
				BgmLogInfo("PlayFallbackNext: HTTP download failed: %s, trying next", tostring(err));
				-- 下载失败, 尝试下一首
				commonlib.TimerManager.SetTimeout(function()
					if(self.fallbackActive) then
						self:PlayFallbackNext();
					end
				end, 100);
				return;
			end
			BgmLogDebug("PlayFallbackNext: downloaded to: %s", diskfilename);
			sound.loop = false;
			sound:SetPlayEndCb(function()
				if(self.fallbackActive) then
					self:PlayFallbackNext();
				end
			end);
			self.curSrc = sound;
			BgmLogDebug("PlayFallbackNext: playing %s", diskfilename);
			self:SafePlaySound(sound, diskfilename, nil, false);
		end);
	else
		-- 本地文件: 直接创建音频源
		local sound = BackgroundMusic:GetMusic(url);
		if(not sound) then
			BgmLogInfo("PlayFallbackNext: GetMusic failed for local file: %s", url);
			return;
		end
		sound.loop = false;
		sound:SetPlayEndCb(function()
			if(self.fallbackActive) then
				self:PlayFallbackNext();
			end
		end);
		BgmLogDebug("PlayFallbackNext: playing local file %s", url);
		self:SafePlaySound(sound, url, nil, false);
	end
end

---------- 定时检测 + 切换 ----------
function HaqiBgmPlaylist.OnTimer()
	local self = HaqiBgmPlaylist;
	if(not self.isPlaying) then return; end

	if(self.cooldown > 0) then
		self.cooldown = self.cooldown - self.updateInterval;
		return;
	end

	local region = self:DetectRegion();
	BgmLogDebug("OnTimer: detected region=%s, curRegion=%s, fallbackActive=%s", tostring(region), tostring(self.curRegion), tostring(self.fallbackActive));
	if(region and region ~= self.curRegion) then
		-- 如果已在下载同一区域, 不要重复触发
		if(self.regionDownloading) then return; end
		-- Detected a new region with valid BGM
		BgmLogDebug("OnTimer: switching to region=%s", region);
		self:PlayRegion(region);
		self.cooldown = self.cooldownTime;
	elseif(region and region == self.curRegion and self.curSrc and not self.fallbackActive and not self.regionDownloading) then
		-- 同一区域, 检查当前曲子是否还在播放。
		-- macOS / iOS 上 Sound 可能因为以下原因停止:
		--   1) AudioEngine 重复 CreateGet 同一 file 把它 stop 了(StopOriginalBGM)
		--   2) Scene.ReplaceBGMusic 切到战斗音乐后没恢复
		--   3) play2d 在文件流式加载未完成时静默
		-- 解决: 用 isPlaying / isStopped 判断, 若停了就重新 play2d
		local isStopped = false;
		pcall(function()
			-- AudioEngine 的 source 有 isPlaying() 或类似方法; 没有 / 出错就当作停了来检查
			if(self.curSrc.isPlaying) then
				isStopped = not self.curSrc:isPlaying();
			elseif(self.curSrc.isStopped) then
				isStopped = self.curSrc:isStopped();
			end
		end);
		if(isStopped) then
			BgmLogInfo("OnTimer: region BGM stopped, replaying region=%s", tostring(self.curRegion));
			pcall(function() self.curSrc:play2d(1); end);
		end
	elseif(not region) then
		-- No region detected (no region PNG or map) - use fallback playlist
		if(not self.fallbackActive) then
			BgmLogInfo("OnTimer: no region detected, starting fallback playlist");
			self:StartFallback();
		elseif(not self.curSrc and not self.fallbackDownloading) then
			-- Fallback is active but no sound source AND not currently downloading,
			-- restart the chain to keep trying
			BgmLogInfo("OnTimer: fallback active but no sound source, restarting PlayFallbackNext");
			self:PlayFallbackNext();
		end
	end
end

-- 启动区域 BGM (立即触发首次检测)
function HaqiBgmPlaylist:Start()
	if(self.isPlaying) then return; end
	self.isPlaying = true;
	self.isStarted = true;
	self.cooldown = 0;
	self.curRegion = nil;
	self.maskAvailable = nil;   -- 重新探测区域掩码可用性
	self.regionDownloading = false;

	-- 停止原版 Scene/main.lua 的区域 BGM 系统, 避免两套同时播放冲突
	self:StopOriginalBGM();

	if(not self.timer) then
		self.timer = commonlib.Timer:new({callbackFunc = HaqiBgmPlaylist.OnTimer});
	end
	self.timer:Change(0, self.updateInterval);
	BgmLogInfo("Start() called, timer started with interval=%sms", tostring(self.updateInterval));
end

-- 停止原版 Scene/main.lua 的区域 BGM (bg_sound_maps + AudioEngine.CreateGet)
function HaqiBgmPlaylist:StopOriginalBGM()
	NPL.load("(gl)script/apps/Aries/Scene/main.lua");
	local Scene = commonlib.gettable("MyCompany.Aries.Scene");
	if(Scene) then
		-- 停止当前播放的区域 BGM
		if(Scene.lastBGMusic) then
			pcall(function() AudioEngine.CreateGet(Scene.lastBGMusic):stop(); end);
			Scene.lastBGMusic = nil;
		end
		-- 停止替换战斗/区域音乐
		if(Scene.curReplaceMusic) then
			pcall(function() AudioEngine.CreateGet(Scene.curReplaceMusic):stop(); end);
			Scene.curReplaceMusic = nil;
		end
		-- 停止 TerrainRegionProvider 定时器 (teen 版)
		NPL.load("(gl)script/apps/Aries/Scene/TerrainRegionProvider.lua");
		local TerrainRegionProvider = commonlib.gettable("MyCompany.Aries.TerrainRegionProvider");
		if(TerrainRegionProvider and TerrainRegionProvider.Stop) then
			pcall(function() TerrainRegionProvider.Stop(); end);
		end
		BgmLogInfo("StopOriginalBGM: stopped original BGM system");
	end
end

-- 恢复原版 Scene/main.lua 的区域 BGM (Stop 时调用)
function HaqiBgmPlaylist:ResumeOriginalBGM()
	NPL.load("(gl)script/apps/Aries/Scene/main.lua");
	local Scene = commonlib.gettable("MyCompany.Aries.Scene");
	if(Scene) then
		-- 重启 TerrainRegionProvider (teen 版)
		NPL.load("(gl)script/apps/Aries/Scene/TerrainRegionProvider.lua");
		local TerrainRegionProvider = commonlib.gettable("MyCompany.Aries.TerrainRegionProvider");
		if(TerrainRegionProvider and TerrainRegionProvider.EnableIfExist) then
			local WorldManager = commonlib.gettable("System.App.worlds.WorldManager");
			if(WorldManager and WorldManager.GetCurrentWorld) then
				local world = WorldManager:GetCurrentWorld();
				if(world and world.name) then
					pcall(function() TerrainRegionProvider.EnableIfExist(world.name); end);
				end
			end
		end
		BgmLogInfo("ResumeOriginalBGM: restored original BGM system");
	end
end

--[[ 诊断打印: 把每一步的实际状态输出到控制台, 方便定位资源缺失。
用法: 在游戏聊天框输入 /lua HaqiBgmDiagnostics() 或代码里直接调用
HaqiBgmPlaylist:Diagnostics()
]]
function HaqiBgmPlaylist:Diagnostics()
	echo("======== HaqiBgmPlaylist Diagnostics ========");
	echo("  isPlaying        = "..tostring(self.isPlaying));
	echo("  useRegionMask    = "..tostring(self.useRegionMask));
	echo("  maskAvailable    = "..tostring(self.maskAvailable));
	echo("  regionTitle      = "..tostring(self.regionTitle));
	echo("  curRegion        = "..tostring(self.curRegion));
	echo("  fallbackActive   = "..tostring(self.fallbackActive));
	echo("  lastRegionTile   = "..tostring(self.lastMountedRegionTile));
	echo("  world dir leaf   = "..tostring(GetWorldDirLeaf()));
	echo("  isTownMaskWorld  = "..tostring(self:IsTownMaskWorld()).." (mask path="..tostring(self:GetRegionMaskWorldPath())..")");

	-- 1) 玩家位置
	local px, py, pz = GetPlayerPos();
	if(px) then
		echo("  player pos       = ("..tostring(px)..", "..tostring(py)..", "..tostring(pz)..")");
		local candidates = self:GetRegionTileCandidates(px, pz);
		for _, candidate in ipairs(candidates) do
			for _, tileFile in ipairs(self:GetRegionTileFilepaths(candidate.name)) do
				local manifestItem = self:GetRegionManifestItem(tileFile);
				local loadPath = manifestItem and manifestItem.filename or tileFile;
				local status = ParaIO and ParaIO.CheckAssetFile and ParaIO.CheckAssetFile(tileFile);
				local exists = ParaIO and ParaIO.DoesAssetFileExist and ParaIO.DoesAssetFileExist(tileFile, true);
				local cachePath = self:GetRegionAssetCachePath(tileFile);
				local localPath = self:GetRegionLocalCachePath(tileFile);
				echo("  region tile      = "..tileFile.." load="..tostring(loadPath).." mode="..tostring(candidate.mode).." state="..tostring(self.regionTileLoadState and self.regionTileLoadState[loadPath]).." status="..tostring(status).." exists="..tostring(exists).." cache="..tostring(cachePath).." local="..tostring(localPath).." localExists="..tostring(localPath and ParaIO.DoesFileExist(localPath, true)));
			end
		end
	else
		echo("  player pos       = <unavailable>");
		echo("  -> 玩家未就绪, 跳过后续检测");
		echo("============================================");
		return;
	end

	-- 2) ParaTerrain / GetRegionValue API
	if(ParaTerrain and ParaTerrain.GetRegionValue) then
		echo("  ParaTerrain.GetRegionValue = OK");
	else
		echo("  ParaTerrain.GetRegionValue = MISSING (C++ API 不可用)");
	end

	-- 3) 探测掩码图层
	local oldMask = self.maskAvailable;
	self.maskAvailable = nil;
	local avail = self:ProbeMaskAvailable();
	echo("  ProbeMaskAvailable = "..tostring(avail));
	self.maskAvailable = oldMask;

	-- 4) Global_RegionRadar
	local ok, radar = pcall(function()
		return commonlib.gettable("Map3DSystem.App.worlds.Global_RegionRadar");
	end);
	if(ok and radar) then
		echo("  Global_RegionRadar = OK");
		if(radar.WhereIsXZ) then
			local args = radar.WhereIsXZ(px, pz);
			if(args and args.key) then
				echo("    WhereIsXZ key  = "..tostring(args.key));
			else
				echo("    WhereIsXZ key  = <nil>");
			end
		else
			echo("    WhereIsXZ = <missing>");
		end
	else
		echo("  Global_RegionRadar = MISSING");
	end

	-- 5) 区域曲目文件
	echo("  --- region music files ---");
	for region, filename in pairs(self.regionToMusic) do
		local src = BackgroundMusic:GetMusic(filename);
		echo("    "..region.." -> "..filename.." : "..(src and "OK" or "MISSING"));
	end

	-- 6) 兜底列表
	echo("  --- fallback playlist ---");
	for i, filename in ipairs(self.fallbackPlaylist) do
		local src = BackgroundMusic:GetMusic(filename);
		echo("    ["..i.."] "..filename.." : "..(src and "OK" or "MISSING"));
	end

	-- 7) 当前区域掩码检测结果
	local maskRegion = self:DetectRegion();
	echo("  DetectRegion (mask) = "..tostring(maskRegion));

	echo("============================================");
end

-- 全局快捷函数, 方便在游戏里 /lua 调用
function HaqiBgmDiagnostics()
	HaqiBgmPlaylist:Diagnostics();
end
-- 显式注册到 _G, 确保控制台可见
_G.HaqiBgmDiagnostics = HaqiBgmDiagnostics;
echo("HaqiBgmDiagnostics global function defined!");

function HaqiBgmPlaylist:Stop()
	self.isPlaying = false;
	self.isStarted = false;
	self.regionDownloading = false;
	if(self.timer) then
		self.timer:Change();
	end
	self:StopFallback();
	if(self.curSrc) then
		self.curSrc:SetPlayEndCb(nil);
		self.curSrc:stop();
		self.curSrc = nil;
	end
	self.curRegion = nil;
	-- 恢复原版 BGM 系统
	self:ResumeOriginalBGM();
end

-- 给 Scene.ReplaceBGMusic 用:临时让出 BGM, 之后 ResumeForReplace 恢复
function HaqiBgmPlaylist:PauseForReplace()
	if(not self.isPlaying or self.pausedForReplace) then return; end
	self.pausedForReplace = true;
	if(self.timer) then self.timer:Change(); end
	if(self.curSrc) then
		self.curSrc:SetPlayEndCb(nil);
		self.curSrc:stop();
	end
end

function HaqiBgmPlaylist:ResumeForReplace()
	if(not self.pausedForReplace) then return; end
	self.pausedForReplace = false;
	if(self.timer) then
		self.timer:Change(0, self.updateInterval);
	end
	self.cooldown = 0;
	local region = self:DetectRegion();
	if(region and region ~= self.curRegion) then
		self.curRegion = nil;     -- 触发重新切换
	end
end
