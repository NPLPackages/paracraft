--[[
Title: PersonalPageTutorial Task
Author(s): Copilot
Date: 2025/11/28
Desc: A copilot task that manages a sequence of tutorials/quests defined in a config file.
It tracks progress using PersonalPageStore and guides the user through quests.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/PersonalPageTutorial.task.lua");
local PersonalPageTutorial = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.PersonalPageTutorial");

-- Method 1: Load quests from a URL (local or remote)
local task = PersonalPageTutorial:new():Init(copilot, {
    pagename = "MyCustomTutorial",
    url="config/Aries/creator/PersonalPageTutorial.json",
});
copilot:AddTask(task, {autoStart = true});

-- Method 2: Pass quests directly
local task = PersonalPageTutorial:new():Init(copilot, {
    pagename = "MyCustomTutorial",
    -- restart = true, -- uncomment to restart the tutorial from beginning
    quests = {
        {
            name = "quest1",
            title = "First Quest",
            description = "This is the first quest",
            tasks = {
                {type = "HeadOnDialog", params = {messages = {{text = "Hello!"}}}},
                {type = "BuildSomething", params = {userDesc = "a red table"}},
            },
            coin_reward = 10
        },
        {
            name = "quest2",
            title = "Second Quest",
            description = "This is the second quest",
            tasks = {
                {type = "HeadOnDialog", params = {messages = {{text = "Well done!"}}}},
                {type = "BuildBlockTemplate", params = {filename = "blocktemplates/chair.bmax",}},
            },
            coin_reward = 20
        }
    },
});
copilot:AddTask(task, {autoStart = true});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua")
NPL.load("(gl)script/ide/System/Util/HttpWrapper.lua")
NPL.load("(gl)script/ide/Json.lua")

local HttpWrapper = commonlib.gettable("System.Util.HttpWrapper")
local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore")
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local PersonalPageTutorial = commonlib.inherit(
	CopilotTaskBase,
	commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.PersonalPageTutorial")
)

PersonalPageTutorial.name = "PersonalPageTutorial"

function PersonalPageTutorial:ctor()
	self.quests = {}
	self.currentQuestIndex = 1
	self.finishedQuests = {}
	self.pagename = "PersonalPageTutorial" -- Default pagename for saving progress
end

function PersonalPageTutorial:Init(copilot, params)
	PersonalPageTutorial._super.Init(self, copilot, params)

	-- Support custom pagename for saving progress
	if self.params.pagename then
		self.pagename = self.params.pagename
	end

	-- Support direct quests array or URL
	if self.params.quests then
		-- Direct quests provided
		if #self.params.quests == 0 and (self.params.quests.name or self.params.quests.type) then
			self.quests = { self.params.quests }
		else
			self.quests = self.params.quests
		end
		self.configUrl = nil
	else
		-- Load from URL (default or provided)
		self.configUrl = self.params.url or "config/Aries/creator/PersonalPageTutorial.json"
	end

	if self.params.taskData then
		self.taskData = self.params.taskData
	end

	if self.params.category then
		self.category = self.params.category
	end

	if self.params.runningTaskKey then
		self.runningTaskKey = self.params.runningTaskKey
	end

	self.restart = self.params.restart or false
	
	-- Check if we need preparation phase
	if self.params.needPrepare ~= nil then
		self.needPrepare = self.params.needPrepare
	end
	
	return self
end

function PersonalPageTutorial:GetCopilotMgr()
	if not self.copilotMgr then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotManager.lua");
		local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
		self.copilotMgr = CopilotManager.GetInstance()
	end
	return self.copilotMgr
end

function PersonalPageTutorial:DoPrepare(copilot)
	-- If task is already accepted (from saved progress), skip preparation
	if self.isAccepted then
		return true;
	end

	-- 1. Load Config (only if not using direct quests)
	if self.configUrl and (not self.quests or #self.quests == 0) then
		self:LoadConfig()
	end

	if not self.quests or #self.quests == 0 then
		LOG.std(nil, "warn", "PersonalPageTutorial", "No quests found")
		self.state = self.STATE_FAILED
		return
	end

	self:LoadProgress()

	self.isConfirmed = false;
	local startTime = os.time();
	local lastSayTime = 0;
	local showHeadTipTime = 5; -- Show head tip after 5 seconds of being near
	local isNearStartTime = nil;
    
    -- Request global permission to start active guidance
    local hasPermission = false;
    
    -- Reset preparing active state on start
    self.isPreparingActive = false;
	
	local nextMoveTime = 0;
	local isHeadTipShown = false;
	local activeStartTime = 0;
	local MAX_ACTIVE_TIME = 8;
	local CopilotManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotManager");
	
	while not self.isConfirmed do
		if self:CheckStopRequested() then
			self.isPreparingActive = false;
			self:GetCopilotMgr():ReleasePreparePermission(copilot);
			return false;
		end
        
		local player = GameLogic.EntityManager.GetPlayer();
		if player and copilot:GetEntity() then
			local px,py,pz = player:GetBlockPos()
			local disSq = copilot:GetEntity():DistanceSqTo(px,py,pz);
			local curTime = commonlib.TimerManager.GetCurrentTime() / 1000;
			
			-- 1. Passive State: Always update HeadTip based on distance
			if disSq <= 25 and not self.isPreparingActive then
				 if not isHeadTipShown then
					 self:ShowHeadTip(true);
					 isHeadTipShown = true;
				 end
			end

			-- 2. Request Active Permission
			if not hasPermission then
				if self:GetCopilotMgr():RequestPreparePermission(copilot) then
					hasPermission = true;
					self.isPreparingActive = true;
					activeStartTime = os.time();
				end
			end
			
			-- 3. Active State Logic
			if hasPermission then
				if disSq > 15*15 then
					isNearStartTime = nil;
					hasPermission = false;
					self.isPreparingActive = false;
					self:GetCopilotMgr():ReleasePreparePermission(copilot);
				elseif disSq > 25 then
					if curTime > nextMoveTime then
						if math.random() > 0.3 then
							self:WalkTo(px, py, pz, 2, true);
						end
						nextMoveTime = curTime + 2 + math.random() * 3;
					end
					isNearStartTime = nil;
					lastSayTime = 0;
					self:ShowHeadTip(false);
					isHeadTipShown = false;
				else
					copilot:SetFacing(copilot:GetEntity():GetFacing()); -- Stop rotation?
					if not isNearStartTime then
						isNearStartTime = os.time();
					end
					
					-- Say message periodically
					if os.time() - lastSayTime > 10 then
						self:ShowHeadTip(false);
						isHeadTipShown = false;
						self:Say(L"我身上有任务，请点击我！", 3);
						lastSayTime = os.time();
					end
					
					-- Show head tip after some time
					if not isHeadTipShown and (os.time() - isNearStartTime > showHeadTipTime) then
						self:ShowHeadTip(true);
						isHeadTipShown = true;
					end
					
					-- Delay next move check to avoid jitters
					nextMoveTime = curTime + 1;
				end
				
				if (os.time() - activeStartTime > MAX_ACTIVE_TIME) then
					hasPermission = false;
					self.isPreparingActive = false;
					self:GetCopilotMgr():ReleasePreparePermission(copilot);
				end
			end
		end
		
		copilot:Wait(0.5);
	end
	
	self:ShowHeadTip(false); -- Hide head tip when confirmed
    self.isPreparingActive = false;
	return true;
end

function PersonalPageTutorial:FinishPreparation()
	if self.state == self.STATE_PREPARING then
		self.isConfirmed = true;
		self:Say(L"任务开始！", 2);
	else
		PersonalPageTutorial._super.FinishPreparation(self);
	end
end

function PersonalPageTutorial:GetTaskName()
	return "PersonalPageTutorial"
end

function PersonalPageTutorial:ExecuteTask(copilot)
	-- 1. Load Config (only if not using direct quests)
	if self.configUrl and (not self.quests or #self.quests == 0) then
		self:LoadConfig()
	end

	if not self.quests or #self.quests == 0 then
		LOG.std(nil, "warn", "PersonalPageTutorial", "No quests found")
		self.state = self.STATE_FAILED
		return
	end

	self:LoadProgress()

	self:DetermineNextQuest()
	if self.currentQuestIndex > #self.quests then
		copilot:Say(L("恭喜你，所有教程任务都已完成！"))
		self.state = self.STATE_COMPLETED
		return
	end

	local maxIterations = #self.quests * 2 -- Safety limit to prevent infinite loop
	local iterations = 0
	while self.currentQuestIndex <= #self.quests do
		iterations = iterations + 1
		if iterations > maxIterations then
			LOG.std(nil, "error", "PersonalPageTutorial", "Max iterations exceeded, breaking loop to prevent hang")
			self.state = self.STATE_FAILED
			return
		end

		if self:CheckStopRequested() then
			return
		end
		self:CheckPaused()
		local quest = self.quests[self.currentQuestIndex]
		if not self.finishedQuests[quest.name] then
			local taskResult, taskNum = self:RunQuest(quest)
			if taskResult then
				local successCount = 0
				for _, result in pairs(taskResult) do
					if result then
						successCount = successCount + 1
					end
				end
				local failNum = taskNum - successCount
				if failNum < 1 then
					self.finishedQuests[quest.name] = true
					self:SaveProgress()
					if self.isLoadConfig then
						local isTaskRecorded = false
						for _, t in ipairs(self.currentFinishedTasks) do
							if t.name == quest.name then
								isTaskRecorded = true
								break
							end
						end
						if not isTaskRecorded then
							self.currentFinishedTasks[#self.currentFinishedTasks + 1] = {taskIndex=self.currentQuestIndex,name=quest.name,finished=true}
							self:GiveReward(quest)
							self:SaveSkillBookData()
						end
					else
						self:GiveReward(quest)
					end
				else
					GameLogic:AddBBS(nil, string.format(L("还有%d个任务未完成，请检查任务是否正确。"), failNum))
				end
			end
		end
		self.currentQuestIndex = self.currentQuestIndex + 1
		copilot:Wait(0.5)
	end
	copilot:Say(L"所有任务已结束！",5)
	
	-- Set task result with completion info
	self:SetTaskResult({
		success = true,
		finishedQuests = self.finishedQuests,
		totalQuests = #self.quests,
		currentFinishedTasks = self.currentFinishedTasks,
	});
	
	self.state = self.STATE_COMPLETED
	self:CheckAndSaveLevelProgress()
end

function PersonalPageTutorial:LoadConfig(callback)
	local url = self.configUrl
	local content = nil

	if url:match("^http") then
		-- Remote file
		local isDone = false
		System.os.GetUrl(url, function(err, msg, response)
			local runningTask = self.copilot:GetRunningTask()
			if not runningTask or runningTask.taskInstance ~= self then
				return
			end

			if err == 200 then
				content = response
			end

			isDone = true
			-- Only resume if we are suspended and not currently running inside the coroutine
			if self.co and coroutine.status(self.co) == "suspended" and coroutine.running() ~= self.co then
				self.copilot:Resume()
			end
		end)

		if not isDone then
			self.copilot:Yield()
		end

		if self:CheckStopRequested() then
			return
		end
	else
		-- Local file
		local file = ParaIO.open(url, "r")
		if file:IsValid() then
			content = file:GetText(0, -1)
			file:close()
		end
	end

	if content then
		local data = commonlib.totable(content)
		local all_quests = data.quest or data.quests or {}
		local levels = data.levels or {}
		self.maxLevel = #levels
		self.isLoadConfig = true
		-- TODO: Get current level from player skill or config
		local taskData = self.taskData or nil
		local levelData = taskData and taskData.level or nil
		local task = taskData and taskData.task or nil
		local cur_level = levelData and levelData.level or nil
		local tasksData = levelData and levelData.tasks or nil
		local cur_task_name = task and task.name or nil
		local category = levelData and levelData.category
			or (self.category and self.category ~= "" and self.category)
		
		local current_level = 1
		local loadedPageData = nil
		local last_task_name = nil

		if not cur_level and self.runningTaskKey and self.runningTaskKey ~= "" then
			loadedPageData = self.copilot:LoadPageData("my_skill_book", self.runningTaskKey)
			if type(loadedPageData) == "table" then
				if not category or category == ""  or category == nil then
					category = loadedPageData.currentCategory
				end
			end
		end

		if not category or category == "" then
			category = "fishing"
		end

		self.category = category
		self:LoadSkillBookData()

		if cur_level then
			current_level = cur_level
			self.currentLevel = current_level
		elseif self.runningTaskKey and self.runningTaskKey ~= "" then
			if type(loadedPageData) == "table" then
				current_level = loadedPageData.currentLevel or 1
				last_task_name = loadedPageData.lastTaskName or nil
				self.currentLevel = current_level
			end
		else
			current_level = self.currentLevel
		end
		
		local currentLevelQuests = {}
		local questMap = {}
		for _, q in ipairs(all_quests) do
			if q.name then
				questMap[q.name] = q
			end
		end

		if cur_task_name ~= nil and cur_task_name ~= "" and tasksData then
			for _, taskInfo in ipairs(tasksData) do
				table.insert(currentLevelQuests, questMap[taskInfo.name])
			end
			-- Move the target task to the front, preserving the order of others
			local targetIndex = nil
			for i, quest in ipairs(currentLevelQuests) do
				if quest.name == cur_task_name then
					targetIndex = i
					break
				end
			end

			if targetIndex and targetIndex > 1 then
				local targetQuest = table.remove(currentLevelQuests, targetIndex)
				table.insert(currentLevelQuests, 1, targetQuest)
			end
			last_task_name = cur_task_name
		else
			-- Find level config for current level
			local levelConfig = nil
			for _, level_data in ipairs(levels) do
				if level_data.level == current_level and level_data.category == category then
					levelConfig = level_data
					break
				end
			end

			if levelConfig and levelConfig.tasks then
				-- Populate currentLevelQuests based on task names in level config
				for _, taskInfo in ipairs(levelConfig.tasks) do
					local questData = questMap[taskInfo.name]
					if questData then
						table.insert(currentLevelQuests, questData)
					end
				end
				if last_task_name and last_task_name ~= "" then
					for i, quest in ipairs(currentLevelQuests) do
						if quest.name == last_task_name then
							table.remove(currentLevelQuests, i)
							table.insert(currentLevelQuests, 1, quest)
							break
						end
					end
				end
			elseif #levels == 0 and #all_quests > 0 then
				-- If no levels defined, use all quests (fallback to flat list)
				currentLevelQuests = all_quests
			end
		end
		if #currentLevelQuests > 0 then
			self.quests = currentLevelQuests
		elseif data.allQuests then
			self.quests = data.allQuests
		elseif #self.quests == 0 and #all_quests > 0 then
			-- Fallback if self.quests is still empty
			self.quests = all_quests
		end

		if data.pagename ~= "" and data.pagename ~= nil then
			self.pagename = data.pagename
		end
		if data.restart ~= nil then
			self.restart = data.restart
		end
		if
			not loadedPageData
			or loadedPageData.currentLevel ~= current_level
			or loadedPageData.currentCategory ~= category
		then
			if self.runningTaskKey then
				self.copilot:SavePageData(
					"my_skill_book",
					self.runningTaskKey,
					{ currentLevel = current_level, currentCategory = category, lastTaskName = last_task_name },
					true
				)
			end
		end
		if callback and type(callback) == "function" then
			callback()
		end
	end
end

function PersonalPageTutorial:LoadProgress()
	if not self.restart then
		self.finishedQuests = self.copilot:LoadPageData(self.pagename, "finishedQuests") or {}
	else
		self.finishedQuests = {}
	end
end

function PersonalPageTutorial:SaveProgress()
	self.copilot:SavePageData(self.pagename, "finishedQuests", self.finishedQuests, true)
end

function PersonalPageTutorial:DetermineNextQuest()
	for i, quest in ipairs(self.quests) do
		if not self.finishedQuests[quest.name] then
			self.currentQuestIndex = i
			return
		end
	end
	self.currentQuestIndex = #self.quests + 1
end

function PersonalPageTutorial:AskUserToResume(quest)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/HeadOnDialog.task.lua")
	local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.HeadOnDialog")

	local text = string.format(L("准备好开始任务【%s】了吗？"), quest.title or quest.name)
	local dialog = HeadOnDialog:new():Init(self.copilot, {
		messages = {
			{
				text = text,
				button = {
					{ L("开始任务"), name = "start", default = true },
					{ L("查看列表"), name = "view_list" },
					{ L("稍后再说"), name = "cancel" },
				},
			},
		},
	})

	self:StartSubTask(dialog)
	return dialog:GetLastAnswer()
end

function PersonalPageTutorial:ShowHeadTip(bShow)
	local entity = self.copilot.entity
	local imageUrl = ""
	local baseUrl = "https://qiniu-public.keepwork.com/paracraft-cdn-resource/Texture/Aries/Paracraft/Mod/MaiSi/"
	if not bShow then
		imageUrl = ""
	else
		if not self.isAccepted and (self.state == self.STATE_RUNNING or self.state == self.STATE_PREPARING) then
			-- 进行中未接受的任务-- 黄色感叹号
			imageUrl = "Texture/Aries/Paracraft/Mod/MaiSi/gold_exclamation_point.png"
		end
	end

	local mcml = [[
    <pe:mcml>
        <div style="width:200px; margin-left: -100px; margin-top: -80dpx; color: #ffffff;">
            <pe:if condition="<%=headStatusImageUrl~=''and headStatusImageUrl~=nil%>">
                <div align="center" style="width:60px; height:60px; background: url(https://qiniu-public.keepwork.com/paracraft-cdn-resource/Texture/Aries/Paracraft/Mod/MaiSi/quan.png);">
                    <img src="<%=headStatusImageUrl%>" style="width:40px; height:40px; margin-left: 10px;margin-top: 10px;" />
                </div>
            </pe:if>
            </div>
        </div>
    </pe:mcml>
        ]]
	if imageUrl == "" then
		entity:SetHeadOnDisplay(nil)
	else
		entity:SetHeadOnDisplay({
			url = commonlib.ParseXmlToString(mcml),
			pageGlobalTable = { headStatusImageUrl = imageUrl },
		})
	end
	if self.on_accpeted_callback then
		GameLogic.GetCodeGlobal():UnregisterTextEvent("on_accepted_personal_turorial_task", self.on_accpeted_callback)
		self.on_accpeted_callback = nil
	end
	if bShow then
		self.on_accpeted_callback = function(_, msg)
			self:OnAcceptedHandle(msg.msg)
		end
		GameLogic.GetCodeGlobal():RegisterTextEvent("on_accepted_personal_turorial_task", self.on_accpeted_callback)
	end
end

function PersonalPageTutorial:OnAcceptedHandle(msg)
	local entity = self.copilot.entity
	if entity and entity.name == msg.name then
		self.isAccepted = msg.isAccepted
		if self.isAccepted then
			if self.on_accpeted_callback then
				GameLogic.GetCodeGlobal()
					:UnregisterTextEvent("on_accepted_personal_turorial_task", self.on_accpeted_callback)
				self.on_accpeted_callback = nil
			end
			self:ShowHeadTip()
		end
	end
end

function PersonalPageTutorial:OpenTutorialList()
	self:Say(L("正在打开任务列表..."))
	-- Try to open the page if it exists, or show a message
	local Page = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Page")
	if Page and Page.Show then
		-- This is just a guess at how to open a page, might need adjustment
		-- Page.Show("PersonalPageTutorialList", {url="..."})
		GameLogic.RunCommand("/open PersonalPageTutorialList")
	end
end

function PersonalPageTutorial:RunQuest(quest)
	local tasks = quest.tasks
	if not tasks and quest.type then
		tasks = { quest }
	end

	if not tasks then
		return
	end

	self:Say(string.format(L("任务开始：%s"), quest.title or quest.name or ""))
	if quest.description then
		self:Say(quest.description)
	end
	local taskNum = #tasks
	local taskResult = {}
	for taskIndex, taskData in ipairs(tasks) do
		if self:CheckStopRequested() then
			return
		end
		self:CheckPaused()

		local taskType = taskData.type
		local taskClassPath =
			string.format("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/%s.task.lua", taskType)

		NPL.load(taskClassPath)
		local TaskClass =
			commonlib.gettable(string.format("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.%s", taskType))

		if TaskClass then
			local subTask = TaskClass:new():Init(self.copilot, taskData.params)
			self.currentSubTask = subTask
			local success = self:StartSubTask(subTask)
			local result = self.currentSubTask:GetTaskResult()
			self.currentSubTask = nil
			taskResult[taskIndex] = result
			if not success then
				LOG.std(nil, "warn", "PersonalPageTutorial", "Subtask failed: %s", taskType)
			end
		else
			taskResult[taskIndex] = false
			LOG.std(nil, "error", "PersonalPageTutorial", "Unknown task type: %s", taskType)
			self:Say(string.format(L("未知任务类型：%s"), taskType))
		end
	end
	return taskResult, taskNum
end

function PersonalPageTutorial:GiveReward(quest)
	if quest.coin_reward and quest.coin_reward > 0 then
		GameLogic.MiniGameMgr:AchieveBean(tonumber(quest.coin_reward), function(result)
			if result and result.beanNum and result.beanNum > 0 then
				self:Say(string.format(L("任务完成！获得 %d 金币奖励！"), result.beanNum))
			else
				LOG.std(nil, "warn", "PersonalPageTutorial", "Failed to achieve bean reward: %s", commonlib.serialize(result))
			end
		end, true)
	else
		self:Say(L("任务完成！"))
	end
end

function PersonalPageTutorial:OnRemove()
	if self.currentSubTask then
		self.currentSubTask:Stop()
		if self.currentSubTask.OnRemove then
			self.currentSubTask:OnRemove()
		end
	end
	PersonalPageTutorial._super.OnRemove(self)
end

function PersonalPageTutorial:OnPauseByUser()
	if self.currentSubTask then
		self.currentSubTask:OnPauseByUser()
	end
end

function PersonalPageTutorial:GetActionButtons(buttons)
	buttons = PersonalPageTutorial._super.GetActionButtons(self, buttons) or {}
	--buttons = buttons or {}
	table.insert(buttons, { text = L("所有任务"), name = "all_quests" })
	return buttons
end

function PersonalPageTutorial:OnClickActionButton(actionName)
	if actionName == "all_quests" then
		self:Say(L("敬请期待！"))
	elseif actionName == "start" then
		self.copilot:StartTask(self.copilotTaskId)
	else
		-- Call parent class for other actions
		if actionName == "pause" then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua")
			local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide")
			if CopilotGUIGuide then
				CopilotGUIGuide.Stop()
			end
		end
		PersonalPageTutorial._super.OnClickActionButton(self, actionName)
	end
end

function PersonalPageTutorial:ReceiveData(data)
	if self.currentSubTask ~= nil and self.currentSubTask.ReceiveData then
		self.currentSubTask:ReceiveData(data)
	end
end

function PersonalPageTutorial:CheckAndSaveLevelProgress()
	if self.runningTaskKey then
		self.copilot:SavePageData("my_skill_book", self.runningTaskKey, {}, true)
	end
	if not self.isLoadConfig then
		return
	end
	local allFinished = true
	if self.quests then
		for _, quest in ipairs(self.quests) do
			if not self.finishedQuests[quest.name] then
				allFinished = false
				break
			end
		end
	end

	if allFinished then
		local isLevelRecorded = false
		local curLevelIndex = -1
		for index, l in ipairs(self.finishedLevels) do
			if l.level == self.currentLevel and l.category == self.category then
				isLevelRecorded = true
				curLevelIndex = index
				break
			end
		end
		
		if not isLevelRecorded then
			self.finishedLevels[#self.finishedLevels + 1] = {level=self.currentLevel, category=self.category, finished=true, finishedCount=1,finishedTime=os.time()}
		elseif curLevelIndex > 0 then
			self.finishedLevels[curLevelIndex].finishedCount = self.finishedLevels[curLevelIndex].finishedCount + 1
			self.finishedLevels[curLevelIndex].finishedTime = os.time()
		end
		
		self.currentLevel = self.currentLevel + 1
		if self.maxLevel and self.currentLevel > self.maxLevel then
			self.currentLevel = self.maxLevel
		end
		self.currentFinishedTasks = {}
		self:SaveSkillBookData()
	end
end

function PersonalPageTutorial:LoadSkillBookData()
	if not self.category then
		return
	end
	local data = self.copilot:LoadPageData("my_skill_book", self.category) or {}
	self.awardIndex = data.awardIndex
	self.currentLevel = data.currentLevel or 1
	self.currentFinishedTasks = data.currentFinishedTasks or {}
	self.finishedLevels = data.finishedLevels or {}
	if not self.awardIndex then
		for _, level in ipairs(self.finishedLevels) do
			if level.level == 1 and level.finished then                 
				self.awardIndex = 1
				break
			end
		end
	end
end

function PersonalPageTutorial:SaveSkillBookData()
	if not self.category then
		return       
	end
	local data = {
		awardIndex = self.awardIndex,
		currentLevel = self.currentLevel,
		currentFinishedTasks = self.currentFinishedTasks,
		finishedLevels = self.finishedLevels,
	}
	self.copilot:SavePageData("my_skill_book", self.category, data, true)
end
