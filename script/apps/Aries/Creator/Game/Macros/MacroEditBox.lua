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
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


--@param uiName: UI name
--@param text: content text
function Macros.EditBox(uiName, text)
	Macros.SetNextKeyPressWithMouseMove(nil, nil);
	local obj = ParaUI.GetUIObject(uiName)
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
	local obj = ParaUI.GetUIObject(uiName)
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
	if(not text or text == "") then
		return;
	end
	local obj = ParaUI.GetUIObject(uiName)
	if(obj and obj:IsValid()) then
		local x, y, width, height = obj:GetAbsPosition();
		local mouseX = math.floor(x + width /2)
		local mouseY = math.floor(y + height /2)
		ParaUI.SetMousePosition(mouseX, mouseY);
		obj:SetCaretPosition(-1);
		

		-- get final text in editbox
		local nOffset = 0;
		local targetText = text;
		while(true) do
			nOffset = nOffset + 1;
			local nextMacro = Macros:PeekNextMacro(nOffset)
			if(nextMacro and (nextMacro.name == "Idle" or nextMacro.name == "EditBoxTrigger" or nextMacro.name == "EditBox"
				or nextMacro.name == "EditBoxKeyupTrigger" or nextMacro.name == "EditBoxKeyup")) then
				if(nextMacro.name ~= "Idle") then
					local nextUIName = nextMacro:GetParams()[1];
					if(nextUIName == uiName) then
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
			return Macros.Idle();
		else
			local textDiff = GetTextDiff(text, obj.text);
			local callback = {};
			MacroPlayer.SetEditBoxTrigger(mouseX, mouseY, targetText, textDiff, function()
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end);
			return callback;
		end
	end
end

--@param uiName: UI name
--@param text: content text
function Macros.EditBoxKeyupTrigger(uiName, keyname)
	if(keyname == "DIK_RETURN") then
		-- we will only trigger the enter key
		local obj = ParaUI.GetUIObject(uiName)
		if(obj and obj:IsValid()) then
			local x, y, width, height = obj:GetAbsPosition();
			local mouseX = math.floor(x + width /2)
			local mouseY = math.floor(y + height /2)
			ParaUI.SetMousePosition(mouseX, mouseY);
			obj:SetCaretPosition(-1);
		
			-- Macros.SetNextKeyPressWithMouseMove(mouseX, mouseY);
			Macros.SetNextKeyPressWithMouseMove(nil, nil);
			return Macros.KeyPressTrigger(keyname)
		end
	end
end






