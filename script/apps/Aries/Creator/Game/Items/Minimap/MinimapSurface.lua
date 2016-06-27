--[[
Title: Minimap Surface
Author(s): LiXizhi
Date: 2015/5/05
Desc: paint minimap around the current player location in a spiral pattern. 
	- click to close. 
	- mouse wheel to zoom in/out
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/Minimap/MinimapSurface.lua");
local MinimapSurface = commonlib.gettable("Paracraft.Controls.MinimapSurface");

-- it is important for the parent window to enable self paint and disable auto clear background. 
window:EnableSelfPaint(true);
window:SetAutoClearBackground(false);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local MinimapSurface = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("Paracraft.Controls.MinimapSurface"));

MinimapSurface:Property({"CenterX", nil, desc="map center in block position"});
MinimapSurface:Property({"CenterY", nil, desc="map center in block position"});
MinimapSurface:Property({"MapRadius", 32, "GetMapRadius", "SetMapRadius", desc="map radius in block coordinate"});
MinimapSurface:Property({"BlocksPerFrame", 20, desc = "how many blocks to render per frame. "});

MinimapSurface:Signal("mapChanged");

-- mapping from block_id to block color like "#ff0000"
local color_table = nil;

function MinimapSurface:ctor()
	self:ResetDrawProgress();
	self:BuildBlockColorTable();
end

function MinimapSurface:BuildBlockColorTable()
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

-- set center of the map in block coordinate system.
-- @param x,y: if nil, it will be current player's position. 
function MinimapSurface:SetMapCenter(x, y)
	if(not x or not y) then
		local _;
		x, _, y = EntityManager.GetPlayer():GetBlockPos();
	end
	if(self.CenterX~=x or self.CenterY~=y) then
		self.CenterX = x;
		self.CenterY = y;
		self:Invalidate();
		-- signal
		self:mapChanged();
	end
end

-- in block coordinate
function MinimapSurface:GetMapRadius()
	return self.MapRadius;
end

-- in block coordinate
function MinimapSurface:SetMapRadius(radius)
	local radius = math.max(16, math.min(radius, 512));
	if(self.MapRadius~=radius) then
		self.MapRadius = radius;
		self:Invalidate();
		-- signal
		self:mapChanged();
	end
end

function MinimapSurface:paintEvent(painter)
	if(self:width() <= 0) then
		return;
	end
	self:DrawBackground(painter);
	self:DrawSome(painter);
	self:DrawPlayerPos(painter)
	self:ScheduleNextPaint();
end

function MinimapSurface:ResetDrawProgress()
	self.backgroundPainted = false;
	self.last_x, self.last_y = 0,0;
	if(not self.CenterX) then
		self:SetMapCenter(nil, nil);
		return;
	end
	self.map_left = self.CenterX - self.MapRadius;
	self.map_top = self.CenterY - self.MapRadius;
	self.map_width = self.MapRadius * 2;
	self.map_height = self.MapRadius * 2;
	if(self:width() > 0) then
		self.step_size = self.map_width / self:width();
		self.block_size = 1 / self.step_size;
		if(self.step_size <= 1) then
			self.step_size = 1;
			self.block_count = self.map_width;
			self.block_size = self:width()/self.block_count;
		else
			self.block_count = math.floor(self:width()/self.block_size);
		end
	end
end

function MinimapSurface:Invalidate()
	self:ResetDrawProgress();
	self:ScheduleNextPaint();
end


function MinimapSurface:showEvent()
	-- always Invalidate when page become visible. 
	self:SetMapCenter(nil, nil)
	self:Invalidate();
end

function MinimapSurface:DrawBackground(painter)
	if(not self.backgroundPainted) then
		self.backgroundPainted = true;
		painter:SetPen("#ffffffff");
		painter:DrawRect(self:x(), self:y(), self:width(), self:height());
	end
end


function MinimapSurface:GetHighmapColor(x,z)
	local block_id, y = BlockEngine:GetNextBlockOfTypeInColumn(x,255,z, 4, 255);
	if(block_id and block_id > 0) then
		return color_table[block_id] or "#0000ff";
	else
		return "#000000"
	end
end

function MinimapSurface:DrawSome(painter)
	local step_size = self.step_size;
	local block_size = self.block_size;
	local block_count = self.block_count;

	local from_x, from_y = self.map_left, self.map_top;
	local count = 0;

	while (true) do
		local color = self:GetHighmapColor(from_x+self.last_x*step_size, from_y+self.last_y*step_size);
		-- echo({color,from_x+self.last_x*step_size, from_y+self.last_y*step_size})
		painter:SetPen(color);
		painter:DrawRect(self.last_x*block_size, self.last_y*block_size, block_size, block_size);
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
end

function MinimapSurface:DrawPlayerPos(painter)
	if(self.last_x > self.block_count) then
		-- draw a red cross for player info
		local playerX, _, playerY = EntityManager.GetPlayer():GetBlockPos();
		local x = (playerX+0.5 - self.map_left) / self.map_width;
		local y = (playerY+0.5 - self.map_top) / self.map_height;
		x = math.min(0.99, math.max(x, 0.01));
		y = math.min(0.99, math.max(y, 0.01));
		x, y = x*self:width(), y*self:height();
		painter:SetPen("#ff0000");
		painter:Save();
		painter:Translate(x, y);
		painter:Rotate(45);
		painter:DrawRect(-8, -2, 16, 4);
		painter:Rotate(90);
		painter:DrawRect(-8, -2, 16, 4);
		painter:Restore();

		-- draw player and map pos text
		painter:SetPen("#cccccc");
		painter:SetFont("System;14;norm");
		painter:DrawText(5,5, format("center:%d, %d  player:%d %d", self.CenterX, self.CenterY, playerX, playerY))
	end
end

function MinimapSurface:ScheduleNextPaint()
	if(self.block_count) then
		if(self.last_x > self.block_count) then
			LOG.std(nil, "debug", "MinimapSurface", "refreshed finished");
			self:ResetDrawProgress();
		else
			self:repaint();
		end
	end
end

-- virtual: 
function MinimapSurface:mousePressEvent(mouse_event)
	if(mouse_event:button() == "right" or mouse_event:button() == "left") then
		mouse_event:accept();
	end
end

-- virtual: 
function MinimapSurface:mouseReleaseEvent(mouse_event)
	if(mouse_event:button() == "right" or mouse_event:button() == "left") then
		mouse_event:accept();
		-- click to close 
		local window = self:GetWindow();
		if(window) then
			window:hide();
		end
	end
end

-- virtual: 
function MinimapSurface:mouseWheelEvent(mouse_event)
	local radius = self:GetMapRadius() - 0.1*mouse_event:GetDelta()*self:GetMapRadius();
	self:SetMapRadius(math.floor(radius));
end