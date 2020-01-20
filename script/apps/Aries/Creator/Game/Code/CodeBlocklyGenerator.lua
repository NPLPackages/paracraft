--[[
Title: CodeBlocklyGenerator
Author(s): leio
Date: 2018/6/17
Desc: the help functions for reading/writing blockly information 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyGenerator.lua");
local CodeBlocklyGenerator = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyGenerator");

links:
blockfactory: https://blockly-demo.appspot.com/static/demos/blockfactory/index.html
define-blocks: https://developers.google.com/blockly/guides/create-custom-blocks/define-blocks
generating-code: https://developers.google.com/blockly/guides/create-custom-blocks/generating-code
operator-precedence: https://developers.google.com/blockly/guides/create-custom-blocks/operator-precedence
-------------------------------------------------------
]]

local CodeBlocklyGenerator = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyGenerator"));

function CodeBlocklyGenerator:ctor()
    self.arg_len = 100; -- the max number of argument, start index is from 0

    self.language_names = {
        ["lua"] = { blockly_namesapce = "Lua", function_name = "func_description", function_provider_name = "func_description_lua_provider", },
        ["javascript"] = { blockly_namesapce = "JavaScript", function_name = "func_description_js", function_provider_name = "func_description_js_provider", },
        ["python"] = { blockly_namesapce = "Python", function_name = "func_description_py", function_provider_name = "func_description_py_provider", },
    }
end

function CodeBlocklyGenerator:OnInit(categories,all_cmds)
    self.categories = categories;
    self.all_cmds = all_cmds;
    return self;
end

function CodeBlocklyGenerator:GetLanguageName(language)
    local config = self:GetLanguageConfig(language);
    if(config)then
        return config.blockly_namesapce;
    end
end
function CodeBlocklyGenerator:GetFunctionName(language)
    local config = self:GetLanguageConfig(language);
    if(config)then
        return config.function_name;
    end
end
function CodeBlocklyGenerator:GetFunctionProviderName(language)
    local config = self:GetLanguageConfig(language);
    if(config)then
        return config.function_provider_name;
    end
end
function CodeBlocklyGenerator:GetLanguageConfig(language)
    if(not language)then
        return
    end
    return self.language_names[language];
end
function CodeBlocklyGenerator:GetCategoryButtons()
    return self.categories;
end
function CodeBlocklyGenerator:GetAllCmds()
	return self.all_cmds;
end

function CodeBlocklyGenerator:GetKeywords()
	local all_cmds = self:GetAllCmds();
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
function CodeBlocklyGenerator:GetBlocklyMenuXml()
	local categories = self:GetCategoryButtons()
	local all_cmds = self:GetAllCmds();
	local s = [[<xml id="toolbox" style="display: none">]];
	local k,v;
	for k,v in ipairs(categories) do
		local c_s = self:GetCategoryStr(v);
		s = string.format("%s\n%s",s,c_s);
	end
	s = string.format("%s\n</xml>",s);
	return s;
end
-- create a xml menu
function CodeBlocklyGenerator.WriteBlocklyMenuToXml(filename,categories,all_cmds)
	
end
function CodeBlocklyGenerator:GetAllVariableTypes()
	local all_cmds = self:GetAllCmds();
    local variable_type_maps = {};
    for __,cmd in ipairs(all_cmds) do
        for k = 0,self.arg_len do
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
function CodeBlocklyGenerator:GetCategoryStr(category)
	local all_cmds = self:GetAllCmds();
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
            if(category.name == "Data" or category.name == "NplMicroRobot.Data" )then
                if(not bCreateVarBtn)then
                    local variable_type_maps = self:GetAllVariableTypes();
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
            local shadow = self:GetShadowStr(cmd);
			s = string.format("%s<block type='%s'>%s</block>\n",s,cmd.type,shadow);
		end
	end
	s = string.format("%s</category>",s);
	return s;
end
-- check shadow table in arg0 -- arg9 from cmd
-- see definition here https://github.com/LLK/scratch-blocks/tree/develop/blocks_common
function CodeBlocklyGenerator:GetShadowStr(cmd)
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
    for k = 0,self.arg_len do
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
function CodeBlocklyGenerator:GetBlocklyConfig()
	local all_cmds = self:GetAllCmds();
	local categories = self:GetCategoryButtons()
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
function CodeBlocklyGenerator:GetBlocklyCode()
    local all_cmds = self:GetAllCmds();
	local s = "";
	local cmd
	for __,cmd in ipairs(all_cmds) do
        local language;
        for language,__ in pairs(self.language_names) do
            local execution_str = self:GetBlockExecutionStr(cmd,language)
		    if(s == "")then
			    s = execution_str;
		    else
			    s = s .. "\n" .. execution_str;
		    end
        end
		
	end
	return s;
end
-- translate a cmd to a full block function
function CodeBlocklyGenerator:GetBlockExecutionStr(cmd,language)
	local type = cmd.type;
    language = language or "lua";
	local body = self:ArgsToStr(cmd,language);

    local language_name = self:GetLanguageName(language);
    if(language_name)then
    local s = string.format([[
Blockly.%s['%s'] = function (block) {
%s
};]],language_name,type,body);
	    return s;
    end
end

-- translate a cmd to a return value of block function
function CodeBlocklyGenerator:ArgsToStr(cmd,language)
	local type = cmd.type
    language = language or "lua";
	local var_lines = "";
	local arg_lines = "";
	local k,v;
	local prefix = type;
	prefix = string.gsub(prefix,"%.","_")


    -- read 10 args 
    for k = 0,self.arg_len do
        local input_arg = cmd["arg".. k];
        if(input_arg)then
            for k,v in ipairs(input_arg) do
		        local _type = v.type;
		        if(_type and _type ~= "input_dummy")then
			        local var_str = self:ArgToJsStr_Variable(prefix,v,language)
			        local arg_str = self:Create_VariableName(prefix,v);
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
    local language_name = self:GetLanguageName(language);
    local func_name = self:GetFunctionName(language);
	local func_description = cmd[func_name];
    if(language == "python" or language == "javascript")then
        -- get func_description from lua func_description if python/javascript func_description is nil
        func_description = func_description or cmd[self:GetFunctionName("lua")];
    end
    local func_provider_name = self:GetFunctionProviderName(language);
	local func_description_provider = cmd[func_provider_name];
	
    if(func_description_provider)then
        return func_description_provider;
    end
	local s;
	if(func_description)then
		local output = cmd.output;
		if(output and output.type)then
		s = string.format([[%s
    return ['%s'.format(%s),Blockly.%s.ORDER_ATOMIC];]],var_lines,func_description,arg_lines,language_name);
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
function CodeBlocklyGenerator:ArgToJsStr_Variable(prefix,arg,language)
	local type = arg.type
	local name = arg.name
	local s;
    local language_name = self:GetLanguageName(language);
    if(language_name)then
        local var_name = self:Create_VariableName(prefix,arg);
	    if(type == "input_statement")then
		    s = string.format([[    var %s = Blockly.%s.statementToCode(block, '%s') || '';]],var_name,language_name,name)
	    elseif(type == "input_value")then
	    s = string.format([[    var %s = Blockly.%s.valueToCode(block,'%s', Blockly.%s.ORDER_ATOMIC) || '""';]],var_name,language_name,name,language_name)
	    elseif(type == "field_variable")then
		    s = string.format([[    var %s = Blockly.%s.variableDB_.getName(block.getFieldValue('%s'), Blockly.Variables.NAME_TYPE) || '""';]],var_name,language_name,name)
        elseif(type == "field_variable_getter")then
		    s = string.format([[    var %s = block.getField('%s').getText();]],var_name,name);
	    else
		    s = string.format([[    var %s = block.getFieldValue('%s');]],var_name,name);
	    end
	    return s;
    end
	
end
-- create a unique name of variable
function CodeBlocklyGenerator:Create_VariableName(prefix,arg)
	local type = arg.type
	local name = arg.name
	local s = string.format("%s_%s_%s_var",prefix,type,name);
	return s;
end



