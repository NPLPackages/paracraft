--[[
Title: RolePlayMovieController Page
Author(s): LiXizhi
Date: 2021/9/2
Desc: UI page for role playing mode movie block. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
RolePlayMovieController.OnActivate("movie")
RolePlayMovieController.ShowPage(true)
RolePlayMovieController.ShowPage(bShow, movieEntity, OnClose);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/DateTime.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local RolePlayMovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMovieClipTimeLine");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local RolePlayMovieController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController"));
local self = RolePlayMovieController;
RolePlayMovieController.isActorsLocked = true
local defaultEditor = "SimpleRolePlayingEditor"
RolePlayMovieController.timelineHeight = 64;
RolePlayMovieController.max_movieTime = 30000 --单位：ms
local curMovieEntity;
local page;

local ani_path = "Texture/Aries/Creator/keepwork/macro/lessonrubbish/aniicon/"
local player_ani_config = {
	{ani_name="bow",ani_id = 34,ani_icon = "bow_32bits.png",isdefault = true},
	{ani_name="wave",ani_id = 35,ani_icon = "wave_32bits.png",isdefault = true},
	{ani_name="lieside",ani_id = 88,ani_icon = "lieside_32bits.png",isdefault = true},
	{ani_name="dance",ani_id = 144,ani_icon = "dance_32bits.png",isdefault = true},
	{ani_name="clap",ani_id = 145,ani_icon = "clap_32bits.png",isdefault = true},
	{ani_name="nod",ani_id = 31,ani_icon = "nod_32bits.png",},
	{ani_name="shakehead",ani_id = 32,ani_icon = "shakehead_32bits.png",},
	{ani_name="sit",ani_id = 72,ani_icon = "sit_32bits.png",},
	{ani_name="lie",ani_id = 100,ani_icon = "lie_32bits.png",},
	{ani_name="sort",ani_id = 118,ani_icon = "sort_32bits.png",},
	{ani_name="jump",ani_id = 176,ani_icon = "jump_32bits.png",},
	{ani_name="dazuo",ani_id = 187,ani_icon = "dazuo_32bits.png",},
	{ani_name="pushup",ani_id = 188,ani_icon = "pushup_32bits.png",},
	{ani_name="dizzy",ani_id = 189,ani_icon = "dizzy_32bits.png",},
	{ani_name="hooray",ani_id = 191,ani_icon = "hooray_32bits.png",},
}

RolePlayMovieController:Signal("beforeActorFocusChanged");
RolePlayMovieController:Signal("afterActorFocusChanged");
-- virtual function: for MovieClipEditors's player class
function RolePlayMovieController.ShowPlayEditorForMovieClip(movieClip)
	--print("ShowPlayEditorForMovieClip===================")
	if movieClip then
		--print("movieClip=======================")
		MovieManager:SetActiveMovieClip(movieClip);
		RolePlayMovieController:OnActiveMovieClipChange(movieClip)
	end
	-- RolePlayMovieController.ShowPage(true)
	return movieClip
end

function RolePlayMovieController.OnInit()
	local self = RolePlayMovieController
	page = document:GetPageCtrl();
	page.OnCreate = RolePlayMovieController.OnCreate
	self.AutoSelectActorInEditor()
	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = self.OnTimer})
	self.mytimer:Change(200, 200);
	
end


function RolePlayMovieController.AutoSelectActorInEditor()
	local activeClip = MovieManager:GetActiveMovieClip()
	local entity = activeClip and activeClip:GetEntity();
	if(not entity) then
		return
	end
	if(entity:GetSelectedActorIndex()) then
		local itemStack = entity.inventory:GetItem(entity:GetSelectedActorIndex())		
		if(itemStack) then
			RolePlayMovieController.SetFocusToItemStack(itemStack);
			return
		end
	end
	local codeEntity = entity:GetNearByCodeEntity();
	if(codeEntity) then
		local firstActor = entity:GetFirstActorStack();
		if(firstActor) then
			--print("firstActor===================2",tostring(firstActor))
			RolePlayMovieController.SetFocusToItemStack(firstActor);
		end
	else
		local cameraItem = entity:GetCameraItemStack();
		if(cameraItem) then
			RolePlayMovieController.SetFocusToItemStack(cameraItem);
		end
	end
end



function RolePlayMovieController:OnActiveMovieClipChange(clip)
	if(self.activeClip~=clip) then
		if(self.activeClip) then
			-- self.activeClip:Disconnect("remotelyUpdated", self, self.OnMovieClipChange);
			self.activeClip:Disconnect("stateChanged", self, self.OnChangeMovieClipState);
		end
		if(clip) then
			-- clip:Connect("remotelyUpdated", self, self.OnMovieClipRemotelyUpdated, "UniqueConnection");
			clip:Connect("stateChanged", self, self.OnChangeMovieClipState, "UniqueConnection");
		end
		self.activeClip = clip;
	end
end

-- @param state: "activated", "deactivated", "recording", "not_recording", "playmodeChange", "replay"
function RolePlayMovieController:OnChangeMovieClipState(state)
	if RolePlayMovieController.controll_mode == "main" then
		if state == "activated" or state == "playmodeChange" then
			RolePlayMovieController.OnClickGodMode() --这个是保证选中主角，一般情况下，刚创建的电影方块是已经选中了主角的
			commonlib.TimerManager.SetTimeout(function()
				local ParaLifeMainUI = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeMainUI.lua");
				ParaLifeMainUI.ShowView()
			end, 200);
		end
	else
		if(state == "activated" or state == "playmodeChange") then
			if(GameMode:CanShowTimeLine() and (MovieManager:IsLastModeEditor() and not MovieManager:IsCapturing())) then
				RolePlayMovieController.ShowPage(true)
				self:ShowTimeline(state)
			else
				RolePlayMovieController.ShowPage(false)
				self:ShowTimeline(nil);
			end
		elseif(state == "deactivated") then
			self:ShowTimeline(nil);
			RolePlayMovieController.ShowPage(false);
		elseif(state == "recording") then
			self:ShowTimeline("recording")
		elseif(state == "not_recording") then
			self:ShowTimeline("not_recording")
		elseif(state == "replay") then
			RolePlayMovieController.SetFocusToItemStackCamera();
		end
	end
	
end

function RolePlayMovieController:ShowTimeline(state)
	RolePlayMovieClipTimeLine:ShowTimeline(state)
end

-- @param bShow: true to show
-- @param movieEntity: if nil, we will use current active movie clip, if nil, a virtual in-memory movieEntity will be created. 
function RolePlayMovieController.ShowPage(bShow, movieEntity, OnClose)
	-- if(bShow) then
	-- 	if(not movieEntity) then
	-- 		local movieClip = MovieManager:GetActiveMovieClip()
	-- 		if(movieClip) then
	-- 			movieEntity = movieClip:GetEntity()
	-- 		end
	-- 		movieEntity = movieEntity or RolePlayMovieController.CreateVirtualMovieEntity()
	-- 	end
	-- 	movieEntity:SetDefaultEditor("SimpleRolePlayingEditor");
	-- 	curMovieEntity = movieEntity
	-- 	QuickSelectBar.ShowPage(false);
	-- end
	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.html", 
			name = "RolePlayMovieController.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			bShow = bShow,
			click_through = true, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	if(bShow) then
		-- RolePlayMovieController.GetSceneContext():activate();
		QuickSelectBar.ShowPage(false);
		-- NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		-- local Screen = commonlib.gettable("System.Windows.Screen");
		-- local viewport = ViewportManager:GetSceneViewport();
		-- viewport:SetMarginBottom(math.floor(self.timelineHeight * (Screen:GetUIScaling()[2])));
		-- viewport:SetMarginBottomHandler(self);
		-- if(GameLogic.options:IsMaintainMovieBlockAspectRatio() and not viewport:GetMarginRightHandler()) then
		-- 	-- let us maintain aspect ratio
		-- 	viewport:SetMarginRight(math.floor(self.timelineHeight/Screen:GetHeight()*Screen:GetWidth() * (Screen:GetUIScaling()[1])));
		-- 	viewport:SetMarginRightHandler(self);
		-- end
		RolePlayMovieController.SetFocusToActor();
		params._page.OnClose = function()
			RolePlayMovieController.OnClosePage()
			if(OnClose) then
				OnClose();
			end
			page = nil;
		end
	end
end

function RolePlayMovieController.OnActivate(mode,movieEntity) --main movie
	RolePlayMovieController.ClearEntity()
	RolePlayMovieController.controll_mode = mode or "movie"
	local isCreate = true
	if(not movieEntity and not curMovieEntity) then
		print("create or get movie entity")
		local movieClip = MovieManager:GetActiveMovieClip()
		if(movieClip) then
			movieEntity = movieClip:GetEntity()
			isCreate = false
		end
		movieEntity = movieEntity or RolePlayMovieController.CreateVirtualMovieEntity()
	end
	
	curMovieEntity = curMovieEntity or movieEntity
	curMovieEntity:SetDefaultEditor(defaultEditor);
	if isCreate then
		curMovieEntity:OpenEditor()
	end
end

function RolePlayMovieController.ClearEntity()
	-- if RolePlayMovieController.controll_mode == "main" then --保存当前电影方块的数据
		
	-- end
	if curMovieEntity then
		--curMovieEntity = nil
		MovieManager:SetActiveMovieClip(nil);
	end
end

function RolePlayMovieController.IsVisible()
	if(page) then
		return page:IsVisible();
	end
end

function RolePlayMovieController.GetalExistsRoleData()
	local movieClip = MovieManager:GetActiveMovieClip()
	if movieClip then
		return movieClip:GetEntity():GetAllActorData()
	end
end

function RolePlayMovieController.OnClosePage()
	GameLogic.ActivateDefaultContext()
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

function RolePlayMovieController.CreateVirtualMovieEntity()
	local movieEntity = EntityManager.EntityMovieClip:new();
	local entityData = {attr={bx=19200,by=5,bz=19196,class="EntityMovieClip",isUseNplBlockly=true,defaultEditor = defaultEditor, item_id=228,},name="entity",};
	movieEntity:SetCommand("/t 30 /end")
	movieEntity:LoadFromXMLNode(entityData);
	--movieEntity:Attach()
	return movieEntity
end

function RolePlayMovieController.GetSceneContext()
	if(not RolePlayMovieController.movieContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
		local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
		RolePlayMovieController.movieContext = AllContext:GetContext("roleplay");
	end
	return RolePlayMovieController.movieContext;
end

function RolePlayMovieController.AddRoleToEntity(params)
	local movieClip = RolePlayMovieController.GetMovieClip()
	local type = params.type or "npc"
	if movieClip then
		if type == "npc" then
			RolePlayMovieController.CreateNpc(params)
		elseif type == "camera" then
			RolePlayMovieController.CreateCamera(params)
		end
		RolePlayMovieController.UpdateActors()
		RolePlayMovieController.ToggleLockAllActors(false)

	end
end

function RolePlayMovieController.UpdateActors()
	local movieClip = RolePlayMovieController.GetMovieClip()
	if movieClip then
		movieClip:UpdateActors();
	end
end

function RolePlayMovieController.CreateNpc(params)
	local movieClip = RolePlayMovieController.GetMovieClip()
	if not movieClip then
		return 
	end
	local itemStack = movieClip:CreateNPC();
	if itemStack then
		local actor = movieClip:GetActorFromItemStack(itemStack,true)
		if actor then
			actor:SetTime(0);
			actor:FrameMove(0);
			local entity = actor:GetEntity();
			if(entity) then
				entity:SetSkipPicking(true)
			end
			--echo(actor)
			--添加皮肤或者其他的actor属性
			local assetfile = params.assetfile
			if assetfile and assetfile~= "" then
				actor:AddKeyFrameByName("assetfile", 0, assetfile);
			end
			local skin = params.skin
			if skin and skin ~= "" then
				actor:AddKeyFrameByName("skin", 0, skin);
			end
			actor:FrameMovePlaying(0);
			RolePlayMovieController.SetFocusToItemStack(nil)
		end
	end
end

function RolePlayMovieController.CreateCamera()
		
end

function RolePlayMovieController.GetEmptySlot()
	local movieClip = RolePlayMovieController.GetMovieClip()
	if movieClip then
		local inventory = movieClip:GetEntity():GetInventory()
		if inventory then
			local num = inventory:GetSlotCount()
			for i=1,num do
				local itemStack = inventory:GetItem(i)
				if not itemStack then
					return i
				end
			end
		end
		return -1
	end
	return -1
end

function RolePlayMovieController.RemoveSlotItem(slotIndex)
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		local inventory = movieClip:GetEntity():GetInventory()
		if inventory then
			local itemStack = inventory:GetItem(slotIndex) 
			if itemStack then
				inventory:RemoveItem(slotIndex)
				RolePlayMovieController.SetFocusToItemStack(nil)
			end
		end
	end
end

function RolePlayMovieController.SelectSlotItem(slotIndex)
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		local inventory = movieClip:GetEntity():GetInventory()
		if inventory then
			if slotIndex == -1 then
				RolePlayMovieController.SetFocusToItemStack(nil)
				return
			end
			local itemStack = inventory:GetItem(slotIndex) 
			if itemStack and itemStack.id == block_types.names.TimeSeriesNPC then
				RolePlayMovieController.SetFocusToItemStack(itemStack)
			end
		end
	end
end

function RolePlayMovieController.UpdateSlotItem(slotIndex,skin)
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		local inventory = movieClip:GetEntity():GetInventory()
		if inventory then
			local itemStack = inventory:GetItem(slotIndex) --AddKeyFrameByName("skin", nil, skin);
			if itemStack and itemStack.id == block_types.names.TimeSeriesNPC then
				local actor = movieClip:GetActorFromItemStack(itemStack, nil, true);
				if(actor) then
					if skin and skin ~= "" then
						actor:AddKeyFrameByName("skin", nil, skin);
					end
					actor:FrameMovePlaying(0);
				end
			end
		end
		
	end
end

function RolePlayMovieController.SetFocusToItemStackCamera()
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(actor) then
			RolePlayMovieController.SetFocusToItemStack(actor:GetItemStack());
		end
	end
end

-- actor-cammera self:AddKeyFrameByName("eye_rot_y", nil, vars[3]); -- 0,0; 90;0.5; 180,1 ;270,1.5
-- actor-cammera self:AddKeyFrameByName("eye_dist", nil, result); --scaling default 8
--[[self:AddKeyFrameByName("x", nil, x);
	self:AddKeyFrameByName("y", nil, y);
	self:AddKeyFrameByName("z", nil, z);]]

function RolePlayMovieController.OnExitWorld()
	if(page) then
		page:CloseWindow();
		page = nil
	end
	MovieManager:SetActiveMovieClip(nil);
	RolePlayMovieController.OnClosePage()
	RolePlayMovieController.actor_ani_config = {}
end

function RolePlayMovieController.OnClose()
	if(page) then
		page:CloseWindow();
	end
	MovieManager:SetActiveMovieClip(nil);
	-- RolePlayMovieController.OnActivate("main")
end


function RolePlayMovieController.RestoreFocusToCurrentPlayer()
	local player = EntityManager.GetPlayer();
	if(player) then
		player:SetFocus();
		Game.SelectionManager:SetSelectedActor(nil);
	end
end

function RolePlayMovieController.IsRecording()
	local actor = RolePlayMovieController.GetMovieActor();
	if(actor) then
		return actor:IsRecording();
	end
end

function RolePlayMovieController.GetMovieActor()
	local itemStack = RolePlayMovieController.GetItemStack();
	if(itemStack) then
		local movieClip = MovieManager:GetActiveMovieClip()
		if(movieClip) then
			local actor = movieClip:GetActorFromItemStack(itemStack, nil, true);
			if(actor) then
				return actor;
			end
		end
		-- deselect actor if it no longer exist. 
		RolePlayMovieController.SetFocusToItemStack(nil);
	end
end

function RolePlayMovieController.GetItemID()
	local itemStack = RolePlayMovieController.GetItemStack()
	return itemStack and itemStack.id;
end

function RolePlayMovieController.GetItemStack()
	local movieClip = RolePlayMovieController.GetMovieClip()
	return movieClip and movieClip:GetCurrentItemStack();
end

function RolePlayMovieController.GetMovieClip()
	return MovieManager:GetActiveMovieClip()
end

local index = 0

function RolePlayMovieController.SetFocusToItemStack(itemStack)
	local curItemChanged;
	local movieClip = RolePlayMovieController.GetMovieClip()
	if(movieClip:GetCurrentItemStack() ~= itemStack) then
		movieClip:SetCurrentItemStack(itemStack);
		curItemChanged = true;
		if(page) then
			page:Refresh(0.1);
		end
	end
	RolePlayMovieController.SetFocusToActor();
	return curItemChanged;
end

-- if not active actor, we will set focus backto current player
function RolePlayMovieController.SetFocusToActor()
	local actor = RolePlayMovieController.GetMovieActor();
	if(actor) then
		RolePlayMovieController:beforeActorFocusChanged();
		actor:SetFocus();
		Game.SelectionManager:SetSelectedActor(actor);
		RolePlayMovieController:afterActorFocusChanged();
	else
		RolePlayMovieController.RestoreFocusToCurrentPlayer();
	end
end

--下面是UI相关
function RolePlayMovieController.OnTimer(timer)
	if(page) then
		RolePlayMovieController.UpdateTime()
		-- RolePlayMovieController.UpdateUI();
	else
		timer:Change();
	end
end

function RolePlayMovieController.UpdateTime()
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip) then
		local curTime = movieClip:GetTime();
		if(curTime and RolePlayMovieController.last_time~=curTime) then
			RolePlayMovieController.last_time = curTime;
			local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
			local ms = curTime - (tonumber(m)*60*1000 + tonumber(math.floor(s))*1000)
			if(page and h) then
				page:SetValue("recordtime", string.format("%.2d:%.2d:%.3d", m,math.floor(s),ms));
			end
		end
	end
end

local off_maps = {
	["Texture/Aries/Creator/player/key_off.png"] = "Texture/Aries/Creator/player/key_on.png",
	["Texture/Aries/Creator/player/auto_off.png"] = "Texture/Aries/Creator/player/auto_on.png",
	["Texture/Aries/Creator/player/play_off.png"] = "Texture/Aries/Creator/player/suspend_off.png",
	["Texture/Aries/Creator/player/god_off.png"] = "Texture/Aries/Creator/player/god_on.png",
	["Texture/blocks/items/ts_char_off.png"] = "Texture/blocks/items/ts_char_on.png",
}

local on_maps = {
	["Texture/Aries/Creator/player/key_on.png"] = "Texture/Aries/Creator/player/key_off.png",
	["Texture/Aries/Creator/player/auto_on.png"] = "Texture/Aries/Creator/player/auto_off.png",
	["Texture/Aries/Creator/player/suspend_off.png"] = "Texture/Aries/Creator/player/play_off.png",
	["Texture/Aries/Creator/player/god_on.png"] = "Texture/Aries/Creator/player/god_off.png",
	["Texture/blocks/items/ts_char_on.png"] = "Texture/blocks/items/ts_char_off.png",
}

function RolePlayMovieController.ToggleButtonBg(uiobj, bIsOn)
	if(uiobj) then
		local background = uiobj.background:gsub("[;:].*$", "");
		local filename;
		if( bIsOn ) then
			filename = off_maps[background];
		else
			filename = on_maps[background];
		end
		if(filename and filename ~= background) then
			uiobj.background = filename;
		end
	end
end

-- update button pressed and unpressed state. 
function RolePlayMovieController.UpdateUI()
	if(page) then
		local actor = RolePlayMovieController.GetMovieActor();
		if(actor) then
			if(actor:IsRecording())then
				if(actor:IsPaused()) then
					RolePlayMovieController.ToggleButtonBg(page:FindControl("record"), false);
				else
					RolePlayMovieController.ToggleButtonBg(page:FindControl("record"), true);
				end
				RolePlayMovieController.ToggleButtonBg(page:FindControl("play"), false);	
			else
				RolePlayMovieController.ToggleButtonBg(page:FindControl("record"), false);
				
				if(actor:IsPaused()) then
					RolePlayMovieController.ToggleButtonBg(page:FindControl("play"), false);	
				else
					RolePlayMovieController.ToggleButtonBg(page:FindControl("play"), true);	
				end
			end
		else
			local movieClip = RolePlayMovieController.GetMovieClip();
			if(movieClip) then
				if(movieClip:IsPaused()) then
					RolePlayMovieController.ToggleButtonBg(page:FindControl("play"), false);
				else
					RolePlayMovieController.ToggleButtonBg(page:FindControl("play"), true);
				end
			end
		end
	end
end

function RolePlayMovieController.OnRecord()
	local actor = RolePlayMovieController.GetMovieActor();
	-- --print("actor==============1")
	if(actor) then
		-- --print("actor==============2")
		if(actor.class_name == "ActorCamera_CANCELED") then
			-- _guihelper.MessageBox("摄影机不支持扮演");
		else
			local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
			if(shift_pressed) then
				-- shift click to record and pause, thus clearing all animations from current frame to end. 
				RolePlayMovieController.ClearAllAnimationFromCurrentFrame();
			else
				-- --print("actor==============3")
				if(actor:IsPaused()) then
					actor:SetRecording(true);
					actor:Resume();
				else
					-- --print("actor==============4")
					actor:SetRecording(false);
					actor:Pause();
				end
			end
		end
    end
end

-- record and pause, thus clearing all animations from current frame to end. 
function RolePlayMovieController.ClearAllAnimationFromCurrentFrame()
	local actor = RolePlayMovieController.GetMovieActor();
    if(actor) then
		if(actor:IsPaused()) then
			actor:SetRecording(true);
			actor:Pause();
		end
	end
end

function RolePlayMovieController.OnPause()
	local actor = RolePlayMovieController.GetMovieActor();
    if(actor) then
        actor:SetRecording(false);
        if(not actor:IsPaused()) then
            actor:Pause();
        end
    end
end

function RolePlayMovieController.OnPlay()
	local actor = RolePlayMovieController.GetMovieActor();
    if(actor) then
        actor:SetRecording(false);
    end
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip) then
		if(movieClip:IsPaused()) then
            movieClip:Resume();
		else
			movieClip:Pause();
        end
	end
end

function RolePlayMovieController.OnGotoBeginFrame()
	RolePlayMovieController.OnPause();
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip) then
		movieClip:SetTime(movieClip:GetStartTime());
		movieClip:Pause();
	end
end

function RolePlayMovieController.OnGotoEndFrame()
	RolePlayMovieController.OnPause();
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip) then
		movieClip:GotoEndFrame();
		movieClip:Pause();
	end
end

function RolePlayMovieController.OnCaptureVideo()
	MovieManager:ToggleCapture();
end

function RolePlayMovieController.OnSettings()
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip) then
		local selectedActor = movieClip:GetSelectedActor();
		if(selectedActor) then
			-- select me to edit. 
			selectedActor:SelectMe();
		else
			local entity = movieClip:GetEntity();
			if(entity and entity.OpenBagEditor) then
				entity:OpenBagEditor();
			end
		end
	end
end

-- @param bLock: if nil, means toggle
function RolePlayMovieController.ToggleLockAllActors(bLock)
	if(bLock == nil) then
		RolePlayMovieController.isActorsLocked = not RolePlayMovieController.isActorsLocked;
	else
		RolePlayMovieController.isActorsLocked = bLock;
	end
	RolePlayMovieController.UpdateUI();
	local movieClip = RolePlayMovieController.GetMovieClip();
	if(movieClip and movieClip:IsPaused()) then
		movieClip:FrameMove(0);
		if(RolePlayMovieController.IsActorsLocked()) then
			movieClip:UpdateActors(0);
		end
	end
end

function RolePlayMovieController.IsActorsLocked()
	return RolePlayMovieController.isActorsLocked;
end

function RolePlayMovieController.OnClickGodMode()
	-- actually deselect
	RolePlayMovieController.SetFocusToItemStack(nil);
	-- TODO: show quick select panel. 
end


function RolePlayMovieController.GetDefaultAni()
	local defaultAni = {}
	for i=1,#player_ani_config do
		if player_ani_config[i].isdefault then
			defaultAni[#defaultAni + 1] = player_ani_config[i]
		end
	end
	return defaultAni
end

function RolePlayMovieController.GetAniIconById(aniId)
	local path = ani_path
	for i=1,#player_ani_config do
		local cnf = player_ani_config[i]
		if cnf and cnf.ani_id == aniId then
			path = path..cnf.ani_icon..";0 0 170 170"
			break
		end
	end
	print("ani path ==============",path)
	return path
end

function RolePlayMovieController.InitBtnAniIcon()
	local default = RolePlayMovieController.GetDefaultAni()
	for i=1,5 do
		local uiname = "RolePlayMovieController.actor_ani"..i
		local btn = ParaUI.GetUIObject(uiname)
		local cnf = default[i]
		if cnf and cnf.ani_id then
			local background = RolePlayMovieController.GetAniIconById(cnf.ani_id)
			btn.background = background
		end
	end
	RolePlayMovieController.cur_btn_anis = default
end

function RolePlayMovieController.ChangeAni(index,ani_id)
	local uiname = "RolePlayMovieController.actor_ani"..index
	local btn = ParaUI.GetUIObject(uiname)
	btn.background = RolePlayMovieController.GetAniIconById(ani_id)
	local select_anim = RolePlayMovieController.GetAnimById(ani_id)
	RolePlayMovieController.cur_btn_anis[index] = select_anim
	echo(RolePlayMovieController.cur_btn_anis,true)
end

function RolePlayMovieController.GetAnimById(anim_id)
	for i=1,#player_ani_config do
		local cnf = player_ani_config[i]
		if cnf and cnf.ani_id == anim_id then
			return cnf
		end
	end
end

function RolePlayMovieController.OnInitButton()
	local self = RolePlayMovieController
	self.InitBtnAniIcon()
	for i=1,5 do
		local uiname = "RolePlayMovieController.actor_ani"..i
		local btn = ParaUI.GetUIObject(uiname)
		 print("uiname==========",uiname)
		-- echo(btn)
		if btn and btn:IsValid()then
			 print("addEvent===================1111111111")
			btn:SetScript("ontouch", function() 
				self:OnTouch(msg,i) 
			end);
			btn:SetScript("onmousedown", function() self:OnMouseDown(i) end);
			btn:SetScript("onmouseup", function() self:OnMouseUp(i) end);
		end
	end
end

-- simulate the touch event with id=-1
function RolePlayMovieController:OnMouseDown(touchIndex)
	print("OnMouseDown============")
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch,touchIndex);
end

-- simulate the touch event
function RolePlayMovieController:OnMouseUp(touchIndex)
	print("OnMouseUp============")
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch,touchIndex);
end

-- handleTouchEvent
function RolePlayMovieController:OnTouch(touch,touchIndex)
	-- handle the touch
	local self = RolePlayMovieController
	local touch_session = TouchSession.GetTouchSession(touch);
	local btnItem = self:GetButtonItem(touchIndex);
	-- let us track it with an item. 
	local curTime = os.time()
	if(touch.type == "WM_POINTERDOWN") then
		if(btnItem) then
			touch_session:SetField("keydownBtn", btnItem);
			self:SetKeyState(btnItem, true);
			btnItem.isDragged = nil;
			curTime = os.time()
			RolePlayMovieController.touch_time = curTime
		end
	elseif(touch.type == "WM_POINTERUPDATE") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
			
			
		end
		
	elseif(touch.type == "WM_POINTERUP") then
		self:SetKeyState(btnItem, false);
		local ani_id = RolePlayMovieController.cur_btn_anis[touchIndex].ani_id
		curTime = os.time()
		local btnName = btnItem.name
		if curTime - RolePlayMovieController.touch_time >= 1 then --长按
			-- GameLogic.AddBBS(nil,"开始===============")
			RolePlayMovieController.touch_time = curTime
			local ParaLifeSelectAnimate = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectAnimate.lua") 
    		ParaLifeSelectAnimate.ShowView(ani_id,function(select_anim_id)
				RolePlayMovieController.ChangeAni(touchIndex,select_anim_id)
			end)
			return
		end
		-- GameLogic.AddBBS(nil,"播放动作，或者电影方块添加动作")
		--播放动作，或者电影方块添加动作
		print("ani_id=============",ani_id)
		RolePlayMovieController.PlayPlayerAni(ani_id)
	end
	
end

function RolePlayMovieController.PlayPlayerAni(ani_id)
	if not ani_id or ani_id < 0 then
		return
	end
	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local player = EntityManager:GetFocus()--GameLogic.GetPlayer()
	if player then
		local obj = player:GetInnerObject();
		if(obj) then
			obj:ToCharacter():PlayAnimation(ani_id);
		end
	end
end

--{normal="#ffffff", pressed="#888888"}, 
function RolePlayMovieController:SetKeyState(btnItem, bPress);
	if btnItem and btnItem:IsValid() then
		if bPress then
			_guihelper.SetUIColor(btnItem, "#888888");
		else
			_guihelper.SetUIColor(btnItem, "#ffffff");
		end
	end
end

-- get button item by global touch screen position. 
function RolePlayMovieController:GetButtonItem(touchIndex)
	local btn = ParaUI.GetUIObject("RolePlayMovieController.actor_ani"..touchIndex)
	if btn and btn:IsValid() then
		return btn
	end
end

function RolePlayMovieController.OnCreate()
    -- RolePlayMovieController.InitOperateBtn()
    -- RolePlayMovieController.InitViewBtn()
	print("RolePlayMovieController.OnCreate=")
    RolePlayMovieController.OnInitButton()
	local root = ParaUI.GetUIObject("RolePlayMovieController.cameraOperate");
    root.visible = false
	commonlib.TimerManager.SetTimeout(function ()
        RolePlayMovieController.InitAnimPlayer()
    end, 100);
end

function RolePlayMovieController.GetUIPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("movie_role_anim")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                return player
            end
        end
    end
end

function RolePlayMovieController.InitAnimPlayer()
    local player = RolePlayMovieController.GetUIPlayer()
    if player then
        player:SetScale(1)
        player:SetFacing(1.57);
        player:SetField("HeadUpdownAngle", 0.3);
        player:SetField("HeadTurningAngle", 0);
    end
end

function RolePlayMovieController.ShowRolePage()
	local ParaLifeSelectRole = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectRole.lua") 
	ParaLifeSelectRole.ShowView(function(model,skin)
		RolePlayMovieController.UpdateRoleIcon(model,skin)
	end)
end

function RolePlayMovieController.UpdateRoleIcon(model,skin)
	
end

function RolePlayMovieController.OnCut()
	GameLogic.AddBBS(nil,"功能暂未开放敬请期待")
	-- local movieClip = RolePlayMovieController.GetMovieClip();
	-- local curTime = movieClip:GetTime()
	-- local movielength = movieClip:GetLength()
	-- local startTime = movieClip:GetStartTime()
	-- if curTime <= startTime or curTime >= movielength then
	-- 	GameLogic.AddBBS(nil,"请选择正确的剪切时间段")
	-- 	return 
	-- end
	-- local trimToEnd = false
	-- local actor = movieClip:GetCamera();
	-- if(actor) then
	-- 	local offset_time = 0
	-- 	local params = {}
	-- 	params.curTime = curTime
	-- 	params.startTime = startTime
	-- 	params.timeLength = movielength

	-- 	local cutMovie = NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/cutMovie.lua");
    -- 	cutMovie.ShowView(params,function(isCancel,isTrimEnd)
	-- 		if isCancel then
	-- 			return
	-- 		end
	-- 		if isTrimEnd then
	-- 			offset_time = movielength - curTime
	-- 			actor:ShiftKeyFrame(curTime, offset_time);
	-- 			movieClip:SetLength(curTime)
	-- 			return
	-- 		end
	-- 		offset_time = curTime - startTime
	-- 		actor:ShiftKeyFrame(startTime, offset_time);
	-- 		movieClip:SetStartTime(curTime)
	-- 		movieClip:SetTime(curTime)
	-- 		movieClip:SetLength(movielength)
	-- 	end)
	-- end
end



