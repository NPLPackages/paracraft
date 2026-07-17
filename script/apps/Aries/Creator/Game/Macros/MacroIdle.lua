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
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

-- milliseconds between triggers
local DefaultTriggerInterval = 200;

function Macros.IsSkipIdle()
	local offset = 1;
	repeat 
		local offsetMacro = Macros:PeekNextMacro(offset);
		if (not offsetMacro) then return false end 
		offset = offset + 1;
		-- 如果下一个宏为按键宏则无需等待, 不检测上一个宏是否为按键宏(输入通常会有个点击聚焦事件中断)
		if (offsetMacro.name == "Idle") then
			-- 忽略
		elseif (offsetMacro.name == "WindowKeyPressTrigger" or offsetMacro.name == "EditBoxTrigger") then
			return true;
		elseif (offsetMacro.name == "UIWindowEventTrigger") then 
			local params = offsetMacro:GetParams();
			if (type(params) == "table" and type(params[1]) == "table" and params[1].virtual_event_type == "UIWindowKeyBoardEvent") then 
				return true;
			else 
				return false;
			end
		else 
			return false;
		end
	until(false);  -- 死循环

	return false;
end

-- @param timeMs: milliseconds or nil. 
-- @param bForceWait: if true, we will not skip even if there is trigger in the next macro. 
-- @param mode: default to nil. if "text", it will be ignored if previous text has finished playing.
-- @return nil or {OnFinish=function() end}
function Macros.Idle(timeMs, bForceWait, mode)
	if(timeMs and timeMs > 0 and not bForceWait) then
		local nextMacro = Macros:PeekNextMacro(1)
		if(nextMacro) then
			if (Macros.IsSkipIdle()) then return end 
			
			local nextNextMacro = Macros:PeekNextMacro(2)
			
			if(nextMacro.name == "WindowKeyPressTrigger") then
				local previousMacro = Macros:PeekNextMacro(-1)
				if(previousMacro and previousMacro.name == "WindowKeyPress") then
					-- ignore idle timer, if we are typing continously
					return
				end
			end

			if(nextMacro.name == "EditBoxTrigger") then
				local previousMacro = Macros:PeekNextMacro(-1)
				if(previousMacro and previousMacro.name == "EditBoxKeyup") then
					-- ignore idle timer, if we are typing continously
					return
				end
			end

			-- also merge CameraLookat and Trigger. 
			if(nextMacro:IsTrigger() or 
				(nextMacro.name == "CameraMove") or (nextMacro.name == "PlayerMove") or (nextMacro.name == "SceneMouseMove") or
				(nextNextMacro and (nextNextMacro:IsTrigger() or (nextNextMacro.name == "SceneMouseMove")) and nextMacro.name == "CameraLookat")) then
				return Macros.Idle(DefaultTriggerInterval, true, mode);
			end

			if (nextMacro.name == "CameraLookat" or nextMacro.name == "Idle" or nextMacro.name == "text") then
				local previousMacro = Macros:PeekNextMacro(-1)
				if(previousMacro and previousMacro.name == "text") then
					local params = type(previousMacro.params) == "table" and previousMacro.params or {}
					local text = params[1] or ""
					local voiceNarrator = params[4] or 10012;
					voiceNarrator = tonumber(voiceNarrator);
					if text ~= "" and voiceNarrator ~= nil then
						local sound_name = "playtext" .. voiceNarrator;
						local md5_value = SoundManager:GetPlayTextMd5(text, voiceNarrator)
						local file_path = SoundManager:GetTempSoundFile(voiceNarrator, md5_value)
						if (file_path) then
							local t = SoundManager:GetSoundDuration(sound_name, file_path);
							return Macros.Idle(t * 1000 + DefaultTriggerInterval, true, mode);
						end
						return Macros.Idle((math.floor(commonlib.utf8.len(text) / 5) + 1.5) * 1000, true);
					else
						return Macros.Idle(DefaultTriggerInterval, true, mode);
					end
				elseif (previousMacro:IsTrigger() or previousMacro.name == "Idle") then
					return Macros.Idle(DefaultTriggerInterval, true, mode);
				end
			end
		end
	end

	if(mode == "text") then
		local callback = {};
		local lastPlayingText = Macros.isPlayingText;
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			local elapsed = commonlib.TimerManager.GetCurrentTime() - (Macros.lastPlayTextTime or 0);
			if((elapsed > (timeMs or 1)) or (lastPlayingText and not Macros.isPlayingText)) then
				timer:Change();
				if(callback.OnFinish) then
					callback.OnFinish();
				end
			end
		end})
		mytimer:Change(50, 50);
		return callback;
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






