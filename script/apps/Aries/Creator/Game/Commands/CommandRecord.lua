--[[
Title: Command Recording
Author(s): LiXizhi
Date: 2014/5/15
Desc: recording related. output to different format. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandRecord.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

--[[ showvideo recorder
/recorder
]]
Commands["recorder"] = {
	name="recorder", 
	quick_ref="/recorder", 
	desc="show video recorder" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Movie/VideoRecorder.lua");
		MyCompany.Aries.Movie.VideoRecorder.Show();	
	end,
};

--[[ begin recording
]]
Commands["record"] = {
	name="record", 
	quick_ref="/record", 
	desc="toggle recording" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoRecorder.lua");
		local VideoRecorder = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoRecorder");
		VideoRecorder.ToggleRecording();
	end,
};