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
	MovieManager:Connect("activeMovieClipChanged", self, self.OnActiveMovieClipChange, "UniqueConnection");
end

function MovieClipController:OnActiveMovieClipChange(clip)
	if(self.activeClip~=clip) then
		if(self.activeClip) then
			self.activeClip:Disconnect("remotelyUpdated", self, self.OnMovieClipChange);
		end
		if(clip) then
			clip:Connect("remotelyUpdated", self, self.OnMovieClipRemotelyUpdated, "UniqueConnection");
		end
		self.activeClip = clip;
	end
end

function MovieClipController:OnMovieClipRemotelyUpdated()
	if(page and page:IsVisible()) then
		page:Refresh(0.1);
	end
end

function MovieClipController.OnClosePage()
	local self = MovieClipController;
	MovieManager:Disconnect("activeMovieClipChanged", self, self.OnActiveMovieClipChange);
	-- focus back to current player. 
	self.RestoreFocusToCurrentPlayer();
	Game.SelectionManager:Disconnect("selectedActorChanged", self, self.OnSelectedActorChange);
	
    if(self.activeClip and self.activeClip:GetEntity()) then
        self.activeClip:GetEntity():MarkForUpdate();
    end

	MovieClipController:OnActiveMovieClipChange(nil);
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

function MovieClipController.DeleteSelectedActor()
	local itemStack = MovieClipController.GetItemStack()
	local movieClip = MovieClipController.GetMovieClip()
	if(movieClip and itemStack) then
		local inventory = movieClip:GetEntity():GetInventory();
		if(inventory) then
			local slot_index = inventory:GetItemStackIndex(itemStack)
			if(slot_index) then
				inventory:RemoveItem(slot_index)
			end
		end
	end
end

function MovieClipController.OnClickActorContextMenuItem(node)
	local name = node.Name;
	if(name == "copySelected" or name == "pasteSelected") then
		local actor = MovieClipController.GetMovieActor();
		if(actor) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.lua");
			local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");
			if(name == "copySelected") then
				local movieClip = MovieManager:GetActiveMovieClip();
				local fromTime, toTime;
				if(movieClip) then
					fromTime = movieClip:GetStartTime();
					toTime = movieClip:GetLength();
				end
				CopyActorTimeSeries.ShowPage(actor, actor:GetTime() or fromTime, toTime)
			else
				CopyActorTimeSeries.PasteToActor(actor)
			end
		end
	elseif(name == "rename") then
		local actor = MovieClipController.GetMovieActor();
		if(actor) then
			local oldValue = actor:GetDisplayName()
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
			local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
			EnterTextDialog.ShowPage(L"输入新名字", function(result)
				if(result and result ~= oldValue) then
					actor:SetDisplayName(result);
				end
			end, oldValue)
		end
	elseif(name == "delete") then
		MovieClipController.DeleteSelectedActor()
	end
end

-- menu items
local actorMenuItems = {
	{name="copySelected", text=L"选择性复制..."}, 
	{name="pasteSelected", text=L"粘贴"},
	{name="rename", text=L"重命名..."},
	{name="delete", text=L"删除"},
};

function MovieClipController.OnShowActorContextMenu(x,y, width, height)
	if(MovieClipController.contextMenuActor == nil)then
		MovieClipController.contextMenuActor = CommonCtrl.ContextMenu:new{
			name = "contextMenuActor",
			width = 180,
			height = 30,
			DefaultNodeHeight = 26,
			onclick = MovieClipController.OnClickActorContextMenuItem,
		};
		local node = MovieClipController.contextMenuActor.RootNode;
		node:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		local node = node:GetChild(1);
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"选择性复制...", Name = "copySelected", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"粘贴", Name = "pasteSelected", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = "", Name = "", Type = "Separator",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除", Name = "delete", Type = "Menuitem",  }));
	end
	local ctl = MovieClipController.contextMenuActor
	local node = ctl.RootNode:GetChild(1);
	if(node) then
		node:ClearAllChildren();
		local actor = MovieClipController.GetMovieActor();
		for index, item in ipairs(actorMenuItems) do
			local text = item.text or item.name;
				
			if(item.name == "pasteSelected") then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.lua");
				local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");
				local obj = CopyActorTimeSeries.GetClipBoardData()
				if(obj and actor and actor:GetItemStack().id == obj.itemId) then
					if(obj.fromTime ~= obj.toTime and obj.toTime) then
						text = format(L"粘贴区间: %d-%d", obj.fromTime, obj.toTime or -1);
					else
						text = format(L"%s %s", text, tostring(obj.fromTime or 0));
					end
				else
					text = nil;
				end
			elseif(item.name == "rename") then
				if(actor.class_name == "ActorNPC" or actor.class_name == "ActorOverlay") then
					
				else
					text = nil;
				end
			end
			if(text) then
				node:AddChild(CommonCtrl.TreeNode:new({Text = text, Name = item.name, Type = "Menuitem", onclick = nil, }))
			end
		end
		ctl.height = (#actorMenuItems) * 26 + 4;
	end
	if(not x or not width) then
		x, y, width, height = _guihelper.GetLastUIObjectPos();
	end
	if(x and width) then
		MovieClipController.contextMenuActor:Show(x, y+height);
	end
end


function MovieClipController.OnRightClickItemStack(itemStack)
	if(not MovieClipController.SetFocusToItemStack(itemStack)) then
		MovieClipController.OnShowActorContextMenu();
	end
end

function MovieClipController.SetFocusToItemStack(itemStack)
	local curItemChanged;
	if(curItemStack~=itemStack) then
		curItemStack = itemStack;
		curItemChanged = true;
		if(page) then
			page:Refresh(0.1);
		end
	end
	MovieClipController.SetFocusToActor();
	return curItemChanged;
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
		return movieClip:GetEntity():GetInventoryView();
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

function MovieClipController.GetMarginBottom()
	if(System.options.IsTouchDevice) then
		return 270;
	else
		return 40+12;
	end
end

-- @param bShow:true to refresh or show
function MovieClipController.ShowPage(bShow, OnClose)

	if(bShow) then
		GameLogic:desktopLayoutRequested("MovieClipController");
		GameLogic:Connect("desktopLayoutRequested", MovieClipController, MovieClipController.OnLayoutRequested, "UniqueConnection");
	end

	if(not page) then
		local width,height = 200, 235;
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
					x = -width-20,
					y = -height - MovieClipController.GetMarginBottom(),
					width = 200,
					height = height,
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

	if MovieClipController.IsPlayingMode() then
		GameLogic.GetFilters():apply_filters("user_event_stat", "movie", "play", nil, nil);
	end
end


function MovieClipController.IsVisible()
	if(page) then
		return page:IsVisible();
	end
end

function MovieClipController:OnLayoutRequested(requesterName)
	if(requesterName ~= "MovieClipController") then
		if(MovieClipController.IsVisible()) then
			MovieClipController.OnClose();
		end
	end
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
			local contView = entity:GetInventoryView();
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
		GameLogic.GetFilters():apply_filters("user_event_stat", "actor", "addNPC", 2, nil);

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

-- called when R key is pressed to toggle recording, usually in scene context. 
-- return true if key processed.
function MovieClipController.OnRecordKeyPressed()
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip) then
		if(not movieclip:IsPlayingMode()) then
			MovieClipController.OnRecord();
		else
			MovieManager:ToggleCapture();
		end
		return true;
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

function MovieClipController.OnClickHelp()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/UserGuide/animation/movie_block", "", "", 1);
end
