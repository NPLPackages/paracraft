--[[
Title: Variables mostly used in entities by command line. 
Author(s): LiXizhi
Date: 2014/3/16
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Variables.lua");
local Variables = commonlib.gettable("MyCompany.Aries.Game.Common.Variables");
local v = Variables:new();
v:SetVariable("name", "123")
echo(v:GetVariable("name"));
echo(v:ReplaceText("My name is %name%"));

-- In ctor() of entity class: 
self.variables = Variables:new();
self.variables:CreateVariable("name", self.GetDisplayName, self);
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local Variable = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.Variable"));

function Variable:ctor()
end

local function ConvertToString(value)
	local t = type(value);
	if(t == "string") then
		return value;
	elseif(t == "table") then
		return commonlib.serialize_compact(t);
	else
		return tostring(value);
	end
end

-- @param value can be string, bool, int or a function (self) end
function Variable:Init(name, value, parent)
	self.name = name;
	self.filtertext = "%%"..name.."%%";
	self.parent = parent;
	self:SetValue(value);
	return self;
end

function Variable:GetValue()
	if(self.get_func) then
		return self.get_func(self.parent);
	else
		return self.value;
	end
end

function Variable:GetValueAsString()
	if(self.get_func) then
		return tostring(self:GetValue());
	else
		return self.str_value;
	end
end

function Variable:SetValue(value)
	if(type(value) == "function") then
		self.get_func = value;
	else
		self.value = value;
		self.str_value = ConvertToString(value);
	end
end

-------------------------------------
-- variables
-------------------------------------
local Variables = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.Variables"));

function Variables:ctor()
	self.variables = {};
end

function Variables:CreateVariable(name, value, parent)
	if(type(name) == "string") then
		local v = Variable:new():Init(name, value, parent);
		self.variables[name] = v;
		return v;
	end
end

function Variables:SetVariable(name, value)
	local v = self.variables[name];
	if(v) then
		v:SetValue(value);
	else
		self:CreateVariable(name, value);
	end
end

function Variables:GetVariable(name)
	local v = self.variables[name];
	if(v) then
		return v:GetValue();
	end
end

function Variables:GetVariableAsString(name)
	local v = self.variables[name];
	if(v) then
		return v:GetValueAsString();
	end
end

-- replace text containing "%name%" with their variable name. 
function Variables:ReplaceText(text)
	if(type(text) == "string") then
		local old_text = text;
		for name in old_text:gmatch("%%([^%%]+)%%") do
			local v = self.variables[name];
			if(v) then
				text = text:gsub(v.filtertext, v:GetValueAsString());
			else
				-- unknown variable. 
			end
		end
	end
	return text;
end

-- this is simply used for the compiler interface in the slashcommand interface. 
function Variables:Compile(input)
	return self:ReplaceText(input);
end