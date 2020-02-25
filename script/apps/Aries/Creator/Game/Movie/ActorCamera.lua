--[[
Title: camera actor
Author(s): LiXizhi
Date: 2014/3/30
Desc: for recording and playing back of camera creation and editing. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorCamera.lua");
local ActorCamera = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCamera");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MultiAnimBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCamera"));

Actor.class_name = "ActorCamera";
-- default to none-fps mode, the lookat position is more smooth than FPS one. 
local default_fps_mode = 0;
-- take a key frame every 5 seconds. 
Actor.auto_record_interval = 5000;

-- keyframes that can be edited from UI keyframe. 
local selectable_var_list = {
	"pos", -- multiple of x,y,z
	"rot", -- multiple of "roll", "pitch", "facing"
	"scaling",
	"---", -- separator
	"parent", 
	"static", -- multiple of "name" and "isAgent"
};


function Actor:ctor()
	self.curEditVariableIndex = -1;
end

function Actor:GetMultiVariable()
	local var = self:GetCustomVariable("multi_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new();
		var:AddVariable(self:GetVariable("lookat_x"));
		var:AddVariable(self:GetVariable("lookat_y"));
		var:AddVariable(self:GetVariable("lookat_z"));
		var:AddVariable(self:GetVariable("eye_dist"));
		var:AddVariable(self:GetVariable("eye_liftup"));
		var:AddVariable(self:GetVariable("eye_rot_y"));
		var:AddVariable(self:GetVariable("eye_roll"));
		-- var:AddVariable(self:GetVariable("parent"));
		self:SetCustomVariable("multi_variable", var);
		return var;
	end
end

-- get rotate multi variable
function Actor:GetStaticVariable()
	local var = self:GetCustomVariable("static_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="static"});
		var:AddVariable(self:GetVariable("name"));
		var:AddVariable(self:GetVariable("isAgent"));
		self:SetCustomVariable("static_variable", var);
		return var;
	end
end

-- get position multi variable
function Actor:GetPosVariable()
	local var = self:GetCustomVariable("pos_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="pos"});
		var:AddVariable(self:GetVariable("lookat_x"));
		var:AddVariable(self:GetVariable("lookat_y"));
		var:AddVariable(self:GetVariable("lookat_z"));
		self:SetCustomVariable("pos_variable", var);
		return var;
	end
end

-- get rotate multi variable
function Actor:GetRotateVariable()
	local var = self:GetCustomVariable("rot_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="rot"});
		var:AddVariable(self:GetVariable("eye_roll"));
		var:AddVariable(self:GetVariable("eye_liftup"));
		var:AddVariable(self:GetVariable("eye_rot_y"));
		self:SetCustomVariable("rot_variable", var);
		return var;
	end
end


function Actor:GetRollVariable()
	return self:GetVariable("eye_roll");
end

function Actor:GetYawVariable()
	return self:GetVariable("eye_rot_y");
end

function Actor:GetPitchVariable()
	return self:GetVariable("eye_liftup");
end

function Actor:GetScalingVariable()
	return self:GetVariable("eye_dist");
end

function Actor:Init(itemStack, movieclipEntity, isReuseActor, newName, movieclip)
	if(not Actor._super.Init(self, itemStack, movieclipEntity, movieclip)) then
		return;
	end

	local timeseries = self.TimeSeries;
	
	timeseries:CreateVariableIfNotExist("lookat_x", "Linear");
	timeseries:CreateVariableIfNotExist("lookat_y", "Linear");
	timeseries:CreateVariableIfNotExist("lookat_z", "Linear");
	timeseries:CreateVariableIfNotExist("eye_dist", "Linear");
	timeseries:CreateVariableIfNotExist("eye_liftup", "Linear");
	timeseries:CreateVariableIfNotExist("eye_rot_y", "LinearAngle");
	timeseries:CreateVariableIfNotExist("eye_roll", "LinearAngle");
	timeseries:CreateVariableIfNotExist("is_fps", "Discrete");
	timeseries:CreateVariableIfNotExist("has_collision", "Discrete");
	timeseries:CreateVariableIfNotExist("name", "Discrete");
	timeseries:CreateVariableIfNotExist("isAgent", "Discrete"); -- true, nil|false, "relative", "searchNearPlayer"
	timeseries:CreateVariableIfNotExist("parent", "LinearTable");
	
	self:AddValue("position", self.GetPosVariable);
	self:AddValue("roll", self.GetRollVariable);
	self:AddValue("facing", self.GetYawVariable);
	self:AddValue("pitch", self.GetPitchVariable);
	self:AddValue("scaling", self.GetScalingVariable);

	-- get initial position from itemStack, if not exist, we will use movie clip entity's block position. 
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		local x, y, z = movieClip:GetOrigin();
		y = y + BlockEngine.blocksize;

		x = self:GetValue("lookat_x", 0) or x;
		y = self:GetValue("lookat_y", 0) or y;
		z = self:GetValue("lookat_z", 0) or z;

		local att = ParaCamera.GetAttributeObject();

		self.entity = EntityCamera:Create({x=x,y=y,z=z, item_id = block_types.names.TimeSeriesCamera});
		self.entity:SetPersistent(false);
		self.entity:Attach();
		return self;
	end
end

-- this is called right after all actors in movie clips have been created. 
function Actor:OnCreate()
	local movieClip = self:GetMovieClip();
	if(movieClip:IsPlayingMode()) then
		local isAgent = self:GetValue("isAgent", 0);
		local offsetFacing;
		if(isAgent) then
			if(isAgent == "searchNearPlayer") then
				-- relative to player actor in the  movie clip
				local playerActor = movieClip:FindActor("player");
				if(playerActor) then
					self.offset_x, self.offset_y, self.offset_z =  playerActor.offset_x, playerActor.offset_y, playerActor.offset_z;
					self.offset_facing = playerActor:GetOffsetFacing();
				end
			elseif(isAgent == "relative") then
				-- relative to current camera position
				local x = self:GetValue("lookat_x", 0);
				local y = self:GetValue("lookat_y", 0);
				local z = self:GetValue("lookat_z", 0);
				if(x and y and z) then
					local cx, cy, cz = ParaCamera.GetLookAtPos()
					self.offset_x, self.offset_y, self.offset_z =  cx-x, cy-y, cz-z;
					local facing = self:GetValue("eye_rot_y", 0);
					local camobjDist, LifeupAngle, CameraRotY = ParaCamera.GetEyePos();
					self.offset_facing = CameraRotY - (facing or 0)
				end
			end
		end
	end
end

function Actor:IsKeyFrameOnly()
	return true;
end

-- @return nil or a table of variable list. 
function Actor:GetEditableVariableList()
	return selectable_var_list;
end

-- whether we will also show  the command actor's variables on this actor's timeline. 
-- self.curEditVariableIndex must be -1 in order for command actor's variable to be selected. otherwise, this actor's variable is selected.
function Actor:CanShowCommandVariables()
	return true;
end

-- @param selected_index: if nil,  default to current index
-- @return var
function Actor:GetEditableVariable(selected_index)
	selected_index = selected_index or self:GetCurrentEditVariableIndex();
	
	local name = selectable_var_list[selected_index];
	local var;
	if(name == "pos") then
		var = self:GetPosVariable();
	elseif(name == "rot") then
		var = self:GetRotateVariable();
	elseif(name == "scaling") then
		var = self:GetScalingVariable();
	elseif(name == "static") then
		var = self:GetStaticVariable();
	elseif(name) then
		var = self.TimeSeries:GetVariable(name);
	end
	return var;
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	isRecording = isRecording == true;
	if(isRecording~=self:IsRecording()) then
		self.isRecording = isRecording;

		if(isRecording) then
			self.begin_recording_time = self:GetTime();
			--self:RemoveKeysInTimeRange(self:GetTime(), self:GetCurrentRecordingEndTime());
			self:ClearRecordToTime();
		else
			self.begin_recording_time = nil;
			self.end_recording_time = self:GetTime();
		end
			
		local movieClip = self:GetMovieClip();
		if(movieClip) then
			movieClip:SetActorRecording(self, isRecording);
		end

		-- add key frame at recording switch time. 
		self:AddKeyFrame();
	end
	return self.isRecording;
end

function Actor:OnRemove()
	Actor._super.OnRemove(self);
end

function Actor:FrameMoveRecording(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	
	if( not entity.ridingEntity and deltaTime > 0 and self.begin_recording_time) then
		-- only take a key frame every self.auto_record_interval milliseconds. 
		if ((self.begin_recording_time+self.auto_record_interval) > curTime) then
			-- do nothing if we are not at auto recording interval. 
			return;
		else
			self.begin_recording_time = curTime;
		end
	end

	entity:UpdatePosition();
	local x,y,z = entity:GetPosition();

	self:BeginUpdate();
	self:AutoAddKey("lookat_x", curTime, x);
	self:AutoAddKey("lookat_y", curTime, y);
	self:AutoAddKey("lookat_z", curTime, z);

	local eye_dist, eye_liftup, eye_rot_y = ParaCamera.GetEyePos();
	if(eye_dist) then
		self:AutoAddKey("eye_dist", curTime, eye_dist);
		self:AutoAddKey("eye_liftup", curTime, eye_liftup);
		self:AutoAddKey("eye_rot_y", curTime, eye_rot_y);
		self:AutoAddKey("eye_roll", curTime, entity:GetCameraRoll());
	end
	self:AutoAddKey("is_fps", curTime, if_else(CameraController.IsFPSView(), 1,0));

	local has_collision = if_else(self.entity:HasCollision(), 1,0); 
	self:AutoAddKey("has_collision", curTime, has_collision);
	self:EndUpdate();
end

function Actor:IsAllowUserControl()
	local entity = self:GetEntity();
	if(entity) then
		local curTime = self:GetTime();
		return entity:HasFocus() and not self:IsPlayingMode() and self:IsPaused() and 
			-- allow user control when there is no key frames at the end
			-- using OR, we will allow dragging when no key frames. 
			(((self:GetMultiVariable():GetLastTime()+1) <= curTime) or not MovieClipTimeLine.IsDraggingTimeLine());
	end
end

-- return the parent link and parent actor if found.
-- @return parent, curTime, parentActor, keypath: where parent contains local transform relative to target:
--  in the form {target="fullname", pos={}, rot={}, use_rot=true}
function Actor:GetParentLink(curTime)
	curTime = curTime or self:GetTime();
	local parent = self:GetValue("parent", curTime);
	if(parent and type(parent) == "table" and parent.target and parent.target ~="")then
		-- animate linking to another actor's bone animation. 
		local actorname, keypath = parent.target:match("^([^:]+):*(.*)"); 
		if(actorname) then
			local parentActor = self:FindActor(actorname);
			if(parentActor and parentActor~=self) then
				return parent, curTime, parentActor, keypath;
			end
		end
	end
end

function Actor:ComputePosition(curTime)
	local new_x = self:GetValue("lookat_x", curTime);
	local new_y = self:GetValue("lookat_y", curTime);
	local new_z = self:GetValue("lookat_z", curTime);

	-- animate linking to another actor's bone animation. 
	local parent, _, parentActor, keypath = self:GetParentLink(curTime);
	if(keypath and parentActor and parentActor.ComputeWorldTransform)then
		local p_x, p_y, p_z = parentActor:ComputeWorldTransform(keypath, curTime, parent.pos, parent.rot, parent.use_rot); 
		if(p_x) then
			new_x, new_y, new_z = p_x, p_y, p_z;
		else
			if(self.last_unknown_keypath~=keypath and keypath and keypath~="") then
				-- here we just wait 500 and try again only once for a given bone keypath.
				self.last_unknown_keypath = keypath;
				self.loader_timer = self.loader_timer or commonlib.Timer:new({callbackFunc = function(timer)
					self:FrameMovePlaying(0);
				end})
				LOG.std(nil, "info", "ActorCamera", "parent bone may be async loading, wait 500ms");
				self.loader_timer:Change(500, nil);
			end
		end
	end

	if(new_x and new_y and new_z) then
		if(self.offset_x) then
			new_x = self.offset_x + new_x;
			new_y = self.offset_y + new_y;
			new_z = self.offset_z + new_z;
		end
	end
	return new_x, new_y, new_z;
end

local camera_params = {0,0,0}; -- yaw, pitch, roll
function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	
	local eye_dist = self:GetValue("eye_dist", curTime);
	local eye_liftup = self:GetValue("eye_liftup", curTime);
	local eye_rot_y = self:GetValue("eye_rot_y", curTime);
	local eye_roll = self:GetValue("eye_roll", curTime);

	if(self.offset_facing and eye_rot_y) then
		eye_rot_y = eye_rot_y + self.offset_facing;
	end

	local allow_user_control;
	if(entity:HasFocus()) then
		local parent = self:GetParentLink(curTime);
		local isBehindLastFrame = ((self:GetMultiVariable():GetLastTime()+1) <= curTime);
		if(isBehindLastFrame) then
			if(not self.isBehindLastFrame) then
				self.isBehindLastFrame = true;
				isBehindLastFrame = false;
			end
		else
			self.isBehindLastFrame = isBehindLastFrame;
		end
		allow_user_control = (not self:IsPlayingMode() and isBehindLastFrame) and (not parent);
		if( not allow_user_control ) then
			ParaCamera.SetEyePos(eye_dist, eye_liftup, eye_rot_y);
			self:UpdateFPSView(curTime);
		end
		entity:SetCameraRoll(eye_roll or 0);
		if(isBehindLastFrame and not parent) then
			return;
		end
	else
		self.isBehindLastFrame = nil;
	end
	
	local obj = entity:GetInnerObject();
	if(obj) then
		obj:SetFacing(eye_rot_y or 0);
		obj:SetField("HeadUpdownAngle", 0);
		obj:SetField("HeadTurningAngle", 0);
		local nx, ny, nz = mathlib.math3d.vec3Rotate(0, 1, 0, 0, 0, -(eye_liftup or 0))
		nx, ny, nz = mathlib.math3d.vec3Rotate(nx, ny, nz, 0, eye_rot_y or 0, 0)
		obj:SetField("normal", {nx, ny, nz});
	end
	

	if(not allow_user_control) then
		local new_x, new_y, new_z = self:ComputePosition(curTime);
		if(new_x and new_y and new_z) then
			entity:SetPosition(new_x, new_y, new_z);
			-- due to floating point precision of the view matrix, slowly moved camera may jerk.
			--LOG.std(nil, "debug", "ActorCamera", "x,y,z: %f %f %f", new_x, new_y, new_z);
			--LOG.std(nil, "debug", "ActorCamera", "c pos: %f %f %f", ParaCamera.GetLookAtPos());
		end
	end

	local has_collision = self:GetValue("has_collision", curTime) or 1; 
	-- disable collision if camera is inside a solid block. 
	if(entity:IsInsideObstructedBlock() and not CameraController.HasCameraCollision()) then
		has_collision = false;
	end
	entity:SetCameraCollision(has_collision);

	if(self:IsPlayingMode()) then
		entity:HideCameraModel();
	else
		entity:ShowCameraModel();
	end
end

function Actor:UpdateFPSView(curTime)
	curTime = curTime or self:GetTime();
	local is_fps = self:GetValue("is_fps", curTime) or default_fps_mode; 
	local current_is_fps = if_else(CameraController.IsFPSView(), 1,0);
	if(current_is_fps ~= is_fps) then
		CameraController.ToggleCamera(is_fps == 1);
	end
end

function Actor:SetFocus()
	Actor._super.SetFocus(self);
	self:UpdateFPSView(curTime);
	self:FrameMovePlaying(0);
	-- always begin with nil variable, rather than remember last selection.  
	self:SetCurrentEditVariableIndex(-1);
end

-- select me: for further editing. 
function Actor:SelectMe()
	-- camera actor does not show up anything. 
	
end

-- get the camera settings before SetFocus is called. this usually stores the current player's camera settings
-- before a movie clip is played. we will usually restore the camera settings when camera is reset. 
function Actor:GetRestoreCamSettings()
	local entity = self.entity;
	if(entity) then
		return entity:GetRestoreCamSettings()
	end
end

function Actor:SetRestoreCamSettings(settings)
	local entity = self.entity;
	if(entity) then
		return entity:SetRestoreCamSettings(settings);
	end
end

-- force adding current values to all transform variables, these include position and rotation.
function Actor:KeyTransform()
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	entity:UpdatePosition();
	local x,y,z = entity:GetPosition();
	self:BeginUpdate();

	self:AutoAddKey("lookat_x", curTime, x);
	self:AutoAddKey("lookat_y", curTime, y);
	self:AutoAddKey("lookat_z", curTime, z);
	
	self:EndUpdate();
end

function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local curTime = self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local old_value = self:GetValue(keyname, curTime);
	if(keyname == nil) then
		-- multi-variable
		local title = format(L"起始时间:%s <br/>lookat_x, lookat_y, lookat_z,<br/>eye_dist, eye_liftup, eye_rot_y", strTime);
		local lookat_x = self:GetValue("lookat_x", curTime);
		local lookat_y = self:GetValue("lookat_y", curTime);
		local lookat_z = self:GetValue("lookat_z", curTime);
		if(not lookat_x) then
			return;
		end
		local eye_dist = self:GetValue("eye_dist", curTime) or 10;
		local eye_liftup = self:GetValue("eye_liftup", curTime) or 0;
		local eye_rot_y = self:GetValue("eye_rot_y", curTime) or 0;

		local old_value = string.format("%f, %f, %f,\n%f, %f, %f", lookat_x,lookat_y,lookat_z,eye_dist,eye_liftup,eye_rot_y);

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");

				if(vars[1] == lookat_x and vars[2] == lookat_y and vars[3] == lookat_z and
					vars[4] == eye_dist and vars[5] == eye_liftup and vars[6] == eye_rot_y) then
					-- nothing has changed
				elseif(vars[6]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("lookat_x", nil, vars[1]);
					self:AddKeyFrameByName("lookat_y", nil, vars[2]);
					self:AddKeyFrameByName("lookat_z", nil, vars[3]);
					self:AddKeyFrameByName("eye_dist", nil, vars[4]);
					self:AddKeyFrameByName("eye_liftup", nil, vars[5]);
					self:AddKeyFrameByName("eye_rot_y", nil, vars[6]);
					self:EndUpdate();
					self:FrameMovePlaying(0);	
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end,old_value,true); 
	elseif(keyname == "pos") then
		local title = format(L"起始时间%s, 请输入位置x,y,z:", strTime);
		local bx, by, bz = self:GetValue("lookat_x", curTime),self:GetValue("lookat_y", curTime), self:GetValue("lookat_z", curTime)
		if(not bx or not by or not bz) then
			local entity = self:GetEntity() or EntityManager.GetPlayer();
			bx, by, bz = entity:GetPosition();
		end
		bx, by, bz = BlockEngine:block_float(bx, by, bz)
		bx = bx - 0.5;
		bz = bz - 0.5;
		old_value = string.format("%f, %f, %f", bx, by, bz);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					local x, y, z = BlockEngine:real_bottom(vars[1], vars[2], vars[3])
					self:BeginUpdate();
					self:AddKeyFrameByName("lookat_x", nil, x);
					self:AddKeyFrameByName("lookat_y", nil, y);
					self:AddKeyFrameByName("lookat_z", nil, z);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end, old_value)
	elseif(keyname == "rot") then
		local title = format(L"起始时间%s, 请输入roll, pitch, yaw (-1.57, 1.57)<br/>", strTime);
		old_value = string.format("%f, %f, %f", self:GetValue("eye_roll", curTime) or 0,self:GetValue("eye_liftup", curTime) or 0,self:GetValue("eye_rot_y", curTime) or 0);
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("eye_roll", nil, vars[1]);
					self:AddKeyFrameByName("eye_liftup", nil, vars[2]);
					self:AddKeyFrameByName("eye_rot_y", nil, vars[3]);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end,old_value)
	elseif(keyname == "scaling" or keyname == "eye_dist") then
		local title = format(L"起始时间%s, 请输入放大系数(默认1)", strTime);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result) then
				self:AddKeyFrameByName("eye_dist", nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value)
	elseif(keyname == "parent") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditParentLinkPage.lua");
		local EditParentLinkPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditParentLinkPage");
		EditParentLinkPage.ShowPage(strTime, self, function(values)
			if(values.target=="") then
				-- this will automatically add a key frame, when link is removed. 
				self:KeyTransform();
			end
			self:AddKeyFrameByName(keyname, nil, values);
			self:FrameMovePlaying(0);
			if(target~="") then
				-- this will automatically add a key frame at the position. 
				self:KeyTransform();
			end
			if(callbackFunc) then
				callbackFunc(true);
			end
		end, old_value);
	elseif(keyname == "static") then
		old_value = {name = self:GetValue("name", 0) or "", isAgent = self:GetValue("isAgent", 0)}
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditStaticPropertyPage.lua");
		local EditStaticPropertyPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditStaticPropertyPage");
		EditStaticPropertyPage.ShowPage(function(values)
			if(values.name ~= old_value.name) then
				self:AddKeyFrameByName("name", 0, values.name);
				self:SetDisplayName(values.name)
			end
			if(values.isAgent ~= old_value.isAgent) then
				self:AddKeyFrameByName("isAgent", 0, values.isAgent);
			end
			if(callbackFunc) then
				callbackFunc(true);
			end
		end, old_value, {
			{value="false", text=L"默认"},
			{value="relative", text=L"相对摄影机"},
			{value="searchNearPlayer", text=L"相对主角"},
		});
	end
end