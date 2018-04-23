--[[
Title: The map system Event handlers
Author(s): LiXizhi(code&logic)
Date: 2007/10/16
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_obj.lua");
Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveObject})
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/TimeSeries/TimeSeries.lua");
NPL.load("(gl)script/ide/object_editor.lua");

local Map3DSystem = Map3DSystem;
local User = commonlib.gettable("Map3DSystem.User");
local L = CommonCtrl.Locale("IDE");
local ObjEditor = commonlib.gettable("ObjEditor");

-- switch to object
function Map3DSystem.SwitchToObject(obj)
	local objParam;
	if(type(obj) == "table") then
		-- obj param
		objParam = obj;
	elseif(type(obj) == "userdata") then
		-- obj
		objParam = ObjEditor.GetObjectParams(obj);
	else
		log("warning: switch to a non ParaObject obj in Map3DSystem.SwitchToObject(obj).\n")
		return;
	end
	
	local player = ParaScene.GetPlayer();
	local playerParam = ObjEditor.GetObjectParams(player);
	
	
	local char = ObjEditor.GetObjectByParams(objParam);
	if(char ~= nil and char:IsValid() == true) then
		if(char:IsCharacter() == true) then
			if(not Map3DSystem.User.HasRight("ShiftCharacter"))then
				autotips.AddMessageTips("你的权限无法驾驭这个人物")
			elseif( (char:IsGlobal() == true) and (char:IsCharacter() == true) and 
				(char:IsOPC()==false and char:GetDynamicField("IsOPC", false)==false) ) then
				
				Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SwitchObject, 
					fromObjectParam = playerParam, 
					toObjectParam = objParam, });
					
				-- stop the old character, to prevent it from running after switched off. 
				local fromChar = ObjEditor.GetObjectByParams(playerParam);	
				if(fromChar and not fromChar:IsStanding()) then
					fromChar:ToCharacter():Stop();
				end
			else
				autotips.AddMessageTips("你不能切换到这个人物")
			end
		else
			autotips.AddMessageTips("请选中一个人物完成切换")
		end
	end
end

-------------------------------------------------------------
-- object related
-------------------------------------------------------------
local sys_obj = commonlib.gettable("Map3DSystem.obj");

-- we may support group selection in future. So wrap it with function
Map3DSystem.obj.ObjectParamsPool = {
	-- object in clipboard
	["clipboard"] = nil, 
	-- current selection
	["selection"] = nil, 
	-- last created object
	["lastcreated"] = nil, 
	-- context menu selected object
	["contextmenu"] = nil, 
	
	-- number indexed object,
	[1] = nil,
	[2] = nil,
	[3] = nil,
	-- array of object params in group. Useful when dealing with a group of objects as one entity
	["group1"] = {}, 
	["group2"] = {}, 
	
	-- history is a time series object that contains variables, which are a table of time, value pairs. 
	history=nil,
}; 
local ObjectParamsPool = Map3DSystem.obj.ObjectParamsPool;

-- get the history 
function Map3DSystem.obj.GetHistory()
	local self = sys_obj;
	if(self.history == nil)  then
		self.ResetHistory();
	end
	return self.history;
end

-- reset the history class
function Map3DSystem.obj.ResetHistory()
	local self = sys_obj;
	self.history = TimeSeries:new{name = "ObjHistory",}; 
	self.history:CreateVariable({name = "creations", type="Discrete"});
	-- all shares creations
	--self.history:CreateVariable({name = "modifications", type="Discrete"});
	--self.history:CreateVariable({name = "deletions", type="Discrete"});
end

-- Set one or a group of object params from ObjectParamsPool. 
-- @param key: the key for the object in the pool. If nil, it default to "selection", which means the current selected. 
function Map3DSystem.obj.SetObjectParams(params, key)
	ObjectParamsPool[key or "selection"] = params;
end

-- get one or a group of object params from ObjectParamsPool. 
-- @param key: the key for the object in the pool. If nil, it default to "selection", which means the current selected. 
function Map3DSystem.obj.GetObjectParams(key)
	return ObjectParamsPool[key or "selection"];
end


-- Set object params to ObjectParamsPool. 
-- @param key: the key for the object in the pool. If nil, it default to "selection", which means the current selected. 
function Map3DSystem.obj.SetObject(obj, key)
	ObjectParamsPool[key or "selection"] = ObjEditor.GetObjectParams(obj);
end

-- get object. it may return nil.
function Map3DSystem.obj.GetObject(key)
	return ObjEditor.GetObjectByParams( ObjectParamsPool[key or "selection"] );
end

-- get object passed in a windows message. 
function Map3DSystem.obj.GetObjectInMsg(msg)
	return msg.obj or ObjEditor.GetObjectByParams(msg.obj_params);
end

-- get object params passed in a windows message. 
function Map3DSystem.obj.GetObjectParamsInMsg(msg)
	return msg.obj_params or ObjEditor.GetObjectParams(msg.obj);
end

----------------------------------------
-- for selection fire timer: it fire a missile to selected object. 
-- This effect is deprecated and only used in Taurus SDK. 
----------------------------------------
local fire_missile_timer;
local function StartFireMissile()
	if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
		return;
	end
	-- register a timer for Missile firing
	fire_missile_timer = fire_missile_timer or commonlib.Timer:new({callbackFunc = function()
		-- fire missile from the player
		local player = ParaScene.GetObject("<player>");
		local fromX, fromY, fromZ = player:GetPosition();
		fromY = fromY+1.0;
		
		local curObj;
		
		-- choose the moving and copying object in the mini scene graph
		if( Map3DSystem.ObjectWnd.OperationState == "MoveObject" or 
			Map3DSystem.ObjectWnd.OperationState == "CopyObject" ) then
			
			local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
			curObj = objGraph:GetObject("cursorObj");
		else
			curObj = Map3DSystem.obj.GetObject("selection");
		end
		
		-- do not fire the missile if the current object is a character object
		if(curObj~=nil) then
			if(not curObj:IsCharacter()) then
				-- fire missile to the current object
				local toX, toY, toZ = curObj:GetViewCenter();
				ParaScene.FireMissile(2, 15, fromX, fromY, fromZ, toX, toY, toZ);	
			end
		end	
	end});
	fire_missile_timer:Change(170, 170);
end

local function EndFireMissile()
	if(Map3DSystem.SystemInfo.GetField("name") == "Aries") then
		return;
	end
	if(fire_missile_timer) then
		fire_missile_timer:Change(nil, nil);
	end	
end

-------------------------------------------------------------
-- message related
-------------------------------------------------------------

function Map3DSystem.OnMessage_OBJ(window, msg)
	local msg_def = Map3DSystem.msg;
	if(msg.type == msg_def.OBJ_ModifyObject) then
		
		----------------------------------------------
		-- modify an object in the scene 
		-- {obj_params={object parameters}, obj, reset=boolean, pos={x,y,z}, pos_delta_camera = {dx,dy,dz},  rot_delta={dx, dy, dz}, quat={x,y,z,w}, scale_delta, scale } 
		----------------------------------------------
		if(msg.checkright and not Map3DSystem.User.CheckRight("Edit")) then return end
		
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(not obj) then return end
		-- tricky: only modifcation message needs to keep a deep copy of obj_params. Since the processor will change msg.obj_params. 
		local obj_params = commonlib.deepcopy(Map3DSystem.obj.GetObjectParamsInMsg(msg));
		
		--local x,y,z = obj:GetPosition();
		--commonlib.echo({x,y,z})
		--commonlib.echo(obj:GetFacing());
		--commonlib.echo(obj:GetScale());
		--commonlib.echo({obj:GetPrimaryAsset():GetKeyName()})
		
		local nServerState = ParaWorld.GetServerState();
		if(msg.forcelocal or nServerState == 0) then
			-- this is a standalone computer
			local re_attach;
			--------------------------------------------------
			-- translation
			--------------------------------------------------
			if(msg.pos~=nil) then
				obj:SetPosition(msg.pos.x, msg.pos.y, msg.pos.z);
				re_attach = true;
			elseif(msg.pos_delta_camera~=nil) then
				local x,y,z = obj:GetPosition();
				local pos_x, pos_y, pos_z = ObjEditor.CameraToWorldSpace(msg.pos_delta_camera.dx, msg.pos_delta_camera.dy, msg.pos_delta_camera.dz);
				-- tricky: save delta pos as absolute pos so that we can save to history for playback.
				msg.pos = {
					x = pos_x + x,
					y = pos_y + y,
					z = pos_z + z,	
				}
				msg.pos_delta_camera = nil;
				obj:SetPosition(msg.pos.x, msg.pos.y, msg.pos.z);
				re_attach = true;
			end
			
			--------------------------------------------------
			-- rotation
			--------------------------------------------------
			if(msg.quat~=nil) then
				obj:SetRotation(msg.quat);
				-- character does not have physics, so does not reattach it to the scene.
				if(obj:IsCharacter()==false) then
					re_attach = true;
				end
			elseif(msg.rot_delta~=nil) then
				obj:Rotate(msg.rot_delta.dx,msg.rot_delta.dy,msg.rot_delta.dz);
				-- character does not have physics, so does not reattach it to the scene.
				if(obj:IsCharacter()==false) then
					re_attach = true;
				end
			end
			
			--------------------------------------------------
			-- scaling
			--------------------------------------------------
			if(msg.scale_delta~=nil) then
				local s = obj:GetScale()*msg.scale_delta;
				obj:SetScale(s);
				-- character does not have physics, so does not reattach it to the scene.
				if(obj:IsCharacter()==false) then
					re_attach = true;
				end
			elseif(msg.scale~=nil) then
				obj:SetScale(msg.scale);
				-- character does not have physics, so does not reattach it to the scene.
				if(obj:IsCharacter()==false) then
					re_attach = true;
				end
			end
			
			-- for character related
			if(obj:IsCharacter()) then
				--------------------------------------------------
				-- base model change
				--------------------------------------------------
				if(type(msg.asset_file) == "string") then
					Map3DSystem.UI.CCS.Predefined.SetBaseModel(obj_params, msg.asset_file);
				end
				
				--------------------------------------------------
				-- CCS
				--------------------------------------------------
				if(type(msg.CCSInfoStr) == "string") then
					Map3DSystem.UI.CCS.ApplyCCSInfoString(obj, msg.CCSInfoStr);
				else
					-- character slot
					if(type(msg.characterslot_info) == "table") then
						Map3DSystem.UI.CCS.Inventory.SetCharacterSlotInfo(obj_params, msg.characterslot_info);
					end
					-- facial param
					if(type(msg.facial_info) == "table") then
						Map3DSystem.UI.CCS.Predefined.SetFacialInfo(obj_params, msg.facial_info);
					end
					-- cartoon face
					if(type(msg.cartoonface_info) == "table") then
						Map3DSystem.UI.CCS.DB.SetCartoonfaceInfo(obj_params, msg.cartoonface_info);
					end
				end	
			end	
			
			if(msg.reset)then
				obj:Reset();
				-- character does not have physics, so does not reattach it to the scene.
				if(obj:IsCharacter()==false) then
					re_attach = true;
				end
			end
				
			if(re_attach) then
				ParaScene.Attach(obj);
			end	
			
			-- change msg.obj_params to updated information. 
			if(msg.obj_params) then
				ObjEditor.GetObjectParams(obj, msg.obj_params)
			end
		elseif(nServerState == 1 or nServerState == 2) then
			-- this is a server or client.
			local pos, quat, scale;
			--------------------------------------------------
			-- translation
			--------------------------------------------------
			if(msg.pos~=nil) then
				pos = msg.pos;
			elseif(msg.pos_delta_camera~=nil) then
				pos = {}
				pos.x, pos.y, pos.z = ObjEditor.CameraToWorldSpace(msg.pos_delta_camera.dx, msg.pos_delta_camera.dy, msg.pos_delta_camera.dz);
				local x,y,z = obj:GetPosition();
				pos.x = pos.x + x;
				pos.y = pos.y + y;
				pos.z = pos.z + z;
			end
			
			--------------------------------------------------
			-- rotation
			--------------------------------------------------
			if(msg.quat~=nil) then
				quat = msg.quat;
			elseif(msg.rot_delta~=nil) then
				local oldquat = obj:GetRotation({});
				obj:Rotate(msg.rot_delta.dx,msg.rot_delta.dy,msg.rot_delta.dz);
				quat = obj:GetRotation({});
				obj:SetRotation(oldquat);
			end
			
			--------------------------------------------------
			-- scaling
			--------------------------------------------------
			if(msg.scale_delta~=nil) then
				scale = obj:GetScale()*msg.scale_delta;
			elseif(msg.scale~=nil) then
				scale = msg.scale;
			end
			
			if(msg.reset)then
				scale = 1.0;
				quat = {x=0, y=0,z=0,w=1}
			end
			
			-- for character related
			if(obj:IsCharacter()) then
				--------------------------------------------------
				-- base model change
				--------------------------------------------------
				if(type(msg.asset_file) == "string") then
					Map3DSystem.UI.CCS.Predefined.SetBaseModel(obj_params, msg.asset_file);
				end
				
				--------------------------------------------------
				-- CCS
				--------------------------------------------------
				if(type(msg.CCSInfoStr) == "string") then
					Map3DSystem.UI.CCS.ApplyCCSInfoString(obj, msg.CCSInfoStr);
				else
					-- character slot
					if(type(msg.characterslot_info) == "table") then
						Map3DSystem.UI.CCS.Inventory.SetCharacterSlotInfo(obj_params, msg.characterslot_info);
					end
					-- facial param
					if(type(msg.facial_info) == "table") then
						Map3DSystem.UI.CCS.Predefined.SetFacialInfo(obj_params, msg.facial_info);
					end
					-- cartoon face
					if(type(msg.cartoonface_info) == "table") then
						Map3DSystem.UI.CCS.DB.SetCartoonfaceInfo(obj_params, msg.cartoonface_info);
					end
				end	
			end	
			
			-------------------------------------
			-- TODO: broadcast CCS modification as client or server
			-------------------------------------
			
			if(nServerState == 1) then
				-- this is a server. 
				server.BroadcastObjectModification(obj, pos, scale, quat);
			elseif(nServerState == 2) then
				-- this is a client. 
				client.RequestObjectModification(obj, pos, scale, quat);
			end
		end	
	
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil and obj_params~=nil and not obj_params.IsCharacter) then
				local history = Map3DSystem.obj.GetHistory();
				local time = history.creations:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author, obj_params = obj_params};
				commonlib.partialcopy(new_msg, msg);
				new_msg.obj=nil;
				history.creations:AutoAppendKey(time+1, new_msg, true);
				-- log("History: "..author.." modified "..tostring(obj_params.AssetFile).."\n")
			end	
		end	
		
	elseif(msg.type == msg_def.OBJ_BeginMoveObject) then
		----------------------------------------------
		-- begin move an object in the scene
		----------------------------------------------
		Map3DSystem.ObjectWnd.OperationState = "MoveObject";
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		if(obj_params~=nil) then
			Map3DSystem.obj.SetObjectParams( obj_params, "clipboard");
			local src_obj = Map3DSystem.obj.GetObject("clipboard");
			if(src_obj~=nil) then
				-- hide source object
				src_obj:SetVisible(false);
				-- disable physics temporarily
				src_obj:EnablePhysics(false);
				
				-- visuals 
				local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
				objGraph:DestroyObject("cursorObj");
				obj_params = commonlib.deepcopy(obj_params);
				obj_params.name = "cursorObj";
				local obj = ObjEditor.CreateObjectByParams(obj_params);
				if(obj~=nil and obj:IsValid()) then
					obj:SetField("progress", 1);
					autotips.AddTips("CursorHelp", "鼠标右键取消,中键编辑,键盘+-放缩, []旋转", 10)
					
					objGraph:AddChild(obj);
					
					-- face the current player to the target. 
					--Map3DSystem.Animation.SendMeMessage({type = msg_def.ANIMATION_Character, animationName = "SelectObject",facingTarget = {x=obj_params.x, y=obj_params.y, z=obj_params.z},});
				end	
			end
		end	
		
	elseif(msg.type == msg_def.OBJ_CopyObject) then
		----------------------------------------------
		-- copy object to clipboard
		----------------------------------------------
		Map3DSystem.ObjectWnd.OperationState = "CopyObject";
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		if(obj_params~=nil) then
			Map3DSystem.obj.SetObjectParams( obj_params, "clipboard");
			
			-- visuals 
			local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
			objGraph:DestroyObject("cursorObj");
			obj_params = commonlib.deepcopy(obj_params);
			obj_params.name = "cursorObj";
			local obj = ObjEditor.CreateObjectByParams(obj_params);
			if(obj~=nil and obj:IsValid()) then
				obj:SetField("progress", 1);
				autotips.AddTips("CursorHelp", "鼠标右键取消,中键编辑,键盘+-放缩, []旋转", 10)
				
				objGraph:AddChild(obj);
				
				-- face the current player to the target. 
				--Map3DSystem.Animation.SendMeMessage({type = msg_def.ANIMATION_Character, animationName = "SelectObject",facingTarget = {x=obj_params.x, y=obj_params.y, z=obj_params.z},});
			end	
		end	
		
	elseif(msg.type == msg_def.OBJ_MoveCursorObject) then	
		----------------------------------------------
		-- move cursor object in the "object_editor" miniscenegraph
		----------------------------------------------
		local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
		local cursorObj = objGraph:GetObject("cursorObj");
		if(cursorObj:IsValid()) then
			if(msg.x~=nil and msg.y~=nil and msg.z~=nil) then
				cursorObj:SetPosition(msg.x, msg.y, msg.z);
			end
			if(msg.scale_delta~=nil) then
				cursorObj:SetScale(cursorObj:GetScale()*msg.scale_delta);
			elseif(msg.scale~=nil) then	
				cursorObj:SetScale(msg.scale);
			end
			
			if(msg.rotY_delta~=nil) then
				cursorObj:Rotate(0,msg.rotY_delta,0);
			elseif(msg.quat~=nil) then
				cursorObj:SetRotation(msg.quat);
			end
			
			if(msg.reset)then
				cursorObj:SetScale(1.0);
				cursorObj:SetRotation({x=0, y=0,z=0,w=1});
			end
		end
	elseif(msg.type == msg_def.OBJ_PopupEditObject) then		
		----------------------------------------------
		-- show a top level window to edit the object at the mouse cursor
		----------------------------------------------
		if(msg.target == "cursorObj") then
			local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
			local cursorObj = objGraph:GetObject("cursorObj");
			if(cursorObj:IsValid()) then
				local obj_params = ObjEditor.GetObjectParams(cursorObj);
				if(obj_params ~= nil) then
					-- TODO: lixizhi 2008.6.13. move this to advanced tab of objmodifypage.html
					NPL.load("(gl)script/kids/3DMapSystemUI/Creator/PopupObjModWnd.lua");
					Map3DSystem.UI.Creator.PopupModWnd.ShowPopupEdit(obj_params, mouse_x, mouse_y, msg.onclose)
				end
			end
		end	
		
	elseif(msg.type == msg_def.OBJ_EndMoveObject) then
		----------------------------------------------
		-- end move object in clipboard: delete old and create a copy at the new location
		----------------------------------------------
		if(Map3DSystem.ObjectWnd.OperationState == "MoveObject") then
			Map3DSystem.ObjectWnd.OperationState = nil;
		end
		
		
		local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
		local cursorObj = objGraph:GetObject("cursorObj");
		if(cursorObj:IsValid()) then
			local old_obj_params = Map3DSystem.obj.GetObjectParams("clipboard");
			local obj_params = ObjEditor.GetObjectParams(cursorObj)
		
			-- delete object in clipboard and create object in clipboard at the new location, if and only if any property changes	
			if( not commonlib.partialcompare(obj_params.x, old_obj_params.x, 0.01) or
				not commonlib.partialcompare(obj_params.y, old_obj_params.y, 0.01) or
				not commonlib.partialcompare(obj_params.z, old_obj_params.z, 0.01) or
				not commonlib.partialcompare(obj_params.rotation, old_obj_params.rotation, 0.01) or
				not commonlib.partialcompare(obj_params.scaling, old_obj_params.scaling, 0.01) ) then
				-- object has changed
				
				-- remember the selection group index. 
				local src_obj = Map3DSystem.obj.GetObject("clipboard");
				if(not src_obj) then
					commonlib.log("warning: clipboard object is not found during OBJ_EndMoveObject\n")
					return;
				end
				local select_group_index = src_obj:GetSelectGroupIndex();
				
				if(old_obj_params.IsCharacter) then
					-- for character object, we will just change its position. 
					src_obj:SetVisible(true);
					local x,y,z = cursorObj:GetPosition();
					src_obj:SetPosition(x,y,z);
					if( not commonlib.partialcompare(obj_params.scaling, old_obj_params.scaling, 0.01)) then
						if(obj_params.scaling) then
							src_obj:SetScale(obj_params.scaling)
						end	
					end
					if( not commonlib.partialcompare(obj_params.facing, old_obj_params.facing, 0.01)) then
						if(obj_params.facing) then
							src_obj:SetFacing(obj_params.facing)
						end
					end
					src_obj:UpdateTileContainer();
				else
					-- for model object, we will delete old and create a new one at the new position. 
					Map3DSystem.SendMessage_obj({type = msg_def.OBJ_DeleteObject, obj_params = old_obj_params});
					
					obj_params.name = old_obj_params.name;
					obj_params.x, obj_params.y, obj_params.z = cursorObj:GetPosition();
					
					Map3DSystem.SendMessage_obj({type = msg_def.OBJ_CreateObject, obj_params = obj_params, progress=1});
				
				end
				
				-- remember the selection index. 
				if(select_group_index >=0) then
					Map3DSystem.SendMessage_obj({type = msg_def.OBJ_SelectObject, obj_params = obj_params, group=select_group_index});
				end
			else
				-- object has not changed
				local src_obj = Map3DSystem.obj.GetObject("clipboard");
				if(src_obj~=nil) then
					-- show source object again
					src_obj:SetVisible(true);
					if(old_obj_params.EnablePhysics) then
						src_obj:EnablePhysics(true);
					end
				end	
			end				
		
			--visuals	
			objGraph:DestroyObject("cursorObj");
		end
		autotips.AddTips("CursorHelp", nil);
		
	elseif(msg.type == msg_def.OBJ_CancelMoveCopyObject) then
		----------------------------------------------
		-- cancel move or copy operation. 
		----------------------------------------------
		if(Map3DSystem.ObjectWnd.OperationState == "MoveObject") then
			Map3DSystem.ObjectWnd.OperationState = nil;
			local src_obj_params = Map3DSystem.obj.GetObjectParams("clipboard");
			local src_obj = Map3DSystem.obj.GetObject("clipboard");
			if(src_obj_params~=nil and src_obj~=nil) then
				-- show source object again
				src_obj:SetVisible(true);
				if(src_obj_params.EnablePhysics) then
					src_obj:EnablePhysics(true);
				end
			end	
		elseif(Map3DSystem.ObjectWnd.OperationState == "CopyObject") then
			Map3DSystem.ObjectWnd.OperationState = nil;
		end
		
		--visuals
		local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
		objGraph:DestroyObject("cursorObj");
		autotips.AddTips("CursorHelp", nil);
		
	elseif(msg.type == msg_def.OBJ_PasteObject) then
		----------------------------------------------
		-- paste object in clipboard
		----------------------------------------------
		if(not msg.silentmode) then
			-- paste from mini scene graph 
			local objGraph = ParaScene.GetMiniSceneGraph("object_editor");
			local cursorObj = objGraph:GetObject("cursorObj");
			if(cursorObj:IsValid()) then
				local old_obj_params = Map3DSystem.obj.GetObjectParams("clipboard");
				if(old_obj_params~=nil) then
					local obj_params = ObjEditor.GetObjectParams(cursorObj)
					obj_params.name = old_obj_params.name;
					obj_params.x, obj_params.y, obj_params.z = cursorObj:GetPosition();
					
					Map3DSystem.SendMessage_obj({type = msg_def.OBJ_CreateObject, obj_params = obj_params});
				end	
			end
		else	
			-- paste directly from clipboard.
			local obj_params = Map3DSystem.obj.GetObjectParams("clipboard");
			if(obj_params~=nil) then
				obj_params = commonlib.deepcopy(obj_params);
				-- use the same name for the new character
				if(msg.x~=nil and msg.y~=nil and msg.z~=nil) then
					obj_params.x, obj_params.y, obj_params.z = msg.x, msg.y, msg.z;
					
					Map3DSystem.SendMessage_obj({type = msg_def.OBJ_CreateObject, obj_params = obj_params});
				end	
			end
		end	
		
	elseif(msg.type == msg_def.OBJ_CreateObject) then	
		----------------------------------------------
		-- create object
		----------------------------------------------
		local obj_params = msg.obj_params;
		if(not obj_params) then return end
		
		-- 2010.2.7 by LXZ: the following code is removed 
		--NPL.load("(gl)script/kids/3DMapSystemUI/Creator/Main.lua");
		---- added on 2008.12.29: for ZhangYu to create any object on "anything" XRef reference point
		--obj_params.x = Map3DSystem.UI.Creator.CreateAnythingOnX or obj_params.x;
		--obj_params.y = Map3DSystem.UI.Creator.CreateAnythingOnY or obj_params.y;
		--obj_params.z = Map3DSystem.UI.Creator.CreateAnythingOnZ or obj_params.z;
		--obj_params.localMatrix = Map3DSystem.UI.Creator.CreateAnythingOnLocalMatrix or obj_params.localMatrix;
		--Map3DSystem.UI.Creator.CreateAnythingOnX = nil;
		--Map3DSystem.UI.Creator.CreateAnythingOnY = nil;
		--Map3DSystem.UI.Creator.CreateAnythingOnZ = nil;
		--Map3DSystem.UI.Creator.CreateAnythingOnLocalMatrix = nil;
		--local obj = ParaScene.GetObject("CreateAnythingMarker")
		--if(obj:IsValid() == true) then
			--ParaScene.Delete(obj);
		--end
		--local player = ParaScene.GetPlayer();
		--player:ToCharacter():RemoveAttachment(11);
		
		if(msg.silentmode) then
			local obj = ObjEditor.CreateObjectByParams(obj_params);
			if(obj~=nil) then
				ParaScene.Attach(obj);
				obj_params.obj_id = obj:GetID();
				Map3DSystem.obj.SetObjectParams( obj_params, "lastcreated");
			end
		else
			local nServerState = ParaWorld.GetServerState();
			
			if(msg.forcelocal or nServerState == 0) then
				-- if the price of the model is not free
				if(msg.obj_params.price~=nil and msg.obj_params.price>10) then
					if(ParaEngine.IsProductActivated()==false) then
						autotips.AddMessageTips("您的产品未注册,无发创建此物品");
						return
					end
				end
				
				-- check if distance too close
				local LastObj = Map3DSystem.obj.GetObjectParams("lastcreated");
				if(LastObj and LastObj.IsCharacter == msg.obj_params.IsCharacter and LastObj.AssetFile == msg.obj_params.AssetFile and LastObj.rotation == msg.obj_params.rotation and LastObj.scaling == msg.obj_params.scaling and 
					(math.abs(LastObj.x - msg.obj_params.x)+math.abs(LastObj.y - msg.obj_params.y)+math.abs(LastObj.z - msg.obj_params.z))<0.01 ) then
					autotips.AddMessageTips(L"==distance too close==\nYou can not create the same object at the same location twice");
					return
				end
	
				local obj = ObjEditor.CreateObjectByParams(msg.obj_params);
				if(obj~=nil) then
					if(msg.progress~=nil) then
						obj:SetField("progress",msg.progress);
					end
					if(msg.effect == "boundingbox") then
						-- TODO: just display its bounding box.
						obj:SetField("showboundingbox", true);
					end	
					ParaScene.Attach(obj);
					Map3DSystem.obj.SetObjectParams( msg.obj_params, "lastcreated");
				end
				
			elseif(nServerState == 1) then
				-- this is a server. 
				server.BroadcastObjectCreation(msg.obj_params.name, msg.obj_params.AssetFile, {[1]=msg.obj_params.x, [2]=msg.obj_params.y, [3]=msg.obj_params.z,}, "");
			elseif(nServerState == 2) then
				-- this is a client. 
				client.RequestObjectCreation(msg.obj_params.name, msg.obj_params.AssetFile, {[1]=msg.obj_params.x, [2]=msg.obj_params.y, [3]=msg.obj_params.z,}, "");
			end
		end	
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil and obj_params~=nil and not obj_params.IsCharacter) then
				local history = Map3DSystem.obj.GetHistory();
				local time = history.creations:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author, obj_params = obj_params};
				commonlib.partialcopy(new_msg, msg);
				new_msg.obj=nil;
				history.creations:AutoAppendKey(time+1, new_msg, true);
				-- log
				-- log("History: "..author.." created "..tostring(obj_params.AssetFile).."\n")
			end	
		end	
		
	elseif(msg.type == msg_def.OBJ_DeleteObject) then
		----------------------------------------------
		-- Delete object
		----------------------------------------------
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj == nil or obj:IsValid()==false) then
			autotips.AddMessageTips("找不到物体，删除操作被忽略了");
			return
		end
		
		local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
		
		local nServerState = ParaWorld.GetServerState();
		if(msg.forcelocal or msg_def.silentmode or nServerState == 0 or obj:IsCharacter()==true) then
			-- this is a standalone computer or a character. 
			
			local curObj = Map3DSystem.obj.GetObject("selection");
			if(curObj~=nil and curObj:equals(obj) == true) then
				-- deselect if object is selected.
				Map3DSystem.SendMessage_obj({type = msg_def.OBJ_DeselectObject});
			end
			
			if(obj:IsCharacter() and obj:IsGlobal()) then
				local NextPlayer = ParaScene.GetNextObject(obj);
				if(NextPlayer:IsValid() == true) then
					if(_movie~=nil) then
						_movie.DeleteActor(obj.name);
					end	
					ParaScene.Delete(obj);
				else
					autotips.AddMessageTips("场景中只剩下一个角色,你不能删除它.");
				end
			else
				ParaScene.Delete(obj);
			end
			
		elseif(nServerState == 1) then
			-- this is a server. 
			if(obj:IsOPC()==false) then
				server.BroadcastObjectDelete(obj);
			else
				-- TODO: kick out the given user.
			end	
		elseif(nServerState == 2) then
			-- this is a client. 
			if(obj:IsOPC()==false) then
				client.RequestObjectDelete(obj);
			else
				autotips.AddMessageTips("你不能删除其他玩家");		
			end	
		end	
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil and obj_params~=nil and not obj_params.IsCharacter) then
				local history = Map3DSystem.obj.GetHistory();
				local time = history.creations:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author, obj_params = obj_params};
				commonlib.partialcopy(new_msg, msg);
				new_msg.obj=nil;
				history.creations:AutoAppendKey(time+1, new_msg, true);
				-- log
				--log("History: "..author.." deleted "..tostring(obj_params.AssetFile).."\n")
			end	
		end	
		
	elseif(msg.type == msg_def.OBJ_DeselectObject) then
		----------------------------------------------
		-- deselect object
		----------------------------------------------
		local obj = Map3DSystem.obj.GetObject("selection");
		if(obj and obj:IsValid()) then
			obj:SetField("showboundingbox", false);
		end
		
		Map3DSystem.obj.SetObjectParams(nil, "selection");
		-- clear any selection	in group or 0
		ParaSelection.ClearGroup(msg.group or 0); 
		
		-- remove head on text from old character
		if(Map3DSystem.LastSelectedCharacterName~=nil) then
			local lastplayer = ParaScene.GetCharacter(Map3DSystem.LastSelectedCharacterName);
			if(lastplayer:IsValid() and 
				(lastplayer:IsOPC()==false) and (lastplayer:GetDynamicField("AlwaysShowHeadOnText", false)==false))then
				-- remove head on text
				Map3DSystem.ShowHeadOnDisplay(false, lastplayer);
				Map3DSystem.LastSelectedCharacterName = nil;
			end
		end
		
		-- play sound
		if(SystemInfo.GetField("name") == "Taurus") then -- for taurus only
			ParaAudio.PlayUISound("Btn7");
		end
		
		EndFireMissile();
		
	elseif(msg.type == msg_def.OBJ_SelectObject) then
		----------------------------------------------
		-- select as the current object
		----------------------------------------------
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj~=nil and obj:IsValid()) then
			if(Map3DSystem~=nil and Map3DSystem.PushState~=nil) then
				Map3DSystem.PushState({name = "SelectObject", OnEscKey = "Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject, obj = nil});"});
				autotips.AddMessageTips("按Esc键取消选择")
			end
			---------------------------------------
			-- select the current object
			---------------------------------------
			ParaSelection.AddObject(obj, msg.group or 0); -- add object to selection group 0
			
			Map3DSystem.obj.SetObjectParams(ObjEditor.GetObjectParams(obj), "selection")
			
			local player = ParaScene.GetObject("<player>");
			local fromX, fromY, fromZ = player:GetPosition();
			fromY = fromY+1.0;
			local toX, toY, toZ = obj:GetViewCenter();
			if(msg.effect == nil) then
				-- using selection group effect. 
			elseif(msg.effect == "missile") then
				-- Fire a missile from the current player to the picked object.
				StartFireMissile();
			elseif(msg.effect == "boundingbox") then
				-- TODO: just display its bounding box.
				obj:SetField("showboundingbox", true);
			end	
			
			---------------------------------------
			-- For different object selected
			---------------------------------------
			if(obj:IsCharacter())then
				-- show text on the head of the selected character, and remove text from previously selected model.
				if(obj.name~=Map3DSystem.LastSelectedCharacterName) then
					-- remove arrow from old
					if(Map3DSystem.LastSelectedCharacterName~=nil and Map3DSystem.LastSelectedCharacterName~="") then
						local lastplayer = ParaScene.GetCharacter(Map3DSystem.LastSelectedCharacterName);
						if(lastplayer:IsValid() and
							(lastplayer:IsOPC()==false) and (lastplayer:GetDynamicField("AlwaysShowHeadOnText", false)==false))then
							-- remove text from lastplayer
							Map3DSystem.ShowHeadOnDisplay(false, lastplayer);
							Map3DSystem.LastSelectedCharacterName = nil;
						end
					end
					-- attach to new one
					Map3DSystem.LastSelectedCharacterName = obj.name;
					
					if(Map3DSystem.LastSelectedCharacterName and Map3DSystem.LastSelectedCharacterName~="") then
						-- show text on obj
						if(obj:GetDynamicField("AlwaysShowHeadOnText", false)) then
							Map3DSystem.ShowHeadOnDisplay(true, obj);
						else
							Map3DSystem.ShowHeadOnDisplay(true, obj, Map3DSystem.GetHeadOnText(obj));
						end
					end
				end

				-- play sound
				if(commonlib.getfield("System.options.version") == "teen") then
					ParaAudio.PlayUISound("Click_teen");
				else
					ParaAudio.PlayUISound("Btn5");
				end
			else
				-- play sound
				ParaAudio.PlayUISound("Btn1");
				
				-- face the current player to the target. 
				Map3DSystem.Animation.SendMeMessage({type = msg_def.ANIMATION_Character, animationName = "SelectObject",facingTarget = {x=toX, y=toY, z=toZ},});
			end
		end
		
	elseif(msg.type == msg_def.OBJ_SaveCharacter) then
		-------------------------------------------------
		-- save a character attribute to local database
		-------------------------------------------------
		local obj = Map3DSystem.obj.GetObjectInMsg(msg);
		if(obj~=nil and obj:IsValid()) then
			if(obj:IsPersistent())then
				obj:CallField("Save");
				if(not msg.silent) then
					autotips.AddMessageTips("角色被成功保存");
				end	
			else
				if(not msg.silent) then
					autotips.AddMessageTips("我不属于这个世界，你不能保存我");
				end	
			end
		end
	elseif(msg.type == msg_def.OBJ_SwitchObject) then
		local char = ObjEditor.GetObjectByParams(msg.toObjectParam);
		local fromChar = ObjEditor.GetObjectByParams(msg.fromObjectParam);
		if(char ~= nil and char:IsValid() == true) then
			ParaCamera.FollowObject(char);
		end
	elseif(msg.type == msg_def.OBJ_PickObject) then	
		--------------------------------------------------
		-- pick a given type of object using a filter
		--------------------------------------------------
		Map3DSystem.PickObject(msg.filter, msg.callbackFunc);
	end
end

function Map3DSystem.OnMessage_SCENE(window, msg)
	local msg_def = Map3DSystem.msg;
	if(msg.type == msg_def.SCENE_SAVE) then	
		--------------------------------------------------
		-- save current scene
		--------------------------------------------------
		if(not Map3DSystem.User.HasRight("Save"))then
			_guihelper.MessageBox("对不起, 您没有权限保存这个世界.");
			return 
		end
		-- save to database
		Map3DSystem.world:SaveWorldToDB();
		
		if(msg and msg.bQuickSave) then
			-- save only changed content
			-- save others
			if( ParaTerrain.IsModified() ) then
				ParaTerrain.SaveTerrain(true,true);
				local player = ParaScene.GetObject("<player>");
				
				if(player:IsValid()==true) then
					local x,y,z = player:GetPosition();
					local OnloadScript = ParaTerrain.GetTerrainOnloadScript(x,z);
					autotips.AddMessageTips(string.format("场景被保存到: %s", OnloadScript));
				else	
					autotips.AddMessageTips("场景被存盘");
				end
			else
				autotips.AddMessageTips("场景没有被更改过");	
			end
		else
			-- save all within 500 meters. 
			-- save everything
			ParaScene.SetModified(true);
			local x,y,z = ParaScene.GetPlayer():GetPosition();
			
			if(msg.radius) then	
				local radius = msg.radius;
				-- save everything within 500 meters radius from the current character
				ParaTerrain.SetContentModified(x,z, true, 65535);
				ParaTerrain.SetContentModified(x+radius,z+radius, true, 65535);
				ParaTerrain.SetContentModified(x+radius,z-radius, true, 65535);
				ParaTerrain.SetContentModified(x-radius,z+radius, true, 65535);
				ParaTerrain.SetContentModified(x-radius,z-radius, true, 65535);
			else
				-- this allows us to quickly mark all terrain content as modified before performing a save all operation. 
				ParaTerrain.SetAllLoadedModified(true, 65535);
			end	
			ParaTerrain.SaveTerrain(true,true);
			
			if(not msg.bSkipCharacter) then
				local nCount = ParaScene.SaveAllCharacters();
				autotips.AddMessageTips(string.format("共有%d个已加载的人物被保存，地形、地表、物体等都被保存了。",nCount));
			end
		end
	end
end


-- scene:object window handler
function Map3DSystem.OnObjectMessage(window, msg)
	local msg_def = Map3DSystem.msg;
	if(msg.type >= msg_def.OBJ_BEGIN and msg.type <= msg_def.OBJ_END) then
		Map3DSystem.OnMessage_OBJ(window, msg);
	elseif(msg.type >= msg_def.SCENE_BEGIN and msg.type <= msg_def.SCENE_END) then	
		Map3DSystem.OnMessage_SCENE(window, msg);
	end
end

