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
	local pageUrl = "script/apps/Aries/Creator/Game/Code/CodeBlockSettings.html"
	if true then
		pageUrl = "script/apps/Aries/Creator/Game/Code/CodeBlockSettingsV2.html"
		width, height = 400, 580;
	end
	local params = {
			url = pageUrl, 
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
			zorder = 9,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CodeBlockSettings.OnInit()
	page = document:GetPageCtrl();
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		if(entity.GetTriggerBoxString) then
			local triggerString = type(entity.GetTriggerBoxString) == "function" and entity:GetTriggerBoxString() or ""
			page:SetValue("txtTriggerBox", triggerString or "");
		end
		page:SetValue("allowClientExecution", type(entity.IsAllowClientExecution) == "function" and entity:IsAllowClientExecution() == true);
		page:SetValue("allowMultiThreaded", (type(entity.IsGliaFile) == "function" and entity:IsGliaFile() == true));
		page:SetValue("allowFastMode", (type(entity.IsAllowFastMode) == "function" and entity:IsAllowFastMode() == true));
		page:SetValue("isDeferLoad", (type(entity.IsDeferLoad) == "function" and entity:IsDeferLoad() == true));
		page:SetValue("isStepMode", (type(entity.IsStepMode) == "function" and entity:IsStepMode() == true));
		page:SetValue("isOpenSource", type(entity.IsOpenSource) == "function" and entity:IsOpenSource() == true);
		page:SetValue("isCodeReadOnly", type(entity.IsCodeReadOnly) == "function" and entity:IsCodeReadOnly() == true);
		page:SetValue("isUseNplBlockly", type(entity.IsUseNplBlockly) == "function" and entity:IsUseNplBlockly() == true);
		page:SetValue("isUseCustomBlock", type(entity.IsUseCustomBlock) == "function" and entity:IsUseCustomBlock() == true);
		page:SetValue("FontSize", tostring(CodeBlockWindow.GetFontSize()));
		
		local languageFile = entity:GetLanguageConfigFile();
		if(languageFile == "" or languageFile == "NPL" or languageFile=="npl") then
			languageFile = ""
		end
		page:SetValue("language", languageFile);
		
		if true then
			page:SetValue("blocklyMode", (type(entity.IsUseNplBlockly) == "function" and entity:IsUseNplBlockly() == true) and "npl" or "web");
			page:SetValue("blocklyType", (type(entity.IsUseCustomBlock) == "function" and entity:IsUseCustomBlock() == true) and "custom" or "default");
		end
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
	if not System.options.isCommunity then
		CodeBlockWindow.OnClickSelectLanguageSettings()
		if(page) then
			page:CloseWindow();
		end
		return
	end
	local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
	if not is_signed_in then
		GameLogic.AddBBS(nil,L"请登录后使用")
		GameLogic.CheckSignedIn(L"请登录", function(result)
			if result then
				CodeBlockWindow.OnClickSelectLanguageSettings()
			end
		end)
		return
	end
	GameLogic.IsVip("CodeCustomLanguage",true,function(result)
		if result then
			CodeBlockWindow.OnClickSelectLanguageSettings()
		end
	end,"Vip")
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

function CodeBlockSettings.OnChangeDeferLoad(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetDeferLoad(value == true);
	end
end

function CodeBlockSettings.OnChangeAllowMultiThreaded(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		entity:SetGliaFile(value == true);
		CodeBlockWindow.UpdateFilename()
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
	if not entity or not page then 
		return 
	end
	if not System.options.isCommunity then
		entity:SetLanguageConfigFile(value);
		if(value == "npl_python") then
			entity:SetCodeLanguageType("python");
		else
			entity:SetCodeLanguageType(nil);
		end
		CodeBlockWindow.UpdateCodeEditorStatus()
		return
	end
	local language_file = entity:GetLanguageConfigFile()
	local language_type = entity:GetCodeLanguageType()
	local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
	if not is_signed_in then
		page:SetValue("language", language_file);
		page:Refresh(0.01)
		GameLogic.AddBBS(nil,L"请登录后使用")
		GameLogic.CheckSignedIn(L"请登录", function(result)
			if result then
				CodeBlockSettings.OnSelectLang(name, value)
			end
		end)
		return
	end
	
	GameLogic.IsVip("CodeCustomLanguage",true,function(result)
		if result then
			entity:SetLanguageConfigFile(value);
			if(value == "npl_python") then
				entity:SetCodeLanguageType("python");
			else
				entity:SetCodeLanguageType(nil);
			end
			CodeBlockWindow.UpdateCodeEditorStatus()
		else
			page:SetValue("language", language_file);
			page:Refresh(0.01)
		end
	end,"Vip")
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

function CodeBlockSettings.IsCodeReadOnly()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.IsCodeReadOnly) == "function") then
		return entity:IsCodeReadOnly();
	end
end

function CodeBlockSettings.OnSetCodeReadOnly(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if not entity or not page then 
		return 
	end
	if not System.options.isCommunity then
		entity:SetCodeReadOnly(value == true);
		CodeBlockWindow.UpdateCodeReadOnly()
		return
	end
	local is_signed_in = GameLogic.GetFilters():apply_filters('is_signed_in')
	if not is_signed_in then
		page:SetValue("isCodeReadOnly", false);
		page:Refresh(0.01)
		GameLogic.AddBBS(nil,L"请登录后使用")
		GameLogic.CheckSignedIn(L"请登录", function(result)
			if result then
				CodeBlockSettings.OnSetCodeReadOnly(value)
			end
		end)
		return
	end
	GameLogic.IsVip("CodeReadOnly",true,function(result)
		if result and type(entity.SetCodeReadOnly) == "function" then
			entity:SetCodeReadOnly(value == true);
			CodeBlockWindow.UpdateCodeReadOnly()
		else
			page:SetValue("isCodeReadOnly", false);
			page:Refresh(0.01)
		end
	end,"Vip")
end

function CodeBlockSettings.OnSetUseNplBlockly(value)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.SetUseNplBlockly) == "function") then
		entity:SetUseNplBlockly(value == true);
	end
end

function CodeBlockSettings.IsUseNplBlockly()
	local entity = CodeBlockWindow.GetCodeEntity()
	if entity and type(entity.IsUseNplBlockly) == "function" then
		return entity:IsUseNplBlockly()
	end
end

function CodeBlockSettings.OnSelectBlocklyMode()
	if page then
		CodeBlockSettings.OnSetUseNplBlockly(page:GetValue("blocklyMode") == "npl")
		page:Refresh(0.01)
	end
end

function CodeBlockSettings.ClickBlockToolboxBtn()
	local entity = CodeBlockWindow.GetCodeEntity()
	if (not entity or type(entity.IsUseNplBlockly) ~= "function" or not entity:IsUseNplBlockly()) then return end 
	if(page) then page:CloseWindow() end
	local config = CodeBlockWindow.PrepareNplBlocklyConfig(entity);
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
	Page.Show({
		BlockManager = BlockManager,
		XmlText = config.toolbox_xmltext,
		Language = config.language,
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

function CodeBlockSettings.IsUseCustomBlock()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity and type(entity.IsUseCustomBlock) == "function") then
		return entity:IsUseCustomBlock()
	end
end

function CodeBlockSettings.OnSelectBlocklyType()
	if page then
		CodeBlockSettings.OnSetUseCustomBlock(page:GetValue("blocklyType") == "custom")
		page:Refresh(0.01)
	end
end

function CodeBlockSettings.ClickCustomBlockBtn()
	if(page) then page:CloseWindow() end
	local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
	BlockManager.LoadCustomCurrentBlockEntity();
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	Page.Show({
		BlockManager = BlockManager,
	}, {
		-- draggable = false,
		draggable = true,
		width = 1200,
		height = 800,
		alignment="_mt",
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