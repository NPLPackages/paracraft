--[[
Title: DEPRECATED: multi-touch event handler (use TouchController.lua)
Author(s): Andy, LiXizhi
Date: 2014/4/24.  
Revised: 2014/11/10 this file is DEPRECATED. 
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_touch.lua");
Map3DSystem.ReBindEventHandlers();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");

NPL.load("(gl)script/ide/timer.lua");

local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");

local TouchEvent = TouchEvent;

local bCreateNavigator = false;

local cameramovestart = false;
local cameramovestart_id = nil;
local cameramovestart_x = nil;
local cameramovestart_y = nil;
local cameramovestart_rot_y = nil;
local cameramovestart_liftup = nil;

local cameramove_mode = nil;

local touchmove_id = nil;


-- right panel buttons
local touch_esc_id = nil;

-- left panel buttons
local touch_undo_id = nil;
local touch_redo_id = nil;
local touch_delete_id = nil;


local wheelstart = false;
local wheelstart_id = nil;
local wheelstart_x = nil;
local wheelstart_y = nil;

local isOverDelete = false;

local last_touch_pressedtime = 0;

local lastTouchPos = {};
local lastTouchEnterTime = {};

local isTouchScenePressed = false;

local TouchSceneIDs = {};

function Map3DSystem.CreateAllTouchUI()

	ParaUI.Destroy("TouchArea_Navigator");
	ParaUI.Destroy("TouchArea_Navigator_Center");
	ParaUI.Destroy("TouchArea_Jump");
	ParaUI.Destroy("TouchArea_ToggleFly");
	ParaUI.Destroy("TouchArea_Delete");
	ParaUI.Destroy("TouchArea_Undo");
	ParaUI.Destroy("TouchArea_Redo");

	local _this = ParaUI.CreateUIObject("container", "TouchArea_Navigator", "_lb", 20, - 20 - 184, 184, 184);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;0 0 184 184";
	_this.zorder = 10000;
	_this:AttachToRoot();
	
	local _this = ParaUI.CreateUIObject("container", "TouchArea_Navigator_Center", "_lb", 20 + 42, - 20 - 184 + 42, 100, 100);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;327 0 100 100";
	_this.zorder = 10001;
	_this.enabled = false;
	_this:AttachToRoot();

	local _this = ParaUI.CreateUIObject("container", "TouchArea_Jump", "_rb", -40 - 102, - 40 - 102, 102, 102);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;208 0 102 102";
	_this.zorder = 10000;
	_this:AttachToRoot();

	local _this = ParaUI.CreateUIObject("container", "TouchArea_ToggleFly", "_rb", -40 - 102 - 64 - 20, - 40 - 64, 64, 64);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;326 101 102 102";
	_this.zorder = 10000;
	_this:AttachToRoot();
	
	--local _this = ParaUI.CreateUIObject("container", "TouchArea_Delete", "_lb", 0, - 460, 65, 57);
	--_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;1 200 65 57";
	--_this.zorder = 10000;
	--_this:AttachToRoot();
	
	-- fake escape
	local _this = ParaUI.CreateUIObject("container", "TouchArea_Esc", "_lt", 0, 50, 65, 57);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;1 267 65 57";
	_this.rotation = math.pi;
	_this.zorder = 10000;
	_this:AttachToRoot();
	
	local _this = ParaUI.CreateUIObject("container", "TouchArea_Redo", "_lt", 0, 120, 65, 57);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;151 200 65 57";
	_this.zorder = 10000;
	_this:AttachToRoot();
	
	local _this = ParaUI.CreateUIObject("container", "TouchArea_Undo", "_lt", 0, 190, 65, 57);
	_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;76 200 65 57";
	_this.zorder = 10000;
	_this:AttachToRoot();
	
	--local _this = ParaUI.CreateUIObject("container", "TouchArea_Command", "_rt", -65, 420, 65, 57);
	--_this.background = "Texture/Aries/Creator/Desktop/TouchUI.png;301 267 65 57";
	--_this.zorder = 10000;
	--_this:AttachToRoot();

end

function Map3DSystem.DestroyAllTouchUI()
	ParaUI.Destroy("TouchArea_Navigator");
	ParaUI.Destroy("TouchArea_Navigator_Center");
	ParaUI.Destroy("TouchArea_Jump");
	ParaUI.Destroy("TouchArea_ToggleFly");
	ParaUI.Destroy("TouchArea_Delete");
	ParaUI.Destroy("TouchArea_Undo");
	ParaUI.Destroy("TouchArea_Redo");
	
	ParaUI.Destroy("TouchArea_Esc");
end

local slatemode_timer;

local function IsSlateMode()
	return ParaEngine.GetAttributeObject():GetField("IsSlateMode", false);
end
local function CheckAndValidateSlateModeUI()
	
	local mode = Desktop.GetDesktopMode();
	if(mode == "movie") then
		if(bCreateNavigator) then
			Map3DSystem.DestroyAllTouchUI();
			bCreateNavigator = true;
		end
		return;
	end

	local bSlateMode = IsSlateMode();
	if(not bCreateNavigator) then
		local player = ParaScene.GetPlayer();
		if(player:IsValid()) then
			if(not bSlateMode) then
				bCreateNavigator = false;
			else
				Map3DSystem.DestroyAllTouchUI();
				Map3DSystem.CreateAllTouchUI();
				ParaUI.GetUIObject("root"):GetAttributeObject():SetField("UIScale", {1.25, 1.25});
				bCreateNavigator = true;

				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GoalTracker.lua");
				local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
				GoalTracker.ShowPage(false);

				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
				local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
				QuickSelectBar.ShowPage(false);
				
				System.App.Commands.Call("File.MCMLWindowFrame", {
					url = "script/apps/Aries/Creator/Game/Areas/NewDesktopPage.html", 
					--url = url,
					name = "CreatorDesktop.ShowNewPage", 
					bRefresh = true,
				});
			end
		else
			bCreateNavigator = false;
		end
	else
		if(not bSlateMode) then
			Map3DSystem.DestroyAllTouchUI();
			ParaUI.GetUIObject("root"):GetAttributeObject():SetField("UIScale", {1, 1});
			bCreateNavigator = false;
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GoalTracker.lua");
			local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
			GoalTracker.ShowPage(true);
			
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			QuickSelectBar.ShowPage(true);
			
			System.App.Commands.Call("File.MCMLWindowFrame", {
				url = "script/apps/Aries/Creator/Game/Areas/NewDesktopPage.html", 
				--url = url,
				name = "CreatorDesktop.ShowNewPage", 
				bRefresh = true,
			});
		end
	end
end

local function GetAbsPositionWithUIScale(obj)
	if(obj and obj:IsValid()) then
		if(obj.GetAbsPosition) then
			local x, y, width, height = obj:GetAbsPosition();
			local scale = ParaUI.GetUIObject("root"):GetAttributeObject():GetField("UIScale", {1, 1});
			if(scale and scale[1] and scale[2]) then
				--return math.floor(x * scale[1]), math.floor(y * scale[2]), math.floor(width * scale[1]), math.floor(height * scale[2]);
			end
			return x, y, width, height;
		end
	end
end

local totalRedoTipCount = 10;
local totalUndoTipCount = 10;

-- input: msg.type, msg.x, msg.y, msg.id, 
function Map3DSystem.OnTouchEvent()
	
	-- apply only to MC
	if(not System.options.mc) then
		return;
	end

	slatemode_timer = slatemode_timer or commonlib.Timer:new({callbackFunc = CheckAndValidateSlateModeUI});
	slatemode_timer:Change(0, 50);
	
	
	local mode = Desktop.GetDesktopMode();
	if(mode == "movie") then
		return;
	end

	if(not msg) then
		return
	end

	
	local scale = ParaUI.GetUIObject("root"):GetAttributeObject():GetField("UIScale", {1, 1});
	if(scale and scale[1] and scale[2] and msg.x and msg.y) then
		msg.x = math.floor(msg.x / scale[1]);
		msg.y = math.floor(msg.y / scale[2]);
	end

	local event_type = msg.type;
	--_guihelper.MessageBox(msg.x.." "..msg.y.." "..msg.id.." "..msg.type)

	--local _, _, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
	
	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local player = EntityManager.GetPlayer();
	
	local isOverNavigator = false;
	local _navigator = ParaUI.GetUIObject("TouchArea_Navigator");
	local _navigator_center = ParaUI.GetUIObject("TouchArea_Navigator_Center");
	if(_navigator:IsValid() and _navigator_center:IsValid()) then
		local x_navigator, y_navigator, width_navigator, height_navigator = GetAbsPositionWithUIScale(_navigator);
		if(msg.x > x_navigator and msg.x < (x_navigator + width_navigator)) then
			if(msg.y > y_navigator and msg.y < (y_navigator + height_navigator)) then
				--_navigator
				local att = ParaCamera.GetAttributeObject();
				local CameraRotY = att:GetField("CameraRotY", 0);
				local centor_x = x_navigator + width_navigator / 2;
				local centor_y = y_navigator + height_navigator / 2;
				local pos_angle = math.pi / 2 + math.atan((msg.y - centor_y) / (msg.x - centor_x));
				if((msg.x - centor_x) < 0) then
					pos_angle = pos_angle + math.pi;
				end
				CameraRotY = CameraRotY + pos_angle;
--				ParaScene.GetPlayer():SetFacing(CameraRotY);
				
				if(msg.type == "WM_POINTERENTER") then
					player:BeginTouchMove();
				elseif(msg.type == "WM_POINTERUPDATE") then
					player:TouchMove(pos_angle);
				elseif(msg.type == "WM_POINTERLEAVE") then
					player:EndTouchMove();
				end
				--_guihelper.MessageBox(msg.x.." "..msg.y.." "..msg.id.." "..msg.type.." "..CameraRotY)
				
				if(msg.type == "WM_POINTERENTER" or msg.type == "WM_POINTERUPDATE") then
					local navigator_sq = 1600;
					local dist_sq = (msg.y - centor_y) * (msg.y - centor_y) + (msg.x - centor_x) * (msg.x - centor_x);
					if(navigator_sq <= dist_sq) then
						local scale = math.sqrt(navigator_sq / dist_sq);
						_navigator_center.translationx = (msg.x - centor_x) * scale;
						_navigator_center.translationy = (msg.y - centor_y) * scale;
					else
						_navigator_center.translationx = msg.x - centor_x;
						_navigator_center.translationy = msg.y - centor_y;
					end
				end
				
				isOverNavigator = true;

				touchmove_id = msg.id;
			end
		end
	end
	
	if(_navigator_center:IsValid()) then
		if(msg.type == "WM_POINTERLEAVE") then
			_navigator_center.translationx = 0;
			_navigator_center.translationy = 0;
		end
	end
	if(msg.type == "WM_POINTERLEAVE" and touchmove_id == msg.id) then
		player:EndTouchMove();
	end

	local isOverJump = false;
	local _jump = ParaUI.GetUIObject("TouchArea_Jump");
	if(_jump:IsValid() and msg.type == "WM_POINTERDOWN") then
		local x_jump, y_jump, width_jump, height_jump = GetAbsPositionWithUIScale(_jump);
		if(msg.x > x_jump and msg.x < (x_jump + width_jump)) then
			if(msg.y > y_jump and msg.y < (y_jump + height_jump)) then
				--jump
				local playerChar = ParaScene.GetPlayer():ToCharacter();
				playerChar:AddAction(action_table.ActionSymbols.S_JUMP_START);
--_guihelper.MessageBox(msg.x.." "..msg.y.." "..msg.id.." "..msg.type.." "..CameraRotY)
				
				isOverJump = true;
			end
		end
	end
	
	local isOverToggleFly = false;
	local _togglefly = ParaUI.GetUIObject("TouchArea_ToggleFly");
	if(_togglefly:IsValid() and msg.type == "WM_POINTERDOWN") then
		local x_togglefly, y_togglefly, width_togglefly, height_togglefly = GetAbsPositionWithUIScale(_togglefly);
		if(msg.x > x_togglefly and msg.x < (x_togglefly + width_togglefly)) then
			if(msg.y > y_togglefly and msg.y < (y_togglefly + height_togglefly)) then
				-- toggle fly
				local input = Map3DSystem.InputMsg;
				NPL.load("(gl)script/ide/event_mapping.lua");

				local event_map = Event_Mapping;
				input.virtual_key = event_map.EM_KEY_F;
				input.wndName = "key_down";
				input.IsSceneEnabled = ParaScene.IsSceneEnabled()
				-- call hook for "input" application
				if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", input) ==nil) then
					return
				end
--_guihelper.MessageBox(msg.x.." "..msg.y.." "..msg.id.." "..msg.type.." "..CameraRotY)
				
				isOverToggleFly = true;
			end
		end
	end
	

	local isOverEsc = false;
	local _esc = ParaUI.GetUIObject("TouchArea_Esc");
	if(_esc:IsValid()) then
		local x_esc, y_esc, width_esc, height_esc = _esc:GetAbsPosition();
		if(msg.x > x_esc and msg.x < (x_esc + width_esc)) then
			if(msg.y > y_esc and msg.y < (y_esc + height_esc)) then
				isOverEsc = true;
			end
		end
	end

	local isOverUndo = false;
	local _undo = ParaUI.GetUIObject("TouchArea_Undo");
	if(_undo:IsValid()) then
		local x_undo, y_undo, width_undo, height_undo = GetAbsPositionWithUIScale(_undo);
		if(msg.x > x_undo and msg.x < (x_undo + width_undo)) then
			if(msg.y > y_undo and msg.y < (y_undo + height_undo)) then
				isOverUndo = true;
			end
		end
	end

	local isOverRedo = false;
	local _redo = ParaUI.GetUIObject("TouchArea_Redo");
	if(_redo:IsValid()) then
		local x_redo, y_redo, width_redo, height_redo = GetAbsPositionWithUIScale(_redo);
		if(msg.x > x_redo and msg.x < (x_redo + width_redo)) then
			if(msg.y > y_redo and msg.y < (y_redo + height_redo)) then
				isOverRedo = true;
			end
		end
	end
	
	if(isOverDelete ~= true) then
		isOverDelete = false;
	end
	local this_over_delete = false;
	local _delete = ParaUI.GetUIObject("TouchArea_Delete");
	if(_delete:IsValid()) then
		local x_delete, y_delete, width_delete, height_delete = GetAbsPositionWithUIScale(_delete);
		if(msg.x > x_delete and msg.x < (x_delete + width_delete)) then
			if(msg.y > y_delete and msg.y < (y_delete + height_delete)) then
				this_over_delete = true;
			end
		end
	end
	
	-- delete
	if(this_over_delete == true and msg.type == "WM_POINTERDOWN") then
		touch_delete_id = msg.id;
		isOverDelete = true;
	end
	if(msg.type == "WM_POINTERLEAVE" and touch_delete_id == msg.id) then
		touch_delete_id = nil;
		isOverDelete = false;
	end
	if(msg.type == "WM_POINTERUPDATE" and touch_delete_id == msg.id) then
		isOverDelete = this_over_delete;
	end

	-- esc
	if(isOverEsc == true and msg.type == "WM_POINTERDOWN") then
		touch_esc_id = msg.id;
	end
	if(msg.type == "WM_POINTERLEAVE" and touch_esc_id == msg.id) then
		touch_esc_id = nil;
		if(isOverEsc == true) then
			-- trigger esc
			local input = Map3DSystem.InputMsg;
			NPL.load("(gl)script/ide/event_mapping.lua");

			local event_map = Event_Mapping;
			input.virtual_key = event_map.EM_KEY_ESCAPE;
			input.wndName = "key_down";
			input.IsSceneEnabled = ParaScene.IsSceneEnabled()
			-- call hook for "input" application
			if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", input) ==nil) then
				return
			end
		end
	end

	-- undo
	if(isOverUndo == true and msg.type == "WM_POINTERDOWN") then
		touch_undo_id = msg.id;
	end
	if(msg.type == "WM_POINTERLEAVE" and touch_undo_id == msg.id) then
		touch_undo_id = nil;
		if(isOverUndo == true) then
			-- trigger undo
			NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
			local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
			NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
			local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
			local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
			if(GameLogic.GameMode:IsEditor()) then
				if(GameMode:IsAllowGlobalEditorKey()) then
					UndoManager.Undo();
					
					if(totalUndoTipCount > 0) then
						totalUndoTipCount = totalUndoTipCount - 1;
						NPL.load("(gl)script/ide/TooltipHelper.lua");
						local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
						BroadcastHelper.PushLabel({id="touch_undo_tip", label = "撤销方块", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
					end
				end
			end
		end
	end

	-- redo
	if(isOverRedo == true and msg.type == "WM_POINTERDOWN") then
		touch_redo_id = msg.id;
	end
	if(msg.type == "WM_POINTERLEAVE" and touch_redo_id == msg.id) then
		touch_redo_id = nil;
		if(isOverRedo == true) then
			-- trigger redo
			NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
			local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
			NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
			local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
			local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
			if(GameLogic.GameMode:IsEditor()) then
				if(GameMode:IsAllowGlobalEditorKey()) then
					UndoManager.Redo();
					
					if(totalRedoTipCount > 0) then
						totalRedoTipCount = totalRedoTipCount - 1;
						NPL.load("(gl)script/ide/TooltipHelper.lua");
						local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
						BroadcastHelper.PushLabel({id="touch_undo_tip", label = "返回上一步", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
					end
				end
			end
		end
	end
	
	
	if(msg.type == "WM_POINTERENTER") then
		lastTouchEnterTime[msg.id] = ParaGlobal.timeGetTime();
	end
	if(msg.type == "WM_POINTERLEAVE") then
		TouchSceneIDs[msg.id] = nil;
		if(lastTouchEnterTime[msg.id]) then
			last_touch_pressedtime = ParaGlobal.timeGetTime() - lastTouchEnterTime[msg.id];
			lastTouchEnterTime[msg.id] = nil;
		end
	end

	if(not isOverNavigator and not isOverJump and not isOverToggleFly and not isOverUndo and not isOverRedo and not this_over_delete) then
		-- camera control
		if(msg.type == "WM_POINTERENTER") then
			local temp = ParaUI.GetUIObjectAtPoint(msg.x, msg.y);
			
			if(temp:IsValid() == true) then
				-- touch UI object
				if(wheelstart == false) then
					--wheelstart = true;
					wheelstart_id = msg.id;
					wheelstart_x = msg.x;
					wheelstart_y = msg.y;
				end
			else
				-- touch on scene
				if(cameramovestart == false) then
					cameramovestart = true;
					cameramovestart_id = msg.id;
					cameramovestart_x = msg.x;
					cameramovestart_y = msg.y;
					local att = ParaCamera.GetAttributeObject();
					cameramovestart_rot_y = att:GetField("CameraRotY", 0);
					cameramovestart_liftup = att:GetField("CameraLiftupAngle", 0);
				end
				if(cameramovestart == true and msg.id ~= cameramovestart_id) then
					if(cameramove_mode == nil) then
						cameramove_mode = "LiftUp";
					else
						cameramovestart = false;
						cameramovestart_id = nil;
						cameramovestart_x = nil;
						cameramovestart_y = nil;
						cameramovestart_rot_y = nil;
					end
				end
			end
		elseif(msg.type == "WM_POINTERUPDATE") then
			if(cameramovestart == true) then
				local delta_x_and_y = math.abs(msg.x - cameramovestart_x) + math.abs(msg.y - cameramovestart_y);
				if(cameramovestart == true and msg.id == cameramovestart_id and delta_x_and_y > 36 and cameramove_mode == nil) then
					cameramove_mode = "RotY";
				end
				if(cameramovestart == true and msg.id == cameramovestart_id and cameramove_mode == "RotY") then
					local rot = cameramovestart_rot_y + (msg.x - cameramovestart_x) / 100;
					local att = ParaCamera.GetAttributeObject();
					att:SetField("CameraRotY", rot);
				end
				if(cameramovestart == true and msg.id == cameramovestart_id and cameramove_mode == "LiftUp") then
					local liftup = cameramovestart_liftup - (msg.y - cameramovestart_y) / 100;
					local att = ParaCamera.GetAttributeObject();
					att:SetField("CameraLiftupAngle", liftup);
				end

			end
			if(wheelstart == true) then
				local delta_y = math.abs(msg.y - wheelstart_y);
				if(msg.y > wheelstart_y) then
					mouse_wheel = 1;
				else
					mouse_wheel = -1;
				end
				-- update input message
				local InputMsg_Mouse_Wheel = {};
				InputMsg_Mouse_Wheel.mouse_wheel = mouse_wheel;
				InputMsg_Mouse_Wheel.wndName = "mouse_wheel";
				
				-- call hook for "input" application
				--if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", InputMsg_Mouse_Wheel) ==nil) then
					--return
				--end
			end
		elseif(msg.type == "WM_POINTERLEAVE") then
			cameramovestart = false;
			cameramovestart_id = nil;
			cameramovestart_x = nil;
			cameramovestart_y = nil;
			cameramovestart_rot_y = nil;
			cameramovestart_liftup = nil;
			cameramove_mode = nil;
			
			wheelstart = false;
			wheelstart_id = nil;
			wheelstart_x = nil;
			wheelstart_y = nil;
		end
		
		if(msg.type == "WM_POINTERENTER") then
			mouse_x = msg.x;
			mouse_y = msg.y;
			mouse_button = "left";
			Map3DSystem.OnMouseDown(true); -- true for bSkipTouchTest
		elseif(msg.type == "WM_POINTERUPDATE") then
			mouse_dx = msg.x - lastTouchPos[msg.id].x;
			mouse_dy = msg.y - lastTouchPos[msg.id].y;
			--mouse_button = "left";
			Map3DSystem.OnMouseMove(true); -- true for bSkipTouchTest
		elseif(msg.type == "WM_POINTERLEAVE") then
			mouse_x = msg.x;
			mouse_y = msg.y;
			mouse_button = "left";
			Map3DSystem.OnMouseUp(true); -- true for bSkipTouchTest
		end

		
		if(msg.type == "WM_POINTERENTER") then
			isTouchScenePressed = true;
			TouchSceneIDs[msg.id] = true;
		elseif(msg.type == "WM_POINTERUPDATE") then
			isTouchScenePressed = true;
			ParaUI.SetMousePosition(msg.x, msg.y);
		end


	end

	if(next(TouchSceneIDs) == nil) then
		isTouchScenePressed = false;
	end

	-- record last touch position
	if(not lastTouchPos[msg.id]) then
		lastTouchPos[msg.id] = {
			x = msg.x,
			y = msg.y,
		};
	end
		lastTouchPos[msg.id] = {
			x = msg.x,
			y = msg.y,
		};

	if(event_type == TouchEvent.TouchEvent_Begin) then
		
	elseif(event_type == TouchEvent.TouchEvent_Move) then	
		
	elseif(event_type == TouchEvent.TouchEvent_End) then

	elseif(event_type == TouchEvent.TouchEvent_Cancel) then

	end
end