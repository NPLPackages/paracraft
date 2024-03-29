--[[
Title: EntityHomePoint
Author(s): LiXizhi
Date: 2013/7/14
Desc: the home position. It will activate all rules, and then activate all commands and inventory items as EntityCommandBlock will do. 
use the lib:
------------------------------------------------------------
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityHomePoint.lua");
local EntityHomePoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityHomePoint")
local entity = MyCompany.Aries.Game.EntityManager.EntityHomePoint:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCollectable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaWorldNPC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldNPC.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local math_abs = math.abs;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCollectable"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityHomePoint"));


-- persistent object by default. 
Entity.is_persistent = true;
Entity.framemove_interval = 0.2;
-- class name
Entity.class_name = "EntityHomePoint";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
	self.inventory:SetParentEntity(self);

	self:SetRuleBagSize(16);
end

-- bool: whether has command panel
function Entity:HasCommand()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"世界加载时会执行的命令"
end

-- bool: whether show the rule panel
function Entity:HasRule()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle()
	return L"规则";
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
	return L"背包";
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return true;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	local generatorName = WorldCommon.GetWorldTag("world_generator");
	if (generatorName == "paraworld" and not System.options.isPapaAdventure) then
		ParaWorldNPC.LoadNPCFromHomePoint(node);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = node or {name='entity', attr={}};
	local generatorName = WorldCommon.GetWorldTag("world_generator");
	if (generatorName == "paraworld" and not System.options.isPapaAdventure) then
		local npcList = {};
		for i = 1, #ParaWorldNPC.npcList do
			npcList[i] = {name = 'npc', attr = ParaWorldNPC.npcList[i]};
		end
		node[#node+1] = npcList;
	end
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

function Entity:ActivateRules()
	Entity._super.ActivateRules(self);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
	local EntityCommandBlock = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock")
	
	local oldList = self:GetCommandList() or {}
	local tempList = commonlib.copy(oldList)
	local dft_cmds = (System.options.world_enter_cmds and commonlib.split(System.options.world_enter_cmds,";")) or {}
	for i=#dft_cmds,1,-1 do
		local str = dft_cmds[i]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
		table.insert(tempList,1,str)
	end
	if #tempList>0 then
		self:SetCommandTable(tempList) --将从渠道配置里读取到的世界参数，添加到起点命令列表开头，以便有冲突时以出生点编辑为准
	end
	-- tricky: just emulate the command block. 
	EntityCommandBlock.ExecuteCommand(self, EntityManager.GetPlayer(), true, true);
	self:SetCommandTable(oldList)
end

-- when the body of the player hit this entity. 
function Entity:OnCollideWithPlayer(entity, bx,by,bz)
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button == "right" and GameLogic.GameMode:CanEditBlock()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
		local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=self:GetInnerObject()})
		task:Run();

		local generatorName = WorldCommon.GetWorldTag("world_generator");
		if (generatorName == "paraworld" and not System.options.isPapaAdventure) then
			ParaWorldNPC.ShowPage();
		end
	end
	return true;
end

-- return empty collision AABB, since it does not have physics. 
function Entity:GetCollisionAABB()
	if(not self.aabb) then
		self.aabb = ShapeAABB:new();
	end
	return self.aabb;
end

function Entity:IsSearchable()
	return true;
end

function Entity:GetDisplayName()
	return "home";
end

function Entity:GetText()
	return self:GetCommand()
end

function Entity:FindFile(text, bExactMatch)
	local code = self:GetText()
	if(code) then
		return mathlib.StringUtil.FindTextInLine(code, text, bExactMatch)
	end
end

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = Entity._super.GetNewItemsList(self) or {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.CommandLine,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Code,1);
	return itemStackArray;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	Entity._super.FrameMove(self, deltaTime);
end