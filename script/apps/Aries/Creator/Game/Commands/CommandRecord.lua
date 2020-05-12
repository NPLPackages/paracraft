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

Commands["share"] = {
	name="share", 
	quick_ref="/share [10|30]", 
	desc="toggle sharing, [10] to record 10 seconds video, [30] to record 30 seconds" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local time, cmd_text = CmdParser.ParseInt(cmd_text);
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/VideoSharing.lua");
		local VideoSharing = commonlib.gettable("MyCompany.Aries.Game.Movie.VideoSharing");
		VideoSharing.ToggleRecording(time);
	end,
};