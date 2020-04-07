--[[
Title: Haqi
Author(s): LiXizhi
Date: 2020/4/7
Desc: 
use the lib:
-------------------------------------------------------
local HaqiAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/HaqiDef/HaqiAPI.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local HaqiAPI = commonlib.inherit(nil, NPL.export());

function HaqiAPI:ctor()
end

-- private:invoke code block API 
function HaqiAPI:InvokeMethod(name, ...)
	return self.codeEnv[name](...);
end

local publicMethods = {
"createArena",
}

-- create short cut in code API
function HaqiAPI:InstallAPIToCodeEnv(codeEnv)
	for _, func_name in ipairs(publicMethods) do
		local func = self[func_name];
		if(type(func) == "function") then
			codeEnv[func_name] = function(...)
				return func(self, ...);
			end
		end
	end
end

function HaqiAPI:Init(codeEnv)
	self.codeEnv = codeEnv;
	self:InstallAPIToCodeEnv(codeEnv);
		
	-- global functions for canvas
	return self;
end


function HaqiAPI:createArena()
end

