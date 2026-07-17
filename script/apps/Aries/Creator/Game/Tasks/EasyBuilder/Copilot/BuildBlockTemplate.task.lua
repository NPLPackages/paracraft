--[[
Title: BuildBlockTemplate Task
Author(s): LiXizhi
Date: 2025
Desc: A task for building block templates with EasyPetCopilot.
1. it first loads a block template from a specified file,like "blocktemplates/house1.blocks.xml".
2. it find the bounding box of the block template.
3. it automatically find a suitable location near the copilot to build the template using copilot:FindEmptySquareGround
4. if it can not find the location, it will ask the user to drag the copilot to another location until it can find a location. 
5. once a free space is found, it shows the wire frame of the block template at the target location for user confirmation. using copilot:Ask()
6. upon user confirmation, it builds the block template one block at a time, based on sequence on algorithm in BuildQuestTask and BuildQuestServer. 
7. after all blocks are built, it will continue to create live entities. 
8. when everything is done, it will mark the task as completed.
9. In the middle, the pet will randomly copilot:Say() something to the user to invite the user to build together. 
10. supports buildSpeed parameter (0.5 to 10, default 1.0) to control building speed
11. Consumes stamina via copilot:ConsumeStamina() for every block created
    - Override ConsumeStamina() method in CopilotBase subclasses to implement custom stamina systems
12. autoSaveToBmax: if nil, automatically set to true when filename extension is .bmax
    - When true, after building, asks user whether to save to bmax in temp folder and create an instance
    - Uses SelectBlocksTask with autoSaveBMaxToTemp to save blocks to temp/blocktemplates/[hash].bmax
    - If user confirms, creates a live model instance 
13. Build Modes:
    - "standalone" (default): The copilot builds all by itself automatically.
    - "guide": The copilot guides the user to build the target. It shows the block on its head,
      walks to the placement location, and asks the user to select and place the correct block.
      If the user places blocks correctly several times (autoAssistThreshold), the copilot will help build together.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildBlockTemplate.task.lua");
local BuildBlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate");

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
local copilot = CopilotDragonPet.GetInstance()

-- Create and add a task with custom options
local task = BuildBlockTemplate:new():Init(copilot, {
    filename = "blocktemplates/chair.bmax",
    alwaysShowBuildTargetWireFrame = true,
	allowUserCancel = false,
	allowUserStop = false,
	buildSpeed = 1.0,
	displayName = "chair",
	autoSaveToBmax = true,  -- or nil to auto-detect from .bmax extension
	buildOrigin = nil,  -- or {x=19200, y=5, z=19200} or {19200, 5, 19200} to skip location confirmation and resume from a specific origin
});

copilot:AddTask(task, {
    name = "Build a chair",
    description = "Build a chair from template",
    enabled = true,
    autoStart = true
});

-- Apply temporary speed boost (e.g., accelerate for 20 seconds)
task:ApplySpeedBoost(5.0, 20);  -- 5x speed for 20 seconds

-- Example 2: Build from raw template data
local task = BuildBlockTemplate:new():Init(copilot, {
    template = {
        blocks = {
            {0, 0, 0, 10, 0}, -- x, y, z, block_id, block_data
            {0, 1, 0, 10, 0},
        },
        liveEntities = {},
    },
    alwaysShowBuildTargetWireFrame = true,
    buildSpeed = 2.0,
});
copilot:AddTask(task);

-- Example 3: Guide mode - copilot guides user to build
local task = BuildBlockTemplate:new():Init(copilot, {
    filename = "blocktemplates/chair.bmax",
    buildMode = "guide",  -- Guide mode: copilot shows blocks and asks user to place them
    autoAssistThreshold = 3,  -- After 3 correct placements, copilot helps build together
});
copilot:AddTask(task, {
    name = "Build a chair together",
    description = "Learn to build a chair with guidance",
    enabled = true,
    autoStart = true
});

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua");
local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local BuildBlockTemplate = commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate"));

BuildBlockTemplate.defaultBuildSpeed = 1.0;
BuildBlockTemplate.minBuildSpeed = 0.5;
BuildBlockTemplate.maxBuildSpeed = 10.0;
BuildBlockTemplate.minEntitySpeedScale = 1.0;
BuildBlockTemplate.maxEntitySpeedScale = 2.0;
BuildBlockTemplate.name = "BuildBlockTemplate"

-- Constructor
function BuildBlockTemplate:ctor()
	BuildBlockTemplate._super.ctor(self);
	self.buildSpeed = self.defaultBuildSpeed;
	self.speedBoostEndTime = nil; -- timestamp when speed boost expires
	self.originalBuildSpeed = nil; -- speed before boost
	self.originalEntitySpeedScale = nil; -- entity's original speed scale
	self.alwaysShowBuildTargetWireFrame = true; -- default to true: show wire frame during build
	self.allowUserCancel = false; -- default to false: don't allow user to cancel during confirmation
	self.autoRemoveWhenStopped = true;
	self.autoSaveToBmax = nil;
	self.autoBoost = true; -- if true, periodically (10-15 seconds) check (we have consumed stamina) and automatically apply speed boost when stamina is above 20. 
	self.buildOrigin = nil; -- default to nil: if specified {x, y, z}, skip location confirmation and start building immediately
	self.lastAutoBoostCheckTime = nil; -- timestamp of last auto-boost check
	self.lastStaminaConsumedCount = 0; -- track number of times stamina was consumed between boost
	self.autoBoostCheckInterval = 5; -- seconds between auto-boost checks
	self.lastBlockId = nil; -- track previous block ID for cost reduction
	self.lastBlockData = nil; -- track previous block data for cost reduction
	self.allowUserStop = true; -- allow user to stop the task during building
	self.allowQuickFinishBuild = false;
	-- Build mode: "standalone" (default) or "guide"
	-- "standalone": copilot builds all by itself
	-- "guide": copilot guides the user to build the target, showing hints and observing user actions
	self.buildMode = "standalone";
	-- Guide mode settings
	self.consecutiveCorrectPlacements = 0; -- Track correct placements for auto-assist
	self.autoAssistThreshold = 3; -- After this many correct placements, copilot helps build
end

function BuildBlockTemplate:Init(copilot, params)
	BuildBlockTemplate._super.Init(self, copilot, params);
	if(type(params) == "table") then
		if params.alwaysShowBuildTargetWireFrame ~= nil then
			self.alwaysShowBuildTargetWireFrame = params.alwaysShowBuildTargetWireFrame;
		end

		if params.allowUserCancel ~= nil then
			self.allowUserCancel = params.allowUserCancel;
		end

		if params.buildOrigin ~= nil then
			self.buildOrigin = params.buildOrigin;
		end

		if params.displayName ~= nil then
			self.displayName = params.displayName;
		end

		if params.saveUnfinishedTask ~= nil then
			self.saveUnfinishedTask = params.saveUnfinishedTask;
		end
		if(params.autoSaveToBmax ~= nil) then
			self.autoSaveToBmax = params.autoSaveToBmax;
		end
		if params.allowQuickFinishBuild ~= nil then
			self.allowQuickFinishBuild = params.allowQuickFinishBuild;
		end
		-- Build mode: "standalone" (default) or "guide"
		if params.buildMode then
			self.buildMode = params.buildMode;
		end
		-- Guide mode settings
		if params.autoAssistThreshold then
			self.autoAssistThreshold = params.autoAssistThreshold;
		end
	end
	return self;
end

function BuildBlockTemplate:OnRemove()
	BuildBlockTemplate._super.OnRemove(self);
	ParaTerrain.DeselectAllBlock(2); -- clear preview group
	
	-- Clear buildOrigin from memory when task is removed (cancelled or failed)
	if self.state == self.STATE_FAILED or self.state == self.STATE_STOPPED then
		self:ClearBuildInfoFromMemory();
	end
end

function BuildBlockTemplate:OnStopByUser()
	BuildBlockTemplate._super.OnStopByUser(self);
	self:ClearBuildInfoFromMemory();
end

-- Get build order priority for different block types
-- Lower values are built first, higher values are built later
-- This ensures proper building sequence: normal blocks first, then wires, then power sources, then pistons
-- @return table mapping block_id to priority value
function BuildBlockTemplate:GetBuildOrder()
	if not BuildBlockTemplate.build_orders then
		BuildBlockTemplate.build_orders = {
			-- Input/control blocks (high priority, built later)
			[block_types.names.Lever] = 900,
			[block_types.names.Stone_Button] = 901,
			[block_types.names.Wooden_Pressure_Plate] = 911,
			[block_types.names.Stone_Pressure_Plate] = 912,
			
			-- Power sources (very high priority, built near end)
			[block_types.names.Electric_Torch] = 950,
			[block_types.names.Electric_Torch_On] = 951,
			[block_types.names.PowerBlock] = 952,
			
			-- Doors and trapdoors
			[block_types.names.IronTrapdoor] = 971,
			[block_types.names.IronTrapdoor_On] = 972,
			
			-- Wiring (high priority, built late)
			[block_types.names.Wire] = 980,
			[block_types.names.Repeater] = 981,
			[block_types.names.Repeater_On] = 982,
			
			-- Pistons (highest priority, built last)
			[block_types.names.StickyPiston] = 1000,
			[block_types.names.Piston] = 1001,
			[block_types.names.PistonHead] = 1002,
		}
	end
	return BuildBlockTemplate.build_orders;
end

-- Sort blocks for optimized building
-- This method implements a smarter sorting strategy that considers:
-- 1. Build order priority (normal blocks first, then wires, power sources, pistons)
-- 2. Y coordinate (bottom-up construction)
-- 3. Spatial proximity for efficient batching
-- @param blocks: array of blocks to sort (in-place sort)
function BuildBlockTemplate:SortBlocksOptimized(blocks)
	local buildOrders = self:GetBuildOrder();
	
	-- Sort blocks using multiple criteria
	table.sort(blocks, function(a, b)
		local blockId_a = a[4];
		local blockId_b = b[4];
		
		-- First priority: build order (normal blocks before special blocks)
		local order_a = buildOrders[blockId_a] or 0;
		local order_b = buildOrders[blockId_b] or 0;
		if order_a ~= order_b then
			return order_a < order_b;
		end
		
		-- Second priority: Y coordinate (bottom to top)
		local y_a = a[2];
		local y_b = b[2];
		if y_a ~= y_b then
			return y_a < y_b;
		end
		
		-- Third priority: Z coordinate for row-by-row building
		local z_a = a[3];
		local z_b = b[3];
		if z_a ~= z_b then
			return z_a < z_b;
		end
		
		-- Fourth priority: X coordinate
		local x_a = a[1];
		local x_b = b[1];
		return x_a < x_b;
	end);

	-- now we create a map from pos to boolean to track built blocks
	-- we will iterate through blocks, if the next block is not of the same type, we will query nearby blocks of the same block id, 
	-- if so, we will create them first, and then add until there are no more nearby blocks of the same type. then we will continue the next block in the array. 
	-- this way, we build a new array of blocks that are optimized for batching.
	
	local count = #blocks;
	if count == 0 then return end

	local function GetPosKey(x, y, z)
		return y*900000000+x*30000+z;
	end

	local spatial_map = {};
	for i = 1, count do
		local b = blocks[i];
		spatial_map[GetPosKey(b[1], b[2], b[3])] = i;
	end

	local processed = {};
	local new_blocks = {};
	local new_count = 0;

	-- Search only 5 neighbor positions (4 cardinal + up), exclude bottom
	local neighbor_offsets = {
		{1, 0, 0},
		{-1, 0, 0},
		{0, 0, 1},
		{0, 0, -1},
		{0, 1, 0}, -- up
	}
	
	for i = 1, count do
		if not processed[i] then
			-- Add current block
			processed[i] = true;
			new_count = new_count + 1;
			new_blocks[new_count] = blocks[i];
			
			local current_block = blocks[i];
			local cx, cy, cz = current_block[1], current_block[2], current_block[3];
			local block_id = current_block[4];
			local block_data = current_block[5];

			-- Check if next block in natural order is different type or already processed
			local next_i = i + 1;
			local need_search = false;
			
			if next_i <= count then
				if processed[next_i] then
					need_search = true;
				else
					local next_block = blocks[next_i];
					if next_block[4] ~= block_id or next_block[5] ~= block_data then
						need_search = true;
					elseif math.abs(next_block[1] - cx) >= 3 or math.abs(next_block[2] - cy) > 1 or math.abs(next_block[3] - cz) >= 3 then
						need_search = true;
					end
				end
			end

			if need_search then
				-- Track valid planes for the current batch
				local valid_xz, valid_xy, valid_yz = true, true, true;

				-- Continue searching neighbors until no more blocks of the same type are found
				while true do
					local found_neighbor = false;
					-- Check neighbors of the *last added block* (which is now at new_blocks[new_count])
					local last_block = new_blocks[new_count];
					local lcx, lcy, lcz = last_block[1], last_block[2], last_block[3];
					
					for _, off in ipairs(neighbor_offsets) do
						local dx, dy, dz = off[1], off[2], off[3]
						
						-- Check if this direction is allowed by current plane constraints
						-- XZ plane: dy == 0, XY plane: dz == 0, YZ plane: dx == 0
						if (valid_xz and dy == 0) or (valid_xy and dz == 0) or (valid_yz and dx == 0) then
							local key = GetPosKey(lcx + dx, lcy + dy, lcz + dz)
							local idx = spatial_map[key]
							if idx and not processed[idx] then
								local b = blocks[idx]
								if b[4] == block_id and b[5] == block_data then
									processed[idx] = true;
									new_count = new_count + 1;
									new_blocks[new_count] = blocks[idx];
									found_neighbor = true;
									
									-- Update plane constraints based on the direction taken
									if dy ~= 0 then valid_xz = false end
									if dz ~= 0 then valid_xy = false end
									if dx ~= 0 then valid_yz = false end
									
									break; -- Found one, break inner loop to continue from this new block
								end
							end
						end
					end
					
					if not found_neighbor then
						break; -- No more neighbors of same type found, stop searching
					end
				end
			end
		end
	end

	-- Replace original blocks with sorted ones
	for i = 1, new_count do
		blocks[i] = new_blocks[i];
	end
end

-- Set build speed (0.5 to 10, default 1)
-- @param speed: build speed multiplier
function BuildBlockTemplate:SetBuildSpeed(speed)
	speed = speed or self.defaultBuildSpeed;
	speed = math.max(self.minBuildSpeed, math.min(self.maxBuildSpeed, speed));
	if self.buildSpeed ~= speed then
		self.buildSpeed = speed;
		-- Notify user about speed change
		if self.copilot then
			if speed > self.defaultBuildSpeed * 1.5 then
				local remainingTime = "";
				if self.speedBoostEndTime then
					local remainingSec = math.ceil((self.speedBoostEndTime - commonlib.TimerManager.GetCurrentTime()) / 1000);
					if remainingSec > 0 then
						remainingTime = string.format(L"，持续%d秒", remainingSec);
					end
				end
				self.copilot:Say(L"全速建造中！" .. remainingTime, 3);
				self.copilot:SetWalkSpeed(4 * speed);
			else
				self.copilot:Say(L"建造速度已恢复正常", 2);
				self.copilot:SetWalkSpeed(4);
			end
		end
	end
	return self;
end

-- Get current effective build speed
function BuildBlockTemplate:GetBuildSpeed()
	-- Check if speed boost has expired
	if self.speedBoostEndTime and commonlib.TimerManager.GetCurrentTime() > self.speedBoostEndTime then
		-- Boost expired, restore original speed
		if self.originalBuildSpeed then
			self:SetBuildSpeed(self.originalBuildSpeed);
			self.originalBuildSpeed = nil;
		end
		self.speedBoostEndTime = nil;
	end
	return self.buildSpeed;
end

-- Calculate entity speed scale from build speed
-- Maps buildSpeed to entity speed scale in range [1.0, 2.5]
-- @param buildSpeed: current build speed
-- @return entity speed scale
function BuildBlockTemplate:GetEntitySpeedScale(buildSpeed)
	-- Clamp buildSpeed to entity speed scale range
	local speedScale = math.max(self.minEntitySpeedScale, math.min(self.maxEntitySpeedScale, buildSpeed));
	return speedScale;
end

-- Set entity speed scale based on build speed
-- @param copilot: copilot instance
-- @param buildSpeed: current build speed
function BuildBlockTemplate:SetEntitySpeedScale(copilot, buildSpeed)
	local entity = copilot:GetEntity();
	if entity and entity:IsValid() then
		local speedScale = self:GetEntitySpeedScale(buildSpeed);
		local obj = entity:GetInnerObject();
		if obj then
			obj:ToCharacter():SetSpeedScale(speedScale);
		end
	end
end

-- Restore entity speed scale to normal
-- @param copilot: copilot instance
function BuildBlockTemplate:RestoreEntitySpeedScale(copilot)
	local entity = copilot:GetEntity();
	if entity and entity:IsValid() then
		local obj = entity:GetInnerObject();
		if obj then
			obj:ToCharacter():SetSpeedScale(1.0);
		end
	end
end


-- Apply a temporary speed boost
-- @param speed: target speed multiplier
-- @param duration: duration in seconds
function BuildBlockTemplate:ApplySpeedBoost(speed, duration)
	if not self.speedBoostEndTime then
		-- Store original speed only if not already boosted
		self.originalBuildSpeed = self.buildSpeed;
	end
	
	speed = math.max(self.minBuildSpeed, math.min(self.maxBuildSpeed, speed));
	self.speedBoostEndTime = commonlib.TimerManager.GetCurrentTime() + (duration * 1000);
	self:SetBuildSpeed(speed);
	
	return self;
end



function BuildBlockTemplate:GetActionButtons(buttons)
	-- Call parent class to get base buttons
	buttons = BuildBlockTemplate._super.GetActionButtons(self, buttons) or {};

	if(self.allowQuickFinishBuild) then
		table.insert(buttons, 1, {
			text = L"快速完成",
			name = "QuickFinishBuild",
		});
	else
		-- Prepend speed boost button
		table.insert(buttons, 1, {
			text = L"加速建造20秒",
			name = "AccelerateBuild20s",
		});
	end
	
	return buttons;
end

function BuildBlockTemplate:OnClickActionButton(actionName)
	if actionName == "AccelerateBuild20s" then
		self:ApplySpeedBoost(5.0, 20);
	elseif actionName == "QuickFinishBuild" then
		self.isQuickFinishing = true;
	else
		-- Call parent class for other actions
		BuildBlockTemplate._super.OnClickActionButton(self, actionName);
	end
end

-- Find and confirm a build spot near the copilot. Returns originBX, originBY, originBZ on success or nil on cancel/stop.
function BuildBlockTemplate:FindAndConfirmBuildSpot(copilot, blocks, radius, maxSearchDistance, maxHeightDiff, minX, minY, minZ, maxX, maxY, maxZ)
	local EntityManager = EntityManager;
	local groupindex_preview = 2; -- follow BuildQuest convention for empty group

	while(true) do
		while(true) do
			if self:CheckStopRequested() then return nil end
			self:CheckPaused();
			local targetBX, targetBY, targetBZ = copilot:FindEmptySquareGround(radius, maxSearchDistance, maxHeightDiff);
			if(targetBX) then
				-- compute origin based on template center and ground Y
				local centerX = (minX + maxX) / 2;
				local centerZ = (minZ + maxZ) / 2;
				local centerX_round = math.floor(centerX + 0.5);
				local centerZ_round = math.floor(centerZ + 0.5);
				local originBX = targetBX - centerX_round;
				local originBZ = targetBZ - centerZ_round;
				local originBY = targetBY - minY;

				-- walk to target and show preview
				copilot:WalkTo(targetBX, targetBY, targetBZ);
				ParaTerrain.DeselectAllBlock(groupindex_preview);
				for _, b in ipairs(blocks) do
					local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
					ParaTerrain.SelectBlock(wx, wy, wz, true, groupindex_preview);
				end

				-- face player
				local player = EntityManager.GetFocus();
				if(player) then
					copilot:TurnTo(player:GetPosition());
				end

				-- Build confirmation options based on allowUserCancel
				local confirmOptions;
				if self.allowUserCancel then
					confirmOptions = {{text = L"是的", default = true}, L"换个位置", L"取消"};
				else
					confirmOptions = {{text = L"是的", default = true}, L"换个位置"};
				end

				local answer, btnIndex = copilot:Ask(L"这里有足够的空间，要在这里建造吗？", confirmOptions);
				if(btnIndex == 1) then
					if not self.alwaysShowBuildTargetWireFrame then
						ParaTerrain.DeselectAllBlock(groupindex_preview);
					end
					return originBX, originBY, originBZ;
				end

				ParaTerrain.DeselectAllBlock(groupindex_preview);
				if(btnIndex == 2) then
					-- User wants to try another location
					local relocateOptions;
					if self.allowUserCancel then
						relocateOptions = {{text = L"好了", default = true}, L"取消"};
					else
						relocateOptions = {{text = L"好了", default = true}};
					end
					
					local again, againIdx = copilot:Ask(L"请把我拖到一个空旷的位置。", relocateOptions);
					if(againIdx == 1) then
						copilot:Say(L"好的，正在搜索新位置...", 1);
						break
					elseif self.allowUserCancel then
						copilot:Say(L"已取消建造。", 2);
						self.state = self.STATE_FAILED;
						return nil
					end
				elseif self.allowUserCancel and btnIndex == 3 then
					-- User explicitly cancelled (only possible if allowUserCancel is true)
					copilot:Say(L"已取消建造。", 2);
					self.state = self.STATE_FAILED;
					return nil
				end
			else
				local noAreaOptions;
				if self.allowUserCancel then
					noAreaOptions = {{text = L"准备好了", default = true}, L"取消"};
				else
					noAreaOptions = {{text = L"准备好了", default = true}};
				end
				
				local answer, btnIndex = copilot:Ask(L"附近找不到空闲区域。请把我拖到另一个位置，然后点击准备好了。", noAreaOptions);
				if(btnIndex == 1) then
					copilot:Say(L"正在新位置重新搜索...", 1);
					break
				elseif self.allowUserCancel and btnIndex == 2 then
					self.state = self.STATE_FAILED;
					copilot:Say(L"已取消建造。", 2);
					return nil;
				end
			end
		end
		copilot:Wait(0.2);
	end
end

-- Initialize runtime options from params table
function BuildBlockTemplate:InitializeTaskOptions(params)
	local buildSpeed = params.buildSpeed or self.defaultBuildSpeed;
	self:SetBuildSpeed(buildSpeed);
end

-- Load template blocks/entities and compute bounds
function BuildBlockTemplate:LoadTemplateData(params, copilot)
	if params.template and params.template.blocks then
		local blocks = params.template.blocks;
		local liveEntities = params.template.liveEntities;
		
		if #blocks == 0 then
			copilot:Say(L"模板中没有方块。", 2);
			self.state = self.STATE_FAILED;
			return;
		end

		local bounds = self:ComputeTemplateBounds(blocks);
		bounds.blocks = blocks;
		bounds.liveEntities = liveEntities;
		bounds.filename = params.filename;
		return bounds;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");

	local filename = params.filename;
	if(not filename) then
		copilot:Say(L"未提供模板文件名。", 2);
		self.state = self.STATE_FAILED;
		return;
	end

	-- Set autoSaveToBmax to true if filename extension is .bmax and autoSaveToBmax is not explicitly set
	if(self.autoSaveToBmax == nil) then
		local extension = filename:match("%.([^%.]+)$");
		if(extension and extension:lower() == "bmax") then
			self.autoSaveToBmax = true;
		end
	end

	local fullpath;
	if(commonlib.Files.IsAbsolutePath(filename)) then
		fullpath = filename;
	else
		fullpath = Files.GetWorldFilePath(filename)
			or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename))
			or Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename));
	end

	local tmpl = BlockTemplate:new({filename = fullpath, UseAbsolutePos = params.UseAbsolutePos});
	local ok, blocks, liveEntities = tmpl:LoadTemplateToMemory(fullpath);
	if(not ok or not blocks or #blocks == 0) then
		copilot:Say(L"加载方块模板失败: " .. tostring(fullpath), 3);
		self.state = self.STATE_FAILED;
		return;
	end

	local bounds = self:ComputeTemplateBounds(blocks);
	bounds.blocks = blocks;
	bounds.liveEntities = liveEntities;
	bounds.filename = filename;
	return bounds;
end

-- Compute bounding box and placement radius for template blocks
function BuildBlockTemplate:ComputeTemplateBounds(blocks)
	local minX, minY, minZ = math.huge, math.huge, math.huge;
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge;
	for _, b in ipairs(blocks) do
		local x, y, z = b[1], b[2], b[3];
		minX = math.min(minX, x); minY = math.min(minY, y); minZ = math.min(minZ, z);
		maxX = math.max(maxX, x); maxY = math.max(maxY, y); maxZ = math.max(maxZ, z);
	end

	local width = maxX - minX + 1;
	local depth = maxZ - minZ + 1;
	local radius = math.ceil(math.max(width, depth) / 2 + 1);

	return {
		minX = minX, minY = minY, minZ = minZ,
		maxX = maxX, maxY = maxY, maxZ = maxZ,
		radius = radius,
	};
end

-- Build all blocks from template with batching/animation logic
function BuildBlockTemplate:BuildBlocksSequence(copilot, blocks, originBX, originBY, originBZ, params, groupindex_preview)
	local total = #blocks;
	if total == 0 then
		return true;
	end

	-- Use optimized sorting strategy that considers build order, Y coordinate, and spatial proximity
	self:SortBlocksOptimized(blocks);

	math.randomseed(commonlib.TimerManager.GetCurrentTime() % 100000);

	local currentSpeed = self:GetBuildSpeed();
	self:SetEntitySpeedScale(copilot, currentSpeed);
	local lastSpeedScale = currentSpeed;

	local i = 1;
	while i <= total do
		if self.isQuickFinishing then
			local blocksProcessed = 0;
			for j = i, total do
				local b = blocks[j];
				local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
				local block_id = b[4];
				local block_data = b[5];
				if(BlockEngine:GetBlockId(wx, wy, wz) == 0) then
					copilot:SetBlock(wx, wy, wz, block_id, block_data);
					blocksProcessed = blocksProcessed + 1;

					currentSpeed = self:ConsumeStamina(copilot, 0.1, 2);
					if(currentSpeed == 1) then
						self.isQuickFinishing = false;
						i = j + 1;
						break
					else
						if(blocksProcessed % 25 == 0) then
							copilot:Wait(0.1);
						end
					end
				end
				if self.alwaysShowBuildTargetWireFrame then
					ParaTerrain.SelectBlock(wx, wy, wz, false, groupindex_preview);
				end
			end
			if(self.isQuickFinishing) then
				copilot:Say(L"快速完成建造成功！", 2);
				break;
			else
				copilot:Say(L"体力不足，恢复到正常速度建造。", 2);
			end
		end

		if self:CheckStopRequested() then
			self:RestoreEntitySpeedScale(copilot);
			return false;
		end
		self:CheckPaused();

		currentSpeed = self:GetBuildSpeed();
		if currentSpeed ~= lastSpeedScale then
			self:SetEntitySpeedScale(copilot, currentSpeed);
			lastSpeedScale = currentSpeed;
		end

		local b = blocks[i];
		local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
		local block_id = b[4];
		local block_data = b[5];

		if currentSpeed > 2.0 and i < total then
			local maxBlocksPerBatch = math.min(math.floor(currentSpeed), 10);
			local maxDistance = currentSpeed + 2;
			local batchBlocks = {1};
			for j = 1, maxBlocksPerBatch - 1 do
				local nextIdx = i + j;
				if nextIdx > total then break; end

				local nextBlock = blocks[nextIdx];
				local wx_next = originBX + nextBlock[1];
				local wy_next = originBY + nextBlock[2];
				local wz_next = originBZ + nextBlock[3];
				local block_id_next = nextBlock[4];
				local block_data_next = nextBlock[5];

				local distance = self:GetBlockDistance(wx, wy, wz, wx_next, wy_next, wz_next);
				if block_id == block_id_next and block_data == block_data_next and distance < maxDistance then
					table.insert(batchBlocks, j + 1);
				else
					break;
				end
			end

			if #batchBlocks > 1 then
				local firstBlock = blocks[i];
				local wx1, wy1, wz1 = originBX + firstBlock[1], originBY + firstBlock[2], originBZ + firstBlock[3];
				self:BuildSingleBlock(copilot, wx1, wy1, wz1, block_id, block_data, true, currentSpeed);

				if self.alwaysShowBuildTargetWireFrame then
					ParaTerrain.SelectBlock(wx1, wy1, wz1, false, groupindex_preview);
				end

				for batchIdx = 2, #batchBlocks do
					copilot:Wait(0.3);

					local blockIdx = i + batchBlocks[batchIdx] - 1;
					local batchBlock = blocks[blockIdx];
					local wxb, wyb, wzb = originBX + batchBlock[1], originBY + batchBlock[2], originBZ + batchBlock[3];

					self:BuildSingleBlock(copilot, wxb, wyb, wzb, block_id, block_data, false, currentSpeed);

					if self.alwaysShowBuildTargetWireFrame then
						ParaTerrain.SelectBlock(wxb, wyb, wzb, false, groupindex_preview);
					end
				end

				i = i + #batchBlocks;
			else
				self:BuildSingleBlock(copilot, wx, wy, wz, block_id, block_data, true, currentSpeed);

				if self.alwaysShowBuildTargetWireFrame then
					ParaTerrain.SelectBlock(wx, wy, wz, false, groupindex_preview);
				end

				i = i + 1;
			end
		else
			self:BuildSingleBlock(copilot, wx, wy, wz, block_id, block_data, true, currentSpeed);

			if self.alwaysShowBuildTargetWireFrame then
				ParaTerrain.SelectBlock(wx, wy, wz, false, groupindex_preview);
			end

			i = i + 1;

			if(math.random(1, 100) <= (params.inviteChance or 10)) then
				if currentSpeed > 2.0 then
					copilot:Say(L"全速建造中！", 2);
				else
					copilot:Say(L"一起来建造吧！", 2);
				end
			end
		end
	end

	return true;
end

-- Create live entities after blocks are placed
function BuildBlockTemplate:CreateLiveEntitiesIfNeeded(copilot, liveEntities, originBX, originBY, originBZ)
	if not (liveEntities and #liveEntities > 0) then
		return true;
	end

	copilot:FallDown();

	local originX = originBX * BlockEngine.blocksize;
	local originY = originBY * BlockEngine.blocksize;
	local originZ = originBZ * BlockEngine.blocksize;

	for i, entityData in ipairs(liveEntities) do
		if self:CheckStopRequested() then
			self:RestoreEntitySpeedScale(copilot);
			return false;
		end
		self:CheckPaused();

		local currentSpeed = self:GetBuildSpeed();
		currentSpeed = self:ConsumeStamina(copilot, 3, currentSpeed);

		local targetX = entityData.attr.x + originX;
		local targetY = entityData.attr.y + originY;
		local targetZ = entityData.attr.z + originZ;

		-- Convert to block position to check for existing entities
		local bx, by, bz = BlockEngine:block(targetX, targetY, targetZ);
		
		-- Check if there's already an entity with the same filename at this position
		local shouldCreate = true;
		local targetFilename = entityData.attr.filename;
		if targetFilename then
			local entities = EntityManager.GetEntitiesByMinMax(bx, by - 1, bz, bx, by + 1, bz);
			if entities then
				for _, entity in ipairs(entities) do
					-- Check if it's a LiveModel with the same filename
					if entity.class_name == "LiveModel" and entity:GetModelFile() == targetFilename then
						shouldCreate = false;
						break;
					end
				end
			end
		end

		-- Only create entity if no duplicate found
		if shouldCreate then
			-- Use the new CopilotBase:CreateLiveModel method
			local entity = copilot:CreateLiveModel(entityData, targetX, targetY, targetZ, currentSpeed);
			
			if not entity then
				LOG.std(nil, "warn", "BuildBlockTemplate", "Failed to create live entity at (%f, %f, %f)", targetX, targetY, targetZ);
			end
		end
	end

	return true;
end

-- Final cleanup after build completes
function BuildBlockTemplate:FinalizeBuild(copilot)
	self:RestoreEntitySpeedScale(copilot);
	copilot:Say(L"模板建造完成。", 2);
	copilot:FallDown();
	self:ClearBuildInfoFromMemory();
	self.state = self.STATE_COMPLETED;
	self:SetTaskResult(true);
end

-- Save build info  to copilot memory
-- @param originBX, originBY, originBZ: build origin in block coordinates
function BuildBlockTemplate:SaveBuildInfoToMemory(originBX, originBY, originBZ, filename)
	if self.copilot and self.saveUnfinishedTask then
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBX", originBX);
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBY", originBY);
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBZ", originBZ);
		self.copilot:SaveMemoryValue("BlockTemplateTask_filename", filename);
	end
end

-- Load build info from copilot memory
-- @return originBX, originBY, originBZ or nil if not found
function BuildBlockTemplate:LoadBuildInfoFromMemory()
	if self.copilot then
		local originBX = self.copilot:LoadMemoryValue("BlockTemplateTask_originBX");
		local originBY = self.copilot:LoadMemoryValue("BlockTemplateTask_originBY");
		local originBZ = self.copilot:LoadMemoryValue("BlockTemplateTask_originBZ");
		local filename = self.copilot:LoadMemoryValue("BlockTemplateTask_filename");
		if originBX and originBY and originBZ then
			return originBX, originBY, originBZ, filename;
		end
	end
	return nil;
end

-- Clear build info from copilot memory
function BuildBlockTemplate:ClearBuildInfoFromMemory()
	if self.copilot then
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBX", nil);
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBY", nil);
		self.copilot:SaveMemoryValue("BlockTemplateTask_originBZ", nil);
		self.copilot:SaveMemoryValue("BlockTemplateTask_filename", nil);
	end
end

-- Handle auto-save to bmax and create instance if enabled
-- @param copilot: copilot instance
-- @param templateData: template data with bounds and filename
-- @param originBX, originBY, originBZ: origin position of built template
-- @return true if should continue, false if cancelled
function BuildBlockTemplate:HandleAutoSaveToBmax(copilot, templateData, originBX, originBY, originBZ)
	if not self.autoSaveToBmax then
		return true;
	end

	-- Find a free space of 2*2 in 10 radius, and walk there
	local targetBX, targetBY, targetBZ = copilot:FindEmptySquareGround(2, 10, 4);
	if(targetBX) then
		copilot:WalkTo(targetBX, targetBY, targetBZ);
		copilot:TurnTo();
	end

	-- Load SelectBlocks task to perform selection and save
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");

	-- Ask user whether to save to bmax and create instance
	local answer, btnIndex = copilot:Ask(L"是否保存为物品？", {{text = L"是的", default = true}, L"不用了"});
	
	if(btnIndex ~= 1) then
		-- User chose not to save
		copilot:Say(L"已跳过保存。", 2);
		return true;
	end
	copilot:Say(L"让我先选中方块...", 1);

	-- Collect all built blocks with their world positions and block data
	local blocks = {};
	local all_template_blocks = {};
	for _, b in ipairs(templateData.blocks) do
		local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
		local block_id = b[4];
		local block_data = b[5];
		table.insert(all_template_blocks,{bx = wx,by=wy,bz = wz,id = block_id});	
		-- Get the actual block from the world to ensure it was created
		local block = BlockEngine:GetBlock(wx, wy, wz);
		if block and block.id == block_id then
			-- Add block in format: {x, y, z, block_id, data, serverdata}
			table.insert(blocks, {wx, wy, wz, block_id, block_data or 0, nil});
		end
	end

	if #blocks == 0 then
		copilot:Say(L"未找到已建造的方块。", 2);
		return true;
	end

	if self.buildMode == "guide" then
		CopilotGUIGuide.GuideSelectBlocks(all_template_blocks, copilot, self)
	end
	local task
	local selectionCompleted = false;
	local savedFilePath = nil;
	local select_task = SelectBlocks.GetCurrentInstance();
	if select_task then
		select_task.clickToSelect = true;
		select_task.onlySelectEditable = true;
		select_task.autoSaveBMaxToTemp = true;
		select_task.add_to_history = true;
		select_task:Connect("selectionCanceled", function()
			selectionCompleted = true;
			if(task.saveAsBmaxPath) then
				savedFilePath = task.saveAsBmaxPath;
				copilot:Say(L"成功保存为物品", 2);
			end
		end);
		task = select_task;
	else
		task = SelectBlocks:new({
			blocks = blocks,
			clickToSelect = true, 
			onlySelectEditable = true, 
			autoSaveBMaxToTemp = true,
			add_to_history = true,
		});
		task:Connect("selectionCanceled", function()
			selectionCompleted = true;
			if(task.saveAsBmaxPath) then
				savedFilePath = task.saveAsBmaxPath;
				copilot:Say(L"成功保存为物品", 2);
			end
		end);
		task:Run();
	end
	copilot:Wait(1)
	SelectBlocks.DoClick("save_template")

	-- If save was successful, create instance using EasyModel
	if(savedFilePath) then
		copilot:FallDown();

		local filename = commonlib.Files.GetRelativePath(savedFilePath);
		
		local posX, posY, posZ = copilot:GetPosition()
		-- Create instance using copilot's CreateLiveModel method
		local entityData = {
			name="entity",
			attr = {
				class = "LiveModel",
				item_id = 10074,
				x = posX, y = posY, z = posZ,
				filename = filename,
				displayName = self.displayName,
				facing = 0,
				scaling = 1,
			}
		};
		local entity = copilot:CreateLiveModel(entityData);
		if entity then
			local targetBX, targetBY, targetBZ = copilot:FindEmptySquareGround(1, 4, 4);
			if(targetBX) then
				copilot:WalkTo(targetBX, targetBY, targetBZ);
				copilot:TurnTo();
			end

			local answer, btnIndex = copilot:Ask(L"是否删除原始方块只保留模型？", {{text = L"是的", default = true}, L"保留方块"});
			if(btnIndex == 1) then
				for _, b in ipairs(blocks) do
					BlockEngine:SetBlock(b[1], b[2], b[3], 0);
				end
			end
		else
			copilot:Say(L"创建模型实例失败。", 2);
		end
	end
	return true;
end

-- Main task execution logic (runs in coroutine)
function BuildBlockTemplate:ExecuteTask(copilot)
	-- Store copilot reference for GetBuildSpeed notification
	self.copilot = copilot;

	local params = self.params or {};
	local groupindex_preview = 2; -- follow BuildQuest convention for empty group

	self:InitializeTaskOptions(params);
	local templateData = self:LoadTemplateData(params, copilot);
	if not templateData then
		return;
	end

	local originBX, originBY, originBZ;
	
	-- Check if buildOrigin is specified, if so skip location confirmation
	if self.buildOrigin then
		originBX = self.buildOrigin.x or self.buildOrigin[1];
		originBY = self.buildOrigin.y or self.buildOrigin[2];
		originBZ = self.buildOrigin.z or self.buildOrigin[3];
		
		if not originBX or not originBY or not originBZ then
			LOG.std(nil, "warn", "BuildBlockTemplate", "Invalid buildOrigin specified.");
			self.state = self.STATE_FAILED;
			return;
		end
		
		-- Show preview wireframe if enabled
		if self.alwaysShowBuildTargetWireFrame then
			ParaTerrain.DeselectAllBlock(groupindex_preview);
			for _, b in ipairs(templateData.blocks) do
				local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
				ParaTerrain.SelectBlock(wx, wy, wz, true, groupindex_preview);
			end
		end
		copilot:Say(L"让我继续建造吧", 2);
	else
		-- Normal flow: find and confirm build spot
		local maxSearchDistance = params.maxSearchDistance or (templateData.radius * 2 + 5);
		local maxHeightDiff = params.maxHeightDiff or 3;
		originBX, originBY, originBZ = self:FindAndConfirmBuildSpot(
			copilot,
			templateData.blocks,
			templateData.radius,
			maxSearchDistance,
			maxHeightDiff,
			templateData.minX, templateData.minY, templateData.minZ,
			templateData.maxX, templateData.maxY, templateData.maxZ
		);
		if(not originBX) then
			return;
		end
		
		-- Save buildOrigin to memory after confirmation
		self:SaveBuildInfoToMemory(originBX, originBY, originBZ, templateData.filename);
	end

	-- Check build mode: guide mode uses different building logic
	if self.buildMode == "guide" then
		if not self:BuildBlocksGuideMode(copilot, templateData.blocks, originBX, originBY, originBZ, groupindex_preview) then
			return;
		end
	else
		-- Standalone mode: copilot builds all by itself
		if not self:BuildBlocksSequence(copilot, templateData.blocks, originBX, originBY, originBZ, params, groupindex_preview) then
			return;
		end
	end

	if not self:CreateLiveEntitiesIfNeeded(copilot, templateData.liveEntities, originBX, originBY, originBZ) then
		return;
	end
	
	if not self:HandleAutoSaveToBmax(copilot, templateData, originBX, originBY, originBZ) then
		return;
	end

	self:FinalizeBuild(copilot);
end

-- Consume stamina and reduce speed if insufficient
-- @param copilot: copilot instance
-- @param cost: stamina cost amount
-- @param currentSpeed: current build speed (will be updated if stamina insufficient)
-- @return new currentSpeed after potential adjustment
function BuildBlockTemplate:ConsumeStamina(copilot, cost, currentSpeed)
	currentSpeed = currentSpeed or self:GetBuildSpeed()
	if(not copilot:ConsumeStamina(cost)) then
		-- Slow down build speed if stamina insufficient
		local currentSpeedScale = self:GetEntitySpeedScale(currentSpeed);
		if currentSpeedScale > 1.0 then
			-- Reduce speed to normal
			self:SetBuildSpeed(1.0);
			self:SetEntitySpeedScale(copilot, 1.0);
			currentSpeed = 1.0;
			copilot:Say(L"体力不足，降低建造速度。", 3);
		end
	else
		-- Track stamina consumption for auto-boost
		self.lastStaminaConsumedCount = self.lastStaminaConsumedCount + 1;
	end
	
	-- Check for auto-boost opportunity
	self:CheckAutoBoost(copilot);
	
	return currentSpeed;
end

-- Check if auto-boost should be triggered
-- Periodically checks (every 10-15 seconds) if stamina has been consumed and stamina is above 20
-- @param copilot: copilot instance
function BuildBlockTemplate:CheckAutoBoost(copilot)
	if self.isQuickFinishing then
		local stamina = copilot:GetStamina();
		if stamina and stamina > 1 then
			local currentTime = commonlib.TimerManager.GetCurrentTime();
			self:ApplySpeedBoost(self.maxBuildSpeed, 20);
		end
		return;
	end

	if not self.autoBoost then
		return;
	end
	
	local currentTime = commonlib.TimerManager.GetCurrentTime();
	
	-- Initialize last check time if not set
	if not self.lastAutoBoostCheckTime then
		self.lastAutoBoostCheckTime = currentTime;
		return;
	end
	
	-- Check if enough time has passed since last check
	local timeSinceLastCheck = (currentTime - self.lastAutoBoostCheckTime) / 1000;
	if timeSinceLastCheck < self.autoBoostCheckInterval then
		return;
	end
	
	-- Update last check time and randomize next interval
	self.lastAutoBoostCheckTime = currentTime;
	
	-- Check if we've consumed enough stamina since last check (more than 3)
	if self.lastStaminaConsumedCount <= 3 then
		return;
	end
	
	-- Check if stamina is above 20 and not already boosted
	local stamina = copilot:GetStamina();
	if stamina and stamina > 20 then
		-- Only apply boost if not already boosted or boost has expired
		if not self.speedBoostEndTime or currentTime > self.speedBoostEndTime then
			-- Reset stamina consumed counter
			self.lastStaminaConsumedCount = 0;

			-- Apply auto-boost (5x speed for 20 seconds)
			self:ApplySpeedBoost(5.0, 20);
			copilot:Say(L"体力充足，自动加速建造！", 2);
		end
	end
end

-- Build a single block with position checking and optional animation
-- @param copilot: copilot instance
-- @param x, y, z: block position in block coordinates
-- @param blockId: block ID
-- @param data: block data value
-- @param useAnimation: if true, use normal animation and walk-to; if false, fast build without animation
-- @param currentSpeed: current build speed for animation timing
-- @return true if successful
function BuildBlockTemplate:BuildSingleBlock(copilot, x, y, z, blockId, data, useAnimation, currentSpeed)
	if(BlockEngine:GetBlockId(x, y, z) == 0) then
		-- Check if block is at entity's current position, if so move away
		if self:IsEntityAtBlockPos(copilot, x, y, z) then
			local px, py, pz = copilot:GetFreeBlockPos(x, y, z, true);
			if px then
				copilot:WalkTo(px, py, pz);
			end
		end

		-- Calculate stamina cost based on whether block is same as previous
		local staminaCost = 1;
		if self.lastBlockId == blockId and self.lastBlockData == data then
			-- Same block as previous: cost is 0.2x
			staminaCost = 0.2;
		end
		
		-- Update last block tracking
		self.lastBlockId = blockId;
		self.lastBlockData = data;

		-- Consume stamina whenever a block is created
		currentSpeed = self:ConsumeStamina(copilot, staminaCost, currentSpeed);
		
		if useAnimation then
			-- Build with animation using copilot's CreateBlock method
			copilot:CreateBlock(x, y, z, blockId, data, currentSpeed);
		else
			-- Fast build without animation using SetBlock
			copilot:SetBlock(x, y, z, blockId, data);
		end
	end
	return true;
end

-- Calculate distance between two block positions
-- @param x1, y1, z1: first block position
-- @param x2, y2, z2: second block position
-- @return distance in blocks
function BuildBlockTemplate:GetBlockDistance(x1, y1, z1, x2, y2, z2)
	local dx = x2 - x1;
	local dy = y2 - y1;
	local dz = z2 - z1;
	return math.sqrt(dx * dx + dy * dy + dz * dz);
end

-- Check if entity is currently at the target block position
-- @param copilot: copilot instance
-- @param x, y, z: block position in block coordinates
-- @return true if entity is at this position
function BuildBlockTemplate:IsEntityAtBlockPos(copilot, x, y, z)
	local entity = copilot:GetEntity();
	if not entity or not entity:IsValid() then
		return false;
	end
	
	local ex, ey, ez = entity:GetBlockPos();
	return (ex == x and ey == y and ez == z);
end

-- Guide mode: copilot guides the user to build the target
-- The copilot shows each block on its head, walks to the placement location,
-- and waits for the user to place the correct block. After several correct placements,
-- the copilot will help build together to avoid repetitive tasks.
-- @param copilot: copilot instance
-- @param blocks: array of blocks to build
-- @param originBX, originBY, originBZ: origin position for building
-- @param groupindex_preview: preview group index
-- @return true if successful, false if cancelled/failed
function BuildBlockTemplate:BuildBlocksGuideMode(copilot, blocks, originBX, originBY, originBZ, groupindex_preview)
	if not blocks or #blocks == 0 then
		copilot:Say(L"模板中没有方块。", 2);
		return false;
	end
	local highlightGroupIndex = 5;

	copilot:Say(L"让我们一起来建造吧！跟着我的提示放置方块。", 3);
	copilot:Wait(2);
	
	self:SortBlocksOptimized(blocks);

	math.randomseed(commonlib.TimerManager.GetCurrentTime() % 100000);

	local currentSpeed = self:GetBuildSpeed();
	self:SetEntitySpeedScale(copilot, currentSpeed);
	local lastSpeedScale = currentSpeed;

	-- Map for O(1) checking of valid blocks in this template
	self.valid_template_blocks = {};
	for _, b in ipairs(blocks) do
		local key = (originBY + b[2])*900000000 + (originBX + b[1])*30000 + (originBZ + b[3]);
		self.valid_template_blocks[key] = {bx = originBX + b[1],by=originBY + b[2],bz = originBZ + b[3],id = b[4], data = b[5]};
	end
	-- Reset guide mode state
	self.consecutiveCorrectPlacements = 0;
	local autoAssistMode = false;
	local i = 1;
	local total = #blocks;
	
    -- State definitions
    local STATE = {
        CHECK_BLOCK = 0,
        PREPARE = 1,
        PLACE = 2,
        NEXT_BLOCK = 3,
    }
    local currentState = STATE.CHECK_BLOCK
    local last_block_id = nil
	local category_button,block_button
	while i <= total do
		if self:CheckStopRequested() then
			ParaTerrain.DeselectAllBlock(groupindex_preview);
			ParaTerrain.DeselectAllBlock(highlightGroupIndex);
			copilot:HideHeadOnBlock();
			return false;
		end
		self:CheckPaused();
		
		local b = blocks[i];
		local wx, wy, wz = originBX + b[1], originBY + b[2], originBZ + b[3];
		local block_id = b[4];
		local block_data = b[5] or 0;

        if currentState == STATE.CHECK_BLOCK then
            -- Skip if block already exists at this position
            if BlockEngine:GetBlockId(wx, wy, wz) ~= 0 then
				ParaTerrain.DeselectAllBlock(highlightGroupIndex);
                ParaTerrain.SelectBlock(wx, wy, wz, false, groupindex_preview);
                currentState = STATE.NEXT_BLOCK
            else
                currentState = STATE.PREPARE
            end
        elseif currentState == STATE.PREPARE then
             -- Check if user has the correct block
             local selectedBlockId = CopilotGUIGuide.GetSelectedBlockId();
             if selectedBlockId == block_id then
                 currentState = STATE.PLACE
                 self.prepareStartTime = nil;
                 self.lastHintTime = nil;
             else
                 -- Guide user to take block
                 local currentTime = commonlib.TimerManager.GetCurrentTime();
                 
                 if last_block_id ~= block_id then
                     category_button,block_button = CopilotGUIGuide.GuideTakeBlock(block_id);
                     last_block_id = block_id
                     copilot:Say(L"请选中对应的方块", 2);
                     self.prepareStartTime = currentTime;
                     self.lastHintTime = currentTime;
                 end
                 
                 self.prepareStartTime = self.prepareStartTime or currentTime;
                 self.lastHintTime = self.lastHintTime or currentTime;
                 
                 -- Wait a bit and check again (or auto-equip after timeout)
                 copilot:Wait(0.5)
                 
				 if category_button and block_button then
					local isVisible1 = CopilotGUIGuide.IsUIObjectVisible(category_button) 
					local isVisible2 = CopilotGUIGuide.IsUIObjectVisible(block_button) 
					if category_button and block_button  then
						if isVisible1 and not isVisible2 then
							copilot:Wait(1)
							CopilotGUIGuide.GuideScrollTips()
						elseif isVisible1 and isVisible2 then
							category_button = nil
							block_button = nil
						end
					end
				end

                 -- Periodic Hint
                 if (currentTime - self.lastHintTime) > 5000 then
                     copilot:Say(L"请选中对应的方块", 2);
                     self.lastHintTime = currentTime;
                 end
                 
                 -- Timeout Auto-select
                 if (currentTime - self.prepareStartTime) > 15000 then
					 CopilotGUIGuide.SelectBlock(block_id)
                     copilot:Say(L"帮你选中了方块", 1);
                     currentState = STATE.PLACE
                     CopilotGUIGuide.Stop();
                     self.prepareStartTime = nil;
                     self.lastHintTime = nil;
                 end

                 -- If stuck in prepare for too long, help user (optional, but good for flow)
                 -- For now, just loop until user picks it or manual override
                 if CopilotGUIGuide.GetSelectedBlockId() == block_id then
                     currentState = STATE.PLACE
					 CopilotGUIGuide.Stop();
                     self.prepareStartTime = nil;
                     self.lastHintTime = nil;
                 end
             end
        elseif currentState == STATE.PLACE then
			local rx,ry,rz = BlockEngine:real(wx,wy,wz)
			local screen_pos = {}
			local result = ParaScene.GetScreenPosFrom3DPoint(rx,ry,rz, screen_pos);
			local viewport = ParaEngine.GetAttributeObject():GetField("ScreenResolution", {1280, 720});
			local is_visible = result and screen_pos.x >= 0 and screen_pos.x <= viewport[1] and screen_pos.y >= 0 and screen_pos.y <= viewport[2];
			self.posCheckCount = self.posCheckCount or 0;

			if not is_visible and self.posCheckCount < 3 then
				self.posCheckCount = self.posCheckCount + 1;
				local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
				local player = EntityManager.GetFocus();
				if player then
					local px, py, pz = player:GetBlockPos();
					self:WalkTo(px, py, pz);
					local dy = wy - py;
					if math.abs(dy) > 5 then
						if dy > 0 then
							self:Say(L"目标太高了，请飞起来跟随我", 2);
						else
							self:Say(L"目标太低了，请取消飞行跟随我", 2);
						end
					else
						self:Say(L"当前建造的位置离你太远了，我带你去吧", 2);
					end
					copilot:Wait(2);
					self:WalkTo(wx, wy, wz, 2)
				end
			else
				self.posCheckCount = 0;
				ParaTerrain.DeselectAllBlock(highlightGroupIndex);
				ParaTerrain.SelectBlock(wx, wy, wz, true, highlightGroupIndex);
				local cx, cy, cz = copilot:GetBlockPos();
				if cx == wx and cz == wz then
					self:WalkTo(wx, wy, wz, 4, true)
				end
				copilot:ShowHeadOnBlock(block_id, block_data);
				-- Hint
				local block = block_types.get(block_id);
				local blockName = block and block:GetDisplayName() or tostring(block_id);
				copilot:Say(string.format(L"请在绿色高亮位置放置【%s】", blockName), 1);
				

				local stepStartTime = commonlib.TimerManager.GetCurrentTime();
				local stuckTime = 10000; -- 10 seconds to consider stuck
				if autoAssistMode then
					stuckTime = 2000; -- Faster in auto assist
				end
				
				local placed = false
				while not placed do
					if self:CheckStopRequested() then return false end
					-- Check if placed
					local currentId = BlockEngine:GetBlockId(wx, wy, wz)
					if currentId == block_id then
						placed = true
						self.consecutiveCorrectPlacements = self.consecutiveCorrectPlacements + 1
						-- Feedback
						if self.consecutiveCorrectPlacements == self.autoAssistThreshold then
							copilot:Say(L"太棒了！连续放对了好几个！", 2);
							copilot:Wait(1);
						else
							local encouragements = {L"很好！", L"继续！", L"不错！", L"太棒了！"};
							copilot:Say(encouragements[math.random(1, #encouragements)], 1);
							copilot:Wait(1);
						end
					elseif currentId ~= 0 then
						-- Wrong block
						copilot:Say(L"方块不对哦", 1);
						copilot:Wait(1);
						BlockEngine:SetBlock(wx, wy, wz, 0); -- Remove wrong block
					end
				
					local elapsed = commonlib.TimerManager.GetCurrentTime() - stepStartTime;
				
					if not autoAssistMode and self.consecutiveCorrectPlacements >= self.autoAssistThreshold then
						autoAssistMode = true
						copilot:Say(L"你做得很好！让我来帮你一起建造。", 2);
					end
				
					if not placed then
						if autoAssistMode and elapsed > 1500 then
							-- Use BuildSingleBlock to handle positioning and robustness
							self:BuildSingleBlock(copilot, wx, wy, wz, block_id, block_data, true, currentSpeed);
							placed = true;
						elseif elapsed > 3500 and elapsed < 10000 then
							self:WalkTo(wx, wy, wz, nil, true)
							copilot:Say(L"这里是你要建造的位置", 2);
							copilot:Wait(2);
						elseif elapsed > 10000 then -- 15s stuck
							copilot:Say(L"这一步有点难？我来帮你。", 2);
							self:BuildSingleBlock(copilot, wx, wy, wz, block_id, block_data, true, currentSpeed);
							placed = true;
							self.consecutiveCorrectPlacements = 0 -- Reset combo
						end
					end
				
					if not placed then
						copilot:Wait(0.2)
					end
				end
				currentState = STATE.NEXT_BLOCK
			end
        elseif currentState == STATE.NEXT_BLOCK then
            ParaTerrain.SelectBlock(wx, wy, wz, false, groupindex_preview);
            i = i + 1
            currentState = STATE.CHECK_BLOCK
        end
	end
	
	-- Clean up
	ParaTerrain.DeselectAllBlock(groupindex_preview);
	ParaTerrain.DeselectAllBlock(highlightGroupIndex);

	copilot:HideHeadOnBlock();
	
	return true;
end

function BuildBlockTemplate:OnPauseByUser()
    CopilotGUIGuide.Stop()
	CopilotGUIGuide.GuideKeyAndMouse()
	CopilotGUIGuide.GuideTextTip("")
end

function BuildBlockTemplate:OnStopByUser()
    CopilotGUIGuide.Stop()
	CopilotGUIGuide.GuideKeyAndMouse()
	CopilotGUIGuide.GuideTextTip("")
end

