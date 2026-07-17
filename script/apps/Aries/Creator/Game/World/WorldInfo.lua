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
local WorldInfo = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.WorldInfo"));

WorldInfo.class_name = "WorldInfo";
WorldInfo:Property({"totalTime", 0, auto=true})
WorldInfo:Property({"worldTime", 0, auto=true})
WorldInfo:Property({"totalEditSeconds", 0, auto=true})
WorldInfo:Property({"totalClicks", 0, auto=true})
WorldInfo:Property({"totalKeyStrokes", 0, auto=true})
WorldInfo:Property({"totalSingleBlocks", 0, auto=true})
WorldInfo:Property({"editCodeLine", 0, auto=true})
WorldInfo:Property({"assetUrl", "", auto=true})
WorldInfo:Property({"isFreezeWorld", false, auto=true})

-- x,y,z,block_id
function WorldInfo:ctor()
	self.totalTime = 0;
	self.worldTime = 0;
	self.totalEditSeconds = 0;
	self.totalClicks = 0;
	self.totalKeyStrokes = 0;
	self.totalSingleBlocks = 0;
	self.editCodeLine = 0
	self.isFreezeWorld = false
end

function WorldInfo:LoadFromXMLNode(node)
	if(node and node.attr) then
		commonlib.partialcopy(self, node.attr);
		self.texture_pack_path = commonlib.Encoding.Utf8ToDefault(self.texture_pack_path or self.texture_pack or "");
		self.weather_strength = tonumber(self.weather_strength);
		self.totaltime = tonumber(self.totaltime);
		self.isVipWorld = self.isVipWorld == "true" or self.isVipWorld == true;
		self.isCommonVipWorld = self.isCommonVipWorld == "true" or self.isCommonVipWorld == true;
		self.hasCopyright = self.hasCopyright == "true" or self.hasCopyright == true;
		self.selectWater = self.selectWater == "true" or self.selectWater == true;

		self:SetTotalWorldTime(self.totaltime or 0);
		self.totalEditSeconds = tonumber(self.totalEditSeconds) or 0;
		self.totalClicks = tonumber(self.totalClicks) or 0;
		self.totalKeyStrokes = tonumber(self.totalKeyStrokes) or 0;
		self.totalSingleBlocks = tonumber(self.totalSingleBlocks) or 0;
		self.editCodeLine = tonumber(self.editCodeLine) or 0; 
		self.model_entity_num = tonumber(self.model_entity_num) or 0;
		self.totalWorkScore_bak = tonumber(self.totalWorkScore_bak) or 0;
		self.player_skin = self.player_skin or "";
		self.isHomeWorkWorld = self.isHomeWorkWorld == "true" or self.isHomeWorkWorld == true;
		self.platform = self.platform or "paracraft";
		-- web课程相关
		self.lessonPackageName = self.lessonPackageName or ""
		self.lessonName = self.lessonName or ""
		self.materialName = self.materialName or ""
		self.classroomId = self.classroomId or ""
		self.sectionContentId = self.sectionContentId or ""
		-- web课程相关 end	
		
		--世界类型
		--类型 '来源标识: 自主创建.0 (默认), edu课程-创作模板.1, 赛事系统.2, 帕帕奇遇记课程-创作模板.3',
		self.channel = self.channel or 0
		self.visibility = self.visibility or 0 --是否私有
		
		GameLogic.GetFilters():apply_filters("load_world_info", self, node);

		--世界冻结
		self.isFreezeWorld = self.isFreezeWorld == "true" or self.isFreezeWorld == true;

		--p3d文件
		self.parentInfo = self.parentInfo or "";

		-- 是否显示宠物 和 坐骑
		self.show_mount_pet = self.show_mount_pet or "false";
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
		isCommonVipWorld = self.isCommonVipWorld,
		hasCopyright = self.hasCopyright,
		selectWater = self.selectWater,
		extra = tostring(self.extra),
		privateKey = self.privateKey or "",
		totalEditSeconds = tonumber(self.totalEditSeconds) or 0,--总编辑时长， 用户在编辑模式下，并且窗口有输入焦点时的总时 长。
		totalClicks = tonumber(self.totalClicks) or 0,--编辑模式下，每次鼠标操作点击（无论左右键）的总次数。
		totalKeyStrokes = tonumber(self.totalKeyStrokes) or 0,--编辑模式下，总打字次数，包括命令，代码方块等一切键盘操作，但Ctrl、shift、alt除外。
		totalSingleBlocks = tonumber(self.totalSingleBlocks) or 0,--创建的总方块数，只计算单击鼠标创建的方块数。复制粘贴，拉伸等不算。 例外，shift+右键算1个方块。 这里需要在鼠标事件的地方截取数据，程序生成的不算。

		totalWorkScore = self:GetTotalWorkScore(),
		totalWorkScore_bak = self.totalWorkScore_bak or 0, --备份

		superrenderdist = self.superrenderdist or "",
		hide_player = self.hide_player or "", --隐藏角色（设置界面）
		stereoMode = self.stereoMode or "", --立体输出
		weather = self.weather or "", --环境设置界面的, sun,cloudy,rain,snow
		lightcolor = self.lightcolor or "", --光源颜色
		autoDayTime = self.autoDayTime, --自动昼夜交替
		lastdaytime = self.lastdaytime or "",--退出世界自动保存时间
		eyeBrightness = self.eyeBrightness or "",--亮度
		cloudThickness = self.cloudThickness or "",--云量
		editCodeLine = tonumber(self.editCodeLine) or 0, 
		model_entity_num = tonumber(self.model_entity_num) or 0, --模型实体数量

		isHomeWorkWorld = self.isHomeWorkWorld, --是否课程作业世界

		-- web课程相关
		lessonPackageName = self.lessonPackageName or "",
		lessonName = self.lessonName or "",
		materialName = self.materialName or "",
		classroomId = self.classroomId or "",
		sectionContentId = self.sectionContentId or "",

		--世界类型
		--类型 '来源标识: 自主创建.0 (默认), edu课程-创作模板.1, 赛事系统.2, 帕帕奇遇记课程-创作模板.3',
		channel = self.channel or 0, 
		visibility = self.visibility or 0, --是否私有

		player_skin = self.player_skin or "",
		platform = self.platform or "paracraft", -- from which client.
		assetUrl = self.assetUrl,
		isFreezeWorld = self.isFreezeWorld,

		-- p3d文件
		parentInfo = self.parentInfo or "",
		-- 是否显示宠物 和 坐骑
		show_mount_pet = self.show_mount_pet or "false",
	};

	GameLogic.GetFilters():apply_filters("save_world_info", self, node);
	return node;
end

--(作品体量总分 ) = (totalEditSeconds/20 + totalClicks + totalKeyStrokes * 2 + totalSingleBlocks * 3)/ 1000 （取小数后一位，最小0.1）
function WorldInfo:GetTotalWorkScore()
	local totalWorkScore = math.floor(((self.totalEditSeconds/20 + self.totalClicks + self.totalKeyStrokes * 2 + self.totalSingleBlocks * 3 + self.editCodeLine*5 + (self.model_entity_num or 0)*5)/ 1000)*10)/10
	if System.options.isPapaAdventure then --帕帕奇遇记的先放大10倍，方便生成视频
		totalWorkScore = totalWorkScore * 10
	end
	return totalWorkScore
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