--[[
Title: HeadOnDialog Task
Author(s): LiXizhi
Date: 2025/11/17
Desc: A simple task that displays a sequence of short text messages using the copilot.
This task is useful for showing tutorials, introductions, or storytelling sequences.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/HeadOnDialog.task.lua");
local HeadOnDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.HeadOnDialog");

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua");
local CopilotDragonPet = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotDragonPet");
local copilot = CopilotDragonPet.GetInstance()

-- Create and add a task with a sequence of messages
local task = HeadOnDialog:new():Init(copilot, {
    messages = {
        {text = L"你好！欢迎来到Paracraft！", duration = 3, button = L"好的", speak = true},
        {text = L"我是你的建造助手", duration = 2, button = L"继续", speak = false},
		{text = L"给你的世界起个名字吧", button = {{"", type="text"}, L"确定"}, speak = false},
        {text = L"让我们一起创造精彩的世界吧！", duration = 3, speak = true},
    },
    -- Optional: delay between messages (in seconds), default is 0.5
    delayBetweenMessages = 0.5,
});

-- Message properties:
--   text: (required) The message text to display
--   duration: (optional) Duration to display the message in seconds, default is 2
--   button: (optional) If provided, user must click this button to continue
--   speak: (optional) If true, text will be spoken with text-to-speech (default voice), default is false/nil

copilot:AddTask(task, {
    name = "Welcome Message",
    description = "Show welcome messages to the user",
    enabled = true,
    autoStart = true
});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotTaskBase.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local CopilotTaskBase = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.CopilotTaskBase");

local HeadOnDialog = commonlib.inherit(CopilotTaskBase, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.HeadOnDialog"));

HeadOnDialog.name = "HeadOnDialog"

-- Constructor
function HeadOnDialog:ctor()
	HeadOnDialog._super.ctor(self);
	self.messages = {};
	self.delayBetweenMessages = 0.5; -- default delay between messages
	self.autoRemoveWhenStopped = true;
end

-- Get task name for logging
function HeadOnDialog:GetTaskName()
	return "HeadOnDialog";
end

function HeadOnDialog:GetLastAnswer()
	return self.lastAnswer, self.lastBtnIndex, self.allTextResults;
end

-- Main task execution logic (runs in coroutine)
-- @param copilot: reference to the EasyPetCopilot instance
function HeadOnDialog:ExecuteTask(copilot)
	local params = self.params or {};
	
	-- Get messages from params
	local messages = params.messages or {};
	if #messages == 0 then
		LOG.std(nil, "warn", "HeadOnDialog", "No messages provided for HeadOnDialog task");
		self.state = self.STATE_FAILED;
		return;
	end
	
	-- Get delay between messages
	local delayBetweenMessages = params.delayBetweenMessages or self.delayBetweenMessages;
	
	-- Iterate through each message
	for i, msgData in ipairs(messages) do
		-- Check if task was stopped
		if self:CheckStopRequested() then
			return;
		end
		
		-- Check if task is paused
		self:CheckPaused();
		
		-- Get message properties
		local text = msgData.text or msgData;
		local duration = msgData.duration or 3;
		local button = msgData.button;
		local speak = msgData.speak;
		
        -- face player
        copilot:TurnTo();

		-- Speak the text if requested (text-to-speech)
		if speak then
			copilot:PlayText(text);
		end
		
		-- Display the message with optional button
		if button then
			-- If button is provided, use Ask() to wait for user click
			local buttons = type(button) == "string" and {{button, default=true}} or button;
			local answer, btnIndex, allTextResults = copilot:Ask(text, buttons);
			self.lastAnswer = answer; -- store the last answer in the task instance
			self.lastBtnIndex = btnIndex;
			self.allTextResults = allTextResults;
		else
			-- Otherwise use normal Say() behavior
			copilot:Say(text, duration);
		end
		
		-- Wait for the message duration plus delay before next message
		if i < #messages then
			if not button then
				-- Only wait if there's no button (button already waits for user)
				copilot:Wait(duration + delayBetweenMessages);
			else
				-- With button, just wait for the delay between messages
				copilot:Wait(delayBetweenMessages);
			end
		else
			-- For the last message, wait for duration only if no button
			if not button then
				copilot:Wait(duration);
			end
		end
	end
	
	-- Set task result with last answer info
	self:SetTaskResult({
		success = true,
		lastAnswer = self.lastAnswer,
		lastBtnIndex = self.lastBtnIndex,
		allTextResults = self.allTextResults,
	});
end
