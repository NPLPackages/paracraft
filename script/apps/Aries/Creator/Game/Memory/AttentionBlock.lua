--[[
Title: Attention Block
Author(s): LiXizhi
Date: 2017/6/3
Desc: A single block that caught our attention in the vision context. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/AttentionBlock.lua");
local AttentionBlock = commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/AttentionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternBlockEdge.lua");
local PatternBlockEdge = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternBlockEdge");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local AttentionBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBlock"));
AttentionBlock:Property("Name", "AttentionBlock");
AttentionBlock:Property({"render_size", 0.2});

function AttentionBlock:ctor()
	-- self.edges = {}
	-- self.view_direction
end

function AttentionBlock:init(bx, by, bz)
	self.bx, self.by, self.bz = bx, by, bz;
	return self;
end

-- quick longest distance to 
function AttentionBlock:DistanceTo(x, y, z)
	return math.max(self.bx-x, self.by-y, self.bz-z);
end


-- virtual function
function AttentionBlock:Draw(painter, visionContext)
	local rx, ry, rz = visionContext:GetRenderOrigin();
	local x, y, z = self.bx-rx, self.by-ry, self.bz-rz;
	painter:SetBrush(self:GetPowerColor());
	ShapesDrawer.DrawCube(painter, x * BlockEngine.blocksize, y * BlockEngine.blocksize, z * BlockEngine.blocksize, self.render_size)

	if(self.edges) then
		for _, edge in ipairs(self.edges) do
			if(edge == PatternBlockEdge.face_bottom) then
				
			end
		end
	end
end
