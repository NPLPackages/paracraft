--[[
Title: ParametricMake 
Author(s): leio
Date: 2021/3/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricMake.lua");
local ParametricMake = commonlib.gettable("ParametricMake.ParametricMake");
local m = ParametricMake.createOrGet("firstUIMaker")
m:runFile("script/apps/Aries/Creator/Game/Tasks/ParametricMake/Test/project1.lua");
local json = m:getNodeJson()
commonlib.echo("============json");
commonlib.echo(json,true);



NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricPage.lua");
local ParametricPage = commonlib.gettable("ParametricMake.ParametricPage");
ParametricPage.show("firstUIMaker","_lt", 0, 0, 400, 600);
------------------------------------------------------------
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricNode.lua");
local ParametricNode = commonlib.gettable("ParametricMake.ParametricNode");


local ParametricMake = commonlib.gettable("ParametricMake.ParametricMake");

local lastErrorCallstack = "";

ParametricMake.env_methods = {
	"project",
	"include",
	"defineBounds",
	"getEnumValue",
	"defineEnum",
	"addProperty",
	"setAction",
};
ParametricMake.instance_map = {};
function ParametricMake.createOrGet(name)
	if(not name)then
		return
	end
	local m = ParametricMake.instance_map[name];
	if(not m)then
		m = ParametricMake:new();
		ParametricMake.instance_map[name] = m;
	end
	return m;
end
function ParametricMake:new (o)
	o = o or {}  
	setmetatable(o, self)
	self.__index = self
	return o
end

function ParametricMake.handle_err(x)
    lastErrorCallstack = commonlib.debugstack(2, 5, 1);
	return x;
end
function ParametricMake:run()
	if(self.codes)then
		self:runCodes(self.codes);
	end
end
function ParametricMake:runFile(filename,bForce)
	if(not filename)then
		return
	end
	if(bForce and self.codes)then
		self:run();
		return
	end
	local file = ParaIO.open(filename, "r")
	if(file:IsValid()) then
		local codes = file:GetText();
		file:close();
		if(codes and codes ~= "") then
			self:runCodes(codes);
		end
	else
		LOG.std(nil, "error", "ParametricMake", "can not load file %s", filename);
	end
end
function ParametricMake:createOrGetEnv()
	if(not self.env)then
		local node = ParametricNode:new();
		self.env = {
			self = node,
		};
		self.node = node;
		local meta = {
			__index = _G
		}
		setmetatable(self.env, meta);

		self:installMethods(self.env,self.node);
	end
	if(self.node)then
		self.node:clearDynamicProps();
	end
end
function ParametricMake:runCodes(codes)
	codes = codes or "";
	self.codes = codes;
	self:createOrGetEnv();
	local code_func, errormsg = loadstring(codes);
	 if(not code_func and errormsg)then
		LOG.std(nil, "error", "ParametricMake", "load error: %s", errormsg);
    else
		setfenv(code_func, self.env);
        local ok, result = xpcall(code_func,ParametricMake.handle_err);
        if(not ok)then
			LOG.std(nil, "error", "ParametricMake", "run error: %s\n%s", result, lastErrorCallstack);
        end

		
    end
end

function ParametricMake:installMethods(env,inputObject)
	for _, func_name in ipairs(ParametricMake.env_methods) do
		local f = function(...)
			return inputObject[func_name](inputObject, ...);
		end
		env[func_name] = f;
	end
end
function ParametricMake:getNodeJson()
	if(self.node and self.node.toJson)then
		return self.node:toJson();
	end
end
