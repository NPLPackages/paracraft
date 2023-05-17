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

-- get the entity associated with the actor, or get global entity by name
function env_imp:GetEntity(name)
    if(name and name~="") then
		return EntityManager.GetEntity(name);
    elseif(self.actor) then
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

local actor_value_type = {
	["name"] = "string",
	["physicsRadius"] = "number",
	["physicsHeight"] = "number",
	["isBlocker"] = "boolean",
	["isLodEnabled"] = "boolean",
	["groupId"] = "number",
	["sentientRadius"] = "number",
	["x"] = "number",
	["y"] = "number",
	["z"] = "number",
	["time"] = "number",
	["facing"] = "number",
	["walkSpeed"] = "number",
	["pitch"] = "number",
	["roll"] = "number",
	-- ["color"] = "string",
	["opacity"] = "number",
	-- ["selectionEffect"] = "string or number",
	["isAgent"] = "boolean",
	["zorder"] = "number",
	["movieactor"] = "number",
	["playSpeed"] = "number",
	-- ["billboarded"] = "table",
	["shadowCaster"] = "boolean",
	["isServerEntity"] = "boolean",
	["dummy"] = "boolean",
	["gravity"] = "number",
	["velocity"] = "number",
	["addVelocity"] = "number",
	["surfaceDecay"] = "number",
	["airDecay"] = "number",
	["isRelativePlay"] = "boolean",
	["isIgnoreSkinAnim"] = "boolean",
	-- ["parent"] = "string",
	["parentOffset"] = "number",
	["parentRot"] = "number",
}

function env_imp:setActorValue(name, value, v2, v3)
	if (actor_value_type[name] == "number") then
		value = tonumber(value);
		if (value == nil) then return print("setActorValue 设置无效值:", value) end 
	end
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

-- importing a library is the alternative way of placing code blocks in the scene. 
-- A library is a group of code blocks in the form of files. These files are usually organized in a folder with the same name of the library. 
-- for example, when import("abc"), we will load all files in ./lib/abc/*.* as code blocks. These code blocks are loaded only once in a given world, 
-- but can be imported multiple times. When the last code block that is importing a library is stopped, the imported libary will be unloaded. 
-- This also makes debugging a library easy by just restarting the code block that referenced it. 
-- When importing a lib, we will first search in the current world directory's ./lib folder for a given library, and then in system library folder, which is ..Game/Code/lib folder.
-- The advantage of using library is for making the scene cleaner than placing code blocks.
-- @param libName: import a library by name. loading all files in  "./lib/[libName]/*.*" folder.
function env_imp:import(libName)
	if(self.codeblock) then
		local library = self.codeblock:ImportCodeLibrary(libName)
		if(not library or library:IsEmpty()) then
			env_imp.exit(self);
		end
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

function env_imp:string_length(var, str)
	if (type(var) == "table") then return #var end 
	if (type(var) == "string") then return ParaMisc.GetUnicodeCharNum(var) end 

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

function env_imp:List_GetIndexByItem(list, item)
    if (type(list) ~= "table") then
        return nil
    end
    for index, val in ipairs(list) do
        if (val == item) then
            return index
        end
    end
    return nil;
end

function env_imp:List_IsExistItem(list, item)
    if (type(list) ~= "table") then
        return false
    end
    for index, val in ipairs(list) do
        if (val == item) then
            return true
        end
    end
    return false;
end

function env_imp:List_Insert(list, index, item)
    if (type(list) ~= "table") then
        return nil
    end
    if (index ~= nil and item == nil) then
        item, index = index, #list + 1
    end
    return table.insert(list, index, item);
end

function env_imp:List_Remove(list, index)
    if (type(list) ~= "table") then
        return nil
    end
    return table.remove(list, index);
end

function env_imp:List_Length(list)
    if (type(list) ~= "table") then
        return 0
    end
    return #(list);
end

-- get url synchronously or async according to whether callbackFunc is nil. 
-- @param url_params: {url=string, options={}, form={}, headers={}, json=true}, see also System.os.GetUrl(). 
-- @param callbackFunc: function(data, errCode, msg) end. if nil, this function is synchronous, if not this function is async. 
-- @return data, errCode, msg: data can be nil or msg if no json object. The second parameter is always http code, the third is HTML message. 
function env_imp:getUrl(url_params, callbackFunc)
	if(not callbackFunc) then
		local err_, msg_, data_
		System.os.GetUrl(url_params, self.co:MakeCallbackFunc(function(err, msg, data)
			err_, msg_, data_ = err, msg, data
			env_imp.resume(self, err, msg, data);
		end))
		env_imp.yield(self)
		if(data_) then
			return data_, err_, msg_;
		elseif(err_ == 200) then
			return msg_, err_, msg_;
		else
			return nil, err_, msg_;	
		end
	else
		System.os.GetUrl(url_params, self.co:MakeCallbackFuncAsyncRun(function(err, msg, data)
			if(not data and err == 200) then
				data = msg;
			end
			callbackFunc(data, err, msg)
		end))
	end
end
