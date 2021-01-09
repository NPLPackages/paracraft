--[[
Title: all Macros 
Author(s): LiXizhi
Date: 2021/1/2
Desc: namespace for all macros

Idle(500)
CameraMove(8,0.54347,0.18799)
CameraLookat(19980.29883,-126.59001,19998.52929)
PlayerMove(19181,5,19198,0.23781)
SceneClick("shift+right",-0.19781,0.07273)
Tip("some text")
Broadcast("globalGameEvent")

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
if(GameLogic.Macros:IsRecording()) then
	GameLogic.Macros:AddMacro("PlayerMove", x, y, z);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

local lastPlayerPos = {pos = {x=0, y=0, z=0}, facing=0, recorded=false};
local lastCameraPos = {camobjDist=10, LiftupAngle=0, CameraRotY=0, recorded = false, lookatX=0, lookatY = 0, lookatZ = 0};
local startTime = 0;
local idleStartTime = 0;

local isInited;
function Macros:Init()
	if(isInited) then
		return true;
	end
	isInited = true;
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroIdle.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroTip.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayerMove.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayerMoveTrigger.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroButtonClick.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroButtonClickTrigger.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroSceneClick.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroSceneClickTrigger.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroKeyPress.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroKeyPressTrigger.lua");
	-- TODO: add more here
end

function Macros:IsRecording()
	return self.isRecording;
end

function Macros:GetElapsedTime()
	return commonlib.TimerManager.GetCurrentTime() - startTime;
end

function Macros:BeginRecord()
	self:Init()
	self.isRecording = true;
	self.macros = {};
	
	local lastCamera = self:GetLastCameraParams()
	lastCamera.lookatX, lastCamera.lookatY, lastCamera.lookatZ = nil, nil, nil;
	lastCamera.camobjDist, lastCamera.LiftupAngle, lastCamera.CameraRotY = 8, 0.4, 0;

	startTime = commonlib.TimerManager.GetCurrentTime();
	idleStartTime = startTime;

	local player = EntityManager.GetPlayer();
	if(player) then
		local x, y, z = player:GetBlockPos();
		lastPlayerPos.pos = {x=x, y=y, z=z}
		lastPlayerPos.facing = player:GetFacing();
		lastPlayerPos.recorded = false;
	end
	lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = ParaCamera.GetEyePos();
	lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ =  0,0,0;
	lastCameraPos.recorded = false;

	commonlib.__onuievent__ = Macros.OnGUIEvent;
	

	self.tickTimer = self.tickTimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:OnTimer();
	end})
	self.tickTimer:Change(500, 500);
	GameLogic.GetFilters():apply_filters("Macro_BeginRecord");
end

local ignoreBtnList = {
	["MacroRecorder.Stop"] = true,
	["_click_to_continue_delay_"] = true,
}

-- called whenever GUI event is received from c++ engine. 
function Macros.OnGUIEvent(obj, eventname, callInfo)
	if(not Macros:IsRecording()) then
		return
	end
	if(eventname == "onclick") then
		local name = obj.name or "";
		if(name and name~="" and #name > 1 and ParaUI.GetUIObject(name):IsValid() and not name:match("^%d+/")) then
			if(not ignoreBtnList[name]) then
				Macros:AddMacro("ButtonClick", name, mouse_button)
			end
		else
			GameLogic.AddBBS("macros", format(L"警告：没有录制的宏点击事件:%s", name or ""), 4000, "255 0 0");
		end
	end
end

-- macros that needs to sync camera and viewport settings
local cameraViewMacros = {
	["SceneClick"] = true,
}

-- @param text: macro command text or just macro function name
-- @param ...: additional input parameters to macro function name
function Macros:AddMacro(text, ...)
	local args = {...}
	if(#args > 0) then
		local params;
		for _, param in ipairs(args) do
			if(params) then
				params = params..","..commonlib.serialize_compact(param);
			else
				params = commonlib.serialize_compact(param);
			end
		end
		text = format("%s(%s)", text, params or "");
	else
		if(not text:match("%(")) then
			text = text.."()";
		end
	end
	local idleTime = commonlib.TimerManager.GetCurrentTime() - idleStartTime;
	if(idleTime > 100) then
		idleStartTime = commonlib.TimerManager.GetCurrentTime();
		self:AddMacro("Idle", idleTime);
	end
	local name = text:match("^([^%(]+)");
	if(cameraViewMacros[name]) then
		self:CheckAddCameraView();
	end
	local macro = Macro:new():Init(text);
	if(macro:IsValid()) then
		if(self:IsRecording() and self:IsInteractiveMode() and macro:HasTrigger()) then
			self.macros[#self.macros + 1] = macro:CreateTriggerMacro();
		end
		self.macros[#self.macros + 1] = macro;
		GameLogic.GetFilters():apply_filters("Macro_AddRecord", #self.macros);
	else
		GameLogic.AddBBS("Macro", format("Unknown macro: %s", text), 5000, "255 0 0");
	end
end

function Macros:EndRecord()
	if(not self.isRecording) then
		return;
	end
	self.isRecording = false;
	commonlib.__onuievent__ = nil;
	if(self.tickTimer) then
		self.tickTimer:Change();
	end
	if(self.macros) then
		local out = {};
		for _, m in ipairs(self.macros) do
			out[#out+1] = m:ToString();
		end
		local text = table.concat(out, "\n");
		ParaMisc.CopyTextToClipboard(text);
		GameLogic.AddBBS(nil, format("%d macros are copied to clipboard", #(self.macros)), 5000, "0 255 0")
	end
	GameLogic.GetFilters():apply_filters("Macro_EndRecord");
end

function Macros:IsPlaying()
	return self.isPlaying;
end

local lastCamera = {camobjDist=8, LiftupAngle=0.4, CameraRotY=0}

-- @return {camobjDist=8, LiftupAngle=0.4, CameraRotY=0, lookatX, lookatY, lookatZ}
function Macros:GetLastCameraParams()
	return lastCamera;
end

function Macros:LockInput()
	ParaScene.GetAttributeObject():SetField("BlockInput", true);
	ParaCamera.GetAttributeObject():SetField("BlockInput", true);
end
function Macros:UnlockInput()
	ParaScene.GetAttributeObject():SetField("BlockInput", false);
	ParaCamera.GetAttributeObject():SetField("BlockInput", false);
end

-- @param text: text lines of macros.
-- @return array of Macro objects
function Macros:LoadMacrosFromText(text)
	if(not text) then
		return
	end
	Macros:Init();
	local macros = {};
	for line in text:gmatch("[^\r\n]+") do
		line = line:gsub("^%s+", "")
		local m = Macro:new():Init(line);
		if(m:IsValid()) then
			macros[#macros+1] = m;
		end
	end
	return macros;
end

-- @param text: text lines of macros. if nil, it will play from clipboard
function Macros:Play(text)
	text = text or ParaMisc.GetTextFromClipboard() or "";
	local macros = self:LoadMacrosFromText(text)
	self:PlayMacros(macros);
end

function Macros:BeginPlay()
	self:EndRecord()
	self:Init();

	self.isPlaying = true;
		
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
	local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
	MacroPlayer.ShowPage();
	self:LockInput()

	GameLogic.GetFilters():add_filter("ShowExitDialog", Macros.OnShowExitDialog);
end

function Macros.OnShowExitDialog(p1)
	if(Macros:IsPlaying()) then
		_guihelper.MessageBox(L"是否退出示教系统?", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				Macros:Stop();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		return;
	end
	return p1;
end

-- peek next macro in execution. Usually used by Idle macro to merge with triggers
function Macros:PeekNextMacro()
	return self.nextMacro;
end

-- @param fromLine: optional
function Macros:PlayMacros(macros, fromLine)
	fromLine = fromLine or 1
	if(fromLine == 1) then
		self:BeginPlay()
	end

	while(true) do
		local m = macros[fromLine];
		if(m) then
			self.isPlaying = true;
			self.nextMacro = macros[fromLine + 1];
			local isAsync = nil;
			GameLogic.GetFilters():apply_filters("Macro_PlayMacro", fromLine, macros);
			m:Run(function()
				if(isAsync) then
					if(self.isPlaying) then
						self:PlayMacros(macros, fromLine+1)
					end
				else
					isAsync = false;
				end
			end)
			if(isAsync == false) then
				fromLine = fromLine + 1;
			else
				isAsync = true;
				break;
			end
		else
			self:Stop()
			break;
		end
	end
end


function Macros:Stop()
	if(self:IsRecording()) then
		self:EndRecord()
	elseif(self:IsPlaying()) then
		self.isPlaying = false;
		self:UnlockInput();

		local player = EntityManager.GetPlayer();
		player:SetFocus();
		local obj = player:GetInnerObject();
		if(obj) then
			if(obj.ToCharacter) then
				obj:ToCharacter():SetFocus();
			end
		end

		GameLogic.GetFilters():apply_filters("Macro_EndPlay");
	end
end

-- only record when the user has moved and been still for at least 500 ms. 
function Macros:Tick_RecordPlayerMove()
	local player = EntityManager.GetPlayer();
	if(player and EntityManager.GetFocus() == player) then
		-- for scene camera. 
		local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
		local diff = math.abs(lastCameraPos.camobjDist - camobjDist) + math.abs(lastCameraPos.LiftupAngle - LiftupAngle) + math.abs(lastCameraPos.CameraRotY - CameraRotY);
		if(diff ~= 0) then
			lastCameraPos.recorded = false;
			lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = camobjDist, LiftupAngle, CameraRotY
		elseif(diff == 0 and not lastCameraPos.recorded) then
			lastCameraPos.recorded = true;
			self:AddMacro("CameraMove", camobjDist, LiftupAngle, CameraRotY);
		end

		-- for player position changes
		local x, y, z = player:GetBlockPos();	
		local diff = math.abs(lastPlayerPos.pos.x - x) + math.abs(lastPlayerPos.pos.y - y) + math.abs(lastPlayerPos.pos.z - z);
		if(diff ~= 0) then
			lastPlayerPos.recorded = false;
			lastPlayerPos.pos.x, lastPlayerPos.pos.y, lastPlayerPos.pos.z = x, y, z
		elseif(diff == 0 and not lastPlayerPos.recorded) then
			lastPlayerPos.recorded = true;
			local facing = player:GetFacing();
			self:AddMacro("PlayerMove", x, y, z, facing);

			--local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
			--lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ = lookatX, lookatY, lookatZ
			--self:AddMacro("CameraLookat", lookatX, lookatY, lookatZ);
		end
	end
end

-- only add camera lookat and positions if the current is different from last. 
-- this function is usually called automatically before any scene clicking macros. 
function Macros:CheckAddCameraView()
	local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
	local diff = math.abs(lastCameraPos.camobjDist - camobjDist) + math.abs(lastCameraPos.LiftupAngle - LiftupAngle) + math.abs(lastCameraPos.CameraRotY - CameraRotY);
	if(diff > 0.001 or not lastCameraPos.recorded) then
		lastCameraPos.camobjDist, lastCameraPos.LiftupAngle, lastCameraPos.CameraRotY = camobjDist, LiftupAngle, CameraRotY
		lastCameraPos.recorded = true;
		self:AddMacro("CameraMove", camobjDist, LiftupAngle, CameraRotY);
	end
	local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
	local diff = math.abs(lastCameraPos.lookatX - lookatX) + math.abs(lastCameraPos.lookatY - lookatY) + math.abs(lastCameraPos.lookatZ - lookatZ);
	if(diff > 0.001) then
		lastCameraPos.lookatX, lastCameraPos.lookatY, lastCameraPos.lookatZ = lookatX, lookatY, lookatZ
		self:AddMacro("CameraLookat", lookatX, lookatY, lookatZ);
	end
end


function Macros:SetInteractiveMode(isInteractive)
	self.isInteractive = isInteractive == true;
end

function Macros:IsInteractiveMode()
	return self.isInteractive;
end

function Macros:OnTimer()
	if(self:IsRecording() and not self:IsPlaying()) then
		self:Tick_RecordPlayerMove()
	end
end