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
NPL.load("npl_packages/HaqiMod/"); -- haqi mod
local HaqiMod = NPL.load("HaqiMod");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local HaqiAPI = commonlib.inherit(nil, NPL.export());

function HaqiAPI:ctor()
end

-- private:invoke code block API 
function HaqiAPI:InvokeMethod(name, ...)
	return self.codeEnv[name](...);
end

local publicMethods = {
"createArena", "addArenaMob", "removeAllArenas", "removeArena", "setMyCards", "restart", "isArenaModified", "setCurrentHP", "getCurrentHP", "setUserValue", "getUserValue"
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

function HaqiAPI:removeAllArenas()
	HaqiMod.removeAllArenas()
end

function HaqiAPI:removeArena(name)
	HaqiMod.removeArena(name)
end

function HaqiAPI:createArena(name, position)
	local actor = self.codeEnv.codeblock:GetFirstActor();
	if(actor) then
		local entity = actor:GetEntity()
		local x, y, z = CmdParser.ParsePos(position, entity);
		
		if(x) then
			x, y, z = BlockEngine:real_bottom(x, y, z)
			HaqiMod.createArena(name, x, y, z)
		end
	end
end

function HaqiAPI:addArenaMob(index, name)
	local actor = self.codeEnv.codeblock:GetFirstActor();
	if(actor) then
		local filename = actor:GetActorValue("assetfile");
		HaqiMod.addArenaMob(index, name, filename)
	end
end

function HaqiAPI:setMyCards(cards)
	if(type(cards) == "table") then
		for i=1, #cards do
			if(type(cards[i]) == "number") then
				cards[i] = {gsid = cards[i]};
			end
		end
		HaqiMod.setMyCards(cards)
	end
end

function HaqiAPI:restart()
	HaqiAPI.restart_timer = HaqiAPI.restart_timer or commonlib.Timer:new({callbackFunc = function(timer)
		HaqiMod.Logout()
		HaqiMod.Join()
	end})
	HaqiAPI.restart_timer:Change(300);
end

function HaqiAPI:isArenaModified()
	return HaqiMod.IsArenaModified();
end

function HaqiAPI:addIncludeFiles()
	local entityCode = self.codeEnv.codeblock:GetEntity();
	if(entityCode) then
		local files = HaqiMod.GetEditableFiles();
		if(files) then
			entityCode:ClearIncludedFiles();
			for _, filename in ipairs(files) do
				entityCode:AddIncludedFile(filename);
			end
		end
	end
end


function HaqiAPI:setCurrentHP(hpValue)
    HaqiMod.SetCurrentHP(hpValue)
end

function HaqiAPI:getCurrentHP()
    return HaqiMod.GetCurrentHP()
end

-- set equipment addon value for the current player. 
-- @param name: "combatlel", "addonlevel_hp_absolute", "addonlevel_damage_percent", "addonlevel_resilience_percent", 
-- "addonlevel_criticalstrike_percent", "addonlevel_resist_absolute"
function HaqiAPI:setUserValue(name, value)
    HaqiMod.SetUserValue(name, value)
end

function HaqiAPI:getUserValue(name)
    return HaqiMod.GetUserValue(name)
end
