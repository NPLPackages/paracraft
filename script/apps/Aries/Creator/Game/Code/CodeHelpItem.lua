--[[
Title: CodeHelpItem
Author(s): LiXizhi
Date: 2018/6/7
Desc: input format naming is kind of compatible with google blockly. Because we need to rewrite the help code in google blockly anyway.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpItem.lua");
local CodeHelpItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpItem");
local item = CodeHelpItem:new({
	type = "say", 
	message0 = L"说 %1 持续 %2 秒",
	arg0 = {
		{
			name = "text",
			type = "field_input",
			text = L"hello!", 
		},
		{
			name = "duration",
			type = "field_number",
			text = 2, 
		},
	},
	category = "Motion", 
	helpUrl = "", 
	canRun = true, -- when we allow users to tes run ToNPL() code
	ToNPL = function(self)
		return string.format('say("%s", %d);\n', self:getFieldValue('text'), self:getFieldValue('duration'));
	end,
}):Init();
-------------------------------------------------------
]]
local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");

local CodeHelpItem = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpItem"));
function CodeHelpItem:ctor()
	self.all_fields = self.all_fields or {};
end

function CodeHelpItem:Init()
	local lineNumber = 0;
	local message = self["message"..lineNumber];
	while(message) do
		local arguments = self["arg"..lineNumber];
		if(arguments) then
			local all_fields = self.all_fields;
			for argIndex, arg in ipairs(arguments) do
				all_fields[arg.name] = arg;
				arg.argIndex = argIndex;
			end
		end
		lineNumber = lineNumber + 1;
		message = self["message"..lineNumber];
	end
	return self;
end

function CodeHelpItem:ResetCache()
	self.html = nil;
	self.npl_code = nil;
	self.dsItem = nil;
end

-- get an html presentation of the code item 
function CodeHelpItem:GetHtml()
	if(self.html) then
		return self.html;
	end
	local lineNumber = 0;
	local message = self["message"..lineNumber];
	local lines = "";
	while(message) do
		local line = message;
		
		local bContinue = true;
		while(bContinue) do
			bContinue = false;
			local arg_index = string.match(line, "^[^%%]*%%(%d)");
			if(arg_index) then
				local arguments = self["arg"..lineNumber];
				local arg_item = arguments[tonumber(arg_index)];
				if(arg_item) then
					local item_text = arg_item.text;
					if(type(item_text) == "function") then
						item_text = item_text();
					end
					local arg_text = "";
					if(arg_item.shadow and arg_item.shadow.type and not arg_item.options) then
						local item = CodeHelpData.GetItemByType(arg_item.shadow.type)
						if(item and item.arg0 and item.arg0[1]) then
							arg_item.options = item.arg0[1].options;
						end
					end

					if(arg_item.type == "field_input") then
						arg_text = format('<div style="float:left;margin:3px;line-height:12px;font-size:bold;background-color:#ffffff;color:#000000;">%s</div>', item_text or "");
					elseif(arg_item.type == "input_value") then
						if(arg_item.options) then
							arg_item.selectedIndex = arg_item.selectedIndex or 1;
							item_text = tostring(arg_item.options[arg_item.selectedIndex][1]);
							arg_item.text = tostring(arg_item.options[arg_item.selectedIndex][2]);
							arg_text = format('<input type="button" name="%s" onclick="MyCompany.Aries.Game.Code.CodeHelpItem.OnClickDropDown" class="mc_button_grey" style="margin:2px;font-size:12px;height:16px;" value="%s" />', self.type.."_"..tostring(arg_index), item_text);
						elseif(not item_text or item_text=="") then
							arg_text = '<div style="float:left;margin:3px;background-color:#ffffff;color:#000000;width:5px;height:12px"></div>';
						else
							arg_text = format('<div style="float:left;margin:3px;line-height:12px;font-size:bold;background-color:#ffffff;color:#000000;">%s</div>', item_text or "");
						end
					elseif(arg_item.type == "field_variable") then
						if(arg_item.options) then
							arg_item.selectedIndex = arg_item.selectedIndex or 1;
							item_text = tostring(arg_item.options[arg_item.selectedIndex][1]);
							arg_item.text = tostring(arg_item.options[arg_item.selectedIndex][2]);
							arg_text = format('<input type="button" name="%s" onclick="MyCompany.Aries.Game.Code.CodeHelpItem.OnClickDropDown" class="mc_button_grey" style="margin:2px;font-size:12px;height:16px;" value="%s" />', self.type.."_"..tostring(arg_index), item_text);
						else
							arg_text = format('<div style="float:left;margin:3px;line-height:12px;font-size:bold;background-color:#ffffff;color:#000000;">%s</div>', arg_item.variable or item_text or "");	
						end
					elseif(arg_item.type == "field_dropdown") then
						arg_item.selectedIndex = arg_item.selectedIndex or 1;
						item_text = tostring(arg_item.options[arg_item.selectedIndex][1]);
						arg_item.text = tostring(arg_item.options[arg_item.selectedIndex][2]);
						arg_text = format('<input type="button" name="%s" onclick="MyCompany.Aries.Game.Code.CodeHelpItem.OnClickDropDown" class="mc_button_grey" style="margin:2px;font-size:12px;height:16px;" value="%s" />', self.type.."_"..tostring(arg_index), item_text);
					elseif(arg_item.type == "field_number") then
						arg_text = format('<div style="float:left;margin:3px;line-height:12px;font-size:bold;background-color:#80ff80;color:#000000;">%s</div>', tostring(item_text or 0));
					elseif(arg_item.type == "input_statement") then
						arg_text = format('<div style="margin:5px;background-color:#cec8a8;width:80px;height:10px;padding-left:5px;">%s</div>', tostring(item_text or ""));
					elseif(arg_item.type == "input_expression"  or arg_item.type == "expression") then
						arg_text = format('<div style="float:left;min-width:25px;height:14px;margin:3px;background-color:#80ff80;color:#000000;">%s</div>', tostring(item_text or ""));
					elseif(arg_item.type == "input_dummy") then
						arg_text = "";
					else
						arg_text = format('<span style="font-weight:bold">arg%d<span>', arg_index);
					end
					line = string.gsub(line, "^([^%%]*)(%%%d)", "%1"..arg_text);
					bContinue = true;
				end
			end
		end
		lines = lines..line;
		lineNumber = lineNumber + 1;
		message = self["message"..lineNumber];
	end
	if(lines == "") then
		lines = self.type;
	end

	self.html = lines;
	return self.html;
end

function CodeHelpItem:AddExample(example, index)
	self.examples = self.examples or {};
	self.examples[#self.examples+1] = example;
end

function CodeHelpItem:getFieldValue(name)
	if(self.all_fields[name]) then
		local text = self.all_fields[name].text;
		if(type(text) == "function") then
			return text();
		else
			return text;
		end
	else
		return name;
	end
end

function CodeHelpItem:getFieldAsString(name)
	return tostring(self:getFieldValue(name) or "");
end

-- @return "" if no code is generated
function CodeHelpItem:GetNPLCode()
	if(self.npl_code) then
		return self.npl_code;
	end
	local npl_code = ""
	if(self.ToNPL) then
		npl_code = (self:ToNPL() or "");
	end
	self.npl_code = npl_code;
	return npl_code;
end

function CodeHelpItem:CopyNPLCodeToClipboard()
	local code = self:GetNPLCode();
	if(code) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
		local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
		MovieUISound.PlayAddKey();
		ParaMisc.CopyTextToClipboard(code);
	end
end

function CodeHelpItem:GetNPLCodeLineCount()
	if(not self.npl_code_lines) then
		local code = self:GetNPLCode();
		local nLineCount = 0;
		for _ in string.gfind(code or "", "[^\n]+") do
			nLineCount = nLineCount + 1;
		end
		self.npl_code_lines = nLineCount;
	end
	return self.npl_code_lines;
end

function CodeHelpItem:GetColor()
	if(self.color) then
		return self.color;
	else
		return self:HasOutput() and "#ff6a00" or "#4a6cd4";
	end
end

function CodeHelpItem:GetName()
	return self.type;
end

function CodeHelpItem:CanRun()
	return self.canRun;
end

function CodeHelpItem:GetNPLCodeExample()
	if(self.examples) then
		local example = self.examples[1];
		return example and example.code;
	end
end

function CodeHelpItem:CanRunExample()
	if(self.examples) then
		local example = self.examples[1];
		return example and example.canRun;
	end
end

function CodeHelpItem:GetTooltip()
	return "page://script/apps/Aries/Creator/Game/Code/CodeHelpItemTooltip.html?name="..self:GetName();
end

function CodeHelpItem:HasOutput()
	return self.output;
end

function CodeHelpItem:GetNPLCodeExamples()
	if(not self.codeExamples) then
		self.codeExamples = "";
		if(self.examples) then
			local out = {};
			for i, example in ipairs(self.examples) do
				if(example.code) then
					out[#out + 1] = "-- ";
					out[#out + 1] = format(L"例子%d:", i);
					if(example.desc and example.desc~="") then
						out[#out + 1] = example.desc;
					end
					if(not example.code:match("^\r?\n")) then
						out[#out + 1] = "\n";
					end
					out[#out + 1] = example.code;
					if(not example.code:match("\n$")) then
						out[#out + 1] = "\n";
					end
				end
			end
			self.codeExamples = self.codeExamples .. table.concat(out, "");
		end
	end
	return self.codeExamples;
end

-- for use in mcml page's datasource
function CodeHelpItem:GetDSItem()
	if(not self.dsItem) then
		self.dsItem = {name=self:GetName(), html = self:GetHtml(), color = self:GetColor(), nplcode = self:GetNPLCode(), tooltip=self:GetTooltip()};
	end
	return self.dsItem;
end

function CodeHelpItem.OnClickDropDown(name, mcmlNode)
	local itemType, argIndex = name:match("^(.*)_(%d)$");
	if(itemType and argIndex) then
		argIndex = tonumber(argIndex);
		local self = CodeHelpData.GetItemByType(itemType)
		if(self) then
			local arg_item = self.arg0[argIndex];
			if(arg_item) then
				if(arg_item.options) then
					CodeHelpItem.curDropDownDS = arg_item.options;
					CodeHelpItem.curDropDownSelectedIndex = arg_item.selectedIndex;
					local x, y, width, height = mcmlNode:GetControl():GetAbsPosition();
					self:ShowArgumentDropDownWnd(x+width, y, function(result)
						if(result and result~=arg_item.selectedIndex) then
							arg_item.selectedIndex = result;
							self:SetArgumentText(argIndex, arg_item.options[arg_item.selectedIndex][1], mcmlNode);
						end
					end)
				end
			end
		end
	end
end

function CodeHelpItem:SetArgumentText(argIndex, text, mcmlNode)
	local arg_item = self.arg0[argIndex];
	if(arg_item) then
		arg_item.text = text;
		self:ResetCache();
		if(mcmlNode) then
			mcmlNode:GetPageCtrl():Refresh(0.01);
		end
	end
end

function CodeHelpItem:ShowArgumentDropDownWnd(x, y, callbackFunc)
	local params = {
			url = "script/apps/Aries/Creator/Game/Code/CodeArgumentDropDown.html", 
			name = "CodeHelpItem.DropDown.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_lt",
				x = x,
				y = y,
				width = 400,
				height = 200,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(callbackFunc) then
			callbackFunc(CodeHelpItem.curDropDownSelectedIndex);
		end
	end
	local used_width, used_height = params._page:GetUsedSize();
	params._page:GetWindow():MoveWindow(x, y, used_width, used_height);
end

function CodeHelpItem.GetCurrentDropDownIndex()
	return CodeHelpItem.curDropDownSelectedIndex;
end

function CodeHelpItem.GetCurrentDropDownDS()
	return CodeHelpItem.curDropDownDS;
end

function CodeHelpItem.OnClickSelectDropDown(index)
	CodeHelpItem.curDropDownSelectedIndex = index;
end