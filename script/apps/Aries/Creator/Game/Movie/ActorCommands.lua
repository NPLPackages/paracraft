--[[
Title: actor commands
Author(s): LiXizhi
Date: 2014/4/9
Desc: a number of command that is executed on the time line. 
Please note, only movie related command is recommended to use, such that dragging timeline will match the actual output
current supported addkey command is:
	/addkey text [any text]
	/addkey tip [any text]
	/addkey fadein [seconds or 0.5]
	/addkey fadeout [seconds or 0.5]
	/addkey time [number:-1,1]
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorCommands.lua");
local actor = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCommands");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorGUIText.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorBlocks.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorMovieSequence.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorMusic.lua");
local ActorMusic = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMusic");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local ActorBlocks = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlocks");
local ActorGUIText = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorGUIText");
local ActorMovieSequence = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorMovieSequence");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCommands"));

Actor.class_name = "ActorCommands";

function Actor:ctor()
	self.actor_text = ActorGUIText:new();
	self.actor_blocks = ActorBlocks:new();
	self.actor_movie_sequence = ActorMovieSequence:new();
	self.actor_movie_sequence:SetParentActor(self);
	self.actor_music = ActorMusic:new();

	self.actor_text:Connect("keyChanged", self, "keyChanged");
	self.actor_text:Connect("valueChanged", self, "valueChanged");
	self.actor_blocks:Connect("keyChanged", self, "keyChanged");
	self.actor_blocks:Connect("valueChanged", self, "valueChanged");
	self.actor_movie_sequence:Connect("keyChanged", self, "keyChanged");
	self.actor_movie_sequence:Connect("valueChanged", self, "valueChanged");
	self.actor_music:Connect("keyChanged", self, "keyChanged");
	self.actor_music:Connect("valueChanged", self, "valueChanged");
end

function Actor:SetItemStack(itemStack)
	self.actor_text:SetItemStack(itemStack);
	self.actor_blocks:SetItemStack(itemStack);
	self.actor_movie_sequence:SetItemStack(itemStack);
	self.actor_music:SetItemStack(itemStack);
	-- base class must be called last, so that child actors have initialized their own variables on itemStack. 
	Actor._super.SetItemStack(self, itemStack);
end

-- get child actor
-- @param name: "actor_text", "actor_blocks", etc
function Actor:GetChildActor(name)
	return self[name];
end

function Actor:Init(itemStack, movieclipEntity, isReuseActor, newName, movieclip)
	local timeseries = self.TimeSeries;
	self.actor_text:Init(itemStack, movieclipEntity, movieclip);
	self.actor_blocks:Init(itemStack, movieclipEntity, movieclip);
	self.actor_movie_sequence:Init(itemStack, movieclipEntity, movieclip);
	-- background music track1
	self.actor_music:Init(itemStack, movieclipEntity, movieclip);
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, movieclipEntity, movieclip)) then
		return;
	end

	timeseries:CreateVariableIfNotExist("cmd", "Discrete");
	timeseries:CreateVariableIfNotExist("tip", "Discrete");
	-- time of day
	timeseries:CreateVariableIfNotExist("time", "Linear"); 
	return self;
end

-- get display name
function Actor:GetDisplayName()
	return L"全局";
end

local selectable_var_list = {"text", "time", "blocks", "cmd", "movieblock", "music"};

-- @return nil or a table of variable list. 
function Actor:GetEditableVariableList()
	return selectable_var_list;
end

-- @param selected_index: if nil,  default to current index
-- @return var
function Actor:GetEditableVariable(selected_index)
	selected_index = selected_index or self:GetCurrentEditVariableIndex();
	return self.TimeSeries:GetVariable(selectable_var_list[selected_index]);
end

function Actor:IsKeyFrameOnly()
	return true;
end

-- @return true if recording. 
function Actor:SetRecording(isRecording)
	-- disable recording camera. 
	return false
end

-- the same command can only be played once. 
function Actor:PlayCmd(curTime)
	local cmd = self:GetValue("cmd", curTime, true);
	if(cmd) then
		if(self.last_cmd~=cmd) then
			self.last_cmd = cmd;
			CommandManager:RunText(cmd, self:GetMovieClipEntity());
		end
	end
end

function Actor:PlayTip(curTime)
	-- local tip = self:GetValue("tip", curTime);
end

-- day time. 
function Actor:PlayTime(curTime)
	local time = self:GetValue("time", curTime, true);
	if(time) then
		ParaScene.SetTimeOfDaySTD(time);
		GameLogic.GetSim():OnTickDayLight();
	end
end

-- add movie text at the current time. 
function Actor:AddKeyFrameOfText(text)
	self.actor_text:AddKeyFrameOfText(text)
end

-- add movie text at the current time. 
function Actor:AddKeyFrameOfTime(time)
	if(type(time) == "number") then
		self:AddKeyFrameByName("time", nil, time);
	end
end

-- let the user to create a key and add to current timeline 
function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local curTime = self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local old_value = self:GetValue(keyname, curTime);

	if(keyname == "text") then
		self.actor_text:CreateKeyFromUI(keyname, callbackFunc);
	elseif(keyname == "movieblock") then
		self.actor_movie_sequence:CreateKeyFromUI(keyname, callbackFunc);
	elseif(keyname == "music") then
		self.actor_music:CreateKeyFromUI(keyname, callbackFunc);
	elseif(keyname == "time") then
		local title = format(L"起始时间%s, 请输入时间[-1,1]", strTime);
		old_value = ParaScene.GetTimeOfDaySTD();
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value);
	elseif(keyname == "blocks") then
		self.actor_blocks:AddKeyFrameOfSelectedBlocks();
		if(callbackFunc) then
			callbackFunc(true);
		end
	elseif(keyname == "cmd") then
		local title = format(L"起始时间%s, 请输入命令行(/)", strTime);
		if(old_value) then
			old_value = old_value:gsub(";/", "\n/");
		end
		-- TODO: use a dedicated UI 
		-- show as multiline text input box. 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="" and result:match("^/")) then
				result=result:gsub("[\r\n]+/", ";/");
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value,true); 
	end
end

-- virtual function: display a UI to let the user to edit this keyframe's data. 
function Actor:EditKeyFrame(keyname, time)
	time = time or self:GetTime();
	local old_value = self:GetValue(keyname, time);
	if(old_value) then
		if(keyname == "text") then
			self.actor_text:EditKeyFrame(keyname, time)
		elseif(keyname == "blocks") then
			self.actor_blocks:EditKeyFrame(keyname, time)
		elseif(keyname == "movieblock") then
			self.actor_movie_sequence:EditKeyFrame(keyname, time)
		elseif(keyname == "music") then
			self.actor_music:EditKeyFrame(keyname, time)
		elseif(keyname == "time") then
			-- TODO: edit the key and set back
			-- _guihelper.MessageBox(old_value);
		end
	end
end

-- remove GUI text
function Actor:OnRemove()
	self.actor_text:OnRemove();
	self.actor_blocks:OnRemove();
	self.actor_movie_sequence:OnRemove();
	self.actor_music:OnRemove();

	Actor._super.OnRemove(self);
end

function Actor:FrameMovePlaying(deltaTime, bIsSelected)
	local curTime = self:GetTime();
	if(not curTime) then
		return
	end
	self.actor_text:FrameMovePlaying(deltaTime, bIsSelected)
	self.actor_blocks:FrameMovePlaying(deltaTime, bIsSelected);
	self.actor_movie_sequence:FrameMovePlaying(deltaTime, bIsSelected);
	self.actor_music:FrameMovePlaying(deltaTime, bIsSelected);

	self:PlayCmd(curTime);
	self:PlayTip(curTime);
	self:PlayTime(curTime);
end
