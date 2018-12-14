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
		CodeHelpWindow.RefreshPage();
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

		if(filename == "") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpData.lua");
			local CodeHelpData = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpData");
			CodeHelpData.LoadParacraftCodeFunctions();
		else
			filename = Files.GetWorldFilePath(filename)
			if(filename) then
				-- used forward slash for absolute file path, otherwise NPL.load will inteprete : wrongly.  
				filename = filename:gsub("^(%S):/", "%1:\\");
				local langConfig = NPL.load(filename);
				if(type(langConfig) == "table" and langConfig.GetCategoryButtons and langConfig.GetAllCmds) then
					CodeHelpWindow.SetCategories(langConfig.GetCategoryButtons())
					CodeHelpWindow.SetAllCmds(langConfig.GetAllCmds());
				end
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
			CodeBlockWindow.InsertCodeAtCurrentLine(item:GetNPLCode(), not item:HasOutput());
		end
	end
end

CodeHelpWindow:InitSingleton();