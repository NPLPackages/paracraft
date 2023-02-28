--[[
Title: a Macro instance
Author(s): LiXizhi
Date: 2021/1/2
Desc: a macro is a set of recordable command that is triggered by a short user action, like clicking or typing. 
The concept is from VBA of MS Office. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local Macro = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Macro"));

local function null_func(params)
	-- echo(parmas)
end

function Macro:ctor()
end

-- @param text: a line of macro command
-- @param lineNumber
function Macro:Init(text, lineNumber)
	self.lineNumber = lineNumber;
	if(text) then
		if(not text:match("^%-%-")) then
			local name, params = text:match("(%w[%w%.]*)%((.*)%)");
			if(name) then
				self.name = name;
				self.params = params;
				self.func = Macros[self.name] or null_func;
				if(Macros[self.name.."Trigger"]) then
					self.hasTrigger = true
				end
				if(name:match("Trigger$")) then
					self.isTrigger = true;
				end
			end
		end
	end
	return self;
end

function Macro:GetLineNumber()
	return self.lineNumber;
end

function Macro:GetLineText()
	if(self.lineNumber) then
		return format("%d: %s", self.lineNumber, self:ToString())	
	else
		return self:ToString();
	end
end

function Macro:ToString()
	return format("%s(%s)", self.name, self.paramsText or self.params or "")
end

function Macro:IsValid()
	return type(self.func) == "function";
end

function Macro:HasTrigger()
	return self.hasTrigger;
end

function Macro:IsTrigger()
	return self.isTrigger;
end

function Macro:CreateTriggerMacro()
	if(self:HasTrigger()) then
		local m = Macro:new():Init(format("%sTrigger(%s)", self.name, self.params or ""));
		return m;
	end
end

-- nil or an array of parameters
function Macro:GetParams()
	if(type(self.params) == "string") then
		self.paramsText = self.params;
		self.params = NPL.LoadTableFromString("{"..self.params.."}");
	end
	return self.params;
end

-- @param onFinished: optional callback function when macro is finished. 
-- @return nil if macro is finished immediately, or {} if not. 
function Macro:Run(onFinished)
	self.OnFinish = function()
		self.isFinished = true;
		if(onFinished) then
			onFinished()
		end
		self.OnFinish = nil;
	end

	self:RunImp();
end

-- only called when the screen size changes
function Macro:RunAgain()
	if(not self.isFinished and self:IsTrigger() and self.OnFinish) then
		self:RunImp();
	end
end

function Macro:RunImp()
	if(not self.OnFinish) then
		return
	end
	if(self:IsValid()) then
		LOG.std(nil, "debug", "Macro:Run", "%s(%s)", self.name, self.params or "");
		local params = self:GetParams();
		local result;

		if(not params) then
			result = self.func();
		else
			result = self.func(unpack(params));
		end
		if(type(result) == "table") then
			result.OnFinish = self.OnFinish;
			return result;
		else
			self.OnFinish();
		end
	else
		self.OnFinish();
	end
end

