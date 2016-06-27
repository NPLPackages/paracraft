--[[
Title:Public Source Script
Author(s):LiPeng
Desc:
use the lib:
------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandPublishSourceScript.lua");
------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local excludeFiles = {};
local privateFiles = {};
local classFiles = {}
local publicFiles  = {};


local default_dest_folder = "src/";
local default_src_file_list = "packages/redist/source_script.txt"

local function ResetAll()
	excludeFiles = {};
	privateFiles = {};
	classFiles = {}
	publicFiles  = {};
end

-- to classify the files according to the outline of the srouce files;
-- @param options: {private=boolean}
local function GetAllFilesInfo(src_file_list, options)
	local txtFilePath = src_file_list or default_src_file_list;
	options = options or {};
	local isForcePrivate = options.private;
	local formatFile = ParaIO.open(txtFilePath,"r");
	if(formatFile:IsValid() ~= true) then
		log("error: failed loading source_script.txt file\n");
		return;
	end

	local function AddFile(rule)
		local filesList = {};
		local filegradetable;
		local filePath;
		local dirdeep;
		if(string.match(rule,"%[exclude[%d]?%]")) then
			dirdeep = string.match(rule,"%[exclude([%d]?)%]");
			filePath = string.gsub(rule,"%[exclude[%d]?%]","");
			filegradetable = excludeFiles;
		elseif(string.match(rule,"%[private%]")) then
			filePath = string.gsub(rule,"%[private%]","")
			filegradetable = privateFiles;
		elseif(string.match(rule,"%[class%]")) then
			filePath = string.gsub(rule,"%[class%]","")
			filegradetable = classFiles;
		elseif(string.match(rule,"%[public%]")) then
			filePath = string.gsub(rule,"%[public%]","")
			if(isForcePrivate) then
				filegradetable = classFiles;
			else
				filegradetable = publicFiles;
			end
		end
		if(filePath) then
			local floderPath,pattern = string.match(filePath,"(.+/)(.+)");
			if(dirdeep and tonumber(dirdeep)) then
				dirdeep = tonumber(dirdeep) - 1;
			else
				dirdeep = 100
			end
			--local file_num = table.getn(filesList);
			commonlib.Files.SearchFiles(filesList, floderPath, pattern, dirdeep, 100000, true)
			if(#filesList > 0) then
				local filename
				for i = 1,#filesList do
					filename = filesList[i];
					if(string.match(filename,"%.%w+$")) then
						filename = floderPath..filesList[i];
						filegradetable[filename] = true;
						--filesList[i] = floderPath..filesList[i];
					end
				end
			end
		end
	end


	local line = formatFile:readline();
	while(line) do
		AddFile(line);
		line = formatFile:readline();
	end

	local file;
	for file,_ in pairs(excludeFiles) do
		if(publicFiles[file]) then
			publicFiles[file] = nil;
		end
		if(classFiles[file]) then
			classFiles[file] = nil;
		end
		if(privateFiles[file]) then
			privateFiles[file] = nil;
		end
	end

	for file,_ in pairs(privateFiles) do
		if(publicFiles[file]) then
			publicFiles[file] = nil;
		end
		if(classFiles[file]) then
			classFiles[file] = nil;
		end
	end

	for file,_ in pairs(classFiles) do
		if(publicFiles[file]) then
			publicFiles[file] = nil;
		end
	end
	--echo("excludeFiles");
	--echo(excludeFiles);
	--echo("unpublicFiles");
	--echo(unpublicFiles);
	--echo("privateFiles");
	--echo(privateFiles);
	--echo("publicFiles");
	--echo(publicFiles);
end

-- process the public files table
local function GeneratePublicFiles()
	local filepath;
	for filepath,_ in pairs(publicFiles) do
		local newfilepath = default_dest_folder..filepath;
		ParaIO.CopyFile(filepath,newfilepath,true);
	end
	ParaIO.CloseFile();
end

-- process the class files table
local function GenerateClassFiles(dest_folder)
	dest_folder = dest_folder or default_dest_folder;
	local function DeleteLineFeedInBegin(fileTextTable)
		local _,_, del_part,str = string.find(fileTextTable[1], "^(%s*\r\n)(.*)$");
		if(del_part) then
			fileTextTable[1] = str;
			DeleteLineFeedInBegin(fileTextTable);
		end
	end

	local function createNewClassFile(oldpath,newpath)
		local oldfile = ParaIO.open(oldpath,"r");
		local old_str = oldfile:GetText() or "";
		oldfile:close();

		old_str = string.gsub(old_str, "\r\n", "\n");
		old_str = string.gsub(old_str, "\n", "\r\n");

		local new_str = "";
		-- begin with "--[[" 
		local _,_, header,body = string.find(old_str, "^%s*(%-%-%[%[.-%]%])(.*)$")
		if(header or body) then
		else
			-- begin with "--"  or line feed
			local str_table = {old_str};
			DeleteLineFeedInBegin(str_table)
			old_str = str_table[1];
			
			if(string.match(old_str,"^%-%-")) then
				_,_, header,body = string.find(old_str, "^(%-%-.-%]%])(.*)$")
			end
		end
		
		if(header) then
			new_str = new_str..header;
		end
		if(body) then
			local comments, syntax;
			for comments,syntax in string.gfind(body, "\r\n(\r\n%-%-.-\r\n)(function [^\r\n]*)") do
				local fun_comments = "";
				local line;
				for line in string.gfind(comments,"([^\r\n]-\r\n)") do
					if(string.match(line,"^%-%-")) then
						fun_comments = fun_comments..line;
					else
						fun_comments = ""
					end
				end
				new_str = new_str.."\r\n"..fun_comments..syntax.."\r\n".."end".."\r\n";
			end
		end
		ParaIO.CreateDirectory(newpath);
		local newfile = ParaIO.open(newpath,"w");
		newfile:WriteString(new_str);
		newfile:close();
	end

	local filepath;
	for filepath,_ in pairs(classFiles) do
		local prefix,suffix = string.match(filepath,"(.*)(%.%w+)");
		local newfilepath = dest_folder..prefix..".class"..suffix;
		createNewClassFile(filepath,newfilepath)
	end
end

-- process the private files table
local function GeneratePrivateFiles(dest_folder)
	dest_folder = dest_folder or default_dest_folder;
	for filepath,_ in pairs(privateFiles) do
		local prefix,suffix = string.match(filepath,"(.*)(%.%w+)");
		local newfilepath = dest_folder..prefix..".private"..suffix;
		ParaIO.CreateDirectory(newfilepath);
		ParaIO.CreateNewFile(newfilepath);
		ParaIO.CloseFile();
	end
end

Commands["generatesrc"] = {
	name = "generatesrc",
	quick_ref = "/generatesrc [-private] [src_file_list] [dest_folder]",
	desc = [[generate the open soucre codes. 
-private: if available force all as private files
src_file_list defaults to: 'packages/redist/source_script.txt'
dest_folder defaults to: 'src/'
/generatesrc -private
]],
	handler = function (cmd_name, cmd_text, cmd_params)
		local src_file_list, dest_folder, options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		src_file_list, cmd_text = CmdParser.ParseString(cmd_text);
		dest_folder, cmd_text = CmdParser.ParseString(cmd_text);
		src_file_list = src_file_list or default_src_file_list;
		dest_folder = dest_folder or default_dest_folder;
		LOG.std(nil, "info", "generatesrc", "from %s to %s (options:%s)", src_file_list, dest_folder, commonlib.serialize_compact(options));
		ResetAll();
		GetAllFilesInfo(src_file_list, options);
		ParaIO.CreateDirectory(dest_folder);
		ParaIO.DeleteFile(dest_folder.."*.*")
		GeneratePublicFiles(dest_folder);
		GenerateClassFiles(dest_folder);
		GeneratePrivateFiles(dest_folder);
		_guihelper.MessageBox("the Source Files processed over!!");
	end

};

local function SortString(a,b)
	if(type(a) ~= "string" or type(b) ~= "string") then
		return nil;
	end
	if(a == b) then
		return false;
	end
	local a_len = string.len(a);
	local b_len = string.len(b);
	local l = if_else(a_len <= b_len,a_len,b_len);
	for i = 1,l do
		--local a_letter = string.sub(d
	end
end

local function GenerateCommandXmlFile()
	local cmd_file = "config/Aries/creator/Commands.xml";
	--local original_cmd_file = "config/Aries/creator/Original_Commands.xml";
	local cmds = {};
	local all_cmds = {};
	local new_add_cmds = {};
	local xml_root_node;
	--local command_floder_dir = "script/apps/Aries/Creator/Game/Commands/";
	--local exclude_files = {""}
	--local cmd_files = {};
	--commonlib.Files.SearchFiles(cmd_files, command_floder_dir, "*.lua", 0, 100000, true);

	local cmd_file_index = 1;
	local function ProcessCommands()

		for name, cmd in pairs(Commands) do
			if(not cmds[name]) then
				local attr = {
					name = commonlib.Encoding.DefaultToUtf8(name),
					quick_ref = commonlib.Encoding.DefaultToUtf8(cmd.quick_ref),
					desc = commonlib.Encoding.DefaultToUtf8(cmd.desc),
				};
				--echo("name");
				--echo(name);
				new_add_cmds[name] = {attr = attr};
			end
		end
	end

	local function LoadCmdFile()
		local xmlRoot = ParaXML.LuaXML_ParseFile(cmd_file);
		if(xmlRoot) then
			xml_root_node = xmlRoot[1];
			local node;
			for node in commonlib.XPath.eachNode(xmlRoot, "/Commands/Type/Command") do
				if(node.attr.name) then
					local cmd = {};
					cmd.attr = node.attr;
					--echo(node);
					--echo(#node);
					for i = 1,#node do
						cmd[i] = node[i];
					end
					cmds[node.attr.name] = cmd;
				end
			end
		end
	end

	local function SaveCmdFile()
		local file = ParaIO.open(cmd_file, "w");
		if(file:IsValid()) then
			--local commands = {};
			--commonlib.partialcopy(cmds, new_add_cmds);
			--table.sort(cmds,function (a,b)
				--
			--end);

			--for name, cmd in pairs(cmds) do
				--local command = {name = "Command",attr = cmd.attr};
				--if(#cmd >0) then
					--for i = 1,#cmd do
						--command[i] = cmd[i];
					--end
				--end
				--commands[#commands + 1] = command;
			--end
			local new_commands;
			for name, cmd in pairs(new_add_cmds) do
				if(not new_commands) then
					new_commands = {name="Type",attr={name="new"}};
				end
				local command = {name = "Command",attr = cmd.attr};
				new_commands[#new_commands + 1] = command;
			end

			table.insert(xml_root_node,1,new_commands)
			--table.sort(commands,function (a,b)
				--if(string.lower(a.attr.name) < string.lower(b.attr.name)) then
					--return true;
				--else
					--return false;
				--end
			--end);

			--local node = {name="Commands",
				--[1] = commands,
			--}

			file:WriteString(commonlib.Lua2XmlString(xml_root_node, true));
			file:close();
			LOG.std(nil, "info", "WorldInfo",  "saved");
			-- save success
			return true;
		else
			return false;	
		end
	end
	LoadCmdFile();
	ProcessCommands();
	SaveCmdFile();
end

Commands["generatecmdfile"] = {
	name = "generatecmdfile",
	quick_ref = "/generatecmdfile",
	desc = "generate command xml file or add the new command to the command xml file",
	handler = function (cmd_name, cmd_text, cmd_params)
		
		GenerateCommandXmlFile();
		_guihelper.MessageBox("命令文件处理完成,具体请查看:config/Aries/creator/Commands.xml.");
	end

};