--[[
Title: mouse event for creator
Author(s): LiXizhi
Date: 2010/2/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/EventHandler_Mouse.lua");
local EventHandler = commonlib.gettable("MyCompany.Aries.Creator.EventHandler")
EventHandler.Hook();
EventHandler.UnHook();
-------------------------------------------------------
]]

-- create class
local EventHandler = commonlib.gettable("MyCompany.Aries.Creator.EventHandler")
local DesktopMode = commonlib.gettable("System.UI.DesktopMode")

-- whether we will enable object editing. 
EventHandler.is_object_edit_enabled = true;

-- set whether we will enable object editing. 
function EventHandler.EnableObjectEdit(bEnable)
	EventHandler.is_object_edit_enabled = bEnable;
	
	if(bEnable) then
		DesktopMode.CanSelectModel = true;
	else
		DesktopMode.CanSelectModel = false;
		ParaSelection.ClearGroup(1);
	end	
end

-- set whether the game world is modified or not
function EventHandler.Hook()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	local o = {hookType = hookType, 		 
		hookName = "AriesCreator_m_down_hook", appName = "input", wndName = "mouse_down"}
			o.callback = EventHandler.OnMouseDown;
	CommonCtrl.os.hook.SetWindowsHook(o);
	o = {hookType = hookType, 		 
		hookName = "AriesCreator_m_move_hook", appName = "input", wndName = "mouse_move"}
			o.callback = EventHandler.OnMouseMove;
	CommonCtrl.os.hook.SetWindowsHook(o);
	o = {hookType = hookType, 		 
		hookName = "AriesCreator_m_up_hook", appName = "input", wndName = "mouse_up"}
			o.callback = EventHandler.OnMouseUp;
	CommonCtrl.os.hook.SetWindowsHook(o);
	o = {hookType = hookType, 		 
		hookName = "AriesCreator_Obj_Hook", appName = "scene", wndName = "object"}
			o.callback = EventHandler.OnObjMessage;
	CommonCtrl.os.hook.SetWindowsHook(o);
end

function EventHandler.UnHook()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "AriesCreator_m_down_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "AriesCreator_m_move_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "AriesCreator_m_up_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "AriesCreator_Obj_Hook", hookType = hookType});
end

-- whenever an object message is sent
function EventHandler.OnObjMessage(nCode, appName, msg)
	local self = EventHandler;
	-- return the nCode to be passed to the next hook procedure in the hook chain. 
	-- in most cases, if nCode is nil, the hook procedure should do nothing. 
	if(nCode==nil) then return end
	
	if(EventHandler.is_object_edit_enabled) then
		-- force selection to group 1, since group 0 will not be visualized. 
		if(msg.type == Map3DSystem.msg.OBJ_SelectObject) then
			local obj = Map3DSystem.obj.GetObjectInMsg(msg);
			if(not obj or obj:equals(ParaScene.GetPlayer())) then
				-- selection of the main player is not permitted. 
				return;
			end
			msg.group = 1;
			if(obj:GetSelectGroupIndex() == 1) then
				-- if the user select the same object twice, we will start a moving operation on it. This behavior mimics that of the home land by leio. 
				if(obj:IsCharacter()) then
					-- if character is not OPC, player, or any other special objects, we will allow moving it. 
					if(not obj:GetAttributeObject():GetDynamicField("IsOPC", false)) then
						local obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg);
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = obj_params});
					end
				else
					Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = Map3DSystem.obj.GetObjectParamsInMsg(msg)});
				end	
				return;
			end
		elseif(msg.type == Map3DSystem.msg.OBJ_DeselectObject) then
			msg.group = 1;
		end
	end	
	return nCode
end

function EventHandler.OnMouseDown(nCode, appName, msg)
	local self = EventHandler;
	-- return the nCode to be passed to the next hook procedure in the hook chain. 
	-- in most cases, if nCode is nil, the hook procedure should do nothing. 
	if(nCode==nil) then return end
	
	return nCode
end

function EventHandler.OnMouseMove(nCode, appName, msg)
	local self = EventHandler;
	-- return the nCode to be passed to the next hook procedure in the hook chain. 
	-- in most cases, if nCode is nil, the hook procedure should do nothing. 
	if(nCode==nil) then return end
	
	return nCode
end

function EventHandler.OnMouseUp(nCode, appName, msg)
	local self = EventHandler;
	-- return the nCode to be passed to the next hook procedure in the hook chain. 
	-- in most cases, if nCode is nil, the hook procedure should do nothing. 
	if(nCode==nil) then return end
	
	return nCode
end