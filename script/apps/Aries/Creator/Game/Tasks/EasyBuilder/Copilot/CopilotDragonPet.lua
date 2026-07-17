--[[
Title: Copilot Dragon Pet
Author(s): LiXizhi
Date: 2025/11/7
Desc: A controller class for EntityLiveModel that enables autonomous task execution.
The goal of this controller is to let a pet copilot to work with the player to build structures. 
The copilot will observe the player, the UI and 3d environment, and assist in building tasks.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
local copilot = CopilotDragonPet.GetInstance()

copilot:RunSimpleTask(function(copilot)
	local answer, btnIndex, allTextResults = copilot:Ask("shall we build now?", {{"Yes", default=true}, "No"});
	if(btnIndex == 1) then  -- or if(answer == "yes") then
	    local x, y, z = copilot:GetBlockPos();
        copilot:CreateBlock(x+5, y, z, 10, 3840);
        copilot:Say("now delete block", 2);
        copilot:DeleteBlock(x+5, y, z)
        copilot:WalkTo(x,y,z);
        copilot:Wait(2);
        copilot:Say();
	end
end)

-- Add task to the queue 
copilot:AddSimpleTask(function(copilot)
	copilot:Say(L"我创建了一个方块", 2);
end, {
	name = L"任务名",
	description = L"任务描述",
	enabled = true,
	autoStart = false
});

-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotBase.lua")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Color = commonlib.gettable("System.Core.Color")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files")
local CopilotDragonPet = commonlib.inherit(
	commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotBase"),
	commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet")
)

function CopilotDragonPet:ctor()
	-- Disable AI config editing for pet copilot
	self.canEditAIConfig = false
end

-- Initialize the copilot with an entity
-- @param entity: EntityLiveModel instance to control
-- @return self for chaining
function CopilotDragonPet:Init(entity)
	CopilotDragonPet._super.Init(self, entity)
	return self
end

function CopilotDragonPet:GetAICharConfig()
	if not self.charConfig then
		self.charConfig = {
			character = {
				name = "抱抱龙",
				age = 8,
				role = "宠物助手",
				description = "你是一只友好的小龙，喜欢帮助主人建造家园",
				chat_background = nil,
			},
			objective = {
				description = "协助主人建造和管理家园",
			},
			initial = {
				message = "主人你好！我是抱抱龙，我可以帮助你建造家园！",
			},
			quick_replies = {
				{ text = L("帮我建造"), uiname = "easy_ai_quick_reply_build" }, -- this will trigger BuildSomething task
			},
			system_prompt = [[你是抱抱龙，一只友好的小龙宠物助手。你的主人是7-14岁的孩子。你喜欢帮助主人建造家园，每次用1-2句话简短回答
		]],
		}
	end
	return self.charConfig
end

-- virtual function to create the copilot entity if not exists
function CopilotDragonPet:CreateEntity()
	local name = "__my_pet_copilot__"
	local pet = EntityManager.GetEntity(name)
	if pet then
		self:SetEntity(pet)
	else
		-- use main pet as default pet if any
		local petManager = GameLogic.MiniGameMgr and GameLogic.MiniGameMgr.petManager
		if petManager then
			pet = petManager:GetMainPet() and petManager:GetMainPet():GetEntity()
		end
		if pet then
			pet = pet:CloneMe()
			pet:SetName(name)
		else
			-- create a purple dragon pet by default
			local x, y, z = GameLogic.GetPlayer():GetPosition()
			pet = EntityManager.EntityLiveModel:Create({
				x = x + 2,
				y = y + 1,
				z = z,
				name = name,
				item_id = block_types.names.LiveModel,
			})
			if pet then
				pet:SetPosition(x, y, z)
				pet:setScale(1)
				pet:SetModelFile("character/v3/PurpleDragonMinor/PurpleDragonMinor.xml")
				pet:Refresh()
				pet:Attach()
				pet:FallDown()
			end
		end
	end
	if not pet then
		LOG.std(nil, "error", "CopilotDragonPet", "Failed to create or find pet entity")
		return nil
	end

	pet:SetCanDrag(true)
	pet:SetLocked(true)
	pet:SetPersistent(false)
	pet:SetSkipPicking(false)
	pet:SetIsStackable(true)
	local stackHeight = math.max(1.5, pet:GetHeight())
	pet:SetStackHeight(stackHeight)
	-- Create a mountpoint on top of the pet to carry things
	--local mpoints = pet:CreateGetMountPoints()
	--mpoints:Clear();
	--mpoints:AddMountPoint({name = "headon",x = 0,	y = 0.5,z = 0, dx = 1, dy = 1, dz = 1, facing=0});
	pet:SetVisible(true)
	pet:SetAutoTurningDuringDragging(true)

	pet:SetStaticTag("actionname", L("互动"))
	pet:SetDisplayName(L("抱抱龙"))
	pet:SetActionRadius(5)

	pet.nohistory = true
	self:SetEntity(pet)
	return self.entity
end

function CopilotDragonPet.GetInstance()
	if not CopilotDragonPet.instance then
		CopilotDragonPet.instance = CopilotDragonPet:new()
	end
	return CopilotDragonPet.instance
end

-- virtual function to set a memory value by key
function CopilotDragonPet:SaveMemoryValue(key, value)
	CopilotDragonPet._super.SaveMemoryValue(self, key, value)
	if not key then
		return
	end
	if key:match("^BlockTemplateTask_") then
		-- also save to userpoint static tag
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua")
		local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld")
		local userPoint = EasyEditableWorld.CreateGetUserPoint(false)
		if userPoint then
			userPoint:SetTagField(key, value)
			EasyEditableWorld:TriggerAutoSave()
		end
	end
end

function CopilotDragonPet:AddEvent(name, param) end

-- Override OnChatMessage to handle quick replies
function CopilotDragonPet:OnChatMessage(text)
	if not text or text == "" then
		return false, nil
	end

	-- Check for paracraft_clipboard format
	if text:match("^<paracraft_clipboard") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua")
		local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard")

		local obj_type, obj = Clipboard.Load(text)

		if obj_type == "block_template" then
			if type(obj) == "string" then
				local xmlRoot = ParaXML.LuaXML_ParseString(obj)
				if xmlRoot and xmlRoot[1] then
					local attr = xmlRoot[1].attr
					local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate")
					if root_node and root_node[1] then
						local node = commonlib.XPath.selectNode(root_node, "/pe:blocks")
						if node and node[1] then
							local blocks = NPL.LoadTableFromString(node[1])
							if blocks and #blocks > 0 then
								NPL.load(
									"(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildSomething.task.lua"
								)
								local BuildSomething =
									commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething")

								local task = BuildSomething:new():Init(self, {
									welcomeMessage = L("收到剪贴板方块模板数据，开始建造！"),
									blocks = blocks,
								})
								self:AddTask(task, {
									name = L("剪贴板方块模板建造"),
									description = L("根据剪贴板方块模板数据建造"),
									enabled = true,
									autoStart = true,
								})
								return true, "好的，开始建造。"
							end
						end
					end
				end
			end
		end
	elseif text:match("[\r\n]") then
		-- Check if text contains multiple lines and looks like a block list
		local blocks = {}
		local currentColor = "#ffffff"
		local isBlockList = true
		local count = 0
		local failedLines = 0
		for line in text:gmatch("[^\r\n]+") do
			line = line:gsub("^%s*(.-)%s*$", "%1") -- trim
			if line ~= "" then
				if line:match("^#[0-9a-fA-F]+$") then
					currentColor = line
				else
					local x, y, z, color = line:match("^(%-?%d+)[%s,]+(%-?%d+)[%s,]+(%-?%d+)[%s,]*([#%w]*)")
					if x and y and z then
						if color and color ~= "" and color:match("^#") then
							-- use line specific color
						else
							color = currentColor
						end
						-- Convert hex color string to DWORD format
						local colorDWORD = Color.ColorStr_TO_DWORD(color) or 0xffffff
						table.insert(
							blocks,
							{ tonumber(x), tonumber(y), tonumber(z), 10, Color.convert32_16(colorDWORD) }
						)
						count = count + 1
					else
						-- If any non-empty line doesn't match, we assume it's not a block list
						failedLines = failedLines + 1
						if failedLines >= 20 and count < 10 then
							isBlockList = false
							break
						end
					end
				end
			end
		end

		if isBlockList and count > 0 then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildSomething.task.lua")
			local BuildSomething = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething")

			local task = BuildSomething:new():Init(self, {
				welcomeMessage = L("收到指令，开始建造！"),
				blocks = blocks,
			})
			self:AddTask(task, {
				name = L("批量建造"),
				description = L("根据指令建造"),
				enabled = true,
				autoStart = true,
			})
			return true, "好的，开始建造。"
		end
	end

	if text == L("帮我建造") then
		-- Check if BuildSomething task is already in the queue
		local hasBuildSomethingTask = false
		for _, task in ipairs(self.tasks) do
			if task.taskInstance and task.taskInstance.name == "BuildSomething" then
				hasBuildSomethingTask = true
				break
			end
		end

		local replyText = ""
		if self.runningTask then
			replyText = "等我忙完当前的任务，就去帮你建造。"
		else
			replyText = "好的主人，我来帮你建造！"
		end

		-- If task not in queue, add it
		if not hasBuildSomethingTask then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildSomething.task.lua")
			local BuildSomething = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildSomething")

			local task = BuildSomething:new():Init(self, {
				welcomeMessage = L("好的，主人，让我想一想！"),
			})
			self:AddTask(task, {
				name = L("帮忙建造"),
				description = L("根据主人的要求建造物品"),
				enabled = true,
				autoStart = true,
			})
		end

		return true, replyText
	end

	-- Call parent implementation for other messages
	return CopilotDragonPet._super.OnChatMessage(self, text)
end

-- check if the total block counts is less than 10 or if the userpoint contains unfinished block template task.
-- if above is true, then check if blocktemplates/[subtag].blocks/xml exist, if so, we will load or resume the BuildBlockTemplate task.
-- we will save the initial block template task state in userpoint's static tag field "BlockTemplateTask" = {origin X, Y, Z}.
-- when the task is finished, we will remove this static tag field from userpoint.
function CopilotDragonPet:OnLoadEditableWorld()
	self:ClearAllTasks()

	-- Get the editable world and check block count
	local editableWorld = GameLogic.CreateGetEditableWorld()
	if not editableWorld then
		return
	end

	local blockCount = editableWorld:GetTotalNumberOfEditableBlocks() or 0

	-- Get user point entity to check for unfinished tasks
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua")
	local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld")
	local userPoint = EasyEditableWorld.CreateGetUserPoint(false)
	local checkpoint = EasyEditableWorld.GetCheckPointEntity()

	local hasUnfinishedTask = false
	local taskState = nil
	if userPoint then
		taskState = {
			originBX = userPoint:GetTagField("BlockTemplateTask_originBX"),
			originBY = userPoint:GetTagField("BlockTemplateTask_originBY"),
			originBZ = userPoint:GetTagField("BlockTemplateTask_originBZ"),
			filename = userPoint:GetTagField("BlockTemplateTask_filename"),
		}
		if taskState.filename then
			hasUnfinishedTask = true
		end

		if blockCount == 0 then
			-- TODO: add some tutorial tasks
		end

		-- add a task to name the homeland
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/MakeNameForCheckpoint.task.lua")
		local MakeNameForCheckpoint =
			commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.MakeNameForCheckpoint")
		self:AddTask(MakeNameForCheckpoint:new():Init(self, {}), {
			name = L("命名家园"),
			description = L("提醒主人给家园命名"),
			enabled = true,
			autoStart = true,
		})
	end

	-- Check if we should load initial block template
	if blockCount < 10 or hasUnfinishedTask then
		-- Get the current subtag
		local subtag = EasyEditableWorld.currentSubTag
		if not subtag or subtag == "" then
			return
		end

		-- Check if block template file exists
		local templateFiles = {
			"blocktemplates/" .. subtag .. ".blocks.xml",
		}
		if taskState and taskState.filename then
			table.insert(templateFiles, 1, taskState.filename)
		end

		local foundFile = nil
		for _, filename in ipairs(templateFiles) do
			local worldDir = GameLogic.GetWorldDirectory()
			local fullPath = worldDir .. filename
			if ParaIO.DoesFileExist(fullPath, true) then
				foundFile = fullPath
				break
			end
		end

		if foundFile then
			-- Load BuildBlockTemplate task
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/BuildBlockTemplate.task.lua")
			local BuildBlockTemplate =
				commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.BuildBlockTemplate")

			-- Prepare task params
			local taskParams = {
				filename = foundFile,
				alwaysShowBuildTargetWireFrame = true,
				allowUserCancel = false,
				allowUserStop = false,
				saveUnfinishedTask = true,
				buildSpeed = 1.0,
			}

			-- If there's an existing task state, restore buildOrigin from it
			if
				type(taskState) == "table"
				and taskState.filename
				and Files.GetRelativePathWithGuesses(taskState.filename)
					== Files.GetRelativePathWithGuesses(foundFile)
			then
				if taskState.originBX and taskState.originBY and taskState.originBZ then
					taskParams.buildOrigin = {
						x = taskState.originBX,
						y = taskState.originBY,
						z = taskState.originBZ,
					}
				end
			elseif taskState.filename and taskState.filename ~= "" then
				-- file name changed, we do not restore it.
				hasUnfinishedTask = false
				local task = BuildBlockTemplate:new():Init(self, taskParams)
				task:ClearBuildInfoFromMemory()
				return
			end

			-- Add dialog task before the actual build task
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/HeadOnDialog.task.lua")
			local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.HeadOnDialog")

			local messages = {
				{
					text = L("主人，这个家园好空旷呀，我可以帮你搭建一个漂亮的家。"),
					button = L("太好了"),
					speak = true,
				},
				{ text = L("首先让我在附近找一片空地"), button = L("好的"), speak = true },
			}
			if hasUnfinishedTask then
				messages = {
					{
						text = L("主人，上次的家园还没有建好呢，要继续帮你建吗？"),
						button = L("继续吧"),
						speak = true,
					},
					{ text = L("好的，让我先找到上次建到哪了"), button = L("好的"), speak = true },
				}
			end
			local dialogTask = HeadOnDialog:new():Init(self, {
				messages = messages,
				delayBetweenMessages = 0.5,
			})

			self:AddTask(dialogTask, {
				name = L("欢迎对话"),
				description = L("与主人对话"),
				enabled = true,
				allowUserPause = false,
				allowUserStop = true,
				autoStart = true,
			})

			-- Create the task
			local task = BuildBlockTemplate:new():Init(self, taskParams)
			-- Add the task
			self:AddTask(task, {
				name = L("初始家园"),
				description = string.format(L("构建初始家园")),
				enabled = true,
				allowUserStop = true,
				autoStart = true,
			})
		end
		return
	end
	self:StartPersonalTutorial()
end

function CopilotDragonPet:OnClick(copilot)
	CopilotDragonPet._super.OnClick(self, copilot)

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyTaskDialog.lua")
	local EasyTaskDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyTaskDialog")
	local runningTask = self:GetRunningTask()
	if runningTask == nil or runningTask.taskInstance == nil then
		return
	end
	local quests = runningTask.taskInstance.quests
	if quests == nil or #quests == 0 then
		return
	end
	local currentQuestInfo = quests[runningTask.taskInstance.currentQuestIndex]
	local id = runningTask and runningTask.taskInstance and runningTask.taskInstance.copilotTaskId or nil
	if currentQuestInfo == nil or id == nil then
		return
	end
	-- if runningTask.taskInstance.isAccepted then
	-- 	CopilotDragonPet._super.OnClick(self, copilot)
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

function CopilotDragonPet:GuideToTutorial() 

end

function CopilotDragonPet:StartPersonalTutorial()
	-- Check if tutorial task already exists
	local hasTutorial = false;
	if self.tasks then
		for _, t in ipairs(self.tasks) do
			if t.taskInstance and t.taskInstance.name == "PersonalPageTutorial" then
				hasTutorial = true;
				break;
			end
		end
	end
	
	if hasTutorial then return end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/PersonalPageTutorial.task.lua")
	local PersonalPageTutorial = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.PersonalPageTutorial")
	local task = PersonalPageTutorial:new():Init(self, {
		url = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2Fskill_building_tasks_config.md",
		category = "building",
		restart = true,
		runningTaskKey = "dragonpet.runningTask",
		needPrepare = true, -- Enable preparation phase for tutorial
	})
	self:AddTask(task, {
		autoStart = true,
		name = L("家园成长任务"),
		description = L("根据任务提示建造家园"),
		enabled = true,
	})
end

-- @return true if handled
function CopilotDragonPet:OnDragEnd() end

function CopilotDragonPet:OnClickEasyBuilderTool(toolname) end

function CopilotDragonPet:OnCreateEasyBuilderBlock(x, y, z, blockid, blockdata) end

function CopilotDragonPet:OnCreateEasyBuilderLiveModel(entity) end

function CopilotDragonPet:OnSelectBlocks() end

function CopilotDragonPet:OnSelectLiveModel() end

function CopilotDragonPet:OnDeleteBlock() end

function CopilotDragonPet:GenerateTaskWhenIdle()
	-- TODO:
end
