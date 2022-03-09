--[[
Title: all Macros 
Author(s): LiXizhi
Date: 2021/1/2
Desc: Macros are sequences of key and mouse text command that can be replayed in a command block or 
by calling GameLogic.Macros:Play(text). 

## What are good macros?
Macros are almost independent of screen resolution. However, it is good practice to click in the center of a scene block, 
and do not click around the edge of the scene, because the viewport aspect ratio may be different on the user's computer
and the click location may not be seen on it. Always clicking around the center of the scene to ensure valid mouse clicks on all aspect ratios. 
Also, remove redundant steps like frequently moving the player or changing camera view, because they will generate unnecessary
macro commands. 

## Interactive mode
One can record macro in Interactive mode by "/macro record -i" command.  This will generate additional [XXX]trigger command.
These trigger commands will ignore previous Idle(wait) command. Once played, trigger commands require the user to 
perform the same mouse or key actions in order to continue playing the next macro. 

Interactive mode is usually used as a tutorial for teaching users. 
In this mode, it is good practice to manually edit the triggers in a text editor and inject "Tip" or "Broadcast" commands. 
The Tip command will just display some comment text at the left top corner of the screen. 
The Broadcast command can /sendevent to the world, so that external code, like in a code block, can know the progress of the playing macros. 
This enables us to add more visual or audio effects in external code, while macros are being played. 

## Play Macro Controller
If the world is not readonly, the play macro controller will display a progress bar and a stop button. 
- `SetPlaySpeed(1.25)` : change the playback speed at runtime.
- `SetAutoPlay(true)` : play triggers through
- `SetHelpLevel(0)`: -1 to display key and mouse tips, 0 to disable mouse tips, 1 (default) to show all possible tips

Following code is good for playing the sequence as a movie
```
SetHelpLevel(-1)
SetAutoPlay(true)
SetPlaySpeed(1.25)
```
Following code is default

```
SetHelpLevel(1)
SetAutoPlay(false)
SetPlaySpeed(1)
```

## Macro Lists
```
Idle(500)
Wait(5000)
CameraMove(8,0.54347,0.18799)
CameraLookat(19980.29883,-126.59001,19998.52929)
PlayerMove(19181,5,19198,0.23781)
SceneClickTrigger("shift+right",-0.19781,0.07273)
SceneClick("shift+right",-0.19781,0.07273)
SceneDragTrigger("ctrl+left",-0.35925,0.23271,-0.05236,0.23562)
SceneDrag("ctrl+left",-0.35925,0.23271,-0.05236,0.23562)

SetPlaySpeed(1.25)
SetAutoPlay(true)
SetHelpLevel(0)

loadtemplate("aaa.bmax")
loadtemplate("abc.bmax", "-r")
tip("some text")
voice("text to speech")
playsound("1.mp3")
text("bottom line big text", 5000)
broadcast("globalGameEvent")
ShowWindow(false)
```

## How to make UI control recordable?
In mcml v1 or v2, recordable button(like input/div) should have "uiname" attribute. 
aries:window close button attribute name is "uiname_onclose".
editbox like (input text) should have both "uiname" and "onchange" attribute. You can assign a dummy function to "onchange", but it needs one. 

## How to record scene event (both key and mouse)?
We can add macros in SceneContext's handleMouseEvent() and handleKeyEvent() method. 
Since all scene contexts in paracraft are derived from BaseContext, we did above in BaseContext. 


Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
if(GameLogic.Macros:IsRecording()) then
	GameLogic.Macros:AddMacro("PlayerMove", x, y, z);
end
GameLogic.Macros:Play(text)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macro.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroVoice.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroControl.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroKeys.lua");
NPL.load("(gl)script/ide/SliderBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Screen = commonlib.gettable("System.Windows.Screen");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Application = commonlib.gettable("System.Windows.Application");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local Screen = commonlib.gettable("System.Windows.Screen");
local KeyFrameCtrl = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFrameCtrl");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local pe_mc_slot = commonlib.gettable("MyCompany.Aries.Game.mcml.pe_mc_slot");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");

local lastPlayerPos = {pos = {x=0, y=0, z=0}, facing=0, recorded=false};
local lastCameraPos = {camobjDist=10, LiftupAngle=0, CameraRotY=0, recorded = false, lookatX=0, lookatY = 0, lookatZ = 0};
local startTime = 0;
local idleStartTime = 0;
local pause = {};
local end_preplaytext_index = 0
local has_playtext = false

local isInited;
function Macros:Init()
	if(isInited) then
		return true;
	end
	isInited = true;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroIdle.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroTip.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayerMove.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroButtonClick.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroSceneClick.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroKeyPress.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroEditBox.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroSliderBar.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroKeyFrameCtrl.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroMCSlot.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroDropdownListbox.lua");
	-- TODO: add more here
end

function Macros:IsRecording()
	return self.isRecording;
end

function Macros:GetElapsedTime()
	return commonlib.TimerManager.GetCurrentTime() - startTime;
end

local originalCopyTextToClipboard = ParaMisc.CopyTextToClipboard;

local function TrackedCopyTextToClipboard(text)
	Macros.lastCopyTextToClipboard = text;
	originalCopyTextToClipboard(text);
end

function Macros:BeginRecord()
	GameLogic.options:SetClickToContinue(false);
	Macros.lastCopyTextToClipboard = nil;
	ParaMisc.CopyTextToClipboard = TrackedCopyTextToClipboard
	self:Init()
	self.isRecording = true;
	self.macros = {};
	
	self:ResetLastCameraParams()

	startTime = commonlib.TimerManager.GetCurrentTime();
	idleStartTime = startTime;

	local player = EntityManager.GetPlayer();
	local x, y, z;
	if(player) then
		x, y, z = player:GetBlockPos();
		lastPlayerPos.pos = {x=x, y=y, z=z}
		lastPlayerPos.facing = player:GetFacing();
		lastPlayerPos.recorded = false;
	end
	lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = ParaCamera.GetEyePos();
	lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ =  0,0,0;
	lastCameraPos.recorded = false;

	commonlib.__onuievent__ = Macros.OnGUIEvent;
	System.Windows.Window.__onuievent__ = Macros.OnWindowGUIEvent;
	CommonCtrl.SliderBar.__onuievent__ = Macros.OnSliderbarEvent;
	CommonCtrl.dropdownlistbox.__onuievent__ = Macros.OnDropdownListboxEvent;
	KeyFrameCtrl.__onuievent__ = Macros.OnKeyFrameCtrlEvent;

	self.tickTimer = self.tickTimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnTimer();
	end})
	self.tickTimer:Change(500, 500);
	GameLogic.GetFilters():apply_filters("Macro_BeginRecord");

	Macros:AddMacro("SetMacroOrigin", x, y, z)
end

local ignoreBtnList = {
	["MacroRecorder.Stop"] = true,
	["MacroRecorder.AddSubTitle"] = true,
	["_click_to_continue_delay_"] = true,
	["_g_GlobalDragCanvas"] = true,
	["TouchMiniKeyboard"] = true,
	["TouchMiniRightKeyboard"] = true,
	["TouchVirtualKeyboardIcon"] = true,
	["TouchVirtualKeyboard"] = true,
}

local function IsRecordableUIObject(obj, name)
	name = name or obj.name
	-- name should be at least 5 letters, and not mcml v1's default instance name like 1/2/3/4
	if(name and name~="" and #name >= 5 and not name:match("^%d+")) then
		if(not obj:GetAttributeObject():GetDynamicField("isWindow", false)) then
			return true;
		end
	end
end

-- called whenever window GUI event is received
function Macros.OnWindowGUIEvent(window, event)
	if(event:isAccepted()) then
		local event_type = event:GetType()
		if(event_type == "mouseReleaseEvent") then
			if(Application.lastMouseReceiver) then
				local name = Application.lastMouseReceiver:GetUIName(true)
				if(name and not ignoreBtnList[name]) then
					local obj = Application.GetUIObject(name);
					if(obj) then
						local x, y, width, height = obj:GetAbsPosition()
						local controlName = Application.lastMouseReceiver.Name;
						if(controlName == "TextControl") then
							local textCtrl = Application.lastMouseReceiver
							local curPos = textCtrl:CursorPos()
							Macros:AddMacro("WindowTextControlClick", name, event:button(), event.x - x, event.y - y, curPos.line, curPos.pos)
						else
							Macros:AddMacro("WindowClick", name, event:button(), event.x - x, event.y - y)
						end
					end
				end
			end
		elseif(event_type == "keyPressEvent") then
			local focusCtrl = window:focusWidget()
			if(focusCtrl) then
				local name = focusCtrl:GetUIName(true);
				if(name and not ignoreBtnList[name]) then
					if(not event:IsShiftCtrlAltKey()) then
						if(event:IsKeySequence("Paste")) then
							local text = ParaMisc.GetTextFromClipboard();
							if(Macros.lastCopyTextToClipboard ~= text) then
								-- tricky: if we are pasting from external apps, we need to save the clipboard content
								Macros:AddMacro("SetClipboard", text);
								if(Macros.IsInteractiveMode()) then
									-- also ignore the Ctrl+V trigger, if pasting from external app
									Macros.SetInteractiveMode(false)
									Macros:AddMacro("WindowKeyPress", name, Macros.GetButtonTextFromKeyEvent(event))
									Macros.SetInteractiveMode(true)
									return
								end
							end
						end
						Macros:AddMacro("WindowKeyPress", name, Macros.GetButtonTextFromKeyEvent(event))
					end
				end
			end
		elseif(event_type == "inputMethodEvent") then
			local focusCtrl = window:focusWidget()
			if(focusCtrl) then
				local name = focusCtrl:GetUIName(true);
				if(name and not ignoreBtnList[name]) then
					Macros:AddMacro("WindowInputMethod", name, event:commitString())
				end
			end
		end
	end
end

-- only for CommonCtrl.OnDropdownListboxEvent exclusively
function Macros.OnDropdownListboxEvent(dropdownCtl, eventName, dx, dy)
	local uiname = dropdownCtl.uiname;
	if(uiname) then
		if(eventName == "OnClickDropDownButton") then
			Macros:AddMacro("DropdownClickDropDownButton", uiname)
		elseif(eventName == "OnTextChange") then
			Macros:AddMacro("DropdownTextChange", uiname, dropdownCtl:GetValue())
		elseif(eventName == "OnMouseUpListBoxCont") then
			Macros:AddMacro("DropdownListBoxCont", uiname, dropdownCtl:GetValue())
		elseif(eventName == "OnSelectListBox") then
			Macros:AddMacro("DropdownSelect", uiname, dropdownCtl:GetValue())
		elseif(eventName == "OnMouseUpClose") then
			Macros:AddMacro("DropdownMouseUpClose", uiname)
		end
	end
end

-- only for CommonCtrl.SliderBar exclusively
function Macros.OnSliderbarEvent(sliderBar, eventName)
	local uiname = sliderBar.uiname;
	if(uiname) then
		if(eventName == "OnClickButton") then
			if(mouse_button == "right") then
				Macros:AddMacro("SliderBarClickButton", uiname, mouse_button)
			end
		elseif(eventName == "OnMouseUp") then
			if(sliderBar.value) then
				Macros:AddMacro("SliderBarMouseUp", uiname, sliderBar.value)
			end
		elseif(eventName == "OnMouseWheel") then
			Macros:AddMacro("SliderBarMouseWheel", uiname, mouse_wheel)
		end
	end
end

-- only for KeyFrameCtrl in movie block
function Macros.OnKeyFrameCtrlEvent(ctrl, eventName, p1, p2)
	local uiname = ctrl.uiname;
	if(uiname) then
		if(eventName == "ClickKeyFrame") then
			-- p1, p2: time, time_index
			Macros:AddMacro("KeyFrameCtrlClick", uiname, p1, mouse_button)
		elseif(eventName == "RemoveKeyFrame") then
			-- p1, p2: time, time_index
			Macros:AddMacro("KeyFrameCtrlRemove", uiname, p1, p2)
		elseif(eventName == "MoveKeyFrame") then
			-- p1, p2: new_time, begin_shift_time
			Macros:AddMacro("KeyFrameCtrlMove", uiname, p1, p2)
		elseif(eventName == "ShiftKeyFrame") then
			-- p1, p2: begin_shift_time, offset_time
			Macros:AddMacro("KeyFrameCtrlShift", uiname, p1, p2)
		elseif(eventName == "CopyKeyFrame") then
			-- p1, p2: new_time, shift_begin_time
			Macros:AddMacro("KeyFrameCtrlCopy", uiname, p1, p2)
		elseif(eventName == "ClickTimeLine") then
			-- p1: time
			Macros:AddMacro("KeyFrameCtrlClickTimeLine", uiname, p1)
		end
	end
end

-- called whenever GUI event is received from c++ engine. 
function Macros.OnGUIEvent(obj, eventname, callInfo)
	if(not Macros:IsRecording()) then
		return
	end
	if(eventname == "onclick" or eventname == "onmouseup") then
		local name = obj.name or "";
		if(IsRecordableUIObject(obj, name)) then
			if(not ignoreBtnList[name]) then
				local eventName_;
				if(eventname == "onmouseup") then
					eventName_ = eventname;
				end
				Macros:AddMacro("ButtonClick", name, Macros.GetButtonTextFromKeyboard(mouse_button), eventName_)
			end
		else
			-- GameLogic.AddBBS("macros", format(L"警告：没有录制的宏点击事件:%s", name or ""), 4000, "255 0 0");
		end
	elseif(eventname == "onmodify" or eventname == "onkeyup") then
		local name = obj.name or "";
		if(IsRecordableUIObject(obj, name)) then
			if(not ignoreBtnList[name]) then
				if(eventname == "onmodify") then
					Macros:AddMacro("EditBox", name, obj.text)
				elseif(eventname == "onkeyup") then
					Macros:AddMacro("EditBoxKeyup", name, VirtualKeyToScaneCodeStr[virtual_key])
				end
			end
		else
			-- GameLogic.AddBBS("macros", format(L"警告：没有录制的文本输入框事件:%s", name or ""), 4000, "255 0 0");
		end
	elseif(eventname == "ondragend") then
		local name = obj.name or "";
		if(IsRecordableUIObject(obj, name)) then
			if(not ignoreBtnList[name]) then
				local x, y, width, height = obj:GetAbsPosition()
				Macros:AddMacro("ContainerDragEnd", name, mouse_x-x, mouse_y-y)
			end
		end
	elseif(eventname == "onmousewheel") then
		local name = obj.name or "";
		if(IsRecordableUIObject(obj, name)) then
			if(not ignoreBtnList[name]) then
				Macros:AddMacro("ContainerMouseWheel", name, mouse_wheel)
			end
		end
	elseif(eventname == "onmousedown") then
		local name = obj.name or "";
		if(name == "_g_GlobalDragCanvas") then
			-- tricky: this is for pe_mc_slot
			local mcmlNode = pe_mc_slot.GetNodeByMousePosition();
			if(mcmlNode) then
				local btn = mcmlNode:GetControl()
				if(btn) then
					local btn_name = btn.name
					if(IsRecordableUIObject(btn, btn_name)) then
						Macros:AddMacro("MCSlotDragTarget", btn_name, Macros.GetButtonTextFromKeyboard(mouse_button))
					end
				end
			end
		end
	end
end

-- macros that needs to sync camera and viewport settings
local cameraViewMacros = {
	["SceneClick"] = true,
	["SceneDrag"] = true,
	["ButtonClick"] = true,
	["SceneMouseMove"] = true,
	["NextKeyPressWithMouseMove"] = true,
}

function Macros:ClearIdleTime()
	idleStartTime = commonlib.TimerManager.GetCurrentTime();
	self:SetPauseTime(0);
end

-- @param text: macro command text or just macro function name
-- @param ...: additional input parameters to macro function name
function Macros:AddMacro(text, ...)
	if (self:IsPaused()) then 
		return 
	end 
	local args = {...}
	local argCount = select('#', ...);
	if(argCount > 0) then
		local params;
		-- skip nil values
		for i = argCount, 1, -1 do 
			if args[i] == nil then
				argCount = argCount - 1
			else
				break
			end
		end
		for i = 1, argCount do 
			local param = args[i];
			if(params) then
				param = param == nil and "nil" or commonlib.serialize_compact(param)
				params = params..",".. param;
			else
				params = commonlib.serialize_compact(param);
			end
		end 
		text = format("%s(%s)", text, params or "");
	else
		if(not text:match("%(")) then
			text = text.."()";
		end
	end
	if (self:IsPaused()) then self:Resume() end 
	local idleTime = commonlib.TimerManager.GetCurrentTime() - idleStartTime - self:GetPauseTime();
	self:SetPauseTime(0); 

	if(idleTime > 100) then
		idleStartTime = commonlib.TimerManager.GetCurrentTime();
		self:AddMacro("Idle", idleTime);
	end
	local name = text:match("^([^%(]+)");
	if(cameraViewMacros[name]) then
		self:CheckAddCameraView(true);
	end
	local macro = Macro:new():Init(text);
	if(macro:IsValid()) then
		if(self:IsRecording() and self:IsInteractiveMode() and macro:HasTrigger()) then
			local bCreateTrigger = true;
			if(macro.name:match("MouseWheel$")) then
				-- do not create mouse wheel trigger for connected ***MouseWheel event
				local lastMacro = self.macros[#self.macros];
				if(lastMacro and lastMacro.name:match("MouseWheel$")) then
					bCreateTrigger = false;
				end
			end
			if(bCreateTrigger) then
				local mTrigger = macro:CreateTriggerMacro();
				self.macros[#self.macros + 1] = mTrigger;

				-- tricky: swap WindowInputMethod and WindowKeyPressTrigger, so that trigger is always before input method
				if(mTrigger.name == "WindowKeyPressTrigger") then
					local lastMacro = self.macros[#self.macros - 1]
					local lastLastMacro = self.macros[#self.macros - 2];
					if(lastLastMacro and lastMacro.name == "Idle" and lastLastMacro.name == "WindowInputMethod") then
						local nCount = #self.macros;
						self.macros[nCount - 2], self.macros[nCount-1] = lastMacro, lastLastMacro;
						lastMacro = lastLastMacro;
					end
					if((lastMacro and lastMacro.name == "WindowInputMethod")) then
						local nCount = #self.macros;
						self.macros[nCount - 1], self.macros[nCount] = mTrigger, lastMacro;
					end
				end
			end
		end
		self.macros[#self.macros + 1] = macro;
		GameLogic.GetFilters():apply_filters("Macro_AddRecord", #self.macros);
	else
		GameLogic.AddBBS("Macro", format("Unknown macro: %s", text), 5000, "255 0 0");
	end
end

-- whether we paused recording or playing
function Macros:IsPaused()
	return pause.IsPaused;
end

function Macros:Pause()
	pause.IsPaused = true;
	pause.startPauseTime = commonlib.TimerManager.GetCurrentTime();
	pause.endPauseTime = nil;
	pause.pauseTime = 0;
	-- TODO: shall we add a black UI overlay?
end

function Macros:Resume()
	if (not pause.IsPaused) then return end
	pause.IsPaused = false;
	pause.endPauseTime = commonlib.TimerManager.GetCurrentTime();
	pause.pauseTime = pause.endPauseTime - pause.startPauseTime;
	if(self.isPlaying) then
		self:ResumePlayMacros()
	end
end

function Macros:GetPauseTime()
	return pause.pauseTime or 0;
end

function Macros:SetPauseTime(pauseTime)
	pause.pauseTime = pauseTime or 0;
end

local MaxNonVIPMacroAllowed = 3000;

function Macros:EndRecord()
	if(not self.isRecording) then
		return;
	end
	self.isRecording = false;
	ParaMisc.CopyTextToClipboard = originalCopyTextToClipboard
	commonlib.__onuievent__ = nil;
	System.Windows.Window.__onuievent__ = nil;
	CommonCtrl.SliderBar.__onuievent__ = nil;
	CommonCtrl.dropdownlistbox.__onuievent__ = nil;
	KeyFrameCtrl.__onuievent__ = nil;
	if(self.tickTimer) then
		self.tickTimer:Change();
	end
	if(self.macros) then
		local out = {};
		for _, m in ipairs(self.macros) do
			out[#out+1] = m:ToString();
		end
		out[#out+1] = "Broadcast(\"macroFinished\")";
		if(#out > MaxNonVIPMacroAllowed) then
			if(not GameLogic.IsVip()) then
				_guihelper.MessageBox(format(L"非会员用户只能录制%d个示教宏命令,你录制了%d。是否要开通会员?", MaxNonVIPMacroAllowed, #(self.macros)), function()
					-- TODO: 开通VIP

				end)
			end
		end
		local text = table.concat(out, "\n");
		ParaMisc.CopyTextToClipboard(text);
		GameLogic.AddBBS(nil, format(L"%d个示教宏命令已经复制到裁剪版", #(self.macros)), 5000, "0 255 0")
	end
	GameLogic.GetFilters():apply_filters("Macro_EndRecord");
end

function Macros:IsPlaying()
	return self.isPlaying;
end

local lastCamera = {camobjDist=8, LiftupAngle=0.4, CameraRotY=0}

-- @return {camobjDist=8, LiftupAngle=0.4, CameraRotY=0, lookatX, lookatY, lookatZ}
function Macros:GetLastCameraParams()
	return lastCamera;
end

function Macros:ResetLastCameraParams()
	local lastCamera = self:GetLastCameraParams()
	lastCamera.lookatX, lastCamera.lookatY, lastCamera.lookatZ = nil, nil, nil;
	lastCamera.camobjDist, lastCamera.LiftupAngle, lastCamera.CameraRotY = 8, 0.4, 0;
end

function Macros:LockInput()
	System.os.options.DisableInput(true);
end
function Macros:UnlockInput()
	System.os.options.DisableInput(false);
end

-- @param text: text lines of macros.
-- @return array of Macro objects
function Macros:LoadMacrosFromText(text)
	if(not text) then
		return
	end
	Macros:Init();
	local macros = {};
	local lineNumber = 0;

	local last_text_duration = 0;
	local last_total_idle = 0;
	local add_idle = false;

	for line in text:gmatch("([^\r\n]*)\r?\n?") do
		lineNumber = lineNumber + 1;
		line = line:gsub("^%s+", "")

		if (add_idle) then
			local name, params = line:match("(%w[%w%.]*)%((.*)%)");
			if (name == "text" and params) then
				local t = last_text_duration - last_total_idle;
				if (t > 0) then
					local m = Macro:new():Init(string.format("Idle(%d)", t + 200), lineNumber);
					if (m:IsValid()) then
						macros[#macros+1] = m;
						lineNumber = lineNumber + 1;
					end
				end
			elseif (name == "Idle" and params) then
				params = NPL.LoadTableFromString("{"..params.."}");
				local t = unpack(params);
				last_total_idle = last_total_idle + t;
			end
		end

		local m = Macro:new():Init(line, lineNumber);
		if(m:IsValid()) then
			macros[#macros+1] = m;
			if (m.name == "text" and m.params) then
				if (not add_idle) then
					add_idle = true;
				end
				last_total_idle = 0;
				local params = type(m.params) == "table" and m.params or commonlib.split(m.params,",")
				local text = params[1] or ""
				if (string.find(text, "\"", 1) == 1 and string.find(text, "\"", string.len(text)) == string.len(text)) then
					text = string.sub(text, 2, string.len(text) - 1);
				end
				if text ~= "" then
					self.text_lines[#macros+1] = 1
				end
				local voiceNarrator = params[4] or 10012;
				voiceNarrator = tonumber(voiceNarrator);
				if (text ~= "" and voiceNarrator ~= nil) then
					last_text_duration = (math.floor(commonlib.utf8.len(text) / 5) + 1.5) * 1000;
					local sound_name = "playtext" .. voiceNarrator;
					local md5_value = SoundManager:GetPlayTextMd5(text, voiceNarrator)
					local file_path = SoundManager:GetTempSoundFile(voiceNarrator, md5_value)
					if (file_path) then
						SoundManager:PlaySound(sound_name, file_path);
						last_text_duration = SoundManager:GetSoundDuration(sound_name, file_path) * 1000;
						SoundManager:StopSound(sound_name);
					end				
				end
			end
		end
	end
	return macros;
end



function Macros:HasUnplayedPreparedMode()
	return Macros.hasUnplayedPreparedMode;
end

-- @param cx, cy, cz: if nil, we will not play using absolute position. otherwise, we will play relatively. 
function Macros:PrepareDefaultPlayMode(cx, cy, cz, isAutoPlay, bNoHelp, nSpeed)
	Macros.hasUnplayedPreparedMode = true;
	Macros.SetPlayOrigin(cx, cy, cz)
    Macros.SetAutoPlay(isAutoPlay);
    Macros.SetHelpLevel(bNoHelp and 0 or 1);
    Macros.SetPlaySpeed(nSpeed or 1);
end
	

function Macros:PrepareInitialBuildState()
    GameLogic.RunCommand("/mode edit");
    GameLogic.RunCommand("/clearbag");
    GameLogic.RunCommand("/camerayaw 3.14");
	GameLogic.RunCommand("/hide info");
	GameLogic.RunCommand("/fps 0");
	GameLogic.options:SetFieldOfView()
	
    local player = GameLogic.EntityManager.GetPlayer()
    player:ToggleFly(false)
    lastPlayerX, lastPlayerY, lastPlayerZ = player:GetBlockPos();
    player:SetHandToolIndex(1);
    local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
    BuilderFramePage.OnChangeCategory(1, false)
    local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");
    CreatorDesktop.OnChangeTabview(1)
    CreatorDesktop.ShowNewPage(false)
    
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
	CodeBlockWindow:SetBigCodeWindowSize(false);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
	local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
	MovieClipController:ShowAllGUI(false);
	
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
    local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
    OpenAssetFileDialog.OnChangeCategory(2);
    
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
    local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
    CodeHelpWindow.OnChangeCategory(1)
    
    NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
    local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
    ChatEdit.LostFocus()

	local TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon")
	if TouchVirtualKeyboardIcon and TouchVirtualKeyboardIcon.GetSingleton then
		TouchVirtualKeyboardIcon = TouchVirtualKeyboardIcon.GetSingleton()
		if TouchVirtualKeyboardIcon then
			local keyboard = TouchVirtualKeyboardIcon:GetKeyBoard()
			if keyboard and keyboard:isVisible() then
				TouchVirtualKeyboardIcon:ShowKeyboard(false)
			end
		end
	end

end

-- @param text: text lines of macros. if nil, it will play from clipboard
-- @param maxPrepareTime: max number of seconds, if prepare downloading text-to-speech audio files if any. default to 3 seconds. 
function Macros:Play(text, speed, maxPrepareTime)
	Macros.hasUnplayedPreparedMode = false;
	text = text or ParaMisc.GetTextFromClipboard() or "";
	self.maxPrepareTime = maxPrepareTime or 3;
	self.text_lines = {}
	local macros = self:LoadMacrosFromText(text)
	self:PlayMacros(macros, 1, speed);
	self:InitPrePlaytextData()
	self:PreparePlayText(5)
end

function Macros:BeginPlay()
	self:EndRecord()
	self:Init();
	
	self:ResetLastCameraParams()

	self.isPlaying = true;
	pause.IsPaused = false;

	Macros.SetNextKeyPressWithMouseMove(nil, nil)
	MacroPlayer.ShowPage();
	self:LockInput()
	GameLogic.options:SetClickToContinue(false);

	GameLogic.GetFilters():add_filter("OnBeforeShowExitDialog", Macros.OnShowExitDialog);
	
	GameLogic.GetFilters():apply_filters("Macro_BeginPlay");
end



function Macros.OnShowExitDialog(p1)
	if(p1 == false) then
		return
	end
	if(Macros:IsPlaying()) then
		Macros:Pause()
		_guihelper.MessageBox(L"是否退出示教系统?", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				Macros:Stop();
			else
				Macros:Resume()
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		return false;
	end
	return p1;
end

-- peek next macro in execution. Usually used by Idle macro to merge with triggers
-- @param nOffset: nil or 1 or 2.  if 2, it will return the next's next macro. -1 tp return previous macro
function Macros:PeekNextMacro(nOffset)
	if(self.macros and self.curLine) then
		return self.macros[self.curLine + (nOffset or 1)];
	end
end

function Macros:GetLastMacro(nOffset)
	if(self.macros) then
		return self.macros[#(self.macros) + (nOffset or 0)];
	end
end

function Macros:PopMacro()
	if(self.macros) then
		self.macros[#(self.macros)] = nil;
	end
end

function Macros:GetMacroByIndex(index)
	if(self.macros) then
		return self.macros[index];
	end
end

-- @param fromIndex: if nil, default to 1
-- @return macro, index:   index of the next macro of name from fromIndex. return nil if not found
function Macros:FindNextMacro(name, fromIndex)
	fromIndex = fromIndex or 1;
	while(true) do
		local macro = self:GetMacroByIndex(fromIndex)
		if(macro) then
			if(macro.name == name) then
				
				return macro, fromIndex;
			end
		else
			break;
		end
		fromIndex = fromIndex + 1;
	end
end

function Macros:ResumePlayMacros()
	if(self.macros and self.curLine and self.isPlaying and self.needResumePlay) then
		self:PlayMacros(self.macros, self.curLine + 1)
	end
end

-- @param fromLine: optional
function Macros:PlayMacros(macros, fromLine, speed)
	fromLine = fromLine or 1
	if(fromLine == 1) then
		self:BeginPlay()
		if(speed) then
			Macros.SetPlaySpeed(speed);
		end
	end
	self.macros = macros;
	self.needResumePlay = false;
	local function play()
		while(true) do
			local m = macros[fromLine];
			if(m) then
				if Macros.IsTextManualPlay() and self.text_lines[fromLine] == 1 and Macros.IsAutoPlay() then
					self:Pause()
					MacroPlayer.ShowNextController(true)
					self.text_lines[fromLine] = 0
				end
				self.isPlaying = true;
				self.curLine = fromLine
				local isAsync = nil;
				MacroPlayer.Focus();
				GameLogic.GetFilters():apply_filters("Macro_PlayMacro", fromLine, macros);
				m:Run(function()
					if(isAsync) then
						if(self.isPlaying) then
							if(not self:IsPaused()) then
								self:PlayMacros(macros, fromLine+1)
							else
								self.needResumePlay = true;
							end
						end
					else
						isAsync = false;
					end
				end)

				if m.name == "text" then
					self:PreparePlayText()
				end

				if(isAsync == false) then
					fromLine = fromLine + 1;
				else
					isAsync = true;
					break;
				end
			else
				self:Stop()
				break;
			end
		end
	end

	if (fromLine == 1) then
		self.firstTextPrepared = false;
		self.elapsedPrepareTime = 0;
		if(self.checkText) then
			self.checkText:Change();
		end
		self.checkText = commonlib.Timer:new({callbackFunc = function(timer)
			self.elapsedPrepareTime = self.elapsedPrepareTime + 1;
			if (not has_playtext or self.elapsedPrepareTime >= self.maxPrepareTime or self.firstTextPrepared) then
				self.checkText:Change();
				play();
			end
		end});
		self.checkText:Change(1, 1000);
	else
		play();
	end
end


function Macros:Stop()
	if(self.checkText) then
		self.checkText:Change();
	end
	if(self:IsRecording()) then
		self:EndRecord()
	elseif(self:IsPlaying()) then
		self.isPlaying = false;
		self:UnlockInput();

		local player = EntityManager.GetPlayer();
		local lookX, lookY, lookZ = ParaCamera.GetLookAtPos()

		player:SetFocus();
		local obj = player:GetInnerObject();
		if(obj) then
			if(obj.ToCharacter) then
				obj:ToCharacter():SetFocus();

				if(not GameLogic.IsReadOnly()) then
					-- tricky restore player position according to previous camera lookat position. 
					commonlib.TimerManager.SetTimeout(function()  
						local lookX1, lookY1, lookZ1 = ParaCamera.GetLookAtPos()
						local x, y, z = obj:GetPosition()
						local lookatHeight = lookY1 - y;
						player:SetPosition(lookX, lookY-lookatHeight, lookZ)
					end, 1)
				end
			end
		end

		GameLogic.GetFilters():apply_filters("Macro_EndPlay");
	end
end

-- only record when the user has moved and been still for at least 500 ms. 
function Macros:Tick_RecordPlayerMove()
	local player = EntityManager.GetPlayer();
	local focusEntity = EntityManager.GetFocus();
	if(player and focusEntity == player) then
		-- for scene camera. 
		local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
		local diff = math.abs(lastCameraPos.camobjDist - camobjDist) + math.abs(lastCameraPos.LiftupAngle - LiftupAngle) + math.abs(lastCameraPos.CameraRotY - CameraRotY);
		if(diff ~= 0) then
			lastCameraPos.recorded = false;
			lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = camobjDist, LiftupAngle, CameraRotY
		elseif(diff == 0 and not lastCameraPos.recorded) then
			lastCameraPos.recorded = true;
			self:AddMacro("CameraMove", camobjDist, LiftupAngle, CameraRotY);
		end

		-- for player position changes
		local x, y, z = player:GetBlockPos();	
		local diff = math.abs(lastPlayerPos.pos.x - x) + math.abs(lastPlayerPos.pos.y - y) + math.abs(lastPlayerPos.pos.z - z);
		if(diff ~= 0) then
			lastPlayerPos.recorded = false;
			lastPlayerPos.pos.x, lastPlayerPos.pos.y, lastPlayerPos.pos.z = x, y, z
		elseif(diff == 0 and not lastPlayerPos.recorded) then
			lastPlayerPos.recorded = true;
			local facing = player:GetFacing();
			self:AddMacro("PlayerMove", x, y, z, facing);

			--local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
			--lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ = lookatX, lookatY, lookatZ
			--self:AddMacro("CameraLookat", lookatX, lookatY, lookatZ);
		end
	elseif(focusEntity and focusEntity:isa(EntityManager.EntityCamera) and not focusEntity:IsControlledExternally()) then
		if(MovieManager:HasActiveCameraPlaying()) then
			-- do not record when movie clip is playing with a camera. 
		else
			self:CheckAddCameraView();	
		end
	end
end

local currentViewportParams = {fov=1.5, aspectRatio=1, screenWidth=800, screenHeight=600};

-- it is usually called before handling user event, just in case the user changed viewport during processing. 
function Macros:SaveViewportParams()
	local viewport = ViewportManager:GetSceneViewport();
	currentViewportParams.screenWidth, currentViewportParams.screenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();
	currentViewportParams.fov = Cameras:GetCurrent():GetFieldOfView()
	currentViewportParams.aspectRatio = Cameras:GetCurrent():GetAspectRatio()
	currentViewportParams.saveTime = commonlib.TimerManager.GetCurrentTime();

	currentViewportParams.camobjDist, currentViewportParams.LiftupAngle, currentViewportParams.CameraRotY = ParaCamera.GetEyePos();
	currentViewportParams.lookatX, currentViewportParams.lookatY, currentViewportParams.lookatZ = ParaCamera.GetLookAtPos();
end

--@return {fov, aspectRatio, screenWidth, screenHeight}
function Macros:GetViewportParams()
	if(currentViewportParams.saveTime ~= commonlib.TimerManager.GetCurrentTime()) then
		self:SaveViewportParams();
	end
	return currentViewportParams;
end

-- only add camera lookat and positions if the current is different from last. 
-- this function is usually called automatically before any scene clicking macros. 
function Macros:CheckAddCameraView()
	local viewParams = self:GetViewportParams()
	local camobjDist, LiftupAngle, CameraRotY;
	local lookatX, lookatY, lookatZ;
	if(viewParams.saveTime == commonlib.TimerManager.GetCurrentTime()) then
		camobjDist, LiftupAngle, CameraRotY = viewParams.camobjDist, viewParams.LiftupAngle, viewParams.CameraRotY
		lookatX, lookatY, lookatZ = currentViewportParams.lookatX, currentViewportParams.lookatY, currentViewportParams.lookatZ; 
	else
		camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
		lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
	end

	local diff = math.abs(lastCameraPos.camobjDist - camobjDist) + math.abs(lastCameraPos.LiftupAngle - LiftupAngle) + math.abs(lastCameraPos.CameraRotY - CameraRotY);
	if(diff > 0.001 or not lastCameraPos.recorded) then
		lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = camobjDist, LiftupAngle, CameraRotY
		lastCameraPos.recorded = true;
		self:AddMacro("CameraMove", camobjDist, LiftupAngle, CameraRotY);
	end
	
	local diff = math.abs(lastCameraPos.lookatX - lookatX) + math.abs(lastCameraPos.lookatY - lookatY) + math.abs(lastCameraPos.lookatZ - lookatZ);
	if(diff > 0.001) then
		lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ = lookatX, lookatY, lookatZ
		self:AddMacro("CameraLookat", lookatX, lookatY, lookatZ);
	end
end

function Macros.AutoCompleteTrigger()
	MacroPlayer.AutoCompleteTrigger();
end

function Macros:OnTimer()
	if(self:IsRecording() and not self:IsPlaying()) then
		self:Tick_RecordPlayerMove()
	end
end

local lastMouseDownEvent = {x=0, y=0,};

function Macros:GetLastMousePressEvent()
	return lastMouseDownEvent;
end

function Macros:MarkMousePress(event)
	lastMouseDownEvent.x = event.x;
	lastMouseDownEvent.y = event.y;
	lastMouseDownEvent.mouse_button = event.mouse_button;
	lastMouseDownEvent.clickTime = commonlib.TimerManager.GetCurrentTime();
end

function Macros:InitPrePlaytextData()
	end_preplaytext_index = 0
	has_playtext = false
end

function Macros:PreparePlayText(prepare_nums)
	if self.macros == nil then
		return
	end

	prepare_nums = prepare_nums or 1
	if (prepare_nums == 1 and not has_playtext) or (end_preplaytext_index >= #self.macros) then
		return
	end

	local pre_count = 0
	for i = end_preplaytext_index + 1, #self.macros do
		local item = self.macros[i]
		if item then
			if item.name == "text" and item.params then
				local params = type(item.params) == "table" and item.params or commonlib.split(item.params,",")
				-- if there is audio.  
				if(params[4] ~= "-1" and params[4] ~= -1) then
					local text = params[1] or ""
					if (string.find(text, "\"", 1) == 1 and string.find(text, "\"", string.len(text)) == string.len(text)) then
						text = string.sub(text, 2, string.len(text) - 1);
					end
					if text ~= "" then
						SoundManager:PrepareText(text,  params[4], function(file_path)
							self.firstTextPrepared = true;
						end)
						pre_count = pre_count + 1
					end
				end
			end
			
			if pre_count >= prepare_nums then
				end_preplaytext_index = i
				break
			end
		end
	end

	if pre_count > 0 then
		has_playtext = true
	end
end

function Macros:GetLinesAsText()
	local out = {};
	for _, m in ipairs(self.macros) do
		local lineNo = m:GetLineNumber()
		while(lineNo > (#out + 1)) do
			out[#out+1] = "";
		end
		out[#out+1] = m:ToString();
	end
	local text = table.concat(out, "\n");
	return text or "";
end