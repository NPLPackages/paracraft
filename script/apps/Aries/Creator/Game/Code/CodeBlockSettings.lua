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
			zorder = 200,
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
		if(entity.GetTriggerBoxString) then
			page:SetValue("txtTriggerBox", entity:GetTriggerBoxString() or "");
		end
		page:SetValue("allowClientExecution", entity:IsAllowClientExecution() == true);
		page:SetValue("allowFastMode", entity:IsAllowFastMode() == true);
		page:SetValue("isStepMode", entity:IsStepMode() == true);
		page:SetValue("isOpenSource", type(entity.IsOpenSource) == "function" and entity:IsOpenSource() == true);
		page:SetValue("isUseNplBlockly", type(entity.IsUseNplBlockly) == "function" and entity:IsUseNplBlockly() == true);
		page:SetValue("isUseCustomBlock", type(entity.IsUseCustomBlock) == "function" and entity:IsUseCustomBlock() == true);
		page:SetValue("FontSize", tostring(CodeBlockWindow.GetFontSize()));
		
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

function CodeBlockSettings.OnChangeStepMode(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetStepMode(value == true);
	end
end

function CodeBlockSettings.OnSelectLang(name, value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetLanguageConfigFile(value);
		CodeBlockWindow.UpdateCodeEditorStatus()
	end
end

function CodeBlockSettings.OnChangeFontSize(name, value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		value = tonumber(value)
		CodeBlockWindow.SetFontSize(value)
	end
end


function CodeBlockSettings.OnSetOpenSource(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.SetOpenSource) == "function") then
		entity:SetOpenSource(value == true);
	end
end

function CodeBlockSettings.OnSetUseNplBlockly(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.SetUseNplBlockly) == "function") then
		entity:SetUseNplBlockly(value == true);
	end
end

function CodeBlockSettings.ClickBlockToolboxBtn()
	local entity = CodeBlockWindow.GetCodeEntity()
	if (not entity or type(entity.IsUseNplBlockly) ~= "function" or not entity:IsUseNplBlockly()) then return end 
	if(page) then page:CloseWindow() end
	
	local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);
	local language = entity:IsUseCustomBlock() and "UserCustomBlock" or entity:GetLanguageConfigFile();
	Page.Show({
		XmlText = entity:GetNplBlocklyToolboxXmlText() or "",
		Language = (language == "npl" or language == "") and "SystemNplBlock" or language,
		OnConfirm = function(text)
			entity:SetNplBlocklyToolboxXmlText(text);
		end
	}, {
		draggable = false,
		url = "%ui%/Blockly/Pages/CustomToolBox.html",
	});
end

function CodeBlockSettings.OnSetUseCustomBlock(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.SetUseCustomBlock) == "function") then
		entity:SetUseCustomBlock(value == true);
	end
end

function CodeBlockSettings.ClickCustomBlockBtn()
	if(page) then page:CloseWindow() end
	local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);
	Page.Show({
	}, {
		draggable = false,
		width = 1200,
		height = 1000,
		url = "%ui%/Blockly/Pages/BlocklyFactory.html",
	});
end

function CodeBlockSettings.OnChangeBoxTriggerString()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(page and entity and entity.SetTriggerBoxByString) then 
		local triggerString = page:GetValue("txtTriggerBox")
		entity:SetTriggerBoxByString(triggerString)
		local codeBlock = entity:GetCodeBlock()
		if(codeBlock) then
			codeBlock:stateChanged();
		end
	end
end