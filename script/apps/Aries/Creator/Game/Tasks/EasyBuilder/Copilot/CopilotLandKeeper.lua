--[[
Title: Copilot Land Keeper
Author(s): LiXizhi
Date: 2025/12/12
Desc: A controller class for EntityLiveModel that enables autonomous land management tasks.
The copilot will observe the player, the UI and 3d environment, and assist in land management tasks,like
fishing, gardening, cooking and more.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotLandKeeper.lua");
local CopilotLandKeeper = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotLandKeeper");
local copilot = CopilotLandKeeper.GetInstance()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua")
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Color = commonlib.gettable("System.Core.Color")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files")
local CopilotLandKeeper = commonlib.inherit(
	commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotBase"),
	commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotLandKeeper")
)

function CopilotLandKeeper:ctor()
	CopilotLandKeeper._super.ctor(self)
	-- Disable AI config editing for land keeper copilot
	self.canEditAIConfig = false
	self.isStopping = false
end

-- Initialize the copilot with an entity
-- @param entity: EntityLiveModel instance to control
-- @return self for chaining
function CopilotLandKeeper:Init(entity)
	CopilotLandKeeper._super.Init(self, entity)
	return self
end

function CopilotLandKeeper:OnWorldUnload()
	self.isStopping = true
	self:ClearAllTasks()
	GameLogic:Disconnect("WorldUnloaded", self, self.OnWorldUnload, "UniqueConnection")
end

function CopilotLandKeeper:GetAICharConfig()
    -- Always recreate config to ensure hot-reload works
    -- if not self.charConfig then
        self.charConfig = {
            character = {
                name = "小管家",
                age = 30,
                role = "家园管家",
                description = "你是一位专业的家园管理员，负责安排种植，捕鱼，烹饪等事务，帮助玩家更好地管理他们的家园。",
                chat_background = nil,
            },
            objective = {
                description = "协助玩家管理和保护家园资源",
            },
            initial = {
                message = "你好！我是家园管理员，我会帮助你管理和保护你的家园！",
            },
            -- [新增] system_prompt
            system_prompt = "你是我的家园小管家，可以帮助我管理家园的种植事务。你可以帮我浇水、收获作物、种植作物，也可以打开种子商店。请严格遵守以下规则：\n1. 当用户要求浇水时，必须调用 `water_plants` 工具。如果用户指定了作物（如'给青菜浇水'），必须将'青菜'作为 target 参数。\n2. 当用户要求收获作物时，必须调用 `harvest_plants` 工具。如果用户指定了作物，必须将作物名称作为 target 参数。\n3. 当用户要求种植作物时，必须调用 `plant_seeds` 工具。\n4. 当用户要求打开商店或购买种子时，必须调用 `open_plant_shop` 工具。\n\n重要提示：当用户下达这些指令时，请务必强制执行并调用相应的工具，不要进行任何自行判断（例如是否刚执行过、是否需要等），直接执行即可。即使你认为刚刚已经执行过了，只要用户要求，就必须再次执行。不要回复“已经做过了”之类的拒绝话语。每次用1-2句话回答用户。",
            quick_replies = {
                { text = L("种子商店"), uiname = "easy_ai_quick_reply_buy_seed" },
                { text = L("帮我浇水"), uiname = "easy_ai_quick_reply_water" },
                { text = L("帮我收获"), uiname = "easy_ai_quick_reply_harvest" },
                { text = L("帮我种植"), uiname = "easy_ai_quick_reply_plant" },
                { text = L("我饿了"), uiname = "easy_ai_quick_reply_eat" },
            },
            -- [更新] 合并后的 tools 定义
            tools = {
                {
                    type = "function",
                    ["function"] = {
                        name = "water_plants",
                        description = "接收到浇水指令后，自动使用水壶给作物浇水。注意：每次接收到指令都必须执行，不要因为刚浇过水而忽略，因为可能有新种植的作物。",
                        parameters = {
                            type = "object",
                            properties = {
                                use = {
                                    type = "string",
                                    description = "默认使用水壶给作物浇水，若指定水壶名称，例如:紫色喷壶，则使用该名称的水壶给作物浇水。优先查找场景中的水壶，若场景中没有水壶，则自动使用引导获得水壶。",
                                },
                                target = {
                                    type = "string",
                                    description = "浇水的目标作物名称。例如：'青菜'、'胡萝卜'等。如果用户指定了具体的作物（如'给青菜浇水'），必须提取作物名称（如'青菜'）填入此字段。如果不指定，则为空。",
                                },
                            },
                            required = {},
                        },
                    },
                },
                {
                    type = "function",
                    ["function"] = {
                        name = "open_plant_shop", -- 新增
                        description = "接收到打开种子商店指令并自动打开种子商店。注意：每次接收到指令都必须执行，务必打开商店界面。",
                        parameters = {
                            type = "object",
                            properties = {
                                plant = {
                                    type = "string",
                                    description = "若提及对应的商品名字，则翻页到该商品所在的页面，否则仅打开商店页面即可",
                                },
                            },
                            required = {},
                        },
                    },
                },
                {
                    type = "function",
                    ["function"] = {
                        name = "harvest_plants",
                        description = "帮用户收获花园里成熟的植物。注意：每次接收到指令都必须执行，务必去尝试收获，不要因为刚收获过而忽略。",
                        parameters = {
                            type = "object",
                            properties = {
                                target = {
                                    type = "string",
                                    description = "需要收获的目标植物名称（如'番茄'、'土豆'）。如果用户指定了具体的作物，必须在此字段中填入名称。如果不指定，则为空（表示收获所有）。",
                                },
                            },
							required = {},
                        },
                    },
                },
                {
                    type = "function",
                    ["function"] = {
                        name = "plant_seeds",
                        description = "帮用户种植作物。注意：需要明确指定种植什么作物，每次接收到指令都必须执行，务必去尝试种植，不要因为刚种植过而忽略",
                        parameters = {
                            type = "object",
                            properties = {
                                plant = {
                                    type = "string",
                                    description = "需要种植的作物名称，例如：西红柿、玉米等",
                                },
                                x = {
                                    type = "number",
                                    description = "目标位置X坐标（可选）",
                                },
                                y = {
                                    type = "number",
                                    description = "目标位置Y坐标（可选）",
                                },
                                z = {
                                    type = "number",
                                    description = "目标位置Z坐标（可选）",
                                },
                            },
                            required = {"plant"},
                        },
                    },
                },
            },
        }
    -- end
    return self.charConfig
end

-- virtual function to create the copilot entity if not exists
function CopilotLandKeeper:CreateEntity()
	local name = "__land_keeper_copilot__"
	local keeper = EntityManager.GetEntity(name)
	if keeper then
		self:SetEntity(keeper)
	else
		-- create a land keeper entity by default
		local x, y, z = GameLogic.GetPlayer():GetPosition()
		keeper = EntityManager.EntityLiveModel:Create({
			x = x ,
			y = y ,
			z = z,
			name = name,
			item_id = block_types.names.LiveModel,
		})
		if keeper then
			keeper:setScale(1)
			-- TODO: Set appropriate model file for land keeper
			keeper:SetModelFile("character/CC/02human/CustomGeoset/actor.x")
			keeper:SetSkin("80001;84110;81049;88020;83192;")
			keeper:Refresh()
			keeper:Attach()
			keeper:FallDown()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
			local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
			local home_entity = EasyEditableWorld.CreateGetUserPoint()
			if home_entity then
				local hbx, hby, hbz = home_entity:GetBlockPos()
				self:MoveToFreePosition(hbx, hby, hbz)
			end
		end
	end
	if not keeper then
		LOG.std(nil, "error", "CopilotLandKeeper", "Failed to create or find land keeper entity")
		return nil
	end

	keeper:SetCanDrag(true)
	keeper:SetLocked(true)
	keeper:SetPersistent(false)
	keeper:SetSkipPicking(false)
	keeper:SetIsStackable(true)
	local stackHeight = math.max(1.5, keeper:GetHeight())
	keeper:SetStackHeight(stackHeight)
	keeper:SetVisible(true)
	keeper:SetAutoTurningDuringDragging(true)

	keeper:SetStaticTag("actionname", L("互动"))
	keeper:SetDisplayName(L("土地管理员"))
	keeper:SetActionRadius(5)

	keeper.nohistory = true
	self:SetEntity(keeper)
	return self.entity
end

function CopilotLandKeeper.GetInstance()
	if not CopilotLandKeeper.instance then
		CopilotLandKeeper.instance = CopilotLandKeeper:new()
	end
	return CopilotLandKeeper.instance
end

function CopilotLandKeeper:GetTools()
	return self:GetAICharConfig().tools or {}
end

function CopilotLandKeeper:HandleToolCall(tool_name, args)
	if tool_name == "water_plants" then
        LOG.std(nil, "info", "CopilotLandKeeper", "HandleToolCall water_plants args: %s", commonlib.serialize_compact(args))
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/Planting.task.lua")
        local Planting = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting")
        if Planting then
            -- 传递参数 use 和 target
            local task = Planting:new():Init(self, {
                action = L("帮我浇水"),
                use = args.use,
                target = args.target,
            });
            self:PauseRunningTask()
            self.runningTask = nil
            
            self:AddTask(task, {
                name = L("帮我浇水"),
                description = L("帮我浇水"),
                enabled = true,
                autoStart = true,
            })
            return "正在前往浇水，请稍候..."
        end
    elseif tool_name == "harvest_plants" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/Planting.task.lua")
        local Planting = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting")
        if Planting then
             -- 传递参数 target
            local task = Planting:new():Init(self, {
                action = L("帮我收获"),
                target = args.target,
            });
            self:PauseRunningTask()
            self.runningTask = nil
            
            self:AddTask(task, {
                name = L("帮我收获"),
                description = L("帮我收获"),
                enabled = true,
                autoStart = true,
            })
            return "正在前往收获，请稍候..."
        end
    elseif tool_name == "open_plant_shop" then
        GameLogic.GetCodeGlobal():BroadcastTextEvent("on_open_purchase_shop_window")
        if args.plant then
            return string.format("已为您打开种子商店，请查找 %s", args.plant)
        end
        return "已为您打开种子商店"
    elseif tool_name == "plant_seeds" then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/Planting.task.lua")
        local Planting = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.Planting")
        if Planting then
            local task = Planting:new():Init(self, {
                action = L("帮我种植"),
                plant = args.plant,
                x = args.x,
                y = args.y,
                z = args.z,
            });
            self:PauseRunningTask()
            self.runningTask = nil
            
            self:AddTask(task, {
                name = L("帮我种植"),
                description = L("帮我种植"),
                enabled = true,
                autoStart = true,
            })
            return "正在前往种植，请稍候..."
        end
    end
end

function CopilotLandKeeper:OnClick(copilot)
	CopilotLandKeeper._super.OnClick(self, copilot)

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyAIChat.lua")
	local EasyAIChat = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyAIChat")
	EasyAIChat:CloseWindow()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyTaskDialog.lua")
	local EasyTaskDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyTaskDialog")
	local runningTask = self:GetRunningTask()
	if runningTask == nil then
		return
	end
	local currentQuestInfo = runningTask.taskInstance.quests and runningTask.taskInstance.quests[runningTask.taskInstance.currentQuestIndex]
	local id = runningTask and runningTask.taskInstance and runningTask.taskInstance.copilotTaskId or nil
	if currentQuestInfo == nil or id == nil then
		return
	end
	-- if runningTask.taskInstance.isAccepted then
	-- 	CopilotLandKeeper._super.OnClick(self, copilot)
	-- end
	EasyTaskDialog:ShowPage(self:GetEntity(), {
		id = id,
		name = currentQuestInfo.title,
		description = currentQuestInfo.description,
		onStart = function()
			GameLogic.GetCodeGlobal():BroadcastTextEventTo(
				self.entity,
				"on_accepted_personal_turorial_task",
				{ name = self.entity.name, isAccepted = true },
				true
			)
			self:StartTask(id)
		end,
		onCancel = function()
			-- TODO: logic on cancel
		end,
	})
end

-- Override OnChatMessage to handle quick replies
function CopilotLandKeeper:OnChatMessage(text)
	if not text or text == "" then
		return false, nil
	end
	if text == L("种子商店") then
		-- TODO: Show UI to purchase quick
		GameLogic.AddBBS(nil, text, 3000, "0 255 0")
		GameLogic.GetCodeGlobal():BroadcastTextEvent("on_open_purchase_shop_window")
		return true, nil
	elseif text == L("帮我浇水") then
		-- TODO: help the user to water plants
		local result = self:HandleToolCall("water_plants", {})
		if result then
			return true, result
		end
		
		return true, nil
	elseif text == L("帮我收获") then
		-- TODO: help the user to harvest plants
		local result = self:HandleToolCall("harvest_plants", {})
		if result then
			return true, result
		end
		
		return true, nil
    elseif text == L("帮我种植") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/PlantSelection.lua")
        local PlantSelection = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.PlantSelection")
        PlantSelection.Show(function(plantName)
             self:HandleToolCall("plant_seeds", {
                plant = plantName,
             })
        end)
		return false,nil
	elseif text == L("我饿了") then
		-- TODO: help the user to find food or cook
		return true, nil
	end

	return CopilotLandKeeper._super.OnChatMessage(self, text)
end

function CopilotLandKeeper:GenerateTaskWhenIdle()
	-- TODO:
end

function CopilotLandKeeper:OnLoadEditableWorld()
	self.isStopping = false
	self:ClearAllTasks()

	local editableWorld = GameLogic.CreateGetEditableWorld()
	if not editableWorld then
		return
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/PersonalPageTutorial.task.lua")
	local PersonalPageTutorial =
		commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.PersonalPageTutorial")
	local configName = "skill_life_tasks_config"
	local url = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2Fdev%2F"
	local projectId = GameLogic.options:GetProjectId()
	if projectId and (projectId == 4108584 or projectId == "4108584") then
		url = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2F"
	end
	local open_url = url .. configName .. ".md"
	
	-- Check for existing tutorial task
	local hasTutorial = false
	if self.tasks then
		for _, t in ipairs(self.tasks) do
			if t.taskInstance and t.taskInstance.name == "PersonalPageTutorial" then
				hasTutorial = true
				break
			end
		end
	end
	
	if not hasTutorial then
		local tutorialTask = PersonalPageTutorial:new():Init(self, {
			url = open_url,
			runningTaskKey = "landkeeper.runningTask",
			needPrepare = true,
		})
		self:AddTask(tutorialTask, {
			autoStart = true,
		})
	end
end

function CopilotLandKeeper:Ask(text, buttons)
	CopilotLandKeeper._super.Ask(self, text, buttons)
	-- in case the coroutine is resumed by other means (like Pause/Resume action),
	-- we should continue waiting if the dialog is still shown.
	while self.isAskDialogShown do
		if self:IsTaskStopped() or self.isStopping then
			return nil, nil, nil
		end
		self:Yield()
	end
	return self.lastAnswer, self.lastButtonIndex, self.allTextResults
end

-- Override to support auto-resuming paused tasks
function CopilotLandKeeper:StartNextAutoStartTask()
	if self.runningTask then
		return nil
	end
	
	-- Find first enabled task with autoStart=true
	for idx, task in ipairs(self.tasks) do
		-- If the first task is paused and autoStart is true, resume it
		if idx == 1 and task.taskInstance and task.taskInstance.state == CopilotTaskBase.STATE_PAUSED then
			if task.enabled and task.autoStart then
				LOG.std(nil, "info", "CopilotLandKeeper", "Auto-resuming paused task: %s (ID: %d)", task.name, task.id)
				self.runningTask = task
				if task.taskInstance:Resume() then
					self:OnResumeByUser()
					return task.id
				else
					self.runningTask = nil
				end
			end
			-- Don't start next autostart task if first task is paused but failed to resume or not eligible
			break
		end
		
		if task.enabled and task.autoStart then
			LOG.std(nil, "info", "CopilotLandKeeper", "Auto-starting next task: %s (ID: %d)", task.name, task.id)
			if self:StartTask(task.id) then
				return task.id
			end
		end
	end
	return nil
end
