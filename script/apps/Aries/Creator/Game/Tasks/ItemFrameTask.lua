--[[
Title: ItemFrame Task
Author(s): LiXizhi
Date: 2025/10/13
Desc: A scene context task that redirects all mouse and keyboard events to the ItemItemFrame item class.
This task is created automatically when ItemItemFrame tool is selected in the inventory.
It provides scene interaction capabilities for the item frame tool by delegating all input events.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ItemFrameTask.lua");
local task = MyCompany.Aries.Game.Tasks.ItemFrameTask:new()
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Task.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemItemFrame.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemItemFrame = commonlib.gettable("MyCompany.Aries.Game.Items.ItemItemFrame");

local ItemFrameTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ItemFrameTask"));

-- this is not a top level task, it runs as a subtask of the tool
ItemFrameTask.is_top_level = false;

local cur_instance;

function ItemFrameTask:ctor()
end

-- Called when task is executed
function ItemFrameTask:Run()
	self:LoadSceneContext();
    cur_instance = self;
end

-- Called when task is finished/exited
function ItemFrameTask:OnExit()
	self:SetFinished();
    self:UnloadSceneContext();
	cur_instance = nil;
end

-- Override to prevent auto-finishing
function ItemFrameTask:FrameMove()
	-- Don't call SetFinished() - keep the task running
end

-- Redirect all mouse press events to ItemItemFrame
function ItemFrameTask:mousePressEvent(event)
	if(event:isAccepted()) then
		return
	end
	
	local item = self:GetItem();
	if(item and item.mousePressEvent) then
		item:mousePressEvent(event);
	end
end

-- Redirect all mouse release events to ItemItemFrame
function ItemFrameTask:mouseReleaseEvent(event)
    if(event:isAccepted()) then
		return
	end
    local item = self:GetItem();
	if(item and item.mouseReleaseEvent) then
		item:mouseReleaseEvent(event);
	end
    if(event:isAccepted()) then
		return
	end
	
    local context = self:GetSceneContext();
    context.is_click = event:isClick()
    
    if(context.is_click) then
        local result = context:CheckMousePick();
        local item = self:GetItem();
        if(event.mouse_button == "left") then
            if(item and item.handleLeftClickScene) then
                item:handleLeftClickScene(event, result);
            end
        elseif(event.mouse_button == "right") then
            if(item and item.handleRightClickScene) then
                item:handleRightClickScene(event, result);
            end
        elseif(event.mouse_button == "middle") then
            if(item and item.handleMiddleClickScene) then
                item:handleMiddleClickScene(event, result);
            end
        end
	end
end

-- Redirect all mouse move events to ItemItemFrame
function ItemFrameTask:mouseMoveEvent(event)
	if(event:isAccepted()) then
		return
	end
	
	local item = self:GetItem();
	if(item and item.mouseMoveEvent) then
		item:mouseMoveEvent(event);
	end
end

-- Redirect all mouse wheel events to ItemItemFrame
function ItemFrameTask:mouseWheelEvent(event)
	if(event:isAccepted()) then
		return
	end
	
	local item = self:GetItem();
	if(item and item.mouseWheelEvent) then
		item:mouseWheelEvent(event);
	end
end

-- Redirect all key press events to ItemItemFrame
function ItemFrameTask:keyPressEvent(event)
	if(event:isAccepted()) then
		return
	end
	
	local item = self:GetItem();
	if(item and item.keyPressEvent) then
		item:keyPressEvent(event);
	end
end


-- Get current active instance
function ItemFrameTask.GetInstance()
	return cur_instance;
end

-- Get the item stack for the item frame tool
function ItemFrameTask:GetItemStack()
	return self.itemStack;
end

-- Set the item stack for the item frame tool
function ItemFrameTask:SetItemStack(itemStack)
	self.itemStack = itemStack;
end

-- Get the ItemItemFrame item instance
function ItemFrameTask:GetItem()
	return self.itemStack and self.itemStack:GetItem();
end
