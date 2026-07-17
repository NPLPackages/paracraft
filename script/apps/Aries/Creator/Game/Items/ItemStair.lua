--[[
Title: ItemStair
Author(s): LiXizhi
Date: 2024/2/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStair.lua");
local ItemStair = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStair");
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

local ItemStair = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemStair"));

block_types.RegisterItemClass("ItemStair", ItemStair);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemStair:ctor()
end

function ItemStair:OnSelect(itemStack)
	ItemStair._super.OnSelect(self, itemStack);
	GameLogic.SetStatus(L"Alt+右键改变形状");
end
function ItemStair:OnDeSelect()
	ItemStair._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end

function ItemStair:mouseReleaseEvent(event)
	if(event:isAccepted()) then
		return
	end
	if(event:button() == "right" and GameLogic.GameMode:IsEditor()) then
		if(event.alt_pressed and not event.shift_pressed and not event.ctrl_pressed) then
			-- alt + right click to change its shape
			event:accept();
			local result = Game.SelectionManager:MousePickBlock(true, false, false);
			if(result.blockX) then
				local x,y,z = result.blockX,result.blockY,result.blockZ;
				local block_template = BlockEngine:GetBlock(x,y,z);
				if(block_template and block_template.shape == "stairs") then
					self:SwitchStairShape(x,y,z)
					event:accept();
				end
			end
		end
	end
end

local shapeSwitchTable;
function ItemStair:GetShapeSwitchTable()
	if(not shapeSwitchTable) then
		shapeSwitchTable = {
			[21] = 25, [25] = 27, [27] = 21, 
			[20] = 24, [24] = 26, [26] = 20, 
			[19] = 23, [23] = 29, [29] = 19,
			[18] = 22, [22] = 28, [28] = 18, 
			[3] = 11, [1] = 12, [2] = 10, [4] = 12,
			[11] = 3, [12] = 1, [10] = 2, [13] = 4,
		}
	end
	return shapeSwitchTable;
end

function ItemStair:SwitchStairShape(x,y,z)
	local block_template = BlockEngine:GetBlock(x,y,z);
	if(block_template and block_template.shape == "stairs") then
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