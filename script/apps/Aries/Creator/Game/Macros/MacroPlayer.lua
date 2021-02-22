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
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MacroPlayer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer"));
local page;

function MacroPlayer.OnInit()
	page = document:GetPageCtrl();
	GameLogic.GetFilters():add_filter("Macro_EndPlay", MacroPlayer.OnEndPlay);
	GameLogic.GetFilters():add_filter("Macro_PlayMacro", MacroPlayer.OnPlayMacro);
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
	local cursorClick = page:FindControl("cursorClick");
	if(cursorClick) then
		cursorClick:SetScript("onmousewheel", function()
			MacroPlayer.OnMouseWheel()
		end);
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
end

function MacroPlayer.OnViewportChange()
	if(page and MacroPlayer.triggerCallbackFunc) then
		MacroPlayer.RefreshPage(0);
		
		if(page and page.keyboardWnd) then
			page.keyboardWnd:Destroy();
			page.keyboardWnd = nil;
		end
		local m = Macros:PeekNextMacro(0)
		if(m and m:IsTrigger()) then
			m:RunAgain()
		end
	end
end

-- @param duration: in seconds
function MacroPlayer.ShowPage()
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
	end
	MacroPlayer.ShowEditBox(false);
	MacroPlayer.ShowMouseWheel(false);
	MacroPlayer.ShowKeyboard(false);
end

function MacroPlayer.OnPlayMacro(fromLine, macros)
	local progress = math.floor(fromLine / (#macros)*100 + 0.5);
	if(page) then
		page:SetValue("progress", progress);
	end
	return fromLine;
end

function MacroPlayer.OnEndPlay()
	MacroPlayer.CloseWindow();
end

function MacroPlayer.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function MacroPlayer.OnClickStop()
	GameLogic.Macros:Stop()
end


function MacroPlayer.InvokeTriggerCallback()
	local callback = MacroPlayer.triggerCallbackFunc;
	if(callback) then
		MacroPlayer.triggerCallbackFunc = nil;
		callback();
		MacroPlayer.AutoAdjustControlPosition()
	end
end

local nStartTime = 0;
MacroPlayer.ShowTipTime = 5000;
function MacroPlayer.SetTriggerCallback(callback)
	if(callback) then
		GameLogic.AddBBS("Macro", nil);
		if(Macros.IsShowButtonTip() and not Macros.IsAutoPlay()) then
			nStartTime = commonlib.TimerManager.GetCurrentTime();
			MacroPlayer.waitActionTimer = MacroPlayer.waitActionTimer or commonlib.Timer:new({callbackFunc = function(timer)
				if(page and MacroPlayer.triggerCallbackFunc) then
					local elapsedTime = commonlib.TimerManager.GetCurrentTime() - nStartTime;
					if(elapsedTime > MacroPlayer.ShowTipTime) then
						MacroPlayer.ShowMoreTips();
						nStartTime = commonlib.TimerManager.GetCurrentTime() + MacroPlayer.ShowTipTime;
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
		local mouseX, mouseY = GameLogic.Macros.GetNextKeyPressWithMouseMove()
		if(mouseX and mouseY) then
			-- key press at given scene location. 
		else
			local count = MacroPlayer.ShowKeyboard(true, MacroPlayer.expectedKeyButton);
			if(count and count > 1) then
				GameLogic.AddBBS("Macro", format(L"你需要同时按下%d个按键", count), 5000, "0 255 0");
				Macros.voice("你需要同时按下2个按键")
			end
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
			local x, y, width, height = cursor:GetAbsPosition();
			x = x + 12;
			y = y + 15;
			local cursorBtn = page:FindControl("cursorBtn")
			

			local mouseX, mouseY = ParaUI.GetMousePosition();
			
			local totalTicks = 30;
			cursorTick = bRestart and 0 or (cursorTick + 1);
			local progress = (totalTicks - cursorTick) / totalTicks;
			if(cursorTick >= totalTicks) then
				cursorTick = 0;
			end
			local diffDistance = math.sqrt((mouseX - x)^2 + (mouseY - y)^2)
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

-- @return the number of key buttons to press
function MacroPlayer.ShowKeyboard(bShow, button)
	local count = 0;
	if(page) then
		local parent = MacroPlayer.GetRootUIObject()

		if(not page.keyboardWnd) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/VirtualKeyboard.lua");
			local VirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.VirtualKeyboard");
			page.keyboardWnd = VirtualKeyboard:new():Init("MacroVirtualKeyboard", nil, 400, 1024);
		end
		page.keyboardWnd:Show(bShow);
		
		if(bShow and button and button~="") then
			count = page.keyboardWnd:ShowButtons(button)
			if(count == 0) then
				page.keyboardWnd:Show(false);
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
			cursor.visible = bShow;
			if(bShow) then
				MacroPlayer.SetTopLevel();
				
				if(x and y) then
					cursor.x = x - 16;
					cursor.y = y - 16;
				end
				button = button or "";
				if(not Macros.IsShowButtonTip()) then
					button = ""
				end
				local left = 16 + 32;
				
				local shiftKey = page:FindControl("shiftKey")
				if(button:match("shift")) then
					shiftKey.visible = true;
					shiftKey.translationx = left;
					shiftKey:ApplyAnim();
					left = left + shiftKey.width + 5;
				else
					shiftKey.visible = false;
				end
				local ctrlKey = page:FindControl("ctrlKey")
				if(button:match("ctrl")) then
					ctrlKey.visible = true;
					ctrlKey.translationx = left;
					ctrlKey:ApplyAnim();
					left = left + ctrlKey.width + 5;
				else
					ctrlKey.visible = false;
				end
				local altKey = page:FindControl("altKey")
				if(button:match("alt")) then
					altKey.visible = true;
					altKey.translationx = left;
					altKey:ApplyAnim();
					left = left + altKey.width + 5;
				else
					altKey.visible = false;
				end


				local mouseBtn = page:FindControl("mouseBtn")
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

				local cursorBtn = page:FindControl("cursorBtn")
				if(cursorBtn) then
					cursorBtn.visible = Macros.IsShowButtonTip()
				end
				if(Macros.IsShowButtonTip()) then
					MacroPlayer.AnimCursorBtn(true);
				end
			end
		end
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
	if(button:match("ctrl") and not (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	if(button:match("shift") and not (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	if(button:match("alt") and not (ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU))) then
		isOK = false
		reason = "keyboardButtonWrong"
	end
	return isOK, reason;
end

function MacroPlayer.OnClickCursor()
	if(MacroPlayer.expectedDragButton) then
		GameLogic.AddBBS("Macro", L"按住鼠标左键不要放手， 同时拖动鼠标到目标点", 5000, "255 0 0");
		Macros.voice("按住鼠标左键不要放手， 同时拖动鼠标到目标点")
		return;
	elseif(MacroPlayer.expectedKeyButton and not MacroPlayer.expectedEditBoxText) then
		GameLogic.AddBBS("Macro", L"鼠标移动到这里，但不要点击", 5000, "255 0 0");
		Macros.voice("鼠标移动到这里，但不要点击")
		return
	elseif(MacroPlayer.expectedMouseWheelDelta) then
		GameLogic.AddBBS("Macro", L"不要点击鼠标, 而是滚动鼠标中间的滚轮", 5000, "255 0 0");
		Macros.voice("不要点击鼠标, 而是滚动鼠标中间的滚轮")
		return
	end
	
	local isOK, reason = MacroPlayer.CheckButton(MacroPlayer.expectedButton);
	if(isOK) then
		if(MacroPlayer.expectedEditBoxText) then
			if(not MacroPlayer.expectedButton) then
				GameLogic.AddBBS("Macro", L"请按照指示输入文字", 5000, "255 0 0");
				Macros.voice("请按照指示输入文字")
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
			GameLogic.AddBBS("Macro", L"请按住键盘的指定按钮不要松手，同时点击鼠标", 5000, "255 0 0");
			Macros.voice("请按住键盘的指定按钮不要松手，同时点击鼠标")
		elseif(reason == "mouseButtonWrong") then
			GameLogic.AddBBS("Macro", L"请点击正确的鼠标按键", 5000, "255 0 0");
			Macros.voice("请点击正确的鼠标按键")
		end
	end
end

function MacroPlayer.OnKeyDown(event)
	if(Macros.IsAutoPlay()) then
		MacroPlayer.DoAutoPlay();
		return
	end
	local button = MacroPlayer.expectedKeyButton
	if(not button) then
		return
	end
	local isOK = true;
	if(button:match("ctrl") and not event.ctrl_pressed) then
		isOK = false
	end
	if(button:match("shift") and not event.shift_pressed) then
		isOK = false
	end
	if(button:match("alt") and not event.alt_pressed) then
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
		MacroPlayer.ShowKeyboard(false)
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
		MacroPlayer.ShowDrag(true, startX, startY, endX, endY, button)
		MacroPlayer.ShowCursor(true, startX, startY, button)
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
			local startX, startY = curPoint:GetAbsPosition();
			local endX, endY = endPoint:GetAbsPosition();
			local diffDistance = math.sqrt((endX - startX)^2 + (endY - startY)^2)
			MacroPlayer.isReachedDragTarget = (diffDistance < 16);
		end
	end

	MacroPlayer.isDragButtonCorrect = MacroPlayer.isDragButtonCorrect and MacroPlayer.CheckButton(MacroPlayer.expectedDragButton);
	if(not MacroPlayer.isDragButtonCorrect) then
		GameLogic.AddBBS("Macro", L"拖动鼠标时需要按正确的按键", 5000, "255 0 0");
	end
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
		end
	else
		GameLogic.AddBBS("Macro", L"拖动鼠标时需要按正确的按键", 5000, "255 0 0");
		Macros.voice("拖动鼠标时需要按正确的按键")
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

-- @param text: text.  if nil, we will hide it. 
-- @param duration: the max duration
-- @param position: nil default to "bottom", can also be "center", "top"
function MacroPlayer.ShowText(text, duration, position)
	if(page) then
		local textWnd = page:FindControl("textWnd");
		if(text and text~="") then
			textWnd.visible = true;
			page:SetValue("text", text)
		else
			textWnd.visible = false;
			page:SetValue("text", "")
		end
		if(duration) then
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
		textWnd:Reposition("_mb", 0, 80, 0, 60);
	elseif(position == "center") then
		textWnd:Reposition("_mb", 0, 400, 0, 60);
	elseif(position == "top") then
		textWnd:Reposition("_mt", 0, 120, 0, 60);
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
	end
end

-- @param window: attach a mcml v2 window object to it, usually from CodeBlock's window() function
function MacroPlayer.AttachWindow(window)
	if(window) then
		MacroPlayer.ShowController(false);
		local parent = MacroPlayer.GetRootUIObject()
		if(parent) then
			local win = window:GetNativeWindow()
			if(win) then
				MacroPlayer.attachedWnd = window;
				win.zorder = 1000;
				parent:AddChild(win)
				return true
			end
		end
	end
	return false
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
	end
end