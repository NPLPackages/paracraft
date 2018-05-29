--[[
Title: Command Actor
Author(s): LiXizhi
Date: 2014/3/28
Desc: movie actor related commands
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandActor.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["addactor"] = {
	name="addactor", 
	quick_ref="/addactor [npc|camera]", 
	desc=[[ add a new actor to the current active scene
/addactor			add a default npc entity to the current scene
/addactor npc		add a default npc entity to the current scene
/addactor camera	add a default camera entity to the current scene
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local word, cmd_text = CmdParser.ParseWord(cmd_text);
		word = word or "npc"

		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			if(word=="npc") then
				movieClip:CreateNPC();
			elseif(word=="camera") then
				movieClip:CreateCamera();
			end
		end
	end,
};



Commands["focus"] = {
	name="focus", 
	quick_ref="/focus [@playername]", 
	desc=[[ focus on a given player. if no player, the current player is used. 
/focus			: default to current player. 
/focus  @man	: focus on a player called man
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, x, y, z, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());

		if(playerEntity) then
			playerEntity:SetFocus();
		end
	end,
};


Commands["end"] = {
	name="end", 
	quick_ref="/end [output_number]", 
	desc=[[same as SetLastCommandResult to 15 and /return 15
usually used in a movieclip to end the current movie and fire an electric output.  usually used with /t like
/t 10 /end     end the movie block 2 seconds after it stops
/t 10 /end 1   end the movie block immediately after it stops
@param output_number: default to 15. if 1, it means immediate output. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(fromEntity and fromEntity.SetLastCommandResult) then
			local output;
			if(cmd_text and cmd_text~="" and cmd_text:match("^%d+$")) then
				output = tonumber(cmd_text);
			end

			fromEntity:SetLastCommandResult(output or 15);
		end
		return 15;
	end,
};


Commands["addkey"] = {
	name="addkey", 
	quick_ref="/addkey [text|time|tip|fadein|fadeout] [value]", 
	desc=[[ add a command based movieclip key to the current active movie clip
/addkey text this is movie subscript text
/addkey time			: use current time
/addkey time 1			: dark night
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		local name, cmd_text = CmdParser.ParseWord(cmd_text);

		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			local actor = movieClip:GetCommand(true);
			if(actor) then
				if(name=="text") then
					actor:AddKeyFrameOfText(cmd_text);
				elseif(name=="time") then
					local time, cmd_text = CmdParser.ParseInt(cmd_text);
					actor:AddKeyFrameOfTime(time or nil);
				elseif(name=="tip") then
					
				elseif(name=="fadein") then
				
				elseif(name=="fadeout") then
				
				end
			end
		end
	end,
};
