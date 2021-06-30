--[[
Title:
Author(s): chenjinxian
Date:
Desc: 
use the lib:
-------------------------------------------------------
local CameraBlocklyAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/CameraBlocklyAPI.lua");
-------------------------------------------------------
]]
local CameraBlocklyAPI = commonlib.inherit(nil, NPL.export());

function CameraBlocklyAPI:ctor()
end

-- private:invoke code block API 
function CameraBlocklyAPI:InvokeMethod(name, ...)
	return self.codeEnv[name](...);
end

local publicMethods = {
}

-- create short cut in code API
function CameraBlocklyAPI:InstallAPIToCodeEnv(codeEnv)
	for _, func_name in ipairs(publicMethods) do
		local func = self[func_name];
		if(type(func) == "function") then
			codeEnv[func_name] = function(...)
				return func(self, ...);
			end
		end
	end
end

function CameraBlocklyAPI:Init(codeEnv)
	self.codeEnv = codeEnv;
	self:InstallAPIToCodeEnv(codeEnv);
	return self;
end
