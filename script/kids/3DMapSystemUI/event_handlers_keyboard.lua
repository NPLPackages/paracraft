--[[
Title: The map system Event handlers
Author(s): LiXizhi(code&logic)
Date: 2006/1/26
Desc: only included in event_handlers.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers_keyboard.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/action_table.lua");
				
-------------------------------------
-- character mount action rules
-------------------------------------
NPL.load("(gl)script/ide/rulemapping.lua");
local CharMountRules = CommonCtrl.rulemapping:new("script/AI/animations/mount.rules.table")

-- get mount aniamtion file according to driver and target asset key
local function GetMountAnimationFile(driver, target)
	if(driver and target and driver:IsValid() and target:IsValid()) then
		local target_assetkey = target:GetPrimaryAsset():GetKeyName();
		local driver_assetkey = driver:GetPrimaryAsset():GetKeyName();
		if(driver_assetkey == "character/v3/TeenElf/Female/TeenElfFemale.xml") then
			
			if(target_assetkey == "character/v6/02animals/MagicBesom/MagicBesom.x") then
				return "character/Animation/v5/DefaultMount_teen.x";
				-- return "character/Animation/v5/MagicBesom_teen.x";
			elseif(target_assetkey == "character/common/teen_default_combat_pose_mount/teen_default_combat_pose_mount.x") then
				return "character/Animation/v6/teen_default_combat_pose_female.x";
			elseif(target_assetkey == "character/v6/02animals/WhiteCloud/WhiteCloud.x") then
				return "character/Animation/v6/teen_default_combat_pose_female.x";
				--return "character/Animation/v6/teen_Mount_FlyingCloud_female.x";
			else
				return "character/Animation/v5/DefaultMount_teen.x";
			end
		elseif(driver_assetkey == "character/v3/TeenElf/Male/TeenElfMale.xml") then
			
			if(target_assetkey == "character/v6/02animals/MagicBesom/MagicBesom.x") then
				return "character/Animation/v5/DefaultMount_teen.x";
				-- return "character/Animation/v5/MagicBesom_teen.x";
			elseif(target_assetkey == "character/common/teen_default_combat_pose_mount/teen_default_combat_pose_mount.x") then
				return "character/Animation/v6/teen_default_combat_pose_male.x";
			elseif(target_assetkey == "character/v6/02animals/WhiteCloud/WhiteCloud.x") then
				return "character/Animation/v6/teen_default_combat_pose_male.x";
				--return "character/Animation/v6/teen_Mount_FlyingCloud_male.x";
			else
				return "character/Animation/v5/DefaultMount_teen.x";
			end
		end
	end
end

-- auto play mount animation of player according to the being mounted target object. 
-- @param player: player that is mounted
-- @param targetObject: the target object, a car or other models.
-- @param AnimID: the animation index in the rule value table. if nil the default matching animation will be played by player. For instance 4 is usually forward, 13 is usually backward
local function AutoPlayMountAnim(player, targetObject, AnimID)
	local modelname = targetObject:GetPrimaryAsset():GetKeyName();
	if(modelname) then
		modelname = string.match(modelname, "/([^/]+)%.%w+$");
		if(modelname) then
			local animFile = CharMountRules(modelname);
			if(type(animFile) == "string") then
				Map3DSystem.Animation.PlayAnimationFile(animFile, player);
			elseif(type(animFile) == "table") then
				local file = animFile[AnimID or 1] or animFile[1]
				if(file) then
					Map3DSystem.Animation.PlayAnimationFile(file, player);	
				end	
			else
				-- if no mount animation is found, use the default one. 
				local player_asset_name = player:GetPrimaryAsset():GetKeyName();
				if(player_asset_name == "character/v3/Elf/Female/ElfFemale.xml") then
					Map3DSystem.Animation.PlayAnimationFile("character/Animation/v5/DefaultMount.x", player);
				else
					local anim_file = GetMountAnimationFile(player, targetObject);
					Map3DSystem.Animation.PlayAnimationFile(anim_file or "character/Animation/v5/DefaultMount_teen.x", player);
				end
				---- if no mount animation is found, play animation sequence 91
				--player:ToCharacter():PlayAnimation(91);
			end
		end
	end
end

-- get mount aniamtion file according to driver and target asset key
-- @param driver: driver obj
-- @param target: target obj
function Map3DSystem.GetMountAnimationFile(driver, target)
	return GetMountAnimationFile(driver, target);
end

-- mount the a character on a target. the target may be a character or mesh with at least one attachment point
-- if there are multiple attachment point, it will mount to the closest one to player. 
-- @param player: the character to mount on target. 
-- @param target: the target object to mount on
-- @param bAutoSwitch: if this is true, then if current player is already mounted it will switch to target, but not mount on it, 
-- @param bForcePlayMountAnim: force to play mount animation if player is already mounted on the target
-- if current player is not mounted , it will mount on it. Thus it allows toggling between vehicle and driver. 
function Map3DSystem.MountPlayerOnChar(player, target, bAutoSwitch, bForcePlayMountAnim)
	if(player==nil or not player:IsCharacter() or target==nil) then return end
	
	local char = player:ToCharacter();
	
	-- there is no need to check target:HasAttachmentPoint(0), since asset may be async loaded. 
	if(not char:IsMounted()) then
		-- only mount if target has attachment points and the current player is not attached before.
		-- force the char to face up front.
		player:GetAttributeObject():SetField("HeadTurningAngle", 0);
		char:MountOn(target);
		AutoPlayMountAnim(player, target)
	else
		if(bForcePlayMountAnim) then
			AutoPlayMountAnim(player, target)
		end
	end	
	if(bAutoSwitch and target:IsCharacter()) then
		-- if target is a global and non-opc character, we will try to focus (switch to it). 
		Map3DSystem.SwitchToObject(target);
	end
end

--------------------------------------
-- key handlers
--------------------------------------
local OriginalDensity = nil;
local KeyBoard = commonlib.gettable("Map3DSystem.KeyBoard");
-- mapping from virtual_key to boolean. we will only allow key in this list to pass.  
local key_pass_filter = nil;

KeyBoard.enter_key_filter = {[Event_Mapping.EM_KEY_RETURN] = true, [Event_Mapping.EM_KEY_NUMPADENTER]=true};

-- Set which keys can now be processed. 
-- e.g. System.KeyBoard.SetKeyPassFilter({[Event_Mapping.EM_KEY_RETURN] = true, [Event_Mapping.EM_KEY_NUMPADENTER]=true}) this will only allow enter key to be processed. 
-- @param filter: nil or a table of {virtual_key=boolean, ...} . If nil it will remove key pass filter. 
function KeyBoard.SetKeyPassFilter(filter)
	key_pass_filter = filter;
end

function Map3DSystem_OnKeyDownEvent()
	-- apply key filter
	if(key_pass_filter and not key_pass_filter[virtual_key]) then
		return;
	end

	-- update input message
	local input = Map3DSystem.InputMsg;

	local event_map = Event_Mapping;
	input.virtual_key = virtual_key;
	input.IsComboKeyPressed = (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or 
				ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU))
		 and 
		-- single virtual_key down response for EM_KEY_LCONTROL and EM_KEY_LSHIFT
		-- e.g. BCS Xref activation and avatar prosession operation
		(virtual_key ~= event_map.EM_KEY_LCONTROL) and (virtual_key ~= event_map.EM_KEY_LSHIFT);
	input.wndName = "key_down";
	input.IsSceneEnabled = ParaScene.IsSceneEnabled()
	-- call hook for "input" application
	if(CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROC, 0, "input", input) ==nil) then
		return
	end
	
	-- we will not handle key stroke if either ctrl, shift or alt key is pressed. 
	if(input.IsSceneEnabled and not input.IsComboKeyPressed) then 
		if(virtual_key == event_map.EM_KEY_SPACE) then
			-- space key to jump
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				--[[local speed = ParaScene.GetPlayer():GetField("CurrentSpeed", 5)
				if(speed < 0) then
					speed = - speed;
				end
				char:AddAction(action_table.ActionSymbols.S_JUMP_START, math.max(speed*0.5, 4));]]
				char:AddAction(action_table.ActionSymbols.S_JUMP_START);
			end
			return
		elseif(virtual_key == event_map.EM_KEY_RETURN or virtual_key == event_map.EM_KEY_NUMPADENTER) then
			-- TODO: toggle to the chat 
			if(Map3DSystem.User.HasRight("Chat")) then
				if(Map3DSystem.UI.AppDesktop.CheckUser()) then
					Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetDefaultCommand("EnterChat"));
				end
			end	
			
			return
		--elseif(virtual_key == event_map.EM_KEY_R) then	
			---- 'R' key to toggle running
			--local command = Map3DSystem.App.Commands.GetCommand("player.togglerun");
			--if(command) then command:Call() end
			--return	
		---- allow flying by F key	
		--elseif(virtual_key == event_map.EM_KEY_F) then	
			---- 'F' key to toggle flying
			--local command = Map3DSystem.App.Commands.GetCommand("player.togglefly");
			--if(command) then command:Call() end
			--return	
		elseif(virtual_key == event_map.EM_KEY_L) then	
			-- 'L' key to open quest list
			local command = Map3DSystem.App.Commands.GetCommand("Profile.Aquarius.Task");
			if(command) then command:Call() end
			return	
		elseif(virtual_key == event_map.EM_KEY_M) then	
			-- 'M' key to open local map
			local command = Map3DSystem.App.Commands.GetCommand("Profile.Aquarius.LocalMap");
			if(command) then command:Call() end
			return	
		elseif(virtual_key == event_map.EM_KEY_LSHIFT and Map3DSystem.UI.DesktopMode.CanMountClosest) then
			-- 'left shift' key to switch to and mount on the closest character
			local player = ParaScene.GetPlayer()
			local char = ParaScene.GetPlayer():ToCharacter();
			local fromX, fromY, fromZ = player:GetPosition()
			-- search for any objects within 6 meters from the current player. 
			local objlist = {};
			local nCount = ParaScene.GetObjectsBySphere(objlist, fromX, fromY, fromZ, 6, "");
			local k = 1;
			local closest = nil;
			local min_dist = 100000;
			for k = 1, nCount do
				local obj = objlist[k];
				if(not obj:equals(player) and (obj:IsCharacter() or obj:HasAttachmentPoint(0))) then
					local dist = obj:DistanceTo(player);
					if( dist < min_dist) then
						closest = obj;
						min_dist = dist;
					end
				end
			end	
			if(closest~=nil) then
				Map3DSystem.MountPlayerOnChar(player, closest, true);
			end
			return
		elseif(virtual_key == event_map.EM_KEY_W) then	-- or virtual_key == event_map.EM_KEY_UP
			local player = ParaScene.GetPlayer()
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsMounted()) then
				if(not Map3DSystem.SystemInfo.GetField("name") == "Aries") then
					-- fix: this prevents free camera mode to conflict with action
					if(ParaCamera.GetAttributeObject():GetField("CameraMode", 1) ~= 11) then
						-- when player is mounted, the forward key will just play the running animation (4) of the being mounted object if it is not a character
						local i = player:GetRefObjNum();
						if(i>0) then
							local BeingMountedObj = player:GetRefObject(0);
							if(BeingMountedObj) then
								BeingMountedObj:SetAnimation(4);
								AutoPlayMountAnim(player, BeingMountedObj, 4)
							end
						end
					end
				end
			end
			
		elseif(virtual_key == event_map.EM_KEY_S) then -- or virtual_key == event_map.EM_KEY_DOWN
			local player = ParaScene.GetPlayer()
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsMounted()) then
				if(not Map3DSystem.SystemInfo.GetField("name") == "Aries") then
					-- fix: this prevents free camera mode to conflict with action
					if(ParaCamera.GetAttributeObject():GetField("CameraMode", 1) ~= 11) then
						-- when player is mounted, the forward key will just play the standing animation (0) of the being mounted object if it is not a character
						local i = player:GetRefObjNum();
						if(i>0) then
							local BeingMountedObj = player:GetRefObject(0);
							if(BeingMountedObj) then
								BeingMountedObj:SetAnimation(0); -- TODO:shall it be 13?, take qiuqian for example, it will not stop if 13. 
								AutoPlayMountAnim(player, BeingMountedObj, 13)
							end
						end
					end
				end
			end
		
		elseif((virtual_key == event_map.EM_KEY_LCONTROL or virtual_key == event_map.EM_KEY_RCONTROL) and Map3DSystem.UI.DesktopMode.CanClickClosest ) then	
			-- 'left control' key to fire a missle to the closest character or the closest action point on the selected mesh object
			-- and if the distance is very close, we will perform a click on the character, which is both a selection and an action.
			local player = ParaScene.GetPlayer();
			local char = player:ToCharacter();
			if(char:IsValid())then
				local nCount = player:GetNumOfPerceivedObject();
				local closest = nil;
				local min_dist = 100000;
				for i=0,nCount-1 do
					local gameobj = player:GetPerceivedObject(i);
					local dist = gameobj:DistanceTo(player);
					if( dist < min_dist) then
						closest = gameobj;
						min_dist = dist;
					end
				end
				if(closest~=nil) then
					local fromX, fromY, fromZ = player:GetPosition();
					fromY = fromY+1.0;
					local toX, toY, toZ = closest:GetViewCenter();
					if(min_dist<4) then
						-- just perform a simple click if distance smaller than 4 meters.
						ParaAudio.PlayUISound("Btn5");
						closest:On_Click(0,0,0);
						-- using missile type 2, with a speed of 5.0
						ParaScene.FireMissile(2, 5, fromX, fromY, fromZ, toX, toY, toZ);
					else
						-- using missile type 2(Maybe a different missile), with a speed of 5.0
						ParaScene.FireMissile(2, 5, fromX, fromY, fromZ, toX, toY, toZ);
					end
				end
			end
			-- check if there are any XRef scripts on the nearby mesh object
			
				
			local objlist = {};
			local fromX, fromY, fromZ = player:GetPosition();
			-- NOTE: radius agianst the object center, we only sense the Xref points within the radius
			local NearByRadius = 10;
			local nCount = ParaScene.GetActionMeshesBySphere(objlist, fromX, fromY, fromZ, NearByRadius);
			local k = 1;
			local subIndex = nil;
			local closestObj = nil;
			local min_dist = 100000;
			for k=1,nCount do
				local obj = objlist[k];
				
				local nXRefCount = obj:GetXRefScriptCount();
				local i=0;
				local toX, toY, toZ;
				
				for i=0,nXRefCount-1 do
					toX, toY, toZ = obj:GetXRefScriptPosition(i);
					local dist = math.sqrt((fromX-toX)*(fromX-toX)+(fromY-toY)*(fromY-toY)+(fromZ-toZ)*(fromZ-toZ));
					if( dist < min_dist) then
						subIndex = i;
						closestObj = obj;
						min_dist = dist;
					end
				end
			end
			if(closestObj~=nil) then
				if(not XRefScriptObj) then XRefScriptObj = {} end
				toX, toY, toZ = closestObj:GetXRefScriptPosition(subIndex);
				
				if(min_dist<2) then
					local msg = {};
					msg.posX, msg.posY, msg.posZ = toX, toY, toZ;
					msg.scaleX, msg.scaleY, msg.scaleZ = closestObj:GetXRefScriptScaling(subIndex);
					msg.facing = closestObj:GetXRefScriptFacing(subIndex);
					msg.dist = min_dist;
					msg.localMatrix = closestObj:GetXRefScriptLocalMatrix(subIndex);
					
					-- call the script file
					NPL.call(closestObj:GetXRefScript(subIndex), msg);
				else
					-- fire a missile to the action point on the static mesh
					ParaScene.FireMissile(2, 5, fromX, fromY, fromZ, toX, toY, toZ);
				end
			end
			return
		--elseif(virtual_key == event_map.EM_KEY_TAB) then
			---- tab key to toggle marker display: in most cases, we will only disable marker when doing a camera shot. 
			--Map3DSystem.OnShowMarkers();
			--return	
		elseif(virtual_key >= event_map.EM_KEY_0 and virtual_key <= event_map.EM_KEY_UP9) then
			--local nIndex = math.floor(virtual_key-event_map.EM_KEY_0)/2;
			--if(nIndex == 1) then
				---- face camera
				--Map3DSystem.App.Commands.Call("Profile.CCS.FaceCamera")
			--else
				---- make nIndex [1,9]
				--if(nIndex == 0) then 
					--nIndex = 10;
				--end
				--Map3DSystem.App.Commands.Call("Profile.CCS.AnimationPage", {ShortCutIndex = nIndex-1})
			--end
			return
		elseif(virtual_key == event_map.EM_KEY_F1) then	
			-- show the Help page for the currently active desktop
			--Map3DSystem.App.Commands.Call("File.Help")
			return
		end
		
		if(Map3DSystem.ObjectWnd.OperationState == "MoveObject" or Map3DSystem.ObjectWnd.OperationState == "CopyObject") then
			--------------------------------
			-- mouse cursor object hot key during copy, paste and move 3d object
			--------------------------------
			if(virtual_key == event_map.EM_KEY_MINUS) then	
				-- '_' key to scale down cursor object
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_MoveCursorObject, scale_delta = 0.9});
				return
			elseif(virtual_key == event_map.EM_KEY_EQUALS) then	
				-- '=' key to scale up cursor object
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_MoveCursorObject, scale_delta = 1.1});
				return
			elseif(virtual_key == event_map.EM_KEY_LBRACKET) then	
				-- '[' or '{' key to rotation left cursor object
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_MoveCursorObject, rotY_delta = 0.1});
				return
			elseif(virtual_key == event_map.EM_KEY_RBRACKET) then	
				-- ']' or '}' key to rotation right cursor object
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_MoveCursorObject, rotY_delta = -0.1});
				return		
			end
		end
		
		--if(not ReleaseBuild) then
			---- only valid at in-house development time.
			--
			--if(virtual_key == event_map.EM_KEY_F) then	
				---- 'F' key to change to camera follow mode
				--ParaCamera.GetAttributeObject():CallField("FollowMode");
				--return
			--elseif(virtual_key == event_map.EM_KEY_C) then	
				---- 'C' key to change to camera follow mode
				--ParaCamera.GetAttributeObject():CallField("FreeCameraMode");	
				--return	
			--elseif(virtual_key == event_map.EM_KEY_CAPSLOCK) then	
				---- capslock key to toggle always running
				--local bAlwaysRun = ParaCamera.GetAttributeObject():GetField("AlwaysRun", false);
				--bAlwaysRun = not bAlwaysRun;
				--ParaCamera.GetAttributeObject():SetField("AlwaysRun", bAlwaysRun);
				--return		
			--end
		--end
	else
		-- press any key to go to next logo page	
	end
	
	if(virtual_key == event_map.EM_KEY_ESCAPE) then	
		local state = Map3DSystem.GetState();
		if(type(state) == "table" and state.OnEscKey~=nil) then
			if(state.name ~= "MessageBox") then
				Map3DSystem.PopState(state.name);
			end
			if(type(state.OnEscKey)=="function") then
				state.OnEscKey();
			elseif(type(state.OnEscKey)=="string") then
				NPL.DoString(state.OnEscKey);
			end
				
			return
		end
		
		if(ParaScene.IsSceneEnabled()) then
			if(not ParaUI.GetTopLevelControl():IsValid()) then
				-- it is a game esc key, only if there are no top level control anywhere
				Map3DSystem.OnEscKey();
			end	
		end	
	--elseif(virtual_key == event_map.EM_KEY_F11)then
		-- take screen shot : moved to screen shot application
		--ParaMovie.TakeScreenShot("");
	end
	
	if(virtual_key == event_map.EM_KEY_SCROLLLOCK) then
		-- check for a hidden file dance_drum.lua
		local isAriesRunning = commonlib.getfield("MyCompany.Aries");
		if(isAriesRunning and Map3DSystem.options.isAB_SDK) then
			NPL.load("(gl)script/apps/Aries/Pipeline/main.lua");
			MyCompany.Aries.Pipeline.Show();
		end
	end
	
	-- All SDK functions are here. 
	if(not ReleaseBuild) then
		if(virtual_key == event_map.EM_KEY_F5) then	
			---- F5 key bring up ParaIDE
			--NPL.activate("ParaAllInOne.dll");
		end	
	end
end

-- when esc key is clicked. 
function Map3DSystem.OnEscKey()
	-- TODO
	Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetDefaultCommand("OnGameEscKey"));
end