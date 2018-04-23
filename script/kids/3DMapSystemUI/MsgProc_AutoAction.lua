--[[
Title: Auto action timer handler
Author(s): LiXizhi
Date: 2007/10/16
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_AutoAction.lua");
Map3DSystem.EnableAutoActionMarker(true);
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/autotips.lua");

local L = CommonCtrl.Locale("IDE");

-- disabled by default
Map3DSystem.bShowMarkers = false;

local MyTimer;
-- Auto action is a timer that periodically check the player position and its surroundings, and display some helper text and visual markers.
function Map3DSystem.EnableAutoActionMarker(bShow) 
	if(not bShow) then
		bShow = not Map3DSystem.bShowMarkers;
	end
	Map3DSystem.bShowMarkers = bShow;
	if(bShow) then
		Map3DSystem.InitMakerAsset();
		
		NPL.load("(gl)script/ide/timer.lua");
		MyTimer = MyTimer or commonlib.Timer:new({callbackFunc = Map3DSystem.OnTimer_AutoAction});
		MyTimer:Change(500, 500);
	else
		if(MyTimer) then
			MyTimer:Change();
		end
	end	
end

-- automatically called when script is loaded. However, if the application restarts, remember to call 
function Map3DSystem.InitMakerAsset()
	if(not Map3DSystem.Assets) then
		Map3DSystem.Assets = {};
	end
	if(not Map3DSystem.Assets["CharMaker"]) then
		-- TODO: move asset to locale file.
		Map3DSystem.Assets["CharMaker"] = ParaAsset.LoadStaticMesh("", "model/common/marker_point/marker_point.x") --ParaAsset.LoadParaX("", L"CharMaker");
		Map3DSystem.Assets["XRefScript"] = ParaAsset.LoadStaticMesh("", "model/common/building_point/building_point.x") --ParaAsset.LoadParaX("", L"XRefScript");
		Map3DSystem.Assets["BCSSelectMarker"] = ParaAsset.LoadParaX("", "character/common/marker_point/marker_point3.x");
	end	
end


function Map3DSystem.ForceDonotHighlight()
	g_force_donot_highlight = true;
end

function Map3DSystem.CancelForceDonotHighlight()
	g_force_donot_highlight = false;
end

-- display some helper via mini scene graph
-- this is timer handler for timer ID 102
function Map3DSystem.OnTimer_AutoAction()
	if(not ParaScene.IsSceneEnabled()) then 
		return	
	end
	local nextaction;
	
	-- find all nearby characters and display some visual clues 
	local CharMarkerGraph_Last = ParaScene.GetMiniSceneGraph("CharMarker");
	local CharMarkerGraph = ParaScene.GetMiniSceneGraph("CharMarkerLast");
	-- here is the trick: create two graphs: current and last, and move objects from last to current, and delete remaining ones in the last. 
	CharMarkerGraph:SetName("CharMarker");
	CharMarkerGraph_Last:SetName("CharMarkerLast");
	
	local XRefScriptGraph = ParaScene.GetMiniSceneGraph("XRefScriptMarkerLast");
	local XRefScriptGraph_Last = ParaScene.GetMiniSceneGraph("XRefScriptMarker");
	XRefScriptGraph:SetName("XRefScriptMarker");
	XRefScriptGraph_Last:SetName("XRefScriptMarkerLast");
	
	local player = ParaScene.GetPlayer();
	local char = player:ToCharacter();
	
	if(Map3DSystem.UI.DesktopMode.CanShowClosestCharMarker) then
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
				if(min_dist<Map3DSystem.options.CharClickDist) then
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
					
					-- NOTE by Andy: force to unhighlight the closest character, currently the following situations are used:
					-- 1. donot highlight the closest character when movie is playing
					if(g_force_donot_highlight == true) then
						donot_highlight = true;
					end
					
					if(not donot_highlight) then
						local obj = CharMarkerGraph_Last:GetObject(toX, toY, toZ);
						if(obj:IsValid()) then
							-- if there is already an highlighter in the last frame, we will reuse it in the current frame.
							CharMarkerGraph_Last:RemoveObject(obj);
							CharMarkerGraph:AddChild(obj);
						else	
							obj = ParaScene.CreateMeshPhysicsObject("ClosestCharMaker", Map3DSystem.Assets["CharMaker"], 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
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
	else	
		CharMarkerGraph:Reset();
	end	
	
	if(Map3DSystem.UI.DesktopMode.CanShowNearByXrefMarker) then

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
						meshobj = ParaScene.CreateMeshPhysicsObject("XRefScriptMaker", Map3DSystem.Assets["XRefScript"], 1,1,1, false, transform);
						if(meshobj:IsValid()==true) then
							meshobj:SetPosition(toX, toY, toZ);
							meshobj:SetFacing(0);
							meshobj:GetAttributeObject():SetField("progress", 1);
							XRefScriptGraph:AddChild(meshobj);
						end
					end	

				end	
			end
		end
		if(closestObj~=nil) then
			if(not XRefScriptObj) then XRefScriptObj = {} end
			toX, toY, toZ = closestObj:GetXRefScriptPosition(subIndex);
			if(min_dist<Map3DSystem.options.XrefClickDist) then
				-- TODO: when it is the nearest action point, display some specials
				local script = closestObj:GetXRefScript(subIndex);
				-- only display a visual helper if the script file contains "_point" in the file name.
				if(string.find(script, "model/scripts/.+_point.*") ~= nil) then
				
					local obj = CharMarkerGraph_Last:GetObject(toX, toY, toZ);
					if(obj:IsValid()) then
						-- if there is already an highlighter in the last frame, we will reuse it in the current frame.
						CharMarkerGraph_Last:RemoveObject(obj);
						CharMarkerGraph:AddChild(obj);
					else	
						obj = ParaScene.CreateMeshPhysicsObject("ClosestCharMaker", Map3DSystem.Assets["CharMaker"], 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
						if(obj:IsValid()==true) then
							obj:SetPosition(toX, toY, toZ);
							obj:SetFacing(0);
							obj:GetAttributeObject():SetField("progress", 1);
							CharMarkerGraph:AddChild(obj);
						end
					end	
					
					nextaction = L"mouse click on mark or press Ctrl key to change the building block!"
						--local msg = {};
						--msg.posX, msg.posY, msg.posZ = toX, toY, toZ;
						--msg.scaleX, msg.scaleY, msg.scaleZ = closestObj:GetXRefScriptScaling(subIndex);
						--msg.facing = closestObj:GetXRefScriptFacing(subIndex);
						--msg.dist = min_dist;
						--
						---- call the script file
						--NPL.call(closestObj:GetXRefScript(subIndex), msg);

				elseif(string.find(script, "model/scripts/.+chair.*") ~= nil) then
					-- show tips: press control key to sit on the chair
					nextaction = L"press Ctrl key to sit!"
				end	
			else
				-- TODO: it is the nearest action point, but character is not close enough to trigger it
			end
		end
	else
		if(not Map3DSystem.UI.DesktopMode.CanShowClosestCharMarker) then
			CharMarkerGraph:Reset();
		end	
		XRefScriptGraph:Reset();
	end

	CharMarkerGraph_Last:Reset();
	XRefScriptGraph_Last:Reset();
	
	-- display tips
	autotips.AddTips("nextaction", nextaction, 10);
	
	-- refresh autotips. 
	autotips.Refresh();
end