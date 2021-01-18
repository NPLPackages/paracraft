--[[
Title: movie clip
Author(s): LiXizhi
Date: 2014/3/30
Desc: a movie clip is a group of actors (time series entities) that are sharing the same time origin. 
multiple connected movie clip makes up a movie. The camera actor is a must have actor in a movie clip.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFrameCtrl.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local KeyFrameCtrl = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFrameCtrl");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");

local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");

local movie_clip_timeline_name = "movieclip_timeline";
local page;
local timeline_color_map = {
	["activated"] = "0 0 255 200",
	["playing"] = "0 255 0 200",
	["recording"] = "255 0 0 200",
	["not_recording"] = "0 0 255 200",
}
MovieClipTimeLine.keyframes_parent_name = "keyframe_timeline_parent";
MovieClipTimeLine.subframes_parent_name = "subframe_timeline_parent";

local var_name_to_text = {
	text = L"文字",
	bones = L"骨骼",
	time = L"时间",
	blocks = L"方块",
	anim = L"动作",
	assetfile = L"模型",
	skin = L"皮肤",
	blockinhand = L"手持",
	scaling = L"大小",
	cmd = L"命令",
	speedscale = L"运动速度",
	gravity = L"重力",
	facing = L"转身",
	rot = L"旋转",
	HeadUpdownAngle = L"头部上下",
	HeadTurningAngle = L"头部左右",
	head = L"头部运动",
	movieblock = L"子电影方块",
	music = L"背景音乐",
	opacity = L"透明度",
	pos = L"位置",
	screen_pos = L"屏幕坐标",
	ui_zorder = L"Z排序",
	ui_align = L"屏幕坐标对齐方式",
	parent = L"父链接",
	color = L"颜色",
	code = L"代码",
	static = L"静态属性",
	cam_dist = L"到镜头的距离",
	LightType = L"光源类型", 
	Diffuse = L"漫反射颜色",
	Specular = L"反射颜色",
	Ambient = L"环境颜色",
	Range = L"范围",
	Falloff = L"衰减范围",
	Attenuation0 = L"衰减参数0",
	Attenuation1 = L"衰减参数1",
	Attenuation2 = L"衰减参数2",
	is_fps = L"第一人称",
}
local var_longname_to_text = {
	anim = L"动作 (1键)",
	bones = L"骨骼 (1,1键)",
	pos = L"位置 (2键)",
	facing = L"转身 (3键)",
	rot = L"三轴旋转 (3,3键)",
	scaling = L"大小 (4键)",
}

MovieClipTimeLine.timelineHeight = 12;
MovieClipTimeLine.timeSliderHeight = 16;
MovieClipTimeLine.height = MovieClipTimeLine.timelineHeight*2 + MovieClipTimeLine.timeSliderHeight;

function MovieClipTimeLine.OnInit()
	local self = MovieClipTimeLine;
	self.inited = true;
	Game.SelectionManager:Connect("selectedActorChanged", self, self.OnSelectedActorChange, "UniqueConnection");
	Game.SelectionManager:Connect("varNameChanged", self, self.OnVariableNameChange, "UniqueConnection");
	MovieManager:Connect("activeMovieClipChanged", self, self.OnActiveMovieClipChange, "UniqueConnection");
	-- set initial values: 
	self:OnSelectedActorChange(Game.SelectionManager:GetSelectedActor());
	self:OnActiveMovieClipChange(MovieManager:GetActiveMovieClip());
	self:OnMovieClipTimeChange();
end

function MovieClipTimeLine.OnClosePage()
	local self = MovieClipTimeLine;
	Game.SelectionManager:Disconnect("selectedActorChanged", self, self.OnSelectedActorChange);
	Game.SelectionManager:Disconnect("varNameChanged", self, self.OnVariableNameChange);
	MovieManager:Disconnect("activeMovieClipChanged", self, self.OnActiveMovieClipChange);

	self.inited = false;
	local viewport = ViewportManager:GetSceneViewport();
	if(viewport:GetMarginBottomHandler() == self) then
		viewport:SetMarginBottomHandler(nil);
		viewport:SetMarginBottom(0);
	end
	if(viewport:GetMarginRightHandler() == self) then
		viewport:SetMarginRightHandler(nil);
		viewport:SetMarginRight(0);	
	end
end

-- set UI height. only valid during startup
function MovieClipTimeLine:SetControlSize(timelineHeight, timeSliderHeight)
	timelineHeight = timelineHeight or 12;
	timeSliderHeight = timeSliderHeight or timelineHeight;
	self.timelineHeight = timelineHeight;
	self.timeSliderHeight = timeSliderHeight;
	self.height = self.timelineHeight*2 + self.timeSliderHeight;
end

function MovieClipTimeLine:OnActiveMovieClipChange(clip)
	if(self.activeClip~=clip) then
		if(self.activeClip) then
			self.activeClip:Disconnect("timeChanged", self, self.OnMovieClipTimeChange);
			self.activeClip:Disconnect("remotelyUpdated", self, self.OnMovieClipRemotelyUpdated);
		end
		if(clip) then
			clip:Connect("timeChanged", self, self.OnMovieClipTimeChange, "UniqueConnection");
			clip:Connect("remotelyUpdated", self, self.OnMovieClipRemotelyUpdated, "UniqueConnection");
		end
		self.activeClip = clip;
	end
end

-- force update all time variables. Only called once during page rebuild
function MovieClipTimeLine:UpdateUI()
	if(self.activeClip) then
		local time = self.activeClip:GetTime();
		self:UpdateSubKeyFrames(time, true);
		self:UpdateKeyFrames(time, true);
		self:UpdateTimeSlider(time);
	end
end

function MovieClipTimeLine:OnMovieClipRemotelyUpdated()
	if(page and page:IsVisible()) then
		self:UpdateUI()
	end
end

function MovieClipTimeLine:OnMovieClipTimeChange()
	if(self.activeClip) then
		local time = self.activeClip:GetTime();
		self:UpdateSubKeyFrames(time, nil);
		self:UpdateKeyFrames(time, nil);
		self:UpdateTimeSlider(time);
	end
end

-- get actor at given channel
function MovieClipTimeLine:GetActorAt(channel_name)
	return self[channel_name];
end

local channels = {"cur_actor", "sub_actor"}
function MovieClipTimeLine:HasActor(actor)
	return actor and (self:GetActorAt(channels[1]) == actor or self:GetActorAt(channels[2]) == actor);
end

-- set actor that is being watched (edited). 
-- @param channel_name: "cur_actor", "sub_actor"
function MovieClipTimeLine:SetActorAt(channel_name, actor)
	local oldActor = self:GetActorAt(channel_name);
	if(oldActor ~= actor) then
		self[channel_name] = nil;
		if(oldActor and not self:HasActor(oldActor)) then
			oldActor:Disconnect("keyChanged", self, self.OnActorKeyChange);
			oldActor:Disconnect("currentEditVariableChanged", self, self.OnCurrentEditVariableChange);
		end
		if(actor and not self:HasActor(actor)) then
			actor:Connect("keyChanged", self, self.OnActorKeyChange);
			actor:Connect("currentEditVariableChanged", self, self.OnCurrentEditVariableChange);
		end
		self[channel_name] = actor;
	end
end

function MovieClipTimeLine:OnSelectedActorChange(actor)
	local actor = Game.SelectionManager:GetSelectedActor();
	self:SetActorAt("cur_actor", actor);
	local var, sub_actor = self:GetCurrentSubFrameVariable(true);
	self:SetActorAt("sub_actor", if_else(sub_actor~=actor, sub_actor, nil));

	self:UpdateCameraActor();
	self:OnMovieClipTimeChange();
end

function MovieClipTimeLine:OnCurrentEditVariableChange()
	self:UpdateSubKeyFrames(nil, nil);
	self:OnVariableNameChange();
end

function MovieClipTimeLine:UpdateCameraActor()
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(self.camera_actor~=actor) then
			if(self.camera_actor) then
				self.camera_actor:Disconnect("keyChanged", self, self.OnCameraKeyChange);
			end
			if(actor) then
				actor:Connect("keyChanged", self, self.OnCameraKeyChange);
			end
			self.camera_actor = actor;
		end
	end
end

function MovieClipTimeLine:OnCameraKeyChange()
	if(self.camera_actor) then
		self.camera_actor:FrameMovePlaying(0);
		self:UpdateKeyFrames(nil, true);
	end
end

function MovieClipTimeLine:OnActorKeyChange()
	if(self.cur_actor) then
		if(not self.cur_actor:IsRecording()) then
			self.cur_actor:FrameMovePlaying(0);
		end
		self:UpdateSubKeyFrames(nil, true);
	end
end

function MovieClipTimeLine.GetKeyFrameCtrl()
	if(not MovieClipTimeLine.ctlKeyFrame) then
		MovieClipTimeLine.ctlKeyFrame = KeyFrameCtrl:new({
			name="keyframe_timeline_",
			uiname = "MovieClipTimeLine.keyframe",
			onclick_frame = MovieClipTimeLine.OnClickCameraKeyFrame,
			onshift_keyframe = MovieClipTimeLine.OnShiftKeyFrame, 
			onremove_keyframe = MovieClipTimeLine.OnRemoveKeyFrame,
			oncopy_keyframe = MovieClipTimeLine.OnCopyKeyFrame,
			onmove_keyframe = MovieClipTimeLine.OnMoveKeyFrame,
			height = MovieClipTimeLine.timelineHeight,
		});
	end	
	return MovieClipTimeLine.ctlKeyFrame;
end

function MovieClipTimeLine.IsDraggingTimeLine()
	if(MovieClipTimeLine.IsMouseCursorInsideTimeLine() and ParaUI.IsMousePressed(0)) then
		return true;
	end
end

function MovieClipTimeLine.IsMouseCursorInsideTimeLine()
	local _this = ParaUI.GetUIObject(movie_clip_timeline_name)
	if(_this:IsValid()) then
		local x, y, width, height = _this:GetAbsPosition();
		local mx, my = ParaUI.GetMousePosition();
		if(my > y) then
			return true;
		end
	end
end

function MovieClipTimeLine.GetSubFrameCtrl()
	if(not MovieClipTimeLine.ctlSubFrame) then
		MovieClipTimeLine.ctlSubFrame = KeyFrameCtrl:new({
			name="subframe_timeline_",
			uiname = "MovieClipTimeLine.subframe",
			onclick_frame = MovieClipTimeLine.OnClickEditSubFrameKey,
			onshift_keyframe = MovieClipTimeLine.OnShiftSubFrame, 
			onremove_keyframe = MovieClipTimeLine.OnRemoveSubFrame,
			oncopy_keyframe = MovieClipTimeLine.OnCopyKeySubFrame,
			onmove_keyframe = MovieClipTimeLine.OnMoveKeySubFrame,
			isShowDataOnTooltip = true,
			height = MovieClipTimeLine.timelineHeight,
		});
	end	
	return MovieClipTimeLine.ctlSubFrame;
end

-- show timeline line block at the bottom of the screen with different color. 
-- @param state: "activated", "playing", "recording", "not_recording", nil. nil to cancel timeline
function MovieClipTimeLine:ShowTimeline(state)
	self.state = state;
	if(not state) then
		local _this = ParaUI.GetUIObject(movie_clip_timeline_name)
		if(_this:IsValid()) then
			_this.visible = false;
		end
		MovieClipTimeLine.OnClosePage();
	else
		local _this = ParaUI.GetUIObject(movie_clip_timeline_name)
		if(not _this:IsValid()) then
			if(System.options.IsTouchDevice) then
				-- make it bigger on touch device
				self:SetControlSize(24, 32);
			end

			_this = ParaUI.CreateUIObject("container", movie_clip_timeline_name, "_mb", 0, 0, 0, self.height);
			_this:SetScript("onclick", MovieClipTimeLine.OnClickTimeLine);
			_this.zorder = -2;
			_this.background = "Texture/whitedot.png";
			-- _this.tooltip = "可拖动时间轴";
			_this:SetScript("onsize", function()
				if(page) then
					page:Refresh();
				end
			end)
			_guihelper.SetFontColor(_this, "#ffffff");
			_this:AttachToRoot();
			page = page or System.mcml.PageCtrl:new({url="script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.html"});
			page:Create("movieclipTimeLine", _this, "_fi", 0, 0, 0, 0);
		end
		_guihelper.SetUIColor(_this, timeline_color_map[state]);
		_this.visible = true;

		NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		local Screen = commonlib.gettable("System.Windows.Screen");
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginBottom(math.floor(self.height * (Screen:GetUIScaling()[2])));
		viewport:SetMarginBottomHandler(self);
		if(GameLogic.options:IsMaintainMovieBlockAspectRatio() and not viewport:GetMarginRightHandler()) then
			-- let us maintain aspect ratio
			viewport:SetMarginRight(math.floor(self.height/Screen:GetHeight()*Screen:GetWidth() * (Screen:GetUIScaling()[1])));
			viewport:SetMarginRightHandler(self);
		end
		if(not self.inited) then
			MovieClipTimeLine.OnInit();
		end
	end
end

function MovieClipTimeLine.OnClickTimeLine()
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		movieClip:OpenEditor();
	end
end

-- update the time display on the timeline
function MovieClipTimeLine:UpdateTimeSlider(curTime, totalTime)
	local msTime = curTime;
	local curTime = curTime / 1000;
	if(page) then
		local ctl = page:FindControl("timeline");
		if(ctl) then
			local movieClip = MovieManager:GetActiveMovieClip();
			if(movieClip) then
				ctl.min = movieClip:GetStartTime();
				ctl.max = movieClip:GetLength();
			end
			ctl:SetValue(msTime);
		end
	end
end

function MovieClipTimeLine.GetEndTime()
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		return movieClip:GetLength();
	end
end


---------------------------------------------------------------
-- ActorCommand related timeline functions
---------------------------------------------------------------

function MovieClipTimeLine.OnClickToggleSubVariable()
	local self =  MovieClipTimeLine;
	
	local varList = self:GetVariableList();
	if(varList) then
		-- display the context menu item.
		local ctl = MovieClipTimeLine.var_menu_ctl;
		if(not ctl)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "MovieClipTimeLine.var_menu_ctl",
				width = 200,
				height = 60, -- add menuitemHeight(30) with each new item
				DefaultNodeHeight = 26,
				-- style = CommonCtrl.ContextMenu.DefaultStyleThick,
				onclick = function (node) 
					if(node.actor) then
						if(node.originalActor and node.originalIndex and node.originalActor~=node.actor) then
							node.originalActor:SetCurrentEditVariableIndex(node.originalIndex);
						end

						node.actor:SetCurrentEditVariableIndex(tonumber(node.Name));

						GameLogic.GetFilters():apply_filters("user_event_stat", "actor", "edit:"..tostring(node.actor:GetEditableVariable().name), 1, nil);

						Game.SelectionManager:selectedActorVariableChanged(node.actor:GetEditableVariable(), node.actor);
					end
				end
			};
			MovieClipTimeLine.var_menu_ctl = ctl;
			ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		end
		
		local node = ctl.RootNode:GetChild(1);
		if(node) then
			node:ClearAllChildren();
			local totalHeight = 0;
			for index, var in ipairs(varList) do
				if(var.index) then
					node:AddChild(CommonCtrl.TreeNode:new({Text = self:GetVariableDisplayName(var.name, true), 
						uiname=ctl.name.."."..(var.name or ""),
						actor=var.actor, originalActor = var.originalActor, originalIndex = var.originalIndex,
						Name = var.index, Type = "Menuitem", onclick = nil, }));
					totalHeight = totalHeight + (ctl.DefaultNodeHeight or ctl.style.DefaultNodeHeight);
				else
					node:AddChild(CommonCtrl.TreeNode:new({Type = "Separator", }));
					totalHeight = totalHeight + ctl.style.separatorHeight;
				end
			end
			ctl.height = totalHeight + 4;
		end
		local x, y, width, height = _guihelper.GetLastUIObjectPos();
		if(x and y)then
			ctl:Show(x, y - ctl.height);
		end
	end
end

function MovieClipTimeLine:GetCmdActor(bCreateIfNotExist)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		return movieClip:GetCommand(bCreateIfNotExist);
	end
end

function MovieClipTimeLine:GetSelectedActor(bCreateIfNotExist)
	if(not self.cur_actor) then
		local actor = self:GetCmdActor(bCreateIfNotExist);
		Game.SelectionManager:SetSelectedActor(actor);
		return actor;
	end
	return self.cur_actor;
end

-- get current variable list.
-- @return variables, actor  
function MovieClipTimeLine:GetVariableList()
	local varList = {};
	
	local actor = self:GetSelectedActor();
	if(actor) then
		if(actor:CanShowCommandVariables()) then
			local cmdActor = self:GetCmdActor(true);
			if(cmdActor) then
				for index, name in ipairs(cmdActor:GetEditableVariableList()) do
					if(name == "---") then
						varList[#varList+1] = {type="seperator"};
					else
						varList[#varList+1] = {name=name, index=index, actor=cmdActor, originalActor = actor, originalIndex = -1};
					end
				end
				varList[#varList+1] = {type="seperator"};
			end
		end
		for index, name in ipairs(actor:GetEditableVariableList()) do
			if(name == "---") then
				varList[#varList+1] = {type="seperator"};
			else
				varList[#varList+1] = {name=name, index=index, actor=actor};
			end
		end
	end
	return varList
end

-- @return var, actor: please note the second actor may not be selected actor, such as camera. 
function MovieClipTimeLine:GetCurrentSubFrameVariable(bCreateIfNotExist)
	local actor = self:GetSelectedActor();
	if(actor) then
		local var = actor:GetEditableVariable();
		if(var) then
			return var, actor;
		end
	end
	actor = self:GetCmdActor(bCreateIfNotExist);
	if(actor) then
		return actor:GetEditableVariable(), actor;
	end
end

function MovieClipTimeLine:GetVariableDisplayName(varname, bUseLongName)
	if(bUseLongName) then
		return var_longname_to_text[varname] or var_name_to_text[varname] or varname;
	else
		return var_name_to_text[varname] or varname;
	end
end

function MovieClipTimeLine:GetCurrentSubFrameVariableDisplayText(bCreateIfNotExist)
	local var = self:GetCurrentSubFrameVariable(bCreateIfNotExist);
	if(var) then
		return self:GetVariableDisplayName(var.name);
	end
end

-- automatically add a key frame to the current time line. 
function MovieClipTimeLine.OnClickAddSubFrameKey()
	local self = MovieClipTimeLine;
	local var, actor = self:GetCurrentSubFrameVariable(true);
	if(var) then
		actor:CreateKeyFromUI(var.name, function(bIsAdded)
			if(bIsAdded) then
				MovieUISound.PlayAddKey();
			end
		end);
	else
		_guihelper.MessageBox(L"无法添加关键帧。可能电影方块中的角色已经满了, 删除一个再试试看")
	end
end

function MovieClipTimeLine.OnClickCameraKeyFrame(time)
	if(mouse_button == "right") then
		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			if(movieClip:GetTime() == time) then
				local var, actor = MovieClipTimeLine:GetCurrentKeyFrameVariable();
				if(time and var and actor) then
					-- if we are already on the time, show the popup menu
					NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFramePopupMenu.lua");
					local KeyFramePopupMenu = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFramePopupMenu");
					KeyFramePopupMenu.ShowPopupMenu(time, var, actor);
				end
			else
				MovieClipTimeLine.OnClickGotoFrame(time);
			end
		end
	else
		-- left click to goto frame. 
		MovieClipTimeLine.OnClickGotoFrame(time)
	end
end


-- edit the command key frame : such as subscript, time, music etc. 
function MovieClipTimeLine.OnClickEditSubFrameKey(time)
	if(mouse_button == "right") then
		
		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			if(movieClip:GetTime() == time) then
				local var, actor = MovieClipTimeLine:GetCurrentSubFrameVariable();
				if(time and var and actor) then
					-- if we are already on the time, show the popup menu
					NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFramePopupMenu.lua");
					local KeyFramePopupMenu = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFramePopupMenu");
					KeyFramePopupMenu.ShowPopupMenu(time, var, actor);
				end
			else
				MovieClipTimeLine.OnClickGotoFrame(time);
			end
		end
	else
		-- left click to goto frame. 
		MovieClipTimeLine.OnClickGotoFrame(time)
	end
end

-- shifting keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnShiftSubFrame(shift_begin_time, offset_time)
	local v, actor = MovieClipTimeLine:GetCurrentSubFrameVariable();
	if(v) then
		actor:BeginModify();
		v:ShiftKeyFrame(shift_begin_time, offset_time);
		actor:EndModify();
	end
end

-- remove keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnRemoveSubFrame(keytime)
	local v, actor = MovieClipTimeLine:GetCurrentSubFrameVariable();
	if(v) then
		actor:BeginModify();
		MovieUISound.PlayRemoveKey();
		v:RemoveKeyFrame(keytime);
		actor:EndModify();
	end
end

function MovieClipTimeLine.OnMoveKeySubFrame(keytime, from_keytime)
	local v, actor = MovieClipTimeLine:GetCurrentSubFrameVariable();
	if(v) then
		actor:BeginModify();
		MovieUISound.PlayRemoveKey();
		v:MoveKeyFrame(keytime, from_keytime);
		actor:EndModify();
	end
end

function MovieClipTimeLine.OnCopyKeySubFrame(keytime, from_keytime)
	local v, actor = MovieClipTimeLine:GetCurrentSubFrameVariable();
	if(v) then
		actor:BeginModify();
		MovieUISound.PlayRemoveKey();
		v:CopyKeyFrame(keytime, from_keytime);
		actor:EndModify();
	end
end


function MovieClipTimeLine:OnVariableNameChange(name)
	local actor = self:GetSelectedActor();
	if(actor) then
		self:SetActorNameText(actor:GetSelectionName());
	end
end

function MovieClipTimeLine:SetActorNameText(name)
	if(page) then
		-- page:SetValue("actorname", name);
		local ctl = page:FindControl("actorname");
		if(ctl) then
			ctl.text = name or "";
			ctl.width = math.max(64, _guihelper.GetTextWidth(name or "", "System;11")+10);
		end
	end
end

-- update the sub keyframe timeline of the current selected actor. 
-- only called privately
function MovieClipTimeLine:UpdateSubKeyFrames(curTime, bForceUpdate)
	local ctl = MovieClipTimeLine.GetSubFrameCtrl();
	local movieClip = MovieManager:GetActiveMovieClip();
	if(ctl and movieClip) then
		if(not curTime) then
			curTime = movieClip:GetTime();
		end
		local need_update = bForceUpdate;

		local actor = self:GetSelectedActor();
		if(self.last_actor ~= actor) then
			self.last_actor = actor;
			if(page) then
				if(actor) then
					self:SetActorNameText(actor:GetSelectionName());
				else
					self:SetActorNameText(L"全局");
				end
			end
		end

		local curSubFrameVar, subVarActor = self:GetCurrentSubFrameVariable();
		if(ctl:GetVariable() ~= curSubFrameVar) then
			ctl:SetVariable(curSubFrameVar);
			if(page) then
				page:SetValue("varname", self:GetCurrentSubFrameVariableDisplayText() or L"文字");
			end
			Game.SelectionManager:selectedActorVariableChanged(curSubFrameVar, subVarActor);

			need_update = true;
		elseif(curSubFrameVar) then
			-- detect if need update. 
			-- need_update = true;
			if(actor and actor:IsRecording()) then
				need_update = true;	
			end
		end
		if(ctl:GetStartTime()~=movieClip:GetStartTime()) then
			ctl:SetStartTime(movieClip:GetStartTime());
			need_update = true;
		end
		if(ctl:GetEndTime()~=movieClip:GetLength()) then
			ctl:SetEndTime(movieClip:GetLength());
			need_update = true;
		end
		if(need_update) then
			local parent = ParaUI.GetUIObject(MovieClipTimeLine.subframes_parent_name);
			if(parent:IsValid()) then
				local x,y, width, height = parent:GetAbsPosition();
				ctl:Update(parent, width, height);
			end
		end
		
		ctl:UpdateCurrentTime(curTime, true);
	end
end

---------------------------------------------------------------
-- ActorCamera|ActorNPC related timeline functions
---------------------------------------------------------------
function MovieClipTimeLine:GetCurrentKeyFrameVariable()
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(actor) then
			return actor:GetMultiVariable(), actor;
		end
	end
end

-- shifting keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnShiftKeyFrame(shift_begin_time, offset_time)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		-- TODO: currently only shifting the camera actor's keyframes, shall we shift all actors in future?
		local actor = movieClip:GetCamera();
		if(actor) then
			actor:ShiftKeyFrame(shift_begin_time, offset_time);
		end
	end
end

-- remove keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnRemoveKeyFrame(keytime)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		-- TODO: currently only shifting the camera actor's keyframes, shall we shift all actors in future?
		local actor = movieClip:GetCamera();
		if(actor) then
			MovieUISound.PlayRemoveKey();
			actor:RemoveKeyFrame(keytime);
		end
	end
end

-- remove keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnCopyKeyFrame(keytime, from_keytime)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(actor) then
			MovieUISound.PlayRemoveKey();
			actor:CopyKeyFrame(keytime, from_keytime);
		end
	end
end

-- remove keyframes from shift_begin_time to end by the amount of offset_time. 
function MovieClipTimeLine.OnMoveKeyFrame(keytime, from_keytime)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(actor) then
			MovieUISound.PlayRemoveKey();
			actor:MoveKeyFrame(keytime, from_keytime);
		end
	end
end

-- goto the given frame 
function MovieClipTimeLine.OnClickGotoFrame(time)
	if(time)then
		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			movieClip:SetTime(time);
		end
	end
end

-- @param lengthMS in ms seconds
function MovieClipTimeLine:UpdateMovieLength()
	if(page) then
		local movieClip = MovieManager:GetActiveMovieClip();
		if(movieClip) then
			local old_time = page:GetUIValue("endtime", 0);
			old_time = tonumber(old_time);
			local time = movieClip:GetLength();
			if(old_time and old_time*1000~=time) then
				page:SetValue("endtime", time/1000);
			end

			local old_time = page:GetUIValue("starttime", 0);
			old_time = tonumber(old_time);
			local time = movieClip:GetStartTime();
			if(old_time and old_time*1000~=time) then
				page:SetValue("starttime", time/1000);
			end
		end
	end
end


-- update the ActorCamera and ActorCommands's timelines (two timelines are both updated)
-- @param bForceUpdate: true to force update. 
function MovieClipTimeLine:UpdateKeyFrames(curTime, bForceUpdate)
	local ctl = MovieClipTimeLine.GetKeyFrameCtrl();
	local movieClip = MovieManager:GetActiveMovieClip();
	if(ctl and movieClip) then
		if(not curTime) then
			curTime = movieClip:GetTime();
		end

		local need_update = bForceUpdate;
		local curTimeVar, actor = self:GetCurrentKeyFrameVariable();
		if(ctl:GetVariable() ~= curTimeVar) then
			ctl:SetVariable(curTimeVar);
			need_update = true;
		elseif(curTimeVar) then
			-- detect if need update. 
			if(actor and actor:IsRecording()) then
				need_update = true;	
			end
		end
		if(ctl:GetStartTime()~=movieClip:GetStartTime()) then
			ctl:SetStartTime(movieClip:GetStartTime());
			need_update = true;
		end

		if(ctl:GetEndTime()~=movieClip:GetLength()) then
			ctl:SetEndTime(movieClip:GetLength());
			need_update = true;
		end
		if(need_update) then
			self:UpdateMovieLength();
		end
		if(need_update) then
			local parent = ParaUI.GetUIObject(MovieClipTimeLine.keyframes_parent_name);
			if(parent:IsValid()) then
				local x,y, width, height = parent:GetAbsPosition();
				ctl:Update(parent, width, height);
			end
		end
		ctl:UpdateCurrentTime(curTime, true);
	end
end

function MovieClipTimeLine.OnTimeChanged(value)
	local movieClip = MovieManager:GetActiveMovieClip();
	if(movieClip) then
		movieClip:SetTime(value);
	end
end

function MovieClipTimeLine.OnChangeStartTime()
	if(page) then
		local value = page:GetUIValue("starttime", 0);
		if(value) then
			value = tonumber(value);
			if(value) then
				local movieClip = MovieManager:GetActiveMovieClip();
				if(movieClip) then
					page:SetNodeValue("starttime", value);
					-- from seconds to ms
					value = math.floor(value * 1000);
					if(value>=0 and value<=movieClip:GetLength()) then
						movieClip:SetStartTime(value);
						-- movieClip:UpdateDisplayTimeRange(value, nil);
					end
				end
			end
		end
	end
end

function MovieClipTimeLine.OnChangeEndTime()
	if(page) then
		local value = page:GetUIValue("endtime", 10000);
		if(value) then
			value = tonumber(value);
			if(value) then
				if(value>=0) then
					page:SetNodeValue("endtime", value);
					local movieClip = MovieManager:GetActiveMovieClip();
					if(movieClip) then
						value = math.floor(value * 1000)
						movieClip:SetLength(value);
					end
				end
			end
		end
	end
end

function MovieClipTimeLine.OnClickTimeButton(value)
	if(mouse_button == "right") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(L"设置当前时间（毫秒）", function(result)
			if(result and result~="") then
				local newTime = result:match("^(%d+)");
				if(newTime) then
					if(page) then
						page:SetValue("timeline", newTime)
						MovieClipTimeLine.OnTimeChanged(page:GetValue("timeline", 0))
					end
				end
			end
		end,tostring(value));
	end
end