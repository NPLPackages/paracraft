--[[
Title: C++ language
Author(s): LiXizhi
Date: 2023/12/26
Desc: language configuration file for Cpp(C++/C). 
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CppDef/Cpp.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/SerialPort/SerialPortConnector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/STL.lua");

local SerialPortConnector = commonlib.gettable("MyCompany.Aries.Game.Code.SerialPortConnector");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
-- local CppStd = NPL.load("./CppStd.lua");
local Cpp = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.Cpp", Cpp);

-- disable auto create movie entity
Cpp.isAutoCreateMovieEntity = false

local all_cmds = {}
local cmdsMap = {};
local default_categories = {
	{name = "basic", text = L"基础", colour="#cccc00", },
	{name = "control", text = L"控制", colour="#fe0300", },
	{name = "operator", text = L"运算", colour="#70ad48", },
	{name = "variable", text = L"变量", colour="#90a9dc", },
	{name = "array", text = L"数组", colour="#e49710", },
	{name = "function", text = L"函数", colour="#6666ff", },
	{name = "api", text = L"库", colour="#cc8000", show_create_global_variable = true},
};

local is_installed = false;
function Cpp.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./Cpp_Main.lua"),
		NPL.load("./Cpp_Control.lua"),
		NPL.load("./Cpp_Data.lua"),
		NPL.load("./Cpp_Operators.lua"),
		NPL.load("./Cpp_Block.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		Cpp.AppendDefinitions(v);
	end
end

function Cpp.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			cmdsMap[v.type] = v;
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function Cpp.GetCategoryButtons()
	return default_categories;
end

function Cpp:GetFileExtension()
	return "cpp"
end

function Cpp.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/docs/tutorials/Cpp", "", "", 1);
end

-- public:
function Cpp.GetAllCmds()
	Cpp.AppendAll();
	return all_cmds;
end


-- custom compiler here: 
-- @param codeblock: code block object here
-- @return code_func, errormsg
function Cpp.CompileCode(code, filename, codeblock)
	local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
    local entity = codeblock:GetEntity();
    local compiler = CodeCompiler:new():SetFilename(filename)
	
	if(codeblock and entity) then
		if(entity:IsAllowFastMode()) then
			compiler:SetAllowFastMode(true);
		elseif(entity:IsStepMode()) then
			compiler:SetStepMode(true);
		end
	end
	local hasCppSupport = ParaEngine.GetAttributeObject():GetFieldIndex("CppToLua") >= 0;
	if (hasCppSupport) then
		-- local cppcode = [[include("stdlib.lua");]] .. "\n" .. code;  -- 让世界可以重写stdlib相关方法
		local cppcode = code;
		ParaEngine.GetAttributeObject():SetField("CppToLua", cppcode);  
		local luacode = ParaEngine.GetAttributeObject():GetField("CppToLua") or "";
		local lines = {};
		for line in luacode:gmatch("[^\r\n]+") do
			local cin_pos = string.find(line, "cin(", 1, true);
			if (cin_pos) then
				local cin_end = string.find(line, ")", cin_pos, true);
				if (cin_end) then
					local cin_param = line:sub(cin_pos + 4, cin_end - 1);
					line = string.sub(line, 1, cin_end - 1) .. [[,"]] .. cin_param .. [[")]];
				end
			end
			table.insert(lines, line);
		end
		luacode = table.concat(lines, "\n");

		LOG.std(nil, "debug", "C++ code:\n", cppcode)
		luacode = [[local py_env, env_error_msg = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/polyfill.lua");local code_env = codeblock:GetCodeEnv();py_env['_set_codeblock_env'](code_env);for name, api in pairs(py_env) do code_env[name] = api;end local Cpp = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CppDef/Cpp.lua");Cpp.InstallStdLibMethods(codeblock);]]
			..luacode .. "\n" ..[[if(main) then 	main() end ]]
		LOG.std(nil, "debug", "npl code:\n", luacode)
		entity:SetIntermediateCode(luacode)
		-- print("cppcode===>", cppcode)
		-- print("luacode===>", luacode)
		return compiler:Compile(luacode);
	end
end

-- 默认的stdlib.lua方法
function Cpp.InstallStdLibMethods(codeblock)
	local code_env = codeblock:GetCodeEnv();

	code_env.INT_MIN = (-2147483647 - 1);
	code_env.INT_MAX = 2147483647;
	code_env.sqrt = math.sqrt;
	code_env.sleep = function(ms) code_env.wait(ms / 1000) end
	code_env.rand = function() return math.random(0, 32767) end
	code_env.srand = function(seed) math.randomseed (seed) end
	code_env.int = function(value) return math.floor(value) end
	code_env.unsignedint = function(value) return math.floor(value) end
	code_env.short = function(value) return math.floor(value) end
	code_env.unsignedshort = function(value) return math.floor(value) end
	code_env.long = function(value) return math.floor(value) end
	code_env.unsignedlong = function(value) return math.floor(value) end
	code_env.string = function(value) return tostring(value) end
	code_env.float = function(value) return value end
	code_env.double = function(value) return value end
	code_env.bool = function(value) return value end

	-- for key, val in pairs(CppStd) do
	-- 	code_env[key] = val;
	-- end

	code_env.swap = function(a, b)
		return b, a;
	end
	
	code_env.cin = function(param, param_name)
		local line = code_env.cin_lastline;
		if(not line) then
			line = code_env.ask(param_name or L"输入窗", L"确定") or "";
		end
		if(type(param) == "number") then
			local num;
			num, line = line:match("^%s*(%-?[%.%d]+)%s*(.*)$");
			if(not line or line=="") then
				code_env.cin_lastline = nil;
			else
				code_env.cin_lastline = line;
			end
			if(num) then
				line = tonumber(num);
			end
		else
			code_env.cin_lastline = nil
			if(param == nil and line:match("^%d+$")) then
				line = tonumber(line);
			end
		end
		return line;
	end

	code_env.print = function(name, ...)
		local n = select("#", ...);
		if(n > 0 and type(name) == "string") then
			name = name:gsub("(%%[%.%d]*)lf", "%1f");
		end
		local text = string.format(name, ...)
		code_env.log(text);
	end
	code_env.printf = code_env.print
	-- float a; double b; char s[100]; scanf("%f%lf%s", &a, &b, s);
	code_env.scanf = function(name, ...)
		local text =  tostring(name);
		local arg={...}
		line = code_env.ask(L"输入窗: "..text, L"确定") or "";

		text = text:gsub("%%%w+", function(str)
			if(str == "%lf" or str == "%d" or str == "%f") then
				return "%s*(-?[%.%d]+)%s*"
			elseif(str == "%s") then
				return "%s*(.*)%s*"
			else
				return "";
			end
		end)
		local r = {};
		local count = 0;
		r[1], r[2], r[3], r[4], r[5], r[6] = string.match(line, text)
		for index, v in ipairs(arg) do
			if(type(v) == "number" and r[index]) then
				r[index] = tonumber(r[index]);
			end
			if(r[index]) then
				count = count + 1;
			else
				break
			end
		end
		return count, r[1], r[2], r[3], r[4], r[5], r[6];
	end
	
	code_env.setw = function(width)
		code_env.cout_width = width;
	end

	code_env.setprecision = function(precision)
		code_env.cout_precision = precision or 5;
	end
	
	code_env.cout = function(value)
		if (value == nil) then return end 

		if (code_env.cout_precision) then
			value = string.format("%."..code_env.cout_precision.."f", value);
			code_env.cout_precision = nil;
		end
		if(code_env.cout_width) then
			value = string.format("%"..code_env.cout_width.."s", tostring(value));
			code_env.cout_width = nil;
		end
		code_env.log(value);
	end
	code_env.cerr = code_env.cout;
	code_env.endl = "\n"

	code_env.NewMultiArray = function(n1, n2, n3, n4)
		local arr = commonlib.ArrayMap:new():initMulti(n1, n2, n3, n4);
		arr.__size_1__ = n1;
		arr.__size_2__ = n2;
		arr.__size_3__ = n3;
		arr.__size_4__ = n4;
		return arr;
	end

	-- 数组初始 int arr[10][4] = {1,2,3,4,5,6,7,8,9,10}
	code_env.InitMultiArray = function(arr, init_arr)
		if (type(init_arr) ~= "table") then return end
		local init_arr_size = #init_arr;
		if (init_arr_size == 0) then return end
		local init_arr_index = 1;
		local default_value = type(init_arr[1]) == "string" and "" or 0;
		local get_value = function(value, default_value)
			if (value == nil) then 
				return default_value;
			else
				return value;
			end
		end

		arr.__size_1__ = arr.__size_1__ or init_arr_size or 1;
		for i = 1, arr.__size_1__ do
			if (arr.__size_2__ == nil) then
				arr[i - 1] = get_value(init_arr[init_arr_index], default_value);
				init_arr_index = init_arr_index + 1;
			else
				local arr_1 = arr[i - 1];
				if (arr_1 == nil) then arr_1 = commonlib.ArrayMap:new():initMulti(arr.__size_2__, arr.__size_3__, arr.__size_4__) end 
				arr[i - 1] = arr_1;

				for j = 1, arr.__size_2__ do
					if (arr.__size_3__ == nil) then
						arr_1[j - 1] = get_value(init_arr[init_arr_index], default_value);
						init_arr_index = init_arr_index + 1;
					else
						local arr_2 = arr_1[j - 1];
						if (arr_2 == nil) then arr_2 = commonlib.ArrayMap:new():initMulti(arr.__size_3__, arr.__size_4__) end
						arr_1[j - 1] = arr_2;

						for k = 1, arr.__size_3__ do
							if (arr.__size_4__ == nil) then
								arr_2[k - 1] = get_value(init_arr[init_arr_index], default_value);
								init_arr_index = init_arr_index + 1;
							else
								local arr_3 = arr_2[k - 1];
								if (arr_3 == nil) then arr_3 = commonlib.ArrayMap:new():initMulti(arr.__size_4__) end
								arr_2[k - 1] = arr_3;

								for l = 1, arr.__size_4__ do
									arr_3[l - 1] = get_value(init_arr[init_arr_index], default_value);
									init_arr_index = init_arr_index + 1;
								end
							end
						end
					end
				end
			end
		end
	end
end

--[[
-- 世界 stdlib.lua 文件示例
local cin_value = 0;
function cin()
	cin_value = cin_value + 1;
	return cin_value;
end

function cout(value)
	if (value == nil) then return end
	print("stdlib::cout", value)
end
]]