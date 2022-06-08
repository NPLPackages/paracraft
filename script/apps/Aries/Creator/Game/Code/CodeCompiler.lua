--[[
Title: Code Compiler
Author(s): LiXizhi
Date: 2018/5/30
Desc: compiling code, we will inject checkyield() to looping code to avoid infinite loop in coroutine. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCompiler.lua");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
code_func, errormsg = CodeCompiler:new():SetFilename(virtual_filename):Compile(codeString);
-------------------------------------------------------
]]

local CodeCompiler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler"));

CodeCompiler:Property({"isAllowFastMode", false, "IsAllowFastMode", "SetAllowFastMode", auto=true})
CodeCompiler:Property({"isStepMode", nil, "IsStepMode", "SetStepMode", auto=true})


local inject_map = {
	{"^(%s*function%A+[^%)]+%)%s*)$", "%1 checkyield();"},
	{"^(%s*local%s+function%W+[^%)]+%)%s*)$", "%1 checkyield();"}, 
	{"^(%s*for%s.*%s+do%s*)$", "%1 checkyield();"},
	{"^(%s*while%A.*%Ado%s*)$", "%1 checkyield();"},
	{"^(%s*repeat%s*)$", "%1 checkyield();"},
}

local function injectLine_(line)
	for i,v in ipairs(inject_map) do
		line = string.gsub(line, v[1], v[2]);
	end
	return line;
end

function CodeCompiler:ctor()
end

function CodeCompiler:SetFilename(virtual_filename)
	self.filename = virtual_filename;
	return self;
end

function CodeCompiler:GetFilename()
	return self.filename or "";
end


-- we will inject checkyield() such as in: `for do end, while do end, function end`, etc
function CodeCompiler:InjectCheckYieldToCode(code)
	if(code) then
		local lines = {};
		local isInLongString
		for line in string.gmatch(code or "", "([^\r\n]*)\r?\n?") do
			if(isInLongString) then
				lines[#lines+1] = line;	
				isInLongString = line:match("%]%]") == nil;
			else
				isInLongString = line:match("%[%[[^%]]*$") ~= nil;
				lines[#lines+1] = injectLine_(line);	
			end
		end
		code = table.concat(lines, "\n");
		return code;
	end
end

local inject_step_map = {
	{"^(%s*function%A+[^%)]+%)%s*)$", "%1 checkstep();"},
	{"^(%s*local%s+function%W+[^%)]+%)%s*)$", "%1 checkstep();"}, 
	{"^(%s*for%s.*%s+do%s*)$", "%1 checkstep();"},
	{"^(%s*while%A.*%Ado%s*)$", "%1 checkstep();"},
	{"^(%s*repeat%s*)$", "%1 checkstep();"},
	{"^(%s*end%s*)$", "%1 --"},
	{"^(%s*else%s*)$", "%1 --"},
	{"^(%s*if%(?.*then%s*)$", "%1 checkstep();"},
	{"^(%s*elseif%(?.*then%s*)$", "%1 checkstep();"},
	{"^(%s*%-%-.*)$", "%1 --"},
}

local function injectLineStep_(lastLine)
	local line = lastLine
	for i,v in ipairs(inject_step_map) do
		line = string.gsub(line, v[1], v[2]);
	end
	if(line==lastLine and not line:match("^%s*$")) then
		line = "checkstep();"..line;
	end
	return line;
end

-- TODO: use a more strict way, such as AST tree that preserves line info. 
function CodeCompiler:InjectLineStepToCode(code)
	if(code) then
		local lines = {};
		local isInLongString
		for line in string.gmatch(code or "", "([^\r\n]*)\r?\n?") do
			lines[#lines+1] = injectLineStep_(line);	
		end
		code = table.concat(lines, "\n");
		return code;
	end
end

function CodeCompiler:Compile(code)
	if(code and code~="") then
		if(not self:IsAllowFastMode()) then
			if(self:IsStepMode()) then
				code = self:InjectLineStepToCode(code)
			else
				code = self:InjectCheckYieldToCode(code)
			end
		end
		local code_func, errormsg = loadstring(code, self:GetFilename());
		if(not code_func and errormsg) then
			LOG.std(nil, "error", "CodeBlock", self.errormsg);
		end
		return code_func, errormsg;
	end
end