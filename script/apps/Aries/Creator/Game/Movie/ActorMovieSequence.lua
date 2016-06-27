--[[
Title: a sequence of one or more remote movie blocks
Author(s): LiXizhi
Date: 2014/10/13
Desc: we can put movie blocks on the timeline of a single parent movie block. 
Thus allowing precise editing of movie block playing time (without using wires and repeaters)
One cool feature is that we can preview and edit on a single time line for many movie blocks. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorMovieSequence.lua");
local ActorMovieSequence = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMovieSequence");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMovieSequence"));

-- for selection effect. 
local groupindex_select = 3;

function Actor:ctor()
end

function Actor:Init(itemStack, movieclipEntity)
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end
	
	local timeseries = self.TimeSeries;
	-- location array of movie blocks on the timeline.
	timeseries:CreateVariableIfNotExist("movieblock", "Discrete");

	return self;
end

function Actor:IsKeyFrameOnly()
	return true;
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	-- disable recording. 
	return false;
end

-- remove all blocks
function Actor:OnRemove()
	if(self.last_movieclip) then
		local movieclip = self.last_movieclip;
		self.last_movieclip = nil;
		movieclip:Pause();
		movieclip:RemoveAllActors();
		MovieManager:RemoveMovieClip(movieclip);
		movieclip:GetEntity():EnablePlayingMode(false);
		ParaTerrain.DeselectAllBlock(groupindex_select);
	end
end

local function getSparseIndex(bx, by, bz)
	return by*30000*30000+bx*30000+bz;
end

-- virtual function: display a UI to let the user to edit this keyframe's data. 
-- @param default_value: if nil, it will be the one already on the timeline. 
function Actor:EditKeyFrame(keyname, time, default_value, callbackFunc)
	local curTime = time or self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local old_value = default_value or self:GetValue(keyname, curTime);
	local old_value_str;
	if(old_value and old_value[3]) then
		old_value_str = string.format("%d %d %d", old_value[1], old_value[2], old_value[3]);
	end
	local title = format(L"起始时间%s, 请输入电影方块的位置: x y z", strTime);

	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(title, function(result)
		if(result and result~="") then
			local x,y,z = result:match("^%D*(%d+)%D+(%d+)%D+(%d+)");
			if(x and y and z) then
				local value = {tonumber(x), tonumber(y), tonumber(z)};
				self:AddKeyFrameByName(keyname, nil, value);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end
	end,old_value_str)
end

function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local curSelection = GameLogic.GetCurrentSelection()
	if(curSelection and #curSelection == 1) then
		local block = curSelection[1];
		local x, y, z = block[1], block[2], block[3];
		local block_id = BlockEngine:GetBlockId(x, y, z);
		if (block_id and block_id == block_types.names.MovieClip) then
			-- automatically add the current selected movie clip when K key is pressed. 
			local value = {x, y, z};
			self:AddKeyFrameByName(keyname, nil, value);
			self:FrameMovePlaying(0);
			if(callbackFunc) then
				callbackFunc(true);
			end
		else
		end
	else
		local default_value;
		self:EditKeyFrame(keyname, nil, default_value, callbackFunc);	
	end
end

function Actor:FrameMovePlaying(deltaTime, bIsSelected)
	local curTime = self:GetTime();
	if(not curTime) then
		return
	end
	local block_pos = self:GetValue("movieblock", curTime);
	if(not block_pos) then
		return;
	end
	local x, y, z = block_pos[1], block_pos[2], block_pos[3];
	local block_template = BlockEngine:GetBlock(x, y, z);
	local movieclipEntity;
	-- the local movie clip to play
	local movieclip;
	if(block_template) then
		movieclipEntity = block_template:GetBlockEntity(x, y, z);
		if(movieclipEntity) then
			movieclip = movieclipEntity:GetMovieClip();
		end
	end
	if(self.last_movieclip ~= movieclip) then
		-- deactivate last movie block and activate the new movie block 
		if(self.last_movieclip) then
			self.last_movieclip:Pause();
			self.last_movieclip:RemoveAllActors();
			MovieManager:RemoveMovieClip(self.last_movieclip);
		end
		self.last_movieclip = movieclip;
		if(movieclip) then
			movieclip:GotoBeginFrame();
			movieclip:RefreshActors();
			movieclip:RePlay();
			MovieManager:AddMovieClip(movieclip);

			-- highlight the local movie block
			ParaTerrain.DeselectAllBlock(groupindex_select);
			ParaTerrain.SelectBlock(x,y,z, true, groupindex_select);
		end
	end
	if(movieclip) then
		local activeMovieClip = MovieManager:GetActiveMovieClip();
		local isPlayingMode = activeMovieClip:GetEntity():IsPlayingMode();
		movieclip:GetEntity():EnablePlayingMode(isPlayingMode);

		-- always pause local movie clip since its time will be controlled by this ActorMovieSequence block.
		if(not movieclip:IsPaused()) then
			movieclip:Pause();
		end
		-- change the current time of the movie block. 
		local var = self:GetVariable("movieblock");
		local fromTime, toTime = var:getTimeRange(1, curTime);

		local localClipTime = curTime - fromTime;
		

		if(localClipTime >=0) then
			local actor_text = self:GetRootActor():GetChildActor("actor_text");
			local locked_actor_text;
			if(actor_text) then
				local var = actor_text:GetVariable("text");
				if(var and var:GetKeyNum()~=0) then
					-- prevent child movie blocks to display any text, if the parent already contains text
					actor_text:Lock();
					locked_actor_text = true;
				end
			end

			if(movieclipEntity:HasCamera()) then
				movieclip:SetTime(localClipTime);

				if(movieclip ~= activeMovieClip and activeMovieClip) then
					movieclip:UpdateActors(0);

					-- use the local movie clip's camera if movie sequence actor is playing or paused but with ActorCommands selected. 
					local actorSelected = activeMovieClip:GetSelectedActor();
					if( isPlayingMode or (activeMovieClip:IsPlaying() and actorSelected and actorSelected.class_name~="ActorCamera")
						or (actorSelected and actorSelected.class_name=="ActorCommands")) then
						-- actorFocus
						local localCameraActor = movieclip:GetCamera();
						if(not localCameraActor:HasFocus()) then
							localCameraActor:SetFocus();
						end
					end
				end
			else
				movieclip:SetTime(localClipTime);
				if(movieclip ~= activeMovieClip) then
					movieclip:UpdateActors(0);
				end
				-- if local movie does not has camera, use the movie sequence actor's camera. 
				if(activeMovieClip) then
					local actorCamera = activeMovieClip:GetCamera()
					if(actorCamera and not actorCamera:HasFocus()) then
						actorCamera:SetFocus();
					end
				end
			end

			if(locked_actor_text) then
				actor_text:Unlock();
			end
		end
	end
end
