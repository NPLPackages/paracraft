--[[
Title: WorldInfo
Author(s): LiXizhi
Date: 2014/6/30
Desc: base world info. world info is saved to disk file ([worldpath]/tag.xml)
game logic filters:
	load_world_info(worldInfo, xmlNode)
	save_world_info(worldInfo, xmlNode)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldInfo.lua");
local WorldInfo = commonlib.gettable("MyCompany.Aries.Game.WorldInfo")
local world_info = WorldInfo:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldInfo = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.WorldInfo"));

-- x,y,z,block_id
function WorldInfo:ctor()
	self.totalTime = 0;
	self.worldTime = 0;
	self.totalEditSeconds = 0;
	self.totalClicks = 0;
	self.totalKeyStrokes = 0;
	self.totalSingleBlocks = 0;
end

function WorldInfo:LoadFromXMLNode(node)
	if(node and node.attr) then
		commonlib.partialcopy(self, node.attr);
		self.texture_pack_path = commonlib.Encoding.Utf8ToDefault(self.texture_pack_path or self.texture_pack or "");
		self.weather_strength = tonumber(self.weather_strength);
		self.totaltime = tonumber(self.totaltime);
		self.isVipWorld = self.isVipWorld == "true" or self.isVipWorld == true;
		self.hasCopyright = self.hasCopyright == "true" or self.hasCopyright == true;
		self.selectWater = self.selectWater == "true" or self.selectWater == true;

		self:SetTotalWorldTime(self.totaltime or 0);
		self.totalEditSeconds = tonumber(self.totalEditSeconds) or 0;
		self.totalClicks = tonumber(self.totalClicks) or 0;
		self.totalKeyStrokes = tonumber(self.totalKeyStrokes) or 0;
		self.totalSingleBlocks = tonumber(self.totalSingleBlocks) or 0;

		GameLogic.GetFilters():apply_filters("load_world_info", self, node);
	end
end

function WorldInfo:SaveToXMLNode(node, bSort)
	node = node or {name='pe:world', attr={}};

	node.attr = {
		name = self.name or "", 
		nid = self.nid or System.User.nid, 
		create_date = self.create_date or ParaGlobal.GetDateFormat("yyyy-M-d"),
		size = tostring(self.size or 0),
		desc = self.desc or "",
		world_generator = self.world_generator or "",
		seed = self.seed or "",
		shadow = self.shadow or "",
		waterreflection = self.waterreflection or "",
		rendermethod = self.rendermethod or "",
		renderdist = self.renderdist or "",
		texture_pack_path = self.texture_pack_path or "",
		texture_pack_type = self.texture_pack_type or "",
		texture_pack_url = self.texture_pack_url or "",
		texture_pack_text = self.texture_pack_text or "",
		totaltime = self:GetWorldTotalTime(),
		global_terrain = self.global_terrain,
		fromProjects = self.fromProjects,
		isVipWorld = self.isVipWorld,
		hasCopyright = self.hasCopyright,
		selectWater = self.selectWater,
		extra = tostring(self.extra),
		privateKey = self.privateKey or "",
		totalEditSeconds = tonumber(self.totalEditSeconds) or 0,--总编辑时长， 用户在编辑模式下，并且窗口有输入焦点时的总时 长。
		totalClicks = tonumber(self.totalClicks) or 0,--编辑模式下，每次鼠标操作点击（无论左右键）的总次数。
		totalKeyStrokes = tonumber(self.totalKeyStrokes) or 0,--编辑模式下，总打字次数，包括命令，代码方块等一切键盘操作，但Ctrl、shift、alt除外。
		totalSingleBlocks = tonumber(self.totalSingleBlocks) or 0,--创建的总方块数，只计算单击鼠标创建的方块数。复制粘贴，拉伸等不算。 例外，shift+右键算1个方块。 这里需要在鼠标事件的地方截取数据，程序生成的不算。

		totalWorkScore = self:GetTotalWorkScore()
	};

	GameLogic.GetFilters():apply_filters("save_world_info", self, node);
	return node;
end

--(作品体量总分 ) = (totalEditSeconds/20 + totalClicks + totalKeyStrokes * 2 + totalSingleBlocks * 3)/ 1000 （取整数）
function WorldInfo:GetTotalWorkScore()
	return math.floor((self.totalEditSeconds/20 + self.totalClicks + self.totalKeyStrokes * 2 + self.totalSingleBlocks * 3)/ 1000)
end

function WorldInfo:GetTerrainType()
	return self.world_generator;
end

function WorldInfo:GetTexturePack()
	return self.texture_pack or "";
end

function WorldInfo:GetOwnerNid()
	return self.nid or "";
end

-- owner xml node
function WorldInfo:GetPlayerXmlNode()
end

-- total number of world ticks since the world is created. 
-- this can also be served as a revision number. 
function WorldInfo:GetWorldTotalTime()
    return self.totalTime;
end

-- current world time in day-light cycle (repeat in a day).
function WorldInfo:GetWorldTime()
    return self.worldTime;
end

function WorldInfo:SetTotalWorldTime(time)
    self.totalTime = time or self.totalTime;
end

-- Set current world time
function WorldInfo:SetWorldTime(time)
    self.worldTime = time;
end