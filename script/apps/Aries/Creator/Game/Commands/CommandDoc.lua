--[[
Title: CommandDoc
Author(s): LiXizhi
Date: 2015/7/23
Desc: generate NPL documentation for NPL language service. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDoc.lua");
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

local DocGen = commonlib.inherit({});

Commands["docgen"] = {
	name="docgen", 
	quick_ref="/docgen [filename]", 
	desc=[[generate NPL documentation for the given file. 
@param filename: lua file name to parse. if filename matches "*.docgen.txt", we will parse all files in it. 
	if nil, it will default to ./Documentation/paracraft.docgen.txt
e.g.
/docgen script/apps/Aries/Creator/Game/block_engine.lua		:parse only this given file
/docgen     :rebuild all files in paracraft.docgen.txt
/docgen -codeblock    :generate code block docs
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local outputname;
		local option = "";
		while (option) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option == "o") then
				outputname, cmd_text = CmdParser.ParseString(cmd_text);
			elseif(option == "codeblock") then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
				local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
				CodeHelpWindow.GenerateWikiDocs()
			end
		end
		if(not cmd_text or cmd_text=="") then
			cmd_text = "Documentation/paracraft.docgen.txt";
		end
		if(cmd_text and cmd_text~="") then
			local root_node;
			if(cmd_text:match("%.docgen%.txt$")) then
				local file = ParaIO.open(cmd_text, "r");
				if(file:IsValid()) then
					while(true) do
						local line = file:readline();
						if(line and line ~="") then
							if(not line:match("^%s*%-%-")) then
								root_node = DocGen:new():Run(line, root_node);
							end
						else
							break;
						end
					end
					file:close();
				end
			else
				root_node = DocGen:new():Run(cmd_text, root_node);
			end
			if(root_node) then
				local filename = "Documentation/"..ParaIO.GetFileName(cmd_text):gsub("%.%w+$", ".xml");
				NPL.load("(gl)script/ide/LuaXML.lua");
				ParaIO.CreateDirectory(filename);
				local file = ParaIO.open(filename, "w");
				if(file:IsValid()) then
					file:WriteString([[<?xml version="1.0" encoding="utf-8" ?>]]);
					file:WriteString("\r\n");
					file:WriteString(commonlib.Lua2XmlString(root_node, true) or "");
					file:close();
					LOG.std(nil, "info", "DocGen", "successfully written to %s", filename);
				end
			end
		end
	end,
};

function DocGen:Run(filename, root_node)
	if(self:Parse(filename)) then
		root_node = self:SaveToXMLNode(root_node);
	end
	return root_node;
end

function DocGen:Parse(filename)
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		self.filename = filename;
		LOG.std(nil, "info", "DocGen", "parsing npl source file %s", filename);
		local text = file:GetText();
		local header = string.match(text, "^%s*%-%-%[%[(.-\r?\n)%]%]$");
		-- TODO: parser header?
		self.functions = self:ParseFunctions(text);
		file:close();
		return true;
	else
		LOG.std(nil, "warn", "DocGen", "can not open source file %s", filename);
	end
end

function DocGen:CreateGetClassNode(class_name, root_node)
	for i, t in ipairs(root_node[1]) do
		if(t.attr.name == class_name) then
			return t;
		end
	end
	local t = {name="table", attr={name=class_name, src=self.filename}};
	root_node[1][#(root_node[1]) + 1] = t;
	root_node[3][#(root_node[3]) + 1] = {name="variable", attr={name=class_name,  type=class_name}};
	return t;
end

function DocGen:SaveToXMLNode(root_node)
	if(not self.functions) then
		return root_node;
	end
	root_node = root_node or {name="doc", {name="tables",}, {name="globals",}, {name="variables",}}
	
	local last_class_name, class_node;
	for i, memFunc in ipairs(self.functions) do 
		local class_name, func_name =  memFunc.name:match("^([%w%_]+)[:%.](.*)$");
		if(last_class_name ~= class_name and class_name) then
			last_class_name = class_name;
			class_node = self:CreateGetClassNode(class_name, root_node);	
		end
		if(class_node and class_name and func_name) then
			-- add a function to class node;
			local func_node = {name="function", 
				attr={
					name=func_name, 
					line=memFunc.line, 
					src = class_node.attr.src~=self.filename and self.filename or nil,
				}, 
			};
			class_node[#class_node+1] = func_node;
			
			if(memFunc.desc or memFunc.syntax) then
				func_node[#func_node+1] = {name="summary", (memFunc.syntax or "").."\r\n"..(memFunc.desc or "") }
			end
			if(memFunc.params and #(memFunc.params)>0 ) then
				for _, param in ipairs(memFunc.params) do
					local param_doc;
					if(memFunc.paramsDoc) then
						param_doc = memFunc.paramsDoc[param];
					end
					if(param ~= "return") then
						func_node[#func_node+1] = {name="parameter", attr={name=param}, param_doc}
					else
						func_node[#func_node+1] = {name="returns", param_doc}
					end
				end	
			end
		end
	end
	return root_node;
end


--[[
extract array of member functions from string
@param bodyText: a common function looks like below. 
@return: it will return a table {{name="", desc="", syntax="", codes={}, params = {""}, paramsDoc = {a mapping from params name to its description, "return" and "see" are two special param key }, }}
]]
function DocGen:ParseFunctions(bodyText, line_offset)
	local memFuncs = {}
	local comments = nil;
	local lineNum = line_offset or 0;
	local insideComment = false;
	for line in string.gmatch(bodyText, "([^\r\n]*)\r?\n") do
		lineNum = lineNum + 1;
		if(not insideComment and line:match("^%s*%-%-%[%[")) then
			insideComment = true;
			comments = comments or {};
			comments[#comments+1] = line:gsub("^%s*%-%-%[%[%s*", "");
		elseif(insideComment and line:match("%]%]")) then
			insideComment = false;
		elseif(insideComment) then
			comments = comments or {};
			comments[#comments+1] = line;
		elseif(line:match("^%s*%-%-")) then
			comments = comments or {};
			comments[#comments+1] = line:gsub("^%s*%-%-%s*", "");
		elseif(line:match("^%s*$")) then
			comments = nil;
		elseif(line:match("^function %w+")) then
			local memFunc = self:ParseFunction(table.concat(comments or {}, "\r\n"), line)
			if(memFunc.name) then
				memFunc.line = lineNum;
				table.insert(memFuncs, memFunc);
			end
		end
	end
	return memFuncs;
end

-- if text contains a table definition like 
-- table1 = {
-- }
-- it will be encapsulated with verbatim block
function DocGen:DoTableDefVerbatim(text)
	return string.gsub(text, "(\r\n)(.*%{\r\n.-\r\n%})", "%1<verbatim>%2</verbatim>");
end

-- @param comments: all comments text
-- @param syntax: the function definition line. 
function DocGen:ParseFunction(comments, syntax)
	local memFunc = {};
	memFunc.syntax = syntax;
	--
	-- get params and function name from syntax
	--
	local _,_, name, params = string.find(syntax, "function%s+([^%(]-)%s*%(([^%)]-)%)")
	if(name) then
		memFunc.name = string.gsub(name, "%s*$", "")
	end	
	if(params) then
		local param
		for param in string.gfind(params,"([%w%_]+)") do
			param = string.gsub(param, "%s*$", "")
			param = string.gsub(param, "^%s*", "")
			if(param~="") then
				memFunc.params = memFunc.params or {};
				table.insert(memFunc.params, param);
			end	
		end
	end
	--
	-- get parasDoc from comments
	--
	-- encapsulate table definition inside verbatim block. 
	comments = self:DoTableDefVerbatim(comments)

	-- replace parameter definition with bullet style bold text. 
	memFunc.desc = string.gsub(comments, "%s*@%s*([%w%_]+)", "\r\n   @%1");
	for type, paramName, paramDoc in string.gfind(comments,"%s*@%s*([%w%_]+)%s*([%w%_]*)%s*:?%s*([^@]*)") do
		paramDoc = string.gsub(paramDoc, "%s*\r?\n%s*$", "");
		if(type == "param" or type == "params") then
			memFunc.paramsDoc = memFunc.paramsDoc or {};
			memFunc.paramsDoc[paramName] = paramDoc;
		elseif(type == "return" or type == "returns") then
			paramName = "return";
			memFunc.params = memFunc.params or {};
			table.insert(memFunc.params, paramName);
				
			memFunc.paramsDoc = memFunc.paramsDoc or {};
			memFunc.paramsDoc[paramName] = (paramName or "").." "..paramDoc;
		elseif(type == "see") then
			paramName = type;
			memFunc.paramsDoc = memFunc.paramsDoc or {};
			memFunc.paramsDoc[paramName] = paramDoc;
		elseif(type=="code") then
			memFunc.codes = memFunc.codes or {};	
			local codepath = paramDoc;
			table.insert(memFunc.codes, {codepath=codepath});
		end
	end
	return memFunc;
end