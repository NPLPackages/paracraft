--[[
Title: CodeIntelliSense
Author(s): LiXizhi
Date: 2019/10/19
Desc: 
## Mouse over tips
## Auto complete
- Ctrl+Space to trigger intellisense
- TAB or enter key to select intellisense item
- Up and Down key to move selections
- esc or move cursor to cancel

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeIntelliSense.lua");
local CodeIntelliSense = commonlib.gettable("MyCompany.Aries.Game.Code.CodeIntelliSense");
CodeIntelliSense.Show()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpItem.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeHelpItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpItem");
local CodeIntelliSense = commonlib.gettable("MyCompany.Aries.Game.Code.CodeIntelliSense");


local page;
CodeIntelliSense.items = {};
CodeIntelliSense.selected_code_name = nil;
CodeIntelliSense.word = nil;
CodeIntelliSense.maxCandidates = 100;
CodeIntelliSense.maxDisplayItems = 10;
CodeIntelliSense.candidateIndex = 1;
CodeIntelliSense.displayCandidateIndex = 1;
codeCompleteWidth = 180;
intelliWindowMarginTop = 5;


function CodeIntelliSense.GetItems()
	return CodeIntelliSense.items;
end

local dsItem = {};
function CodeIntelliSense.GetItemsDS()
	local dsOffset = CodeIntelliSense.candidateIndex > CodeIntelliSense.maxDisplayItems and 
		(CodeIntelliSense.candidateIndex-CodeIntelliSense.maxDisplayItems) or 0;
	CodeIntelliSense.displayCandidateIndex = CodeIntelliSense.candidateIndex - dsOffset;
	for i=1, CodeIntelliSense.maxDisplayItems do
		dsItem[i] = CodeIntelliSense.items[i+dsOffset];
	end
	return dsItem;
end

-- return current candidate codeItem 
function CodeIntelliSense.GetCurrentItem()
	local name = CodeIntelliSense.items[CodeIntelliSense.candidateIndex]
	if(name) then
		return CodeHelpWindow.GetCodeItemByFuncName(string.lower(name));
	end
end

function CodeIntelliSense.Init()
	page = document:GetPageCtrl();
end

-- return number of candidates
function CodeIntelliSense.SetWord(word)
	CodeIntelliSense.word = word;
	CodeIntelliSense.candidateIndex = 1;
	if(word == nil) then
		CodeIntelliSense.Clear()
		return 0;
	end
	local allNames = CodeHelpWindow.GetAllFunctionNames()
	word = string.lower(word)
	local text = "^"..word;
	local items = {};
	for funcName, codeItem in allNames:pairs() do
		if(funcName:match(text)) then
			items[#items+1] = codeItem.funcName or funcName;
			if(#items > CodeIntelliSense.maxCandidates) then
				break;
			end
		end
	end
	CodeIntelliSense.items = items;
	return #items;
end

function CodeIntelliSense.GetCount()
	return (#CodeIntelliSense.items);
end

function CodeIntelliSense.Update(textCtrl)
	if(CodeIntelliSense.GetCount() >= 1) then
		local window = CodeIntelliSense.window or System.Windows.Window:new();
		window:Show({url="script/apps/Aries/Creator/Game/Code/CodeIntelliSense.html", alignment="_lt", left=0, top=0, width=codeCompleteWidth, height=300, zorder=11});
		if(CodeIntelliSense.window) then
			CodeIntelliSense.RefreshPage()
		else
			CodeIntelliSense.window = window;
			CodeIntelliSense.ShowTipForCurrentCandidate()
		end
		local layout = window:GetLayout()
		if(layout and layout.GetUsedSize) then
			local width, height = layout:GetUsedSize();
			local x, y = textCtrl:GetCursorPositionInClient()
			y = y + textCtrl:GetLineHeight();
			local point = textCtrl:mapToGlobal(mathlib.Point:new_from_pool(x, y))
			window:setGeometry(point:x(), point:y() + intelliWindowMarginTop, width, height);
		end
	else
		CodeIntelliSense.Close()
	end
end

function CodeIntelliSense.ShowTipForCurrentCandidate()
	if(CodeIntelliSense.textCtrl) then
		local codeItem = CodeIntelliSense.GetCurrentItem()
		if(codeItem) then
			local x, y = CodeIntelliSense.textCtrl:GetCursorPositionInClient()
			x = x + codeCompleteWidth;
			local dsOffset = CodeIntelliSense.candidateIndex - CodeIntelliSense.displayCandidateIndex
			y = y + CodeIntelliSense.textCtrl:GetLineHeight() + (CodeIntelliSense.candidateIndex-dsOffset-1) * 20 + intelliWindowMarginTop;
			local point = CodeIntelliSense.textCtrl:mapToGlobal(mathlib.Point:new_from_pool(x, y))
			CodeIntelliSense.ShowMouseOverFuncTip(codeItem, point:x(), point:y())
		end
	end
end

-- refresh without updating the window position or size
function CodeIntelliSense.RefreshPage()
	if(CodeIntelliSense.window) then
		CodeIntelliSense.window:RefreshUrlComponent()
		CodeIntelliSense.ShowTipForCurrentCandidate()
	end
end

function CodeIntelliSense.Clear()
	if(CodeIntelliSense.GetCount() > 0) then
		CodeIntelliSense.items = {}
	end
	CodeIntelliSense.word = nil;
	CodeIntelliSense.arg_item = nil;
	CodeIntelliSense.cursorPos = nil;
	CodeIntelliSense.candidateIndex = 1;
	CodeIntelliSense.mode = nil;
end

function CodeIntelliSense.Close()
	if(CodeIntelliSense.window) then
		CodeIntelliSense.window:hide();
	end
	CodeIntelliSense.Clear()
	if(CodeIntelliSense.mytimer) then
		CodeIntelliSense.mytimer:Change();
	end
	CodeIntelliSense.requestProcessAutoComplete = false;
	CodeIntelliSense.ShowMouseOverFuncTip(nil)
	CodeIntelliSense.textCtrl = nil;
end

function CodeIntelliSense.StartTimer()
	CodeIntelliSense.mytimer = CodeIntelliSense.mytimer or commonlib.Timer:new({callbackFunc = CodeIntelliSense.OnTick})
	CodeIntelliSense.mytimer:Change(100, 100);
end

-- @return true if processed and has candidates
function CodeIntelliSense.ProcessAutoComplete(textCtrl)
	CodeIntelliSense.textCtrl = textCtrl;
	CodeIntelliSense.requestProcessAutoComplete = true;
	CodeIntelliSense.StartTimer();
end

function CodeIntelliSense.OnTick(timer)
	if(CodeIntelliSense.textCtrl) then
		if(CodeIntelliSense.requestCursorOnBracket) then
			CodeIntelliSense.requestCursorOnBracket = false;
			CodeIntelliSense.CursorOnBracketImp(CodeIntelliSense.textCtrl);
		elseif(CodeIntelliSense.requestProcessAutoComplete) then
			CodeIntelliSense.requestProcessAutoComplete = false;
			CodeIntelliSense.ProcessAutoCompleteImp(CodeIntelliSense.textCtrl);
		end
		-- if cursor changed, we will disable auto completion
		if(CodeIntelliSense.GetCount() > 0 and CodeIntelliSense.cursorPos) then
			local cursorPos = CodeIntelliSense.textCtrl:CursorPos();
			if(cursorPos.pos ~= CodeIntelliSense.cursorPos.pos or cursorPos.line ~= CodeIntelliSense.cursorPos.line) then
				CodeIntelliSense.Close()
			end
		end
	end
end

-- return word from current cursor position going back to previous word separator.
-- the word may contain `.` or ':'
-- @param pos: if nil it will default to textCtrl:CursorPos() {line, pos}
function CodeIntelliSense.GetWordToCursor(textCtrl, pos)
	pos = pos or textCtrl:CursorPos();
	local text = textCtrl:GetLineText(pos.line);
	if(text and pos.pos) then
		local curPos = pos.pos;
		local separatorChar = curPos > 1 and text:substr(curPos, curPos);
		local from,to
		if(separatorChar == "." or separatorChar == ":") then
			from,to = text:wordPosition(curPos-1);
			to = curPos;
		else
			from,to = text:wordPosition(curPos);
		end
		
		if(from and from < to and curPos > from) then
			local word;
			if(from > 1) then
				local separatorChar = text:substr(from, from);
				if(separatorChar == "." or separatorChar == ":") then
					local from2 = text:wordPosition(from-1);
					if(from2 < from) then
						from = from2
					end
				end
			end
			word = text:substr(from+1, curPos);
			return word, from, to;
		end
	end
end

function CodeIntelliSense.ProcessAutoCompleteImp(textCtrl)
	local pos = textCtrl:CursorPos();
	local word = CodeIntelliSense.GetWordToCursor(textCtrl)
	if(CodeIntelliSense.SetWord(word)>0) then
		CodeIntelliSense.cursorPos = pos;
		CodeIntelliSense.mode = "AutoComplete";
		CodeIntelliSense.Update(textCtrl)
		return true
	end
	CodeIntelliSense.Close()
end

function CodeIntelliSense.DoAutoCompleteImp(textCtrl)
	local codeItem = CodeIntelliSense.GetCurrentItem()
	if(codeItem and codeItem.funcName) then
		local pos = textCtrl:CursorPos();
		local text = textCtrl:GetLineText(pos.line);
		local cursorOnBracket
		local word, from, to = CodeIntelliSense.GetWordToCursor(textCtrl)
		if(word) then
			local isProcessed;
			if(codeItem.func_description) then
				if((codeItem.previousStatement and codeItem.nextStatement) or text:length() == to) then
					local code = "";
					local curPos = nil;
					local func_description = codeItem.func_description:gsub("\\n", "\n")
					for text, param in func_description:gmatch("([^%%]+)(%%?%w?)") do
						code = code..text;
						if(not curPos and param~="") then
							curPos = #code;
							if(code:sub(curPos,curPos) == "(") then
								cursorOnBracket = true;
							end
						end
					end
					textCtrl:moveCursor(pos.line, from, false);
					textCtrl:moveCursor(pos.line, to, true);
					textCtrl:InsertTextInCursorPos(code)
					if(curPos) then
						textCtrl:moveCursor(pos.line, from+curPos, false);
						textCtrl:moveCursor(pos.line, from+curPos, true);
					end
					isProcessed = true;
				end
			end
			if(not isProcessed) then
				textCtrl:moveCursor(pos.line, from, false);
				textCtrl:moveCursor(pos.line, to, true);
				textCtrl:InsertTextInCursorPos(codeItem.funcName)
				isProcessed = true;
			end
		end
		CodeIntelliSense.Close()
		if(cursorOnBracket) then
			CodeIntelliSense.CursorOnBracket(textCtrl)
		end
	end
end

function CodeIntelliSense.OnLearnMore()
	local item = CodeIntelliSense.curMouseOverCodeItem or CodeIntelliSense.GetCurrentItem()
	if(item) then
		CodeBlockWindow.ShowHelpWndForCodeName(item.type or "")
		return true;
	end
end

-- @param codeItem: if nil, it will cancel
function CodeIntelliSense.ShowMouseOverFuncTip(codeItem, x, y)
	if(codeItem) then
		local tipUrl = "script/apps/Aries/Creator/Game/Code/CodeHelpItemTooltip.html?IsShortTip=true&name="..codeItem:GetName()
		CodeIntelliSense.hoverTipWindow = CodeIntelliSense.hoverTipWindow or System.Windows.Window:new();
		CodeIntelliSense.hoverTipWindow:Show({url=tipUrl, alignment="_lt", left=0, top=0, width=250, height=300, zorder=10});
		local layout = CodeIntelliSense.hoverTipWindow:GetLayout()
		if(layout and layout.GetUsedSize) then
			local width, height = layout:GetUsedSize();
			if(not x or not y) then
				x, y = ParaUI.GetMousePosition();
				y = y + 32;
			end
			CodeIntelliSense.hoverTipWindow:setGeometry(x, y, width, height);
		end
	elseif(CodeIntelliSense.hoverTipWindow) then
		CodeIntelliSense.hoverTipWindow:hide();
	end
end

-- text control callback
function CodeIntelliSense.OnMouseOverWordChange(word, line, from, to)
	if(word and from<to) then
		if(from > 1) then
			local separatorChar = line:substr(from, from);
			if(separatorChar == "." or separatorChar == ":") then
				local from2 = line:wordPosition(from-1);
				if(from2 < from) then
					from = from2
					word = line:substr(from+1, to);
				end
			end
		end
		local codeItem = CodeHelpWindow.GetCodeItemByFuncName(word)
		if(codeItem) then
			CodeIntelliSense.curMouseOverCodeItem = codeItem;
			CodeIntelliSense.ShowMouseOverFuncTip(codeItem)
			return;
		end
	end
	CodeIntelliSense.curMouseOverCodeItem = nil;
	CodeIntelliSense.ShowMouseOverFuncTip(nil)
end

-- text control callback
function CodeIntelliSense:OnUserKeyPress(textCtrl, event)
	local keyname = event.keyname;
	if(keyname == "DIK_BACKSPACE") then
		local word = CodeIntelliSense.GetWordToCursor(textCtrl)
		if(word) then
			CodeIntelliSense.ProcessAutoComplete(textCtrl);
		end
	elseif(CodeIntelliSense.GetCount() > 0 and not self.shift_pressed and not self.ctrl_pressed) then
		if(keyname == "DIK_RETURN" or keyname == "DIK_TAB") then
			if(CodeIntelliSense.mode == "AutoComplete") then
				CodeIntelliSense.DoAutoCompleteImp(textCtrl)
			elseif(CodeIntelliSense.mode == "CursorOnBracket") then
				CodeIntelliSense.DoCursorOnBracketImp(textCtrl)
			end
			event:accept();
		elseif(keyname == "DIK_UP") then
			if(CodeIntelliSense.candidateIndex > 1) then
				CodeIntelliSense.candidateIndex = CodeIntelliSense.candidateIndex - 1
				CodeIntelliSense.RefreshPage()
			end
			event:accept();
		elseif(keyname == "DIK_DOWN") then
			if(CodeIntelliSense.candidateIndex < CodeIntelliSense.GetCount()) then
				CodeIntelliSense.candidateIndex = CodeIntelliSense.candidateIndex + 1
				CodeIntelliSense.RefreshPage()
			end
			event:accept();
		elseif(keyname == "DIK_ESCAPE") then
			CodeIntelliSense.Close()
			event:accept();
		end
	elseif(event.ctrl_pressed and keyname == "DIK_SPACE") then
		CodeIntelliSense.ProcessAutoComplete(textCtrl);
		event:accept();
	end
end

function CodeIntelliSense.CursorOnBracket(textCtrl)
	CodeIntelliSense.textCtrl = textCtrl;
	CodeIntelliSense.requestCursorOnBracket = true;
	CodeIntelliSense.StartTimer();
end

function CodeIntelliSense.DoCursorOnBracketImp(textCtrl)
	local arg_item = CodeIntelliSense.arg_item;
	local option = arg_item and arg_item.options[CodeIntelliSense.candidateIndex]
	if(option and option[2]) then
		local text = option[2];
		if(arg_item.shadow and arg_item.shadow.type) then
			local item = CodeHelpWindow.GetCodeItemByName(arg_item.shadow.typeOptions or arg_item.shadow.type)
			if(item and item.arg0 and item.arg0[1] and item.arg0[1].options == arg_item.options and item.func_description) then
				text = format(item.func_description, option[2])
			end
		end		
		textCtrl:InsertTextInCursorPos(text)
	end
	CodeIntelliSense.Close()
end

function CodeIntelliSense.CursorOnBracketImp(textCtrl)
	local pos = textCtrl:CursorPos();
	local text = textCtrl:GetLineText(pos.line);
	if(text and pos.pos) then
		local curPos = pos.pos;
		local separatorChar = curPos > 1 and text:substr(curPos, curPos);
		if(separatorChar == "(") then
			local funcName = CodeIntelliSense.GetWordToCursor(textCtrl, {pos = pos.pos-1, line=pos.line})
			local codeItem = CodeHelpWindow.GetCodeItemByFuncName(string.lower(funcName));
			if(codeItem) then
				-- this will force shadow options to be computed
				local html = codeItem:GetHtml(); 
				-- let us only do the first parameter to see if it is a drop down list
				local arg_item = codeItem.arg0 and codeItem.arg0[1];
				if(arg_item) then
					if(arg_item.options) then
						local items = {};
						for i, option in ipairs(arg_item.options) do
							items[i] = option[1];
						end
						CodeIntelliSense.items = items;
						CodeIntelliSense.arg_item = arg_item;
						CodeIntelliSense.candidateIndex = arg_item.selectedIndex or 1;
						CodeIntelliSense.cursorPos = pos;
						CodeIntelliSense.mode = "CursorOnBracket";
						CodeIntelliSense.Update(textCtrl)
					end
				end
			end
		end
	end
end

function CodeIntelliSense:OnUserTypedCode(textCtrl, newChar)
	if(newChar and #newChar == 1) then
		if(newChar == "(") then
			CodeIntelliSense.CursorOnBracket(textCtrl)
			return
		else
			CodeIntelliSense.ProcessAutoComplete(textCtrl)
			return
		end
	end
	CodeIntelliSense.Close()
end