--[[
Title: ItemCode
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCode.lua");
local ItemCode = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCode");
local item_ = ItemCode:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCode = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCode"));

block_types.RegisterItemClass("ItemCode", ItemCode);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCode:ctor()
end

-- append file name
function ItemCode:GetTooltipFromItemStack(itemStack)
	local tooltip = self:GetTooltip();
	if(tooltip) then
		local data = itemStack:GetData();
		if(type(data) == "string") then
			tooltip = tooltip.."\n"..data;
		end
	end
	return tooltip;
end

-- not stackable
function ItemCode:GetMaxCount()
	return 64;
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemCode:OnItemRightClick(itemStack, entityPlayer)
	local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	if(ctrl_pressed or GameLogic.GameMode:CanDirectClickToActivateItem()) then
		-- in game mode, right click will trigger the command, in editor mode, Ctrl+right click will trigger. 
		self:OnActivate(itemStack, entityPlayer);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditCodePage.lua");
		local EditCodePage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCodePage");
		EditCodePage.ShowPage(itemStack);
	end
    return itemStack, true;
end

-- called when this function is activated when the entity is activated. 
-- @param entity: this is usually a command block or entity. 
-- @return true if the entity should stop activating other items in its bag. 
function ItemCode:OnActivate(itemStack, entity)
	local filename = itemStack:GetData();
	if(filename) then
		--if(entity and entity.GetBlockPos) then
			--itemStack:SetPosition(entity:GetBlockPos());
		--end
		return itemStack:ActivateScript(entity);
	end
end

-- called when entity receives a custom event via one of its rule bag items. 
function ItemCode:handleEntityEvent(itemStack, entity, event)
	local filename = itemStack:GetData();
	if(filename) then
		local func = itemStack:GetScriptFunction(event:GetHandlerFuncName());
		if(func) then
			local ok, result = pcall(func, entity, event);
			if(not ok) then
				LOG.std(nil, "error", "ItemCode:handleEntityEvent", result);
			end
			return true;
		end
	end
end
