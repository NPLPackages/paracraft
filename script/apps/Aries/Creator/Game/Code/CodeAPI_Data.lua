--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/6/8
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Data.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
local CodeGlobals = commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");


-- simple log any object, similar to echo. 
function env_imp:log(...)
	GameLogic.GetCodeGlobal():log(...);
end

-- similar to log, but without formatting support like %d in first parameter
function env_imp:print(...)
	GameLogic.GetCodeGlobal():print(...);
end

-- @param level: default to 5 
function env_imp:printStack(level)
	local stack = commonlib.debugstack(2, level or 5, 1)
	for line in stack:gmatch("([^\r\n]+)") do
		if(not line:match("C function") and not line:match("CodeCoroutine.lua")) then
			env_imp.echo(self, line);
		end
	end
end

function env_imp:echo(obj, ...)
	commonlib.echo(obj, ...);
	if(type(obj) == "string") then
		GameLogic.RunCommand("/echo "..obj:sub(1, 100))
	else
		GameLogic.RunCommand("/echo "..commonlib.serialize_in_length(obj, 100))
	end
	
end

-- get the entity associated with the actor.
function env_imp:GetEntity()
	if(self.actor) then
		return self.actor:GetEntity();
	end		
end

function env_imp:getActorEntityValue(name, key)
	local actor_entity = nil;
	if(not name or name == "myself") then
		actor_entity = self.actor:GetEntity();
	elseif(name == "player") then
		actor_entity = EntityManager.GetPlayer();
	elseif(type(name) == "string") then
		local actor = GameLogic.GetCodeGlobal():GetActorByName(name);
		actor_entity = actor and actor:GetEntity();
	end
	if (not actor_entity) then return nil end
	if (key == "x" or key == "y" or key == "z") then
		local bx, by, bz = actor_entity:GetBlockPos();
		if (key == "x") then return bx end
		if (key == "y") then return by end 
		if (key == "z") then return bz end 
	end
	return nil;
end

function env_imp:getActorValue(name)
	if(self.actor) then
		return self.actor:GetActorValue(name)
	end
end

function env_imp:setActorValue(name, value, v2, v3)
	if(self.actor) then
		self.actor:SetActorValue(name, value, v2, v3)
	end
end

function env_imp:showVariable(name, title, color, fontSize)
	if(type(name) == "string") then
		if(color == "") then
			color = nil;
		end
		if(title == "") then
			title = nil;
		end
		if(fontSize == "") then
			fontSize = nil
		end
		if(fontSize) then
			fontSize = tonumber(fontSize)
			if(fontSize) then
				fontSize = math.max(math.min(40, fontSize), 6);
			end
		end
		local item = CodeUI:ShowGlobalData(name, title, color, fontSize);
		if(item) then
			item:TrackCodeBlock(self.codeblock)
		end
	end
end

-- @param filename: include a file relative to current world directory
function env_imp:include(filename)
	if(self.codeblock) then
		return self.codeblock:IncludeFile(filename)
	end
end

-- private: This function is faster than getActor(), only used internally. 
function env_imp:GetActor()
	return self.actor;
end

-- get actor by name
-- @param name: nil or "myself" means current actor, or any actor name, if"@p" it means current player
function env_imp:getActor(name)
	if(not name or name == "myself") then
		return self.actor;
	elseif(name == "@p") then
		return GameLogic.GetCodeGlobal():GetPlayerActor();
	else
		return GameLogic.GetCodeGlobal():GetActorByName(name);
	end
end

function env_imp:string_length(str)
	return ParaMisc.GetUnicodeCharNum(str);
end

function env_imp:string_char(str, index)
	local len = ParaMisc.GetUnicodeCharNum(str);
	if (index < 1 or index > len) then return "" end
	return ParaMisc.UniSubString(str, index, index); 
end

function env_imp:string_contain(str, substr)
	local pos = string.find(str, substr, 1, true);
	return pos and true or false;
end
