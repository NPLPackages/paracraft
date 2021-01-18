--[[
Title: CommandQuest
Author(s): LiXizhi
Date: 2016/1/20
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandQuest.lua");
-------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");


Commands["macro"] = {
	name="macro", 
	quick_ref="/macro [record|play|stop] [-i|interactive] [-r|relative] [-a|autoplay] [-nohelp] [-1x|2x|4x]", 
	desc=[[record user actions to clipboard and then playback from current clipboard. 
@param i|interactive: we will automatically insert trigger macros
@param r|relative: play macros relative to current player's block position. 
@param a|autoplay: auto play mode on
@param nohelp: play without help text
@param 1x|2x|4x: play speed, default to 1x. 
e.g.
/macro    toggle recording mode
/macro record -i
/macro record
/macro play
/macro play -r
/macro play -r -autoplay
/macro play -r -nohelp
/macro play -r -a -4x
/macro stop
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local name, options;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		
		local isInteractive = false;
		local isRelative = false;
		local isAutoPlay = false;
		local nHelpLevel = 1;
		local playSpeed = 1;
		if(options) then
			if(options.i or options.interactive) then
				isInteractive = true;
			end
			if(options.r or options.relative) then
				isRelative = true;
			end
			if(options.a or options.autoplay) then
				isAutoPlay = true;
			end
			if(options.nohelp) then
				nHelpLevel = 0;
			end
			if(options["1x"]) then
				playSpeed = 1;
			elseif(options["2x"]) then
				playSpeed = 2;
			elseif(options["4x"]) then
				playSpeed = 4;
			end
		end
		
		local function StartRecord()
			GameLogic.Macros.SetInteractiveMode(isInteractive);
			GameLogic.Macros:BeginRecord()
			NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroRecorder.lua");
			local MacroRecorder = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroRecorder");
			MacroRecorder.ShowPage();
		end
		
		if(name == "record") then
			StartRecord()
		elseif(name == "stop") then
			GameLogic.Macros:Stop();
		elseif(name == "play") then
			local x, y, z;
			if(isRelative) then
				x, y, z = GameLogic.EntityManager.GetPlayer():GetBlockPos();
			end
			GameLogic.Macros.SetPlayOrigin(x, y, z)
			GameLogic.Macros.SetAutoPlay(isAutoPlay);
			GameLogic.Macros.SetHelpLevel(nHelpLevel);
			GameLogic.Macros.SetPlaySpeed(playSpeed);
			
			GameLogic.Macros:Play();
		elseif(not name or name == "") then
			if(GameLogic.Macros:IsRecording()) then
				GameLogic.Macros:Stop()
			else
				StartRecord()
			end
		end
	end,
};
