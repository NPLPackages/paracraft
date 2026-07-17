--[[
Title: Deferred loaded global singleton objects
Author(s): LiXizhi
Date: 2024/2/5
Desc: add all global objects that are not immediately loaded in this function.
The user can fetch them via GameLogic.All function. 
This class is intellisense friendly. 
use the lib:
-------------------------------------------------------
GameLogic.All = NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DeferredGlobalObjects.lua");
GameLogic.All.WebCamera:Open();
-------------------------------------------------------
]]
local DeferredGlobalObjects = NPL.export();

local getFuncs = {
	["WebCamera"] = function()
		return NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/WebCamera.lua");
	end,
	["BlueTooth"] = function()
		return NPL.load("(gl)script/ide/System/os/BlueToothCodeAPI.lua");
	end,
	-- TODO: add your global object's load function here.
}

setmetatable(DeferredGlobalObjects, {
	__index = function(t, key)
		local value = rawget(t, key);
		if(not value) then
			local func = getFuncs[key];
			if(func) then
				value = func();
				rawset(t, key, value);
			end
		end
		return value;
	end
});
