--[[
Title: dump command
Author(s): LiXizhi
Date: 2015/1/25
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDump.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["dump"] = {
	name="dump", 
	quick_ref="/dump [scene|gui|asset|all|view|player|codeblock]", 
	desc=[[dump information to log.txt file
/dump codeblock   dump all codeblocks text to a single file and open it. 
/dump scene
/dump asset
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name, bIsShow;
		name, cmd_text = CmdParser.ParseString(cmd_text);

		local att;
		if(not name or name == "all") then
			att = ParaEngine.GetAttributeObject();
		elseif(name == "scene") then
			att = ParaScene.GetAttributeObject();
		elseif(name == "gui") then
			att = ParaEngine.GetAttributeObject():GetChild("GUI");
		elseif(name == "asset") then	
			att = ParaEngine.GetAttributeObject():GetChild("AssetManager");
		elseif(name == "view") then
			att = ParaEngine.GetAttributeObject():GetChild("ViewportManager");
		elseif(name == "player") then
			att = ParaScene.GetPlayer():GetAttributeObject();
		elseif(name == "codeblock") then
			if(GameLogic.IsReadOnly()) then
				GameLogic.AddBBS(nil, L"只读世界不能导出代码", 3000, "255 0 0");
				return
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockFileSync.lua");
			local CodeBlockFileSync = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockFileSync");
			CodeBlockFileSync:AutoDumpAllCodeBlocks(true)
		elseif(name == "allcode") then
			----/dump  allcode -stripcomments -filename outputfilename -fillup othercodedir
			-- eg 
			--[[
				/dump allcode -stripcomments -fillup F:/paracraft_script/
				/dump allcode -stripcomments -filename temp/abc.txt -fillup F:/paracraft_script/
			]]
			local option = "";
			local dumpOptions = {};
			while(option) do
				option, cmd_text = CmdParser.ParseOption(cmd_text);
				if(option == "stripcomments") then
					dumpOptions.stripComments = true; --去掉注释
				elseif(option == "filename") then
					fileName, cmd_text = CmdParser.ParseString(cmd_text);
					dumpOptions.fileName = fileName; --导出的文件名
				elseif(option == "fillup") then
					directory , cmd_text = CmdParser.ParseString(cmd_text);
					dumpOptions.directory = directory; --使用哪个目录的代码填充
				end
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockFileSync.lua");
			local CodeBlockFileSync = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockFileSync");
			CodeBlockFileSync:DumpAllCodeBlocks(dumpOptions)
		end
		if(att) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AttributeModel.lua");
			local AttributeModel = commonlib.gettable("MyCompany.Aries.Game.Common.AttributeModel");
			local attrModel = AttributeModel:new():init(att);
			attrModel:dump();
		end
	end,
};