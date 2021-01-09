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

function Macro:ctor()
end

-- @param text: a line of macro command
function Macro:Init(text)
	if(text) then
		if(not text:match("^%-%-")) then
			local name, params = text:match("(%w[%w%.]*)%((.*)%)");
			if(name) then
				self.name = name;
				self.params = params;
				self.func = Macros[self.name];
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

function Macro:ToString()
	return format("%s(%s)", self.name, self.params or "")
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


-- @param onFinished: optional callback function when macro is finished. 
-- @return nil if macro is finished immediately, or {} if not. 
function Macro:Run(onFinished)
	local function OnFinish()
		if(onFinished) then
			onFinished()
		end
	end

	if(self:IsValid()) then
		LOG.std(nil, "debug", "Macro:Run", "%s(%s)", self.name, self.params or "");
		local params
		if(self.params) then
			params = NPL.LoadTableFromString("{"..self.params.."}");
		end
		local result;
		if(not params) then
			result = self.func();
		else
			result = self.func(unpack(params));
		end
		if(type(result) == "table") then
			result.OnFinish = OnFinish;
			return result;
		else
			OnFinish();
		end
	else
		OnFinish();
	end
end


