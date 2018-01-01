--[[
Title: Vision Context
Author(s): LiXizhi
Date: 2017/6/3
Desc: 
The vision context contains: blocks(including physical blocks) and NPC entities.
Each object in the vision context has an attention value, the more memory matches the more attention object gets.
But attention value of objects also decays fast and only last a few frames if no matched. 
Each object is also linked with matching memory clips. 

The following things will affect block attention in decreasing order:
- the player position and facing: block faces and edges close to the player viewpoint has greater attention.
- Eye attention: any activated movie clip that has recently applied to the vision context get the eye attention. Eye attention will usually last 1 or 2 seconds
- Block pattern recognition: block patterns that has more valid matches to memory movie clips get higher attention. 
- Entity pattern: Some block with bmax, or scene entities may have more attentions that others in the vision context. 
- Blocks near the mouse cursor usually have more attention, but it is not menditoray. 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/VisionContext.lua");
local VisionContext = commonlib.gettable("MyCompany.Aries.Game.Memory.VisionContext");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/AttentionBlock.lua");
local AttentionBlock = commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBlock");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local VisionContext = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.VisionContext"));
VisionContext:Property("Name", "VisionContext");
-- default view distance is 10 blocks
VisionContext:Property({"ViewDist", 10, auto=true});
-- value to decrease attention when the object is out of view distance. 
VisionContext:Property({"InvisibleDecay", 10});
-- object decay
VisionContext:Property({"NaturalDecay", 2});
-- color to use to draw attention
VisionContext:Property({"color", "#0000ff"});
-- whether to debug draw
VisionContext:Property({"visible", false, "IsVisible", "SetVisible"});

function VisionContext:ctor()
	self.frameCount = 0;
	-- attentioned objects 
	self.attention_blocks = {};
	self.attention_entites = {};

	NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PatternGenBlocks.lua");
	local PatternGenBlocks = commonlib.gettable("MyCompany.Aries.Game.Memory.PatternGenBlocks");
	self.pattern_genBlocks = PatternGenBlocks:new();
end

-- this should be called every frame to decay attention values. 
-- @param playerContext: update from a player Context ( this is actually only used to read player position). If nil, we will use current player's block position.
function VisionContext:Update(playerContext)
	self.frameCount = self.frameCount + 1;
	
	playerContext = playerContext or EntityManager.GetPlayer();
	local eye_x, eye_y, eye_z = playerContext:GetBlockPos();
	local facing = playerContext:GetFacing();
	local lookat_dir = Direction.GetDirectionFromFacing(facing);
	local viewDist = self:GetViewDist();

	if(self:IsVisible()) then
		-- update render origin of overlay if it is visible.
		self:SetRenderOrigin(eye_x, eye_y, eye_z);
		local x, y, z = BlockEngine:real(eye_x, eye_y, eye_z)
		self.overlay:SetPosition(x, y, z);
	end

	-- update the attention weight by eye position. 
	self:DecreaseOutOfViewPower(eye_x, eye_y, eye_z, viewDist)
	self:AddPowerToVisibleObject(eye_x, eye_y, eye_z, lookat_dir, viewDist)
	self:CleanUnusedAttentionBlocks();

	self.pattern_genBlocks:Generate(self.attention_blocks, eye_x, eye_y, eye_z, lookat_dir, viewDist-2);
end

function VisionContext:DecreaseOutOfViewPower(eye_x, eye_y, eye_z, viewDist)
	for index, obj in pairs(self.attention_blocks) do
		
		if(obj:DistanceTo(eye_x, eye_y, eye_z) > viewDist) then
			obj:AddPower(-self.InvisibleDecay);
		else
			obj:AddPower(-self.NaturalDecay);
		end
	end
end

-- get the attention block
function VisionContext:CreateGetAttentionBlock(x,y,z)
	local index = BlockEngine:GetSparseIndex(x,y,z)
	local attentionBlock = self.attention_blocks[index];
	if(not attentionBlock) then
		attentionBlock = AttentionBlock:new():init(x,y,z);
		self.attention_blocks[index] = attentionBlock;
	end
	return attentionBlock;
end

function VisionContext:AddPowerToVisibleObject(eye_x, eye_y, eye_z, lookat_dir, viewDist)
	local radius = 3;
	for dx = -radius, radius do
		for dz = -radius, radius do
			local x = eye_x + dx
			local z = eye_z + dz
			local block_id, y = BlockEngine:GetNextBlockOfTypeInColumn(x,eye_y,z, 0xffffff, radius)
			if(block_id) then
				local attentionBlock = self:CreateGetAttentionBlock(x,y,z);
				if(attentionBlock) then
					attentionBlock:Activate();
				end
			end
		end
	end
end

-- remove unused attentions if any
function VisionContext:CleanUnusedAttentionBlocks()
	local removed;
	for index, obj in pairs(self.attention_blocks) do
		if(not obj:HasAttention()) then
			removed = removed or {};
			removed[#removed+1] = index;
		end
	end
	if(removed) then
		for _, index in ipairs(removed) do
			self.attention_blocks[index] = nil;
		end
	end
end

-- show/hide debug draw
function VisionContext:SetVisible(bVisible)
	if(bVisible and not self.overlay) then
		NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
		local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
		self.overlay = Overlay:new():init();
		
		self.overlay.paintEvent = function(overlay, painter)
			self:Draw(painter);
		end

	elseif(not bVisible and self.overlay) then
		self.overlay:Destroy()
		self.overlay = nil;
	end
end

-- show/hide debug draw
function VisionContext:IsVisible()
	return self.overlay ~= nil;
end


function VisionContext:WorldToLocalBlockPos()
	
end

-- in block coordinate
function VisionContext:SetRenderOrigin(bx, by, bz)
	self.renderOriginX, self.renderOriginY, self.renderOriginZ = bx, by, bz;
end

-- in block coordinate
function VisionContext:GetRenderOrigin()
	return self.renderOriginX, self.renderOriginY, self.renderOriginZ;
end

-- draw vision mostly for debugging purposes
function VisionContext:Draw(painter)
	
	painter:SetBrush(self.color);
	for index, obj in pairs(self.attention_blocks) do
		if(obj:HasAttention()) then
			obj:Draw(painter, self);
		end
	end
end