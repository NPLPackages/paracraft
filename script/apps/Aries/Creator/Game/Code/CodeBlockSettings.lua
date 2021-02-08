--[[
Title: CodeBlockSettings
Author(s): LiXizhi
Date: 2019/9/23
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockSettings.lua");
local CodeBlockSettings = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockSettings");
CodeBlockSettings.Show(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeBlockSettings = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockSettings"));

local page;

function CodeBlockSettings.Show()
	local width, height = 400, 400;
	local params = {
			url = "script/apps/Aries/Creator/Game/Code/CodeBlockSettings.html", 
			name = "CodeBlockSettings.ShowPage", 
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
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = 400,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CodeBlockSettings.OnInit()
	page = document:GetPageCtrl();
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		page:SetValue("allowClientExecution", entity:IsAllowClientExecution() == true);
		page:SetValue("allowFastMode", entity:IsAllowFastMode() == true);
		page:SetValue("isOpenSource", entity:IsOpenSource() == true);
		local languageFile = entity:GetLanguageConfigFile();
		if(languageFile == "" or languageFile == "NPL" or languageFile=="npl") then
			languageFile = ""
		end
		page:SetValue("language", languageFile);
	end
end

function CodeBlockSettings.OnChangeAllowClientExecution(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetAllowClientExecution(value == true);
	end
end

function CodeBlockSettings.SetLanguageConfigFile(filename)
end

function CodeBlockSettings.GetLanguageConfigFile()
	return languageConfigFile;
end

function CodeBlockSettings.Reset()
end

function CodeBlockSettings.OnClickCustomLanguage()
	CodeBlockWindow.OnClickSelectLanguageSettings()
	-- TODO: add callback to OnClickSelectLanguageSettings to avoid closing the caller window. 
	if(page) then
		page:CloseWindow();
	end
end

function CodeBlockSettings.OnChangeAllowFastMode(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetAllowFastMode(value == true);
	end
end

function CodeBlockSettings.OnSelectLang(name, value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetLanguageConfigFile(value);
		CodeBlockWindow.UpdateCodeEditorStatus()
	end
end

function CodeBlockSettings.OnSetOpenSource(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetOpenSource(value == true);
	end
end
