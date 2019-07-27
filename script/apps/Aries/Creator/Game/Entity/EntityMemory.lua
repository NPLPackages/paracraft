--[[
Title: Memory Block Entity
Author(s): LiXizhi
Date: 2016/5/19
Desc: Memory block is a stateful block, which will trigger memories(time series) stored in connected 
movie clips according to similarity between the current virtual world and initial state of time series in movie clips. 

Memory block stores whether the memory is getting attention, and how strict is the initial state matching. 
Left click to increase IncreaseAttention to the block
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMemory.lua");
local EntityMemory = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMemory")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCommandBlock.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCommandBlock"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMemory"));

-- class name
Entity.class_name = "EntityMemory";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;
-- if true, we will not reset time to 0 when there is no time event. 
Entity.disable_auto_stop_time = true;
-- in seconds
-- Entity.framemove_interval = 0.01;

function Entity:ctor()
end

-- @param delta_time: nil to advance to next. 
function Entity:AdvanceTime(delta_time)
	if(delta_time) then
		local cur_time = self:GetTime() + delta_time;
		Entity._super.AdvanceTime(self, 0);
	else
		Entity._super.AdvanceTime(self);
	end
end


function Entity:FindMovieBlockEntity()
	BlockEngine:GetBlockId(self.bx, self.by, self.bz)
end


function Entity:FindNearByMovieEntity()
	local cx, cy, cz = self.bx, self.by, self.bz;
	for side = 0, 5 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x,y,z = cx+dx, cy+dy, cz+dz;
		local blockTemplate = BlockEngine:GetBlock(x,y,z);
		if(blockTemplate and blockTemplate.id == names.MovieClip) then
			local movieEntity = BlockEngine:GetBlockEntity(x,y,z);
			if(movieEntity) then
				return movieEntity;
			end
		end
	end
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	return self:ExecuteCommand(triggerEntity, true, true);
end

-- @return memoryClip, memoryContext: it may be nil
function Entity:CreateGetMemoryClipForEntity(entityPlayer)
	entityPlayer = entityPlayer or EntityManager.GetPlayer();
	local memoryContext = entityPlayer:GetMemoryContext();
	if(memoryContext) then
		local memoryClip = memoryContext:GetMemoryClip(self.bx, self.by, self.bz)
		if(not memoryClip) then
			local movieEntity = self:FindNearByMovieEntity();
			if(movieEntity) then
				memoryClip = memoryContext:CreateMemoryClip();
				memoryClip:SetMovieBlockEntity(movieEntity);
				memoryContext:AddMemoryClip(self.bx, self.by, self.bz, memoryClip);
			end
		end
		return memoryClip, memoryContext;
	end
end

function Entity:ExecuteCommand(entityPlayer, bIgnoreNeuronActivation, bIgnoreOutput)
	Entity._super.ExecuteCommand(self, entityPlayer, true, true);

	local memoryClip, memoryContext = self:CreateGetMemoryClipForEntity(EntityManager.GetPlayer())
	if(memoryClip) then
		-- TODO: following logic is for testing only.
		memoryContext:UpdateContext();
		-- TODO: testing only, just replay it using current player location. 
		memoryClip:Activate(memoryContext);
	end	
end

-- called every frame
function Entity:FrameMove(deltaTime)
	return Entity._super.FrameMove(self, deltaTime);
end


-- add this memory clip to the working memory of player
-- @param player: if nil, it is the current player
function Entity:AddToWorkingMemory(player)
	local memoryClip, memoryContext = self:CreateGetMemoryClipForEntity(player or EntityManager.GetPlayer())
	if(memoryClip) then
		memoryClip:AddToWorkingMemory();
	end
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		-- TODO?
	end

	if(mouse_button=="left") then
		GameLogic.AddBBS("memory", "new attention added to working memory");
		self:AddToWorkingMemory();

	elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
		local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		if(ctrl_pressed) then
			-- ctrl+right click to activate the entity in editor mode, such as for CommandEntity. 
			self:OnActivated(entity);
		else
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end