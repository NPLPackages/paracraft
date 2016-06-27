--[[
Title: RuleBlock
Author(s): LiXizhi
Date: 2014/1/27
Desc: 
---++ example
<verbatim>
	/addrule Block CanPlace Lever Glowstone,62
	this:AddRule("Block", "CanPlace Lever Glowstone,62");

	/addrule Block CanDestroy Lever 1
	this:AddRule("Block", "CanDestroy Lever true");
</verbatim>
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleBlock.lua");
local RuleBlock = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local RuleBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"), commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBlock"));

function RuleBlock:ctor()
end


function RuleBlock:Init(rule_name, rule_params)
	local name, value = rule_name:match("^(%w+)%s+(.*)$");
	if(not name) then	
		return
	elseif(name == "CanPlace") then
		local from_block, to_block = value:match("^(%S+)%s+(.*)$");
		if(from_block and to_block) then
			if(self:SetCanPlace(from_block, to_block)) then
				return self;
			end
		end
	elseif(name == "CanDestroy") then
		local from_block, canDestroy = value:match("(%S+)%s+(%S+)");
		if(from_block and canDestroy) then
			canDestroy = canDestroy == "true" or canDestroy == "1" or canDestroy == "";
			if(self:SetCanDestroy(from_block, canDestroy)) then
				return self;
			end
		end
	end
end

-- set the current block rule as can place. 
-- we will only allow placing from_block on to to_block. 
function RuleBlock:SetCanPlace(from_block, to_block)
	self.type = "CanPlace";
	self.from_block = block_types.GetByNameOrID(from_block);
	local list = CmdParser.ParseStringList(to_block);
	if(list) then
		for i = 1, #(list) do
			local to_block = block_types.GetByNameOrID(list[i]);
			if(to_block) then
				self.to_blocks = self.to_blocks or {};
				self.to_blocks[to_block.id] = true;
			end
		end
	else
		return;
	end
	if(self.from_block and self.to_blocks) then
		self.from_block:SetRule_CanPlace(self);
		LOG.std(nil, "info", "RuleBlock", "SetCanPlace %d onto %s", self.from_block.id, commonlib.serialize_compact(self.to_blocks));
		return true;
	end
end

function RuleBlock:SetCanDestroy(from_block, canDestroy)
	self.type = "CanPlace";
	self.from_block = block_types.GetByNameOrID(from_block);
	self.canDestroy = canDestroy;
	if(self.from_block) then
		self.from_block:SetRule_CanDestroy(self);
		LOG.std(nil, "info", "RuleBlock", "CanDestroy %d %s", self.from_block.id, tostring(canDestroy));
		return true;
	end
end

-- checks to see if you can place this block can be placed on that side of a block: BlockLever overrides
function RuleBlock:canPlaceBlockOnSide(x,y,z,side)
	if(self.to_blocks and side) then
		side = BlockEngine:GetOppositeSide(side);
		local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,side);
		local side_block_id = BlockEngine:GetBlockId(x_, y_, z_);
		if(self.to_blocks[side_block_id]) then
			return true;
		end
	else
		return true;
	end
end

-- whether we can destroy block at the given position. 
function RuleBlock:CanDestroyBlockAt(x,y,z)
	return self.canDestroy;
end

function RuleBlock:OnRemove()
	local rule_type = self.type;
	if(rule_type == "CanPlace") then
		if(self.from_block) then
			self.from_block:SetRule_CanPlace(nil);
		end
	elseif(rule_type == "CanDestroy") then
		if(self.from_block) then
			self.from_block:SetRule_CanDestroy(nil);
		end
	end
end