--[[
Title: MakeNameForCheckpoint Task
Author(s): LiXizhi
Date: 2025/11/20
Desc: A task that prompts the user to name a checkpoint (homeland/userpoint).
This task checks if the checkpoint has a default name (未命名) and if so,
prompts the user to give it a proper name using a dialog with text input.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/MakeNameForCheckpoint.task.lua");
local MakeNameForCheckpoint = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.MakeNameForCheckpoint");

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
local copilot = CopilotDragonPet.GetInstance()

-- Create and add the naming task
local task = MakeNameForCheckpoint:new():Init(copilot, {
	userPoint = nil,  -- optional, will auto-detect if not provided
});

copilot:AddTask(task, {
	name = L"命名家园",
	description = L"提醒主人给家园命名",
	enabled = true,
	autoStart = true
});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/HeadOnDialog.task.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");
local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.HeadOnDialog");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");

local MakeNameForCheckpoint = commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.MakeNameForCheckpoint"));

MakeNameForCheckpoint.name = "MakeNameForCheckpoint"

-- Constructor
function MakeNameForCheckpoint:ctor()
	MakeNameForCheckpoint._super.ctor(self);
	self.autoRemoveWhenStopped = true;
end

-- Get task name for logging
function MakeNameForCheckpoint:GetTaskName()
	return "MakeNameForCheckpoint";
end

-- Generate a random name for homeland by combining 3 sections
-- @return string: a randomly generated homeland name
function MakeNameForCheckpoint:GenerateRandomName()
	-- Section 1: Adjectives/Descriptions (10 options)
	local section1 = {
		L"温馨", L"梦想", L"快乐", L"神秘", L"星光",
		L"彩虹", L"幸福", L"魔法", L"欢乐", L"阳光"
	};
	
	-- Section 2: Descriptive words (10 options)
	local section2 = {
		L"小", L"大", L"新", L"古", L"金",
		L"银", L"翠", L"青", L"碧", L"紫"
	};
	
	-- Section 3: Place nouns (10 options)
	local section3 = {
		L"屋", L"家", L"居", L"院", L"城",
		L"堡", L"园", L"舍", L"阁", L"轩"
	};
	
	-- Randomly select one word from each section
	local part1 = section1[math.random(1, #section1)];
	local part2 = section2[math.random(1, #section2)];
	local part3 = section3[math.random(1, #section3)];
	
	-- Combine the three parts
	local name = part1 .. part2 .. part3;
	
	return name;
end

-- Main task execution logic (runs in coroutine)
-- @param copilot: reference to the EasyPetCopilot instance
function MakeNameForCheckpoint:ExecuteTask(copilot)
	local params = self.params or {};
	
	-- Get userPoint from params or auto-detect
	local userPoint = params.userPoint or EasyEditableWorld.CreateGetUserPoint(false);
	
	if not userPoint then
		LOG.std(nil, "warn", "MakeNameForCheckpoint", "No userPoint found");
		self.state = self.STATE_FAILED;
		return;
	end
	
	-- Check if task was stopped
	if self:CheckStopRequested() then
		return;
	end
	
	-- Get the command text from userPoint
	local text = userPoint:GetCommand() or "";
	local desc = text:match("^(.-)\n") or text;
	
	-- Check if the name is the default "未命名"
	if desc ~= L"未命名" then
		LOG.std(nil, "info", "MakeNameForCheckpoint", "Checkpoint already has a name: %s", desc);
		-- Already named, no need to continue
		return;
	end
	
	-- Check if task is paused
	self:CheckPaused();
	
	local answer = nil;
	local isNamed = false;
	
	-- Loop until we get a valid name
	while not isNamed do
		-- Check if task was stopped during loop
		if self:CheckStopRequested() then
			return;
		end
		
		-- Check if task is paused
		self:CheckPaused();
		
		-- Ask for name input
		local btnIndex, allTextResults;
		answer, btnIndex, allTextResults = copilot:Ask(L"主人，给这个家园起个名字吧~", {{"", type="text"}, {L"确定", default=true}, {L"帮我起个名字"}});
		
		if btnIndex == 3 then
			-- User wants help from the start, enter random name selection
			LOG.std(nil, "info", "MakeNameForCheckpoint", "User requested help naming from first question");
			local selectingRandomName = true;
			while selectingRandomName do
				-- Check if task was stopped
				if self:CheckStopRequested() then
					return;
				end
				
				-- Generate a random name
				local randomName = self:GenerateRandomName();
				LOG.std(nil, "info", "MakeNameForCheckpoint", "Random name suggested: %s", randomName);
				
				-- Ask if user likes this random name
				local randomChoice, randomChoiceIdx = copilot:Ask(string.format(L"这个名字怎么样：%s", randomName), {{L"就用这个", default=true}, L"换一个", L"我自己起"});
				
				if randomChoiceIdx == 1 then
					answer = randomName;
					isNamed = true;
					selectingRandomName = false;
					copilot:Say(string.format(L"好的主人，就叫它%s啦！", answer), 2);
					copilot:Wait(2);
				elseif randomChoiceIdx == 2 then
					-- Continue the loop to generate another random name
					LOG.std(nil, "info", "MakeNameForCheckpoint", "User wants another random name");
				else -- "我自己起"
					-- Exit random selection, go back to manual input
					selectingRandomName = false;
					copilot:Say(L"好呀，主人自己想一个吧~", 2);
					copilot:Wait(2);
				end
			end
		elseif type(answer) == "string" and answer ~= "" then
			-- Valid name provided, exit loop
			isNamed = true;
		else
			-- Empty name, offer options
			LOG.std(nil, "info", "MakeNameForCheckpoint", "Empty name provided, offering options");
			
			-- Check if task was stopped
			if self:CheckStopRequested() then
				return;
			end
			
			-- Ask user what they want to do
			local choice, choiceIdx = copilot:Ask(L"嗯...名字不能为空呢，要我帮你想一个吗？", {L"帮我起名", L"我再想想"});
			
			if choiceIdx == 1 then
				-- Enter random name selection loop
				local selectingRandomName = true;
				while selectingRandomName do
					-- Check if task was stopped
					if self:CheckStopRequested() then
						return;
					end
					
					-- Generate a random name using the function
					local randomName = self:GenerateRandomName();
					
					LOG.std(nil, "info", "MakeNameForCheckpoint", "Random name suggested: %s", randomName);
					
					-- Ask if user likes this random name
					local randomChoice, randomChoiceIdx = copilot:Ask(string.format(L"这个名字怎么样：%s", randomName), {{L"就用这个", default=true}, L"换一个", L"我自己起"});
					
					if randomChoiceIdx == 1 then
						answer = randomName;
						isNamed = true;
						selectingRandomName = false;
						copilot:Say(string.format(L"好的主人，就叫它%s啦！", answer), 2);
						copilot:Wait(2);
					elseif randomChoiceIdx == 2 then
						-- Continue the loop to generate another random name
						LOG.std(nil, "info", "MakeNameForCheckpoint", "User wants another random name");
					else -- "我自己起"
						-- Exit random selection, go back to manual input
						selectingRandomName = false;
						copilot:Say(L"好呀，主人自己想一个吧~", 2);
						copilot:Wait(2);
					end
				end
			else
				-- User wants to try again, continue loop
				LOG.std(nil, "info", "MakeNameForCheckpoint", "User chose to try naming again");
				copilot:Say(L"好的，主人再想一个名字吧~", 2);
				copilot:Wait(2);
			end
		end
	end
	
	-- Update the first line of the command with the new name
	if answer and answer ~= "" then
		local lines = {};
		for line in text:gmatch("[^\n]+") do
			table.insert(lines, line);
		end
		if #lines > 0 then
			lines[1] = answer;
		else
			table.insert(lines, answer);
		end
		local newText = table.concat(lines, "\n");
		userPoint:SetCommand(newText);
		userPoint:Refresh();
		-- Increment edit count for the world
		EasyEditableWorld:TriggerAutoSave();
		
		LOG.std(nil, "info", "MakeNameForCheckpoint", "Checkpoint renamed to: %s", answer);
		
		-- Say something to acknowledge the naming
		copilot:Say(string.format(L"记住了，这里就叫%s~", answer), 2);
		copilot:Wait(2);
	end
end
