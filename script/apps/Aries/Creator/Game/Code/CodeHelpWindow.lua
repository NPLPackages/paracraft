--[[
Title: CodeHelpWindow
Author(s): LiXizhi
Date: 2018/5/22
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
CodeHelpWindow.Show(true)
CodeHelpWindow.SetLanguageConfigFile(filename)
-- or use following
CodeHelpWindow.ClearAll()
CodeHelpWindow.SetCategories(langConfig.GetCategoryButtons())
CodeHelpWindow.SetAllCmds(langConfig.GetAllCmds());
CodeHelpWindow.AddCodeExamples()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpItem.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeHelpItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpItem");
local CodeHelpWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow"));

local page;
-- this is singleton class
local self = CodeHelpWindow;

CodeHelpWindow.category_index = 1;
CodeHelpWindow.categories = default_categories;

---------------------
-- CodeHelpWindow
---------------------
local page;
CodeHelpWindow.currentItems = {};
CodeHelpWindow.selected_code_name = nil;
local category_items = {};
local all_command_names = {};
local languageConfigFile = "";

-- public:
-- see also: https://github.com/NPLPackages/paracraft/wiki/languageConfigFile
function CodeHelpWindow.SetLanguageConfigFile(filename)
	if(languageConfigFile ~= (filename or "")) then
		languageConfigFile = filename;
		CodeHelpWindow.category_index = 1;
		CodeHelpWindow.ClearAll();
		CodeHelpWindow.InitCmds();
		CodeHelpWindow.OnChangeCategory(nil, true);
	end
end

function CodeHelpWindow.GetLanguageConfigFile()
	return languageConfigFile;
end

function CodeHelpWindow.ClearAll()
	CodeHelpWindow.cmdInited = nil;
	category_items = {};
	all_command_names = {};
	CodeHelpWindow.categories = {};
	CodeHelpWindow.currentItems = {};
	CodeHelpWindow.selected_code_name = nil;
end

-- public:
function CodeHelpWindow.SetCategories(categories)
	CodeHelpWindow.categories = categories;
end

function CodeHelpWindow.InitCmds()
	if(not CodeHelpWindow.cmdInited) then
		CodeHelpWindow.cmdInited = true;
		local filename = CodeHelpWindow.GetLanguageConfigFile()
		LOG.std(nil, "info", "CodeHelpWindow", "code block language configuration file changed to %s", filename == "" and "default" or filename);

		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
		local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");

		
		local langConfig = LanguageConfigurations:LoadConfigByFilename(filename)
		if(langConfig) then
			if(CodeHelpWindow.lastLangConfig and CodeHelpWindow.lastLangConfig~=langConfig) then
				if(CodeHelpWindow.lastLangConfig.OnDeselect) then
					CodeHelpWindow.lastLangConfig.OnDeselect();
				end
			end

			if (langConfig.GetCategoryButtons) then
				CodeHelpWindow.SetCategories(langConfig.GetCategoryButtons())
			end
			if (langConfig.GetAllCmds) then
				CodeHelpWindow.SetAllCmds(langConfig.GetAllCmds());
			end
			if (langConfig.GetCodeExamples) then
				CodeHelpWindow.AddCodeExamples(langConfig.GetCodeExamples());
			end
			
			CodeHelpWindow.lastLangConfig = langConfig;
			if(langConfig.OnSelect) then
				langConfig.OnSelect();
			end
		end
	end
end

-- public: 
function CodeHelpWindow.SetAllCmds(all_cmds)
	CodeHelpWindow.all_cmds = all_cmds;
	CodeHelpWindow.AddCodeHelpItems(all_cmds);
end

function CodeHelpWindow.AddCodeHelpItems(all_cmds)
	for _, cmd in ipairs(all_cmds) do
		CodeHelpWindow.AddCodeHelpItem(cmd)
	end
end

function CodeHelpWindow.AddCodeHelpItem(codeHelpItem)
	local items = category_items[codeHelpItem.category];
	if(not items) then
		items = {};
		category_items[codeHelpItem.category] = items;
	end
	local item = CodeHelpItem:new(codeHelpItem):Init();
	if(not item.hide_in_toolbox) then
		items[#items+1] = item;
	end
	all_command_names[item:GetName()] = item;
end

function CodeHelpWindow.AddCodeExamples(examples)
	for _, example in ipairs(examples) do
		CodeHelpWindow.AddCodeExample(example)
	end
end

function CodeHelpWindow.AddCodeExample(example)
	for index, name in ipairs(example.references) do
		local item = CodeHelpWindow.GetCodeItemByName(name);
		if(item) then
			item:AddExample(example, index);
		end
	end
end

function CodeHelpWindow.GetCodeItemByName(name)
	return all_command_names[name];
end

function CodeHelpWindow.OnInit()
	page = document:GetPageCtrl();
	CodeHelpWindow.InitCmds();
	CodeHelpWindow.OnChangeCategory(nil, false);
end

-- show code block window at the right side of the screen
-- @param bShow:
function CodeHelpWindow.Show(bShow)
end

function CodeHelpWindow.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function CodeHelpWindow.GetCategoryButtons()
	return CodeHelpWindow.categories;
end

function CodeHelpWindow.GetAllCmds()
	return CodeHelpWindow.all_cmds
end

function CodeHelpWindow.GetCurrentItems()
	return CodeHelpWindow.currentItems;
end

function CodeHelpWindow.GetSelectionName()
	return CodeHelpWindow.selected_code_name;
end

function CodeHelpWindow.SetSelectionName(name)
	CodeHelpWindow.selected_code_name = name;
end

-- @param bRefreshPage: false to stop refreshing the page
function CodeHelpWindow.OnChangeCategory(index, bRefreshPage)
    CodeHelpWindow.category_index = index or CodeHelpWindow.category_index;
	local category = CodeHelpWindow.GetCategoryButtons()[CodeHelpWindow.category_index];
	if(category) then
		CodeHelpWindow.category_name = category.name;
		CodeHelpWindow.currentItems = category_items[category.name] or {};
	end

	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

function CodeHelpWindow.RunSampleCodeByName(name)
	local item = CodeHelpWindow.GetCodeItemByName(name);
	if(item and item:CanRun()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
		local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
		CodeBlockWindow.RunTempCode(item:GetNPLCode(), item:GetName().."_sample");
	end
end

function CodeHelpWindow.RunSampleCodeExampleByName(name)
	local item = CodeHelpWindow.GetCodeItemByName(name);
	if(item and item:CanRunExample()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
		local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
		CodeBlockWindow.RunTempCode(item:GetNPLCodeExample(), item:GetName().."_example");
	end
end



local global_data = {};
function CodeHelpWindow.RefreshGlobalDataDs()
	global_data = {};
	local globals = GameLogic.GetCodeGlobal():GetCurrentGlobals();
	for name, value in pairs(globals) do
		global_data[#global_data+1] = {name=name, datatype = type(value)};
	end
	table.sort(global_data, function(a, b)
		return a.name < b.name;
	end)
	return CodeHelpWindow.GetGlobalDataDs();
end

function CodeHelpWindow.GetGlobalDataDs()
	return global_data;
end

function CodeHelpWindow.GetGlobalValueAsString(name)
	local value = GameLogic.GetCodeGlobal():GetCurrentGlobals()[name];
	return commonlib.serialize_in_length(value, 100);
end

function CodeHelpWindow.OnClickDataItem(name)
	local value = CodeHelpWindow.GetGlobalValueAsString(name);
	if(value) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
		local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
		CodeBlockWindow.SetConsoleText(format("%s:\n%s", name, value or ""));
	end
end

function CodeHelpWindow.OnCreateVariable()
	if(mouse_button == "left") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(L"创建全局变量", function(result)
			if(result and result:match("%w")) then
				GameLogic.GetCodeGlobal():GetCurrentGlobals()[result] = "";
			end
			CodeHelpWindow.RefreshGlobalDataDs();
			CodeHelpWindow.RefreshPage();
		end, "")
	elseif(mouse_button == "right") then
		CodeHelpWindow.RefreshGlobalDataDs();
		CodeHelpWindow.RefreshPage();
	end
end

function CodeHelpWindow.OnDragEnd(name)
	local item = CodeHelpWindow.GetCodeItemByName(name);
	if(item) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
		local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
		if(CodeBlockWindow.IsMousePointerInCodeEditor()) then
			if(CodeBlockWindow.IsBlocklyEditMode()) then
				_guihelper.MessageBox(L"图块模式下不能直接编辑代码, 请用图块编辑器");
			else
				CodeBlockWindow.InsertCodeAtCurrentLine(item:GetNPLCode(), not item:HasOutput());
			end
		end
	end
end

-- only used for paracraft book. 
function CodeHelpWindow.GenerateWikiDocs(bSilent)
	CodeHelpWindow.InitCmds()
	local docs = {};
	local categories = CodeHelpWindow.GetCategoryButtons()
	for i=1, #categories do
		local category = categories[i];
		if(category) then
			docs[#docs+1] = "### "..category.text;
			docs[#docs+1] = "\n"

			local items = category_items[category.name];
			if(items) then
				for i=1, #items do
					local item = items[i];
					local dsItem = item:GetDSItem();
					if(dsItem) then
						local code = item and item:GetNPLCode();
						if(code) then
							code = code:gsub("\r?\n%s*\r?\n", "\n")
							local html = item:GetHtml() or ""
							html = html:gsub("<div [^>]*>", "`"):gsub("</div>", "`")
							html = html:gsub("<input .*value=\"([^\"]+)\"[^/]*/>", "`%1`")
							docs[#docs+1] = '<div style="float:left;margin-right:10px;">\n\n'
							docs[#docs+1] = "> "..html.."\n"..code;
							if(not code:match("\n%s*$")) then
								docs[#docs+1] = "\n"
							end
							docs[#docs+1] = '\n</div>\n<div style="float:left;">\n\n'
							docs[#docs+1] = "```lua\n"
							local examples = item:GetNPLCodeExamples();
							docs[#docs+1] = examples;
							if(not examples:match("\n%s*$")) then
								docs[#docs+1] = "\n"
							end
							docs[#docs+1] = "```\n"
							docs[#docs+1] = '\n</div>\n<div style="clear:both"/>\n\n'
						end
					end
				end
			end
		end
	end
	local filename = "temp/codeblock_docs.txt"
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		LOG.std(nil, "info", "CodeHelpWindow", "wiki doc written to %s", filename);
		local text = table.concat(docs, "");
		file:WriteString(text, #text);
		file:close();
		if(not bSilent) then
			_guihelper.MessageBox(format("wiki doc written to %s", filename))
		end
	end
end
CodeHelpWindow:InitSingleton();