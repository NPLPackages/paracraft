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

local xgettext = commonlib.inherit({});

-- default files to translate, we will extract all Chinese strings from these files
xgettext.default_filelist = {
	"config/Aries/creator/LoopWords.mobile.xml",
	"config/Aries/creator/LoopWords.mc.xml",
	"config/Aries/creator/PlayerSkins.xml",
	"config/Aries/creator/PlayerAssetFile.xml",
	"config/Aries/creator/block_types.xml",
	"config/Aries/creator/WebTutorials.xml",
	"config/Aries/creator/shortcutkey.xml",
	"config/Aries/creator/modelAnim.xml",
	"config/Aries/creator/blocktemplates/buildingtask/MovieMaking/info.xml",
	"config/Aries/creator/blocktemplates/buildingtask/newusertutorial/info.xml",
	-- "config/Aries/creator/blocktemplates/buildingtask/logic/info.xml",
	"config/Aries/creator/blocktemplates/buildingtask/newyearbuilding/info.xml",
	"config/Aries/creator/blocktemplates/buildingtask/circuit/info.xml",
	"config/Aries/creator/blocktemplates/buildingtask/smallstructure/info.xml",
}
xgettext.output_file = "script/apps/Aries/Creator/Game/Common/test_paracraft_temp_poedit_strings.lua"
xgettext.po_file = "config/Aries/creator/language/paracraft_enUS.po";


Commands["poedit"] = {
	name="poedit", 
	quick_ref="/poedit [filename]", 
	desc=[[generate all translatable strings to a temp file and invoke poedit 
Note: this command is only used by the developer. Use /xgettext command to extract translation text inside current world.
e.g.
/poedit 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		xgettext:extract_NonEnglishString();
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

function xgettext:CreatePoeditFile(bCreateIfNotExist)
	local filename = self.po_file;
	if(bCreateIfNotExist) then
		if(ParaIO.DoesFileExist(filename)) then
			return true;
		end
	end
	ParaIO.CreateDirectory(filename);
	local out = ParaIO.open(filename, "w");
	out:WriteString([[msgid ""
msgstr ""
"Project-Id-Version: paracraft\n"
"Language: en\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"
"X-Poedit-SourceCharset: UTF-8\n"
"X-Poedit-KeywordsList: L\n"
"X-Poedit-Basepath: ../\n"
"X-Poedit-SearchPath-0: .\n"
]]);
	out:close();
	return true;
end

-- return all text strings
function xgettext:extract_NonEnglishString(filelist)
	local nCount = 0;
	local out = ParaIO.open(self.output_file, "w");
	out:WriteString("-- file is automatically generated by /poedit or /xgettext commmand, do not edit manually. \r\n\r\n");
	filelist = filelist or self.default_filelist;
	local existingText = {};
	for _, filename in pairs(filelist) do
		out:WriteString(format("-- %s\r\n", filename));
		local file = ParaIO.open(filename, "r");
		local line = file:readline();
		while(line) do
			-- extract all non-English text in quatations
			-- TODO: inner text in XML is not supported yet. 
			for text in line:gmatch("\"([^%w%d%s<>!%-,\"#%{%[%]&][^\"]*)\"") do
				if(not existingText[text]) then
					existingText[text] = true;
					out:WriteString(format("L\"%s\"\r\n", text));
					nCount = nCount + 1;
				end
			end
			line = file:readline();
		end
		file:close();
	end
	out:close();
	LOG.std(nil, "info", "xgettext", format("%d strings to %s", nCount, self.output_file));
	GameLogic.AddBBS(nil, format("%d strings extracted, see log file", nCount));
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..self.po_file, "", "", 1);
	return existingText;
end
