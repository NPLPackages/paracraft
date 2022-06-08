--[[
Title: Macro Player
Author(s): LiXizhi
Date: 2021/1/4
Desc: Macro Player page

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
MacroPlayer.ShowPage();
MacroPlayer.ShowController(false);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local MacroPlayer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer"));
local page;
local TouchMiniKeyboard, TouchVirtualKeyboardIcon = nil, nil;
local TouchMiniRightKeyboard

MacroPlayer.TextData = {{}}
MacroPlayer.touch_scale = 1

function MacroPlayer.OnInit()
	page = document:GetPageCtrl();
	GameLogic.GetFilters():add_filter("Macro_EndPlay", MacroPlayer.OnEndPlay);
	GameLogic.GetFilters():add_filter("Macro_PlayMacro", MacroPlayer.OnPlayMacro);
	GameLogic.GetFilters():add_filter("sound_starts_playing", MacroPlayer.OnSoundStartsPlaying);
	MacroPlayer.isShowDebugWnd = false;

	if System.os.IsTouchMode() then
		MacroPlayer.touch_scale = 1.8
	end
end

function MacroPlayer.OnInitEnd()
	local obj = MacroPlayer.GetRootUIObject()
	if(obj) then
		-- local viewport = ViewportManager:GetSceneViewport()
		-- viewport:Connect("sizeChanged", MacroPlayer, MacroPlayer.OnViewportChange, "UniqueConnection");
		obj:SetScript("onsize", function()
			MacroPlayer.OnViewportChange();
		end)
	end

	local KeyInput = page:FindControl("KeyInput");
	if(KeyInput) then
		KeyInput:SetField("CanHaveFocus", true); 
		KeyInput:SetField("InputMethodEnabled", false); 
		KeyInput:SetScript("onkeydown", function()
			local event = KeyEvent:init("keyPressEvent")
			MacroPlayer.OnKeyDown(event)
		end);
		KeyInput:Focus();
	end
	MacroPlayer.HideAll()
	MacroPlayer.ShowDebugInfoWnd(false);
	local cursorClick = page:FindControl("cursorClick");
	if(cursorClick) then
		if not System.os.IsTouchMode() then
			cursorClick:SetScript("onmousewheel", function()
				MacroPlayer.OnMouseWheel()
			end);
		end
	end
	
	if(GameLogic.IsReadOnly()) then
		MacroPlayer.ShowController(false);
	end
end

function MacroPlayer.RefreshPage(dTime)
	if(page) then
		page:Refresh(dTime)
	end
end

function MacroPlayer.OnPageClosed()
	if(MacroPlayer.attachedWnd) then
		MacroPlayer.attachedWnd:CloseWindow();
		MacroPlayer.attachedWnd = nil;
	end
	if(MacroPlayer.attachedWindows) then
		for name, wnd in pairs(MacroPlayer.attachedWindows) do
			wnd:CloseWindow();
		end
		MacroPlayer.attachedWindows = nil;
	end
	if(page) then
		if(page.keyboardWnd) then
			page.keyboardWnd:Show(false);
			page.keyboardWnd = nil
		end
	end
	if(MacroPlayer.waitActionTimer) then
		MacroPlayer.waitActionTimer:Change();
	end
	if(MacroPlayer.animCursorTimer) then
		MacroPlayer.animCursorTimer:Change();
	end
	if(MacroPlayer.animKeyPressTimer) then
		MacroPlayer.animKeyPressTimer:Change();
	end
	if(MacroPlayer.animDragTimer) then
		MacroPlayer.animDragTimer:Change();
	end
	if(MacroPlayer.autoPlayTimer) then
		MacroPlayer.autoPlayTimer:Change();
	end
	if(MacroPlayer.textTimer) then
		MacroPlayer.textTimer:Change();
	end
	MacroPlayer.lastSavedTextPosition = nil;
	MacroPlayer.lastSavedTipPos = nil;

	GameLogic.RunCommand("/ggs user visible")
end

function MacroPlayer.OnViewportChange()
	if(page and MacroPlayer.triggerCallbackFunc) then
		MacroPlayer.RefreshPage(0);
		
		if(page and page.keyboardWnd) then
			page.keyboardWnd:Destroy();
			page.keyboardWnd = nil;
		end
		commonlib.TimerManager.SetTimeout(function()  
			if(MacroPlayer.triggerCallbackFunc) then
				local m = Macros:PeekNextMacro(0)
				if(m and m:IsTrigger()) then
					m:RunAgain()
				end
			end
		end, 300)
	end
end

-- @param duration: in seconds
function MacroPlayer.ShowPage()
	GameLogic.RunCommand("/ggs user hidden")
	local params = {
		url = "script/apps/Aries/Creator/Game/Macros/MacroPlayer.html", 
		name = "MacroPlayerTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1000,
		allowDrag = false,
		isTopLevel = true,
		isPinned = true,
		directPosition = true,
			align = "_fi",
			x = 0,
			y = 0,
			width = 0,
			height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		MacroPlayer.OnPageClosed();
		page = nil;
	end;
	if (System.os.IsTouchMode() or IsDevEnv or System.options.isDevMode) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
		TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
		TouchMiniKeyboard = TouchMiniKeyboard.GetSingleton();
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
		TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
		TouchVirtualKeyboardIcon = TouchVirtualKeyboardIcon.GetSingleton();

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniRightKeyboard.lua");
		TouchMiniRightKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniRightKeyboard");
		TouchMiniRightKeyboard = TouchMiniRightKeyboard.GetSingleton();
	end

	if System.options.isDevMode then
		-- local pro_mcml_node = page:GetNode("root")
		-- local pro_ui_object = ParaUI.GetUIObject(pro_mcml_node.uiobject_id)
		
		-- pro_ui_object:SetScript("onmousedown", function() MacroPlayer.OnMouseDown({type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0}) end);
		-- pro_ui_object:SetScript("onmouseup", function() MacroPlayer.OnMouseUp({type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0}) end);
		-- pro_ui_object:SetScript("onmousemove", function() MacroPlayer.OnMouseMove({type="WM_POINTERUPDATE", x=mouse_x, y=mouse_y, id=-1, time=0}) end);
	end

end

function MacroPlayer.HideAll(bSkipTips)
	MacroPlayer.expectedButton = nil;
	MacroPlayer.expectedKeyButton = nil;
	MacroPlayer.expectedDragButton = nil;
	MacroPlayer.expectedMouseWheelDelta = nil;
	MacroPlayer.expectedEditBoxText = nil;
	MacroPlayer.ShowCursor(false);
	MacroPlayer.ShowKeyPress(false);
	MacroPlayer.ShowDrag(false);
	if(not bSkipTips) then
		MacroPlayer.ShowTip()
		MacroPlayer.ShowText()
		MacroPlayer.ShowNextController(false)
	end
	MacroPlayer.ShowEditBox(false);
	MacroPlayer.ShowMouseWheel(false);
	MacroPlayer.ShowKeyboard(false);
	MacroPlayer.ShowBlackBg(false)
end

function MacroPlayer.ShowBlackBg(bShow)
	if MacroPlayer.blackTimer then
		MacroPlayer.blackTimer:Change()
		MacroPlayer.blackTimer = nil
	end
	local scene_back = ParaUI.GetUIObject("MacroPlayer.scene")
	if scene_back and scene_back:IsValid() then
		scene_back.visible = false
		if bShow then
			MacroPlayer.blackTimer = MacroPlayer.blackTimer or commonlib.Timer:new({callbackFunc = function(timer)
				scene_back.visible = true
			end})
			MacroPlayer.blackTimer:Change(5000);	
		end
	end
end

function MacroPlayer.OnPlayMacro(fromLine, macros)
	local progress = math.floor(fromLine / (#macros)*100 + 0.5);
	if(page) then
		page:SetValue("progress", progress);
	end
	if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
		TouchMiniKeyboard:UpdateIconVisible()
	end

	if System.os.IsTouchMode() then
		NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatEdit.lua");
		local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
		ChatEdit.SetUseIME(false)
	end

	return fromLine;
end

function MacroPlayer.OnEndPlay()
	MacroPlayer.CloseWindow();
	if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
		TouchMiniKeyboard:UpdateIconVisible()
		TouchMiniKeyboard:ClearAllKeyDown()
		TouchMiniKeyboard:SetTransparency(0.2, true);
		TouchMiniKeyboard:StopCtrlDrawAnim()
	end
end

function MacroPlayer.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function MacroPlayer.OnClickStop()
	GameLogic.Macros:Stop()
end

function MacroPlayer.OnClickNext()
	GameLogic.Macros:Resume()
	MacroPlayer.ShowNextController(false)
end

function MacroPlayer.InvokeTriggerCallback()
	local callback = MacroPlayer.triggerCallbackFunc;
	if(callback) then
		MacroPlayer.triggerCallbackFunc = nil;
		callback();
		MacroPlayer.AutoAdjustControlPosition()

		if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
			TouchMiniKeyboard:ClearAllKeyDown()
			TouchMiniKeyboard:StopCtrlDrawAnim()
		end
	end
end

MacroPlayer.TipStartTime = 0;
MacroPlayer.ShowTipTime = 5000;
if System.os.IsTouchMode() then
	MacroPlayer.ShowTipTime = 500
end
function MacroPlayer.ResetTipTime(nDeltaMilliSeconds)
	MacroPlayer.TipStartTime = commonlib.TimerManager.GetCurrentTime() + (nDeltaMilliSeconds or 0)
end

function MacroPlayer.SetTriggerCallback(callback)
	if(callback) then
		GameLogic.AddBBS("Macro", nil);
		if(Macros.IsShowButtonTip() and not Macros.IsAutoPlay()) then
			MacroPlayer.TipStartTime = commonlib.TimerManager.GetCurrentTime();
			MacroPlayer.waitActionTimer = MacroPlayer.waitActionTimer or commonlib.Timer:new({callbackFunc = function(timer)
				if(page and MacroPlayer.triggerCallbackFunc) then
					local elapsedTime = commonlib.TimerManager.GetCurrentTime() - MacroPlayer.TipStartTime;
					if(elapsedTime > MacroPlayer.ShowTipTime) then
						MacroPlayer.ShowMoreTips();
						MacroPlayer.TipStartTime = commonlib.TimerManager.GetCurrentTime() + MacroPlayer.ShowTipTime;
					end
				else
					timer:Change();
				end
			end})
			MacroPlayer.waitActionTimer:Change(33, 33);
		else
			if(MacroPlayer.waitActionTimer) then
				MacroPlayer.waitActionTimer:Change(nil);
			end
		end
	else
		if(MacroPlayer.waitActionTimer) then
			MacroPlayer.waitActionTimer:Change(nil);
		end
	end
	MacroPlayer.triggerCallbackFunc = callback;
	MacroPlayer.Focus();
end

-- called every MacroPlayer.ShowTipTime time, when user is not responding correctly
function MacroPlayer.ShowMoreTips()
	if(MacroPlayer.expectedKeyButton) then
		local count = TouchMiniKeyboard and TouchMiniKeyboard:ShowMacroTip(MacroPlayer.expectedKeyButton) or 0
		if count <= 0 then
			local mouseX, mouseY = GameLogic.Macros.GetNextKeyPressWithMouseMove()
			

			if(mouseX and mouseY) then
				-- key press at given scene location. 
				if System.os.IsTouchMode() then
					commonlib.TimerManager.SetTimeout(function()  
						MacroPlayer.AutoCompleteTrigger()
					end, 1000)
				end
			else
				local count = MacroPlayer.ShowKeyboard(true, MacroPlayer.expectedKeyButton);
				if(count and count > 1) then
					GameLogic.AddBBS("Macro", format(L"你需要同时按下%d个按键", count), 5000, "0 255 0");
					Macros.voice("你需要同时按下2个按键")
				end
			end
		end
	end

	if MacroPlayer.expectedButton then
		local count = TouchMiniKeyboard and TouchMiniKeyboard:ShowMacroTip(MacroPlayer.expectedButton) or 0
		if(count and count > 1) then
			GameLogic.AddBBS("Macro", format(L"你需要同时按下%d个按键", count), 5000, "0 255 0");
			Macros.voice("你需要同时按下2个按键")
		end
	end

	if(MacroPlayer.expectedDragButton) then
		Macros.voice("按住鼠标左键不要放手， 同时拖动鼠标到目标点")
		GameLogic.AddBBS("Macro", format(L"按住鼠标左键不要放手， 同时拖动鼠标到目标点", count), 5000, "0 255 0");
	end
end

local cursorTick = 0;
function MacroPlayer.AnimCursorBtn(bRestart)
	if(page) then
		local cursor = page:FindControl("cursorClick");
		if(MacroPlayer.isDragging) then
			local cursorBtn = page:FindControl("cursorBtn")
			cursorBtn.visible = false
		elseif(cursor and cursor.visible) then
			local cursorBtn = page:FindControl("cursorBtn")
			local x, y, width, height = cursor:GetAbsPosition();
			local scale = MacroPlayer.touch_scale
			cursorBtn.x = 12 * scale
			cursorBtn.y = 15 * scale

			x = x + 12;
			y = y + 15;
			
			local mouseX, mouseY = ParaUI.GetMousePosition();
			
			local totalTicks = 30;
			local stopTicks = 10;
			cursorTick = bRestart and 0 or (cursorTick + 1);
			local progress = (totalTicks - math.min(totalTicks, cursorTick)) / totalTicks;
			if(cursorTick >= (totalTicks+stopTicks)) then
				cursorTick = 0;
			end
			local diffDistance = math.sqrt((mouseX - x)^2 + (mouseY - y)^2)

			local maxDistance = 32
			if( diffDistance > maxDistance) then
				-- if too far away, we will begin from maxDistance
				progress = progress * (maxDistance / diffDistance);
			end

			if( diffDistance > 16 ) then
				cursorBtn.visible = true;
				cursorBtn.translationx = math.floor((mouseX - x) * progress + 0.5);
				cursorBtn.translationy = math.floor((mouseY - y) * progress + 0.5);
			else
				cursorBtn.visible = false;
				cursorBtn.translationx = 0;
				cursorBtn.translationy = 0;
				cursorTick = 0;
			end
			MacroPlayer.animCursorTimer = MacroPlayer.animCursorTimer or commonlib.Timer:new({callbackFunc = function(timer)
				if(Macros.IsShowButtonTip()) then
					MacroPlayer.AnimCursorBtn()
				end
			end})
			MacroPlayer.animCursorTimer:Change(30);
		end
	end
end

-- this is important to always focus to the key press control in case the user has clicked elsewhere.
function MacroPlayer.Focus()
	if(page) then
		local KeyInput = page:FindControl("KeyInput");
		if(KeyInput) then
			KeyInput:Focus();
		end
	end
end

function MacroPlayer.AnimKeyPressBtn(bRestart)
	if(page) then
		local keyPress = page:FindControl("keyPress");
		if(keyPress and keyPress.visible) then
			MacroPlayer.Focus()
			MacroPlayer.animKeyPressTimer = MacroPlayer.animKeyPressTimer or commonlib.Timer:new({callbackFunc = function(timer)
				MacroPlayer.AnimKeyPressBtn()
			end})
			MacroPlayer.animKeyPressTimer:Change(100);
		end
	end
end

-- @return textcontrol, multilineEditBox control.
function  MacroPlayer.GetTextControl()
	if(page) then
		local textAreaCtrl = page:FindControl("debugText");
		local textCtrl = textAreaCtrl and textAreaCtrl.ctrlEditbox;
		if(textCtrl) then
			return textCtrl:ViewPort(), textCtrl;
		end
	end
end

function MacroPlayer.ShowDebugInfoWnd(bShow)
	if(page) then
		MacroPlayer.isShowDebugWnd = bShow;
		local debugInfoWnd = page:FindControl("debugInfoWnd");
		if(debugInfoWnd) then
			debugInfoWnd.visible = bShow == true;
			if(bShow) then
				local text = GameLogic.Macros:GetLinesAsText()
				local textCtrl = MacroPlayer.GetTextControl()
				if(textCtrl) then
					textCtrl:SetText(text)
					MacroPlayer.UpdateDebugInfo()
				end
			end
		end
	end	
end

function MacroPlayer.UpdateDebugInfo()
	if(page and MacroPlayer.isShowDebugWnd) then
		local textCtrl = MacroPlayer.GetTextControl()
		if(textCtrl) then
			local m = Macros:PeekNextMacro()
			local line = m and m:GetLineNumber() or 1;
			textCtrl:moveCursor(line, 0, false, true)
			textCtrl:moveCursor(line, 40, true, true)
		end
	end
end

-- @return the number of key buttons to press
function MacroPlayer.ShowKeyboard(bShow, button, is_key_up_hide)
	local count = 0;
	if(page) then
		local parent = MacroPlayer.GetRootUIObject()

		if(not page.keyboardWnd and bShow) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/VirtualKeyboard.lua");
			local VirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.VirtualKeyboard");
			page.keyboardWnd = VirtualKeyboard:new():Init("MacroVirtualKeyboard", nil, 400, 1024);
		end
		if(page.keyboardWnd) then
			page.keyboardWnd:Show(bShow, is_key_up_hide);
		end
		
		if(bShow and button and button~="") then
			count = page.keyboardWnd:ShowButtons(button)
			if(count == 0) then
				page.keyboardWnd:Show(false, is_key_up_hide);
			end
		end
	end
	return count;
end

function MacroPlayer.ShowKeyPress(bShow, button)
	if(page) then
		local keyPress = page:FindControl("keyPress");
		if(keyPress) then
			keyPress.visible = bShow;
			if(bShow) then
				MacroPlayer.Focus()

				button = button or ""
				local buttons = {};
				local duplicatedMap = {};
				for text in button:gmatch("([%w_]+)") do
					text = Macros.ConvertKeyNameToButtonText(text)
					if(not duplicatedMap[text]) then
						duplicatedMap[text] = true
						buttons[#buttons+1] = text;
					end
				end
				local left = 5;
				for i=1, 3 do
					local keyBtn = page:FindControl("key"..i);
					local btnText = buttons[i];
					if(btnText) then
						keyBtn.text = btnText;
						keyBtn.visible = true;
						keyBtn.translationx = left;
						keyBtn:ApplyAnim();
						left = left + keyBtn.width + 5;
					else
						keyBtn.visible = false
					end
				end
				MacroPlayer.AnimKeyPressBtn(true)
			end
		end
	end
end

function MacroPlayer.ShowController(bShow)
	if(page) then
		local progressController = page:FindControl("progressController");
		if(progressController) then
			progressController.visible = bShow;
		end
	end
end

function MacroPlayer.ShowNextController(bShow)
	if page then
		local macroController = page:FindControl("macroController")
		if macroController then
			macroController.visible = bShow
			if bShow then
				local strText = "操作教学开始，理解后点击屏幕即可继续下一步"
				-- NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
				-- local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
				-- SoundManager:PlayText(strText,10006)
				GameLogic.AddBBS(nil,strText)
			end
		end
	end
end

function MacroPlayer.GetRootUIObject()
	if(page) then
		local win = page:GetRootUIObject()
		return win
	end
end

-- make it top level anyway, since some other top level window may be called before. 
function MacroPlayer.SetTopLevel()
	local win = MacroPlayer.GetRootUIObject()
	if(win) then
		-- tricky: this will force bring this window to the top of all top level windows.
		win:SetTopLevel(false);
		win:SetTopLevel(true);
	end
end

function MacroPlayer.ShowCursor(bShow, x, y, button)
	if(page) then
		local cursor = page:FindControl("cursorClick");
		if(cursor) then
			cursor.candrag = false;
			cursor.visible = bShow;
			if(bShow) then
				MacroPlayer.SetTopLevel();
				
				local scale = MacroPlayer.touch_scale
				local default_size = 32

				cursor.width = default_size * scale
				cursor.height = default_size * scale
				local img_cursor = page:FindControl("img_mousecursor");
				img_cursor.x = cursor.width/2 - img_cursor.width/2
				img_cursor.y = cursor.height/2 - img_cursor.height/2

				if(x and y) then
					cursor.x = x - cursor.width/2;
					cursor.y = y - cursor.height/2;
				end
				button = button or "";
				if(not Macros.IsShowButtonTip()) then
					button = ""
				end
				local offset = (cursor.width - default_size)/2 + 32
				local left = default_size/2 + offset;
				

				local shiftKey = page:FindControl("shiftKey")
				if(button:match("shift")) then
					shiftKey.visible = true;
					shiftKey.translationx = left;
					shiftKey:ApplyAnim();
					left = left + shiftKey.width + 5;
					shiftKey.y = offset
				else
					shiftKey.visible = false;
				end
				local ctrlKey = page:FindControl("ctrlKey")
				if(button:match("ctrl")) then
					ctrlKey.visible = true;
					ctrlKey.translationx = left;
					ctrlKey:ApplyAnim();
					left = left + ctrlKey.width + 5;
					ctrlKey.y = offset
				else
					ctrlKey.visible = false;
				end
				local altKey = page:FindControl("altKey")
				if(button:match("alt")) then
					altKey.visible = true;
					altKey.translationx = left;
					altKey:ApplyAnim();
					left = left + altKey.width + 5;
					altKey.y = offset
				else
					altKey.visible = false;
				end


				local mouseBtn = page:FindControl("mouseBtn")
				mouseBtn.y = offset
				--把提示鼠标向上移动
				local x,y,width,height = mouseBtn:GetAbsPosition()
				local screenHeight = Screen:GetHeight()
				if y + height >= screenHeight then
					mouseBtn.y = -offset
					mouseBtn.x = width/4
				end
				if(button:match("left")) then
					mouseBtn.visible = true;
					mouseBtn.background = "Texture/Aries/Quest/TutorialMouse_LeftClick_small_32bits.png";
					mouseBtn.translationx = left;
					left = left + 32 + 5;
				elseif(button:match("right")) then
					mouseBtn.visible = true;
					mouseBtn.background = "Texture/Aries/Quest/TutorialMouse_RightClick_small_32bits.png";
					mouseBtn.translationx = left;
					left = left + 32 + 5;
				elseif(button:match("middle")) then
					mouseBtn.visible = true;
					mouseBtn.background = "Texture/Aries/Quest/TutorialMouse_MiddleClick_32bits.png";
					mouseBtn.translationx = left;
					left = left + 32 + 5;
				else
					mouseBtn.visible = false;
				end
				-- mouseBtn.x = 0
				-- mouseBtn.y = 0
				-- mouseBtn.translationx = 0
				local cursorBtn = page:FindControl("cursorBtn")
				if(cursorBtn) then
					cursorBtn.visible = Macros.IsShowButtonTip()
				end
				if(Macros.IsShowButtonTip()) then
					MacroPlayer.AnimCursorBtn(true);
				end
			end
		end
		MacroPlayer.ShowBlackBg(bShow)
	end
end

-- @return true, reason:  if user is pressing correct button or false if not. 
-- reason = "mouseButtonWrong", "keyboardButtonWrong" or nil.
function MacroPlayer.CheckButton(button)
	button = button or "";
	local isOK = true;
	local reason;
	if(button:match("left") and mouse_button ~= "left") then
		isOK = false
		reason = "mouseButtonWrong"
	end
	if(button:match("right") and mouse_button ~= "right") then
		isOK = false
		reason = "mouseButtonWrong"
	end
	if(button:match("middle") and mouse_button ~= "middle") then
		-- since, some mouse does not have a middle button, we will pass anyway, but tell the user about it. 
		GameLogic.AddBBS("Macro", L"按鼠标中键", 5000, "255 0 0");
	end
	if((not button:match("ctrl")) == (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	if((not button:match("shift")) == (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	if((not button:match("alt")) == (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	return isOK, reason;
end

function MacroPlayer.OnClickCursor()
	if(MacroPlayer.expectedDragButton) then
		GameLogic.AddBBS("Macro", L"按住鼠标左键不要放手， 同时拖动鼠标到目标点", 5000, "255 0 0");
		Macros.voice("按住鼠标左键不要放手， 同时拖动鼠标到目标点")
		MacroPlayer.ResetTipTime()
		return;
	elseif(MacroPlayer.expectedKeyButton and not MacroPlayer.expectedEditBoxText) then
		GameLogic.AddBBS("Macro", L"鼠标移动到这里，但不要点击", 5000, "255 0 0");
		Macros.voice("鼠标移动到这里，但不要点击")
		MacroPlayer.ResetTipTime()
		return
	elseif(MacroPlayer.expectedMouseWheelDelta) then
		GameLogic.AddBBS("Macro", L"不要点击鼠标, 而是滚动鼠标中间的滚轮", 5000, "255 0 0");
		Macros.voice("不要点击鼠标, 而是滚动鼠标中间的滚轮")
		MacroPlayer.ResetTipTime()
		return
	end
	
	local isOK, reason = MacroPlayer.CheckButton(MacroPlayer.expectedButton);
	if(isOK) then
		if(MacroPlayer.expectedEditBoxText) then
			if(not MacroPlayer.expectedButton) then
				GameLogic.AddBBS("Macro", L"请按照指示输入文字", 5000, "255 0 0");
				Macros.voice("请按照指示输入文字")
				MacroPlayer.ResetTipTime()
				return;
			else
				MacroPlayer.expectedEditBoxText = nil;
				MacroPlayer.ShowEditBox(false)
			end
		end
		MacroPlayer.expectedButton = nil;
		MacroPlayer.ShowCursor(false)
		MacroPlayer.InvokeTriggerCallback()
	elseif(MacroPlayer.expectedButton and reason) then
		if(reason == "keyboardButtonWrong") then
			if(MacroPlayer.expectedButton:match("left")) then
				GameLogic.AddBBS("Macro", L"请按住键盘的指定按钮不要松手，同时点击鼠标左键", 5000, "255 0 0");
				Macros.voice("请按住键盘的指定按钮不要松手，同时点击鼠标左键")
			elseif(MacroPlayer.expectedButton:match("right")) then
				GameLogic.AddBBS("Macro", L"请按住键盘的指定按钮不要松手，同时点击鼠标右键", 5000, "255 0 0");
				Macros.voice("请按住键盘的指定按钮不要松手，同时点击鼠标右键")
			else
				GameLogic.AddBBS("Macro", L"请按住键盘的指定按钮不要松手，同时点击鼠标", 5000, "255 0 0");
				Macros.voice("请按住键盘的指定按钮不要松手，同时点击鼠标")
			end
			MacroPlayer.ResetTipTime()
		elseif(reason == "mouseButtonWrong") then
			if(MacroPlayer.expectedButton:match("left")) then
				GameLogic.AddBBS("Macro", L"请点击鼠标左键, 不是右键", 5000, "255 0 0");
				Macros.voice("请点击鼠标左键, 不是右键")
			elseif(MacroPlayer.expectedButton:match("right")) then
				local text = L"请点击鼠标右键, 不是左键"
				if System.os.IsTouchMode() then
					text = L"请点击鼠标右键，不是左键，你可以按住右键按钮不要放手，再点击场景。"
				end
				GameLogic.AddBBS("Macro", text, 5000, "255 0 0");
				Macros.voice(text)
			else
				GameLogic.AddBBS("Macro", L"请点击正确的鼠标按键", 5000, "255 0 0");
				Macros.voice("请点击正确的鼠标按键")
			end
			MacroPlayer.ResetTipTime()
		end
	end
end

function MacroPlayer.OnClick()
	if(not System.options.IsMobilePlatform) then
		if(MacroPlayer.expectedDragButton) then
			GameLogic.AddBBS("Macro", L"找到蓝色圆圈，按住鼠标左键不要放手，同时拖动蓝色圆圈到目标点", 5000, "255 0 0");
			Macros.voice("找到蓝色圆圈，按住鼠标左键不要放手，同时拖动蓝色圆圈到目标点")
			MacroPlayer.ResetTipTime(5000)
		elseif(MacroPlayer.expectedButton) then
			if(MacroPlayer.expectedButton:match("left")) then
				GameLogic.AddBBS("Macro", L"请用鼠标左键点击屏幕蓝色圆圈的中心", 5000, "255 0 0");
				Macros.voice("请用鼠标左键点击屏幕蓝色圆圈的中心")
				MacroPlayer.ResetTipTime()
			elseif(MacroPlayer.expectedButton:match("right")) then
				GameLogic.AddBBS("Macro", L"请用鼠标右键点击屏幕蓝色圆圈的中心", 5000, "255 0 0");
				Macros.voice("请用鼠标右键点击屏幕蓝色圆圈的中心")
				MacroPlayer.ResetTipTime()
			end
		end
	end
end

function MacroPlayer.IsTouchVirtualKeyboardIconEvent()
	local left, top, width, height = TouchVirtualKeyboardIcon.left, TouchVirtualKeyboardIcon.top, TouchVirtualKeyboardIcon.width, TouchVirtualKeyboardIcon.height;
	return left < mouse_x and mouse_x < (left + width) and top < mouse_y and mouse_y < (top + height);
end
function MacroPlayer.OnTouch(event)
	if page and page.keyboardWnd ~= nil and page.keyboardWnd:IsVisible() then
		page.keyboardWnd:OnTouch(msg)
		return
	end
	if (not TouchMiniKeyboard) then return end

	TouchMiniKeyboard:OnTouch(msg);
	-- TouchMiniRightKeyboard:OnTouch(msg)
	if (MacroPlayer.IsTouchVirtualKeyboardIconEvent()) then TouchVirtualKeyboardIcon:OnTouch(msg) end 
	if (TouchVirtualKeyboardIcon:GetKeyBoard():IsVisible()) then TouchVirtualKeyboardIcon:GetKeyBoard():OnTouch(msg) end

end
function MacroPlayer.OnMouseDown(event)
	if page.keyboardWnd and page.keyboardWnd:IsVisible() then
		page.keyboardWnd:OnMouseDown(event)
		return
	end

	if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
		TouchMiniKeyboard:OnMouseDown(event);
		if (MacroPlayer.IsTouchVirtualKeyboardIconEvent()) then TouchVirtualKeyboardIcon:OnMouseDown(event) end 
		if (TouchVirtualKeyboardIcon:GetKeyBoard():IsVisible()) then TouchVirtualKeyboardIcon:GetKeyBoard():OnMouseDown(event) end
	end

end
function MacroPlayer.OnMouseMove(event)
	if page.keyboardWnd and page.keyboardWnd:IsVisible() then
		page.keyboardWnd:OnMouseMove(event)
		return
	end
	if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
		TouchMiniKeyboard:OnMouseMove(event);
		if (MacroPlayer.IsTouchVirtualKeyboardIconEvent()) then TouchVirtualKeyboardIcon:OnMouseMove(event) end 
		if (TouchVirtualKeyboardIcon:GetKeyBoard():IsVisible()) then TouchVirtualKeyboardIcon:GetKeyBoard():OnMouseMove(event) end
	end

end
function MacroPlayer.OnMouseUp(event)
	if page.keyboardWnd and page.keyboardWnd:IsVisible() then
		page.keyboardWnd:OnMouseUp(event)
		return
	end
	if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
		TouchMiniKeyboard:OnMouseUp(event);
		if (MacroPlayer.IsTouchVirtualKeyboardIconEvent()) then TouchVirtualKeyboardIcon:OnMouseUp(event) end 
		if (TouchVirtualKeyboardIcon:GetKeyBoard():IsVisible()) then TouchVirtualKeyboardIcon:GetKeyBoard():OnMouseUp(event) end
	end

end

function MacroPlayer.OnKeyDown(event)
	if(not GameLogic.IsReadOnly() and event.keyname == "DIK_F3") then
		MacroPlayer.ShowDebugInfoWnd(not MacroPlayer.isShowDebugWnd)
	end
	
	if(Macros.IsAutoPlay()) then
		MacroPlayer.DoAutoPlay();
		return
	end
	local button = MacroPlayer.expectedKeyButton
	if(not button) then
		return
	end
	local isOK = true;
	if((not button:match("ctrl")) ~= (not event.ctrl_pressed)) then
		isOK = false
	end
	if((not button:match("shift")) ~= (not event.shift_pressed)) then
		isOK = false
	end
	if((not button:match("alt")) ~= (not event.alt_pressed)) then
		isOK = false
	end
	local keyname = button:match("(DIK_[%w_]+)");
	if(keyname and keyname~=event.keyname) then
		-- this fixed some numeric key lock issues.
		if( (keyname == "DIK_END" and (event.keyname == "DIK_1" or event.keyname == "DIK_NUMPAD1")) or 
			(keyname == "DIK_HOME" and (event.keyname == "DIK_7" or event.keyname == "DIK_NUMPAD7")) or 
			(keyname == "DIK_PAGE_DOWN" and (event.keyname == "DIK_3" or event.keyname == "DIK_NUMPAD3")) or 
			(keyname == "DIK_PAGE_UP" and (event.keyname == "DIK_9" or event.keyname == "DIK_NUMPAD9")) ) then
			GameLogic.AddBBS("Macro2", L"你可能需要按【NUM LOCK】按键", 5000, "0 255 0");
			is_OK = true
		else
			isOK = false
		end
		
	end
	local mouseX, mouseY = GameLogic.Macros.GetNextKeyPressWithMouseMove()
	if(mouseX and mouseY) then
		local mX, mY = ParaUI.GetMousePosition()
		local diffDistance = math.sqrt((mouseX - mX)^2 + (mouseY - mY)^2)
		if(diffDistance > 16) then
			isOK = false
			GameLogic.AddBBS("Macro", L"请将鼠标移动到目标点，再按键盘", 5000, "255 0 0");
			Macros.voice("请将鼠标移动到目标点，再按键盘")
			MacroPlayer.ResetTipTime()
		end
	end

	if(isOK) then
		if(MacroPlayer.expectedEditBoxText) then
			MacroPlayer.expectedEditBoxText = nil;
		end
		MovieUISound.PlayAddKey();
		MacroPlayer.ShowEditBox(false)
		MacroPlayer.expectedKeyButton = nil;
		MacroPlayer.ShowKeyPress(false)
		MacroPlayer.ShowKeyboard(false, nil, true)
		MacroPlayer.ShowCursor(false);
		MacroPlayer.InvokeTriggerCallback()
	end
end

function MacroPlayer.SetClickTrigger(mouseX, mouseY, button, callbackFunc)
	if(page) then
		MacroPlayer.CheckDoAutoPlay(callbackFunc)
		MacroPlayer.expectedButton = button;
		MacroPlayer.SetTriggerCallback(callbackFunc)
		MacroPlayer.ShowCursor(true, mouseX, mouseY, button)
		MacroPlayer.AutoAdjustControlPosition(mouseX, mouseY)
	end
end

function MacroPlayer.SetKeyPressTrigger(button, targetText, callbackFunc)
	if(page) then
		MacroPlayer.CheckDoAutoPlay(callbackFunc)
		if(button == "DIK_ADD") then
			button = "shift+DIK_EQUALS"
		elseif(button == "DIK_SUBTRACT") then
			button = "DIK_MINUS"
		end
		MacroPlayer.expectedKeyButton = button;
		local mouseX, mouseY = GameLogic.Macros.GetNextKeyPressWithMouseMove()
		if(mouseX and mouseY) then
			MacroPlayer.ShowCursor(true, mouseX, mouseY)
			MacroPlayer.AutoAdjustControlPosition(mouseX, mouseY)
		end
		MacroPlayer.SetTriggerCallback(callbackFunc)
		
		if(targetText and targetText~="") then
			MacroPlayer.ShowEditBox(true, targetText)
			if(Macros.IsShowKeyButtonTip()) then
				MacroPlayer.ShowKeyPress(true, button)
			end
		else
			if(Macros.IsShowKeyButtonTip()) then
				MacroPlayer.ShowKeyPress(true, button)
			end
		end
	end
end

function MacroPlayer.SetEditBoxTrigger(mouseX, mouseY, text, textDiff, callbackFunc)
	if(page) then
		MacroPlayer.CheckDoAutoPlay(callbackFunc)
		MacroPlayer.expectedEditBoxText = text;
		MacroPlayer.SetTriggerCallback(callbackFunc)

		local keyButtons = Macros.TextToKeyName(textDiff)
		if(keyButtons) then
			MacroPlayer.ShowEditBox(true, text, textDiff)
			MacroPlayer.expectedKeyButton = keyButtons; 
			Macros.SetNextKeyPressWithMouseMove(nil, nil); -- mouseX, mouseY
			if(Macros.IsShowKeyButtonTip()) then
				MacroPlayer.ShowKeyPress(true, keyButtons)
			end
			MacroPlayer.ShowCursor(true, mouseX, mouseY);
		else
			-- we do not need user to enter text, just click to enter
			MacroPlayer.ShowEditBox(true, text..L"(点击)")
			MacroPlayer.expectedButton = "left";
			MacroPlayer.ShowCursor(true, mouseX, mouseY, "left");
		end
		MacroPlayer.AutoAdjustControlPosition(mouseX, mouseY)
	end
end

local dragTick = 0;
function MacroPlayer.AnimDragBtn(bRestart)
	if(page) then
		local startPoint = page:FindControl("startPoint");
		local endPoint = page:FindControl("endPoint");
		if(MacroPlayer.isDragging) then
			startPoint.translationx = 0
			startPoint.translationy = 0
		elseif(startPoint and startPoint.visible) then
			local startX, startY = startPoint:GetAbsPosition();
			local endX, endY = endPoint:GetAbsPosition();
			
			local diffDistance = math.sqrt((endX - startX)^2 + (endY - startY)^2)

			local totalTicks = 80;
			dragTick = bRestart and 0 or (dragTick + 1);
			local progress = (dragTick) / totalTicks;
			if(dragTick >= totalTicks) then
				dragTick = 0;
			end
			
			if( diffDistance > 16 ) then
				startPoint.translationx = math.floor((endX - startX) * progress + 0.5);
				startPoint.translationy = math.floor((endY - startY) * progress + 0.5);
				MacroPlayer.animDragTimer = MacroPlayer.animDragTimer or commonlib.Timer:new({callbackFunc = function(timer)
					if(Macros.IsShowButtonTip()) then
						MacroPlayer.AnimDragBtn()
					end
				end})
			else
				startPoint.translationx = 0;
				startPoint.translationy = 0;
				dragTick = 0;
			end
			if(MacroPlayer.animDragTimer) then
				MacroPlayer.animDragTimer:Change(30);
			end
		end
	end
end

function MacroPlayer.ShowDrag(bShow, startX, startY, endX, endY, button)
	if(page) then
		local dragPoints = page:FindControl("dragPoints");
		if(dragPoints) then
			dragPoints.visible = bShow;
			if(bShow) then
				local curPoint = page:FindControl("cursorClick");
				curPoint.candrag = true;

				local startPoint = page:FindControl("startPoint")
				local width = 24;
				startPoint.x = startX - width;
				startPoint.y = startY - width;
				
				local endPoint = page:FindControl("endPoint")
				endPoint.x = endX - width;
				endPoint.y = endY - width;

				if(Macros.IsShowButtonTip()) then
					MacroPlayer.AnimDragBtn(true)
				end
			end
		end
	end
end

function MacroPlayer.SetDragTrigger(startX, startY, endX, endY, button, callbackFunc)
	if(page) then
		MacroPlayer.CheckDoAutoPlay(callbackFunc)
		if(button == "right") then
			-- TODO: default C++ dragging does not support right drag, we may find a manual implementation for right mouse drag. 
			button = "left";
		end
		MacroPlayer.expectedDragButton = button;
		MacroPlayer.SetTriggerCallback(callbackFunc)
		MacroPlayer.ShowCursor(true, startX, startY, button)
		MacroPlayer.ShowDrag(true, startX, startY, endX, endY, button)
		MacroPlayer.AutoAdjustControlPosition(startX, startY, endX, endY)
	end
end

function MacroPlayer.OnDragBegin()
	MacroPlayer.isDragging = true;
	MacroPlayer.isDragButtonCorrect = MacroPlayer.CheckButton(MacroPlayer.expectedDragButton);
	MacroPlayer.isReachedDragTarget = false;
end

function MacroPlayer.OnDragMove()
	
	if(page) then
		local curPoint = page:FindControl("cursorClick");
		local endPoint = page:FindControl("endPoint");
		if(curPoint) then
			
			local startX, startY, widthStart = curPoint:GetAbsPosition();
			startX = startX + widthStart * 0.5
			startY = startY + widthStart * 0.5
			local endX, endY, widthEnd = endPoint:GetAbsPosition();
			endX = endX + widthEnd * 0.5
			endY = endY + widthEnd * 0.5
			local diffDistance = math.sqrt((endX - startX)^2 + (endY - startY)^2)
			local targetDistance = 16 * MacroPlayer.touch_scale
			MacroPlayer.isReachedDragTarget = (diffDistance < targetDistance);
		end
	end

	MacroPlayer.isDragButtonCorrect = MacroPlayer.isDragButtonCorrect and MacroPlayer.CheckButton(MacroPlayer.expectedDragButton);
	if(not MacroPlayer.isDragButtonCorrect) then
		GameLogic.AddBBS("Macro", L"拖动鼠标时需要同时按下正确的键盘按键", 5000, "255 0 0");
	end
end


function MacroPlayer.Print(...)
	local arg={...}
	local str = ""
	for index, v in ipairs(arg) do
		str = str .. ", " .. tostring(v)
	end
	str = str .. "   time:" .. os.time()
	commonlib.echo(str)
end

function MacroPlayer.OnDragEnd()
	MacroPlayer.isDragging = false;
	MacroPlayer.isDragButtonCorrect = MacroPlayer.isDragButtonCorrect and MacroPlayer.CheckButton(MacroPlayer.expectedDragButton);
	if(MacroPlayer.isDragButtonCorrect) then
		if(MacroPlayer.isReachedDragTarget) then
			MacroPlayer.expectedDragButton = nil;
			MacroPlayer.isReachedDragTarget = nil;
			MacroPlayer.ShowDrag(false)
			MacroPlayer.ShowCursor(false)
			MacroPlayer.InvokeTriggerCallback()
			return
		else
			-- tell the user to drag to the target location. 
			GameLogic.AddBBS("Macro", L"请拖动鼠标到目标点", 5000, "255 0 0");
			Macros.voice("请拖动鼠标到目标点")
			MacroPlayer.ResetTipTime()
		end
	else
		GameLogic.AddBBS("Macro", L"拖动鼠标时需要同时按下正确的键盘按键", 5000, "255 0 0");
		Macros.voice("拖动鼠标时需要同时按下正确的键盘按键")
		MacroPlayer.ResetTipTime()
	end
	if(Macros.IsShowButtonTip()) then
		MacroPlayer.AnimDragBtn(true)
		MacroPlayer.AnimCursorBtn(true);
	end
end

-- @param text: text or mcml text.  if nil, we will hide it. 
function MacroPlayer.ShowTip(text)
	if(page) then
		local tipWnd = page:FindControl("tipWnd");
		if(text and text~="") then
			tipWnd.visible = true;
			page:SetValue("tipText", text)
		else
			tipWnd.visible = false;
			page:SetValue("tipText", "")
		end
	end	
end

function MacroPlayer.SetTextValue(text)
	MacroPlayer.text = text
	local gvw_name = "text_grid";
	local node = page:GetNode(gvw_name);
	if node then
		pe_gridview.DataBind(node, gvw_name, false);
	end
	
end

-- @param text: text.  if nil, we will hide it. 
-- @param duration: the max duration
-- @param position: nil default to "bottom", can also be "center", "top"
function MacroPlayer.ShowText(text, duration, position)
	if(page) then
		local textWnd = page:FindControl("textWnd");
		if(text and text~="") then
			textWnd.visible = true;
			MacroPlayer.SetTextValue(text)
			-- page:Refresh(0.01)

		else
			textWnd.visible = false;
			MacroPlayer.SetTextValue("")
		end
		if(duration) then
			duration = tonumber(duration);
			MacroPlayer.textTimer = MacroPlayer.textTimer or commonlib.Timer:new({callbackFunc = function(timer)
				MacroPlayer.ShowText(nil)
			end})
			MacroPlayer.textTimer:Change(duration);
		elseif(MacroPlayer.textTimer) then
			MacroPlayer.textTimer:Change();
		end
		position = position or "bottom"
		MacroPlayer.SetShowTextPosition(textWnd, position);
		MacroPlayer.lastTextPosition = position;
	end	
end

function MacroPlayer.SetShowTextPosition(textWnd, position)
	position = position or "bottom"
	if(position == "bottom") then
		if TouchMiniKeyboard and TouchMiniKeyboard:isVisible() then
			textWnd:Reposition("_mb", 0, -30, 0, 120);
		else
			textWnd:Reposition("_mb", 0, 20, 0, 120);
		end
	elseif(position == "center") then
		textWnd:Reposition("_mb", 0, 340, 0, 120);
	elseif(position == "top") then
		textWnd:Reposition("_mt", 0, 120, 0, 120);
	end
end


function MacroPlayer.ShowEditBox(bShow, text, textDiff)
	if(page) then
		local editBox = page:FindControl("editBox");
		editBox.visible = bShow;
		if(bShow) then
			page:SetValue("editboxText", text or "")
		end
	end	
end

function MacroPlayer.OnMouseWheel()
	if(MacroPlayer.expectedMouseWheelDelta) then
		if((MacroPlayer.expectedMouseWheelDelta > 0 and mouse_wheel > 0) or (MacroPlayer.expectedMouseWheelDelta < 0 and mouse_wheel < 0)) then
			MacroPlayer.expectedMouseWheelDelta = nil;
			MacroPlayer.ShowMouseWheel(false)
			MacroPlayer.ShowCursor(false)
			MacroPlayer.InvokeTriggerCallback()
		else
			GameLogic.AddBBS("Macro", L"请向另外一个方向滚动鼠标中间的滚轮", 5000, "255 0 0");
			Macros.voice("请向另外一个方向滚动鼠标中间的滚轮")
			MacroPlayer.ResetTipTime()
		end
	end	
end

function MacroPlayer.ShowMouseWheel(bShow, mouseX, mouseY)
	if(page) then
		local mouseWheel = page:FindControl("mouseWheel");
		if(mouseWheel) then
			mouseWheel.visible = (bShow == true);
			if(bShow) then
				mouseWheel.x = mouseX or 300;
				mouseWheel.y = mouseY or 50;
			end
		end
	end	
end

function MacroPlayer.CheckDoAutoPlay(callbackFunc)
	if(Macros.IsAutoPlay()) then
		MacroPlayer.Focus()
		local defaultInterval = Macros.GetLastIdleTime() or 200;
		defaultInterval = math.max(math.floor(defaultInterval / Macros.GetPlaySpeed() + 0.5), 10)

		MacroPlayer.autoPlayTimer = MacroPlayer.autoPlayTimer or commonlib.Timer:new({callbackFunc = function(timer)
			MacroPlayer.DoAutoPlay()
		end})
		MacroPlayer.autoPlayTimer:Change(defaultInterval)
	end
end

function MacroPlayer.DoAutoPlay()
	if(MacroPlayer.autoPlayTimer) then
		MacroPlayer.autoPlayTimer:Change()
	end
	if(Macros.IsAutoPlay()) then
		MacroPlayer.AutoCompleteTrigger()
	end
end

-- auto finish current trigger and play the next macro
function MacroPlayer.AutoCompleteTrigger()
	if(MacroPlayer.triggerCallbackFunc) then
		MacroPlayer.HideAll(true)
		MacroPlayer.InvokeTriggerCallback();
	end
end


function MacroPlayer.SetMouseWheelTrigger(mouseWheelDelta, mouseX, mouseY, callbackFunc)
	if(page) then
		MacroPlayer.CheckDoAutoPlay(callbackFunc)
		MacroPlayer.expectedMouseWheelDelta = mouseWheelDelta;

		MacroPlayer.SetTriggerCallback(callbackFunc)
		if(Macros.IsShowButtonTip()) then
			MacroPlayer.ShowMouseWheel(true, mouseX, mouseY)
		end
		MacroPlayer.ShowCursor(true, mouseX, mouseY, "")
		MacroPlayer.AutoAdjustControlPosition(mouseX, mouseY)
		if System.os.IsTouchMode() and mouseWheelDelta then
			commonlib.TimerManager.SetTimeout(function()  
				MacroPlayer.AutoCompleteTrigger()
			end, 1000)
			
		end
	end
end

-- @param window: attach a mcml v2 window object to it, usually from CodeBlock's window() function
-- @param name: this can be nil. if not there can only be one named window at a time. 
-- @param zorder: default to 1000, relative to macro player parent
function MacroPlayer.AttachWindow(window, name, zorder)
	if(window) then
		MacroPlayer.ShowController(false);
		local parent = MacroPlayer.GetRootUIObject()
		if(parent) then
			local win = window:GetNativeWindow()
			if(win) then
				if(not name) then
					MacroPlayer.attachedWnd = window;
				else
					MacroPlayer.attachedWindows = MacroPlayer.attachedWindows or {}
					MacroPlayer.attachedWindows[name] = window
				end
				zorder = zorder or 1000
				win.zorder = zorder;
				parent:AddChild(win)
				return true
			end
		end
	end
	return false
end

function MacroPlayer.DetachWindow(name)
	if(not name) then
		if(MacroPlayer.attachedWnd) then
			MacroPlayer.attachedWnd:CloseWindow();
			MacroPlayer.attachedWnd = nil;
		end
	else
		if(MacroPlayer.attachedWindows and MacroPlayer.attachedWindows[name]) then
			MacroPlayer.attachedWindows[name]:CloseWindow();
			MacroPlayer.attachedWindows[name] = nil
		end
	end
end

function MacroPlayer.GetWindow(name)
	if(not name) then
		return MacroPlayer.attachedWnd
	else
		return MacroPlayer.attachedWindows and MacroPlayer.attachedWindows[name]
	end
end

function MacroPlayer.ShowWindow(bShow, name)
	if(page) then
		if(not name) then
			if(MacroPlayer.attachedWnd) then
				if(bShow) then
					MacroPlayer.attachedWnd:show()
				else
					MacroPlayer.attachedWnd:hide()
				end
			end
		else
			local wnd = MacroPlayer.attachedWindows and MacroPlayer.attachedWindows[name]
			if(wnd) then
				if(bShow) then
					wnd:show()
				else
					wnd:hide()
				end
			end
		end
	end
end

-- @return nil if no movement is required, or x, y if moved. 
local function MoveRectDownOutOfRect(x, y, width, height, x1, y1, x2, y2, margin) 
	x2 = x2 or x1;
	y2 = y2 or y1;
	margin = margin or 32;
	if((x+width+margin) < math.min(x1, x2)) then
		return;
	elseif((y+height+margin) < math.min(y1, y2)) then
		return
	else
		return x, math.max(y1, y2)+margin;
	end
end

--@param x1, y1, x2, y2: screen position that should not be covered by a control window. 
-- if all are nil, we will restore all controls to their default position. 
function MacroPlayer.AutoAdjustControlPosition(x1, y1, x2, y2)
	MacroPlayer.UpdateDebugInfo()
	if(MacroPlayer.attachedWnd) then
		local wnd = MacroPlayer.attachedWnd
		if(x1 and y1) then
			local x, y = wnd:GetScreenPos()
			local width = wnd:width();
			local height = wnd:height();
			local layout = wnd:GetLayout();
			if(layout and layout.GetUsedSize) then
				width, height = layout:GetUsedSize();
			end

			local newX, newY = MoveRectDownOutOfRect(x, y, width, height, x1, y1, x2, y2, 32) 
			if(newX and newY) then
				if(not wnd.lastPos) then
					wnd.lastPos = {x = x, y=y, width=width, height = height};
				end
				wnd:setGeometry(newX, newY, width, height);
			end
		elseif(wnd.lastPos) then
			wnd:setGeometry(wnd.lastPos.x, wnd.lastPos.y, wnd.lastPos.width, wnd.lastPos.height);
		end
	end
	if(page) then
		local textWnd = page:FindControl("textWnd");
		if(textWnd and textWnd.visible) then
			if(x1 and y1) then
				if(MacroPlayer.lastTextPosition == "bottom") then
					local x, y, width, height = textWnd:GetAbsPosition();
					y2 = y2 or y1;
					if((y+height+16) > math.max(y1, y2) and (y-32) < math.min(y1, y2)) then
						MacroPlayer.lastSavedTextPosition = MacroPlayer.lastTextPosition;
						MacroPlayer.SetShowTextPosition(textWnd, "center");
					end
				end
			elseif(MacroPlayer.lastSavedTextPosition) then
				MacroPlayer.lastSavedTextPosition = nil;
				MacroPlayer.SetShowTextPosition(textWnd, MacroPlayer.lastSavedTextPosition);
			end
		end	
		local tipWnd = page:FindControl("tipWnd");
		if(tipWnd and tipWnd.visible) then
			if(x1 and y1) then
				local x, y, width, height = tipWnd:GetAbsPosition();

				local newX, newY = MoveRectDownOutOfRect(x, y, width, height, x1, y1, x2, y2, 32) 
				if(newX and newY) then
					MacroPlayer.lastSavedTipPos = {x=x, y=y, width=width, height=height};
					tipWnd:Reposition("_lt", newX, newY, width, height);
				end
			elseif(MacroPlayer.lastSavedTipPos) then
				tipWnd:Reposition("_lt", MacroPlayer.lastSavedTipPos.x, MacroPlayer.lastSavedTipPos.y, MacroPlayer.lastSavedTipPos.width, MacroPlayer.lastSavedTipPos.height);
				MacroPlayer.lastSavedTipPos = nil;
			end
		end
		local progressController = page:FindControl("progressController");
		if(progressController and progressController.visible) then
			if(x1 and y1) then
				local x, y, width, height = progressController:GetAbsPosition();

				local newX, newY = MoveRectDownOutOfRect(x, y, width, height, x1, y1, x2, y2, 32) 
				if(newX and newY) then
					MacroPlayer.lastSavedProgressPos = {x=x, y=y, width=width, height=height};
					progressController:Reposition("_lt", newX, newY, width, height);
				end
			elseif(MacroPlayer.lastSavedProgressPos) then
				progressController:Reposition("_lt", MacroPlayer.lastSavedProgressPos.x, MacroPlayer.lastSavedProgressPos.y, MacroPlayer.lastSavedProgressPos.width, MacroPlayer.lastSavedProgressPos.height);
				MacroPlayer.lastSavedProgressPos = nil;
			end
		end
	end
end

function MacroPlayer.OnSoundStartsPlaying()
	if not page then
		return
	end

	if not SoundManager:IsPlayTextSoundPlaying() then
		return
	end
	
	local sound_icon = page:FindControl("soundIcon")
	if sound_icon:IsValid() then
		if sound_icon.visible then
			return
		end

		sound_icon.visible = true
	end

	local change_index = 1
	MacroPlayer.SoundIconTimer = MacroPlayer.SoundIconTimer or commonlib.Timer:new({callbackFunc = function(timer)
		if page then
			local sound_icon = page:FindControl("soundIcon")
			if not SoundManager:IsPlayTextSoundPlaying() then
				MacroPlayer.SoundIconTimer:Change();			
				if sound_icon:IsValid() then
					sound_icon.visible = false
				end
				return
			end
	
			if sound_icon:IsValid() then
				change_index = change_index == 1 and 2 or 1
				local background = string.format("Texture/Aries/Quest/laba%s_48x46_32bits.png;0 0 48 46", change_index)
				sound_icon.visible = true
				sound_icon.background = background
			end
		else
			MacroPlayer.SoundIconTimer:Change();	
		end
	end})
	MacroPlayer.SoundIconTimer:Change(0, 300);
end