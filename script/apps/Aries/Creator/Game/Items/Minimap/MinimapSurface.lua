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
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local MinimapSurface = commonlib.inherit(ParaWorldMinimapSurface, commonlib.gettable("Paracraft.Controls.MinimapSurface"));

MinimapSurface:Signal("mapChanged");

-- mapping from block_id to block color like "#ff0000"
local color_table = nil;

function MinimapSurface:ctor()
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