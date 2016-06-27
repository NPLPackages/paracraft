--[[
Title: Command Movie
Author(s): LiXizhi
Date: 2014/1/22
Desc: slash command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMovie.lua");
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


Commands["text"] = {
	name="text", 
	quick_ref="/text [-p] [-w] text", 
	desc=[[show movie text at bottom of the screen. 
/text -p user has to click in order to continue. if will pause the calling entity, and resume when closed.  
/text -w user must wait for text to finish and no way to advance to next time event. 
/text default mode is that entity is not paused, and user can click left button to fast continue to next time event. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);		
		local is_pause_entity, is_wait_mode;
		if(options and options.p and fromEntity) then
			is_pause_entity = true;
			fromEntity:Pause();
		end
		if(options and options.w and fromEntity) then
			is_wait_mode = true;
		end
			
		NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Mod/MovieText.lua");
		local MovieText = commonlib.gettable("MyCompany.Aries.Game.Mod.MovieText");
		MovieText.ShowPage(cmd_text, function(result)
			if(result == "click_screen") then
				-- user clicks screen to close the text
				if(not is_wait_mode and fromEntity) then
					fromEntity:SetTimeToNextEvent();
				end
			end	
			if(is_pause_entity) then
				fromEntity:Resume();
			end
		end);
	end,
};


Commands["movieclip"] = {
	name="movieclip", 
	quick_ref="/movieclip [-stop]", 
	desc=[[stops the current movie clip
e.g.
/movieclip -stop			:stop the current movie clip if any
/movieclip					:stop the current movie clip if any
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)

		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);		
		if(cmd_text == "" or (options and options.stop)) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
			local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
			MovieManager:SetActiveMovieClip(nil);
		end
	end,
};

Commands["moviecamera"] = {
	name="moviecamera", 
	quick_ref="/moviecamera [on|off]", 
	desc=[[enable or disable movie camera in the movieclip block or currently playing movieclip.
e.g.
/moviecamera on				: turn on movie camera. by default it is on 
/moviecamera off			: turn off movie camera. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(not fromEntity or not fromEntity:isa(EntityManager.EntityMovieClip)) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
			local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
			local movieclip = MovieManager:GetActiveMovieClip();
			if(movieclip) then
				fromEntity = movieclip:GetEntity();
			end
		end
		if(fromEntity and fromEntity:isa(EntityManager.EntityMovieClip)) then
			local use_camera;
			use_camera, cmd_text = CmdParser.ParseBool(cmd_text);		
			if(use_camera~=nil) then
				fromEntity:EnableCamera(use_camera);
			end
		end
	end,
};

Commands["movieoutputmode"] = {
	name="movieoutputmode", 
	quick_ref="/movieoutputmode [on|off]", 
	desc="enable or disable movie output mode. when enabled, chunks are never unloaded." , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local enabled;
		enabled, cmd_text = CmdParser.ParseBool(cmd_text);		
		GameLogic.options:EnableMovieOutputMode(enabled~=false);
	end,
};
