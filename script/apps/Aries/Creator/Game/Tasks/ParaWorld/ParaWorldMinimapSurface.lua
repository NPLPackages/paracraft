--[[
Title: ParaWorld Minimap Surface
Author(s): LiXizhi
Date: 2020/8/9
Desc: paint minimap with a sampling rate
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
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
local ParaWorldMinimapSurface = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface"));

ParaWorldMinimapSurface:Property({"CenterX", nil, desc="map center in block position"});
ParaWorldMinimapSurface:Property({"CenterY", nil, desc="map center in block position"});
ParaWorldMinimapSurface:Property({"MapRadius", 128*3/2, "GetMapRadius", "SetMapRadius", desc="map radius in block coordinate"});
-- we will only update the map when player moves between grid and over 1/4 into a neighbouring grid. 
ParaWorldMinimapSurface:Property({"GridSize", 128});
ParaWorldMinimapSurface:Property({"isShowGrid", false, "IsShowGrid", "SetShowGrid", auto=true});
ParaWorldMinimapSurface:Property({"GridColor", "#33333380"});
ParaWorldMinimapSurface:Property({"BlocksSamplingSize", 4});
ParaWorldMinimapSurface:Property({"BlocksSamplingLODSize", 4});
ParaWorldMinimapSurface:Property({"BlocksPerFrame", 500, desc = "how many blocks to render per frame. "});
ParaWorldMinimapSurface:Property({"BackgroundColor", "#000000"});
-- use self:LockMap() method to lock. do not set this manually. 
ParaWorldMinimapSurface:Property({"isMapLocked", false});

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
	if(ParaWorldMain:IsMiniWorld()) then
		self.BlocksSamplingSize = 1;
		self:LockMap(19200, 19200, 128/2)
	else
		self.timer:Change(1000, 1000);
	end
end

-- lock map at given region. 
function ParaWorldMinimapSurface:LockMap(centerX, centerZ, radius)
	self.isMapLocked = true;
	self.timer:Change();
	self:SetMapRadius(radius);
	self:SetShowGrid(false);
	self:SetMapCenter(19200, 19200)
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

function ParaWorldMinimapSurface:Destroy()
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
function ParaWorldMinimapSurface:UpdatePlayerPos(x, y, facing)
	if(not x or not y) then
		local _;
		local player = EntityManager.GetPlayer()
		if(player) then
			x, _, y = player:GetBlockPos();
			facing = player:GetFacing();
		else
			return
		end
	end
	self.playerFacing = facing or self.playerFacing;
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
		local gridSize = self.GridSize;
		x, _, y = EntityManager.GetPlayer():GetBlockPos();
		x, y = math.floor(x / gridSize)*gridSize+gridSize/2, math.floor(y / gridSize)*gridSize+gridSize/2;
	end
	if(self.CenterX~=x or self.CenterY~=y) then
		if(self.isMapLocked) then
			self.lockLeft =  0;
			self.lockRight =  0;
			self.lockTop =  999999;
			self.lockBottom =  999999;
		else
			local radius = math.floor(self.GridSize*1.25/2);
			self.lockLeft =  x - radius;
			self.lockRight =  x + radius;
			self.lockTop =  y - radius;
			self.lockBottom =  y + radius;
		end
		self.CenterX = x;
		self.CenterY = y;

		self.map_left = self.CenterX - self.MapRadius;
		self.map_top = self.CenterY - self.MapRadius;
		self.map_width = self.MapRadius * 2;
		self.map_height = self.MapRadius * 2;

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
	
	if(self:width() > 0) then
		self.step_size = self.BlocksSamplingSize;
		self.block_size = self:width() / (self.map_width / self.step_size) ;
		self.block_count = math.floor(self:width()/self.block_size);
	end
end

-- convert from world position to 2d map position in pixel. 
-- @return nil, nil if point is not on map
function ParaWorldMinimapSurface:WorldToMapPos(worldX, worldZ)
	local mapX, mapZ = worldX - self.map_left, worldZ - self.map_top;
	if(mapX>=0 and mapX < self.map_width and mapZ>=0 and mapZ < self.map_height) then
		local width, height = self:width(), self:height();
		local x = math.floor(width - mapZ/self.map_height * width)
		local y = math.floor(height - mapX/self.map_width * height)
		return x, y
	end
end

-- convert from map 2d position to world position
function ParaWorldMinimapSurface:MapToWorldPos(mapX, mapZ)
	local width, height = self:width(), self:height();
	local worldX = math.floor((1 - mapZ/height) * self.map_width + self.map_left)
	local worldZ = math.floor((1 - mapX/width) * self.map_height + self.map_top)
	return worldX, worldZ;
end

function ParaWorldMinimapSurface:Invalidate()
	self:ResetDrawProgress();
	self:ScheduleNextPaint();
end


function ParaWorldMinimapSurface:showEvent()
	-- always Invalidate when page become visible. 
	if(not self.isMapLocked) then
		self:SetMapCenter(nil, nil)
	end
	self:Invalidate();
end

function ParaWorldMinimapSurface:DrawBackground(painter)
	if(not self.backgroundPainted) then
		self.backgroundPainted = true;
		painter:SetPen(self.BackgroundColor);
		painter:DrawRect(self:x(), self:y(), self:width(), self:height());
	end
end

-- get the highest block at world block position. may return nil if no block is found
function ParaWorldMinimapSurface:GetHeightByWorldPos(x, z)
	local block_id, y, block_data = BlockEngine:GetNextBlockOfTypeInColumn(x,255,z, 255, 255);
	if(block_id and block_id > 0) then
		return y;
	end
end

function ParaWorldMinimapSurface:GetHighmapColor(x,z)
	local block_id, y, block_data = BlockEngine:GetNextBlockOfTypeInColumn(x,255,z, 255, 255);
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

	local width, height = self:width(), self:height();

	while (true) do
		local color = self:GetHighmapColor(from_x+self.last_x*step_size, from_y+self.last_y*step_size);
		if(color) then
			-- echo({color,from_x+self.last_x*step_size, from_y+self.last_y*step_size})
			painter:SetPen(color);
			painter:DrawRect(self:x() + width - self.last_y*block_size, self:y() + height - self.last_x*block_size, block_size, block_size);
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
end

-- virtual: 
function ParaWorldMinimapSurface:mouseReleaseEvent(mouse_event)
end

-- virtual: 
function ParaWorldMinimapSurface:mouseWheelEvent(mouse_event)
end