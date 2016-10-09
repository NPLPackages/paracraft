--[[
Title: 
Author(s): zrf
Date: 2011/2/24
Desc: 

------------------------------------------------
使用参考:(详细请参阅 test_pe_worldmap.html)


-- 设置NPC坐标数组
data = {"29909.43, 11.22, 20101.18","19909.43, 11.22, 20101.18","39909.43, 11.22, 20101.18"};
function DS_Source(index)
	if(index==nil)then
		return #data;
	else
		return data[index];
	end
end

<pe:worldmap background = "Texture/Aries/WorldMaps/HaqiTownMap/HaqiTownMap_bg.png;0 0 960 560" title = "哈奇岛" name = "haqiTownLocalMap"
    width = "878" height = "510" 
    StartIndex = "35"
	EndIndex = "39"
    AvatarArrow_bg = "Texture/Aries/Friends/MapAvatarMark_32bits.png"
    AvatarArrow_size = "40"
    isShownAvatar = true
    isFixedFacing = true 
    worldname = "61HaqiTown">

	<!--用地图坐标指定一个标记-->
    <pe:mark background = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest2_32bits.png; 0 0 60 52"
        highlight_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        pressed_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        tooltip = "page://script/apps/Aries/Desktop/WorldMaps/LocalMapTooltip.html?zone=magicforest"
        MapPosition = "328, 202, 50, 42"
		name = "(328, 202, 50, 42),(19909.43, 11.22, 20101.18),(8.71, 0.08, 2.92)"
        onclick="onClick1()" >
    </pe:mark>

	<!--用世界坐标指定一个标记-->
    <pe:mark background = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest2_32bits.png; 0 0 60 52"
        highlight_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        pressed_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        tooltip = "page://script/apps/Aries/Desktop/WorldMaps/LocalMapTooltip.html?zone=magicforest"
        WorldPosition = "19909.43, 11.22, 20101.18"
		name = "(328, 202, 50, 42),(19909.43, 11.22, 20101.18),(8.71, 0.08, 2.92)"
        onclick="onClick1()" >
    </pe:mark>

	<!--用世界坐标来指定3个标记,模拟NPC,可响应点击事件-->
    <pe:markassemble markassemble = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest2_32bits.png; 0 0 60 52"
        highlight_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        pressed_bg = "Texture/Aries/WorldMaps/HaqiTownMap/MagicForest_32bits.png; 0 0 60 52" 
        DataSourceWorldPos="DS_Source()"
		onclick="onClickNPC()" >
    </pe:mark>
</pe:map>
----------------------------------------------------------------

---++ pe:worldmap tag
| *Property*		| *Descriptions*				|
| name				| unique local map instance name|
| background		| map background url			|
| title				| map title name				|
| width				| width in pixel like "100px"	|
| height			| height in pixel like "100px"	|
| AvatarArrow_bg	| avatar arrow background url	|
| AvatarArrow_size	| avatar arrow ui object size	|
| isShownAvatar		| is avatar arrow shown			|
| isFixedFacing		| is avatar arrow facing fixed	|
| worldname			| 所在服务器名称					|
| StartIndex		| 地图对应的世界起始索引,以533.33为单位,默认35	|
| EndIndex			| 地图对应的世界结束索引,以533.33为单位，默认39	|


---++ pe:mark tag
| *Property*		| *Descriptions*				 |
| background		| mark background url |
| highlight_bg		| highlight background, if not specified, use the background property |
| pressed_bg		| pressed background, if not specified, use the highlight_bg or background property |
| tooltip			| mouse over tooltip |
| MapPosition		| coordinate of mark on map(in pixel) "x, y, width, height" e.g. "42, 69, 32, 32" |
| WorldPosition		| 以世界坐标指定标记的位置大小, "x, y, width, height" e.g. "42, 69, 32, 32",如果指定了MapPosition则本属性无效 |
| clickable			| true or false, if clickable is empty then use false as default value.
| onclick			| 标记被点击之后触发的回调函数, 传递参数依次为 name, mcmlNode


---++ pe:markassemble tag
用于显示多个图片类似但是大小和位置不同的标记.
| *Property*		| *Descriptions*				 |
| background		| mark background url |
| highlight_bg		| highlight background, if not specified, use the background property |
| pressed_bg		| pressed background, if not specified, use the highlight_bg or background property |
| tooltip			| mouse over tooltip |
| DataSourceMapPos	| 标记对应的地图坐标的数据源函数,像素为单位 "x, y, width, height" e.g. {"42, 69, 32, 32","50, 210, 76, 100"} |
| DataSourceWorldPos| 标记对应的世界坐标的数据源函数, "x, y, width, height" e.g. {"42.5, 69.4, 32.1, 32.0","50.21, 210.09, 76.3, 100.0"} |
| clickable			| true or false, if clickable is empty then use false as default value.
| onclick			| 标记被点击之后触发的回调函数, 传递参数依次为 name, mcmlNode, index


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_worldmap.lua");
-------------------------------------------------------
--]]

NPL.load("(gl)script/ide/timer.lua");
local pe_worldmap = commonlib.gettable("Map3DSystem.mcml_controls.pe_worldmap");

local ItemManager = System.Item.ItemManager;
local hasGSItem = ItemManager.IfOwnGSItem;

pe_worldmap.LocalMaps = {};
pe_worldmap.instances = {};

function pe_worldmap.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local background = mcmlNode:GetAttributeWithCode("background") or "";
	local foreground = mcmlNode:GetAttributeWithCode("foreground") or "";
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:map"]) or {};
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
			
	local tmpWidth = mcmlNode:GetNumber("width") or css.width;
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end
	local tmpHeight = mcmlNode:GetNumber("height") or css.height
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom
	end
	
	parentLayout:AddObject(width-left, height-top);
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local instName = mcmlNode:GetAttribute("name");
	pe_worldmap.instances[instName] = mcmlNode;
	
	if(instName ==  nil) then
		log("error: nil name for pe:map canvas\n")
		return;
	end

	--local RefPos1 = mcmlNode:GetAttributeWithCode("RefPos1") or "";
	--local RefPos2 = mcmlNode:GetAttributeWithCode("RefPos2") or "";
	local AvatarArrow_bg = mcmlNode:GetAttributeWithCode("AvatarArrow_bg") or "";
	local AvatarArrow_size = mcmlNode:GetNumber("AvatarArrow_size") or 15;
	local isShownAvatar = mcmlNode:GetBool("isShownAvatar") or true;
	local isFixedFacing = mcmlNode:GetBool("isFixedFacing") or false;
	local worldname = mcmlNode:GetString("worldname") or "";
	
	-- don't show avatar position if in other world
	local worldDir = ParaWorld.GetWorldDirectory();
	if(worldDir ~= "worlds/MyWorlds/"..worldname.."/") then
		isShownAvatar = false;
	end

	---------------------------------------------
	-- 平面地图与真实世界的对应关系
	local StartIndex = tonumber(mcmlNode:GetString("StartIndex") or "35");
	local EndIndex = tonumber(mcmlNode:GetString("EndIndex") or "39");

	local StartWorldX = StartIndex * 533.33;
	local StartWorldY = StartWorldX;
	local WorldWidth = (EndIndex - StartWorldX) * 533.33;
	local WorldHeight = WorldWidth;

	local ScaleX = tmpWidth / WorldWidth;
	local ScaleY = tmpHeight / WorldHeight;
	---------------------------------------------

	local mapParams = {
		width = width, 
		height = height, 
		StartWorldX = StartWorldX,		-- 对应地图左上角的世界坐标
		StartWorldY = StartWorldY,		
		WorldWidth = WorldWidth,		-- 地图展现的真实世界大小
		WorldHeight = WorldHeight,
		ScaleX = ScaleX,				-- 地图和真实世界缩放比例
		ScaleY = ScaleY,
		isShownAvatar = isShownAvatar, 
		isFixedFacing = isFixedFacing, 
		anchors = {},
	};
	
	pe_worldmap.LocalMaps[instName] = mapParams;
	
	local _mapCanvas = ParaUI.CreateUIObject("container", instName, "_lt", left, top, width-left, height-top);
	--_mapCanvas.enabled = false;
	if(background == "") then
		_mapCanvas.background = css.background or "";
	else
		-- tricky: this allows dynamic images to update itself, _mapCanvas.background only handles static images with fixed size.
		_mapCanvas.background = background;
	end
	local fastrender = mcmlNode:GetBool("fastrender");
	if(fastrender == nil) then
		fastrender = true;
	end
	_mapCanvas.fastrender = fastrender;
	_guihelper.SetUIColor(_mapCanvas, css["background-color"] or "255 255 255");
	
	_parent:AddChild(_mapCanvas);
	
	if(string.find(background, "http://")) then
		-- TODO: garbage collect HTTP textures after it is no longer used?
	end
	
	-- render mark nodes
	local function render_node(childnode)
		if(type(childnode) ~= "table") then
			return true;
		end
		if(childnode.name == "pe:mark") then
			local background = childnode:GetAttributeWithCode("background") or "";
			local highlight_bg = childnode:GetAttributeWithCode("highlight_bg") or background;
			local pressed_bg = childnode:GetAttributeWithCode("pressed_bg") or highlight_bg;
			local tooltip = childnode:GetAttributeWithCode("tooltip") or "";
			local clickable = string.lower(childnode:GetAttributeWithCode("clickable") or "false");
			local onclick = childnode:GetAttributeWithCode("onclick") or "";
			local MapPosition = childnode:GetAttributeWithCode("mapposition") or "";
			local WorldPosition = childnode:GetAttributeWithCode("worldposition") or "";
			local name = childnode:GetAttributeWithCode("name",nil,true);

			if(clickable=="true" and onclick=="" )then
				log("error: onclick must be specified in pe:mark: \n");
				commonlib.echo(childnode);
				return false;				
			end

			local _scaleX, _scaleY;
			local _pos;
			
			if( MapPosition )then
				_pos = MapPosition;
				_scaleX = 1;
				_scaleY = 1;
			elseif(WorldPosition)then
				_pos = WorldPosition;
				_scaleX = mapParams.ScaleX;
				_scaleY = mapParams.ScaleY;
			else
				log("error: map position or world position must be specified in pe:mark: \n");
				commonlib.echo(childnode);
				return false;
			end

			if(_pos) then
				local _pos = string.gsub(_pos, " ", "");
				local mapX, mapY, mapWidth, mapHeight = string.match(_pos, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
				mapX = tonumber(mapX) * _scaleX;
				mapY = tonumber(mapY) * _scaleY;
				mapWidth = tonumber(mapWidth) * _scaleX;
				mapHeight = tonumber(mapHeight) * _scaleY;
			end

			pe_worldmap.addmark(background,highlight_bg,pressed_bg,tooltip,mapX,mapY,mapWidth,mapHeight);

		elseif(childnode.name == "pe:markassemble")then -- 批量显示 图片相同但是位置大小不同的标记
			local background = childnode:GetAttributeWithCode("background") or "";
			local highlight_bg = childnode:GetAttributeWithCode("highlight_bg") or background;
			local pressed_bg = childnode:GetAttributeWithCode("pressed_bg") or highlight_bg;
			local tooltip = childnode:GetAttributeWithCode("tooltip") or "";
			local clickable = string.lower(childnode:GetAttributeWithCode("clickable") or "false");
			local onclick = childnode:GetAttributeWithCode("onclick") or "";
			local name = childnode:GetAttributeWithCode("name",nil,true);
			local DataSourceMapPos = childnode:GetAttributeWithCode("DataSourceMapPos",nil,true);
			local DataSourceWorldPos = childnode:GetAttributeWithCode("DataSourceWorldPos",nil,true);

			if(clickable=="true" and onclick=="" )then
				log("error: onclick must be specified in pe:markassemble: \n");
				commonlib.echo(childnode);
				return false;				
			end

			local _scaleX, _scaleY;
			local DataSource;

			if( DataSourceMapPos )then
				DataSource = DataSourceMapPos;
				_scaleX = 1;
				_scaleY = 1;
			elseif(DataSourceWorldPos)then
				DataSource = DataSourceWorldPos;
				_scaleX = mapParams.ScaleX;
				_scaleY = mapParams.ScaleY;
			else
				log("error: DataSourceMapPos or DataSourceWorldPos must be specified in pe:markassemble: \n");
				commonlib.echo(childnode);
				return false;
			end

			if(DataSource)then
				local count = pageCtrl:CallMethod(DataSource, "GetItemCount");
				local i;
				if(count and count > 0)then
					for i=1,count do
						local row = pageCtrl:CallMethod(DataSource, "GetRow", i);
						if(row)then
							local mapX, mapY, mapWidth, mapHeight = string.match(row, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
							mapX = tonumber(mapX) * _scaleX;
							mapY = tonumber(mapY) * _scaleY;
							mapWidth = tonumber(mapWidth) * _scaleX;
							mapHeight = tonumber(mapHeight) * _scaleY;

							pe_worldmap.addmark(background,highlight_bg,pressed_bg,tooltip,mapX,mapY,mapWidth,mapHeight,i);
						end
					end
				end
			end
		else
			local left, top, width, height = parentLayout:GetPreferredRect();
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, parentLayout)

			local childnode_;
			for childnode_ in childnode:next() do
				if(type(childnode_) == "table") then
					render_node(childnode_);
				end
			end
		end

		return true;
	end

	-- add all child pe:mark nodes
	local childnode;
	for childnode in mcmlNode:next() do
		if(not render_node(childnode)) then
			break;
		end
	end
	
	if(foreground and foreground ~= "") then
		local _mapForeground = ParaUI.CreateUIObject("container", "foreground", "_lt", left, top, width-left, height-top);
		_mapForeground.background = mcmlNode:GetAbsoluteURL(foreground);
		_guihelper.SetUIColor(_mapForeground, css["background-color"] or "255 255 255");
		_mapForeground.enabled = false;
		_parent:AddChild(_mapForeground);
	end
	
	-- update the avatar arrow
	local _avatarArrow = ParaUI.CreateUIObject("container", "AvatarArrow", "_lt", 
			-AvatarArrow_size/2, -AvatarArrow_size/2, AvatarArrow_size, AvatarArrow_size);
	_avatarArrow.enabled = false;
	_avatarArrow.visible = false;
	_avatarArrow.zorder = 100; --  stay above the pe:marks and push layer
	_avatarArrow.background = AvatarArrow_bg;
	_mapCanvas:AddChild(_avatarArrow);
	
	-- update the arrow according to player position
	--pe_worldmap.RegisterPeMapUpdateAvatarTimer();
end

function pe_worldmap.addmark(background,highlight_bg,pressed_bg,tooltip,mapX,mapY,mapWidth,mapHeight,index)
	local _conMark = ParaUI.CreateUIObject("container", "_conMark", "_lt", mapX, mapY, mapWidth, mapHeight);
	_conMark.background = "";
	_mapCanvas:AddChild(_conMark);

	local _btnMark = ParaUI.CreateUIObject("button", "mark", "_lt", 0, 0, mapWidth, mapHeight);
	local tooltip_page = string.match(tooltip or "", "page://(.+)");
	if(tooltip_page) then
		CommonCtrl.TooltipHelper.BindObjTooltip(_btnMark.id, tooltip_page);
	else
		_btnMark.tooltip = tooltip;
	end

	if(clickable=="true" and onclick~="")then
		Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, onclick, name, mcmlNode, index);
	end

	if(background == highlight_bg and highlight_bg == pressed_bg) then
		_btnMark.background = background;
	else
		_guihelper.SetVistaStyleButton3(_btnMark, background, highlight_bg, background, pressed_bg);
	end

	_conMark:AddChild(_btnMark);
end

-- get the MCML value on the node
function pe_worldmap.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_worldmap.SetValue(mcmlNode, value)
	if(type(value) == "string") then
		mcmlNode:SetInnerText(value)
	else
		mcmlNode:SetInnerText(nil);
	end	
end

-- get the UI value on the node
function pe_worldmap.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		return ctl.text;
	end
end

-- set the UI value on the node
function pe_worldmap.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(value) then
			local text = tostring(value);
			--resize control
			local textWidth = _guihelper.GetTextWidth(text) + 6
			ctl.width = textWidth;
			ctl.text = text;
		else
			ctl.text = "";
		end	
	end
end