--[[
Title: Macro EditBox
Author(s): LiXizhi
Date: 2021/1/13
Desc: 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
-------------------------------------------------------
]]
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");
local Application = commonlib.gettable("System.Windows.Application");

local ConvertToWebMode = NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/ConvertToWebMode/ConvertToWebMode.lua");

--@param uiName: UI name or uiObject
--@param text: content text
function Macros.EditBox(uiName, text)
	Macros.SetNextKeyPressWithMouseMove(nil, nil);
	local obj = (type(uiName) == "string") and ParaUI.GetUIObject(uiName) or uiName;
	if(obj and obj:IsValid()) then
		obj.text = text or ""
		obj:SetCaretPosition(-1);
		--obj:Focus()
		__onuievent__(obj.id, "onmodify");
	end
	return Macros.Idle();
end

function Macros.EditBoxKeyup(uiName, keyname)
	Macros.SetNextKeyPressWithMouseMove(nil, nil);
	local obj = (type(uiName) == "string") and ParaUI.GetUIObject(uiName) or uiName;
	if(obj and obj:IsValid()) then
		local vKey = keyname:gsub("DIK_", "EM_KEY_");
		if(Event_Mapping[vKey]) then
			virtual_key = Event_Mapping[vKey];
			__onuievent__(obj.id, "onkeyup");
		end
	end
	return Macros.Idle();
end

-- return text - lastText.  or nil if text does not begin with lastText
local function GetTextDiff(text, lastText)
	local diff;
	if(lastText and text) then
		if(text:sub(1, #(lastText)) == lastText) then
			diff = text:sub(#(lastText)+1, -1);
		end
	end
	if(diff~="") then
		return diff;
	end
end

--@param uiName: UI name
--@param text: content text
function Macros.EditBoxTrigger(uiName, text)
	if (not text or text == "") then
		return;
	end

	local obj = (type(uiName) == "string") and ParaUI.GetUIObject(uiName) or uiName;

	if (obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local mouseX = math.floor(x + width /2)
		local mouseY = math.floor(y + height /2)
		ParaUI.SetMousePosition(mouseX, mouseY);
		obj:SetCaretPosition(-1);

		-- get final text in editbox
		local nOffset = 0;
		local targetText = text;

		while (true) do
			nOffset = nOffset + 1;
			local nextMacro = Macros:PeekNextMacro(nOffset);

			if (nextMacro and
				(nextMacro.name == "Idle" or
				 nextMacro.name == "EditBoxTrigger" or
				 nextMacro.name == "EditBox" or
				 nextMacro.name == "EditBoxKeyupTrigger" or
				 nextMacro.name == "EditBoxKeyup")) then
				if(nextMacro.name ~= "Idle") then
					local nextUIName = nextMacro:GetParams()[1];
					if (nextUIName == uiName) then
						if(nextMacro.name == "EditBox") then
							targetText = nextMacro:GetParams()[2];
						end
					else
						break;
					end
				end
			else
				break;
			end
		end

		if(text == obj.text) then
			-- skip if equal
			if (Macros.GetHelpLevel() == -2) then
				ConvertToWebMode.isEditboxTriggerStarted = false;

				ConvertToWebMode:StopComputeRecordTime();

				local macro = Macros.macros[Macros.curLine];

				if (macro) then
					macro.processTime = ConvertToWebMode.processTime;
				end
			end
			return Macros.Idle();
		else
			local textDiff = GetTextDiff(text, obj.text) or "";
			local callback = {};

			local macro = Macros:GetMacroByIndex(Macros.curLine);
			local isSkip = false;

			-- ignore chinese.
			if (macro and
				macro.params and
				type(macro.params) == "table" and
				type(macro.params[2]) == "string" and
				macro.params[2]:match("[^%w %p]+")) then
				isSkip = true;
			end

			-- ignore backspace key.
			local nOffset = 0;

			while (true) do
				nOffset = nOffset + 1;
				local nextMacro = Macros:PeekNextMacro(nOffset);

				if (nextMacro) then
					if (nextMacro.name == "EditBoxTrigger" or
						nextMacro.name == "EditBox" or
						nextMacro.name == "Idle") then
						if (nextMacro.name == "EditBoxTrigger") then	
							if (macro:GetParams()[1] == nextMacro:GetParams()[1]) then
								if (nextMacro:GetParams()[2] and
									type(nextMacro:GetParams()[2]) == "string" and
									macro:GetParams()[2] and
									type(macro:GetParams()[2]) == "string" and
									macro:GetParams()[2]:match(nextMacro:GetParams()[2]) and
									#nextMacro:GetParams()[2] <= #macro:GetParams()[2]) then
									isSkip = true;
									break;
								else
									break;
								end
							end
						end
					else
						break;
					end
				else
					break;
				end
			end

			local function MacroEditBoxTrigger(bCutted)
				if (Macros.GetHelpLevel() == -2 and
					ConvertToWebMode.isEditboxTriggerStarted and
					not isSkip) then
					ConvertToWebMode.StopComputeRecordTime();

					local macro = Macros.macros[Macros.curLine];

					if (macro) then
						if (textDiff == " ") then
							textDiff = "SPACE";
						end

						local dikK = "DIK_" .. textDiff:upper();

						MacroPlayer.ShowKeyboard(true, dikK);

						if (MacroPlayer.page.keyboardWnd and
							MacroPlayer.page.keyboardWnd.keylayout) then
							for key, item in ipairs(MacroPlayer.page.keyboardWnd.keylayout) do
								for keyI, itemI in ipairs(item) do
									if (itemI and
										type(itemI) == "table" and
										itemI.name) then
										local keyName;
										
										if (itemI.char) then
											keyName = Macros.TextToKeyName(itemI.char);
										end

										if (not keyName) then
											local keyUpperName = itemI.name:upper();

											if (keyUpperName == "TAB") then
												keyName = "DIK_TAB";
											elseif (keyUpperName == "ENTER") then
												keyName = "DIK_RETURN";
											end
										end

										if (keyName == dikK) then
											local macro = Macros.macros[Macros.curLine];

											if (macro) then
												macro.mousePosition = {
													posX = itemI.pos_x,
													posY = itemI.pos_y
												};
											end

											break;
										end
									end
								end
							end
						end

						MacroPlayer.ShowKeyboard(false);

						macro.processTime = ConvertToWebMode.processTime;
					end
				end

				MacroPlayer.SetEditBoxTrigger(mouseX, mouseY, targetText, textDiff, function()
					if (Macros.GetHelpLevel() == -2 and
						ConvertToWebMode.isEditboxTriggerStarted and
						not isSkip) then
						local nextNextLine = Macros.macros[Macros.curLine + 2];

						if (nextNextLine and
							nextNextLine.name ~= "Broadcast" and
							nextNextLine.params ~= "macroFinished") then
							commonlib.TimerManager.SetTimeout(function()
								if (bCutted) then
									ConvertToWebMode:StopCapture();
									ConvertToWebMode:StartComputeRecordTime();
									ConvertToWebMode:StartComputeDuringTime();
									ConvertToWebMode:BeginCapture(function()
										callback.OnFinish();
									end);
								else
									ConvertToWebMode:StopComputeDuringTime();

									local macro = Macros.macros[Macros.curLine];

									if (macro) then
										macro.duringTime = ConvertToWebMode.duringTime;
									end

									ConvertToWebMode:StartComputeDuringTime();
									ConvertToWebMode:StartComputeRecordTime();
	
									if (callback.OnFinish) then
										callback.OnFinish();
									end
								end
							end, 3000);
						else
							if (callback.OnFinish) then
								callback.OnFinish();
							end
						end
					else
						if (callback.OnFinish) then
							callback.OnFinish();
						end
					end
				end);
			end

			if (Macros.GetHelpLevel() == -2 and not isSkip) then
				if (not ConvertToWebMode.isEditboxTriggerStarted) then
					-- start record.
					ConvertToWebMode.isEditboxTriggerStarted = true;
					MacroEditBoxTrigger(true);
				else
					MacroEditBoxTrigger();
				end
			else
				MacroEditBoxTrigger();
			end

			return callback;
		end
	end
end

--@param uiName: UI name or ui object
--@param text: content text
function Macros.EditBoxKeyupTrigger(uiName, keyname)
	if (keyname == "DIK_RETURN") then
		-- we will only trigger the enter key
		local obj = (type(uiName) == "string") and ParaUI.GetUIObject(uiName) or uiName;

		if (obj and obj:IsValid()) then
			local x, y, width, height = obj:GetAbsPosition();
			local mouseX = math.floor(x + width /2);
			local mouseY = math.floor(y + height /2);

			ParaUI.SetMousePosition(mouseX, mouseY);
			obj:SetCaretPosition(-1);

			-- Macros.SetNextKeyPressWithMouseMove(mouseX, mouseY);
			Macros.SetNextKeyPressWithMouseMove(nil, nil);
			return Macros.KeyPressTrigger(keyname);
		end
	end
end

function Macros.TextAreaDragEnd(fromUiName, textAreaUiName, code, bForceNewLine, line, pos)
	local textCtl = Application.GetUIObject(textAreaUiName);
	if(textCtl) then
		if(textCtl.Name == "MultiLineEditbox") then
			textCtl = textCtl:ViewPort() or textCtl;
		end
		if(textCtl.moveCursor) then
			textCtl:moveCursor(line, pos, false, true);
			textCtl:DropTextAtCurrentLine(code, bForceNewLine)
		end
	end
end

function Macros.TextAreaDragEndTrigger(fromUiName, textAreaUiName, code, bForceNewLine, line, pos)
	local obj = ParaUI.GetUIObject(fromUiName)
	local textCtl = Application.GetUIObject(textAreaUiName);
	if(textCtl and obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local startX = math.floor(x + width / 2 + 0.5);
		local startY = math.floor(y + height / 2 + 0.5);

		local offsetX, offsetY = 0, 0;
		local ctlX, ctlY, ctlWidth, ctlHeight;
		if(textCtl.Name == "MultiLineEditbox") then
			offsetX = textCtl:ViewRegionOffsetX();
			offsetY = textCtl:ViewRegionOffsetY();
			ctlX, ctlY, ctlWidth, ctlHeight = textCtl:GetAbsPosition();
			textCtl = textCtl:ViewPort() or textCtl;
		else
			ctlX, ctlY, ctlWidth, ctlHeight = textCtl:GetAbsPosition();
		end
		
		-- we shall adjustCursor() so that line, pos are always visible. 
		textCtl:moveCursor(line, pos, false, true);
		
		local cursorX, cursorY = textCtl:LinePosToXY(line, pos)
		cursorX, cursorY = ctlX + cursorX + offsetX, ctlY + cursorY + math.floor(textCtl:GetLineHeight()*0.5) + offsetY;

		local endX = math.min(math.max(cursorX, ctlX + 16), ctlX + ctlWidth - 16);
		local endY = math.min(math.max(cursorY, ctlY + 16), ctlY + ctlHeight - 16);
	
		offsetX, offsetY = endX - x, endY - y;
		return Macros.ContainerDragEndTrigger(fromUiName, offsetX, offsetY)
	end
end





