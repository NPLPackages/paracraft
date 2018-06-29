--[[
Title: The map system Event handlers
Author(s): LiXizhi(code&logic)
Company: ParaEnging Co.
Date: 2006/1/26
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_mouse.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppDesktop.lua"); -- required for desktop mode event filter
NPL.load("(gl)script/kids/3DMapSystemUI/HeadonDisplay.lua");
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/action_table.lua");

-- Not used: in milliseconds for click event. 
local max_single_click_interval = 1000;
local type = type;
-------------------------------------------------------------
-- event related
-------------------------------------------------------------

-- this is message used by the "input" application
local InputMsg = {
	-- whether mouse button is down
	IsMouseDown = false,
	-- whether left or right mouse button is down.
	MouseDownStates = {left=false, right=false, middle = false},
	-- drag distance relative to lastMouseDown {x = 0, y=0}
	MouseDragDist = {x=0, y=0},
	-- {x = 0, y=0}
	lastMouseDown = {x = 0, y=0},
	-- drag pixels between mouse down and up. only calculated on mouse up
	dragDist = 0,
	-- drag pixels between mouse down and mouse move. calculated on mouse move
	move_dragDist = 0,
	-- mouse point in screen coordinate
	mouse_x = 0,
	mouse_y = 0,
	-- "left", "middle", "right"
	mouse_button = "left",
	-- from "key_down" event. such as Event_Mapping.EM_KEY_F1
	virtual_key = nil,
	-- one of the window: "mouse_down", "mouse_up","mouse_move", "key_down". 
	wndName = nil,
	-- the game time in milliseconds when the last mouse down event is seen. It is usually used for detecting single click.
	lastMouseDownTime = 0,
	-- the game time in milliseconds when the last mouse up event is seen. It is usually used for detecting double click.
	lastMouseUpTime = 0,
	-- "left", "middle", "right". It is usually used for detecting double click button.
	lastMouseUpButton,
	lastMouseUp_x = 0,
	lastMouseUp_y = 0,
	-- filter name or a number string with bitwise field.
	filter = nil,
	-- function(params) return true; end, -- a callback function that is called when user clicks. if this function return nil, it will stop picking. otherwise, it will continue picking more. 
	pickingCallbackFunc = nil,
};
Map3DSystem.InputMsg = InputMsg;


local DesktopMode = commonlib.gettable("Map3DSystem.UI.DesktopMode");

--------------------------------------
-- Mouse handlers
--------------------------------------
local OriginalDensity = nil;
local Mouse = commonlib.gettable("Map3DSystem.Mouse");
-- mapping from virtual_key to boolean. we will only allow key in this list to pass.  
local mouse_pass_filter = nil;
-- current mouse picking distance from camera to object 
Mouse.mouse_pick_distance = Mouse.mouse_pick_distance or 300;

-- predefined enable or disable filter
Mouse.enable_filter = { OnMouseDown = true, OnMouseMove=true, OnMouseUp=true, OnMouseWheel=true };
Mouse.disable_filter = { OnMouseDown = nil, OnMouseMove=nil, OnMouseUp=nil, OnMouseWheel=nil };
Mouse.isTouchInput = false;
-- Set which keys can now be processed. 
-- e.g. System.Mouse.SetMousePassFilter({OnMouseDown = true, OnMouseMove=true, OnMouseUp=true}) 
-- @param filter: nil or a table of {Key=boolean, ...} . If nil it will remove mouse pass filter. 
function Mouse.SetMousePassFilter(filter)
	mouse_pass_filter = filter;
end

-- pick a given type of object using a filter, and use a callback function when user clicks. a second call of this will overwrite the first call.
-- @param filter: filter name or a number string with bitwise field.
-- @param callbackFunc: function(params) return true; end, -- a callback function that is called when user clicks. if this function return nil, it will stop picking. otherwise, it will continue picking more. 
function Map3DSystem.PickObject(filter, callbackFunc)
	InputMsg.filter = filter;
	InputMsg.pickingCallbackFunc = callbackFunc;
end

local InputMsg_Mouse_Wheel = {};
function Map3DSystem.OnMouseWheel()
	if(mouse_pass_filter and not mouse_pass_filter.OnMouseWheel) then
		return
	end
	-- update input message
	InputMsg_Mouse_Wheel.mouse_wheel = mouse_wheel;
	InputMsg_Mouse_Wheel.wndName = "mouse_wheel";
	
	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", InputMsg_Mouse_Wheel) ==nil) then
		return
	end
end

function Map3DSystem.OnMouseDown()
	if(mouse_pass_filter and not mouse_pass_filter.OnMouseDown) then
		return
	end
	
	-- update input message
	InputMsg.lastMouseDown.x = mouse_x;
	InputMsg.lastMouseDown.y = mouse_y;
	InputMsg.IsMouseDown = true;
	InputMsg.MouseDownStates[mouse_button] = true;
	
	InputMsg.MouseDragDist.x = 0;
	InputMsg.MouseDragDist.y = 0;
	
	InputMsg.mouse_x = mouse_x;
	InputMsg.mouse_y = mouse_y;
	InputMsg.mouse_button = mouse_button;
	InputMsg.wndName = "mouse_down";
	InputMsg.lastMouseDownTime = ParaGlobal.timeGetTime();
	InputMsg.obj = nil;
	
	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", InputMsg) ==nil) then
		return
	end
	
	---- NOTE by Andy 2008-2-20: 
	--NPL.load("(gl)script/kids/3DMapSystemApp/Inventory/BagCtl.lua");
	--if(Map3DSystem.App.Inventory.BagCtl.isClickDrag == true) then
		--Map3DSystem.App.Inventory.BagCtl.SceneClickDuringClickDrag();
	--end
end

function Map3DSystem.OnMouseMove()
	if(mouse_pass_filter and not mouse_pass_filter.OnMouseMove) then
		return
	end
	-- update input message
	local dragDist=0;
	if(InputMsg.IsMouseDown) then
		InputMsg.MouseDragDist.x = InputMsg.MouseDragDist.x + math.abs(mouse_dx or 0);
		InputMsg.MouseDragDist.y = InputMsg.MouseDragDist.y + math.abs(mouse_dy or 0);
		dragDist = math.abs(InputMsg.MouseDragDist.x) + math.abs(InputMsg.MouseDragDist.y);
	end
	InputMsg.mouse_x, InputMsg.mouse_y = ParaUI.GetMousePosition();
	InputMsg.mouse_button = mouse_button;
	InputMsg.wndName = "mouse_move";
	InputMsg.move_dragDist = dragDist;
	InputMsg.obj = nil;

	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", InputMsg) ==nil) then
		return
	end
	
	if(not Map3DSystem.ObjectWnd.DisableMouseMove) then
		if(Map3DSystem.ObjectWnd.OperationState == "MoveObject" or Map3DSystem.ObjectWnd.OperationState == "CopyObject") then
			-- display 3D object in the clipboard at the current mouse position with the intersection of the mouse. 
			local pt = ParaScene.MousePick(Mouse.mouse_pick_distance, "point");
			if(pt:IsValid())then
				local msg = {type = Map3DSystem.msg.OBJ_MoveCursorObject};
				msg.x, msg.y, msg.z = pt:GetPosition();
				Map3DSystem.SendMessage_obj(msg);
				if(not InputMsg.IsMouseDown) then
					-- make the current player face the target
					Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character, animationName = "SelectObject",facingTarget = {x=msg.x, y=msg.y, z=msg.z},});
					--ParaScene.GetPlayer():ToCharacter():GetFaceTrackingController():FaceTarget(msg.x, msg.y, msg.z, 5);
				end	
					
				--commonlib.ShowDebugString("PT_intersection", msg.x..","..msg.y..","..msg.z);
			end
		else
			-- if it is a drag operation, enable or disable camera lock on character
			if(dragDist>5) then
				if(mouse_button == "left") then
					ParaCamera.GetAttributeObject():SetField("CamAlwaysBehindObject", false)
				elseif(mouse_button == "right") then
					ParaCamera.GetAttributeObject():SetField("CamAlwaysBehindObject", true)
				end	
			end
		end
	end	
	
	-- render different cursor with different picking object. 
	if(not InputMsg.IsMouseDown) then
		local mouse_x, mouse_y = InputMsg.mouse_x, InputMsg.mouse_y;
		
		local uiobj = ParaUI.GetUIObjectAtPoint(mouse_x, mouse_y);
		if(uiobj:IsValid() and uiobj.visible and uiobj.enabled) then
			return
		end
		
		local cursor;
		if(DesktopMode.CanClickXrefMarker) then
			-- pick the object in the Xref marker mini scene graph
			local XRefScriptGraph = ParaScene.GetMiniSceneGraph("XRefScriptMarker");
			local objPick = XRefScriptGraph:MousePick(mouse_x, mouse_y, Mouse.mouse_pick_distance, "anyobject");
			if(objPick:IsValid()) then
				cursor = "xref"
				InputMsg.obj = objPick;
			end	
		end
		
		if(cursor == nil and InputMsg.filter) then
			local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, InputMsg.filter); 
			if(obj:IsValid()) then
				cursor = "model";
				InputMsg.obj = obj;
			end	
		elseif(cursor == nil) then
			-- pick all
			if(not DesktopMode.CanSelectModel) then
				obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "biped"); -- this will pick any object
			else
				obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject"); -- this will pick any object
			end
			
			if(obj:IsValid()) then
				-- click a character
				if(DesktopMode.CanClickCharacter) then
					if(obj:IsCharacter())then
						if(obj:equals(ParaScene.GetPlayer())) then
							cursor = "player"
						else
							cursor = "char"
						end	
						InputMsg.obj = obj;
					end
				end	
				-- allow select character and context menu
				if(DesktopMode.CanSelect) then
					-- we only allow selection to character in navigation mode
					if(obj:IsCharacter()) then
						if(DesktopMode.CanSelectCharacter) then
							if(obj:equals(ParaScene.GetPlayer())) then
								cursor = "player"
							else
								cursor = "char";
							end	
							InputMsg.obj = obj;
						end	
					else
						if(DesktopMode.CanSelectModel) then
							cursor = "model"
							InputMsg.obj = obj;
						end	
					end
				end
			end
		end
		
		local cursorfile;
		-- get aries cursor
		--local app = Map3DSystem.App.AppManager.GetApp("Aries_GUID");
		--if(app and commonlib.getfield("MyCompany.Aries.HandleMouse.ShowCursorForSceneObject")) then
			----local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject");
			--local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "biped");
			--local aries_cursor, aries_cursorfile = MyCompany.Aries.HandleMouse.ShowCursorForSceneObject(obj);
			--cursor = aries_cursor;
			--cursorfile = aries_cursorfile;
			--InputMsg.cursor_obj = obj;
		--end
		--
		--Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_CURSOR, cursor = cursor, cursorfile = cursorfile})
		
		InputMsg.cursor = cursor;
	end
	-- call hook for "input" application of WH_CALLWNDPROCRET
	CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "input", InputMsg);
end

function Map3DSystem.OnMouseUp()
	if(mouse_pass_filter and not mouse_pass_filter.OnMouseUp) then
		return
	end
	if(not InputMsg.IsMouseDown) then
		return 
	end
	
	-- update input message
	InputMsg.MouseDownStates[mouse_button] = false;
	InputMsg.IsMouseDown = InputMsg.MouseDownStates.left or InputMsg.MouseDownStates.right or InputMsg.MouseDownStates.middle;
	local dragDist = (math.abs(InputMsg.MouseDragDist.x) + math.abs(InputMsg.MouseDragDist.y));
	
	InputMsg.mouse_x = mouse_x;
	InputMsg.mouse_y = mouse_y;
	InputMsg.mouse_button = mouse_button;
	InputMsg.wndName = "mouse_up";
	InputMsg.dragDist = dragDist;
	InputMsg.action = nil;
	InputMsg.obj = nil;

	local cur_time = ParaGlobal.timeGetTime();
	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", InputMsg) ==nil) then
		return
	end
	
	if(dragDist<=10) then
		-- this is mouse click event if mouse down and mouse up distance is very small.
		if(Map3DSystem.ObjectWnd.OperationState == "MoveObject") then
			if(mouse_button == "left") then
				-- confirm move
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_EndMoveObject});
			elseif(mouse_button == "right") then
				-- cancel move
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveCopyObject});
			elseif(mouse_button == "middle") then
				-- pop up edit
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_PopupEditObject, target = "cursorObj", mouse_x=mouse_x, mouse_y=mouse_y});
			end

		elseif(Map3DSystem.ObjectWnd.OperationState == "CopyObject") then
			if(mouse_button == "left") then
				-- confirm copy
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_PasteObject});
			elseif(mouse_button == "right") then
				-- cancel copy
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveCopyObject});
			elseif(mouse_button == "middle") then
				-- pop up edit
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_PopupEditObject, target = "cursorObj", mouse_x=mouse_x, mouse_y=mouse_y});
			end
		else
			local targetObj = nil;
			if(DesktopMode.CanClickXrefMarker) then
				-- pick the object in the mini scene graph
				local XRefScriptGraph = ParaScene.GetMiniSceneGraph("XRefScriptMarker");
				local objPick = XRefScriptGraph:MousePick(mouse_x, mouse_y, Mouse.mouse_pick_distance, "anyobject");
				
				if(objPick:IsValid() == true) then
					local pickX, pickY, pickZ = objPick:GetPosition();
					local player = ParaScene.GetPlayer();
					local char = player:ToCharacter();
					local objlist = {};
					local fromX, fromY, fromZ = player:GetPosition();
					-- NOTE: radius agianst the object center, we only sense the Xref points within the radius
					local NearByRadius = 10;
					local nCount = ParaScene.GetActionMeshesBySphere(objlist, fromX, fromY, fromZ, NearByRadius);
					local k = 1;
					local subIndex = nil;
					local dist = nil;
					local min_dist = 100000;
					
					-- find the xref object with the same position in mini scene graph
					for k = 1, nCount do
						local obj = objlist[k];
						
						local nXRefCount = obj:GetXRefScriptCount();
						local i = 0;
						local toX, toY, toZ;
						
						for i = 0, nXRefCount-1 do
							toX, toY, toZ = obj:GetXRefScriptPosition(i);
							local dist = math.abs(toX-pickX) + math.abs(toY-pickY) + math.abs(toZ-pickZ);
							if( dist < min_dist) then
								min_dist = dist;
								subIndex = i;
								targetObj = obj;
								--commonlib.ShowDebugString("dist", dist)
								--commonlib.ShowDebugString("xrefto", toX..","..toY..","..toZ)
								--commonlib.ShowDebugString("minipick", pickX..","..pickY..","..pickZ)
							end
							-- the following exact match seems to have some floating point error. we will use the above version by searching closest xref. 
							--if(toX == pickX and toY == pickY and toZ == pickZ) then
								--dist = obj:DistanceTo(player);
								--subIndex = i;
								--targetObj = obj;
								--break;
							--end
						end
					end
					
					-- call the xref script
					if(targetObj ~= nil) then
						if(dist == nil) then
							dist = targetObj:DistanceTo(player);
						end	
						
						local toX, toY, toZ = targetObj:GetXRefScriptPosition(subIndex);
						
						local msg = {};
						msg.posX, msg.posY, msg.posZ = toX, toY, toZ;
						msg.scaleX, msg.scaleY, msg.scaleZ = targetObj:GetXRefScriptScaling(subIndex);
						msg.facing = targetObj:GetXRefScriptFacing(subIndex);
						msg.dist = dist;
						msg.localMatrix = targetObj:GetXRefScriptLocalMatrix(subIndex);
						
						-- call the script file
						NPL.call(targetObj:GetXRefScript(subIndex), msg);
					end
				end -- if(objPick:IsValid() == true) then
			end	-- if(DesktopMode.CanClickXrefMarker) then
			
			if(targetObj == nil) then
				if(InputMsg.filter) then
					local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, InputMsg.filter); 
					if(not obj:IsValid()) then
						obj = nil;
					end	
					if(mouse_button == "right" and obj) then
						-- allow context menu
						if(DesktopMode.CanContextMenu) then
							Map3DSystem.UI.ContextMenu.ShowMenuForObject(obj);
						end	
					else	
						if(InputMsg.pickingCallbackFunc) then
							if(not InputMsg.pickingCallbackFunc(obj)) then
								InputMsg.filter = nil;
								InputMsg.pickingCallbackFunc = nil;
							end
						else	
							InputMsg.filter = nil;
						end
					end
				else
					-- perform scene click, if nothing is picked in the mini scene graph
					local x, y = ParaUI.GetMousePosition();
					local temp = ParaUI.GetUIObjectAtPoint(x, y);
					if(not temp or temp:IsValid() == false) then
						-- perform click if no UI object over the mouse position
						--if( (cur_time - InputMsg.lastMouseDownTime) < max_single_click_interval) then
							Map3DSystem.OnMouseClick_3DScene();
						--end
					end
				end	
			end
		end
	else
		
	end -- if(dragDist<=2) then
	
	InputMsg.MouseDragDist.x = 0;
	InputMsg.MouseDragDist.y = 0;
	
	InputMsg.lastMouseUpTime = cur_time;
	InputMsg.lastMouseUpButton = mouse_button
	InputMsg.lastMouseUp_x = mouse_x
	InputMsg.lastMouseUp_y = mouse_y
	
	CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "input", InputMsg);
end

-- only used by MoveToMouseCursorPick
local hook_move_move_msg = { aries_type = "OnMoveToMouseCursorPick", wndName = "main"};	

local move_counter = 0;
-- move the current player to a given point 
-- @param to_x, to_y, to_z: the dest point
-- @param bShowMarkAnimation: if true, we will show the mark animation. 
-- @return the internal count that this function has been called. 
local function MovePlayerToPoint(to_x, to_y, to_z, bShowMarkAnimation, facing)
	if(to_x) then
		local player = ParaScene.GetPlayer();
		local x,y,z = player:GetPosition();
		if(facing) then
			player:ToCharacter():GetSeqController():MoveAndTurn(to_x-x, to_y-y, to_z-z, facing);
		else
			player:ToCharacter():GetSeqController():MoveTo(to_x-x, to_y-y, to_z-z);
		end

		player:GetAttributeObject():SetField("HeadTurningAngle", 0);
		local distH = 0.01;
		move_counter = move_counter + 1;
		-- use an arrow animation.
		if(bShowMarkAnimation) then
			local asset;
			if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
				asset = headon_speech.GetAsset("tag"); -- default
				if(System.options.version == "kids") then
					asset = headon_speech.GetAsset("aries_walk_point");
				elseif(System.options.version == "teen") then
					asset = headon_speech.GetAsset("aries_walk_point_teen");
				end
			else
				asset = headon_speech.GetAsset("tag");
			end
			ParaScene.FireMissile(asset, distH/0.6, to_x, to_y+distH, to_z, to_x, to_y, to_z);
		end
	end
	return move_counter;
end
-- expose this to external modules
commonlib.setfield("Map3DSystem.HandleMouse.MovePlayerToPoint", MovePlayerToPoint);

-- return the movement count
function Map3DSystem.HandleMouse.GetMovementCount()
	return move_counter;
end

-- move to mouse cursor pick. 
-- @param mouse_msg: in/out. the mouse event message. if nil, it is mouse_msg
-- @return bIgnoreMovement: ignore movement,but will show the dest animation mark. 
-- @return bCanMove, to_x, to_y, to_z: bCanMove is nil if no movement is allowed. 
local function MoveToMouseCursorPick(mouse_msg, bIgnoreMovement)
	mouse_msg = mouse_msg or InputMsg;
	-- set bUseDoubleClick = true to allow only double click character movement
	local bCanMove = true;
	if(Map3DSystem.options.DoubleClickMoveChar) then
		bCanMove = ((ParaGlobal.timeGetTime()-mouse_msg.lastMouseUpTime)< 500 and 
			(math.abs(mouse_msg.lastMouseUp_x-mouse_x)+math.abs(mouse_msg.lastMouseUp_y-mouse_y))<=4 and 
			(mouse_msg.lastMouseUpButton == mouse_button));
	end

	if(Map3DSystem.options.StopClickMoveChar) then
		bCanMove = false;
	end
			
	if( bCanMove ) then
		-- display 3D object in the clipboard at the current mouse position with the intersection of the mouse. 
		-- "walkpoint" is a special filter that only pick walkable physics regions including the terrain. 
		local pt = ParaScene.MousePick(Mouse.mouse_pick_distance, "walkpoint");
		if(pt:IsValid())then
			mouse_msg.action = "walkpoint";
			local to_x, to_y, to_z = pt:GetPosition();
			if(not bIgnoreMovement) then
				MovePlayerToPoint(to_x, to_y, to_z, true);
			end
			if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
				-- TODO: Move this hook to "input" using WH_CALLWNDPROC, call hook for OnMoveToMouseCursorPick
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_move_move_msg);
			end
			return true, to_x, to_y, to_z;
		end
	end	
end
-- expose this to external modules
commonlib.setfield("Map3DSystem.HandleMouse.MoveToMouseCursorPick", MoveToMouseCursorPick);


-- called when the user clicked on a scene object with its mouse.
function Map3DSystem.OnMouseClick_3DScene()
	if(ParaScene.IsSceneEnabled()~=true) then 
		return	
	end
	
	if(mouse_button == "left") then
		-- pick all
		--local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject"); -- TODO: filter different objects according to current view mode, such as explore mode or edit mode.
		--local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "notplayer"); -- this will prevent left click current character. 
		--local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject"); -- this will pick any object
		local obj;
		if(not DesktopMode.CanSelectModel) then
			obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "biped"); -- this will pick any object
		else
			obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject"); -- this will pick any object
		end
		
		local bSelectedObject;
		local bClickedChar;
		if(obj:IsValid()) then
			-- click a character
			if(DesktopMode.CanClickCharacter) then
				if(obj:IsCharacter())then
					bSelectedObject = true;
					bClickedChar = true;
					-- call the on_click event
					obj:On_Click(0,0,0);
				end
			end
			-- NOTE 2009/10/26: a strange bug appears that in RainbowFlowerGame the character is deleted in OBJ_SelectObject hook
			--		and invalid obj is got in obj:On_Click(0,0,0); which leads to program crash
			-- allow select character and context menu
			if(DesktopMode.CanSelect) then
				-- we only allow selection to character in navigation mode
				if(obj:IsCharacter()) then
					if(DesktopMode.CanSelectCharacter) then
						bSelectedObject = true;
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SelectObject, obj=obj});
					end	
				else
					if(DesktopMode.CanSelectModel) then
						bSelectedObject = true;
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SelectObject, obj=obj});
					else
						-- NOTE by Andy: post deselect, if model can't be selected
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject});
					end	
				end
			end
			if(not bSelectedObject and (Map3DSystem.SystemInfo.GetField("name") == "Aries")) then
				MoveToMouseCursorPick();
			end
		else
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject});
			MoveToMouseCursorPick();
		end
		
	elseif(mouse_button == "right") then
		-- cancel aries right click
		if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
			InputMsg.action = "rightclick";
			return;
		end
		local isContinue = true;
		-- right click object for aquarius project
		local app = Map3DSystem.App.AppManager.GetApp("Aquarius_GUID")
		if(app and type(app.OnMouseRightClickObj) == "function") then
			local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "notplayer"); 
			isContinue = app.OnMouseRightClickObj(obj);
		else
			isContinue = true;
		end
		-- allow context menu
		if(isContinue == true) then
			if(DesktopMode.CanContextMenu) then
				isContinue = false;
				local obj = ParaScene.MousePick(Mouse.mouse_pick_distance, "anyobject"); 
				isContinue = not Map3DSystem.UI.ContextMenu.ShowMenuForObject(obj);
			end
		end
		-- moving the character to a given location, if user (double) clicks right mouse
		if(isContinue == true) then
			MoveToMouseCursorPick()
		end
	
	elseif(mouse_button == "middle") then	
		-- cancel aries right click
		if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
			if(not Map3DSystem.bAllowTeleport) then
				return;
			end
		end
		-- quick move the character to the location. 
		Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_TELEPORT_PLAYER});
	end
end

