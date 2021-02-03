--[[
Title: Macro Keys
Author(s): LiXizhi
Date: 2021/1/4
Desc: 

Use Lib:
-------------------------------------------------------
-------------------------------------------------------
]]
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


local keyMaps = {
	["SLASH"] = "/ ?",
	["MINUS"] = "- _",
	["PERIOD"] = ". >",
	["COMMA"] = ", <",
	["SPACE"] = L"空格",
	["EQUALS"] = "= +",
	["ESCAPE"] = "ESC",
	["DELETE"] = "DEL",
	["LSHIFT"] = "SHIFT",
	["RSHIFT"] = "SHIFT",
	["shift"] = "SHIFT",
	["ctrl"] = "CTRL",
	["LCONTROL"] = "CTRL",
	["RCONTROL"] = "CTRL",
	["BACKSPACE"] = "←---",
	["alt"] = "ALT",
	["LMENU"] = "ALT",
	["RMENU"] = "ALT",
	["UP"] = "↑",
	["DOWN"] = "↓",
	["LEFT"] = "←",
	["RIGHT"] = "→",
	["RETURN"] = L"回车",
	["APOSTROPHE"] = "' \"",
	["LBRACKET"] = "[ {",
	["RBRACKET"] = "] }",
	["SEMICOLON"] = ": ;",
	["GRAVE"] = "` ~",
	["BACKSLASH"] = "\\|",
	["MULTIPLY"] = "*",
	["1"] = "1 !",
	["2"] = "2 @",
	["3"] = "3 #",
	["4"] = "4 $",
	["5"] = "5 %",
	["6"] = "6 ^",
	["7"] = "7 &",
	["8"] = "8 *",
	["9"] = "9 (",
	["0"] = "0 )",
	["WIN_LWINDOW"] = "左Win",
	["WIN_RWINDOW"] = "右win",
	["PAGE_DOWN"] = "PgDn", --  DIK_NUMPAD3
	["PAGE_UP"] = "PgUp", --  DIK_NUMPAD9
	["HOME"] = "HOME", --  DIK_NUMPAD7
	["END"] = "END", -- DIK_NUMPAD1
}

function Macros.ConvertKeyNameToButtonText(btnText)
	if(btnText) then
		btnText = btnText:gsub("DIK_", "")
		btnText = string.upper(btnText);
		btnText = keyMaps[btnText] or btnText;
	end
	return btnText
end

local TextToKeyNameMap = {
	["-"] = "DIK_MINUS",
	["_"] = "shift+DIK_MINUS",
	["/"] = "DIK_SLASH",
	["?"] = "shift+DIK_SLASH",
	["."] = "DIK_PERIOD",
	[">"] = "shift+DIK_PERIOD",
	[","] = "DIK_COMMA",
	["<"] = "shift+DIK_COMMA",
	["="] = "DIK_EQUALS",
	["+"] = "shift+DIK_EQUALS",
	[" "] = "DIK_SPACE",
	["'"] = "DIK_APOSTROPHE",
	["\""] = "shift+DIK_APOSTROPHE",
	["["] = "DIK_LBRACKET",
	["{"] = "shift+DIK_LBRACKET",
	["]"] = "DIK_RBRACKET",
	["}"] = "shift+DIK_RBRACKET",
	[";"] = "DIK_SEMICOLON",
	[":"] = "shift+DIK_SEMICOLON",
	["`"] = "DIK_GRAVE",
	["~"] = "shift+DIK_GRAVE",
	["\\"] = "DIK_BACKSLASH",
	["|"] = "shift+DIK_BACKSLASH",
	["!"] = "shift+DIK_1",
	["@"] = "shift+DIK_2",
	["#"] = "shift+DIK_3",
	["$"] = "shift+DIK_4",
	["%"] = "shift+DIK_5",
	["^"] = "shift+DIK_6",
	["&"] = "shift+DIK_7",
	["*"] = "shift+DIK_8",
	["("] = "shift+DIK_9",
	[")"] = "shift+DIK_0",
}

-- @param text: like "a" or "Z"
-- @return string like "DIK_A" "shift+DIK_Z"
function Macros.TextToKeyName(text)
	local keyname;
	if(text and #text == 1) then
		if(text:match("^[a-z]")) then
			keyname = "DIK_"..text:upper();
		elseif(text:match("^[A-Z]")) then
			keyname = "shift+DIK_"..text;
		elseif(text:match("^%d")) then
			keyname = "DIK_"..text;
		elseif(TextToKeyNameMap[text]) then
			keyname = TextToKeyNameMap[text]
		end
	end
	return keyname
end

local isLetterMap = {
["SLASH"] = true,
["MINUS"] = true,
["PERIOD"] = true,
["COMMA"] = true,
["SPACE"] = true,
["EQUALS"] = true,
["APOSTROPHE"] = true,
["LBRACKET"] = true,
["RBRACKET"] = true,
["SEMICOLON"] = true,
["GRAVE"] = true,
["BACKSLASH"] = true,
["MULTIPLY"] = true,
}
function Macros.IsButtonLetter(button)
	local text = button:match("DIK_(%w+)");
	if(text) then
		if(text:match("^%w$") or isLetterMap[text]) then
			return true;
		end
	end
end