--[[
Title: ParaWorld Minimap Surface
Author(s): LiXizhi
Date: 2020/8/9
Desc: paint minimap around the current player location in a spiral pattern. 
	- click to close. 
	- mouse wheel to zoom in/out
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");

-- it is important for the parent window to enable self paint and disable auto clear background. 
window:EnableSelfPaint(true);
window:SetAutoClearBackground(false);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ParaWorldMinimapSurface = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface"));

ParaWorldMinimapSurface:Property({"CenterX", nil, desc="map center in block position"});
ParaWorldMinimapSurface:Property({"CenterY", nil, desc="map center in block position"});
ParaWorldMinimapSurface:Property({"MapRadius", 128*3/2, "GetMapRadius", "SetMapRadius", desc="map radius in block coordinate"});
-- we will only update the map when player moves between grid and over 1/4 into a neighbouring grid. 
ParaWorldMinimapSurface:Property({"GridSize", 128});
ParaWorldMinimapSurface:Property({"isShowGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
ParaWorldMinimapSurface:Property({"GridColor", "#333333"});
ParaWorldMinimapSurface:Property({"BlocksSamplingSize", 4});
ParaWorldMinimapSurface:Property({"BlocksSamplingLODSize", 4});
ParaWorldMinimapSurface:Property({"BlocksPerFrame", 50, desc = "how many blocks to render per frame. "});
ParaWorldMinimapSurface:Property({"BackgroundColor", "#000000"});

ParaWorldMinimapSurface:Signal("mapChanged");

-- mapping from block_id to block color like "#ff0000"
local color_table = nil;

function ParaWorldMinimapSurface:ctor()
	-- player in lock region will not update the map
	self.lockLeft = 0;
	self.lockRight = 0;
	self.lockTop = 0;
	self.lockBottom = 0;
	self:BuildBlockColorTable();
	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnTimer()
	end})
	self.timer:Change(1000, 1000);
end

function ParaWorldMinimapSurface:BuildBlockColorTable()
	if(color_table) then
		return
	end
	color_table = {};
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

	-- some random color used
	local default_colors = {"#ff0000", "#ffff00", "#ff00ff", "#00ff00", "#0000cc", "#00ffff"};
	default_colors_count = #default_colors;
	for id=1, 256 do
		local block_template = block_types.get(id);
		if(block_template) then
			local color = block_template.mapcolor;
			if(not color) then
				color = default_colors[(id%default_colors_count)+1];
			end
			color_table[id] = color;
		end
	end
end

function ParaWorldMinimapSurface:aboutToDestroy()
	if(self.timer) then
		self.timer:Change();
	end
end

function ParaWorldMinimapSurface:OnTimer()
	self:UpdatePlayerPos();
end

-- check if we only move 1/4 of a neighbouring block. 
function ParaWorldMinimapSurface:IsPointInLockRegion(x, y)
	return (self.lockLeft <= x and  x <= self.lockRight and self.lockTop <= y and y <= self.lockBottom);
end

-- @param x, y: if nil, we will use the current player's position. 
function ParaWorldMinimapSurface:UpdatePlayerPos(x, y)
	if(not x or not y) then
		local _;
		x, _, y = EntityManager.GetPlayer():GetBlockPos();
	end
	if(self.playerX~=x or self.playerY~=y) then
		self.playerX = x;
		self.playerY = y;
		if(not self:IsPointInLockRegion(x, y)) then
			local gridSize = self.GridSize;
			local centerX, centerY = math.floor(x / gridSize)*gridSize+gridSize/2, math.floor(y / gridSize)*gridSize+gridSize/2;
			self:SetMapCenter(centerX, centerY)
		end
	end
end

-- set center of the map in block coordinate system.
-- @param x,y: if nil, it will be current player's position. 
function ParaWorldMinimapSurface:SetMapCenter(x, y)
	if(not x or not y) then
		local _;
		x, _, y = EntityManager.GetPlayer():GetBlockPos();
	end
	if(self.CenterX~=x or self.CenterY~=y) then
		local radius = math.floor(self.GridSize*1.25/2);
		self.lockLeft =  x - radius;
		self.lockRight =  x + radius;
		self.lockTop =  y - radius;
		self.lockBottom =  y + radius;
		self.CenterX = x;
		self.CenterY = y;
		self:Invalidate();
		-- signal
		self:mapChanged();
	end
end

-- in block coordinate
function ParaWorldMinimapSurface:GetMapRadius()
	return self.MapRadius;
end

-- in block coordinate
function ParaWorldMinimapSurface:SetMapRadius(radius)
	local radius = math.max(16, math.min(radius, 512));
	if(self.MapRadius~=radius) then
		self.MapRadius = radius;
		self:Invalidate();
		-- signal
		self:mapChanged();
	end
end

function ParaWorldMinimapSurface:paintEvent(painter)
	if(self:width() <= 0) then
		return;
	end
	self:DrawBackground(painter);
	if(self:DrawSome(painter)) then
		if(self:IsShowGrid()) then
			self:DrawGrid(painter);
		end
	end
	self:ScheduleNextPaint();
end

function ParaWorldMinimapSurface:ResetDrawProgress()
	self.backgroundPainted = false;
	self.isGridPainted = false;
	self.last_x, self.last_y = 0,0;
	if(not self.CenterX) then
		return;
	end
	self.map_left = self.CenterX - self.MapRadius;
	self.map_top = self.CenterY - self.MapRadius;
	self.map_width = self.MapRadius * 2;
	self.map_height = self.MapRadius * 2;
	
	if(self:width() > 0) then
		self.step_size = self.BlocksSamplingSize;
		self.block_size = self:width() / (self.map_width / self.step_size) ;
		self.block_count = math.floor(self:width()/self.block_size);
	end
end

function ParaWorldMinimapSurface:Invalidate()
	self:ResetDrawProgress();
	self:ScheduleNextPaint();
end


function ParaWorldMinimapSurface:showEvent()
	-- always Invalidate when page become visible. 
	self:SetMapCenter(nil, nil)
	self:Invalidate();
end

function ParaWorldMinimapSurface:DrawBackground(painter)
	if(not self.backgroundPainted) then
		self.backgroundPainted = true;
		painter:SetPen(self.BackgroundColor);
		painter:DrawRect(self:x(), self:y(), self:width(), self:height());
	end
end


function ParaWorldMinimapSurface:GetHighmapColor(x,z)
	local block_id, y, block_data = BlockEngine:GetNextBlockOfTypeInColumn(x,255,z, 4, 255);
	if(block_id and block_id > 0) then
		local block_template = block_types.get(block_id);
		if(block_template) then
			return  block_template:GetBlockColorStrByData(block_data) or color_table[block_id] or "#0000ff"
		end
	end
end

function ParaWorldMinimapSurface:DrawGrid(painter)
	if(not self.isGridPainted) then
		self.isGridPainted = true;
		local count = self:GetMapRadius() * 2 / self.GridSize;
		local stepSize = self:width() / count;
		if(count > 1) then
			painter:SetPen(self.GridColor);
			for x = 1, count - 1 do
				local left = self:x()+x*stepSize;
				painter:DrawLine(left, self:y(), left, self:y()+ self:width());
			end
			for y = 1, count - 1 do
				local top = self:y()+y*stepSize;
				painter:DrawLine(self:x(), top, self:x()+self:width(), top);
			end
		end
	end
end

-- @return true if we have finished drawing
function ParaWorldMinimapSurface:DrawSome(painter)
	local step_size = self.step_size;
	local block_size = self.block_size;
	local block_count = self.block_count;

	local from_x, from_y = self.map_left, self.map_top;
	local count = 0;

	while (true) do
		local color = self:GetHighmapColor(from_x+self.last_x*step_size, from_y+self.last_y*step_size);
		if(color) then
			-- echo({color,from_x+self.last_x*step_size, from_y+self.last_y*step_size})
			painter:SetPen(color);
			painter:DrawRect(self.last_x*block_size, self.last_y*block_size, block_size, block_size);
		end
		count = count + 1;
		
		if(self.last_y >= block_count) then
			self.last_y = 0;
			self.last_x = self.last_x + 1;
		else
			self.last_y = self.last_y + 1;
		end
		if(count >= self.BlocksPerFrame or self.last_x > block_count) then
			break;
		end
	end
	return self.last_x > block_count;
end

function ParaWorldMinimapSurface:ScheduleNextPaint()
	if(self.block_count) then
		if(self.last_x > self.block_count) then
			self:ResetDrawProgress();
		else
			self:repaint();
		end
	end
end

-- virtual: 
function ParaWorldMinimapSurface:mousePressEvent(mouse_event)
	if(mouse_event:button() == "right" or mouse_event:button() == "left") then
		mouse_event:accept();
	end
end

-- virtual: 
function ParaWorldMinimapSurface:mouseReleaseEvent(mouse_event)
end

-- virtual: 
function ParaWorldMinimapSurface:mouseWheelEvent(mouse_event)
end