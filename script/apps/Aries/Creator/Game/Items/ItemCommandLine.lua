--[[
Title: ItemCommandLine
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCommandLine.lua");
local ItemCommandLine = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCommandLine");
local item_ = ItemCommandLine:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local ItemCommandLine = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCommandLine"));

block_types.RegisterItemClass("ItemCommandLine", ItemCommandLine);


function ItemCommandLine:ctor()
end

function ItemCommandLine:GetMaxCount()
	return 64;
end

function ItemCommandLine:GetTooltipFromItemStack(itemStack)
	local tooltip = self:GetTooltip();
	if(tooltip) then
		local data = itemStack:GetData();
		if(type(data) == "string") then
			data = data:gsub("#", "\n");
			tooltip = tooltip.."\n"..data;
		end
	end
	return tooltip;
end

-- return a table array containing all commands or comments. 
function ItemCommandLine:GetCommandTable(itemStack)
	local out;
	local text = itemStack:GetData();
	if(type(text) == "string") then
		for cmd in string.gmatch(text, "([^#]+)") do
			out = out or {};
			out[#out + 1] = cmd;
		end
	end
	return out;
end

-- set command table
function ItemCommandLine:SetCommandTable(itemStack, commands)
	if(type(commands) == "table") then
		itemStack:SetData(table.concat(commands, "#"));
	else
		itemStack:SetData(nil);
	end
end

-- get latest command list. comments is empty line.
-- it will cache last parsed result
function ItemCommandLine:GetCommandListFromStack(itemStack)
	local text = itemStack:GetData();
	if(type(text) == "string") then
		if(not itemStack.cmd_list or itemStack.cmd_list.src ~= text) then
			itemStack.cmd_list = CommandManager:GetCmdList(text, "([%-]*)%s*(/?[^#]+)");
			itemStack.cmd_list.src = itemStack.text;
			return itemStack.cmd_list;
		else
			return itemStack.cmd_list;
		end
	end
end

-- called when this function is activated when the entity is activated. 
-- @param entity: this is usually a command block or entity. 
-- @return true if the entity should stop activating other items in its bag. 
function ItemCommandLine:OnActivate(itemStack, entityContainer, entityPlayer)
	local cmd_list = self:GetCommandListFromStack(itemStack);
	
	if(cmd_list) then
		local variables = (entityPlayer or EntityManager.GetPlayer()):GetVariables();
		return CommandManager:RunCmdList(cmd_list, variables, entityContainer);
	end
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemCommandLine:OnItemRightClick(itemStack, entityPlayer)
	if(Keyboard.IsCtrlKeyPressed() or GameLogic.GameMode:CanDirectClickToActivateItem()) then
		-- in game mode, right click will trigger the command, in editor mode, Ctrl+right click will trigger. 
		self:OnActivate(itemStack, entityPlayer);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditCommandPage.lua");
		local EditCommandPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCommandPage");
		EditCommandPage.ShowPage(itemStack, function()
			if(entityPlayer and entityPlayer.inventory) then
				entityPlayer.inventory:OnInventoryChanged();
			end
		end);
	end
    return itemStack, true;
end

-- called when entity receives a custom event via one of its rule bag items. 
function ItemCommandLine:handleEntityEvent(itemStack, entity, event)
	local cmd_list = self:GetCommandListFromStack(itemStack);
	return CommandManager:CallFunction(cmd_list, event:GetHandlerFuncName(), nil, entity);
end
