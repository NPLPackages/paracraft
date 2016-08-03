--[[
Title: MovieClipController Page
Author(s): LiXizhi
Date: 2014/4/5
Desc: # is used as the line seperator \r\n. Space key is replaced by _ character. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
MovieClipController.ShowPage(bShow);
MovieClipController.SetFocusToItemStack(itemStack);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/DateTime.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MovieClipController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController"));
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local curItemStack;
local page;

-- whether to lock the actors by default. 
MovieClipController.isActorsLocked = true;
-- whether to force editor mode
MovieClipController:Property({"m_bForceEditorMode", nil, "IsForceEditorMode", "SetForceEditorMode", auto=true});

MovieClipController:Signal("beforeActorFocusChanged");
MovieClipController:Signal("afterActorFocusChanged");

function MovieClipController.OnInit()
	MovieClipController:InitSingleton();
	local self = MovieClipController;
	page = document:GetPageCtrl();
	self.last_time = nil;
	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = self.OnTimer})
	self.mytimer:Change(200, 200);
	Game.SelectionManager:Connect("selectedActorChanged", self, self.OnSelectedActorChange, "UniqueConnection");
end

function MovieClipController.OnClosePage()
	local self = MovieClipController;
	-- focus back to current player. 
	self.RestoreFocusToCurrentPlayer();
	Game.SelectionManager:Disconnect("selectedActorChanged", self, self.OnSelectedActorChange);
end

function MovieClipController:OnSelectedActorChange(actor)
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		movieClip:UpdateActors(0);
	end
end

function MovieClipController.GetItemID()
	return curItemStack.id;
end

function MovieClipController.GetItemStack()
	return curItemStack;
end

function MovieClipController.SetFocusToItemStack(itemStack)
	if(curItemStack~=itemStack) then
		curItemStack = itemStack;
		if(page) then
			page:Refresh(0.1);
		end
	end
	MovieClipController.SetFocusToActor();
end

function MovieClipController.IsPlayingMode()
	if(MovieClipController:IsForceEditorMode()) then
		return false;
	else
		local movieClip = MovieManager:GetActiveMovieClip()
		if(movieClip) then
			return movieClip:IsPlayingMode();
		end
	end
end

function MovieClipController.SetFocusToItemStackCamera()
	local movieClip = MovieManager:GetActiveMovieClip()
	if(movieClip) then
		local actor = movieClip:GetCamera();
		if(actor) then
			MovieClipController.SetFocusToItemStack(actor:GetItemStack());
		end
	end
end

function MovieClipController.GetTitle()
	local actor = MovieClipController.GetMovieActor()
	if(actor) then
		return actor:GetDisplayName();
	else
		return L"请选择演员或摄影机"
	end
end

function MovieClipController.GetActorInventoryView()
	local movieClip = MovieClipController.GetMovieClip()
	if(movieClip) then
		return movieClip:GetEntity().inventoryView;
	end
end

function MovieClipController.OnClose()
	MovieManager:SetActiveMovieClip(nil);
end

function MovieClipController.GetCode()
	local content = curItemStack:GetData();
	if(type(content) == "table") then
		return commonlib.Lua2XmlString(content);
	else
		return content;
	end
end

function MovieClipController.SetCode(code)
	curItemStack:SetData(code);
end

-- @param bShow:true to refresh or show
function MovieClipController.ShowPage(bShow, OnClose)
	if(not page) then
		local params = {
				url = "script/apps/Aries/Creator/Game/Movie/MovieClipController.html", 
				name = "MovieClipController.ShowPage", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				bToggleShowHide=false, 
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = false,
				bShow = bShow,
				click_through = false, 
				zorder = -1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_rb",
					x = -220,
					y = -222-34*2,
					width = 200,
					height = 180+34*2,
			};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		if(params._page) then
			params._page.OnClose = function()
				MovieClipController:SetForceEditorMode(false);
				MovieClipController.OnClosePage();

				if(OnClose) then
					OnClose();
				end
				page = nil;
				MovieClipController.mytimer:Change();
			end
		end
	else
		if(page) then
			page:Refresh(0.1);
		end
		if(bShow == false) then
			page:CloseWindow();
		end
		MovieClipController:SetForceEditorMode(false);
	end
	
	if(bShow) then
		MovieClipController.RegisterSceneEvent();
	else
		MovieClipController.UnRegisterSceneEvent();
	end

	MovieClipController.SetFocusToActor();
end

function MovieClipController.RegisterSceneEvent()
	GameLogic.GetEvents():AddEventListener("CreateBlockTask", MovieClipController.OnCreateBlock, MovieClipController, "MovieClipController");
	GameLogic.GetEvents():AddEventListener("DestroyBlockTask", MovieClipController.OnDestroyBlock, MovieClipController, "MovieClipController");
end

function MovieClipController.UnRegisterSceneEvent()
	GameLogic.GetEvents():RemoveEventListener("CreateBlockTask", MovieClipController.OnCreateBlock, MovieClipController);
	GameLogic.GetEvents():RemoveEventListener("DestroyBlockTask", MovieClipController.OnDestroyBlock, MovieClipController);
end

function MovieClipController:OnCreateBlock(event)
	local movieClip = MovieClipController.GetMovieClip()
	if(movieClip) then
		local actor = movieClip:GetFocus();
		if(actor and actor:CanCreateBlocks()) then
			actor:OnCreateBlocks({{event.x, event.y, event.z, event.block_id, event.block_data, last_block_id=event.last_block_id, last_block_data=event.last_block_data}});
		end
	else
		MovieClipController.UnRegisterSceneEvent();
	end
end

function MovieClipController:OnDestroyBlock(event)
	local movieClip = MovieClipController.GetMovieClip()
	if(movieClip) then
		local actor = movieClip:GetFocus();
		if(actor and actor:CanCreateBlocks()) then
			actor:OnDestroyBlocks({{event.x, event.y, event.z, 0, last_block_id=event.last_block_id, last_block_data=event.last_block_data}});
		end
	else
		MovieClipController.UnRegisterSceneEvent();
	end
end

function MovieClipController.GetMovieClip()
	return MovieManager:GetActiveMovieClip()
end

function MovieClipController.OnClickEmptySlot(slotNumber)
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		local entity = movieClip:GetEntity();
		if(entity) then
			local contView = entity.inventoryView;
			if(contView and slotNumber) then
				local slot = contView:GetSlot(slotNumber);
				entity:OnClickEmptySlot(slot);
			end
		end
	end
end

function MovieClipController.OnClickAddNPC()
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		local itemStack = movieClip:CreateNPC();
		if(itemStack) then
			MovieClipController.SetFocusToItemStack(itemStack);

			local actor = MovieClipController.GetMovieActor();
			if(actor) then
				local entity = actor:GetEntity();
				if(entity and entity:isa(EntityManager.EntityMob)) then
					
					entity:SetDisplayName(movieClip:NewActorName());
					NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MobPropertyPage.lua");
					local MobPropertyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.MobPropertyPage");
					MobPropertyPage.ShowPage(entity, nil, function()
						actor:SaveStaticAppearance();
					end);
				end
			end
		end
	end
end

-- get the movie actor associated with the current itemStack
function MovieClipController.GetMovieActor()
	local itemStack = MovieClipController.GetItemStack();
	if(itemStack) then
		local movieClip = MovieManager:GetActiveMovieClip()
		if(movieClip) then
			local actor = movieClip:GetActorFromItemStack(itemStack);
			if(actor) then
				return actor;
			end
		end
		-- deselect actor if it no longer exist. 
		MovieClipController.SetFocusToItemStack(nil);
	end
end

function MovieClipController.RestoreFocusToCurrentPlayer()
	local player = EntityManager.GetPlayer();
	if(player) then
		player:SetFocus();
		Game.SelectionManager:SetSelectedActor(nil);
	end
end

function MovieClipController.IsRecording()
	local actor = MovieClipController.GetMovieActor();
	if(actor) then
		return actor:IsRecording();
	end
end

-- if not active actor, we will set focus backto current player
function MovieClipController.SetFocusToActor()
	local actor = MovieClipController.GetMovieActor();
	if(actor) then
		MovieClipController:beforeActorFocusChanged();
		actor:SetFocus();
		Game.SelectionManager:SetSelectedActor(actor);
		MovieClipController:afterActorFocusChanged();
	else
		MovieClipController.RestoreFocusToCurrentPlayer();
	end
end

function MovieClipController.OnTimer(timer)
	if(page) then
		MovieClipController.UpdateTime()
		MovieClipController.UpdateUI();
	else
		timer:Change();
	end
end

function MovieClipController.UpdateTime()
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		local curTime = movieClip:GetTime();
		if(curTime and MovieClipController.last_time~=curTime) then
			MovieClipController.last_time = curTime;
			local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
			if(page and h) then
				page:SetValue("text", string.format("%.2d:%.2d", m,math.floor(s)));
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
	
function MovieClipController.ToggleButtonBg(uiobj, bIsOn)
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
function MovieClipController.UpdateUI()
	if(page) then
		local actor = MovieClipController.GetMovieActor();
		
		if(actor) then
			if(actor:IsRecording())then
				if(actor:IsPaused()) then
					MovieClipController.ToggleButtonBg(page:FindControl("record"), false);
				else
					MovieClipController.ToggleButtonBg(page:FindControl("record"), true);
				end
				MovieClipController.ToggleButtonBg(page:FindControl("play"), false);	
			else
				MovieClipController.ToggleButtonBg(page:FindControl("record"), false);
				
				if(actor:IsPaused()) then
					MovieClipController.ToggleButtonBg(page:FindControl("play"), false);	
				else
					MovieClipController.ToggleButtonBg(page:FindControl("play"), true);	
				end
			end
			MovieClipController.ToggleButtonBg(page:FindControl("godview"), false);	
		else
			MovieClipController.ToggleButtonBg(page:FindControl("godview"), true);	

			local movieClip = MovieClipController.GetMovieClip();
			if(movieClip) then
				if(movieClip:IsPaused()) then
					MovieClipController.ToggleButtonBg(page:FindControl("play"), false);
				else
					MovieClipController.ToggleButtonBg(page:FindControl("play"), true);
				end
			end
		end
		MovieClipController.ToggleButtonBg(page:FindControl("addkeyframe"), MovieClipController.IsActorsLocked());	
	end
end


function MovieClipController.OnRecord()
	local actor = MovieClipController.GetMovieActor();
	if(actor) then
		if(actor.class_name == "ActorCamera_CANCELED") then
			-- _guihelper.MessageBox("摄影机不支持扮演");
		else
			local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
			if(shift_pressed) then
				-- shift click to record and pause, thus clearing all animations from current frame to end. 
				MovieClipController.ClearAllAnimationFromCurrentFrame();
			else
				if(actor:IsPaused()) then
					actor:SetRecording(true);
					actor:Resume();
				else
					actor:SetRecording(false);
					actor:Pause();
				end
			end
		end
    end
end

-- record and pause, thus clearing all animations from current frame to end. 
function MovieClipController.ClearAllAnimationFromCurrentFrame()
	local actor = MovieClipController.GetMovieActor();
    if(actor) then
		if(actor:IsPaused()) then
			actor:SetRecording(true);
			actor:Pause();
		end
	end
end

function MovieClipController.OnPause()
	local actor = MovieClipController.GetMovieActor();
    if(actor) then
        actor:SetRecording(false);
        if(not actor:IsPaused()) then
            actor:Pause();
        end
    end
end

function MovieClipController.OnPlay()
	local actor = MovieClipController.GetMovieActor();
    if(actor) then
        actor:SetRecording(false);
    end
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		if(movieClip:IsPaused()) then
            movieClip:Resume();
		else
			movieClip:Pause();
        end
	end
end

function MovieClipController.OnGotoBeginFrame()
	MovieClipController.OnPause();
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		movieClip:SetTime(movieClip:GetStartTime());
		movieClip:Pause();
	end
end

function MovieClipController.OnGotoEndFrame()
	MovieClipController.OnPause();
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		movieClip:GotoEndFrame();
		movieClip:Pause();
	end
end

function MovieClipController.OnClickAddKeyFrameButton()
	if(mouse_button=="left") then
		MovieClipController.OnAddKeyFrame();
	else
		MovieClipController.ToggleLockAllActors();
	end
end

function MovieClipController.OnAddKeyFrame()
	local actor = MovieClipController.GetMovieActor();
	if(actor) then
		if(not actor:IsRecording()) then
			MovieUISound.PlayAddKey();
			actor:AddKeyFrame();
		end
	end
end

-- @param bLock: if nil, means toggle
function MovieClipController.ToggleLockAllActors(bLock)
	if(bLock == nil) then
		MovieClipController.isActorsLocked = not MovieClipController.isActorsLocked;
	else
		MovieClipController.isActorsLocked = bLock;
	end
	MovieClipController.UpdateUI();
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip and movieClip:IsPaused()) then
		movieClip:FrameMove(0);
		if(MovieClipController.IsActorsLocked()) then
			-- restore to correct pose
			movieClip:UpdateActors(0);
		end
	end
end

function MovieClipController.IsActorsLocked()
	return MovieClipController.isActorsLocked;
end

function MovieClipController.OnClickGodMode()
	-- actually deselect
	MovieClipController.SetFocusToItemStack(nil);
	-- TODO: show quick select panel. 
end

function MovieClipController.OnCaptureVideo()
	MovieManager:ToggleCapture();
end

function MovieClipController.OnSettings()
	local movieClip = MovieClipController.GetMovieClip();
	if(movieClip) then
		local focus = movieClip:GetFocus();
		if(focus) then
			-- select me to edit. 
			focus:SelectMe();
		else
			local entity = movieClip:GetEntity();
			if(entity and entity.OpenBagEditor) then
				entity:OpenBagEditor();
			end
		end
	end
end

