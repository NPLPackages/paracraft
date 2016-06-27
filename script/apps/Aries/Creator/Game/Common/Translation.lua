--[[
Title: Translation
Author(s): LiXizhi
Date: 2014/11/21
Desc: utf8 encoded zhCN is used as the source language. enUS is the target language.
zhCN is chosen mostly because it can be easily spotted in source and XML file by both machine and human. 

PoEdit command line:
	cmd:	xgettext --language=Lua --force-po -o %o %C %K %F
	extensions: *.lua,*.xml,*.html
	key:	-k%k
	expand:		%f
	encoding:   --from-code=UTF-8
http://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html#xgettext-Invocation

You can also test from command line using CYGWin bash: 
	xgettext --keyword=L --from-code=UTF-8 DesktopMenu.lua
	xgettext --keyword=L --language=Lua --from-code=UTF-8 EscFramePage.html

Both po text file and mo (binary of po) file are supported. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua");
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
Translation.Init();
Translation.ShowPage();
Translation.ChangeLanguage("enUS");
Translation.TestAndExamples();
-- L is a global gettext function
echo(L"测试");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TranslationGettext.lua");
local TranslationGettext = commonlib.gettable("MyCompany.Aries.Game.Common.TranslationGettext")
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

-- either "enUS", "zhCN", etc.  initialized at start up by reading system locale. 
local currentLanguage;
-- default language
local defaultLanguage = "enUS";
-- this is language we use as source. 
local sourceLanguage = "zhCN";
-- translation table. 
local transTable = CommonCtrl.Locale:new("paracraft");

-- call this function at the very beginning. 
function Translation.Init()
	if(Translation.bInited) then
		return;
	end
	Translation.bInited = true;
	---------------------------------------
	-- define a global helper class L
	---------------------------------------
	L = transTable;

	local systemDefaultLang = Translation.GetSystemLanguage();
	local curLang;
	-- load locale from "config/language.txt"
	local file = ParaIO.open("config/language.txt", "r");
	if(file:IsValid()) then
		local locale = file:readline();
		Translation.customLang = locale;
		curLang = Translation.GetLangFromCustomLanguage(locale);
		file:close();
	else
		LOG.std(nil, "info", "language", "config/language.txt is not found");
		if(System.options.mc) then
			curLang = systemDefaultLang;
		end
	end
	--------------------------------------
	-- TEST:  testing enUS 
	--------------------------------------
	--curLang = "enUS";
	--curLang = "zhCN";
	LOG.std(nil, "info", "language", "UI locale set to: %s. system default is %s", curLang, systemDefaultLang);
	Translation.ChangeLanguage(curLang, false);
end

-- change the current custom language and save settings to config/language.txt
-- one need to call ChangeLanguage to actually change the language
-- @param locale: "auto" means system default, nil means config. "enUS", "zhCN", etc
-- @param bChangeLanguage: if true, we will change language;
function Translation.SetCustomLanguage(locale, bChangeLanguage)
	if(Translation.customLang~=locale) then
		Translation.IsCustomLangChanged = true;
		Translation.customLang = locale;
		local file = ParaIO.open("config/language.txt", "w");
		if(file:IsValid()) then
			file:WriteString(locale or "");
			file:close();
		end
		if(bChangeLanguage) then
			local curLang = Translation.GetLangFromCustomLanguage(locale);
			Translation.ChangeLanguage(curLang, false);
		end
	end
end

function Translation.GetLangFromCustomLanguage(locale)
	local lang;
	if(locale == "auto") then
		-- use system default
		lang = Translation.GetSystemLanguage();
	elseif(locale == "config") then
		-- use the one in config/config.txt;
		lang = nil;
	elseif(locale and locale~="") then
		lang = locale;
	end
	return lang;
end

function Translation.GetCustomLanguage()
	return Translation.customLang;
end

function Translation.ShowPage(callbackFunc)
	Translation.IsCustomLangChanged = false;
	local params = {
			url = "script/apps/Aries/Creator/Game/Login/ChangeLanguagePage.html", 
			name = "ChangeLanguagePage", 
			isShowTitleBar = false,
			enable_esc_key = true,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 0,
			allowDrag = true,
			directPosition = true,
				align = "_ct",
				x = -170,
				y = -200,
				width = 350,
				height = 450,
			cancelShowAnimation = true,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(callbackFunc and Translation.IsCustomLangChanged) then
			callbackFunc();
		end
	end
end

function Translation.GetSystemLanguage()
	local langID = ParaEngine.GetAttributeObject():GetField("CurrentLanguage", 0);
	if(langID == 1) then
		return "zhCN";
	else
		return "enUS";
	end
end

function Translation.GetCurrentLanguage()
	if(currentLanguage) then
		return currentLanguage;
	else
		currentLanguage = ParaEngine.GetLocale();
		return currentLanguage;
	end
end


-- @param lang: either "enUS", "zhCN", etc. if nil, it will force load the current language
-- @param bFireEvent: if nil, it defaults to true
function Translation.ChangeLanguage(lang, bFireEvent)
	if(lang and Translation.GetCurrentLanguage()~=lang) then
		ParaEngine.SetLocale(lang);
		currentLanguage = lang;
		Translation.ReloadTranslations();
		if(bFireEvent ~= false) then
			local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
			GameLogic.GetEvents():DispatchEvent({type = "System.LanguageChange", lang = lang});
		end
	else
		Translation.ReloadTranslations();
	end
end

-- reload all translations
function Translation.ReloadTranslations()
	L:SetStrictness("nocheck");
	L:Reset();
	local lang = Translation.GetCurrentLanguage();
	-- actual file should be [filename]_enUS.mo, [filename]_enUS.po, etc. 
	Translation.RegisterLanguageFile("config/Aries/creator/language/paracraft", lang);
	-- Translation.RegisterLanguageFile("config/Aries/creator/language/paracraft", lang);
	-- Note: add other language files here
end

-- register language file. It will first search for mo file, if not found, it will search po file.  
-- @param filename: actual file should be [filename]_enUS.mo, [filename]_enUS.po, etc. 
-- @param lang: default to current language locale, if no one is found, use "enUS". 
-- @param defaultLang: if nil, it is the defaultLanguage, if same as lang, there are no fallback if lang does not exist.
function Translation.RegisterLanguageFile(filename, lang, translationTable, defaultLang)
	if(not filename) then
		return;
	end
	lang = lang or Translation.GetCurrentLanguage();
	local newLang = lang;
	local filepath = format("%s_%s.mo", filename, newLang);
	if(not ParaIO.DoesFileExist(filepath, true)) then
		filepath = format("%s_%s.po", filename, newLang);
		if(not ParaIO.DoesFileExist(filepath, true)) then
			-- default to enUS
			if(newLang ~= (defaultLang or defaultLanguage)) then
				LOG.std(nil, "info", "Translation", "language translation %s defaults to %s", lang, newLang);
				return Translation.RegisterLanguageFile(filename, defaultLanguage, translationTable, defaultLang);
			else
				filepath = nil;
			end
		else
			return Translation.AddPoFile(filepath, translationTable);
		end
	else
		return Translation.AddMoFile(filepath, translationTable);
	end
end

-- add all translations in a mo translation file to the current locale
-- mo file is the compiled version of po file. 
function Translation.AddMoFile(filepath, translationTable)
	local t = translationTable or L:GetTranslationTable();
	return TranslationGettext.AddMoFile(filepath, t);
end

-- add all translations in a po translation file to the current locale
function Translation.AddPoFile(filepath, translationTable)
	local t = translationTable or L:GetTranslationTable();
	return TranslationGettext.AddPoFile(filepath, t);
end

-- add other unknown text here to be automatically added
function Translation.ManuallyAddedText()
	L"点击这里继续";
end