--[[
Title: CodeBlocklySerializer
Author(s): leio
Date: 2018/6/17
Desc: the help functions for reading/writing blockly information 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklySerializer.lua");
local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
CodeBlocklySerializer.SaveFilesToDebug();

links:
blockfactory: https://blockly-demo.appspot.com/static/demos/blockfactory/index.html
define-blocks: https://developers.google.com/blockly/guides/create-custom-blocks/define-blocks
generating-code: https://developers.google.com/blockly/guides/create-custom-blocks/generating-code
operator-precedence: https://developers.google.com/blockly/guides/create-custom-blocks/operator-precedence
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpItem.lua");

local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
local CodeHelpItem = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpItem");

local CodeBlocklySerializer = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklySerializer");
local arg_len = 9; -- assumed total number of arg, start index from 0

function CodeBlocklySerializer.OnInit(categories,all_cmds)
    CodeBlocklySerializer.categories = categories;
    CodeBlocklySerializer.all_cmds = all_cmds;
end
function CodeBlocklySerializer.GetCategoryButtons()
    return CodeBlocklySerializer.categories or CodeHelpWindow.GetCategoryButtons()
end
function CodeBlocklySerializer.GetAllCmds()
	return CodeBlocklySerializer.all_cmds or CodeHelpWindow.GetAllCmds();
end
function CodeBlocklySerializer.SaveFilesToDebug(folder_name)
    folder_name = folder_name or "block_configs"
    NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua");
    local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")
    local lang = Translation.GetCurrentLanguage();
    if(lang == "enUS")then
        CodeBlocklySerializer.WriteBlocklyMenuToXml(folder_name .. "/BlocklyMenu.xml");
        CodeBlocklySerializer.WriteToBlocklyConfig(folder_name .. "/BlocklyConfigSource.json");
    else
        CodeBlocklySerializer.WriteBlocklyMenuToXml(folder_name .. "/BlocklyMenu-zh-cn.xml");
        CodeBlocklySerializer.WriteToBlocklyConfig(folder_name .. "/BlocklyConfigSource-zh-cn.json");
    end
    CodeBlocklySerializer.WriteToBlocklyCode(folder_name .. "/BlocklyExecution.js");
    CodeBlocklySerializer.WriteKeywordsToJson(folder_name .. "/LanguageKeywords.json");
end
function CodeBlocklySerializer.WriteKeywordsToJson(filename)
	ParaIO.CreateDirectory(filename);

	local s = CodeBlocklySerializer.GetKeywords();
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end
function CodeBlocklySerializer.GetKeywords()
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
	local result = {};
	local k,v;
	for k,v in ipairs(all_cmds) do
		if(v.type)then
			table.insert(result,v.type);
		end
	end
	local s = NPL.ToJson(result,true);
	return s;
end
function CodeBlocklySerializer.GetBlocklyMenuXml()
	local categories = CodeBlocklySerializer.GetCategoryButtons()
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
	local s = [[<xml id="toolbox" style="display: none">]];
	local k,v;
	for k,v in ipairs(categories) do
		local c_s = CodeBlocklySerializer.GetCategoryStr(v);
		s = string.format("%s\n%s",s,c_s);
	end
	s = string.format("%s\n</xml>",s);
	return s;
end
-- create a xml menu
function CodeBlocklySerializer.WriteBlocklyMenuToXml(filename,categories,all_cmds)
	ParaIO.CreateDirectory(filename);
	local s = CodeBlocklySerializer.GetBlocklyMenuXml(categories,all_cmds);
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end
function CodeBlocklySerializer.GetAllVariableTypes()
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
    local variable_type_maps = {};
    for __,cmd in ipairs(all_cmds) do
        for k = 0,arg_len do
            local input_arg = cmd["arg".. k];
            if(input_arg)then
                for __,arg in ipairs(input_arg) do
                    if(arg.type == "field_variable")then
                        local variableTypes = arg.variableTypes;
                        if(variableTypes)then
                            local type;
                            for __, type in ipairs(variableTypes) do
                                variable_type_maps[type] = type;                  
                            end  
                        end
                    end
                end
            end
        end
    end
    return variable_type_maps;
end
function CodeBlocklySerializer.GetCategoryStr(category)
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
	if(not category or not all_cmds)then return end
    local text = category.text;
    local name = category.name;
    local colour = category.colour or "#000000";
    local custom = category.custom or "";
    if(custom and custom ~= "")then
        custom = string.format("custom='%s'",custom);
    end
	local s = string.format("<category name='%s' id='%s' colour='%s' secondaryColour='%s' %s >\n",text,name,colour,colour,custom);
	local cmd
    local bCreateVarBtn = false;
	for __,cmd in ipairs(all_cmds) do
		if(category.name == cmd.category and not cmd.hide_in_toolbox)then
            if(category.name == "Data")then
                if(not bCreateVarBtn)then
                    local variable_type_maps = CodeBlocklySerializer.GetAllVariableTypes();
                    local type;
                    for __,type in pairs(variable_type_maps) do
                        local callbackKey;
                        if(type == "")then
                            callbackKey = "create_variable"
			                s = string.format("%s<button text='%s %s' type='%s' callbackKey='%s'></button>\n",s,L"创建变量", type, type, callbackKey);
                        else
                            callbackKey = "create_variable_" .. type
			                s = string.format("%s<button text='%s %s' type='%s' callbackKey='%s'></button>\n",s,L"创建变量 类型为:", type, type, callbackKey);
                        end
                    end
                    bCreateVarBtn = true;
                end
            end
            local shadow = CodeBlocklySerializer.GetShadowStr(cmd);
			s = string.format("%s<block type='%s'>%s</block>\n",s,cmd.type,shadow);
		end
	end
	s = string.format("%s</category>",s);
	return s;
end
-- check shadow table in arg0 -- arg9 from cmd
-- see definition here https://github.com/LLK/scratch-blocks/tree/develop/blocks_common
function CodeBlocklySerializer.GetShadowStr(cmd)
    if(not cmd)then
        return "";
    end
    local shadow_configs = {
        ["math_number"] = "NUM",
        ["math_integer"] = "NUM",
        ["math_whole_number"] = "NUM",
        ["math_positive_number"] = "NUM",
        ["math_angle"] = "NUM",
        ["colour_picker"] = "COLOUR",
        ["matrix"] = "MATRIX",
        ["text"] = "TEXT",
    }
    local result = "";
    for k = 0,arg_len do
        local input_arg = cmd["arg".. k];
        if(input_arg)then
            for k,v in ipairs(input_arg) do
                local shadow = v.shadow;
                if(shadow and shadow.type)then
                    local shadow_type = shadow.type;
                    local value = shadow.value or "";
                    local filed_name = shadow_configs[shadow_type];
                    local s;
                    if(filed_name)then
                        s = string.format("<value name='%s'><shadow type='%s'><field name='%s'>%s</field></shadow></value>",v.name,shadow_type,filed_name,value);
                    else
                        s = string.format("<value name='%s'><shadow type='%s'></shadow></value>",v.name,shadow_type);
                    end
                    if(result == "")then
                        result = s;
                    else
                        result = result .. s;
                    end
                end
            end
        end
    end
    return result;
end
function CodeBlocklySerializer.GetBlocklyConfig()
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
	local categories = CodeBlocklySerializer.GetCategoryButtons()
	local c_map = {};
	local k,v;
	for k,v in ipairs(categories) do
		local name = v.name;
		c_map[name] = v;
	end
	all_cmds = commonlib.deepcopy(all_cmds)
	for k,v in ipairs(all_cmds) do
		local category = v.category;
		if(not v.colour)then
			local c_node = c_map[category];
			-- set colour
			v.colour = c_node.colour;
		end
	end
	local s = NPL.ToJson(all_cmds,true);
	return s;
end
-- write a json file to config all of blocks
-- how to define-blocks:https://developers.google.com/blockly/guides/create-custom-blocks/define-blocks
function CodeBlocklySerializer.WriteToBlocklyConfig(filename)
	if(not filename)then return end
	ParaIO.CreateDirectory(filename);

	local s = CodeBlocklySerializer.GetBlocklyConfig();
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end
function CodeBlocklySerializer.GetBlocklyCode()
	local all_cmds = CodeBlocklySerializer.GetAllCmds();
	local s = "";
	local cmd
	for __,cmd in ipairs(all_cmds) do
		local execution_str = CodeBlocklySerializer.GetBlockExecutionStr(cmd)
		if(s == "")then
			s = execution_str;
		else
			s = s .. "\n" .. execution_str;
		end
	end
	return s;
end
-- create a js file for execution
-- generating-code: https://developers.google.com/blockly/guides/create-custom-blocks/generating-code
function CodeBlocklySerializer.WriteToBlocklyCode(filename)
	if(not filename)then return end
	ParaIO.CreateDirectory(filename);

	local s = CodeBlocklySerializer.GetBlocklyCode();
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end
-- translate a cmd to a full block function
function CodeBlocklySerializer.GetBlockExecutionStr(cmd)
	local type = cmd.type;
	local body = CodeBlocklySerializer.ArgsToStr(cmd);
	local s = string.format([[
Blockly.Lua['%s'] = function (block) {
%s
};]],type,body)
	return s;
end

-- translate a cmd to a return value of block function
function CodeBlocklySerializer.ArgsToStr(cmd)
	local type = cmd.type
	local var_lines = "";
	local arg_lines = "";
	local k,v;
	local prefix = type;
	prefix = string.gsub(prefix,"%.","_")


    -- read 10 args 
    for k = 0,arg_len do
        local input_arg = cmd["arg".. k];
        if(input_arg)then
            for k,v in ipairs(input_arg) do
		        local _type = v.type;
		        if(_type and _type ~= "input_dummy")then
			        local var_str = CodeBlocklySerializer.ArgToJsStr_Variable(prefix,v)
			        local arg_str = CodeBlocklySerializer.Create_VariableName(prefix,v);
			        if(var_lines == "")then
				        var_lines = var_str;
				        arg_lines = arg_str;
			        else
				        var_lines = var_lines .. "\n" .. var_str;
				        arg_lines = arg_lines .. "," .. arg_str;
			        end
		        end
	        end
        end
	    
    end
	local func_description = cmd.func_description;
	local s;
	
	if(func_description)then
		local output = cmd.output;
		if(output and output.type)then
		s = string.format([[%s
    return ['%s'.format(%s),Blockly.Lua.ORDER_ATOMIC];]],var_lines,func_description,arg_lines);
		else
		s = string.format([[%s
    return '%s\n'.format(%s);]],var_lines,func_description,arg_lines);
		end
	else
		s = 'return ""';
	end
	return s;
end
-- translate a child item of arg[0-9] to a javascript execution
function CodeBlocklySerializer.ArgToJsStr_Variable(prefix,arg)
	local type = arg.type
	local name = arg.name
	local s;
	local var_name = CodeBlocklySerializer.Create_VariableName(prefix,arg);
	if(type == "input_statement")then
		s = string.format([[    var %s = Blockly.Lua.statementToCode(block, '%s') || '';]],var_name,name)
	elseif(type == "input_value")then
	s = string.format([[    var %s = Blockly.Lua.valueToCode(block,'%s', Blockly.Lua.ORDER_ATOMIC) || '""';]],var_name,name)
	elseif(type == "field_variable")then
		s = string.format([[    var %s = Blockly.Lua.variableDB_.getName(block.getFieldValue('%s'), Blockly.Variables.NAME_TYPE) || '""';]],var_name,name)
    elseif(type == "field_variable_getter")then
		s = string.format([[    var %s = block.getField('%s').getText();]],var_name,name);
	else
		s = string.format([[    var %s = block.getFieldValue('%s');]],var_name,name);
	end
	return s;
end
-- create a unique name of variable
function CodeBlocklySerializer.Create_VariableName(prefix,arg)
	local type = arg.type
	local name = arg.name
	local s = string.format("%s_%s_%s_var",prefix,type,name);
	return s;
end



