--[[
Title: Viewport manager
Author(s): LiXizhi
Date: 2014/8/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Viewport.lua");
local Viewport = commonlib.gettable("MyCompany.Aries.Game.Common.Viewport")
Viewport.Get():SetPosition("_fi", 100, 100, 100, 100);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
local math3d = commonlib.gettable("mathlib.math3d");

local viewports = {};

local Viewport = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.Viewport"))

function Viewport:ctor()
	self.nIndex = self.nIndex or 1;
end

-- static function: Get viewport by index
-- @param nIndex: default to 1.
function Viewport.Get(nIndex)
	nIndex = nIndex or 1;
	local viewport = viewports[nIndex];
	if(not viewport) then
		viewport = Viewport:new():Init(nIndex);
		viewports[nIndex] = viewport;
	end
	return viewport;
end

function Viewport:Init(nIndex)
	self.nIndex = nIndex;
	return self;
end

function Viewport:SetPosition(alignment, left, top, width, height)
	local viewport = ParaEngine.GetViewportAttributeObject(self.nIndex);
	viewport:SetField("alignment", alignment);
	viewport:SetField("left", left);
	viewport:SetField("top", top);
	viewport:SetField("width", width);
	viewport:SetField("height", height);
end

function Viewport:Apply()
	local viewport = ParaEngine.GetViewportAttributeObject(self.nIndex);
	viewport:CallField("ApplyViewport");
end

