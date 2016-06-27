--[[
Title: ItemTool
Author(s): LiXizhi
Date: 2014/1/20
Desc: This class demonstrate a crafting tool.
The default implementation will delete blocks when left button is pressed, according to block's hardness, and the tool's attack points. 
A health bar is also displayed per blocks. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTool.lua");
local ItemTool = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTool");
local item = ItemTool:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local Mouse = commonlib.gettable("System.Windows.Mouse");

local ItemTool = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTool"));

block_types.RegisterItemClass("ItemTool", ItemTool);

local default_inhand_offset = {0.15, 0.3, 0}

-- damage factor of this tool that is applied to blocks
-- a value of 2 means, it takes about 10/2*1 hits to destory a block with hardness 1
ItemTool:Property({"AttackValue", 2, auto=true});

-- Attack rate, how many attacks per seconds. 
ItemTool:Property({"AttackRate", 3.5, auto=true});

-- how many blocks from the current player that we can destroy blocks
ItemTool:Property({"attackDistance", 4, });

-- whether to force drop item regardless of game mode
ItemTool:Property({"ForceDropItem", true, });


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTool:ctor()
	-- number of ticks user is press holding mouse button. 
	self.hold_button_ticks = 0;
	self.mouse_timer = commonlib.Timer:new({callbackFunc = function(timer)
			self:OnMouseTimerEvent(timer);
		end})
end

-- item offset when hold in hand. 
-- @return nil or {x,y,z}
function ItemTool:GetItemModelInHandOffset()
	return self.inhandOffset or default_inhand_offset;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemTool:OnItemRightClick(itemStack, entityPlayer)
    return itemStack, true;
end

-- virtual function: when deselected in right hand
function ItemTool:OnDeSelect()
	ParaTerrain.SetDamagedDegree(0);
end

-- called when mouse is pressing with this tool selected. 
function ItemTool:OnMouseTimerEvent(timer)
	if(GameLogic.GetBlockInRightHand() == self.block_id and (Mouse:LeftButton())) then
		-- continue timer if mouse is still pressing
		-- TODO: naive attack rate using timer, only for client world
		local minInterval = math.floor(1000 / self:GetAttackRate() + 1);
		timer:Change(minInterval, nil);


		self.hold_button_ticks = self.hold_button_ticks + 1;
		self:DestoryBlockPartially();
	end
end

-- compute a relative damage using current player entity's attack * ToolAttack * BlockHardness
function ItemTool:GetRelativeDamageToBlock(block_template, entityPlayer)
	local hardness =  block_template:getBlockHardness();
	if(hardness < 0) then
		-- unbreakable
		return 0;
	else
		-- TODO: shall we take the player entity's armor into consideration?
		return self:GetAttackValue() / block_template:getBlockHardness();	
	end
end

-- how many block distance from the current player that we can destroy blocks
function ItemTool:GetAttackDistance()
	return self.attackDistance;
end

-- @param playerEntity: default to current player
function ItemTool:DestoryBlockPartially(playerEntity)
	playerEntity = playerEntity or EntityManager.GetPlayer();
	local result = SelectionManager:MousePickBlock(true, false, true);
	local block_template = result:GetBlock();
	if(playerEntity and block_template and result:GetBlockDistanceToPlayer() <= self:GetAttackDistance()) then
		local x, y, z = result:GetBlockPos();
		local damage = self:GetRelativeDamageToBlock(block_template, playerEntity);
		if(damage > 0) then
			local last_damage = GameLogic.GetSim():GetBlockDamagedProgress(x, y, z);
			local total_damage = last_damage + damage;
			if(total_damage >= 10) then
				local blocks_modified = block_template:Remove(x,y,z);
				if(blocks_modified) then
					block_template:OnUserBreakItem(x,y,z, playerEntity);
					-- TODO: retrieve block_data, etc. 
					block_template:DropBlockAsItem(x,y,z, self.ForceDropItem);
				end
				if(last_damage > 0) then
					GameLogic.GetWorld():DestroyBlockPartially(playerEntity.entityId, x, y, z, -1);	
				end
			else
				-- GameLogic.AddBBS(nil, "current block damage: "..total_damage);
				-- echo({"block damage", x, y, z, total_damage})
				GameLogic.GetWorld():DestroyBlockPartially(playerEntity.entityId, x, y, z, total_damage);	
			end
		end
	end
end

function ItemTool:mousePressEvent(event)
	-- eat all events
	event:accept();

	-- only for left button
	if(event:LeftButton()) then
		self.hold_button_ticks = 0;
		if(not self.mouse_timer:IsEnabled()) then
			self.mouse_timer:Change(50, nil);
		end
	end
end

function ItemTool:mouseMoveEvent(event)
	event:accept();
end

function ItemTool:mouseReleaseEvent(event)
	event:accept();
end