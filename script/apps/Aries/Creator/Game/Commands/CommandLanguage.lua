--[[
Title: CommandLanguage
Author(s): LiXizhi
Date: 2015/7/23
Desc: using Gettext to generate po translation file.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandLanguage.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["poedit"] = {
	name="poedit", 
	quick_ref="/poedit [filename]", 
	desc=[[generate all translatable strings to a temp file and invoke poedit 
Note: this command is only used by the developer. Use /xgettext command to extract translation text inside current world.
e.g.
/poedit 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local xgettext = NPL.load("script/ide/System/Util/xgettext.lua");
		local extractor = xgettext:new();
		extractor:SetFolderFileFilters("*.html")
		extractor:extract_NonEnglishString();
		extractor:open_poedit_file()
	end,
};

Commands["xgettext"] = {
	name="xgettext", 
	quick_ref="/xgettext [enUS|zhCN]", 
	desc=[[extract all display text in current world to a gettext_result.lua file, and generate a "language/translate_enUS.po" file.
Movie block subtitles and sign blocks, etc are all extracted. 
Please install third-party translation software to edit *.po file to provide your translation. 
Recommended software: poedit, google translate tool. 
e.g.
/xgettext    : by default the command will generate translations for english: enUS
/xgettext zhCN
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local locale;
		locale, cmd_text = CmdParser.ParseString(cmd_text);
		locale = nil;
		locale = locale or "enUS";

		local xgettext = NPL.load("script/ide/System/Util/xgettext.lua");
		local extractor = xgettext:new();
		local world_dir = GameLogic.GetWorldDirectory();
		extractor.output_file = world_dir.."language/gettext_result.lua";
		extractor.po_file = world_dir..format("language/translate_%s.po", locale);
		extractor:CreatePoeditFile(true);

		local filelist = {};
		local function searchFolder(folder)
			local result = commonlib.Files.Find({}, folder, 2, 500, "*.xml")
			for i, item in ipairs(result) do
				filelist[#filelist+1] = folder..item.filename;
			end
		end
		searchFolder(world_dir.."blockWorld.lastsave/");
		searchFolder(world_dir);
		extractor:extract_NonEnglishString(filelist);
		extractor:open_poedit_file()
	end,
};

Commands["language"] = {
	name="language", 
	quick_ref="/language [enUS|zhCN]", 
	desc=[[change/reload language settings for the current world
language file is read from current world director/language/translte_[lang].[mo|po] file.
This command is executed during world load, however one can also change it after it manually.
World creator can use /xgettext command to generate translation po file.
e.g.
/language   :use current language
/language enUS  :use English 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua");
		local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
		local locale;
		locale, cmd_text = CmdParser.ParseString(cmd_text);
		
		local translationTable = {}
		local filename = GameLogic.GetWorldDirectory().."language/translate";
		Translation.RegisterLanguageFile(filename, locale, translationTable, locale);
		if(not next(translationTable)) then
			translationTable = nil;
		end
		GameLogic.options:SetTranslationTable(translationTable)
	end,
};
