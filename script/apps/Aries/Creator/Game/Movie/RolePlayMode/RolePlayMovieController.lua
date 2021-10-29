--[[
Title: RolePlayMovieController Page
Author(s): LiXizhi
Date: 2021/9/2
Desc: UI page for role playing mode movie block. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
RolePlayMovieController.ShowPage(true)
RolePlayMovieController.ShowPage(bShow, movieEntity, OnClose);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/DateTime.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local RolePlayMovieController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController"));
local self = RolePlayMovieController;

RolePlayMovieController.timelineHeight = 64;
local curMovieEntity;
local page;

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
	page = document:GetPageCtrl();
	RolePlayMovieController.AutoSelectActorInEditor()
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
	if(state == "activated" or state == "playmodeChange") then
		-- if(GameMode:CanShowTimeLine() and (MovieManager:IsLastModeEditor() and not MovieManager:IsCapturing())) then
		-- 	self:ShowAllGUI(true);
		-- else
		-- 	self:ShowAllGUI(false);
		-- end
		RolePlayMovieController.ShowPage(true)
	elseif(state == "deactivated") then
		-- self:ShowTimeline(nil);
		-- MovieClipController.ShowPage(false);
	elseif(state == "recording") then
		-- self:ShowTimeline("recording")
	elseif(state == "not_recording") then
		-- self:ShowTimeline("not_recording")
	elseif(state == "replay") then
		-- MovieClipController.SetFocusToItemStackCamera();
	end
end

-- @param bShow: true to show
-- @param movieEntity: if nil, we will use current active movie clip, if nil, a virtual in-memory movieEntity will be created. 
function RolePlayMovieController.ShowPage(bShow, movieEntity, OnClose)
	if(bShow) then
		if(not movieEntity) then
			local movieClip = MovieManager:GetActiveMovieClip()
			if(movieClip) then
				movieEntity = movieClip:GetEntity()
			end
			movieEntity = movieEntity or RolePlayMovieController.CreateVirtualMovieEntity()
		end
		movieEntity:SetDefaultEditor("SimpleRolePlayingEditor");
		curMovieEntity = movieEntity
	end
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
		RolePlayMovieController.GetSceneContext():activate();
		
		NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		local Screen = commonlib.gettable("System.Windows.Screen");
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginBottom(math.floor(self.timelineHeight * (Screen:GetUIScaling()[2])));
		viewport:SetMarginBottomHandler(self);
		if(GameLogic.options:IsMaintainMovieBlockAspectRatio() and not viewport:GetMarginRightHandler()) then
			-- let us maintain aspect ratio
			viewport:SetMarginRight(math.floor(self.timelineHeight/Screen:GetHeight()*Screen:GetWidth() * (Screen:GetUIScaling()[1])));
			viewport:SetMarginRightHandler(self);
		end
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

function RolePlayMovieController.IsVisible()
	if(page) then
		return page:IsVisible();
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
	local entityData = {attr={bx=19200,by=5,bz=19196,class="EntityMovieClip",isUseNplBlockly=true,item_id=228,},name="entity",};
	movieEntity:LoadFromXMLNode(entityData);
	return movieEntity
end

function RolePlayMovieController.GetSceneContext()
	if(not RolePlayMovieController.movieContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieContext.lua");
		local RolePlayMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext");
		RolePlayMovieController.movieContext = RolePlayMovieContext:new();
	end
	return RolePlayMovieController.movieContext;
end

function RolePlayMovieController.AddRoleToEntity(params)
	local type = params.type or "npc"
	if curMovieEntity then
		if type == "npc" then
			RolePlayMovieController.CreateNpc(params)
		elseif type == "camera" then
			RolePlayMovieController.CreateCamera(params)
		end
	end
end

function RolePlayMovieController.CreateNpc(params)
	local itemStack = curMovieEntity:CreateNPC();
	if(itemStack) then
		local item = itemStack:GetItem();
		if(item and item.CreateActorFromItemStack) then
			local actor = item:CreateActorFromItemStack(itemStack, curMovieEntity, false, "ActorForRolePlayMovie");
			if(actor) then
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
				actor:FrameMovePlaying(0);
			end
		end
	end
end

function RolePlayMovieController.CreateCamera()
	
end

--[[self:AddKeyFrameByName("x", nil, x);
	self:AddKeyFrameByName("y", nil, y);
	self:AddKeyFrameByName("z", nil, z);]]

function RolePlayMovieController.OnClose()
	if(page) then
		page:CloseWindow();
	end
	MovieManager:SetActiveMovieClip(nil);
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
	-- --print("RolePlayMovieController.GetMovieActor===========1")
	-- echo(itemStack)
	if(itemStack) then
		-- --print("RolePlayMovieController.GetMovieActor===========2")
		local movieClip = MovieManager:GetActiveMovieClip()
		if(movieClip) then
			-- --print("RolePlayMovieController.GetMovieActor===========3")
			local actor = movieClip:GetActorFromItemStack(itemStack, nil, true);
			--print("====================222",tostring(actor),tostring(itemStack),tostring(movieClip))
			if(actor) then
				return actor;
			end
		end
		-- deselect actor if it no longer exist. 
		-- --print("actor not exists")
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
	-- commonlib.echo(commonlib.debugstack(2, 5, 1),true)
	-- echo(itemStack)
	local curItemChanged;
	local movieClip = RolePlayMovieController.GetMovieClip()
	-- echo(movieClip)
	index = index + 1
	-- --print("SetFocusToItemStack=========",index, tostring(itemStack))
	-- --print("===============",movieClip:GetCurrentItemStack() ~= itemStack)
	if(movieClip:GetCurrentItemStack() ~= itemStack) then
		movieClip:SetCurrentItemStack(itemStack);
		curItemChanged = true;
		if(page) then
			page:Refresh(0.1);
		end
	end
	-- --print("SetFocusToItemStack=========12")
	RolePlayMovieController.SetFocusToActor();
	return curItemChanged;
end

-- if not active actor, we will set focus backto current player
function RolePlayMovieController.SetFocusToActor()
	-- --print("SetFocusToActor========1")
	-- commonlib.echo(commonlib.debugstack(2, 5, 1),true)
	local actor = RolePlayMovieController.GetMovieActor();
	-- --print("SetFocusToActor========2")
	if(actor) then
		-- --print("actor is exits")
		-- --print("SetFocusToActor========3")
		RolePlayMovieController:beforeActorFocusChanged();
		actor:SetFocus();
		Game.SelectionManager:SetSelectedActor(actor);
		RolePlayMovieController:afterActorFocusChanged();
	else
		-- --print("SetFocusToActor========4")
		RolePlayMovieController.RestoreFocusToCurrentPlayer();
	end
end

--下面是UI相关
function RolePlayMovieController.OnTimer(timer)
	if(page) then
		RolePlayMovieController.UpdateTime()
		RolePlayMovieController.UpdateUI();
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
			if(page and h) then
				page:SetValue("text", string.format("%.2d:%.2d", m,math.floor(s)));
			end
		end
	end
end


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
			RolePlayMovieController.ToggleButtonBg(page:FindControl("godview"), false);	
		else
			RolePlayMovieController.ToggleButtonBg(page:FindControl("godview"), true);	

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
			-- restore to correct pose
			movieClip:UpdateActors(0);
		end
	end
end

function RolePlayMovieController.IsActorsLocked()
	return RolePlayMovieController.isActorsLocked;
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



