--[[
Title: Game Rules
Author(s): LiXizhi
Date: 2014/1/27
Desc: in the world directory, there can be a file called "rule.lua", 
which defines rules that should be applied to the game mode when the world is loaded. 

---++ rule.lua example

<verbatim>
-- rule.lua is an ordinary lua file in sandbox script environment. 
-- "this" refers to functions in GameRules class. 

this:AddRule("Player", "AutoWalkupBlock true");
this:AddRule("Block", "CanPlace Lever Glowstone");

</verbatim>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
GameRules:LoadFromFile();
GameRules:AddRule("Player", "AutoWalkupBlock true")
GameRules:DoString(code)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronAPISandbox.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleBase.lua");
local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");


local rule_classes = {};

function GameRules:Init()
	if(self.isInited) then
		return;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RulePlayer.lua");
	local RulePlayer = commonlib.gettable("MyCompany.Aries.Game.Rules.RulePlayer");
	self:RegisterRuleClass("Player", RulePlayer); 

	NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleGlobal.lua");
	local RuleGlobal = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleGlobal");
	self:RegisterRuleClass("Global", RuleGlobal); 

	NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleBlock.lua");
	local RuleBlock = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBlock");
	self:RegisterRuleClass("Block", RuleBlock); 
end

function GameRules:RegisterRuleClass(class_name, class_obj)
	rule_classes[class_name] = class_obj;
end

function GameRules:GetRuleClass(class_name)
	return rule_classes[class_name];
end

-- @param filename: default to "rule.lua" in current world directory. 
function GameRules:LoadFromFile(filename)
	self:Init();
	self:Reset();
	filename = filename or "rule.lua";
	local filename_full = self:GetScriptFullPath(filename);
	if(ParaIO.DoesAssetFileExist(filename_full, true)) then
		-- load script
		self:CheckLoadScript(filename, true);
	end
end

-- clear all rules
function GameRules:Reset()
	self._PAGESCRIPT = nil;

	if(self.rules) then
		for name, rule in pairs(self.rules) do
			rule:OnRemove();
		end
	end
	self.rules = {};
	self.scripts = {};
end

-- create or get script scope
function GameRules:GetRuleFileScriptScope()
	if(not self._PAGESCRIPT) then
		self._PAGESCRIPT = {
			this = self,
		};
		setmetatable (self._PAGESCRIPT, NeuronAPISandbox.CreateGetSandbox())
	end
	return self._PAGESCRIPT;
end


-- get the full path from relative script file name. 
-- @param filename: can be relative filepath. 
function GameRules:GetScriptFullPath(filename)
	return format("%s%s", GameLogic.current_worlddir, filename);
end

-- get script code. all functions will be reset. 
-- @return function or false or nil. 
function GameRules:GetScript(filename, bReload)
	if(not filename or filename == "") then
		return false;
	end
	
	local script = self.scripts[filename];
	if(not script) then
		script = {};
		self.scripts[filename] = script;
	end

	local func = script.func;

	if(bReload or func == nil) then
		func = false;
		local filename_full = self:GetScriptFullPath(filename);
		local file = ParaIO.open(filename_full, "r");
		if(file:IsValid()) then
			local text = file:GetText();
			if(text and text~="") then
				local code_func, errormsg = loadstring(text, filename_full);
				if(not code_func) then
					LOG.std(nil, "error", "GameRules", "<Runtime error> syntax error while loading code in file:%s\n%s", filename_full, tostring(errormsg));
					GameLogic.ShowMsg(format("<syntax error>:%s|%s", filename_full, tostring(errormsg)))
				else
					func = code_func;
				end
			end
			file:close();
		else
			GameLogic.ShowMsg(format("<File Not Found>:%s", filename_full));
		end	
		if(not func) then
			LOG.std(nil, "error", "GameRules", "%s not valid game rule file", filename_full);
		end
		script.func = func;
	end
	return script;
end

-- check load script code if any. It will only load on first call. Subsequent calls will be very fast. 
-- usually one do not need to call this function explicitly, unless one wants to preload or reload. 
-- @param bReload: default to nil. 
function GameRules:CheckLoadScript(filename, bReload)
	local script = self:GetScript(filename, bReload);
	if(script and script.func and (bReload or not script.isLoaded)) then
		script.isLoaded = true;
		-- load on first activation call.
		setfenv(script.func, self:GetRuleFileScriptScope());
		local ok, errmsg = pcall(script.func);
		if(ok) then
			LOG.std(nil, "info", "GameRules", "loaded game rule file: %s", filename);
		else
			LOG.std(nil, "error", "GameRules", errmsg);
			GameLogic.ShowMsg(errmsg);
		end
	end
end

-- execute a string in rule env. 
-- @return value. 
function GameRules:DoString(code)
	if(type(code) == "string") then
		local code_func, errormsg = loadstring(code, "GameRules:DoString");
		if(code_func) then
			setfenv(code_func, self:GetRuleFileScriptScope());
			local ok, result = pcall(code_func);
			if(not ok) then
				LOG.std(nil, "error", "GameRules", result);
				GameLogic.ShowMsg(result);
			else
				return result;
			end
		else
			LOG.std(nil, "error", "GameRules", "<Runtime error> syntax error while loading code %s\n%s", code, tostring(errormsg));
			GameLogic.ShowMsg(format("<syntax error>:%s|%s", code, tostring(errormsg)))
		end
	end
end


-- add a new rule to the currently defined rule set
-- e.g. 
--		this:AddRule("Player", "AutoWalkupBlock", true);
-- @param class_name: class name such as "Player", "Global"
-- @param rule_name: rule command name or text. used as key during GetRule();
-- @param rule_value: this is usually nil. 
function GameRules:AddRule(class_name, rule_name, rule_value)
	local class = self:GetRuleClass(class_name)
	if(class) then
		local rule = class:new():Init(rule_name, rule_value);
		if(rule) then
			self.rules[rule_name] = rule;
		end
	end
end

-- return a given rule by name, it may return nil if rule does not exist. 
function GameRules:GetRule(rule_name)
	return self.rules[rule_name];
end


function GameRules:ShowAllRules()
	if(self.rules) then
		local i = 0;
		for name, rule in pairs(self.rules) do
			i = i+1;
			GameLogic.RunCommand("tip", format("-rule%d %s", i, name));
		end
		if(i == 0) then
			GameLogic.RunCommand("tip", "no rules are defined.");
		end
	end
end



