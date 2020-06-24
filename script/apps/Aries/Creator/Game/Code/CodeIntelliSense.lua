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
-- whether to show global variables in code completion. 
CodeIntelliSense.showGlobals = true;
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

local skipNames = {
	["__index"] = true,
	["isa"] = true,
	["_super"] = true,
	["class"] = true,
	-- tricky: follow skipped keywords will avoid hitting enter key twice when typing them
	["do"] = true,
	["then"] = true,
	["end"] = true,
	["nil"] = true,
	["true"] = true,
	["false"] = true,
	["else"] = true,
}

-- @param value: the class object 
local function AddMemberFunctions(value, items, className, separator, memberName)
	if(value and type(value) == "table" and #value == 0) then
		if(memberName and memberName~="") then
			local text = "^"..memberName
			for name, value in pairs(value) do
				if(type(name) == "string" and name:match(text) and not skipNames[name]) then
					if(#items < CodeIntelliSense.maxCandidates) then
						items[#items+1] = className..separator..name;
					else
						break;
					end
				end
			end
		else
			for name, value in pairs(value) do
				if(#items < CodeIntelliSense.maxCandidates) then
					if(type(name) == "string" and not skipNames[name]) then
						items[#items+1] = className..separator..name;
					end
				else
					break;
				end
			end
		end
	end
end

local function AddMemberFunctionsWithMeta(value, items, className, separator, memberName)
	if(value and type(value) == "table" and #value == 0) then
		AddMemberFunctions(value, items, className, separator, memberName)
		-- also parse meta table methods, but just 1 level above
		local metaTable = getmetatable(value)
		local i=0
		while(type(metaTable) == "table" and metaTable.__index ~= value and i<4) do
			value = metaTable.__index
			if(type(value) == "table") then
				AddMemberFunctions(value, items, className, separator, memberName)
				metaTable = getmetatable(value)
			else
				break;
			end
			i = i + 1;
		end
	end
end

local function AddGlobalVariables(globals, items, word)
	if(globals and type(globals) == "table") then
		local text = "^" .. word;
		for name, value in pairs(globals) do
			if(type(name) == "string" and name:match(text) and not skipNames[name]) then
				items[#items+1] = name;
				if(#items > CodeIntelliSense.maxCandidates) then
					break;
				end
			end
		end
	end
end


local function dummyFunc()
end

function CodeIntelliSense.GetSharedAPIGlobals()
	if(CodeIntelliSense.shared_API) then
		return CodeIntelliSense.shared_API;
	end
	local globals = GameLogic.GetCodeGlobal():GetSharedAPI()
	if(globals) then
		local shared_API = {
			math = globals.math,
			bit = globals.bit,
			mathlib = globals.mathlib,
			commonlib = globals.commonlib,
			os = globals.os,
			string = globals.string,
			table = globals.table,
			GameLogic = globals.GameLogic,
			getBlockEntity = globals.getBlockEntity,
			print = dummyFunc,
			printStack = dummyFunc,
			actor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
			codeblock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
		}
		CodeIntelliSense.shared_API = shared_API
		return shared_API;
	else
		return {};
	end
end

-- @param word: "aa", "a.", "b:", "a.c" are all valid names
-- return number of candidates based on word
function CodeIntelliSense.SetWord(word)
	CodeIntelliSense.word = word;
	CodeIntelliSense.candidateIndex = 1;
	if(word == nil or not word:match("^[%w_%.:]+$")) then
		CodeIntelliSense.Clear()
		return 0;
	end
	
	local allNames = CodeHelpWindow.GetAllFunctionNames()
	local text = "^"..string.lower(word);
	
	local items = {};
	for funcName, codeItem in allNames:pairs() do
		if(funcName:match(text) and type(codeItem) == "table") then
			items[#items+1] = codeItem.funcName or funcName;
			if(#items > CodeIntelliSense.maxCandidates) then
				break;
			end
		end
	end
	if(CodeIntelliSense.showGlobals) then
		local globals = GameLogic.GetCodeGlobal():GetCurrentGlobals();
		if(word:match("[%.:]")) then
			if(#items == 0) then
				-- we will also search for global table's member functions if there is no candidates
				local className, separator, memberName = word:match("^([%w%_]+)([%.:])(%S*)$")
				if(className == "_G") then
					-- "_G.a.b" is also supported. 
					local className1, separator1, memberName1 = memberName:match("^([%w%_]+)([%.:])(%S*)$")
					if(className1) then
						local value = globals[className1]
						AddMemberFunctionsWithMeta(value, items, className..separator..className1, separator1, memberName1)
					else
						AddMemberFunctions(globals, items, className, separator, memberName)
					end
				elseif(className) then
					local value = globals[className] or CodeIntelliSense.GetSharedAPIGlobals()[className]
					if(not value) then
						local codeblock = CodeBlockWindow.GetCodeBlock()
						if(codeblock and codeblock:IsLoaded()) then
							value = codeblock:GetCodeEnv()[className];
						end
					end
					for i=1, 5 do
						if(type(value) == "table") then
							-- "a.b.c.d" is also supported.
							local className1, separator1, memberName1 = memberName:match("^([%w%_]+)([%.:])(%S*)$")
							if(className1) then
								value = value[className1]
								className, separator, memberName = className..separator..className1, separator1, memberName1;
							else
								break;
							end
						else
							break;
						end
					end
					AddMemberFunctionsWithMeta(value, items, className, separator, memberName)
				end
			end
		elseif(#items < CodeIntelliSense.maxCandidates) then
			-- also add globals
			AddGlobalVariables(globals, items, word)
			-- also add shared API globals
			AddGlobalVariables(CodeIntelliSense.GetSharedAPIGlobals(), items, word)
			
			-- also add globals in current running code block
			if(#items < CodeIntelliSense.maxCandidates) then
				local codeblock = CodeBlockWindow.GetCodeBlock()
				if(codeblock and codeblock:IsLoaded()) then
					AddGlobalVariables(codeblock:GetCodeEnv(), items, word)
				end
			end
		end
	end
	CodeIntelliSense.sortAndRemoveDuplicates(items)
	CodeIntelliSense.items = items;
	return #items;
end

function CodeIntelliSense.sortAndRemoveDuplicates(items)
	if(#items > 0) then
		table.sort(items, function(a, b)
			return a<b;
		end)
		local i=1;
		while(items[i]) do
			if(items[i] == items[i+1]) then
				table.remove(items, i)
			else
				i = i + 1;
			end
		end
	end
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
				for i=1, 5 do
					local separatorChar = text:substr(from, from);
					if(separatorChar == "." or separatorChar == ":") then
						local from2 = text:wordPosition(from-1);
						if(from2 < from) then
							from = from2
						else
							break;
						end
					else
						break;
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
			if(word == codeItem.funcName and skipNames[word]) then
				return false;
			end
			local isProcessed;
			if(codeItem.func_description) then
				if(text:length() == to or (not codeItem.nextStatement)) then
					local code = "";
					local curPos = nil;
					
					local func_description = codeItem.func_description:gsub("\\n", "\n");
					if(CodeHelpWindow.codeLanguageType == "python" and codeItem.ToPython) then
						func_description = codeItem:ToPython();
					else
						if(func_description:sub(1, #codeItem.funcName) ~= codeItem.funcName) then
							local funcParams = func_description:match("(%(.*)$");
							if(funcParams) then
								func_description = codeItem.funcName..funcParams;
							else
								func_description = codeItem.funcName
							end
							cursorOnBracket = false;
						end
					end

					for text, param in func_description:gmatch("([^%%]+)(%%?%w?)") do
						code = code..text;
						if(not curPos and param~="") then
							curPos = #code;
							if(code:sub(curPos,curPos) == "(") then
								if(cursorOnBracket == nil) then
									cursorOnBracket = true;
								end
							end
						end
					end
				
					textCtrl:moveCursor(pos.line, from, false);
					textCtrl:moveCursor(pos.line, to, true);

					local headingSpaces = textCtrl:GetHeadingSpaces(pos.line)
					if(headingSpaces) then
						code = code:gsub("(\n)(.+)", "%1"..headingSpaces.."%2");
					end
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
		return true;
	else
		local name = CodeIntelliSense.items[CodeIntelliSense.candidateIndex]
		if(name) then
			local pos = textCtrl:CursorPos();
			local text = textCtrl:GetLineText(pos.line);
			local cursorOnBracket
			local word, from, to = CodeIntelliSense.GetWordToCursor(textCtrl)
			if(word) then
				textCtrl:moveCursor(pos.line, from, false);
				textCtrl:moveCursor(pos.line, to, true);
				textCtrl:InsertTextInCursorPos(name)
			end
			CodeIntelliSense.Close()
			return true;
		end
	end
	
end

function CodeIntelliSense.OnLearnMore(textCtrl)
	local item = CodeIntelliSense.curMouseOverCodeItem or CodeIntelliSense.GetCurrentItem()
	if(item) then
		CodeBlockWindow.ShowHelpWndForCodeName(item.type or "")
		return true;
	elseif(textCtrl) then
		local pos = textCtrl:CursorPos()
		local line = textCtrl:GetLineText(pos.line)
		if(line) then
			local from,to = line:wordPosition(pos.pos);
			if(from and from < to) then
				local word = line:substr(from+1, to);
				local codeItem = CodeIntelliSense.GetCodeItemInText(word, line, from, to)
				if(codeItem) then
					CodeBlockWindow.ShowHelpWndForCodeName(codeItem.type or "")
					return true;
				end
			end
		end
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

function CodeIntelliSense.GetCodeItemInText(word, line, from, to)
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
		word = string.lower(word);
		local codeItem = CodeHelpWindow.GetCodeItemByFuncName(word)
		if(codeItem) then
			return codeItem;
		end
	end
end

-- text control callback
function CodeIntelliSense.OnMouseOverWordChange(word, line, from, to)
	CodeIntelliSense.curMouseOverCodeItem = CodeIntelliSense.GetCodeItemInText(word, line, from, to)
	CodeIntelliSense.ShowMouseOverFuncTip(CodeIntelliSense.curMouseOverCodeItem)
end

function CodeIntelliSense.ShowContextMenuForWord(word, line, from, to)
	local curMouseOverCodeItem;
	if(line) then
		curMouseOverCodeItem = CodeIntelliSense.GetCodeItemInText(word, line, from, to)
	end

	
	local ctl = CodeIntelliSense.contextMenuCtrl;
	if(not ctl)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "CodeIntelliSense.contextMenuCtrl",
			width = 230,
			height = 60, -- add menuitemHeight(30) with each new item
			DefaultNodeHeight = 26,
			onclick = CodeIntelliSense.OnClickContextMenuItem,
		};
		CodeIntelliSense.contextMenuCtrl = ctl;
		ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
	end
	local node = ctl.RootNode:GetChild(1);
	if(node) then
		node:ClearAllChildren();
		if(curMouseOverCodeItem) then
			node:AddChild(CommonCtrl.TreeNode:new({Text = format(L"%s 的帮助...".."  F1", word), tag=curMouseOverCodeItem.type, Name = "help", Type = "Menuitem", onclick = nil, }))
			node:AddChild(CommonCtrl.TreeNode:new({Type = "Separator", }));
		end
			
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"裁剪" .. "           Ctrl+ X", Name = "Cut", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"复制" .. "           Ctrl+ C", Name = "Copy", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"粘贴" .. "           Ctrl+ V", Name = "Paste", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Type = "Separator", }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"全选" .. "           Ctrl+ A", Name = "SelectAll", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"撤销" .. "           Ctrl+ Z", Name = "Undo", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"重做" .. "           Ctrl+ Y", Name = "Redo", Type = "Menuitem", onclick = nil, }))
		node:AddChild(CommonCtrl.TreeNode:new({Type = "Separator", }));

		if(word) then
			node:AddChild(CommonCtrl.TreeNode:new({Text = format(L"朗读: %s", word), tag = word, Name = "PronounceIt", Type = "Menuitem", onclick = nil, }))
			if(word:match("^%w+$")) then
				node:AddChild(CommonCtrl.TreeNode:new({Text = format(L"翻译: %s ...", word), tag = word, Name = "Dictionary", Type = "Menuitem", onclick = nil, }))
			end
		end
		ctl.height = (#node) * 26 + 4;
	end

	ctl:Show(mouse_x, mouse_y);
end

function CodeIntelliSense.OnClickContextMenuItem(node)
	local name = node.Name
	if(name == "help") then
		CodeBlockWindow.ShowHelpWndForCodeName(node.tag or "")
	elseif(name == "Cut") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			if (not ctrl:isReadOnly()) then
				ctrl:copy();
				ctrl:del(true);
				ctrl:userTyped(ctrl);
			end
		end
	elseif(name == "Copy") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			ctrl:copy();
		end
	elseif(name == "Paste") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			if (not ctrl:isReadOnly()) then
				ctrl:paste("Clipboard");
				ctrl:userTyped(ctrl);
			end
		end
	elseif(name == "SelectAll") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			ctrl:selectAll();
		end
	elseif(name == "Undo") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			if (not ctrl:isReadOnly()) then
				ctrl:undo();
				ctrl:userTyped(ctrl);
			end
		end
	elseif(name == "Redo") then
		local ctrl = CodeBlockWindow.GetTextControl()
		if(ctrl) then
			if (not ctrl:isReadOnly()) then
				ctrl:redo();
				ctrl:userTyped(ctrl);
			end
		end
	elseif(name == "PronounceIt") then
		GameLogic.RunCommand("/voice ".. node.tag);
	elseif(name == "Dictionary") then
		GameLogic.RunCommand("open", format("https://fanyi.baidu.com/#en/zh/"..node.tag));
	end
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
			local processed;
			if(CodeIntelliSense.mode == "AutoComplete") then
				processed = CodeIntelliSense.DoAutoCompleteImp(textCtrl)
			elseif(CodeIntelliSense.mode == "CursorOnBracket") then
				processed = CodeIntelliSense.DoCursorOnBracketImp(textCtrl)
			end
			if(processed) then
				event:accept();
			end
		elseif(keyname == "DIK_UP") then
			if(CodeIntelliSense.candidateIndex > 1) then
				CodeIntelliSense.candidateIndex = CodeIntelliSense.candidateIndex - 1
				CodeIntelliSense.RefreshPage()
				event:accept();
			end
			
		elseif(keyname == "DIK_DOWN") then
			if(CodeIntelliSense.candidateIndex < CodeIntelliSense.GetCount()) then
				CodeIntelliSense.candidateIndex = CodeIntelliSense.candidateIndex + 1
				CodeIntelliSense.RefreshPage()
				event:accept();
			elseif(CodeIntelliSense.candidateIndex>5) then
				event:accept();
			end
			
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
	return true;
end

function CodeIntelliSense.CursorOnBracketImp(textCtrl)
	local pos = textCtrl:CursorPos();
	local text = textCtrl:GetLineText(pos.line);
	if(text and pos.pos) then
		local curPos = pos.pos;
		local separatorChar = curPos > 1 and text:substr(curPos, curPos);
		if(separatorChar == "(") then
			local funcName = CodeIntelliSense.GetWordToCursor(textCtrl, {pos = pos.pos-1, line=pos.line})
			if(funcName and funcName~="") then
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
	if(newChar and #newChar > 1) then
		CodeIntelliSense.Close()
	end
end