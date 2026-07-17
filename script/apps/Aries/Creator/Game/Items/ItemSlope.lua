--[[
Title: ItemSlope
Author(s): LiXizhi
Date: 2024/2/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSlope.lua");
local ItemSlope = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlope");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local ItemSlope = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemSlope"));

block_types.RegisterItemClass("ItemSlope", ItemSlope);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemSlope:ctor()
end

function ItemSlope:OnSelect(itemStack)
	ItemSlope._super.OnSelect(self, itemStack);
	GameLogic.SetStatus(L"Shift+Alt+鼠标右键自动填充边界. Alt+右键改变形状");
end
function ItemSlope:OnDeSelect()
	ItemSlope._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end

function ItemSlope:mousePressEvent(event)
	ItemSlope._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function ItemSlope:mouseReleaseEvent(event)
	if(event:isAccepted()) then
		return
	end
	if(event:button() == "right" and GameLogic.GameMode:IsEditor() and  not event.ctrl_pressed) then
		if(event.shift_pressed and event.alt_pressed) then
			-- shift + alt + right click to add slope to smooth the clicked surface between solid cube blocks. 
			local result = Game.SelectionManager:MousePickBlock(true, false, false);
			if(result.blockX) then
				local x,y,z = result.blockX,result.blockY,result.blockZ;
				local block_template = BlockEngine:GetBlock(x,y,z);
				if(block_template) then
					if(block_template.solid) then
						self:SmoothSurface(x,y,z, result.side, 20)
						event:accept();
					elseif(block_template.shape == "slope") then
						-- allow replacement of slope colors
					else
						event:accept();
					end
				end
			end
			
		elseif(event.alt_pressed) then
			-- alt + right click to change its shape
			event:accept();
			local result = Game.SelectionManager:MousePickBlock(true, false, false);
			if(result.blockX) then
				local x,y,z = result.blockX,result.blockY,result.blockZ;
				local block_template = BlockEngine:GetBlock(x,y,z);
				if(block_template and block_template.shape == "slope") then
					self:SwitchSlopeShape(x,y,z)
					event:accept();
				end
			end
		end
	end
	ItemSlope._super.mouseReleaseEvent(self, event);
end

local shapeSwitchTable;
function ItemSlope:GetShapeSwitchTable()
	if(not shapeSwitchTable) then
		shapeSwitchTable = {
			-- two different corners
			[100] = 127, [127] = 100,
			[101] = 124, [124] = 101,
			[102] = 125, [125] = 102,
			[103] = 126, [126] = 103,
			[104] = 131, [131] = 104,
			[105] = 130, [130] = 105,
			[106] = 129, [129] = 106,
			[107] = 128, [128] = 107,
			-- two different corners on ground
			[32] = 16, [16] = 32,
			[33] = 17, [17] = 33,
			[34] = 18, [18] = 34,
			[35] = 19, [19] = 35,
			[36] = 20, [20] = 36,
			[37] = 21, [21] = 37,
			[38] = 22, [22] = 38,
			[39] = 23, [23] = 39,
			-- swap up and down shape
			[5] = 6, [6] = 5, [29] = 5,
			[1] = 2, [2] = 1,
			[0] = 3, [3] = 0,
			[7] = 4, [4] = 7, [28] = 4,
		}
	end
	return shapeSwitchTable;
end

function ItemSlope:SwitchSlopeShape(x,y,z)
	local block_template = BlockEngine:GetBlock(x,y,z);
	if(block_template and block_template.shape == "slope") then
		local data = BlockEngine:GetBlockData(x, y, z);
		local shapes = self:GetShapeSwitchTable()
		
		local data2 = shapes[band(data, 0xff)]
		if(data2) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = x,blockY = y, blockZ = z, 
				to_id = self.id, to_data=bor(data2, band(data, 0xffffff00)), max_radius = 0, preserveRotation=false})
			task:Run();
		end
	end
end

-- if there are solid cube blocks on the surface of side. we will smooth the surface by placing slope besides the cube block.
function ItemSlope:SmoothSurface(x,y,z, side, radius)
	local blockMap = {}
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlope.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
	local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
	local blockSlope = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlope")

	local function addBlock(x,y,z)
		blockMap[BlockEngine:GetSparseIndex(x,y,z)] = true;
	end
	local dx, dy, dz = Direction.GetOffsetBySide(side)
	local smoothBlock;
	smoothBlock = function(x, y, z, side, radius)
		if(blockMap[BlockEngine:GetSparseIndex(x,y,z)] or radius == 0) then
			return
		end
		local block_template = BlockEngine:GetBlock(x,y,z);
		
		if(block_template and block_template.solid) then
			if(BlockEngine:GetBlockId(x + dx, y + dy, z + dz) == 0) then
				if(dy == 1 or dy == -1) then
					local hasBlock;
					for dx = -1, 1 do
						for dz = -1, 1 do
							if(BlockEngine:isBlockNormalCube(x + dx, y + dy, z + dz)) then
								hasBlock = true;
								break;
							end
						end
						if(hasBlock) then
							break;
						end
					end
					if(hasBlock) then
						addBlock(x,y,z)
						smoothBlock(x, y, z-1, side, radius - 1);
						smoothBlock(x, y, z+1, side, radius - 1);
						smoothBlock(x-1, y, z, side, radius - 1);
						smoothBlock(x+1, y, z, side, radius - 1);
					end
				end
				if(dx == 1 or dx == -1) then
					local hasBlock;
					for dy = -1, 1 do
						for dz = -1, 1 do
							if(BlockEngine:isBlockNormalCube(x + dx, y + dy, z + dz)) then
								hasBlock = true;
								break;
							end
						end
						if(hasBlock) then
							break;
						end
					end
					if(hasBlock) then
						addBlock(x,y,z)
						smoothBlock(x, y-1, z, side, radius - 1);
						smoothBlock(x, y+1, z, side, radius - 1);
						smoothBlock(x, y, z-1, side, radius - 1);
						smoothBlock(x, y, z+1, side, radius - 1);
					end
				end
				if(dz == 1 or dz == -1) then
					local hasBlock;
					for dx = -1, 1 do
						for dy = -1, 1 do
							if(BlockEngine:isBlockNormalCube(x + dx, y + dy, z + dz)) then
								hasBlock = true;
								break;
							end
						end
						if(hasBlock) then
							break;
						end
					end
					if(hasBlock) then
						addBlock(x,y,z)
						smoothBlock(x-1, y, z, side, radius - 1);
						smoothBlock(x+1, y, z, side, radius - 1);
						smoothBlock(x, y-1, z, side, radius - 1);
						smoothBlock(x, y+1, z, side, radius - 1);
					end
				end
			end
		end
	end
	radius = radius or 20
	if(side) then
		smoothBlock(x, y, z, side, radius);
	else
		for side = 0, 5 do
			smoothBlock(x, y, z, side, radius);
		end
	end

	local blocks = {}
	local blockId = self.id;
	local color = self:HasColorData() and self:ColorToData(self:GetPenColor()) or 0;

	for index, _ in pairs(blockMap) do
		local x, y, z = BlockEngine:FromSparseIndex(index);
		x, y, z = x + dx, y + dy, z + dz
		local data = blockSlope:GetBlockDataFromNeighbour(x, y, z)
		if(data) then
			blocks[#blocks+1] = {x,y,z, blockId, bor(color, data)}
		end
	end
	
	if(#blocks > 0) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blocks = blocks,})
		task:Run();
	end
end
