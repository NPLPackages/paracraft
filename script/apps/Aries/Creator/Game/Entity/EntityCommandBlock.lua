--[[
Title: CommandBlock Entity
Author(s): LiXizhi
Date: 2013/12/17
Desc: It also fire neuron activation. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
local EntityCommandBlock = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"));

-- class name
Entity.class_name = "EntityCommandBlock";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- command line text

function Entity:ctor()
	self.inventory = InventoryBase:new():Init();
	self.inventory:SetClient();
end

function Entity:Refresh()
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	return self:ExecuteCommand(triggerEntity, true);
end

-- the command block's variable is always the current player's variable
function Entity:GetVariables()
	local player = EntityManager.GetPlayer();
	if(player) then
		return player:GetVariables();
	end
end

-- @param entityPlayer: this is the triggering player or sometimes the command entity itself if /activate self is used. 
-- @param bIgnoreNeuronActivation: true to ignore neuron activation. 
-- @param bIgnoreOutput: ignore output
function Entity:ExecuteCommand(entityPlayer, bIgnoreNeuronActivation, bIgnoreOutput)
	if(self:IsInputDisabled()) then
		return
	end

	-- clear all time event
	self:ClearTimeEvent();

	-- just in case the command contains variables. 
	local variables = (entityPlayer or self):GetVariables();
	local last_result;
	local cmd_list = self:GetCommandList();
	if(cmd_list) then
		last_result = CommandManager:RunCmdList(cmd_list, variables, self);
	end

	local bIsInsideBracket;
	local bIsNegatingSign;
	for i = 1, self.inventory:GetSlotCount() do
		local itemStack = self.inventory:GetItem(i);
		if(itemStack) then
			if(bIsInsideBracket) then
				if(itemStack.id == block_types.names.Wire)then
					-- this is a logical OR
					bIsInsideBracket = false;
					bIsNegatingSign = false;
				end
			else
				if(itemStack.id == block_types.names.Electric_Torch_On)then
					bIsNegatingSign = not bIsNegatingSign;
				else
					-- if script return false, we will stop loading slots behind
					last_result = itemStack:OnActivate(self, entityPlayer);
					if( (not bIsNegatingSign and last_result==false) or  (bIsNegatingSign and last_result~=false) ) then
						if(not bIsInsideBracket) then
							bIsInsideBracket = true;
						else
							break;
						end
					end	
					if(bIsNegatingSign) then
						bIsNegatingSign = false;
					end
				end
			end
		end
	end

	if(not bIgnoreOutput) then
		self:SetLastCommandResult(last_result);
	end

	-- if the containing block is a neuron block, we will fire an activation. 
	if(not bIgnoreNeuronActivation) then
		local bx, by, bz = self:GetBlockPos();
		local neuron = NeuronManager.GetNeuron(bx, by, bz, false);
		if(neuron) then
			neuron:Activate({type="click", action="toggle"});
		end
	end
end

-- get the last electric output result. 
function Entity:GetLastOutput()
	return self.last_output;
end

-- get output from result. if result is a value larger than 1. 
-- value larger than 15 is clipped. 
-- @return nil or a value between [1,15]
function Entity:ComputeElectricOutput(last_result)
	if(type(last_result) == "number" and last_result>=1) then
		return math.min(15, math.floor(last_result));
	end
end

-- set the last result. 
function Entity:SetLastCommandResult(last_result)
	local output = self:ComputeElectricOutput(last_result)
	if(self.last_output ~= output) then
		self.last_output = output;
		local x, y, z = self:GetBlockPos();
		BlockEngine:NotifyNeighborBlocksChange(x, y, z, BlockEngine:GetBlockId(x, y, z));
	end
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
		if(self.isPowered ~= isPowered) then
			self.isPowered = isPowered;
			if(isPowered) then
				self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
					local x,y,z = self:GetBlockPos();
					local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
					if(isPowered) then
						self:ExecuteCommand();
					end
				end})
				self.timer:Change(30, nil);
			end
		end
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.isPowered = node.attr.isPowered == "true";
	if(node.attr.last_output) then
		self.last_output = tonumber(node.attr.last_output);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	if(self.isPowered) then
		node.attr.isPowered = true;
	end
	if(self.last_output) then
		node.attr.last_output = self.last_output;
	end
	return node;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"输入命令行(可以多行): <div>例如:/echo Hello</div>"
end

-- allow editing bag 
function Entity:HasBag()
	return true;
end

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	local itemStackArray = Entity._super.GetNewItemsList(self) or {};
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.CommandLine,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Code,1);
	itemStackArray[#itemStackArray+1] = ItemStack:new():Init(block_types.names.Wire,1);
	return itemStackArray;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	if(not self:IsPaused() and not self:AdvanceTime(deltaTime)) then
		-- stop ticking when there is no timed event. 
		self:SetFrameMoveInterval(nil);
	end
end