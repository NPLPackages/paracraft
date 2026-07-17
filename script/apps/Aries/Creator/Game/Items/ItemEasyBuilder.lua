--[[
Title: ItemEasyBuilder
Author(s): LiXizhi
Date: 2025/09/20
Desc: A collection of easy-to-use building tools for users to quickly build and modify the world.
Use the following commands or select from the block list menu

- Teleport Tool: /take EasyBuilder -replace -pin -bag 1 {toolname="map"}
- Live Model Tool: /take EasyBuilder -replace -pin -bag 4 {toolname="livemodel"}
- Model Tool: /take EasyBuilder -replace -pin -bag 5 {toolname="model"}
- Character Tool: /take EasyBuilder -replace -pin -bag 6 {toolname="char"}
- Action/Emote Tool: /take EasyBuilder -replace -pin -bag 7 {toolname="action"}
- Environment Tool: /take EasyBuilder -replace -pin -bag 8 {toolname="env"}

Each tool has its own task(scene context) which are defined in separate files in Tasks/EasyBuilder/ folder

This tool is usually used with `/freezeworld -memorymode true` to avoid accidental deletion of existing blocks. 

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemEasyBuilder.lua");
local ItemEasyBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyBuilder");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
local ItemEasyBuilder = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Creator.Game.Items.ItemEasyBuilder"));

ItemEasyBuilder:Property({"selected_blockid", nil, "GetSelectedBlockId", "SetSelectedBlockId"})
ItemEasyBuilder:Property({"selected_blockdata", nil, "GetSelectedBlockData", "SetSelectedBlockData"})
-- allow running task in game mode too
ItemEasyBuilder:Property({"allowTaskInGameMode", true, auto=true})


block_types.RegisterItemClass("ItemEasyBuilder", ItemEasyBuilder);

function ItemEasyBuilder:ctor()
	self:SetOwnerDrawIcon(true);
    self:SetShowModelInHand(false);
end
-- virtual function: when selected in right hand
function ItemEasyBuilder:OnSelect(itemStack)
    GameLogic.ShowBuilder(false);
    -- GameLogic.SetStatus(L"已选中简易建造工具，可快速建造或编辑。");
    ItemEasyBuilder._super.OnSelect(self, itemStack);
end

function ItemEasyBuilder:OnDeSelect()
    GameLogic.SetStatus(nil);
    ItemEasyBuilder._super.OnDeSelect(self);
end

-- selected block id / data persisted on the current itemStack
function ItemEasyBuilder:GetSelectedBlockId(itemStack)
	itemStack = itemStack or self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("selected_blockid") or self.selected_blockid;
end
function ItemEasyBuilder:SetSelectedBlockId(selected_blockid)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("selected_blockid", selected_blockid);
end
function ItemEasyBuilder:GetSelectedBlockData()
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:GetDataField("selected_blockdata") or self.selected_blockdata;
end
function ItemEasyBuilder:SetSelectedBlockData(selected_blockdata)
	local itemStack = self:GetCurrentItemStack()
	return itemStack and itemStack:SetDataField("selected_blockdata", selected_blockdata);
end

-- when user clicks any other item in the UI while holding EasyBuilder, we treat that as block selection
function ItemEasyBuilder:HandleClickOtherItem(other_item_id)
	if(other_item_id) then
		local block_template = block_types.get(other_item_id);
		if(block_template and (block_template.solid or block_template.liquid or block_template.cubeMode)) then
			self:SetSelectedBlockId(other_item_id);
			self:SetSelectedBlockData(nil);
			GameLogic.SetStatus(L"已选择方块: "..(block_template:GetDisplayName() or tostring(other_item_id)));
			return true;
		end
	end
end

function ItemEasyBuilder:GetTooltipFromItemStack(itemStack)
	local toolname = self:GetToolname(itemStack)
    if(toolname == "map") then
        return L"传送工具";
    elseif(toolname == "char") then
        return L"换装工具";
    elseif(toolname == "action") then
        return L"动作/表情工具";
    elseif(toolname == "env") then
        return L"环境工具";
    elseif(toolname == "play") then
        return L"扮演模式";
    elseif(toolname == "livemodel") then
        return L"活动模型";
    elseif(toolname == "bag") then
        return L"我的背包";
    elseif(toolname == "EasyPetCopilot") then
        return L"抱抱龙AI助手";
    else
        return L"简易建造工具";
    end
end

-- @return toolname: "model", "map", "char", "action", "env", "livemodel"
function ItemEasyBuilder:GetToolname(itemStack)
	return itemStack and itemStack:GetDataField("toolname") or "model";
end

function ItemEasyBuilder:GetIconColorAndImage(itemStack)
    local toolname = self:GetToolname(itemStack)
    if(toolname == "map") then
        return "#F5C119", "Texture/3DMapSystem/Creator/Objects/Anchor.png";
    elseif(toolname == "char") then
        return "#EA515E", "Texture/3DMapSystem/Creator/Objects/Finalize.png";
    elseif(toolname == "action") then
        return "#7AC65A", "Texture/3DMapSystem/common/action.png";
    elseif(toolname == "env") then
        return "#46D0C4", "Texture/3DMapSystem/Creator/Objects/Environment.png"; 
    elseif(toolname == "play") then
        return "#9C27B0", "Texture/3DMapSystem/Creator/Objects/speed.png";
    elseif(toolname == "livemodel") then
        return "#FF6B35", "Texture/3DMapSystem/Creator/Objects/Collection.png";
    elseif(toolname == "bag") then
        return "#da5ddfff", "Texture/3DMapSystem/AppIcons/Inventory_64.dds";
    elseif(toolname == "EasyPetCopilot") then
        return "#FF9800", "Texture/Aries/Item/10001_DragonIcon.png";
    else -- model
        return "#4A74C9", "Texture/3DMapSystem/Creator/Objects/Object_Add.png";
    end
end

local toolDisplayNames;
function ItemEasyBuilder:GetToolDisplayName(name)
    if not toolDisplayNames then
        toolDisplayNames = {
            map = L"传送",
            char = L"换装",
            action = L"动作",
            env = L"环境",
            play = L"扮演",
            model = L"建造",
            livemodel = L"角色",
            bag = L"背包",
            EasyPetCopilot = L"",
        }
    end
    return toolDisplayNames[name] or L"建造";
end

function ItemEasyBuilder:DrawIcon(painter, width, height, itemStack)
    local toolname = self:GetToolname(itemStack)
    local color, image_filename = self:GetIconColorAndImage(itemStack)
    painter:SetPen(color);
    painter:DrawRect(0, 0, width, height);
    -- overlay hint text at bottom left
    painter:SetPen("#ffffff");

    local toolDisplayName = self:GetToolDisplayName(toolname) or "";

    -- Draw square icon above text, center aligned
    local text_size = width > 50 and 16 or 12;
    if( image_filename) then
        local icon_size = toolDisplayName ~= "" and (height - text_size - 3) or height;
        painter:DrawRectTexture((width - icon_size) / 2, 0, icon_size, icon_size, image_filename);
    end
    if(text_size > 14) then
        painter:SetFont("System;16;bold");
    else
        painter:SetFont("System;12;bold");
    end
    
    if(toolDisplayName ~= "") then
        painter:SetPen("#000000");
        painter:DrawText(1, height - text_size - 3, width, text_size, toolDisplayName, 0x121);
        painter:SetPen("#ffffff");
        painter:DrawText(0, height - text_size - 4, width, text_size, toolDisplayName, 0x121); -- single line and horizontally centered and no-clip
    end
end

-- virtual: create the task when this item is selected
function ItemEasyBuilder:CreateTask(itemStack)
    local toolname = self:GetToolname(itemStack)
    if(toolname == "map") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyMap.lua");
        local EasyMap = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyMap");
        if(EasyMap.new) then
            local task = EasyMap:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    elseif(toolname == "char") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyChar.lua");
        local EasyChar = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyChar");
        if(EasyChar.new) then
            local task = EasyChar:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    elseif(toolname == "action") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAction.lua");
        local EasyAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAction");
        if(EasyAction.new) then
            local task = EasyAction:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    elseif(toolname == "env") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEnv.lua");
        local EasyEnv = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEnv");
        if(EasyEnv.new) then
            local task = EasyEnv:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    elseif(toolname == "play" or toolname == "bag") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.lua");
        local EasyPlay = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay");
        if(EasyPlay.new) then
            local task = EasyPlay:new();
            task.isFromItemEasyBuilder = true;

            if(toolname == "bag") then
                task.bIgnoreShowPage = true;
                local MiniGameUserBag = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserBag.lua");
                MiniGameUserBag.ShowPage();
            end
            return task;
        end
    elseif(toolname == "livemodel") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyLiveModel.lua");
        local EasyLiveModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyLiveModel");
        if(EasyLiveModel.new) then
            local task = EasyLiveModel:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    elseif(toolname == "EasyPetCopilot") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
        local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
        local copilot = CopilotDragonPet.GetInstance()
        copilot:ComeHere();
        return nil;
    else -- if(toolname == "model") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModel.lua");
        local EasyModel = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyModel");
        if(EasyModel.new) then
            local task = EasyModel:new();
            task.isFromItemEasyBuilder = true;
            return task;
        end
    end
end

function ItemEasyBuilder:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	return false
end

function ItemEasyBuilder:keyPressEvent(event)
    local dik_key = event.keyname;
    local task = self:GetTask();
    if(task and task:GetSceneContext() ~= GameLogic.GetSceneContext()) then
        return;
    end
    if(dik_key == "DIK_P")then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.lua");
        local EasyPlay = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay");
        EasyPlay.OnClickPossession()
        event:accept();
    elseif(dik_key == "DIK_R")then
        -- disable R key for resource view
        event:accept();
    elseif(dik_key == "DIK_F5")then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyPlay.lua");
        local EasyPlay = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyPlay");
        EasyPlay.OnClickView()
        event:accept();
    end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
-- by default, if there is selected blocks, we will replace selection with current block in hand. 
function ItemEasyBuilder:OnClickInHand(itemStack, entityPlayer)
	self:ReloadTask(itemStack);
end