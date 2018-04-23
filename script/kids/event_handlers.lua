--[[
Title: The Kids Event handlers
Author(s): LiXizhi(code&logic)
Date: 2006/1/26
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/event_handlers.lua");
KidsUI.ReBindEventHandlers();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/action_table.lua");
NPL.load("(gl)script/ide/GUI_inspector_simple.lua");
NPL.load("(gl)script/kids/Ui/autotips.lua");
				
local L = CommonCtrl.Locale("KidsUI");

-- KidsUI: Kids UI library 
if(not KidsUI) then KidsUI={}; end


-- automatically called when script is loaded. However, if the application restarts, remember to call 
function KidsUI.InitMakerAsset()
	if(not KidsUI.Assets) then
		KidsUI.Assets = {};
	end
	local L = CommonCtrl.Locale("IDE");
	-- TODO: move asset to locale file.
	KidsUI.Assets["CharMaker"] = ParaAsset.LoadStaticMesh("", "model/common/marker_point/marker_point.x") --ParaAsset.LoadParaX("", L"CharMaker");
	KidsUI.Assets["XRefScript"] = ParaAsset.LoadStaticMesh("", "model/common/building_point/building_point.x") --ParaAsset.LoadParaX("", L"XRefScript");
end

function KidsUI.ReBindEventHandlers()
	-- register mouse picking event handler
	ParaScene.RegisterEvent("_m_kidsui_pick", ";KidsUI_OnMouseClick();");
	-- register key event handler
	ParaScene.RegisterEvent("_k_kidsmovie_keydown", ";KidsUI_OnKeyDownEvent();");
	-- register network event handler
	ParaScene.RegisterEvent("_n_kidsmovie_network", ";KidsUI_OnNetworkEvent();");

	-- init some assets
	KidsUI.InitMakerAsset();
	
	-- register a timer for updates
	NPL.SetTimer(101, 1.0, ";OnKidsTimer101();");
	-- register a timer for displaying markers
	NPL.SetTimer(102, 0.5, ";OnKidsTimerActionHelper();");
end


KidsUI.bShowMarkers = false;
function KidsUI.OnShowMarkers(bShow) 
	if(not bShow) then
		bShow = not KidsUI.bShowMarkers;
	end
	KidsUI.bShowMarkers = bShow;
	if(bShow) then
		NPL.SetTimer(102, 0.5, ";OnKidsTimerActionHelper();");
	else
		NPL.KillTimer(102);
	end	
end

--[[ called when the user clicked on a scene object with its mouse.]]
function KidsUI_OnMouseClick()
	if(ParaScene.IsSceneEnabled()~=true) then 
		return	
	end
	if(mouse_button == "left") then
		-- pick mesh only
		local obj = ParaScene.MousePick(40, CommonCtrl.CKidLeftContainer.GetFilterName());
		-- Fire a missile from the current player to the picked object.
		local player = ParaScene.GetObject("<player>");
		if(obj:IsValid()==true and player:IsValid()==true) then
			local fromX, fromY, fromZ = player:GetPosition();
			fromY = fromY+1.0;
			local toX, toY, toZ = obj:GetViewCenter();
			-- using missile type 2, with a speed of 5.0
			ParaScene.FireMissile(2, 5, fromX, fromY, fromZ, toX, toY, toZ);
			
			-- attach an arrow to the head of the selected character, and remove arrows from previously selected model.
			if(obj.name~=KidsUI.LastSelectedCharacterName) then
				-- remove arrow from old
				if(KidsUI.LastSelectedCharacterName~=nil) then
					local lastplayer = ParaScene.GetCharacter(KidsUI.LastSelectedCharacterName);
					if(lastplayer:IsValid()==true)then
						lastplayer:ToCharacter():RemoveAttachment(11);
						KidsUI.LastSelectedCharacterName = nil;
					end
				end
				-- attach to new one
				if(obj:IsCharacter() == true) then
					if(KidsUI.HeadArrowAsset~=nil and KidsUI.HeadArrowAsset:IsValid() == true) then
						KidsUI.LastSelectedCharacterName = obj.name;
						obj:ToCharacter():RemoveAttachment(11);
						obj:ToCharacter():AddAttachment(KidsUI.HeadArrowAsset, 11);
					end
				end
			end
			ObjEditor.SetCurrentObj(obj);
			
			-- selected an object
			CommonCtrl.CKidLeftContainer.SwitchUI("object");
			if(obj:IsCharacter()==true)then
				
				ParaAudio.PlayUISound("Btn5");
				CommonCtrl.CKidMiddleContainer.SwitchUI("property");
				-- show CCSMenu when selecting character in 3d map system main menu
				if(application_name == "3DMapSystem" and State_3DMapSystem == "MainMenu") then
					CommonCtrl.CKidMiddleContainer.SwitchUI("CCSMenu");
				end
				-- call the on_click event
				obj:On_Click(0,0,0);
			else
			
				ParaAudio.PlayUISound("Btn1");
				CommonCtrl.CKidMiddleContainer.SwitchUI("modify");
			end
		else
		
			ParaAudio.PlayUISound("Btn7");
			-- selected nothing
			ObjEditor.SetCurrentObj(nil);
			CommonCtrl.CKidMiddleContainer.SwitchUI("text");
			CommonCtrl.CKidLeftContainer.SwitchUI("environment");
			
			-- remove arrow from old
			if(KidsUI.LastSelectedCharacterName~=nil) then
				local lastplayer = ParaScene.GetCharacter(KidsUI.LastSelectedCharacterName);
				if(lastplayer:IsValid()==true)then
					lastplayer:ToCharacter():RemoveAttachment(11);
					KidsUI.LastSelectedCharacterName = nil;
				end
			end
		end
	end
end

-- this is timer handler for timer ID 101
function OnKidsTimer101()
	if(ParaScene.IsSceneEnabled()~=true) then 
		return	
	end
	local self = CommonCtrl.GetControl("kidmiddlecontainer");
	if(self~=nil and self.state=="property")then
		-- update the movie timer. 
		if(CommonCtrl.CKidMiddleContainer.IsMovieControlVisible() == true) then
			local ctl = CommonCtrl.GetControl("Actor_behavior_cont");
			if(ctl~=nil) then
				ctl:Update();
			end
		end
	end	
	local temp = ParaUI.GetUIObject("KidsUI_MovieBox");
	if((temp:IsValid() == true) and (temp.visible == true)) then
		local ctl = CommonCtrl.GetControl("ClipMovieCtrl1");
		if(ctl~=nil) then
			ctl:Update(0);
		end
	end
end

-- display some helper via mini scene graph
-- this is timer handler for timer ID 102
function OnKidsTimerActionHelper()
	if(not ParaScene.IsSceneEnabled()) then 
		return	
	end
	local nextaction;
	
	-- find all nearby characters and display some visual clues 
	local CharMarkerGraph_Last = ParaScene.GetMiniSceneGraph("CharMarker");
	local CharMarkerGraph = ParaScene.GetMiniSceneGraph("CharMarkerLast");
	local EditMarkerGraph = ParaScene.GetMiniSceneGraph("EditMarker");
	--TODO: local EditMarkerGraphSwap = ParaScene.GetMiniSceneGraph("EditMarkerSwap");
	-- here is the trick: create two graphs: current and last, and move objects from last to current, and delete remaining ones in the last. 
	CharMarkerGraph:SetName("CharMarker");
	CharMarkerGraph_Last:SetName("CharMarkerLast");
	EditMarkerGraph:SetName("EditMarker");
	
	local XRefScriptGraph = ParaScene.GetMiniSceneGraph("XRefScriptMarkerLast");
	local XRefScriptGraph_Last = ParaScene.GetMiniSceneGraph("XRefScriptMarker");
	XRefScriptGraph:SetName("XRefScriptMarker");
	XRefScriptGraph_Last:SetName("XRefScriptMarkerLast");
	
	local player = ParaScene.GetPlayer();
	local char = player:ToCharacter();
	
	if(KidsMovie_FunctionSet_BCS == true) then
		if(BCS_main.CurrentMarkerValid == true) then
			-- current edit marker valid
			local editMarkerX = BCS_main.CurrentMarkerPosX;
			local editMarkerY = BCS_main.CurrentMarkerPosY;
			local editMarkerZ = BCS_main.CurrentMarkerPosZ;
			local obj = EditMarkerGraph:GetObject("EditMarker");
			if(obj:IsValid() == false) then
				obj = ParaScene.CreateMeshPhysicsObject("EditMarker", 
					KidsUI.Assets["CharMaker"], 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
				EditMarkerGraph:AddChild(obj);
				if(obj:IsValid() == true) then
					obj:SetPosition(editMarkerX, editMarkerY, editMarkerZ);
					obj:SetScale(1.5);
				end
			else
				obj:SetPosition(editMarkerX, editMarkerY, editMarkerZ);
			end
		else
			EditMarkerGraph:Reset();
		end
	end
	
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
			-- Shall we display something to all perceived characters?
			
		end
		if(closest~=nil) then
			local fromX, fromY, fromZ = player:GetPosition();
			fromY = fromY+1.0;
			local toX, toY, toZ = closest:GetPosition();
			if(min_dist<4) then
				-- highlight the closest interactable character
				local donot_highlight;
				
				local onclickscript = closest:GetAttributeObject():GetField("On_Click", ""); 
				if(onclickscript~=nil and onclickscript~="") then
					nextaction = L"press Ctrl key to talk to it!"
				else
					if(char:IsMounted())then
						nextaction = L"press Space key to get off!"
						-- if object is mounted, do not highlight
						donot_highlight = true;
					elseif(closest:ToCharacter():IsMounted()) then
						nextaction = L"press Shift key and then Space key to get off!"
						-- if closest object is mounted, do not highlight
						donot_highlight = true;
					elseif(closest:HasAttachmentPoint(0)==true) then
						nextaction = L"press Shift key to mount on it!"
					else
						nextaction = L"press Shift key to switch to it!"
					end
					if(not closest:IsStanding()) then
						-- if object is moving, do not highlight
						donot_highlight = true;
					end
				end	
				
				if(not donot_highlight) then
					local obj = CharMarkerGraph_Last:GetObject(toX, toY, toZ);
					if(obj:IsValid()) then
						-- if there is already an highlighter in the last frame, we will reuse it in the current frame.
						CharMarkerGraph_Last:RemoveObject(obj);
						CharMarkerGraph:AddChild(obj);
					else	
						obj = ParaScene.CreateMeshPhysicsObject("ClosestCharMaker", KidsUI.Assets["CharMaker"], 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
						if(obj:IsValid()==true) then
							obj:SetPosition(toX, toY, toZ);
							obj:SetFacing(0);
							obj:GetAttributeObject():SetField("progress", 1);
							CharMarkerGraph:AddChild(obj);
						end
					end	
				end

			else
				-- TODO: mark the closest character, but player is not close enough to interact with it.
			end
		end
	end
	
	
	
	-- find any XRef scripts on the nearby mesh objects
	local objlist = {};
	local fromX, fromY, fromZ = player:GetPosition();
	local NearByRadius = 5;
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
			local script = obj:GetXRefScript(i);
			-- only display a visual helper if the script file contains "_point" in the file name.
			if(string.find(script, "model/scripts/.+_point.*") ~= nil) then
			
if(KidsMovie_FunctionSet_BCS == true) then

				-- display some visual clues if it is an the action point
				local meshobj = XRefScriptGraph_Last:GetObject(toX, toY, toZ);
				if(meshobj:IsValid()) then
					-- if there is already an highlighter in the last frame, we will reuse it in the current frame.
					XRefScriptGraph_Last:RemoveObject(meshobj);
					XRefScriptGraph:AddChild(meshobj);
				else	
					local transform = obj:GetXRefScriptLocalMatrix(i);
					if(not transform) then
						transform = "1,0,0,0,1,0,0,0,1,0,0,0"
					end
					meshobj = ParaScene.CreateMeshPhysicsObject("XRefScriptMaker", KidsUI.Assets["XRefScript"], 1,1,1, false, transform);
					if(meshobj:IsValid()==true) then
						meshobj:SetPosition(toX, toY, toZ);
						meshobj:SetFacing(0);
						meshobj:GetAttributeObject():SetField("progress", 1);
						XRefScriptGraph:AddChild(meshobj);
					end
				end	
				
end --if(KidsMovie_FunctionSet_BCS == true) then

			end	
		end
	end
	if(closestObj~=nil) then
		if(not XRefScriptObj) then XRefScriptObj = {} end
		toX, toY, toZ = closestObj:GetXRefScriptPosition(subIndex);
		if(min_dist<2) then
			-- TODO: when it is the nearest action point, display some specials
			local script = closestObj:GetXRefScript(subIndex);
			-- only display a visual helper if the script file contains "_point" in the file name.
			if(string.find(script, "model/scripts/.+_point.*") ~= nil) then
			
if(KidsMovie_FunctionSet_BCS == true) then

				local obj = CharMarkerGraph_Last:GetObject(toX, toY, toZ);
				if(obj:IsValid()) then
					-- if there is already an highlighter in the last frame, we will reuse it in the current frame.
					CharMarkerGraph_Last:RemoveObject(obj);
					CharMarkerGraph:AddChild(obj);
				else	
					obj = ParaScene.CreateMeshPhysicsObject("ClosestCharMaker", KidsUI.Assets["CharMaker"], 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
					if(obj:IsValid()==true) then
						obj:SetPosition(toX, toY, toZ);
						obj:SetFacing(0);
						obj:GetAttributeObject():SetField("progress", 1);
						CharMarkerGraph:AddChild(obj);
					end
				end	
				
				nextaction = L"press Ctrl key to change the building block!"
					--local msg = {};
					--msg.posX, msg.posY, msg.posZ = toX, toY, toZ;
					--msg.scaleX, msg.scaleY, msg.scaleZ = closestObj:GetXRefScriptScaling(subIndex);
					--msg.facing = closestObj:GetXRefScriptFacing(subIndex);
					--msg.dist = min_dist;
					--
					---- call the script file
					--NPL.call(closestObj:GetXRefScript(subIndex), msg);
					
end --if(KidsMovie_FunctionSet_BCS == true) then

			elseif(string.find(script, "model/scripts/.+chair.*") ~= nil) then
				-- show tips: press control key to sit on the chair
				nextaction = L"press Ctrl key to sit!"
			end	
		else
			-- TODO: it is the nearest action point, but character is not close enough to trigger it
		end
	end
	

	CharMarkerGraph_Last:Reset();
	XRefScriptGraph_Last:Reset();
	
	-- display tips
	autotips.AddTips("nextaction", nextaction, 10);
end

-- key handlers
function KidsUI_OnKeyDownEvent()
	if(ParaScene.IsSceneEnabled()==true) then 
		if(virtual_key == Event_Mapping.EM_KEY_SPACE) then	
			-- space key to jump
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				char:AddAction(action_table.ActionSymbols.S_JUMP_START);
			end
			return
		elseif(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
			-- toggle to the text pannel of the middle containerand set focus on the text input control.
			if(CommonCtrl.CKidMiddleContainer~=nil) then
				CommonCtrl.CKidMiddleContainer.SwitchUI("text");
				local tmp = ParaUI.GetUIObject("kidui_text_text");
				if(tmp:IsValid() and tmp.visible) then
					tmp:Focus();
				end
			end	
			return	
		elseif(virtual_key == Event_Mapping.EM_KEY_O) then
			-- 'O' key to cycle player. (Better cycle to closest one?)
			ParaScene.TogglePlayer();
			return
		elseif(virtual_key == Event_Mapping.EM_KEY_P) then
			-- 'P' key to pause/resume the game
			if(ParaScene.IsScenePaused() == true) then
				ParaScene.PauseScene(false);
			else
				ParaScene.PauseScene(true);
			end	
			return
		elseif(virtual_key == Event_Mapping.EM_KEY_R) then	
			-- 'R' key to toggle running
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				if(char:WalkingOrRunning() ==true) then
					char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, action_table.ActionKeyID.TOGGLE_TO_RUN);
				else
					char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, action_table.ActionKeyID.TOGGLE_TO_WALK);
				end	
			end
			return	
		elseif(virtual_key == Event_Mapping.EM_KEY_LSHIFT) then	
			-- 'left shift' key to mount on closest character
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
					if((closest:IsGlobal() ==true) and (closest:IsCharacter() == true) and (closest:IsOPC()==false)) then
						if(char:IsMounted()) then
							ParaScene.TogglePlayer();
						else
							if(closest:HasAttachmentPoint(0)==true) then
								char:MountOn(closest)
							end
							closest:ToCharacter():SetFocus();
						end
					else
						_guihelper.MessageBox(L"You can not take control of this character");
					end
				end
			end
			return
		elseif(virtual_key == Event_Mapping.EM_KEY_LCONTROL or virtual_key == Event_Mapping.EM_KEY_RCONTROL ) then	
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
			--if(KidsMovie_FunctionSet_BCS == true) then
			
				
				local objlist = {};
				local fromX, fromY, fromZ = player:GetPosition();
				local nCount = ParaScene.GetActionMeshesBySphere(objlist, fromX, fromY, fromZ, 1);
				local k = 1;
				local subIndex = nil;
				local closestObj = nil;
				local min_dist = 100000;
				for k=1,nCount do
					local obj = objlist[k];
					
					local nXRefCount = obj:GetXRefScriptCount();
					local i=0;
					local toX, toY, toZ;
					
					for i=0,nXRefCount do
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
			
			--end
			return
		--elseif(virtual_key == Event_Mapping.EM_KEY_TAB) then
			---- tab key to toggle marker display: in most cases, we will only disable marker when doing a camera shot. 
			--KidsUI.OnShowMarkers();
			--return
		elseif(virtual_key == Event_Mapping.EM_KEY_1) then	
			-- '1' key to perform an action
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, "a1");
			end
			return	
		elseif(virtual_key == Event_Mapping.EM_KEY_2) then	
			-- '2' key to perform an action
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, "a2");
			end
			return		
		elseif(virtual_key == Event_Mapping.EM_KEY_3) then	
			-- '3' key to perform an action
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, "e_d");
			end
			return		
		elseif(virtual_key == Event_Mapping.EM_KEY_F1) then	
			KidsUI.ShowQuickHelp();
			return
		end
		if(not ReleaseBuild) then
			-- only valid at in-house development time.
			
			if(virtual_key == Event_Mapping.EM_KEY_4)then
				-- create the last object at the current mouse position
				local pt = ParaScene.MousePick(70, "point");
				if(pt:IsValid())then
					ObjEditor.CreateLastObject({pt:GetPosition()});
				end
			elseif(virtual_key == Event_Mapping.EM_KEY_5)then	
				-- delete the mesh object at the current mouse position
				local obj = ParaScene.MousePick(70, "");
				if(obj:IsValid()) then
					if(obj:IsCharacter() == false) then
						log("object found\r\n");
						CommonCtrl.CKidLeftContainer.OnDeleteObject(obj);
					end
				end	
			elseif(virtual_key == Event_Mapping.EM_KEY_F) then	
				-- 'F' key to change to camera follow mode
				ParaCamera.GetAttributeObject():CallField("FollowMode");
				return
			elseif(virtual_key == Event_Mapping.EM_KEY_C) then	
				-- 'C' key to change to camera follow mode
				ParaCamera.GetAttributeObject():CallField("FreeCameraMode");	
				return	
			elseif(virtual_key == Event_Mapping.EM_KEY_CAPSLOCK) then	
				-- capslock key to toggle always running
				local bAlwaysRun = ParaCamera.GetAttributeObject():GetField("AlwaysRun", false);
				bAlwaysRun = not bAlwaysRun;
				ParaCamera.GetAttributeObject():SetField("AlwaysRun", bAlwaysRun);
				return		
			end
		end
	else
		-- press any key to go to next logo page
		if(KidsUI.GetState() == "product_logo") then
			KidsUI.NextLogoPage(2000);
			if(KidsUI.CurrentLogoPage == nil) then
				if(not KidsUI.Exiting) then
					KidsUI.restart();
				else
					ParaGlobal.ExitApp();
					if(not ParaEngine.IsProductActivated()) then
						-- open the community website
						local CommunitySite = CommonCtrl.Locale("KidsUI")("community.aspx");
						ParaGlobal.ShellExecute("open", "iexplore.exe", CommunitySite, nil, 1);
					end
				end	
			end
			return
		end
	end
	if(virtual_key == Event_Mapping.EM_KEY_ESCAPE) then	
		local state = KidsUI.GetState();
		if(type(state) == "table" and state.OnEscKey~=nil) then
			if(type(state.OnEscKey)=="function") then
				state.OnEscKey();
			elseif(type(state.OnEscKey)=="string") then
				NPL.DoString(state.OnEscKey);
			end
			KidsUI.PopState(state.name);
			return
		end
		
		if(ParaScene.IsSceneEnabled()) then
			if(not ParaUI.GetTopLevelControl():IsValid()) then
				-- it is a game esc key, only if there are no top level control anywhere
				KidsUI.OnEscKey();
			end	
		end	
	elseif(virtual_key == Event_Mapping.EM_KEY_F11)then
		-- take screen shot 
		ParaMovie.TakeScreenShot("");
	end
end

function KidsUI_OnNetworkEvent()
	if(event_type == Net_Event.ID_ACCOUNT_LOGIN_ACCEPTED) then
		--_guihelper.MessageBox(L"Successfully logged in!".."\r\n");
		KidsUI_ShowChatWindow(true);
		CommonCtrl.chat_display.AddText("chat_display1", L"Successfully logged in!");
		-- TODO: we must ensure that there is a character with the same name as the account name in the current world.
		--
		--local sPlayerName = ParaNetwork.GetLocalNerveReceptorAccountName();
		--local player = ParaScene.GetPlayer();
		--if(player.name ~= sPlayerName) then
			---- change the current player name. 
			--player.name = sPlayerName;
		--end
	elseif(event_type == Net_Event.ID_ACCOUNT_LOGIN_DENIED) then
		_guihelper.MessageBox(L"Log in failed. User does not exist".."\r\n");
		KidsUI_ShowChatWindow(false);
	elseif(event_type == Net_Event.ID_NEW_RECEPTOR_CONNECT) then
		server.OnNewIncomingConnection(pkg.username);
	elseif(event_type == Net_Event.ID_RECEPTOR_USER_LOST) then
		_guihelper.MessageBox(L"Connection with server is broken:"..pkg.username.."\r\n");
		KidsUI_ShowChatWindow(false);
		ParaWorld.SetServerState(0);
	elseif(event_type == Net_Event.ID_CENTER_USER_LOST) then
		--_guihelper.MessageBox(L"Connection with the following user is broken:"..pkg.username.."\r\n");
		KidsUI_ShowChatWindow(true);
		CommonCtrl.chat_display.AddText("chat_display1", L"Connection with the following user is broken:"..pkg.username);
	elseif(event_type == Net_Event.ID_NPL_ERROR) then		
		_guihelper.MessageBox("网络连接失败\r\n");
	end
end