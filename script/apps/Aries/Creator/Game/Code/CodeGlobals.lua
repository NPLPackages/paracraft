--[[
Title: Code API Globals
Author(s): LiXizhi
Date: 2018/5/27
Desc: all global user-defined variables and shared global API in CodeAPI. 
Each world has a single shared global table, we allow users to list and define custom variables inside this table.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeGlobals.lua");
local CodeGlobals = commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals");
local _G = GameLogic.GetCodeGlobal():GetWorldGlobals();
GameLogic.GetCodeGlobal():GetCurrentMetaTable();
GameLogic.GetCodeGlobal():CreateGetTextEvent("msgname");
GameLogic.GetCodeGlobal():BroadcastStartEvent();
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUI.lua");
NPL.load("(gl)script/ide/System/Windows/Application.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyServerViaTunnel.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local LobbyServer = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServer");
local LobbyServerViaTunnel = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyServerViaTunnel");
local Application = commonlib.gettable("System.Windows.Application");
local CodeUI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUI");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local CodeGlobals = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeGlobals"));

CodeGlobals:Signal("logAdded", function(text) end)

function CodeGlobals:ctor()
	-- exposing these API to globals
	self.shared_API = {
		ipairs = ipairs,
		next = next,
		pairs = pairs,
		tostring = tostring,
		tonumber = tonumber,
	
		type = type,
		unpack = unpack,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		rawset = rawset,
		rawget = rawget,
		assert = assert,
		math = { abs = math.abs, acos = math.acos, asin = math.asin, 
			  atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos, 
			  cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor, 
			  fmod = math.fmod, frexp = math.frexp, huge = math.huge, 
			  ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, 
			  min = math.min, modf = math.modf, pi = math.pi, pow = math.pow, 
			  rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh, 
			  sqrt = math.sqrt, tan = math.tan, tanh = math.tanh, 
			  tonumber = tonumber, tostring=tostring },
		bit = mathlib.bit,
		mathlib = mathlib,
		string = { byte = string.byte, char = string.char, find = string.find, 
			  format = string.format, gmatch = string.gmatch, gsub = string.gsub, 
			  len = string.len, lower = string.lower, match = string.match, 
			  rep = string.rep, reverse = string.reverse, sub = string.sub, 
			  upper = string.upper },
		format = string.format,
		table = { insert = table.insert, maxn = table.maxn, remove = table.remove, 
			getn = table.getn, sort = table.sort, concat = table.concat, clear=table.clear, contains = CodeGlobals.table_contains },
		os = { clock = os.clock, difftime = os.difftime, time = os.time, date = os.date },
		real = function(bx,by,bz)
			return BlockEngine:real(bx,by,bz);
		end,
		block = function(x,y,z)
			return BlockEngine:block(x,y,z);
		end,
		select = function(block_id)
			GameLogic.SetBlockInRightHand(block_id)
		end,
		set = function(name, value)
			self:SetGlobal(name, value);
		end,
		get = function(name)
			return self:GetGlobal(name);
		end,
		hideVariable = function(name, title)
			CodeUI:HideGlobalData(name, title);
		end,
		tip = function(text, duration, color)
			return GameLogic.AddBBS("CodeGlobals", text and tostring(text), duration, color);
		end,
		-- return blockX, blockY, blockZ, block_id, side
		mousePickBlock = function(picking_dist)
			local result = SelectionManager:MousePickBlock(true, false, false, picking_dist);
			return result.blockX, result.blockY, result.blockZ, result.block_id, result.side;
		end,
		-- get block id and data at given position
		getBlock = function(x,y,z)
			return BlockEngine:GetBlockIdAndData(math.floor(x), math.floor(y), math.floor(z));
		end,
		-- get the block entity: advanced function
		getBlockEntity = function(x, y, z)
			return EntityManager.GetBlockEntity(math.floor(x), math.floor(y), math.floor(z));
		end,
		-- set block id at given position
		-- @param blockId: can be number or string of "id:data"
		setBlock = function(x,y,z, blockId, blockData, entity_data)
			if(type(blockId) == "string") then
				local id, data = blockId:match("^(%d+):?(%d*)");
				if(id) then
					blockId = tonumber(id)
					if(data and data~="") then
						blockData = tonumber(data);
					end
				else
					return
				end
			end
			return BlockEngine:SetBlock(math.floor(x), math.floor(y), math.floor(z), blockId, blockData, 3, entity_data);
		end,
		-- similar to setBlock, except that we will add to history to allow undo/redo
		createBlock = function(x,y,z, blockId, blockData, entity_data)
			if(type(blockId) == "string") then
				local id, data = blockId:match("^(%d+):?(%d*)");
				if(id) then
					blockId = tonumber(id)
					if(data and data~="") then
						blockData = tonumber(data);
					end
				else
					return
				end
			end
			--local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, blocks = {{0,0,0,blockId, blockData, entity_data}}})
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, block_id = blockId, data = blockData, itemStack = ItemStack:new():Init(blockId, 1, entity_data)})
			task:Run();
		end,
		-- similar to commonlib.gettable(tabNames) but in page scope.
		-- @param tabNames: table names like "models.users"
		gettable = function(tabNames)
			return commonlib.gettable(tabNames, self:GetCurrentGlobals());
		end,
		-- similar to commonlib.createtable(tabNames) but in world scope.
		-- @param tabNames: table names like "models.users"
		createtable = function (tabNames, init_params)
			return commonlib.createtable(tabNames, init_params, self:GetCurrentGlobals());
		end,
		-- same as commonlib.inherit()
		-- @param baseClass: string or table or nil
		-- @param new_class: string or table or nil
		inherit = function(baseClass, new_class, ctor)
			if(type(baseClass) == "string") then
				baseClass = commonlib.gettable(baseClass, self:GetCurrentGlobals());
			end
			if(type(new_class) == "string") then
				new_class = commonlib.gettable(new_class, self:GetCurrentGlobals());
			end
			return commonlib.inherit(baseClass, new_class, ctor);
		end,
		saveUserData = function(name, value, bIsGlobal, bDeferSave)
			return GameLogic.GetPlayerController():SaveLocalUserWorldData(name, value, bIsGlobal, bDeferSave)
		end,
		loadUserData = function(name, default_value, bIsGlobal)
			return GameLogic.GetPlayerController():LoadLocalUserWorldData(name, default_value, bIsGlobal)
		end,
		saveWorldData = function(name, value, filename)
			return self:SaveWorldData(name, value, filename)
		end,
		loadWorldData = function(name, default_value, filename)
			return self:LoadWorldData(name, default_value, filename)
		end,
		-- @return x,y: x in [-500, 500] range
		getMousePoint = function()
			return self:GetMousePoint();
		end,
		Camera = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Camera.lua"),
		----------------------
		-- @NOTE: the following may not be safe to expose to users
		----------------------
		NPL = { load = NPL.load },
		System = System, 
		commonlib = commonlib, 
		ParaIO = ParaIO,
		ParaAsset = ParaAsset,
		GameLogic = GameLogic,
        NplOce = NplOce,
		_guihelper = _guihelper,
		Game = MyCompany.Aries.Game,
	};
	
	self:Reset();

	GameLogic:Connect("beforeWorldSaved", self, self.OnWorldSave, "UniqueConnection");
	GameLogic:Connect("frameMoved", self, self.OnFrameMove, "UniqueConnection");
end

-- call this to clear all globals to reuse this class for future use. 
function CodeGlobals:Reset()
	local curGlobals = {};
	self.curGlobals = curGlobals;
	self.cur_co = nil;
	-- look in global table first, and then in shared API. 
	local meta_table = {__index = function(tab, name)
		if(name == "__LINE__") then
			local info = debug.getinfo(2, "l")
			if(info) then
				return info.currentline;
			end
		elseif(name == "co") then
			return self.cur_co;
		elseif(name == "actor") then
			return self.cur_co and self.cur_co:GetActor();
		elseif(name == "document") then
			return document;
		elseif(name == "GI") then
			return self:GetSandboxAPI();
		end
		local value = curGlobals[name];
		if(value==nil) then
			value = self.shared_API[name];
		end
		return value;
	end}
	self.curMetaTable = meta_table;

	self.text_events = {};

	self.actors = {};
	self.playerActor = nil;

	-- active code blocks
	self.codeblocks= {};

	-- world data
	self.worldData = nil;

	-- clear UI if any
	CodeUI:Clear();

	-- TODO: 
	LobbyServer.GetSingleton():Connect("handleMessage", self, self.handleNetworkEvent, "UniqueConnection");
	LobbyServerViaTunnel.GetSingleton():Connect("handleMessage", self, self.handleNetworkEvent, "UniqueConnection");
end

function CodeGlobals:GetGI()
	if (self.__GI__) then return self.__GI__ end
	self.__GI__ = NPL.load("Mod/GeneralGameServerMod/GI/GI.lua");
	return self.__GI__;
end

function CodeGlobals:GetSandboxAPI()
	-- 边学边玩可能不更新GGS代码 导致GI可能不存在
	if (not self:GetGI()) then return end
	
	return self:GetGI():GetCodeBlockAPI();
end

function CodeGlobals:log(obj, ...)
	local text;
	local args = {...};
	local bPrintArgs = #args > 0;
	if(type(obj) == "string") then
		text = obj;
		if(obj:match("%%")) then
			if(bPrintArgs) then
				text = string.format(obj, ...);
				bPrintArgs = false;
			end
		end
	else
		text = commonlib.serialize_in_length(obj, 100);
	end
	if(bPrintArgs) then
		for _, arg in ipairs(args) do
			if(type(arg) == "string") then
				text = text.." "..arg;
			else
				text = text.." "..commonlib.serialize_in_length(arg, 100);
			end
		end
	end
	if(text) then
		commonlib.echo(text);
		self:logAdded(text);
		GameLogic.AppendChat(text);
	end
end

-- similar to self:log, except that the first parameter does not support %s formating
function CodeGlobals:print(...)
	local text;
	local args = {...};
	for _, arg in ipairs(args) do
		if(text) then
			text = text.." "
		else
			text = "";
		end
		if(type(arg) == "string") then
			text = text..arg;
		else
			text = text..commonlib.serialize_in_length(arg, 100);
		end
	end
	if(text) then
		commonlib.echo(text);
		self:logAdded(text);
		GameLogic.AppendChat(text);
	end
end


-- @return x,y: x in [-500, 500] range
function CodeGlobals:GetMousePoint()
	local x, y = Mouse:GetMousePosition();

	local viewport = ViewportManager:GetSceneViewport();
	local screenWidth, screenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();

	x = x * 1000 / screenWidth - 500;
	local ry = 1000 * screenHeight / screenWidth
	y = -(y * ry / screenHeight - ry * 0.5);
	return math.floor(x+0.5), math.floor(y+0.5);
end

function CodeGlobals:OnFrameMove()	
	self:BroadcastTextEvent("onTick");
end

function CodeGlobals:OnWorldSave()
	if(self.worldData) then
		for filename, data in pairs(self.worldData) do
			if(data.isDirty_) then
				local filepath = GameLogic.GetWorldDirectory().."codeblockdata/"..filename;
				ParaIO.CreateDirectory(filepath);
				local file = ParaIO.open(filepath, "w");
				if(file:IsValid()) then
					data.isDirty_ = nil;
					local text = commonlib.serialize(data, true)
					if(text) then
						file:write(text,#text);
					end
					file:close();
					LOG.std(nil, "info", "CodeGlobals", "save world data to %s", filepath);
				else
					LOG.std(nil, "warn", "CodeGlobals", "failed to save world data to %s", filepath);
				end
			end
		end
	end
end

-- save data to world directory, usually used in level editor code
-- the actual saving happens when user saved the whole world
-- @param filename: if nil, it defaults to "worlddata"
function CodeGlobals:SaveWorldData(name, value, filename)
	filename = filename or "worlddata"
	if(not self.worldData) then
		self.worldData = {};
	end
	local data = self.worldData[filename];
	if(not data) then
		data = {};
		self.worldData[filename] = data;
	end
	data.isDirty_ = true;
	data[name] = value;
end

function CodeGlobals:LoadWorldData(name, value, filename)
	filename = filename or "worlddata"
	local data = self.worldData and self.worldData[filename]
	if(not data) then
		local filepath = GameLogic.GetWorldDirectory().."codeblockdata/"..filename;
		local file = ParaIO.open(filepath, "r");
		if(file:IsValid()) then
			data = NPL.LoadTableFromString(file:GetText())
			if(type(data) == "table") then
				data.isDirty_ = false;
			end
			file:close();
		end
		self.worldData = self.worldData or {};
		data = data or {};
		self.worldData[filename] = data;
	end
	return data[name or ""];
end

function CodeGlobals:SetCurrentCoroutine(co)
	self.cur_co = co;
end

function CodeGlobals:GetCurrentCodeBlock()
	return self.cur_co and self.cur_co.codeBlock;
end

function CodeGlobals:AddCodeBlock(codeblock)
	self.codeblocks[codeblock:GetBlockName()] = codeblock;
end

function CodeGlobals:RemoveCodeBlock(codeblock)
	if(self.codeblocks[codeblock:GetBlockName()] == codeblock) then
		self.codeblocks[codeblock:GetBlockName()] = nil;
	end
end

function CodeGlobals:GetCodeBlockByName(name)
	return self.codeblocks[name];
end

function CodeGlobals:AddActor(actor)
	local name = actor:GetName() or ""
	if(name ~= "") then
		local actors = self.actors[name];
		if(not actors) then
			actors = commonlib.UnorderedArraySet:new();
			self.actors[name] = actors;
		end
		actors:add(actor)
	end
	actor:Connect("nameChanged", self, self.OnActorNameChange, "UniqueConnection");
	actor:Connect("beforeRemoved", self, self.RemoveActor, "UniqueConnection");
end

function CodeGlobals:RemoveActor(actor)
	local name = actor:GetName() or "";
	if(name ~= "") then
		local actors = self.actors[name];
		if(actors) then
			actors:removeByValue(actor);
			if(actors:empty()) then
				self.actors[name] = nil;
			end
		end
	end
end

function CodeGlobals:OnActorNameChange(actor, oldName, newName)
	local name = oldName or "";
	if(name ~= "") then
		local actors = self.actors[name];
		if(actors) then
			actors:removeByValue(actor);
			if(actors:empty()) then
				self.actors[name] = nil;
			end
		end
	end
	name = newName or "";
	if(name ~= "") then
		local actors = self.actors[name];
		if(not actors) then
			actors = commonlib.UnorderedArraySet:new();
			self.actors[name] = actors;
		end
		actors:add(actor)
	end
end

-- return the last added actor by name
function CodeGlobals:GetActorByName(name)
	local actors = self.actors[name];
	return actors and actors:last();
end

-- return array of all actors by the same name
function CodeGlobals:GetActorsByName(name)
	return self.actors[name];
end

function CodeGlobals:GetPlayerActor()
	if(not self.playerActor) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
		local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
		local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
		local item = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1);
		self.playerActor = CodeActor:new():Init(item);
		self.playerActor:BecomeAgent(EntityManager.GetPlayer())
	end
	return self.playerActor;
end

-- @param name: actor name or "@p" for current player
function CodeGlobals:FindEntityByName(name)
	local actor2 = self:GetActorByName(name);
	if(actor2) then
		return actor2:GetEntity();
	elseif(name=="@p") then
		return EntityManager.GetPlayer();
	end
end

-- all user defined variables that is shared by all blocks in the current world
function CodeGlobals:GetCurrentGlobals()
	return self.curGlobals;
end

-- @return mapping of {text, event_object}
function CodeGlobals:GetAllTextEvents()
	return self.text_events;
end

function CodeGlobals:GetTextEvent(text)
	return self.text_events[text];
end

function CodeGlobals:CreateGetTextEvent(text)
	local event = self.text_events[text];
	if(not event) then
		event = commonlib.EventSystem:new();
		self.text_events[text] = event;
	end
	return event;
end

function CodeGlobals:BroadcastStartEvent()
	self:BroadcastTextEvent("start");
end

function CodeGlobals:RegisterKeyPressedEvent(callbackFunc)
	self:CreateGetTextEvent("keyPressedEvent"):AddEventListener("msg", callbackFunc);
end

function CodeGlobals:BroadcastKeyPressedEvent(keyname, param1)
	self:SetAnyKeyDown(true);
	local event = self:GetTextEvent("keyPressedEvent");
	if(event) then
		return event:DispatchEvent({type="msg", keyname = keyname, param1 = param1});
	end
end

function CodeGlobals:UnregisterKeyPressedEvent(callbackFunc)
	self:UnregisterTextEvent("keyPressedEvent", callbackFunc)
end

function CodeGlobals:RegisterBlockClickEvent(callbackFunc)
	self:CreateGetTextEvent("onBlockClicked"):AddEventListener("msg", callbackFunc);
end

function CodeGlobals:BroadcastBlockClickEvent(blockid)
	local event = self:GetTextEvent("onBlockClicked");
	if(event) then
		local result = SelectionManager:MousePickBlock();
		if(result and result.block_id and result.block_id>0 and result.blockX) then
			return event:DispatchEvent({type="msg", blockid = result.block_id, param1 = {
				blockid = result.block_id,
				x = result.blockX, y = result.blockY, z = result.blockZ, side = result.side
			}});
		end
	end
end

function CodeGlobals:UnregisterBlockClickEvent(callbackFunc)
	self:UnregisterTextEvent("onBlockClicked", callbackFunc)
end

-- @param bIsImmediate: if true, the code block needs to immediately process it. 
function CodeGlobals:HandleGameEvent(event, bIsImmediate)
	local textEvent = self:GetTextEvent(event:GetType());
	if(textEvent) then
		local msg = event.msg;
		if(not msg) then
			local trigger_entity = EntityManager.GetLastTriggerEntity();
			if(trigger_entity) then
				-- if no message body is provided, we will send the triggering entity name
				-- this is useful to get the source entity's name, such as a network player
				msg = trigger_entity:GetName();
			end
		end
		
		if(event.cmd_text and event.cmd_text~="") then
			msg = event.cmd_text;
		end

		return textEvent:DispatchEvent({type="msg", msg = msg, dest = event.dest, bIsImmediate = bIsImmediate}, nil, bIsImmediate);
	end
end

function CodeGlobals:BroadcastTextEvent(text, msg, onFinishedCallback)
	local event = self:GetTextEvent(text);
	if(event) then
		if(onFinishedCallback) then
			local nHandlerCount = event:GetEventHandlerCount("msg");
			if(nHandlerCount > 1) then
				local oldCallback = onFinishedCallback;
			
				local nCount = 0;
				onFinishedCallback = function()
					nCount = nCount + 1;
					if(nHandlerCount == nCount) then
						oldCallback();
					end
				end;
			end
		end
		return event:DispatchEvent({type="msg", msg=msg, onFinishedCallback=onFinishedCallback});
	else
		if(onFinishedCallback) then
			onFinishedCallback();
		end
	end
end

-- similar to BroadcastTextEvent
-- @paramm dest: dest actor name. 
function CodeGlobals:BroadcastTextEventTo(dest, text, msg)
	local event = self:GetTextEvent(text);
	if(event) then
		return event:DispatchEvent({type="msg", dest=dest, msg=msg});
	end
end

function CodeGlobals:RegisterTextEvent(text, callbackFunc)
	self:CreateGetTextEvent(text):AddEventListener("msg", callbackFunc);
end

function CodeGlobals:UnregisterTextEvent(text, callbackFunc)
	local event = self:GetTextEvent(text);
	if(event) then
		event:RemoveEventListener("msg", callbackFunc);
	end
end

-- try to start lobby server if not started. 
-- @param bSigninIfNot: whether to force signin
function CodeGlobals:CheckLobbyServer(bSigninIfNot)


	--self.isLobbyStarted = LobbyServer.GetSingleton():IsStarted() and LobbyServerViaTunnel.GetSingleton():IsStarted();
	
	local lobbyServerStarted = LobbyServer.GetSingleton():IsStarted();
	local LobbyServerViaTunnelStarted = LobbyServerViaTunnel.GetSingleton():IsStarted();
	
	local function OnLobbyViaTunnelStartedGlobal(_, msg)
		self:UnregisterTextEvent("OnLobbyViaTunnelStartedGlobal", OnLobbyViaTunnelStartedGlobal);
		self.hasAskedSignin = false;
	end
	
	local function OnLobbyStartedGlobal(_, msg)

		self:UnregisterTextEvent("OnLobbyStartedGlobal", OnLobbyStartedGlobal);
		if msg.msg == "true" then
			if not LobbyServerViaTunnelStarted then
				self:RegisterTextEvent("OnLobbyViaTunnelStartedGlobal", OnLobbyViaTunnelStartedGlobal);
				GameLogic.RunCommand("/startLobbyServer -callback OnLobbyViaTunnelStartedGlobal -tunnelhost 1.tunnel.keepwork.com -tunnelport 8099");
			else
				self.hasAskedSignin = false;
			end
		else
			self.hasAskedSignin = false;
		end
	end
	
	local function onSignIn(bSucceed)
		if bSucceed then
			if not lobbyServerStarted then
				self:RegisterTextEvent("OnLobbyStartedGlobal", OnLobbyStartedGlobal);
				GameLogic.RunCommand("/startLobbyServer -callback OnLobbyStartedGlobal");
			else
				OnLobbyStartedGlobal(nil, {msg="true"})
			end
		else
			self.hasAskedSignin = false;
		end
	end
	
	if((not lobbyServerStarted or not LobbyServerViaTunnelStarted) and bSigninIfNot) then
		if(not self.hasAskedSignin) then
			self.hasAskedSignin = true;
			GameLogic.SignIn(L"", onSignIn);
		end
	end
	
	self.isLobbyStarted = lobbyServerStarted or LobbyServerViaTunnelStarted;
	return self.isLobbyStarted;
end

function CodeGlobals:RegisterNetworkEvent(event_name, callbackFunc)
	if(event_name:match("^ps_")) then
		-- for private server event
		self:RegisterTextEvent(event_name, callbackFunc);
		if(event_name == "ps_server_started" and GameLogic.isServer) then
			-- if server is already started when registering this event
			callbackFunc(_, {type="net", msg={username = "admin", entityId = EntityManager.GetPlayer().entityId, displayname=EntityManager.GetPlayer():GetDisplayName(), isServer = true}});
		end
	else
		local event = self:CreateGetTextEvent(event_name);
		event:AddEventListener("net", callbackFunc);
	
		if event_name == "connect" then
			self:CheckLobbyServer(true);
			local clients = LobbyServer.GetSingleton():GetClients();
			for k, v in pairs(clients) do
				event:DispatchEvent({type="net", msg={userinfo = v}});
			end
		
			clients = LobbyServerViaTunnel.GetSingleton():GetClients();
			for k, v in pairs(clients) do
				event:DispatchEvent({type="net", msg={userinfo = v}});
			end
		end
	end
	
end

function CodeGlobals:UnregisterNetworkEvent(text, callbackFunc, codeblock)
	if(text:match("^ps_")) then
		self:UnregisterTextEvent(text, callbackFunc);
	else
		local event = self:GetTextEvent(text);
		if(event) then
			event:RemoveEventListener("net", callbackFunc);
			if(text == "connect" and event:GetEventListenerCount("net") == 0) then
				LobbyServer.GetSingleton():StopAll();
				LobbyServerViaTunnel.GetSingleton():StopAll()
				self.isLobbyStarted = false;
			end
		end
	end
end

-- send a named message to one computer in the network
-- @param username: entity id or player name
-- @param event_name: if nil, we will send an binary stream (msg) to keepworkUsername, 
-- @param msg: msg.from will be the sender username if not filled. 
-- which needs to be nid/ip:port (*8099, \\\\10.27.3.5 8099)
function CodeGlobals:SendNetworkEvent(username, event_name, msg)
	if(GameLogic.isRemote) then
		if(type(msg) == "table") then
			msg.from = msg.from or EntityManager.GetPlayer():GetUserName();
		end
		-- client side code
		if(username == "host" or username == "admin") then
			GameLogic.GetPlayer():AddToSendQueue(Packets.PacketCodeBlockEvent:new():Init(event_name, msg));	
		elseif(username == nil or username == "@all") then
			-- redirect a broadcast to host
			GameLogic.GetPlayer():AddToSendQueue(Packets.PacketCodeBlockEvent:new():Init("ps_broadcast", {name=event_name, msg = msg}));	
		else
			-- redirect to target user
			GameLogic.GetPlayer():AddToSendQueue(Packets.PacketCodeBlockEvent:new():Init("ps_redirect", {username = username, name = event_name, msg = msg}));	
		end
	elseif(GameLogic.isServer) then
		if(type(msg) == "table") then
			msg.from = msg.from or "admin";
		end
		-- server side code
		if(username == "host" or username == "admin") then
			-- handle locally in the next time frame.
			commonlib.TimerManager.SetTimeout(function()  
				GameLogic.GetCodeGlobal():handleNetworkEvent(event_name, msg);
			end, 1)
			
		elseif(username == nil or username == "@all") then
			local servermanager = GameLogic.GetWorld():GetServerManager();
			if(servermanager) then
				servermanager:SendPacketToAllPlayers(Packets.PacketCodeBlockEvent:new():Init(event_name, msg));
			end
		else
			local targetEntity
			if(type(username) == "number") then
				targetEntity = EntityManager.GetEntityById(username);
			elseif(type(username) == "string") then
				targetEntity = EntityManager.GetEntity("__MP__"..username);
			end
			if targetEntity == GameLogic.GetPlayer() then
				-- handle locally in the next time frame. 
				commonlib.TimerManager.SetTimeout(function()  
					GameLogic.GetCodeGlobal():handleNetworkEvent(event_name, msg);
				end, 1)
			elseif targetEntity then
				if(targetEntity.SendPacketToPlayer) then
					targetEntity:SendPacketToPlayer(Packets.PacketCodeBlockEvent:new():Init(event_name, msg))
					return true;
				end
			end
		end
	elseif(self:CheckLobbyServer()) then
		if(event_name) then
			if LobbyServer.GetSingleton():IsStarted() then
				LobbyServer.GetSingleton():SendTo(username, event_name, msg);
			end
		
			if LobbyServerViaTunnel.GetSingleton():IsStarted() then
				LobbyServerViaTunnel.GetSingleton():SendTo(username, event_name, msg);
			end
		else
			if LobbyServer.GetSingleton():IsStarted() then
				LobbyServer.GetSingleton():SendOriginalMessage(username, msg);
			end
		
			if LobbyServerViaTunnel.GetSingleton():IsStarted() then
				LobbyServerViaTunnel.GetSingleton():SendOriginalMessage(username, msg);
			end
		end	
	end
end

-- send a named message to all computers in the network
function CodeGlobals:BroadcastNetworkEvent(event_name, msg)
	if(GameLogic.isRemote or GameLogic.isServer) then
		self:SendNetworkEvent("@all", event_name, msg)
	elseif(self:CheckLobbyServer()) then
		if LobbyServer.GetSingleton():IsStarted() then
			LobbyServer.GetSingleton():BroadcastMessage(event_name, msg)
		end
	
		if LobbyServerViaTunnel.GetSingleton():IsStarted() then
			LobbyServerViaTunnel.GetSingleton():BroadcastMessage(event_name, msg)
		end	
	end
end

-- when this computer received a message from the network.
-- test code: GameLogic.GetCodeGlobal():handleNetworkEvent("updateScore", {nid="aaa", score=1121})
-- @param event_name: "disconnect", "connect" are two predefined events alongside other user events
-- @param onFinishedCallback: can be nil
function CodeGlobals:handleNetworkEvent(event_name, msg, onFinishedCallback)
	local event = self:GetTextEvent(event_name);
	if(event) then
		event:DispatchEvent({type="net", msg=msg, onFinishedCallback=onFinishedCallback});
	end
end


function CodeGlobals:GetCurrentMetaTable()
	return self.curMetaTable;
end

function CodeGlobals:GetSharedAPI()
	return self.shared_API;
end

function CodeGlobals:SetGlobal(name, value)
	if(name) then
		self:GetCurrentGlobals()[name] = value
	end
end

function CodeGlobals:GetGlobal(name)
	return name and self:GetCurrentGlobals()[name];
end

-- @param keyname: if nil or "any", it means any key, such as "a-z", "space", "return", "escape"
-- @return "DIK_A" or nil
function CodeGlobals:GetKeyNameFromString(name)
	if(name) then
		local name2 = "DIK_"..string.upper(name);
		if(name and DIK_SCANCODE[name2]) then
			return name2;
		end
	end
end

function CodeGlobals:GetStringFromKeyName(name)
	if(name) then
		return string.lower(name:gsub("^(DIK_)" ,""));
	end
end

function CodeGlobals:IsAnyKeyDown()
	return self.isAnyKeyDown;
end

function CodeGlobals:SetAnyKeyDown(bKeyDown)
	self.isAnyKeyDown = bKeyDown;
end

-- helper function for table.contains
-- @return true or nil
function CodeGlobals.table_contains(obj, key)
	if(key == nil) then
		return
	end
	if(type(obj) == "table") then
		if(type(key) == "string" and obj[key]) then
			return true;
		end
		for k, v in ipairs(obj) do
			if(v == key) then
				return true;
			end
		end
	elseif(type(obj) == "string") then
		if(obj:match(tostring(key))) then
			return true;
		end
	end
end

-- @param keyname: if nil or "any", it means any key, such as "a-z", "space", "return", "escape"
function CodeGlobals:IsKeyPressed(keyname)
	-- ignore key press when UI has focus
	-- TODO: use GetGUI()->IsKeyboardProcessed() in C++, instead of just MCML v2 control
	if(self:IsAnyKeyDown() and not Application:focusWidget()) then
		keyname = self:GetKeyNameFromString(keyname);
		if(keyname) then
			if(ParaUI.IsKeyPressed(DIK_SCANCODE[keyname])) then
				return true;
			end
		end
	end
	return false;
end

