--[[
Title: building quest task
Author(s): LiXizhi
Date: 2013/11/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
local task = MyCompany.Aries.Game.Tasks.BuildQuest:new({theme_id=1, task_id=1, step_id=2})
task:Run();

MyCompany.Aries.Game.Tasks.BuildQuest:new({task=task}):Run();

task.EndEditing();

local BuildQuest = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
BuildQuest.GetCurrentQuest()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyBlockTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");		
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");			
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local HelpPage = nil;
if(System.options.IsMobilePlatform) then
	NPL.load("(gl)script/mobile/paracraft/GUI/HelpPage.lua");
	HelpPage = commonlib.gettable("ParaCraft.Mobile.GUI.HelpPage");
else
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
	HelpPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
end

local BuildQuest = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest"));

-- checking this number of blocks per render frame. 
local max_check_count_per_frame = 10;

-- selection group index used to show the frame
local groupindex_empty = 2;
local groupindex_wrong = 3;
local groupindex_hint = 4; -- when placeable but not matching hand block
local groupindex_hint_bling = 5; -- when placeable and match hand block
local groupindex_hint_auto = 6; -- auto selected block

-- hint duration in milliseconds. 
BuildQuest.hint_duration = 5000;
BuildQuest.cur_value = 0;
BuildQuest.max_value = 100;

local ignore_blocks;

local cur_instance;

function BuildQuest:ctor()
	
end

function BuildQuest.GetCurrentQuest()
	return cur_instance;
end

-- IProgress interface: get events
function BuildQuest:GetEvents()
	if(not self.events) then
		self.events = commonlib.EventSystem:new();
	end
	return self.events;
end

-- IProgress interface: 
function BuildQuest:GetValue()
	return self.cur_value;
end

-- IProgress interface: 
function BuildQuest:GetMaxValue()
	return self.max_value;
end

-- set the value. 
function BuildQuest:SetValue(value, max_value)
	if(value) then
		self.cur_value = value;
	end
	if(max_value) then
		self.max_value = max_value;
	end
	self:GetEvents():DispatchEvent({type = "OnChange" , });
end

function BuildQuest:RegisterHooks()
	GameLogic.events:AddEventListener("CreateBlockTask", BuildQuest.OnCreateBlockTask, self, "BuildQuest");
	self:GetEvents():AddEventListener("OnClickAccelerateProgress", BuildQuest.OnClickAccelerateProgress, self, "BuildQuest");
	if(not System.options.IsMobilePlatform) then
		QuickSelectBar.BindProgressBar(self);
	end
end

function BuildQuest:UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", BuildQuest.OnCreateBlockTask, self);
	self:GetEvents():RemoveEventListener("OnClickAccelerateProgress", BuildQuest.OnClickAccelerateProgress, self);
	if(not System.options.IsMobilePlatform) then
		QuickSelectBar.BindProgressBar(nil);
	end
end

-- handle click once deploy via the template interface, instead of the task interface.  
-- return true if click once deploy is executed. 
function BuildQuest:TryClickOnceDeploy()
	if(self.task) then
		if(self.ClickOnceDeploy or self.task:IsClickOnceDeploy()) then
			self.finished = true;
			self.task:ClickOnceDeploy(self.UseAbsolutePos);
			return true;
		end
	end
end

function BuildQuest:Run()
	if(cur_instance) then
		-- stop last task of the same type
		BuildQuest.EndEditing();
	end


	if(not TaskManager.AddTask(self)) then
		return;
	end

	cur_instance = self;

	BuildQuestProvider.Init();
	-- current task
	self.task = self.task or BuildQuestProvider.GetTask(self.theme_id, self.task_id,self.category or "template");
	if(not self.task) then
		BuildQuest.EndEditing();
		return;
	end
	
	if(self:TryClickOnceDeploy()) then
		BuildQuest.EndEditing();
		return;
	end

	-- current step
	self.step = self.task:GetStep(self.step_id);
	if(self.step) then
		self.bom = self.step:GetBom();
	end

	if(not self.bom) then
		self.finished = true;
		return;
	end
	
	local oldPosX, oldPosY, oldPosZ = ParaScene.GetPlayer():GetPosition();
	self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;

	-- origin
	self.x, self.y, self.z = self.x or oldPosX, self.y or oldPosY, self.z or oldPosZ;
	self.bx, self.by, self.bz = BlockEngine:block(self.x, self.y+0.1, self.z);
	
	self.finished = false;
	self:RegisterHooks();

	if(self.task.UseAbsolutePos) then
		self.task:ResetProjectionScene();
	end
	-- BuildQuest.ShowPage();

	self:StartEditing();
end

-- whether current task has been finished before
function BuildQuest:TaskIsFinishedBefore()
	if(self.task) then
		local cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
		if(cur_task_index > self.task:GetIndex()) then
			return true;
		end
	end
end

function BuildQuest:OnExit()
	BuildQuest.EndEditing();
end

function BuildQuest:OnClickAccelerateProgress()
	if(self.step) then
		if(true or self:TaskIsFinishedBefore()) then
			self.step:SetAccelerating();
		else
			local curTime = commonlib.TimerManager.GetCurrentTime();
			self.last_accelerate_time = self.last_accelerate_time or 0;
			local cooldown_time = 3;
			local remain_time = cooldown_time*1000 - (curTime - self.last_accelerate_time);

			self.last_accelerate_time = curTime;
			self.step:SetAccelerating(1);

			--if( remain_time < 0 ) then
				--self.last_accelerate_time = curTime;
				--self.step:SetAccelerating(1);
			--else
				--local x, y = QuickSelectBar.GetExpUICursorPos();
				--if(x) then
					--local bx, by, bz = self:GetOrigin();
					--ObtainItemEffect:new({text=string.format("%.1f秒后可用", remain_time/1000), duration=2000, color="#ff0000ff", width=128,height=32, 
						--from_2d={x=x-8,y=y-68}, to_2d={x=x-8,y=y-16}}):Play();
				--end
			--end
		end
	end
end

-- get blocks that should be ignored
function BuildQuest:GetIgnoreBlocks()
	if(ignore_blocks) then
		return ignore_blocks;
	end
	local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
	ignore_blocks = {
		[names.PistonHead] = true,
	}
	return ignore_blocks;
end

function BuildQuest:AutoEquipHandTools()
	if(self.bom) then
		local player = EntityManager.GetPlayer();
		local ignoreBlocks = self:GetIgnoreBlocks();
		local count = #self.bom.sorted_parts;
		for idx =1, 9 do
			if(idx<=count) then
				local part = self.bom.sorted_parts[idx];
				if(not ignoreBlocks[part.block_id]) then
					player.inventory:SetItemByBagPos(idx, part.block_id);
				else
					player.inventory:SetItemByBagPos(idx, 0);
				end
			else
				player.inventory:SetItemByBagPos(idx, 0);
			end
		end
		player.inventory:SetHandToolIndex(1);
	end
end

function BuildQuest:AutoPrebuildBlocks()
	if(self.bom) then
		local ignoreBlocks = self:GetIgnoreBlocks();
		local bx, by, bz = self:GetOrigin();

		-- finish ignored blocks.
		local blocks = self.bom:GetBlocks();

		local bom = self.bom;
		if(blocks) then
			-- if auto prebuild, we will auto sort parts. 
			if(self.step.auto_sort_blocks) then
				self.bom:SortBlocks();
			end
			for i, block in ipairs(blocks) do
				local block_id = block[4];
				if(self.step:IsAutoPrebuildBlock(block[4]) and  not ignoreBlocks[block_id]) then
					local x, y, z = block[1], block[2], block[3];

					local block_template = block_types.get(block_id);
					if(block_template and not block_template:isNormalCube() and not block_template.obstruction) then
						-- if model is not a normal cube, we will also auto build any block below or next to it. 
						local block1 = bom:FindBlock(x,y-1,z) or bom:FindBlock(x-1,y,z) or bom:FindBlock(x+1,y,z) or bom:FindBlock(x,y,z-1) or bom:FindBlock(x,y,z+1);
						if(block1) then
							local block_template = block_types.get(block1[4]);
							if(block_template and block_template:isNormalCube()) then
								BlockEngine:SetBlock(bx+block1[1], by+block1[2], bz+block1[3], block1[4], block1[5]);
								block1.has_set_user_data = true;
							end
						end
					end
					BlockEngine:SetBlock(bx+x, by+y, bz+z, block_id, block[5]);
					block.has_set_user_data = true;
					-- self:FinishBlock(block, i);
				elseif(ignoreBlocks[block[4]]) then
					self:FinishBlock(block, i);
				end
			end
		end
	end
end

function BuildQuest:StartEditing()
	local profile = UserProfile.GetUser();
	profile:GetEvents():DispatchEvent({type = "BuildProgressChanged" , status = "start",});
end

-- @param bCommitChange: true to commit all changes made 
function BuildQuest.EndEditing(bCommitChange)
	BuildQuest.ClosePage()
	GameLogic.HideTipText("<player>");
	if(cur_instance) then
		local self = cur_instance;
		self:UnregisterHooks();
		self:ResetHints();
		self.finished = true;
		cur_instance = nil;
		local profile = UserProfile.GetUser();
		profile:GetEvents():DispatchEvent({type = "BuildProgressChanged" , status = "end",});
	end
end

-- automatically select one block to bling 
-- @param bling_block: the block to use if no block can be found in the neighbourhood of last bling block. 
function BuildQuest:AutoSelectBlingBlock(bling_block)
	if(self.match_block_count == 0) then
		if(self.hint_block_count ~= 0 and bling_block) then
			local block_id = bling_block[4];
			local nIndex = EntityManager.GetPlayer().inventory:FindItemInBag(block_id)
			if(not nIndex or nIndex > 9) then
				-- set it in hand if not exist
				if(ignore_blocks and ignore_blocks[bling_block[4]]) then
					return;
				end
				EntityManager.GetPlayer().inventory:SetBlockInRightHand(block_id);
				nIndex = EntityManager.GetPlayer().inventory:FindItemInBag(block_id);
			end
			-- auto hint the block. 
			if(nIndex) then
				GameLogic.events:DispatchEvent({type = "OnHintSelectBlock" , index = nIndex,});
			end
		end
	else
		self.match_block_count = 0;
	end
	if(self.hint_block_count ~= 0) then
		self.hint_block_count = 0;
		ParaTerrain.DeselectAllBlock(groupindex_hint_auto);
		return
	end
	
	-- try to figure out the next candidate. 
	local bx, by, bz = self:GetOrigin();

	if(self.last_bling_block)  then
		local last_block = self.last_bling_block;
		local x, y, z = bx+last_block[1],by+last_block[2],bz+last_block[3];
		local block_id = ParaTerrain.GetBlockTemplateByIdx(x, y, z); 
		if(block_id == 0 and not BlockEngine:IsInAir(x,y,z)) then
			-- use last one, if it is still a good candidate. 
			bling_block = self.last_bling_block;
		elseif(block_id ~= 0) then
			-- find a new one in old direction
			local last_side = self.last_side;

			local found_candidate;
			if(self.last_side) then
				local count, c_block = self.bom:GetConnectedBlockCount(last_block[1], last_block[2], last_block[3], self.last_side);
				if(c_block) then
					local cx,cy,cz = bx+c_block[1],by+c_block[2],bz+c_block[3];
					local c_block_id = ParaTerrain.GetBlockTemplateByIdx(cx,cy,cz); 
					if(c_block_id == 0 and not BlockEngine:IsInAir(cx,cy,cz)) then	
						found_candidate = true;
						bling_block = c_block;
					end
				end
			end

			if(not found_candidate) then
				local last_c_count, last_c_block, last_c_side;
				for side=0,3 do 
					local count, c_block = self.bom:GetConnectedBlockCount(last_block[1], last_block[2], last_block[3], side);
					if(count and count>(last_c_count or 0)) then
						local cx,cy,cz = bx+c_block[1],by+c_block[2],bz+c_block[3];
						local c_block_id = ParaTerrain.GetBlockTemplateByIdx(bx+c_block[1],by+c_block[2],bz+c_block[3]); 
						if(c_block_id == 0 and not BlockEngine:IsInAir(cx,cy,cz)) then	
							last_c_count, last_c_block, last_c_side = count, c_block, side;
						end
					end
				end
				if(last_c_block) then
					bling_block = last_c_block;
					self.last_side = last_c_side;
				end
			end
		end
	end

	if(bling_block) then
		ParaTerrain.DeselectAllBlock(groupindex_hint_auto);
		ParaTerrain.SelectBlock(bx+bling_block[1],by+bling_block[2],bz+bling_block[3], true, groupindex_hint_auto);
		self.last_bling_block = bling_block;
	end
end

function BuildQuest:AddBlingCandidate(block, candidate_name)
	candidate_name = candidate_name or "bling_block"

	if(ignore_blocks and ignore_blocks[block[4]]) then
		return;
	end

	local last_candidate = self[candidate_name];
	if(not last_candidate) then
		self[candidate_name] = block;
	else
		if(self.last_bling_block) then
			if(self.last_bling_block[4] == block[4]) then
				if(last_candidate[4] == block[4]) then
					if(last_candidate[2] > block[2]) then
						-- use lowest
						self[candidate_name] = block;
					elseif(last_candidate[2] == block[2]) then
						local x, y, z = self.last_bling_block[1], self.last_bling_block[2], self.last_bling_block[3];
						if( ((x - last_candidate[1])^2+(z - last_candidate[3])^2) > 
							((x - block[1])^2+(z - block[3])^2) ) then
							-- use the closest to last one
							self[candidate_name] = block;
						end
					end
				else
					-- always use the last bling block's type if one is suitable. 
					self[candidate_name] = block;
				end
			end
		elseif(last_candidate[2] > block[2]) then
			-- y is bigger
			self[candidate_name] = block;
		elseif(last_candidate[2] == block[2]) then
			-- TODO: find closest to player block
		end
	end
end


-- user just finished a block. 
function BuildQuest:FinishBlock(block, i)
	local cur_time = commonlib.TimerManager.GetCurrentTime();

	self.bom:FinishBlock(i);
	self:SetValue(self.bom:GetFinishedCount(), self.bom:GetMaxBlockCount());

	if(true or cur_time > (self.last_finish_block_time or 0)) then
		-- play an animation to give some feedback to the user when correctly placed a block. 
		self.last_finish_block_time = cur_time;
		local x, y = QuickSelectBar.GetExpUICursorPos();
		if(x) then
			local bx, by, bz = self:GetOrigin();
			ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;464 43 18 18", duration=1000, color="#ffffffff", width=18,height=18, 
				from_3d={bx = bx+block[1], by = by+block[2], bz = bz+block[3],}, to_2d={x=x-8,y=y-8}}):Play();
		end

		local text = self.step:GetTipText(self.bom:GetFinishedCount());
		if(text) then
			GameLogic.SetTipText(text, "<player>");
		end
	end

	if(self.bom:IsFinished()) then
		self:OnDoNextStep();
	end
end

function BuildQuest:OnFinished()
	local profile = UserProfile.GetUser();
	profile:FinishBuilding(self.task:GetThemeID(), self.task:GetIndex(),HelpPage.cur_category);
	self:OnExit();
end

-- framemove building 
function BuildQuest:FrameMove_Building()
	local blocks = self.bom:GetBlocks();
	if(blocks) then
		local from_index = self.last_check_index or 1;	

		local bx, by, bz = self:GetOrigin();
		
		local end_index; 
		self.last_check_index = from_index+max_check_count_per_frame;
		if( (self.last_check_index+max_check_count_per_frame) < #(blocks) ) then
			end_index = self.last_check_index;
		else
			-- scanning again from the beginning
			end_index = #(blocks);
			self.last_check_index = 1;

			local bling_block = self.bling_block or self.bling_block_empty;
			self.bling_block = nil;
			self.bling_block_empty = nil;
			self:AutoSelectBlingBlock(bling_block);
		end

		local hand_block_id = GameLogic.GetBlockInRightHand()
		local ignoreBlocks = self:GetIgnoreBlocks();

		for i = from_index,  end_index do
			local block = blocks[i];
			local x, y, z = bx+block[1], by+block[2], bz+block[3];
			local block_id = block[4];
			
			if(true) then
				-- block_id 
				local dest_id = ParaTerrain.GetBlockTemplateByIdx(x,y,z); 
				local target_block = block_types.get(block_id);
				if( dest_id == block_id or (target_block:IsAssociatedBlockID(dest_id))) then
					if(self.step:isInvertCreate()) then
						ParaTerrain.SelectBlock(x,y,z, true, groupindex_wrong);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
					else
						-- good match
						if((block[5] or 0) ~= ParaTerrain.GetBlockUserDataByIdx(x,y,z)) then
							-- destroy the block when it is wrong. 
							if(target_block.isAutoUserData) then
								-- for blocks with isAutoUserData with we will only correct it once. 
								if(not block.has_set_user_data) then
									block.has_set_user_data = true;
									BlockEngine:SetBlockData(x,y,z,block[5] or 0, 3);
								end
							else
								BlockEngine:SetBlockData(x,y,z,block[5] or 0, 3);
							end
						end

						if(not block.finished) then
							self:FinishBlock(block, i);
							if(self.finished) then
								return;
							end
						end
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
					end
					-- TODO: give it a feedback!
				elseif(dest_id ~= 0) then
					ParaTerrain.SelectBlock(x,y,z, true, groupindex_wrong);
					ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
					ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
					-- destroy the block when it is wrong. 
					if(self.step:isAutoDelete() and not ignoreBlocks[dest_id] and not ignoreBlocks[block_id] and dest_id ~= names.Water and dest_id ~= names.Still_Water) then
						local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = x,blockY = y, blockZ = z})
						task:Run();
					end
				else
					if(self.step:isInvertCreate()) then
						if(not block.finished) then
							self:FinishBlock(block, i);
							if(self.finished) then
								return;
							end
						end
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
						ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
					else
						if(self.step:isAutoCreate(true) and not ignoreBlocks[block_id]) then
							BlockEngine:SetBlock(x,y,z,block_id,block[5]);
						end
						if(self.show_hint) then
							ParaTerrain.SelectBlock(x,y,z, true, groupindex_empty);
						end
						
						-- empty block
						if( BlockEngine:IsInAir(x,y,z) ) then
							-- if this block's neighbour is all empty, show empty
							ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
							ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
							ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
							self:AddBlingCandidate(block, "bling_block_empty");
						else
							-- hint this block
							--ParaTerrain.SelectBlock(x,y,z, false, groupindex_empty);
							if(hand_block_id == block_id) then
								ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint_bling);
								ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
								self.match_block_count = (self.match_block_count or 0)+ 1;
							else
								-- ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint); -- show 
								ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint); -- show nothing
								ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_bling);
							end
							ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
							self.hint_block_count = (self.hint_block_count or 0)+ 1;
							self:AddBlingCandidate(block);
						end
					end
				end
			end
		end
	end
end

local land_blocks;

function BuildQuest:GetLandBlocks()
	if(land_blocks) then
		return land_blocks;
	end
	local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
	land_blocks = {
		--[names.water] = true,
		--[names.Still_Water] = true,
		[names.Bedrock] = true,
		[names.Stone] = true,
		[names.Air] = true,
		[names.Ice] = true,
		[names.Diamond_Ore] = true,
		[names.Lapis_Lazuli_Ore] = true,
		[names.Gold_Ore] = true,
		[names.Ore] = true,
		[names.Iron_Ore] = true,
		[names.Coal_Ore] = true,
		[names.Sand] = true,
		[names.Grass] = true,
		[names.Dirt] = true,
		[names.Snow] = true,
		[names.TallGrass] = true,
		[names.Fern] = true,
		[names.DeadBush] = true,
		[names.Rose] = true,
		[names.Yellow_Flower] = true,
		[names.Cactus] = true,
		-- tree must be cleared. 
		-- [names.Leaves] = true,
		-- [names.Wood] = true,
	};
	return land_blocks;
end

-- framemove set origin. 
function BuildQuest:FrameMove_SetOrigin()
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	local bx, by, bz = BlockEngine:block(x, y+0.1, z);

	if((self.is_valid and ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_X)) or (self.task.UseAbsolutePos)) then
		self:OnConfirmOrigin();
		return;
	end

	if(self.last_bx==bx and self.last_by==by and self.last_bz==bz) then
		return 
	end
	self.last_bx, self.last_by, self.last_bz = bx, by, bz;

	ParaTerrain.DeselectAllBlock(groupindex_hint);
	ParaTerrain.DeselectAllBlock(groupindex_wrong);

	local land_blocks = self:GetLandBlocks();

	local hasRealTerrain = GameLogic.options.has_real_terrain;

	local force_y_pos;
	if(hasRealTerrain) then
		if ( math.abs(ParaTerrain.GetElevation(x,z) - y) < 1) then
			force_y_pos = by;
		end
	end


	local is_valid = true;
	for _, block in pairs(self.task:GetProjectionBlocks()) do
		local x, y, z = bx+block[1],by,bz + block[3];
		local snap_to_y = nil;
		block.obstruction = nil;
		for dy = math.min(-3,block[2]), 3 do
			local dest_id = ParaTerrain.GetBlockTemplateByIdx(x,y+dy,z); 
			
			if(not land_blocks[dest_id]) then
				block.obstruction = true;
				ParaTerrain.SelectBlock(x, y+dy, z, true, groupindex_wrong);
			elseif(dest_id > 0) then
				-- tricky: if top most block is ok, the entire column is ok.
				block.obstruction = false; 
				snap_to_y = dy;
			end
		end

		if(not block.obstruction) then
			if(snap_to_y or force_y_pos) then
				ParaTerrain.SelectBlock(x, y + (snap_to_y or force_y_pos or -2)+1, z, true, groupindex_hint);
			else
				-- building on air is currently not allowed. 
				ParaTerrain.SelectBlock(x, y + (snap_to_y or force_y_pos or -2)+1, z, true, groupindex_wrong);
				is_valid = false;
			end
		else
			is_valid = false;
		end
	end
	self.is_valid = is_valid;

	if(is_valid) then
		self.bx, self.by, self.bz = bx, by, bz;
		GameLogic.SetTipText(L"按【X】键确认建造位置, 【W,A,S,D】键可以移动", "<player>");
	else
		GameLogic.SetTipText(L"当前位置有障碍物, 请走到一个空旷的位置!", "<player>");
	end
end

function BuildQuest:OnConfirmOrigin()
	ParaTerrain.DeselectAllBlock(groupindex_hint);
	ParaTerrain.DeselectAllBlock(groupindex_wrong);
	self.is_origin_confirmed = true;
	self:OnDoNextStep();
end

function BuildQuest:ResetHints()
	ParaTerrain.DeselectAllBlock(groupindex_empty);
	ParaTerrain.DeselectAllBlock(groupindex_wrong);
	ParaTerrain.DeselectAllBlock(groupindex_hint);
	ParaTerrain.DeselectAllBlock(groupindex_hint_bling);
	ParaTerrain.DeselectAllBlock(groupindex_hint_auto);
end

-- prepare the base ground for the current terrain. 
function BuildQuest:AutoPrepareGround()
	if(self.step) then
		local offset_x, offset_y, offset_z = self.step:GetOffset();
		if(offset_y and offset_y<0) then
			local bx, by, bz = self:GetOrigin();
			for _, block in pairs(self.task:GetProjectionBlocks()) do
				local x, y, z = bx+block[1],by,bz + block[3];
				local snap_to_y = nil;
				for dy = math.max(block[2], offset_y), 0 do
					local dest_id = ParaTerrain.GetBlockTemplateByIdx(x,y+dy,z); 
					if(dest_id and dest_id~=block[4]) then
						BlockEngine:SetBlockToAir(x,y+dy,z);
					end
				end
			end
		end
	end
end

function BuildQuest:OnDoNextStep()
	self.step = self.task:GetStep(self.step_id or 1);
	if(self.step_id and self.step_id > 1) then
		local last_step = self.task:GetStep(self.step_id - 1);
		local offset_x, offset_y, offset_z = last_step:GetPlayerOffset();
		if(offset_x or offset_y or offset_z) then
			local x, y, z = self:GetOrigin();
			local px, py, pz = ParaScene.GetPlayer():GetPosition();
			px, py, pz = BlockEngine:block(px, py+0.1, pz);
			x = if_else(offset_x, x + (offset_x or 0), px);
			y = if_else(offset_y, y + (offset_y or 0), py);
			z = if_else(offset_z, z + (offset_z or 0), pz);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x,blockY = y, blockZ = z})
			task:Run(); 
		end
	end

	if(self.step) then
		self.bom = self.step:GetBom();
		if(self.bom) then
			if((not self.bom.palyerGotoOriginPos) and self.task.UseAbsolutePos) then
				self.bom.palyerGotoOriginPos = true;
				local x,y,z = string.match(self.bom.player_pos,"(%d*),(%d*),(%d*)");
				local playerEntity = EntityManager.GetPlayer();
				if(x and playerEntity) then
					local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX=x, blockY=y, blockZ=z})
					task:Run();
				end
			end
			self.step:Reset();
			local text = self.step:GetTipText();
			if(not text) then
				text = format("%s", self.bom:GetTitle())
			end
			GameLogic.SetTipText(text, "<player>");
			
			self:SetValue(self.bom:GetFinishedCount(), self.bom:GetMaxBlockCount());
			self:ResetHints();
			self:Show3DHintFrame(self.hint_duration);
			self:AutoEquipHandTools();
			self:AutoPrepareGround();
			self:AutoPrebuildBlocks();
			self.step_id = (self.step_id or 1) + 1;
		else
			self:OnFinished();
		end
	else
		self:OnFinished();
	end
end


-- scanning max_check_count_per_frame blocks per frame. 
function BuildQuest:FrameMove()
	if(self.finished or not self.bom) then
		return;
	end
	
	if(not self.is_origin_confirmed) then
		self:FrameMove_SetOrigin();
	else
		self:FrameMove_Building();
	end
end

function BuildQuest:GetOrigin()
	local bx, by, bz;
	if(self.task.UseAbsolutePos) then
		bx, by, bz = string.match(self.bom.pivot,"(%d*),(%d*),(%d*)");
	end
	return bx or self.bx, by or self.by, bz or self.bz;
end

-- show the 3d hint frame
-- @param duration: if nil, it will always show there, otherwise it will only show for this milliseconds. 
function BuildQuest:Show3DHintFrame(duration)
	self.show_hint = true;
	--local blocks = self.bom:GetBlocks();
	--if(blocks) then
		--ParaTerrain.DeselectAllBlock(groupindex_empty);
		--local bx, by, bz = self:GetOrigin();
		--for index, block in ipairs(blocks) do
			--ParaTerrain.SelectBlock(bx+block[1], by+block[2], bz+block[3], true, groupindex_empty);
		--end
	--end
	if(duration) then
		self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
			ParaTerrain.DeselectAllBlock(groupindex_empty);
			self.show_hint = false;
		end})
		self.mytimer:Change(duration, nil);
	end
end

function BuildQuest:OnCreateBlockTask(event)
	if(event.x and self.bom and not self.finished) then
		local x, y, z = self:GetOrigin();
		x, y, z = event.x - x, event.y -y, event.z-z;
		local block = self.bom:FindBlock(x, y, z);
		if(block and block[4] == event.block_id) then
			-- we will redirect bling block to the most recent correctly placed block.
			self.last_bling_block = block;
		end
	end
end

function BuildQuest.IsTaskUnderway()
	if(cur_instance) then
		return true;
	else
		return false;
	end
end

------------------------
-- page function 
------------------------
local page;
function BuildQuest.ShowPage()
	if(not GameLogic.GetFilters():apply_filters("BuildQuest.ShowPage")) then
		return false;
	end

	HelpPage.cur_category = nil;

	if(System.options.IsMobilePlatform) then
		MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(false);

		System.App.Commands.Call("File.MCMLWindowFrame", {
				url = "script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.mobile.html", 
				name = "BuildQuestTask.ShowMobilePage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = false,
				bShow = bShow,
				zorder = -5,
				click_through = true, 
				directPosition = true,
					align = "_fi",
					x = 0,
					y = 0,
					width = 0,
					height = 0,
			});
	else
		System.App.Commands.Call("File.MCMLWindowFrame", {
				url = "script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.html", 
				name = "BuildQuestTask.ShowPage", 
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				isShowTitleBar = false, 
				DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
				style = CommonCtrl.WindowFrame.ContainerStyle,
				zorder = 1,
				allowDrag = true,
				click_through = false,
				directPosition = true,
					--align = "_lt",
					align = "_ct",
					x = -640/2,
					y = -450/2,
					width = 640,
					height = 450,
			});
		--MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
	end
end

function BuildQuest.ClosePage()
	if(page) then
		page:CloseWindow();
		if(System.options.IsMobilePlatform) then
			MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(true);
		end
	end
end

-- @param cur_theme_index: if nil, it is current. 
function BuildQuest.GetCurrentFinishedTaskIndex(cur_theme_index,category)
	if(GameLogic.options:IsCheating()) then
		-- return a large number so that everything can be build. 
		return 999;
	else
		local user = UserProfile.GetUser();
		if(user) then
			cur_theme_index = cur_theme_index or BuildQuest.cur_theme_index or 1;
			local cur_task_index = (user:GetBuildProgress(BuildQuest.cur_theme_index,category) or 0) + 1;
			return cur_task_index;
		else
			return 0;
		end
	end
end

function BuildQuest.OnInit(theme_index,task_index)
	if(HelpPage.cur_category and (HelpPage.cur_category == "command" or HelpPage.cur_category == "shortcutkey")) then
		return;
	end
	BuildQuestProvider.Init();
	BuildQuest.cur_theme_index = theme_index or BuildQuest.cur_theme_index or 1;
	local user = UserProfile.GetUser();
	--if(user) then
		--user:ResetBuildProgress(BuildQuest.cur_theme_index)
	--end

	if(HelpPage.cur_category and HelpPage.cur_category == "tutorial") then
		BuildQuest.cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
	else
		BuildQuest.cur_task_index = 1;
	end
	
	if(task_index) then
		BuildQuest.cur_task_index = task_index;
	end
	
	local cur_theme_taskDS = BuildQuestProvider.GetTasks_DS(BuildQuest.cur_theme_index,HelpPage.cur_category);
	if(cur_theme_taskDS and BuildQuest.cur_task_index > #cur_theme_taskDS) then
		BuildQuest.cur_task_index = #cur_theme_taskDS;
	end
	HelpPage.cur_category = HelpPage.cur_category or "template";
	if(BuildQuest.inited) then
		return;
	end
	BuildQuest.inited = true;
	page = document:GetPageCtrl();
	BuildQuest.template_theme_index = BuildQuest.template_theme_index or 1;
	BuildQuest.template_task_index = BuildQuest.template_task_index or 1;
end

function BuildQuest.QuickBuilding(theme_index,task_index, bUseAbsPosition, category)
	local task = BuildQuestProvider.GetTask(theme_index, task_index, category);
	if(task) then
		if(page) then
			page:CloseWindow();
		end
		task:ClickOnceDeploy(bUseAbsPosition);
	end
end

function BuildQuest.ShowCreateNewThemePage(themeKey,callbcak)
	BuildQuest.new_theme_key = themeKey;
	BuildQuest.create_theme_callback = callbcak;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/BuildQuestTaskNewTheme.html", 
			name = "BuildQuestTask.CreateNewThemeShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = true,
			click_through = false,
			directPosition = true,
				--align = "_lt",
				align = "_ct",
				x = -320/2,
				y = -130/2,
				width = 320,
				height = 130,
		});	
end

function BuildQuest.CreateNewTheme(name)
	local root_dir = BuildQuest.new_theme_category_dir or "worlds/DesignHouse/blocktemplates/";
	local dir = string.format("%s%s",root_dir,name.."/");
	ParaIO.CreateDirectory(commonlib.Encoding.Utf8ToDefault(dir));
	BuildQuestProvider.RefreshDataSource();
	if(page) then
		page:Refresh(0.1);
	end
	local callback = BuildQuest.create_theme_callback;
	if(callback) then
		callback();
	end
end

function BuildQuest.OnOpenMyTemplateFolder()
	local root_dir = "worlds/DesignHouse/blocktemplates/";
	ParaIO.CreateDirectory(root_dir);
    ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..root_dir, "", "", 1); 
end
