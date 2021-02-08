--[[
Title: Macro Idle
Author(s): LiXizhi
Date: 2021/1/4
Desc: the user is idling. 

Use Lib:
-------------------------------------------------------
GameLogic.Macros.Idle(1000)
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

-- milliseconds between triggers
local DefaultTriggerInterval = 200;

-- @param timeMs: milliseconds or nil. 
-- @param bForceWait: if true, we will not skip even if there is trigger in the next macro. 
-- @return nil or {OnFinish=function() end}
function Macros.Idle(timeMs, bForceWait)
	if(timeMs and timeMs > 0 and not bForceWait) then
		local nextMacro = Macros:PeekNextMacro(1)
		if(nextMacro) then
			local nextNextMacro = Macros:PeekNextMacro(2)
			-- also merge CameraLookat and Trigger. 
			if(nextMacro:IsTrigger() or 
				(nextMacro.name == "CameraMove") or (nextMacro.name == "PlayerMove") or 
				(nextNextMacro and nextNextMacro:IsTrigger() and nextMacro.name == "CameraLookat")) then
				return Macros.Idle(DefaultTriggerInterval, true);
			end
		end
	end
	local callback = {};
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		if(callback.OnFinish) then
			callback.OnFinish();
		end
	end})
	
	timeMs = math.max(math.floor((timeMs or 1) / Macros.GetPlaySpeed()), 1)

	mytimer:Change(timeMs);
	return callback;
end

-- wait given milli-seconds
function Macros.Wait(timeMs)
	return Macros.Idle(timeMs, true)
end

-- return nil or time in ms.  
function Macros.GetLastIdleTime()
	local offset = 0;
	local timeMs;
	while(true) do
		offset = offset - 1;
		local m = Macros:PeekNextMacro(offset);
		if(m) then
			if(m.name == "Idle") then
				local params = m:GetParams() or {};
				if(params[1]) then
					timeMs = params[1];
				end
				break;
			elseif(m:IsTrigger()) then
				break
			end
		else
			break;
		end
	end
	return timeMs;
end






