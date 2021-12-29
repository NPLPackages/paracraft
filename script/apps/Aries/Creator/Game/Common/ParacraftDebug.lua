--[[
Title: Paracraft debug
Author(s): LiXizhi
Date: 2021/12/5
Desc: for printing logs in main thread, this is a singleton class.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ParacraftDebug.lua");
local ParacraftDebug = commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug");
ParacraftDebug:Connect("onMessage", function(errorMsg, stackInfo)   end);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local ParacraftDebug = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ParacraftDebug"));

--  function(errorMsg, stackInfo)   end
ParacraftDebug:Signal("onMessage");

function ParacraftDebug:ctor()
	ParacraftDebug.Restart()
end

-- static function 
function ParacraftDebug.Restart()
	commonlib.debug.SetNPLRuntimeErrorCallback(ParacraftDebug.OnNPLErrorCallBack)
	if(commonlib.debug.SetNPLRuntimeDebugTraceLevel) then
		commonlib.debug.SetNPLRuntimeDebugTraceLevel(5);
	end
end

function ParacraftDebug.OnNPLErrorCallBack(errorMessage)
	log(errorMessage);
	local stackInfo;
	if(type(errorMessage) == "string") then
		local title;
		title, stackInfo = errorMessage:match("^([^\r\n]+)\r?\n(.*)$")
		if(stackInfo) then
			errorMessage = title;
		end
	end
	ParacraftDebug:onMessage(errorMessage, stackInfo);
end

ParacraftDebug:InitSingleton();