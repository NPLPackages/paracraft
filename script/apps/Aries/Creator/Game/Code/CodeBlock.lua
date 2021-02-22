--[[
Title: CodeBlock
Author(s): LiXizhi
Date: 2018/5/16
Desc: In addition to object oriented programming(oop), paracraft code block features an memory-oriented-programming(mop) model. 
The smallest memory unit is an animation clip over time. So we can also call it animation-oriented programming model. 
A program is made up of code block, where each code block is associated with one movie block, which contains a short animation
clip for an actor. Code block exposes a `CodeAPI` that can programmatically control the actor inside the movie block. 

CodeBlock can has unlimited inventory code actors, in addition to the default actor.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
local codeBlock = CodeBlock:new():Init(entityCode);
codeBlock:CompileCode('say("hi"); wait(2); say("bye")');
codeBlock:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCompiler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeEvent.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeUIActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeLightActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeUIActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeUIActor");
local CodeLightActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeLightActor");
local CodeEvent = commonlib.gettable("MyCompany.Aries.Game.Code.CodeEvent");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local CodeActor = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActor");
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");

local CodeBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock"));
CodeBlock:Property("Name", "CodeBlock");
CodeBlock:Property({"DefaultTick", 0.02, "GetDefaultTick", "SetDefaultTick", auto=true,});
CodeBlock:Property({"AutoWait", true, "IsAutoWait", "SetAutoWait", });
CodeBlock:Property({"modified", false, "IsModified", "SetModified", auto=true});
CodeBlock:Property({"maxEventCount", 500});
CodeBlock:Property({"isAllowClientExecution", false, "IsAllowClientExecution", "SetAllowClientExecution"})

CodeBlock:Signal("message", function(errMsg) end);
CodeBlock:Signal("actorClicked", function(actor, mouse_button) end);
CodeBlock:Signal("actorCloned", function(actor, msg) end);
CodeBlock:Signal("actorCollided", function(actor, fromActor) end);
CodeBlock:Signal("codeUnloaded", function() end);
CodeBlock:Signal("stateChanged", function() end);
CodeBlock:Signal("beforeStopped", function() end);

function CodeBlock:ctor()
	self.timers = {};
	self.timers_pool = {};
	self.actors = commonlib.UnorderedArraySet:new();
	self.events = {};
	self.startTime = 0;
	self.bAutoWait = true
end

function CodeBlock:Init(entityCode)
	self.entityCode = entityCode;
	self:AutoSetFilename();
	return self;
end

function CodeBlock:SetBlockName(name)
	if(self.entityCode and self.entityCode:GetDisplayName()~=name) then
		self.entityCode:SetDisplayName(name);
	end

	if(self.codename and self.codename~=name) then
		if(self:IsLoaded()) then
			-- it is better to reload the code block.
			self:SetModified(true);
			GameLogic.GetCodeGlobal():RemoveCodeBlock(self);
			self.codename = nil;
			self:AutoSetFilename();
			GameLogic.GetCodeGlobal():AddCodeBlock(self);
		else
			self.codename = nil;
			self:AutoSetFilename();
		end
	end
end

function CodeBlock:GetBlockName()
	if(not self.codename) then
		self.codename = self.entityCode and self.entityCode:GetDisplayName() or "";
	end
	return self.codename;
end

function CodeBlock:AutoSetFilename()
	if(self.entityCode) then
		local x,y,z = self.entityCode:GetBlockPos();
		if(x) then
			self:SetFilename(format("%s_block(%d, %d, %d)", self:GetBlockName(), x,y,z));
		end
	end
end

function CodeBlock:Destroy()
	self:Unload();
	CodeBlock._super.Destroy(self);
end

function CodeBlock:GetBlockPos()
	if(self.entityCode) then
		return self.entityCode:GetBlockPos();
	end
end

-- return the timer object
function CodeBlock:SetTimer(callbackFunc, dueTime, period)
	local timer;
	if(self.timers_pool and #self.timers_pool > 0) then
		timer = self.timers_pool[#self.timers_pool];
		self.timers_pool[#self.timers_pool] = nil;
		timer.callbackFunc = callbackFunc;
	else
		timer = commonlib.Timer:new({callbackFunc = callbackFunc})
	end
	self.timers[timer] = true;
	timer:Change(dueTime, period);
	return timer;
end

function CodeBlock:KillTimer(timer)
	timer:Change();
	if(self.timers[timer]) then
		self.timers[timer] = nil;
		if(#self.timers_pool < 10) then
			self.timers_pool[#self.timers_pool+1] = timer;
		end
	end
end

function CodeBlock:SetTimeout(duration, callbackFunc)
	return self:SetTimer(function(timer)
		self:KillTimer(timer);
		if(callbackFunc) then
			callbackFunc(timer);
		end
	end, duration, nil)
end

--@param code: the actual code
--@param filename: virtual filename, if nil, default to GetFilename()
--@return code_func, errormsg
function CodeBlock:CompileCodeImp(code, filename)
	filename = filename or self:GetFilename();
	local configFile = self:GetEntity():GetLanguageConfigFile()
	local compileCodeFunc = LanguageConfigurations:GetCompiler(configFile);
	if(compileCodeFunc) then
		return compileCodeFunc(code, filename, self)
	else
		local compiler = CodeCompiler:new():SetFilename(filename);
		if(self:GetEntity() and self:GetEntity():IsAllowFastMode()) then
			compiler:SetAllowFastMode(true);
		end
		return compiler:Compile(code);
	end
end

function CodeBlock:BeautifyCompilerErrorMsg(msg)
	if(msg) then
		msg = msg:gsub("invalid syntax at line (%d+) offset (%d+) in code", L"语法错误，在第%1行%2列的代码")
		msg = msg:gsub("(%]:)(%d+)(:)", L"%1第%2行%3")
		msg = msg:gsub("unfinished string near", L"没有完成的字符串在这个附近")
		msg = msg:gsub("expected near", L"被期待在这个附近")
		msg = msg:gsub("expected %(to close", L"被期待(去关闭")
		msg = msg:gsub("at line (%d+)", L"在第%1行")
		msg = msg:gsub("unexpected symbol near", L"不被期待的名字在这个附近")
		msg = msg:gsub("<eof>", L"文件的结束")
		msg = msg:gsub("%[string \"_block%(", L"[\"代码方块(")
		msg = msg:gsub("%s(near)%s", L"临近")
		msg = msg:gsub("malformed number", L"格式不对的数字")
	end
	return msg;
end

function CodeBlock:BeautifyRuntimeErrorMsg(msg)
	if(msg) then
		msg = msg:gsub("(%]:)(%d+)(:)", L"%1第%2行%3")
		msg = msg:gsub("a nil value", L"一个无效值nil")
		msg = msg:gsub("a table value", L"一个表值")
		msg = msg:gsub("<eof>", L"文件的结束")
		msg = msg:gsub("%[string \"_block%(", L"[\"代码方块(")
		msg = msg:gsub("%s(near)%s", L"临近")
		msg = msg:gsub("attempt to perform arithmetic on", L"尝试执行数学运算在")
		msg = msg:gsub("attempt to concatenate", L"尝试连接")
		msg = msg:gsub("attempt to call", L"尝试调用")
		msg = msg:gsub("attempt to compare", L"尝试比较")
		msg = msg:gsub("attempt to index", L"尝试索引")
	end
	return msg;
end


-- compile code and reload if code is changed. 
-- @param code: string
-- return error message if any
function CodeBlock:CompileCode(code)
	code = code or "";
	if(self:IsModified() or (self.last_code ~= code or not self.code_func)) then
		self:Unload();
		self:SetModified(false);
		self.last_code = code;
		self.code_func, self.errormsg = self:CompileCodeImp(code);
		if(not self.code_func and self.errormsg) then
			LOG.std(nil, "error", "CodeBlock", self.errormsg);
			local msg = self.errormsg;
			msg = format(L"编译错误: %s\n在%s", self:BeautifyCompilerErrorMsg(msg), self:GetFilename());
			self:send_message(msg, "error");
		else
			self:send_message(L"编译成功!");
		end
	else
		self:send_message(L"编译成功!");
	end
	return self.errormsg;
end

-- get default virtual code block filename. 
function CodeBlock:GetFilename()
	return self.filename or "";
end

function CodeBlock:SetFilename(filename)
	self.filename = filename;
end

function CodeBlock:IsLoaded()
	return self.isLoaded;
end

-- unload code and related entities
function CodeBlock:Unload()
	self:StopLastTempCode();
	if(not self.isLoaded) then
		return;
	end
	self.isLoaded = nil;
	self:Stop();
end

-- stop all nearby code entity
function CodeBlock:StopAll()
	if(self:GetEntity()) then
		self:GetEntity():Stop();
	end
end

-- restart all nearby code entity
function CodeBlock:RestartAll()
	if(self:GetEntity()) then
		self:GetEntity():Restart();
	end
end


-- remove everything to unloaded state. 
function CodeBlock:Stop()
	self:beforeStopped();

	self:SetAutoWait(false);
	self:FireEvent("onCodeBlockStopped", nil, nil, true)
	self:SetAutoWait(true);

	self:Disconnect("beforeStopped");
	self:Disconnect("actorClicked");
	self:Disconnect("actorCloned");
	self:Disconnect("actorCollided");
	self:RemoveTimers();
	self:RemoveAllActors();
	self.inventoryActors = nil;
	self:RemoveAllEvents();
	self:StopLastTempCode();
	self:SetOutput(0);

	self.code_env = nil;
	self.isLoaded = nil;
	GameLogic.GetCodeGlobal():RemoveCodeBlock(self);
	self.codename = nil;
	self:codeUnloaded();
	self:stateChanged();
	self:Disconnect("codeUnloaded");
	if(self.free_coroutines) then
		self.free_coroutines:clear();
		self.free_coroutines = nil;
	end
end

-- remove all timers without clearing actors.
function CodeBlock:Pause()
	self:RemoveTimers();
	self:RemoveAllEvents();
end

function CodeBlock:RemoveAllEvents()
	for name, events in pairs(self.events) do
		for _, event in ipairs(events) do
			event:Destroy();
		end
	end
	self.events = {};
end

function CodeBlock:RemoveTimers()
	if(self.timers) then
		for timer, _ in pairs(self.timers) do
			timer:Change();
		end
		self.timers = {};
	end
	if(self.timers_pool) then
		for _, timer in ipairs(self.timers_pool) do
			timer:Change();
		end
		self.timers_pool = {};
	end
end

-- usually called when movie finished playing. 
function CodeBlock:RemoveAllActors()
	self.refActors = nil;
	self.refCodeBlock = nil;
	
	self.isRemovingActors = true;
	for i, actor in ipairs(self:GetActors()) do
		actor:SetCodeBlock(nil);
		actor:OnRemove();
		actor:Destroy();
	end
	self:GetActors():clear();
	self.isRemovingActors = false;
	self:EnableActorPicking(false);
end

function CodeBlock:OnRemoveActor(actor)
	if(not self.isRemovingActors) then
		self:GetActors():removeByValue(actor);
	end
end

-- private function: do not call this function. 
function CodeBlock:AddActor(actor)
	self:GetActors():add(actor);
	actor:SetCodeBlock(self);
	actor:Connect("beforeRemoved", self:GetReferencedCodeBlock(), self:GetReferencedCodeBlock().OnRemoveActor);
	GameLogic.GetCodeGlobal():AddActor(actor);
end

function CodeBlock:GetActors()
	return self.refActors or self.actors;
end

function CodeBlock:GetLastActor()
	return self:GetActors()[#self:GetActors()];
end

function CodeBlock:GetFirstActor()
	return self:GetActors()[1];
end

-- referencing codeblock. It will share actors in the referenced code blocks. 
function CodeBlock:SetReferencedCodeBlock(codeBlock)
	if(self ~= codeBlock) then
		if(codeBlock) then
			if(self.refActors ~= codeBlock:GetActors()) then
				self.refActors = codeBlock:GetActors();
				codeBlock:Connect("actorClicked", self, self.OnClickActor, "UniqueConnection");
				codeBlock:Connect("actorCloned", self, self.OnCloneActor, "UniqueConnection");
				codeBlock:Connect("actorCollided", self, self.OnCollideActor, "UniqueConnection");
				self.refCodeBlock = codeBlock;
			end
		elseif(self.refActors) then
			self.refActors = nil;
			self.refCodeBlock = nil;
		end
	end
end

function CodeBlock:HasReferencedCodeBlock()
	return self.refActors ~= nil;
end

function CodeBlock:GetReferencedCodeBlock()
	return self.refCodeBlock or self;
end

-- get the last actor in all nearby connected code block. 
function CodeBlock:FindNearbyActor()
	local actor = self:GetLastActor();
	if(not actor and self:GetEntity() and not self:HasReferencedCodeBlock()) then
		local function getLastActor_(codeEntity)
			local x,y,z = codeEntity:GetBlockPos();
			if(codeEntity:GetNearByMovieEntity(x,y,z)) then
				local codeblock = codeEntity:GetCodeBlock();
				if(codeblock) then
					self:SetReferencedCodeBlock(codeblock);
					actor = codeblock:GetLastActor();
				end
				return true;
			end
		end
		self:GetEntity():ForEachNearbyCodeEntity(getLastActor_);
	end
	return actor;
end

function CodeBlock:GetMovieEntity()
	return self.entityCode:FindNearByMovieEntity();
end

function CodeBlock:GetEntity()
	return self.entityCode;
end


-- create a new actor from the nearby movie block. 
-- Please note one may create multiple actors from the same block.
-- return nil if no actor is found.
function CodeBlock:CreateActor()
	local actor = self:CreateFirstActorInMovieBlock();
	if(actor) then
		actor:SetName(self.entityCode:GetDisplayName());
		self:AddActor(actor);
		-- use time 0
		actor:SetTime(0);
		actor:FrameMove(0, false);
		local parentCodeBlock = self:GetReferencedCodeBlock();
		if(self:IsActorPickingEnabled()) then
			actor:EnableActorPicking(true);
			actor:Connect("clicked", parentCodeBlock, parentCodeBlock.OnClickActor);
		else
			actor:EnableActorPicking(false);
		end
		actor:Connect("collided", parentCodeBlock, parentCodeBlock.OnCollideActor);
		return actor;
	end
end

function CodeBlock:EnableActorPicking(bEnabled)
	if(self:GetActors().enableActorPicking ~= bEnabled) then
		self:GetActors().enableActorPicking	= bEnabled;
		if(bEnabled) then
			local parentCodeBlock = self:GetReferencedCodeBlock();
			for i, actor in ipairs(self:GetActors()) do
				if(not actor:IsActorPickingEnabled()) then
					actor:EnableActorPicking(true);
					actor:Connect("clicked", parentCodeBlock, parentCodeBlock.OnClickActor);
				end
			end
		end
	end
end

function CodeBlock:IsActorPickingEnabled()
	return self:GetActors().enableActorPicking;
end

-- private: 
-- @param movie_entity: can be nil
function CodeBlock:CreateFirstActorInMovieBlock(movie_entity)
	movie_entity = movie_entity or self:GetMovieEntity();
	if movie_entity and movie_entity.inventory then
		local actor;
		for i = 1, movie_entity.inventory:GetSlotCount() do
			local itemStack = movie_entity.inventory:GetItem(i)
			if (itemStack and itemStack.count > 0) then
				if (itemStack.id == block_types.names.TimeSeriesNPC) then
					actor = CodeActor:new():Init(itemStack, movie_entity, false, "codeblock");
					break;
				elseif (itemStack.id == block_types.names.TimeSeriesOverlay) then
					actor = CodeUIActor:new():Init(itemStack, movie_entity);
					break;
				elseif (itemStack.id == block_types.names.TimeSeriesLight) then
					actor = CodeLightActor:new():Init(itemStack, movie_entity);
					break;
				end
			end 
		end
		return actor;
	end
end

function CodeBlock:GetCodeEnv()
	if(not self.code_env) then
		self.code_env = CodeAPI:new(self);
	end
	return self.code_env;
end

function CodeBlock:IsLoaded()
	return self.isLoaded;
end

-- recompile and run
function CodeBlock:Restart(onFinishedCallback)
	if(self:GetEntity()) then
		self:Unload();
		return self:Run(onFinishedCallback);
	end
end

function CodeBlock:GetInventoryActor(slotIndex)
	return self.inventoryActors and self.inventoryActors[slotIndex];
end

-- holding a weak reference to the actor
function CodeBlock:SetInventoryActor(slotIndex, actor)
	self.inventoryActors = self.inventoryActors or {};
	self.inventoryActors[slotIndex] = actor;
end

function CodeBlock:RemoveAllInventoryActors()
	if(self.inventoryActors) then
		for slotIndex, actor in pairs(self.inventoryActors) do
			actor:DeleteThisActor();
		end
		self.inventoryActors = nil;
	end
end

-- it will refresh real inventory code actors if code block is loaded
-- otherwise it will refresh inventory movie actors if code block is NOT loaded. 
-- this function is called automatically when the code block inventory is changed. 
-- @param slotIndex: if nil, it will refresh all 
function CodeBlock:RefreshInventoryActor(slotIndex)
	if(not slotIndex) then
		if(self:IsLoaded()) then
			self:RefreshAllInventoryActors()
		else
			self:RefreshAllInventoryAsMovieActors()
		end
		return 
	end
	if(self:IsLoaded()) then
		local inventory = self:GetEntity():GetInventory()
		local itemStack = inventory:GetItem(slotIndex);
		if(itemStack and not self:GetInventoryActor(slotIndex)) then
			local actor = self:CloneMyself();
			if(actor) then
				actor:SetInitParams(itemStack:GetDataTable())
				actor:ApplyInitParams()
				self:SetInventoryActor(slotIndex, actor);
			end
		elseif(not itemStack) then
			local actor = self:GetInventoryActor(slotIndex);
			if(actor) then
				actor:DeleteThisActor();
				self:SetInventoryActor(slotIndex, nil);
			end
		else
			local actor = self:GetInventoryActor(slotIndex)
			actor:ApplyInitParams();
		end
	else
		local inventory = self:GetEntity():GetInventory()
		local itemStack = inventory:GetItem(slotIndex);
		if(itemStack and not self:GetInventoryMovieActor(slotIndex)) then
			local codeActorItem = self:GetEntity():GetCodeActorItemStack(slotIndex);
			if(codeActorItem) then
				local actor = codeActorItem:CreateMovieActor();
				if(actor) then
					self:SetInventoryMovieActor(slotIndex, actor);
				end
			end
		elseif(not itemStack) then
			local actor = self:GetInventoryMovieActor(slotIndex);
			if(actor) then
				actor:DeleteThisActor();
				self:GetInventoryMovieActor(slotIndex, nil);
			end
		else
			local actor = self:GetInventoryMovieActor(slotIndex)
			local codeActorItem = self:GetEntity():GetCodeActorItemStack(slotIndex);
			if(codeActorItem) then
				codeActorItem:ApplyInitParams(actor);
			end
		end
	end
end

function CodeBlock:RefreshAllInventoryActors()
	if(self:IsLoaded()) then
		self:RemoveAllInventoryActors();
		local inventory = self:GetEntity():GetInventory()
		for slotIndex = 1, inventory:GetSlotCount() do
			local itemStack = inventory:GetItem(slotIndex)
			if(itemStack and itemStack.count > 0 and itemStack.serverdata) then
				local actor = self:CloneMyself();
				if(actor) then
					actor:SetInitParams(itemStack:GetDataTable())
					actor:ApplyInitParams()
					self:SetInventoryActor(slotIndex, actor);
				end
			end
		end
	end
end

function CodeBlock:GetInventoryMovieActor(slotIndex)
	return self.inventoryMovieActors and self.inventoryMovieActors[slotIndex];
end

-- holding a weak reference to the actor
function CodeBlock:SetInventoryMovieActor(slotIndex, actor)
	self.inventoryMovieActors = self.inventoryMovieActors or {};
	self.inventoryMovieActors[slotIndex] = actor;
end

function CodeBlock:RemoveAllInventoryMovieActors()
	if(self.inventoryMovieActors) then
		for slotIndex, actor in pairs(self.inventoryMovieActors) do
			actor:DeleteThisActor();
		end
		self.inventoryMovieActors = nil;
	end
end

-- this function is used for rendering all instanced inventory actors in editor mode. 
-- only call this when code block is not loaded, it will show all inventory actors belonging to this code block
-- this could be inaccurate in turns of rendering, since they are not using any code block logics, but just
-- using data from movie block and initial params from the inventory's item stack. 
-- when code block is loaded,  these movie actors will be removed automatically
function CodeBlock:RefreshAllInventoryAsMovieActors()
	if(not self:IsLoaded()) then
		self:RemoveAllInventoryMovieActors();
		local movieEntity = self:GetMovieEntity();
		if(movieEntity) then
			local itemStack = movieEntity:GetFirstActorStack();
			if(itemStack) then
				local item = itemStack:GetItem();
				if(item and item.CreateActorFromItemStack) then
					local inventory = self:GetEntity():GetInventory()
					for slotIndex = 1, inventory:GetSlotCount() do
						local codeActorItem = self:GetEntity():GetCodeActorItemStack(slotIndex);
						if(codeActorItem) then
							local actor = codeActorItem:CreateMovieActor();
							if(actor) then
								self:SetInventoryMovieActor(slotIndex, actor);
							end
						end
					end
				end
			end
		end
	end
end

-- run code again 
function CodeBlock:Run(onFinishedCallback)
	self:GetEntity():ClearIncludedFiles();
	self:RemoveAllInventoryMovieActors();
	self:CompileCode(self:GetEntity():GetCommand());
	if(self.code_func) then
		self:ResetTime();
		self.isLoaded = true;
		self:stateChanged();
		local co = CodeCoroutine:new():Init(self);
		co:SetFunction(self.code_func);
		local actor = self:FindNearbyActor() or self:CreateActor();
		co:SetActor(actor);
		GameLogic.GetCodeGlobal():AddCodeBlock(self);
		local inventory = self:GetEntity():GetInventory()
		if(inventory and not inventory:IsEmpty()) then
			return co:Run(nil, function(...)
				self:RefreshAllInventoryActors();
				if(onFinishedCallback) then
					onFinishedCallback(...)
				end
			end);
		else
			return co:Run(nil, onFinishedCallback);
		end
		
	else
		self:ResetTime();
		self.isLoaded = true;
		self:stateChanged();
		local actor = self:FindNearbyActor() or self:CreateActor();
		self:RefreshAllInventoryActors();
		GameLogic.GetCodeGlobal():AddCodeBlock(self);
		return false;
	end
end

-- @param msg: string
-- @param msgType: if nil, it is a normal message. 
-- it can also be "error", if it is error, we will show to user via game console. 
function CodeBlock:send_message(msg, msgType)
	self.lastMessage = msg;
	self:message(msg);
	if(msgType == "error") then
		-- LOG.std(nil, "error", "CodeBlock", msg);
		local date_str, time_str = commonlib.log.GetLogTimeString();
		
		local text = commonlib.Encoding.EncodeHTMLInnerText(msg:sub(1, 1024));
		local html_text = format("<div style='color:#ff0000'><span style='color:#808080'>%s %s: </span>%s%s<div>", date_str, time_str, text, ((#msg)>1024) and "..." or "");
		GameLogic.SetTipText(html_text, nil, 10)
		if(not GameLogic.IsReadOnly() and not GameLogic.isRemote and not GameLogic.isServer) then
			GameLogic.ShowMsg(text);
		end
	end
end

function CodeBlock:GetLastMessage()
	return self.lastMessage;
end

-- @param msg: optional message to be passed to event callback
function CodeBlock:FireEvent(event_name, actor, msg, bIsImmediate)
	event_name = event_name or "";
	local events = self.events[event_name];
	if(events) then
		for _, event in ipairs(events) do
			if(actor) then
				event:SetActor(actor);
			end
			event:Fire(msg, nil, bIsImmediate);
		end
	end
end


function CodeBlock:CreateEvent(event_name)
	event_name = event_name or "";

	local events = self.events[event_name];
	if(not self.events[event_name]) then
		events = {};
		self.events[event_name] = events;
	end
	if(#events >= self.maxEventCount) then
		self:send_message(L"注册了太多同名事件"..event_name, "error");
		self:Stop();
		return
	end
	local event = CodeEvent:new():Init(self, event_name);
	events[#events + 1] = event;
	return event;
end

-- when the actor start/end playing at the given time (milliseconds)
-- Only the start and end of an animation is fired. 
function CodeBlock:RegisterAnimationEvent(time, callbackFunc)
	if(callbackFunc and time) then
		local event = self:CreateEvent("onAnimateActor");
		if(not event) then
			return
		end
		event:SetIsFireForAllActors(false);
		event:SetCanFireCallback(function(actor, curTime)
			return (time == curTime);
		end);
		event:SetFunction(callbackFunc);
		return event;
	end
end

function CodeBlock:OnAnimateActor(actor, time)
	self:FireEvent("onAnimateActor", actor, time)
end

-- actor is clicked
function CodeBlock:RegisterClickEvent(callbackFunc)
	self:EnableActorPicking(true);
	local event = self:CreateEvent("onClickActor");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(false);
	event:SetFunction(callbackFunc);
end

-- use this sparingly, because we will disable auto yield in this mode. 
function CodeBlock:RegisterStopEvent(callbackFunc)
	local event = self:CreateEvent("onCodeBlockStopped");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
end

-- @param blockname: block id or name, if nil or "any", it matches all blocks
function CodeBlock:RegisterBlockClickEvent(blockname, callbackFunc)
	local event = self:CreateEvent("onBlockClicked");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);

	local blockid, _;
	if(type(blockname) == "string" and blockname ~= "any") then
		blockid, _ = CmdParser.ParseBlockId(blockname);
	elseif(type(blockname) == "number") then
		blockid = blockname
	end
	
	local function onEvent_(_, msg)
		if(not msg) then
			return 
		end
		local bFire;
		if(not blockid) then
			bFire = true;
		elseif(blockid == msg.blockid) then
			bFire = true;
		end
		if(bFire) then
			event:Fire(msg.param1 or msg);
			return true;
		end
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterBlockClickEvent(onEvent_);
	end)
	GameLogic.GetCodeGlobal():RegisterBlockClickEvent(onEvent_);
end

function CodeBlock:OnClickActor(actor, mouse_button)
	self:FireEvent("onClickActor", actor);
	self:actorClicked(actor, mouse_button);
end

-- we will accept these keys, so that base context does not process them. 
local nonAcceptingKeys = {
	["mouse_buttons"] = true, ["mouse_wheel"] = true, ["escape"] = true,
}

local mouseKeys = {
	["mouse_buttons"] = true, ["mouse_wheel"] = true
}


-- @param keyname: if nil or "any", it means any key, such as "a-z", "space", "return", "escape", "mouse_wheel", "mouse_buttons"
-- @param callbackFunc: if keyname is "any", this function will block key if it returns true. 
-- case insensitive
function CodeBlock:RegisterKeyPressedEvent(keyname, callbackFunc)
	local event = self:CreateEvent("onKeyPressed");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetStopLastEvent(false);
	event:SetFunction(callbackFunc);
	keyname = GameLogic.GetCodeGlobal():GetKeyNameFromString(keyname) or keyname;
	
	local function onEvent_(_, msg)
		if(not msg) then
			return 
		end
		local bFire;
		local bImmediateMode;
		local result;
		if(not keyname or keyname == "any") then
			if(not mouseKeys[msg.keyname or ""]) then
				bFire = true;
				bImmediateMode = true;
			end
		elseif(keyname == msg.keyname) then
			if(not nonAcceptingKeys[keyname]) then
				result = true;
			end
			bFire = true;
		end
		if(bFire) then
			return event:Fire(msg.param1 or msg, nil, bImmediateMode) or result;
		end
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterKeyPressedEvent(onEvent_);
	end)
	GameLogic.GetCodeGlobal():RegisterKeyPressedEvent(onEvent_);
end

-- if last tick event is not finished, the tick is ignored. 
-- @param ticks: default to 1 tick
function CodeBlock:RegisterTickEvent(ticks, callbackFunc)
	ticks = tonumber(ticks or 1);
	local event = self:CreateEvent("onTick");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
	event:SetStopLastEvent(false);
	local tick = 1;
	local function onEvent_(_, msg)
		tick = tick + 1;
		if((tick % ticks) == 0) then
			event:Fire(msg and msg.msg, msg and msg.onFinishedCallback, true);
		end
	end
	
	event.UnRegisterTextEvent = function()
		GameLogic.GetCodeGlobal():UnregisterTextEvent("onTick", onEvent_);
	end
	
	event:Connect("beforeDestroyed", event.UnRegisterTextEvent);
	GameLogic.GetCodeGlobal():RegisterTextEvent("onTick", onEvent_);
	
	return event;
end

function CodeBlock:RegisterAgentEvent(text, callbackFunc)
	-- tricky: since we need to return value immediately, like GetIcon, we will disable auto wait feature in agent callback functions.
	self:SetAutoWait(false);

	if(self.entityCode) then
		local filename = self.entityCode:GetFilename();
		if(filename and filename ~= "") then
			text = format("%s.%s", filename, text);
		end
	end

	local event = self:CreateEvent("onAgent"..text);
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(false);
	event:SetFunction(callbackFunc);
	local function onEvent_(_, msg)
		return event:Fire(msg and msg.msg, msg and msg.onFinishedCallback, true);
	end
	
	event.UnRegisterTextEvent = function()
		GameLogic.GetCodeGlobal():UnregisterTextEvent(text, onEvent_);
	end
	
	event:Connect("beforeDestroyed", event.UnRegisterTextEvent);
	GameLogic.GetCodeGlobal():RegisterTextEvent(text, onEvent_);
	return event;
end


function CodeBlock:RegisterTextEvent(text, callbackFunc)
	local event = self:CreateEvent("onText"..text);
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetFunction(callbackFunc);
	local function onEvent_(_, msg)
		if(msg and msg.dest) then
			for i, actor in ipairs(self:GetActors()) do
				if(msg.dest == actor:GetName()) then
					-- only activate the first matching actor
					return event:FireForActor(actor, msg and msg.msg, msg and msg.onFinishedCallback);
				end
			end
		else
			return event:Fire(msg and msg.msg, msg and msg.onFinishedCallback);
		end
	end
	
	event.UnRegisterTextEvent = function()
		GameLogic.GetCodeGlobal():UnregisterTextEvent(text, onEvent_);
	end
	
	event:Connect("beforeDestroyed", event.UnRegisterTextEvent);
	GameLogic.GetCodeGlobal():RegisterTextEvent(text, onEvent_);
	
	return event;
end

function CodeBlock:UnRegisterTextEvent(text, callbackFunc)
	local eventname = "onText"..text;
	local events = self.events[eventname];
	
	for i, event in ipairs(events) do
		if event.callbackFunc == callbackFunc then
			if(event.UnRegisterTextEvent) then
				event.UnRegisterTextEvent();
			end
			event:Destroy();
			table.remove(events, i);
			break;
		end
	end
	
	if #events == 0 then
		self.events[eventname] = nil;
	end
end

-- @param onFinishedCallback: can be nil
function CodeBlock:BroadcastTextEvent(text, msg, onFinishedCallback)
	if(type(text) == "string") then
		GameLogic.GetCodeGlobal():BroadcastTextEvent(text, msg, onFinishedCallback);
	end
end

-- similar to BroadcastTextEvent
-- @paramm dest: dest actor name. 
function CodeBlock:BroadcastTextEventTo(dest, text, msg)
	GameLogic.GetCodeGlobal():BroadcastTextEventTo(dest, text, msg);
end

function CodeBlock:RegisterCloneActorEvent(callbackFunc)
	local event = self:CreateEvent("onCloneActor");
	if(not event) then
		return
	end
	event:SetFunction(callbackFunc);
end

function CodeBlock:RegisterNetworkEvent(event_name, callbackFunc)
	local event = self:CreateEvent(event_name);
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(true);
	event:SetStopLastEvent(false);
	event:SetFunction(callbackFunc);
	local function onEvent_(_, msg)
		event:Fire(msg and msg.msg, msg and msg.onFinishedCallback);
	end
	event:Connect("beforeDestroyed", function()
		GameLogic.GetCodeGlobal():UnregisterNetworkEvent(event_name, onEvent_);
	end)
--	self:Connect("beforeStopped", function()
--		GameLogic.GetCodeGlobal():UnregisterNetworkEvent(event_name, onEvent_, self);
--	end)

	GameLogic.GetCodeGlobal():RegisterNetworkEvent(event_name, onEvent_);
end

function CodeBlock:BroadcastNetworkEvent(event_name, msg)
	GameLogic.GetCodeGlobal():BroadcastNetworkEvent(event_name, msg);
end

function CodeBlock:SendNetworkEvent(username, event_name, msg)
	GameLogic.GetCodeGlobal():SendNetworkEvent(username, event_name, msg);
end

-- create a clone of some code block's actor
-- @param name: if nil or "myself", it means clone myself
-- @param msg: any mesage that is forwared to clone event
function CodeBlock:CreateClone(name, msg)
	if(not name or name == "myself") then
		self:CloneMyself(msg);
	else
		local codeBlock = self:GetCodeBlockByName(name);
		if(codeBlock) then
			codeBlock:CloneMyself(msg);
		end
	end
end

function CodeBlock:GetCodeBlockByName(name)
	return GameLogic.GetCodeGlobal():GetCodeBlockByName(name);
end

-- @return the actor created
function CodeBlock:CloneMyself(msg)
	local actor = self:CreateActor();
	if(actor) then
		local fromActor = self:GetFirstActor()
		if(fromActor and fromActor~=actor) then
			actor:cloneFrom(fromActor);
		end
		self:GetReferencedCodeBlock():OnCloneActor(actor, msg);
		return actor;
	end
end

function CodeBlock:OnCloneActor(actor, msg)
	self:FireEvent("onCloneActor", actor, msg);
	self:actorCloned(actor, msg);
end

-- blink the created actor 
function CodeBlock:HighlightActors()
	local actors = self:GetActors();
	if(actors:last()) then
		for i = 1, math.min(10, #actors) do
			local actor = actors[i];
			actor:SetHighlight(true);
			commonlib.TimerManager.SetTimeout(function()  
				actor:SetHighlight(false);
			end, 1000 + i*100);
		end
	end
end

function CodeBlock:CreateGetActor()
	local env = self:GetCodeEnv();
	if(env) then
		return env.actor or self:FindNearbyActor() or self:CreateActor();
	end
end

function CodeBlock:GetActor()
	local env = self:GetCodeEnv();
	if(env) then
		return env.actor or self:FindNearbyActor();
	end
end

-- usually from help window. There can only be one temp code running. 
-- @param code: string
function CodeBlock:RunTempCode(code, filename)
	local hasFastMode = false;
	if(self:GetEntity() and self:GetEntity():IsAllowFastMode()) then
		self:GetEntity():SetAllowFastMode(false);
		hasFastMode = true;
	end
	local code_func, errormsg = self:CompileCodeImp(code, filename or "tempcode");
	if(hasFastMode) then
		self:GetEntity():SetAllowFastMode(true);
	end
	if(not code_func and errormsg) then
		LOG.std(nil, "error", "CodeBlock", errormsg);
		local msg = errormsg;
		msg = format(L"编译错误: %s\n在%s", self:BeautifyCompilerErrorMsg(msg), filename);
		self:send_message(msg, "error");
	else
		local env = self:GetCodeEnv();
		if(env) then
			self:StopLastTempCode();
			local co = CodeCoroutine:new():Init(self);
			self.lastTempCodeCoroutine = co;
			self:stateChanged();
			local actor = self:FindNearbyActor() or self:CreateActor();
			co:SetActor(actor);
			co:SetFunction(code_func);
			co:Run()
		end
	end
end

function CodeBlock:HasRunningTempCode()
	if(self.lastTempCodeCoroutine) then
		return true;
	end
end

function CodeBlock:StopLastTempCode()
	if(self.lastTempCodeCoroutine) then
		self.lastTempCodeCoroutine:Stop();
		self.lastTempCodeCoroutine = nil;
	end
end

-- in seconds
function CodeBlock:GetTime()
	return (commonlib.TimerManager.GetCurrentTime() - self.startTime)/1000;
end

function CodeBlock:ResetTime()
	self.startTime = commonlib.TimerManager.GetCurrentTime()
end

-- collision event is special that it will not overwrite the last event.
-- @param name: if nil or "", it matches all actors
-- if name is a number, it means a physics_group_id
function CodeBlock:RegisterCollisionEvent(name, callbackFunc)
	local event = self:CreateEvent("onCollideActor");
	if(not event) then
		return
	end
	event:SetIsFireForAllActors(false);
	event:SetStopLastEvent(false);
	if(type(name) == "number") then
		event:SetCanFireCallback(function(actor, fromActor)
			if(fromActor and (fromActor:GetGroupId() == name)) then
				return true;
			end
		end);
	else
		event:SetCanFireCallback(function(actor, fromActor)
			if(fromActor and (not name or name=="" or fromActor:GetName() == name)) then
				return true;
			end
		end);
	end
	event:SetFunction(callbackFunc);
end

function CodeBlock:OnCollideActor(actor, fromActor)
	self:FireEvent("onCollideActor", actor, fromActor);
	self:actorCollided(actor, fromActor);
end

-- set code block entity's output value. default to nil.
function CodeBlock:SetOutput(result)
	if(self:GetEntity()) then
		self:GetEntity():SetLastCommandResult(result);
	end
end

local lastErrorCallstack = "";
function CodeBlock.handleError(x)
	lastErrorCallstack = commonlib.debugstack(2, 5, 1);
	return x;
end

-- @param filename: include a file relative to current world directory
function CodeBlock:IncludeFile(filename)
	local filepath = Files.WorldPathToFullPath(filename);
	if(self:GetEntity()) then
		self:GetEntity():AddIncludedFile(filename);
	end

	local file = ParaIO.open(filepath, "r")
	if(file:IsValid()) then
		local code = file:GetText();
		file:close();
		if(code and code~="") then
			local code_func, errormsg = self:CompileCodeImp(code, filename);
			if(not code_func and errormsg) then
				LOG.std(nil, "error", "CodeBlock", errormsg);
				local msg = errormsg;
				msg = format(L"编译错误: %s\n在%s", self:BeautifyCompilerErrorMsg(msg), filename);
				self:send_message(msg, "error");
			else
				setfenv(code_func, self:GetCodeEnv());
				--local ok, result = xpcall(code_func, CodeBlock.handleError);
				local arg = {xpcall(code_func, CodeBlock.handleError)};
				local ok = arg[1];
				
				if(not ok) then
					local result = arg[2];
					
					if(result:match("_stop_all_")) then
						self:StopAll();
					elseif(result:match("_restart_all_")) then
						self:RestartAll();
					else
						LOG.std(nil, "error", "CodeBlock", "%s\n%s", result, lastErrorCallstack);
						local msg = format(L"运行时错误: %s\n在%s", self:BeautifyRuntimeErrorMsg(tostring(result)), filename);
						self:send_message(msg, "error");
					end
				end
				
				return unpack(arg, 2);
			end
		end
	else
		LOG.std(nil, "warn", "CodeBlock", "include can not file world file %s", filename);
		local msg = format(L"没有找到文件: %s", filename);
		self:send_message(msg, "error");
	end
end

function CodeBlock:SetAutoWait(bAutoWait)
	self.bAutoWait = bAutoWait;
end

-- whether to automatically wait when a given number of instructions are executed. 
function CodeBlock:IsAutoWait()
	return self.bAutoWait;
end

function CodeBlock:handleAutoWaitCmd(params)
	local isAutowait = true;
	if(type(params) == "string") then
		isAutowait  = CmdParser.ParseBool(params)
	elseif(type(params) == "boolean") then
		isAutowait = params
	end
	self:SetAutoWait(isAutowait);
end

local codeBlockCmds = {
	["autowait"] = CodeBlock.handleAutoWaitCmd
}

function CodeBlock:RunCommand(cmd_name, cmd_text)
	if(cmd_text == nil) then
		cmd_name, cmd_text = cmd_name:match("^/*(%w+)%s*(.*)$");
	end
	local handlerFunc = codeBlockCmds[cmd_name or ""];
	if(handlerFunc) then
		handlerFunc(self, cmd_text);
	else
		return GameLogic.RunCommand(cmd_name, cmd_text, self:GetEntity());
	end
end

function CodeBlock:SetAllowClientExecution(bAllow)
	if(self:GetEntity()) then
		self:GetEntity():SetAllowClientExecution(bAllow)
	end
end

function CodeBlock:IsAllowClientExecution()
	if(self:GetEntity()) then
		return self:GetEntity():IsAllowClientExecution();
	end
end

function CodeBlock:AddCoroutineToFreePool(co)
	self.free_coroutines = self.free_coroutines or commonlib.UnorderedArraySet:new()
	if(#self.free_coroutines < 500) then
		self.free_coroutines:add(co);
	end
end

function CodeBlock:PopFreeCoroutine()
	if(self.free_coroutines and (#self.free_coroutines) >= 1) then
		local co = self.free_coroutines[#self.free_coroutines];
		self.free_coroutines:remove(co)
		return co;
	end
end

-- @param bFromAutoReleasePool: if true, we may reuse this coroutine when it is finished.
function CodeBlock:NewCoroutine(bFromAutoReleasePool)
	local co = bFromAutoReleasePool and self:PopFreeCoroutine()
	if(not co) then
		co = CodeCoroutine:new():Init(self);
		if(bFromAutoReleasePool) then
			CodeCoroutine:SetAutoReleasePool(true);
		end
	end
	return co;
end
