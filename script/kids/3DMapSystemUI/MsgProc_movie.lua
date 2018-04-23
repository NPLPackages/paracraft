--[[
Title: moviemessage processor
Author(s): LiXizhi
Date: 2007/11/11
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_movie.lua");
Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Pause, obj=obj, obj_params=obj_params})
------------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemUI/Movie/Recorder.lua");

-- scene:object window handler
function Map3DSystem.OnMovieMessage(window, msg)
	if(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Pause) then
		-----------------------------------------------
		-- pause a movie actor, the actor may be recording or playing before paused
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent ~= nil) then
				agent:Pause();
				Map3DSystem.ShowHeadOnDisplay(true, obj, "暂停:"..Map3DSystem.GetHeadOnText(obj));
			end
		end	
		
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Stop) then
		-----------------------------------------------
		-- stop a movie actor: it is pause and rewind
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent ~= nil) then
				agent:Pause();
				agent:Rewind();
				Map3DSystem.ShowHeadOnDisplay(true, obj, "停止:"..Map3DSystem.GetHeadOnText(obj));
			end
		end		
		
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Record) then
		-----------------------------------------------
		-- begin recording the action of an actor from its current time cursor
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent == nil) then
				agent = Map3DSystem.Movie.Recorder.agent:new{name=obj_params.name};
				Map3DSystem.Movie.Recorder.AddAgent(agent);
				--_guihelper.MessageBox(obj_params.name.." is added to recording\n");
			end
			if(agent:IsPaused()) then
				agent:Record();
				obj:GetAttributeObject():SetDynamicField("AlwaysShowHeadOnText", true);
				Map3DSystem.ShowHeadOnDisplay(true, obj, "录制:"..Map3DSystem.GetHeadOnText(obj));
			end
		end	
		
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_ReplayRelative) then
		-----------------------------------------------
		-- play from the beginning of the movie, using relative positioning for the actor
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent ~= nil) then
				agent:UseRelativePosition(true);
				agent:Replay();
				obj:GetAttributeObject():SetDynamicField("AlwaysShowHeadOnText", true);
				Map3DSystem.ShowHeadOnDisplay(true, obj, "播放:"..Map3DSystem.GetHeadOnText(obj));
			end
		end
		
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Replay) then
		-----------------------------------------------
		-- play from the beginning of the movie, using absolute positioning for the actor
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent ~= nil) then
				agent:UseRelativePosition(false);
				agent:Replay();
				obj:GetAttributeObject():SetDynamicField("AlwaysShowHeadOnText", true);
				Map3DSystem.ShowHeadOnDisplay(true, obj, "播放:"..Map3DSystem.GetHeadOnText(obj));
			end
		end
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Save) then
		-----------------------------------------------
		-- save the movie sequence of a given actor to a specified file. 
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		
		local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
		if(obj_params~=nil) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent ~= nil) then
				agent:Save(msg.filename);
				if(not msg.silent) then
					_guihelper.MessageBox("成功保存到: "..msg.filename.."\n");
				end
			end
		end
	
	elseif(msg.type == Map3DSystem.msg.MOVIE_ACTOR_Load) then
		-----------------------------------------------
		-- load the movie sequence of a given actor to a specified file. 
		-----------------------------------------------
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);	
		if(obj_params~=nil and obj~=nil and obj:IsCharacter()) then
			local agent = Map3DSystem.Movie.Recorder.GetAgent(obj_params.name);
			if(agent == nil) then
				agent = Map3DSystem.Movie.Recorder.agent:new{name=obj_params.name};
				Map3DSystem.Movie.Recorder.AddAgent(agent);
			end
			if(agent ~= nil) then
				agent:Load(msg.filename);
				if(msg.afterloadmsgtype) then
					-- either play or pause immediately
					Map3DSystem.SendMessage_movie({type = msg.afterloadmsgtype, obj=obj, obj_params=obj_params})
				end
			end
		end		
	end
end
