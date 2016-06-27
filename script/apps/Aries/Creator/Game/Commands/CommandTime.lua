--[[
Title: CommandTime
Author(s): LiXizhi
Date: 2014/2/23
Desc: time related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTime.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["t"] = {
	name="t", 
	quick_ref="/t [~][seconds] /othercmd", 
	desc=[[Execute a command after a given time relative to caller entity. 
Each entity can have a list of timed event and an internal time variable. 
When the entity is active, the time variable will advance in each frame and execute any timed event
This command can be used to add or remove timed event and the internal time variable.
/t ~2 /activate     :loop and activate the calling entity every 2 seconds
/t ~1 /tip hi
/t ~0 /t 0   :set time to 0
/t			 :clear all timed event
]], 
	-- this is tricky: disable compiler
	SetCompiler = function(self, compiler)
		self.cached_compiler = compiler;
	end,
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		fromEntity = fromEntity or EntityManager.GetPlayer();
		if(cmd_text and fromEntity) then
			local deltatime, time;
			deltatime, cmd_text = CmdParser.ParseDeltaInt(cmd_text);
			if(deltatime) then
				-- relative to the last one added
				local last = fromEntity:GetTimeEvent():last();
				if(last) then
					time = last:GetTime() + deltatime;
				else
					time = deltatime;
				end
			else
				-- absolute local time. 
				time, cmd_text = CmdParser.ParseInt(cmd_text);
			end
			if(time) then
				local cached_compiler = Commands["t"].cached_compiler;
				local cmd = cmd_text:match("/.*$");
				
				if(cmd) then
					fromEntity:AddTimeEvent(time, nil, function(entity, timedEvent)
						CommandManager:RunWithVariables(cached_compiler, cmd, entity);
					end);
				else
					fromEntity:SetTime(time);
				end
			else
				fromEntity:ClearTimeEvent();
			end
		end
	end,
};

Commands["pause"] = {
	name="pause", 
	quick_ref="/pause", 
	desc="pause any queued time event for the calling entity", 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		fromEntity = fromEntity or EntityManager.GetPlayer();
		if(fromEntity) then
			fromEntity:Pause();
		end
	end,
};

Commands["resume"] = {
	name="resume", 
	quick_ref="/resume", 
	desc="resume any queued time event for the calling entity", 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		fromEntity = fromEntity or EntityManager.GetPlayer();
		if(fromEntity) then
			fromEntity:Resume();
		end
	end,
};

Commands["advancetime"] = {
	name="advancetime", 
	quick_ref="/advancetime [~][time]", 
	desc=[[advancetime any queued time event for the calling entity
/advancetime       to next key frame time
/advancetime  1    to absolute time
/advancetime  ~1   add delta time
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		fromEntity = fromEntity or EntityManager.GetPlayer();
		if(fromEntity) then
			local deltatime, time;
			deltatime, cmd_text = CmdParser.ParseDeltaInt(cmd_text);
			if(deltatime) then
				-- relative to the last one added
				fromEntity:AdvanceTime(deltatime);
			else
				-- absolute local time. 
				time, cmd_text = CmdParser.ParseInt(cmd_text);
				if(time) then
					fromEntity:SetTime(time);
				else
					-- advance time to next key frame. 
					fromEntity:AdvanceTime();
				end
			end
		end
	end,
};