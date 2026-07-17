--[[
Author:  pbb
Date:    2025-04-07
Purpose: MiniGameMgr
    -- 1. 负责游戏的加载和卸载
    -- 2. 负责游戏数据的保存和读取
UseLib: 
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
    local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/Pet/PetManager.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/SkinDrawSystem.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MaisiAPI.lua")
local SkinDrawSystem = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.SkinDrawSystem")
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua")
local Screen = commonlib.gettable("System.Windows.Screen")
local EmscriptenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/EmscriptenAPI.lua")
local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua")
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua")
local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect")
local CheckPointManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CheckPointManager.lua")
local FriendActionManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/FriendActionManager.lua")

local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local PetManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.Pet.PetManager")
local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")

local MiniGameMgr = commonlib.inherit(
	commonlib.gettable("System.Core.ToolBase"),
	commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
)
local event_name = "@webparacraft_miniGameProxy"
local send_event_name = "@keepwork_miniGameProxy"
local MiniGameDataKey = "MiniGameDataKey"
local MiniGameConfigKey = "MiniGameConfigKey"

function MiniGameMgr:ctor() end

function MiniGameMgr:Init()
	self.game_list = {}
	self.current_game = nil
	self.petManager = nil
	self.timeLimitCheck = true
	self.maisiAPI = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MaisiAPI")

	self:RegisterEvent()
	CheckPointManager.Init()
end

function MiniGameMgr:RegisterEvent()
	GameLogic.GetFilters()
		:remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", MiniGameMgr.OnSwfLoadingClosed)
	GameLogic.GetFilters()
		:add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page", MiniGameMgr.OnSwfLoadingClosed)

	GameLogic:Disconnect("WorldLoaded", MiniGameMgr, MiniGameMgr.OnWorldLoaded, "UniqueConnection")
	GameLogic:Connect("WorldLoaded", MiniGameMgr, MiniGameMgr.OnWorldLoaded, "UniqueConnection")

	GameLogic:Disconnect("WorldUnloaded", MiniGameMgr, MiniGameMgr.OnWorldUnload, "UniqueConnection")
	GameLogic:Connect("WorldUnloaded", MiniGameMgr, MiniGameMgr.OnWorldUnload, "UniqueConnection")

	Screen:Disconnect("sizeChanged", MiniGameMgr, MiniGameMgr.OnScreenChanged, "UniqueConnection")
	Screen:Connect("sizeChanged", MiniGameMgr, MiniGameMgr.OnScreenChanged, "UniqueConnection")

	GameLogic.GetFilters():remove_filter("on_start_login", MiniGameMgr.OnUserChanged)
	GameLogic.GetFilters():add_filter("on_start_login", MiniGameMgr.OnUserChanged)

	GameLogic.GetFilters():remove_filter("OnGGGSDisconnection", MiniGameMgr.OnGGSDisConnected)
	GameLogic.GetFilters():add_filter("OnGGGSDisconnection", MiniGameMgr.OnGGSDisConnected)

	GameLogic.GetFilters():remove_filter("OnGGSLogin", MiniGameMgr.OnGGSLogIn)
	GameLogic.GetFilters():add_filter("OnGGSLogin", MiniGameMgr.OnGGSLogIn)

	GameLogic.GetFilters():remove_filter("OnGGSUpdatePetItem", MiniGameMgr.OnGGSUpdatePetItem)
	GameLogic.GetFilters():add_filter("OnGGSUpdatePetItem", MiniGameMgr.OnGGSUpdatePetItem)

	GameLogic.GetFilters():remove_filter("OnGGSLogout", MiniGameMgr.OnGGSLogout)
	GameLogic.GetFilters():add_filter("OnGGSLogout", MiniGameMgr.OnGGSLogout)

	GameLogic.GetFilters():add_filter("KeyPressEvent", function(callbackVal, event)
		MiniGameMgr.OnKeyPressEvent(callbackVal, event)
		return callbackVal, event
	end)
	local MiniGameSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameSmileyPage.lua")
	MiniGameSmileyPage.RegisterCustomEvent()

	GameLogic.GetFilters():remove_filter("CheckGameTime", MiniGameMgr.CheckGameTime)
	GameLogic.GetFilters():add_filter("CheckGameTime", MiniGameMgr.CheckGameTime)
	GameLogic.GetFilters():remove_filter("ResetGameTimeData", MiniGameMgr.ResetGameTimeData)
	GameLogic.GetFilters():add_filter("ResetGameTimeData", MiniGameMgr.ResetGameTimeData)
end

function MiniGameMgr:OnWorldLoaded()
	self.world_loaded = true
	self:LoadGameData()

	-- 初始化宠物管理器
	if not self.petManager then
		self.petManager = PetManager:GetInstance()
		self.petManager:Init()
	end

	self:OnWorldLoadedFinish()
end

function MiniGameMgr:SetScreenDesignResolution(width, height, callbackFunc)
	width = width or 1280
	height = height or 720
	Screen:ChangeUIDesignResolution(width, height, callbackFunc)
end

function MiniGameMgr:IsCustomGameStarted()
	return self.isCustomGameStarted
end

function MiniGameMgr:OnWorldUnload()
	self:ClearGames()
	self.NpcList = {}
	self.customChat = false
	self.isMountDragon = false
	self.petInfo = nil
	-- self.isCustomGameStarted = false
	GameLogic.GetFilters():remove_all_filters("ggs_custom_chat")
	GameLogic.GetFilters():remove_all_filters("show_custom_create_new_world")

	-- 清理宠物管理器
	if self.petManager then
		self.petManager:Destroy()
		self.petManager = nil
	end
	CheckPointManager.OnWorldUnload()
	FriendActionManager.OnWorldUnLoad()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotGUIGuide.lua");
	local CopilotGUIGuide = commonlib.gettable("MyCompany.Aries.Game.Tasks.Copilot.CopilotGUIGuide");
	CopilotGUIGuide.Stop()
end

function MiniGameMgr.OnUserChanged()
	MiniGameMgr.ClearPersonalPageData()
	-- 清理MaisiAPI
	MiniGameMgr:ClearMaisiData()
end

function MiniGameMgr.ClearPersonalPageData()
	NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua")
	local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore")
	if PersonalPageStore then
		PersonalPageStore:Reset()
	else
		LOG.std(nil, "info", "MiniGameMgr", "ClearPersonalPageData PersonalPageStore is nil")
	end
end

function MiniGameMgr.OnGGSDisConnected()
	MiniGameMgr.isGGSDisConnected = true
	CheckPointManager.OnGGSDisConnected()
end

function MiniGameMgr.OnGGSUpdatePetItem(packetPlayerInfo)
	local username = packetPlayerInfo and packetPlayerInfo.username
	local myUserName = Mod.WorldShare.Store:Get("user/username") or ""
	if username and myUserName == username then
		return packetPlayerInfo
	end
	if MiniGameMgr.petManager then
		MiniGameMgr.petManager:OnGGSUpdatePetItem(packetPlayerInfo)
	end
	return packetPlayerInfo
end

function MiniGameMgr.OnGGSLogIn(packetPlayerInfo)
	MiniGameMgr.isGGSDisConnected = false
	local username = packetPlayerInfo and packetPlayerInfo.username
	local myUserName = Mod.WorldShare.Store:Get("user/username") or ""
	if username and myUserName == username then
		commonlib.TimerManager.SetTimeout(function()
			MiniGameMgr:UpdatePetStatus()
			if MiniGameMgr.customChat then
				GameLogic.RunCommand("/ggs user disableclick")
			end
		end, 1000)
		return packetPlayerInfo
	end
	if MiniGameMgr.petManager then
		MiniGameMgr.petManager:OnGGSLogIn(packetPlayerInfo)
	end
	return packetPlayerInfo
end

function MiniGameMgr.OnGGSLogout(username)
	local myUserName = Mod.WorldShare.Store:Get("user/username") or ""
	if username and myUserName == username then
		return username
	end
	LOG.std(nil, "info", "MiniGameMgr", "OnGGSLogout username:%s", username)
	if MiniGameMgr.petManager then
		MiniGameMgr.petManager:OnGGSLogout(username)
	end
	return username
end

local isMoveKeys = {
	DIK_UP = true,
	DIK_DOWN = true,
	DIK_LEFT = true,
	DIK_RIGHT = true,
	DIK_A = true,
	DIK_S = true,
	DIK_D = true,
	DIK_W = true,
}
local connectStartTime = 0
local connectTime = 0
function MiniGameMgr.OnKeyPressEvent(callbackVal, event)
	if event and event.keyname and isMoveKeys[event.keyname] then
		-- GameLogic.AddBBS(nil,"GGS_MoveKeys:"..event.keyname..":"..tostring(MiniGameMgr.isGGSLogOut)..":"..tostring(MiniGameMgr.isGGSLogin))
		if MiniGameMgr.isGGSLogin and MiniGameMgr.isGGSDisConnected then
			MiniGameMgr.ReconnectGGS()
			return
		end
	end
end

function MiniGameMgr.ReconnectGGS()
	local curTime = ParaGlobal.timeGetTime()
	if curTime - connectStartTime < 5000 then
		return
	end
	connectStartTime = curTime

	connectTime = connectTime + 1
	if connectTime > 3 then
		return
	end
	NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua")
	local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient")
	local world = AppGeneralGameClient:GetWorld()
	if not world then
		return
	end
	local netHandler = world:GetNetHandler()
	if not netHandler then
		return
	end
	netHandler:Reconnect()
end

function MiniGameMgr.OnSwfLoadingClosed()
	MiniGameMgr.swf_loading_closed = true
	MiniGameMgr:OnWorldLoadedFinish()
end

function MiniGameMgr:OnWorldLoadedFinish()
	if self.swf_loading_closed and self.world_loaded then
		-- 这里可以做一些游戏的初始化工作
		-- 例如加载游戏列表，或者加载游戏数据等
		self.isLoadWebView = false
		self.preSendMsgQueue = nil
		GameLogic.GetFilters():apply_filters("on_external_loading_completed", {})
		self:RegisterGameMessage()
		FriendActionManager.OnWorldLoadFinished()
	end
end

function MiniGameMgr:OnScreenChanged()
	local screenWidth = Screen:GetWidth()
	local screenHeight = Screen:GetHeight()
	if self.screenWidth == screenWidth and self.screenHeight == screenHeight then
		return
	end
	self.screenWidth = screenWidth
	self.screenHeight = screenHeight
	local isLanscapeMode = ParaEngine.GetAttributeObject():GetField("IsScreenRotated", false)
	if self.current_game and self.game_list[self.current_game] then
		local msg_data = {
			action = "screenChanged",
			name = self.current_game,
			screenWidth = screenWidth,
			screenHeight = screenHeight,
			isLanscapeMode = isLanscapeMode,
		}
		self:SendMessage(self.current_game, msg_data)
	end
end

function MiniGameMgr.CheckGameTime()
	TimeLimitPage.UpdateTimeLimit()
end

function MiniGameMgr.ResetGameTimeData()
	TimeLimitPage.ResetGameTimeData()
end

function MiniGameMgr:RegisterGameMessage()
	-- 注册本地游戏获得知识豆的事件
	GameLogic.GetCodeGlobal():RegisterTextEvent("wanxue_submit_score", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "wanxue_submit_score====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		self:ReceiveLocalGameData(msg)
	end)

	-- 注册游戏相关的事件
	GameLogic.GetCodeGlobal():RegisterTextEvent("register_game", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "register_game====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		self:RegisterGame(msg)
	end)
	GameLogic.GetCodeGlobal():RegisterTextEvent("unregister_game", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "unregister_game====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		if msg and msg.name then
			self:UnloadGame(msg.name)
		end
	end)
	GameLogic.GetCodeGlobal():RegisterTextEvent("start_game", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "start_game====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		if msg and msg.name then
			self:StartGame(msg.name)
		end
	end)
	GameLogic.GetCodeGlobal():RegisterTextEvent("send_game_msg", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "start_game====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		if msg and msg.name then
			local msg_data = msg or {}
			msg_data.action = "gameMsg"
			self:SendMessage(msg.name, msg_data)
		end
	end)

	GameLogic.GetCodeGlobal():RegisterTextEvent("send_web_msg", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "send_web_msg====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		if msg and msg.name then
			if System.os.IsEmscripten() then
				Emscripten:SendMsg(msg.name, msg, nil, nil, "external")
			else
				NPLJS:SendMsg(msg.name, msg, nil, nil, true)
			end
		end
	end)

	GameLogic.GetCodeGlobal():RegisterTextEvent("report_game", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "report_game====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		if msg and msg.key then
		end
	end)

	GameLogic.GetCodeGlobal():RegisterTextEvent("register_game_ui", function(args, msg)
		LOG.std(nil, "info", "MiniGameMgr", "register_game_ui====" .. commonlib.serialize_compact(msg))
		local msg = msg.msg
		if type(msg) == "string" then
			msg = commonlib.LoadTableFromString(msg)
		end
		self:RegisterGameUI(msg)
	end)
end

function MiniGameMgr.RegisterGameUser(params, callback) end

local saveKey = "MiniGameUniqueKey"
function MiniGameMgr.GetUniqueId()
	local machineId = ParaEngine.GetAttributeObject():GetField("MachineID", "")
	machineId = GameLogic.GetMachineID(machineId, true)
	local uuid = ""
	if machineId == "" then
		local uniqueData = GameLogic.GetPlayerController():LoadLocalData(saveKey, nil, true)
		if uniqueData and uniqueData.uuid then
			uuid = uniqueData.uuid
		else
			uuid = System.Encoding.guid.uuid()
			GameLogic.GetPlayerController():SaveLocalData(saveKey, { uuid = uuid }, true)
		end
	end
	return machineId, uuid
end

function MiniGameMgr:IsEmscripten()
	return false --System.os.IsEmscripten()
end

function MiniGameMgr:SendMessage(game_name, game_data)
	if self:IsEmscripten() then
		Emscripten:SendMsg(send_event_name, game_data, nil, nil, "external")
	else
		if not self.preSendMsgQueue then
			self.preSendMsgQueue = commonlib.Queue:new()
		end
		if not self.isLoadWebView or not self.preSendMsgQueue:empty() then
			self.preSendMsgQueue:pushright({ name = send_event_name, msg = game_data })
			return
		end
		LOG.std(nil, "info", "MiniGameMgr", "MiniGameMgr:SendMessage:" .. commonlib.serialize_compact(game_data))
		NPLJS:SendMsg(send_event_name, game_data)
	end
end

local reportMsg = {}
function MiniGameMgr:ReportGameMsg(gameData)
	local gameData = gameData or {}
	local action = gameData.type or ""
	local data = gameData.data or {}
	local gameName = data.gameName or ""
	local pageName = data.name or ""
	if action == "gameStarted" and pageName == "" then
		if not reportMsg[gameName] then
			reportMsg[gameName] = {}
		end
		reportMsg[gameName].startTime = ParaGlobal.timeGetTime()
	elseif action == "gameFinished" then
		if reportMsg[gameName] then
			reportMsg[gameName].duration = ParaGlobal.timeGetTime() - reportMsg[gameName].startTime
			-- self:ReportGame({
			--     reportType = "game",
			--     gameName = gameName,
			--     duration = reportMsg[gameName].duration/1000,
			--     action = "gameFinished",
			-- })
			reportMsg[gameName] = nil
		end
	elseif action == "vipPayResult" then
		self:ReportGame({
			reportType = "vip",
		})
	end
end

local allowedCmds = {
	["/skin"] = true,
	["/avatar"] = true,
	["/gravity"] = true,
	["/scaling"] = true,
}

function MiniGameMgr:ReceiveMessage(game_data)
	print("MiniGameMgr:ReceiveMessage=================", commonlib.serialize_compact(game_data))
	-- GameLogic.SendErrorLog("MiniGameMgr","MiniGameMgr:ReceiveMessage:" .. commonlib.serialize_compact(game_data))
	self:ReportGameMsg(game_data)
	game_data = game_data or {}
	local action = game_data.type
	if action == "vipPayResult" then -- vip页面支付
		local MiniGameVip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameVip.lua")
		MiniGameVip.CloseVipPage()
		self:LoadThirdPartyGameInfo(function(result)
			if result and result.userDetail then
				GameLogic.AddBBS(
					nil,
					result.userDetail.isVip == true and "会员已开通" or "会员开通失败或取消"
				)
			else
				LOG.std(nil, "info", "MiniGameMgr", "会员开通取消")
			end
		end)
	elseif action == "gameRecommendResult" then --每日游戏推荐
		local gameName = game_data.name
		if gameName and gameName ~= "" then
			self:TeleportToGame(gameName)
		end
	elseif action == "GameLogic.RunCommand" then
		LOG.std(nil, "info", "MiniGameMgr", "GameLogic.RunCommand: " .. commonlib.serialize_compact(game_data))
		local command = game_data.command
		if command and command ~= "" then
			-- Parse multiple commands separated by \n
			local commands = commonlib.split(command, "\n")

			for _, cmd in ipairs(commands) do
				if cmd ~= "" then
					local cmdName = cmd:match("^(/[%w_]+)")
					local isAllowed = allowedCmds[cmdName] == true
					if not isAllowed then
						-- but we still allow it.
						LOG.std(nil, "warn", "MiniGameMgr", "Command not allowed: %s", cmd)
					end
					GameLogic.RunCommand(cmd)
				end
			end
		end
	elseif action == "closeGameCommon" then --每日游戏推荐
		MiniGamePage.ClosePage()
	elseif action == "gameNameClicked" then
		MiniGamePage.ClosePage()
		local gameInfo = game_data.gameInfo
		_guihelper.MessageBox(string.format("是否前往%s游戏？", gameInfo.title), function()
			self:TeleportToGame(gameInfo.name)
		end)
	elseif action == "deletePageData" then
		self:DeletePageData(game_data)
	elseif action == "closeGameSummary" then
		MiniGamePage.ClosePage()
		commonlib.TimerManager.SetTimeout(function()
			local gameData = game_data.data
			if gameData then
				if gameData.gameName and gameData.gameName ~= "" then
					self:TeleportToGame(gameData.gameName)
				end
				GameLogic.GetCodeGlobal():BroadcastTextEvent("npc_daily_game_finish", { msg = gameData })
				if self.achieveBeanNum and self.achieveBeanNum > 0 then
					local screenWidth = Screen:GetWidth()
					local screenHeight = Screen:GetHeight()
					local toObject = { x = screenWidth - 80, y = 30 }
					self:PlayGetBeansEffect(self.achieveBeanNum, toObject, function()
						GameLogic.AddBBS(nil, "获得" .. self.achieveBeanNum .. "知识豆")
					end)
				end
				self:CheckTodayGameFinished()
			end
		end, 100)
	elseif action == "startTask" then
		MiniGamePage.ClosePage()
		
		local data = game_data.data
		if not data or not data.level then
			LOG.std(nil, "warn", "MiniGameMgr", "Unknown task data")
			return
		end

		local category = data.level.category
		if category ~= "fishing" then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua")
			local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld")
			if not EasyEditableWorld.HasLoadedAnyWorld() then
				GameLogic.AddBBS(nil, L("您需要先创建或加载一个存档才能开始任务！"))
				return
			end
		end

		local skillLifes = {fishing=true, planting=true, cooking=true}
		local config = nil

		if skillLifes[category] then
			local projectId = GameLogic.options:GetProjectId()
			local baseUrl = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2Fdev%2F"
			if projectId and (tonumber(projectId) == 4108584) then
				baseUrl = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2F"
			end
			
			config = {
				loader = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotLandKeeper.lua",
				classPath = "MyCompany.Aries.Game.Tasks.CopilotLandKeeper",
				url = baseUrl .. "skill_life_tasks_config.md",
				runningTaskKey = "landkeeper.runningTask",
				addTaskOptions = { autoStart = true }
			}
		elseif category == "building" then
			config = {
				loader = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotDragonPet.lua",
				classPath = "MyCompany.Aries.Game.Tasks.CopilotDragonPet",
				url = "https://api.keepwork.com/core/v0/repos/maisi%2Fmaisi/files/maisi%2Fmaisi%2Fwebgames%2Fdata%2Fskill_building_tasks_config.md",
				runningTaskKey = "dragonpet.runningTask",
				initOptions = { restart = true },
				addTaskOptions = {
					autoStart = true,
					name = L("家园成长任务"),
					description = L("根据任务提示建造家园"),
					enabled = true,
				}
			}
		end

		if config then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/PersonalPageTutorial.task.lua")
			local PersonalPageTutorial = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.Copilot.PersonalPageTutorial")
			
			NPL.load("(gl)" .. config.loader)
			local CopilotClass = commonlib.gettable(config.classPath)
			local copilot = CopilotClass.GetInstance()
			
			if copilot then
				copilot:ClearAllTasks()
				local initParams = {
					url = config.url,
					taskData = data,
					category = category,
					runningTaskKey = config.runningTaskKey,
				}
				if config.initOptions then
					commonlib.partialcopy(initParams, config.initOptions)
				end
				local task = PersonalPageTutorial:new():Init(copilot, initParams)
				copilot:AddTask(task, config.addTaskOptions)
			end
		end
	elseif action == "closeCookingWindow" then
		local data = game_data.data

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/CopilotLandKeeper.lua")
		local CopilotLandKeeper = commonlib.gettable("MyCompany.Aries.Game.Tasks.CopilotLandKeeper")
		local copilot = CopilotLandKeeper.GetInstance()
		if copilot then
			copilot:ReceiveDataToRunningTask(data)
		end
	end
	self:HandleGameMessage(game_data)
end

function MiniGameMgr:DeletePageData(params)
	if not params or not params.data then
		return
	end
	local data = params.data
	local pageName = data.pageName
	local deleteKey = data.key
	if not pageName then
		return
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/PersonalPageStore.lua")
	local PersonalPageStore = commonlib.gettable("MyCompany.Aries.Creator.Game.KeepWork.PersonalPageStore")
	if deleteKey and deleteKey ~= "" then
		PersonalPageStore:DeletePageData(pageName, deleteKey)
		return
	end
	PersonalPageStore:ClearLocalDisk(pageName)
end

function MiniGameMgr:HandleGameMessage(game_data)
	if game_data then
		local command = string.format("/sendevent handle_game_msg %s", commonlib.serialize_compact(game_data))
		GameLogic.RunCommand(command)
		local MiniGameUserProfile =
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserProfile.lua")
		MiniGameUserProfile.HandlePageMessage(game_data)

		local MiniGameEditableWorld =
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameEditableWorld.lua")
		MiniGameEditableWorld.OnRecvMessage(game_data)

		local EasyModelStove = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyModelStove.lua")
		EasyModelStove.OnRecvMessage(game_data)

		local TimeLimitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/TimeLimitPage.lua")
		TimeLimitPage.OnRecvMessage(game_data)

		MiniGamePage.OnRecvMessage(game_data)

		-- Learning tool page message handling
		local LearningToolPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/LearningToolPage.lua")
		LearningToolPage.OnRecvMessage(game_data)
	end
end

function MiniGameMgr:UnloadGame(game_name)
	if self.game_list[game_name] ~= nil then
		if self:IsEmscripten() then
			Emscripten:OffMsg(event_name)
		else
			NPLJS:OffMsg(event_name)
		end
	end
	if self.current_game == game_name then
		self.current_game = nil
	end
end

function MiniGameMgr.HandleGameMsg(msgdata, msgid)
	if not MiniGameMgr.isLoadWebView then
		MiniGameMgr:LoadWebviewFinished()
	end
	MiniGameMgr:ReceiveMessage(msgdata)
end

function MiniGameMgr:RegisterGame(game_data)
	local game_data = game_data or {}
	local game_name = game_data.name or ""
	if not game_name or game_name == "" then
		return
	end
	if self.game_list[game_name] == nil then
		self.game_list[game_name] = game_data
	else
		local oldGameData = self.game_list[game_name]
		for k, v in pairs(game_data) do
			oldGameData[k] = v
		end
	end
end

function MiniGameMgr:RegisterGameNpc(npcConfig)
	if not npcConfig then
		return
	end
	self.NpcList = npcConfig
	self.isCustomGameStarted = true
	-- self:RegisterCustomChat()
	self:RegisterGameMapNpc()
	self:RefreshGameDock()
end

local defaultConfig = {
	yindaoyuan = "王校长",
	laoyeye = "钓鱼导师",
	shen_dian_shou_hu_zhe = "神殿守护者",
	papa = "帕帕(创作导师)",
}
function MiniGameMgr:RegisterGameMapNpc(npcConfig)
	self.mapList = self.mapList or {}
	local npcConfig = npcConfig or defaultConfig
	local allEntities = GameLogic.EntityManager.FindEntitiesByClassName("LiveModel")
	local checkAsset = "character/CC/05effect/fireglowingcircle.x"
	for _, entity in ipairs(allEntities) do
		local modelUrl = entity:GetModelFile()
		if modelUrl and modelUrl == checkAsset then
			local actionname = entity:GetStaticTag("actionname")
			local subTag = entity:GetStaticTag("subtag")
			local bx, by, bz = entity:GetBlockPos()
			if actionname and subTag then
				self.mapList[#self.mapList + 1] = {
					displayName = actionname,
					name = subTag,
					subTag = subTag,
					pos = { x = bx, y = by, z = bz },
				}
			end
		end
	end
	for k, v in pairs(npcConfig) do
		local entity = GameLogic.EntityManager.GetEntity(k)
		if entity then
			local bx, by, bz = entity:GetBlockPos()
			self.mapList[#self.mapList + 1] = {
				displayName = v,
				name = k,
				entityName = k,
				dialog = "",
				pos = { x = bx, y = by, z = bz },
			}
		end
	end
end

function MiniGameMgr:RegisterCustomChat()
	if self.customChat then
		return
	end
	self.customChat = true
	GameLogic.GetFilters():add_filter("ggs_custom_chat", MiniGameMgr.GetCustomChatConfig)
	GameLogic.GetFilters():add_filter("show_custom_create_new_world", MiniGameMgr.GetCustomCreateWorld)
end

local customChatConfig = {
	background = "Texture/Aries/HeadOn/head_speak_bg_32bits.png;0 0 128 64:24 20 64 41",
	min_width = 88,
	min_height = 64,
	text_color = "#333333",
	padding = 14,
	padding_bottom = 36,
	max_width = 230,
	fontSize = 14,
}

function MiniGameMgr.GetCustomChatConfig()
	return customChatConfig
end

function MiniGameMgr.GetCustomCreateWorld()
	return "aigc_custom_create"
end

function MiniGameMgr:GetNpcList()
	return self.NpcList
end

function MiniGameMgr:GetMapList()
	return self.mapList
end

function MiniGameMgr:ClearGames()
	for k, v in pairs(self.game_list) do
		self.game_list[k] = nil
		if self:IsEmscripten() then
			Emscripten:OffMsg(event_name)
		else
			NPLJS:OffMsg(event_name)
		end
	end
	self.current_game = nil
	self.game_list = {}
	self.world_loaded = false
	self.swf_loading_closed = false
end

function MiniGameMgr:SetTimeLimitCheck(timeLimitCheck)
	self.timeLimitCheck = timeLimitCheck
end

function MiniGameMgr:StartGame(game_name)
	if not game_name then
		return
	end
	if MiniGamePage.IsTimeLimited() and self.timeLimitCheck then
		MiniGamePage.ShowTimeLimitPage()
		return
	end
	if self.timeLimitCheck == false then
		self.timeLimitCheck = true
	end

	if not self.game_list[game_name] then
		print("MiniGameMgr:StartGame game_name not found", game_name)
		echo(self.game_list, true)
		GameLogic.AddBBS(nil, L("请先注册当前游戏"))
		return
	end
	if self.current_game == game_name then
		GameLogic.AddBBS(nil, L("当前游戏已经在运行"))
		return
	end
	if self.current_game and self.current_game ~= "" then
		MiniGamePage.ClosePage()
	end
	if self:GetStamina() <= 0 and self.timeLimitCheck then
		_guihelper.MessageBox("当前体力不足，无法进行游戏")
		return
	end
	self:UpdateStamina(-10)
	self.current_game = game_name
	local game_data = self.game_list[game_name]
	local game_url = game_data.url or game_data.game_url or ""
	if game_url ~= "" then
		MiniGamePage.OpenBrowser(game_url, function()
			self:StopGame()
		end)
	end
end

function MiniGameMgr:StopGame()
	if self.current_game then
		self:UnloadGame(self.current_game)
	end
end

function MiniGameMgr:TeleportToGame(game_name)
	if not game_name or game_name == "" then
		return
	end
	if not self.game_list[game_name] then
		-- GameLogic.AddBBS(nil,L"请先注册当前游戏")
		return
	end
	local npcList = MiniGameMgr.NpcList or {}
	for _, npc in ipairs(npcList) do
		local games = npc.games or {}
		local pos = npc.pos or {}
		for _, game in ipairs(games) do
			if game.gameName == game_name then
				self:TeleportToNpc(npc)
			end
		end
	end
end

function MiniGameMgr:TeleportToNpc(npc)
	if not npc then
		return
	end
	local MiniGameMap = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMap.lua")
	MiniGameMap:TeleportNpcImp(npc)
end

local MAX_DAILY_BEANS = 100 -- 每日知识豆上限
local exchange_beans_list =
	{ { 31035, 5 }, { 11001, 10 }, { 11002, 20 }, { 11003, 30 }, { 31032, 50 }, { 31001, 80 }, { 11004, 100 }, {
		30054,
		300,
	} }

-- 知识豆生成公式配置
local BEAN_FORMULA_CONFIG = {
	base_reward = 5, -- 基础奖励
	score_factor = 0.1, -- 得分因子
	difficulty_factor = 3, -- 难度因子
	time_factor = 0.05, -- 时长因子(每分钟)
	min_reward = 5, -- 最小奖励
	max_reward = 50, -- 单次最大奖励
}

-- 计算知识豆奖励
local function CalculateBeanReward(score, difficulty, play_time)
	-- 参数标准化
	score = score or 0
	difficulty = difficulty or 1 -- 难度范围1-5
	play_time = play_time or 0 -- 游戏时长(秒)

	-- 限制难度范围
	difficulty = math.max(1, math.min(5, difficulty))

	-- 计算基于公式的奖励
	local time_minutes = play_time / 60
	local reward = BEAN_FORMULA_CONFIG.base_reward
		+ (score * BEAN_FORMULA_CONFIG.score_factor)
		+ (difficulty * BEAN_FORMULA_CONFIG.difficulty_factor)
		+ (time_minutes * BEAN_FORMULA_CONFIG.time_factor)

	-- 应用上下限
	reward = math.floor(reward) -- 取整
	reward = math.max(BEAN_FORMULA_CONFIG.min_reward, math.min(BEAN_FORMULA_CONFIG.max_reward, reward))

	return reward
end

function MiniGameMgr:ProcessBeanReward(game_id, params, success_callback, error_callback, toObject)
	if not game_id then
		if error_callback then
			error_callback("游戏ID不能为空")
		end
		return
	end
	local score = params.score or 0
	local difficulty = params.difficulty or 1
	local play_time = params.play_time or 0
	local earnedPoints = params.earnedPoints or 0
	local isIgnoreMax = game_id == "characterAI"
	local currentGameData = self.localGameData[game_id] or {}
	local currentKnowledgeBean = currentGameData.knowledge_bean or 0
	if currentKnowledgeBean >= MAX_DAILY_BEANS and not isIgnoreMax then
		local errorMsg = "获得知识豆失败，当前已达到每日上限"
		GameLogic.AddBBS(nil, errorMsg)
		if error_callback then
			error_callback(errorMsg)
		end
		return
	end

	local beanReward = CalculateBeanReward(score, difficulty, play_time)
	if earnedPoints > 0 and isIgnoreMax then
		beanReward = 300
	else
		beanReward = math.min(beanReward, MAX_DAILY_BEANS - currentKnowledgeBean)
	end
	if params and params.beanNum then
		beanReward = params.beanNum
	end
	self:AchieveBean(beanReward, function(result)
		if result and result.achieve and (result.achieve == true or result.achieve == "true") then
			local beanNum = result.beanNum
			currentGameData.knowledge_bean = currentKnowledgeBean + beanNum
			currentGameData.game_id = game_id
			currentGameData.score = math.max(currentGameData.score or 0, score) -- 保存最高分
			currentGameData.difficulty = difficulty
			currentGameData.last_play_time = os.time() -- 记录最后游玩时间
			currentGameData.total_plays = (currentGameData.total_plays or 0) + 1
			currentGameData.total_time = (currentGameData.total_time or 0) + play_time
			self.localGameData[game_id] = currentGameData
			self:SaveGameData()
			if success_callback then
				success_callback(beanNum, currentGameData)
			end
			self.achieveBeanNum = beanNum
		else
			local msg = result.msg or "获得知识豆失败"
			if error_callback then
				error_callback(msg)
			end
		end
	end, true, toObject)
end

function MiniGameMgr:AchieveBean(achieveNum, callback, bPlayGetEffect, toObject)
	local exchangeId, exchangeNum = self:GetExchangeIdByBeans(achieveNum)
	if exchangeId and exchangeNum then
		KeepWorkItemManager.DoExtendedCost(exchangeId, function()
			local beanNum = exchangeNum
			if bPlayGetEffect then
				local screenWidth = Screen:GetWidth()
				local screenHeight = Screen:GetHeight()
				local toObject = toObject or { x = screenWidth - 80, y = 30 }
				self:PlayGetBeansEffect(beanNum, toObject, function()
					GameLogic.AddBBS(nil, "获得" .. beanNum .. "知识豆")
				end)
			end
			KeepWorkItemManager.LoadItems(nil, function()
				if callback and type(callback) == "function" then
					callback({ beanNum = beanNum, achieve = true })
				end
			end)
		end, function(err, msg, data)
			local errorMsg = "获得知识豆失败，" .. err .. "，请重试"
			GameLogic.AddBBS(nil, errorMsg)
			if callback and type(callback) == "function" then
				callback({ beanNum = 0, achieve = false, msg = errorMsg })
			end
		end)
	else
		local errorMsg = "获得知识豆失败，无法确定奖励数量"
		GameLogic.AddBBS(nil, errorMsg)
		if callback and type(callback) == "function" then
			callback({ beanNum = 0, achieve = false, msg = errorMsg })
		end
	end
end

function MiniGameMgr:ReceiveLocalGameData(game_data)
	-- 处理本地游戏获得知识豆的事件
	if not game_data then
		return
	end

	local game_id = game_data.game_id or ""
	local score = game_data.score or 0
	local difficulty = game_data.difficulty or 0
	local play_time = game_data.play_time or 0 -- 新增游戏时长参数(秒)
	local toObject = game_data.toObject or nil --特效位置 {x=0,y=0}
	if not toObject then
		local screenWidth = Screen:GetWidth()
		local screenHeight = Screen:GetHeight()
		toObject = { x = screenWidth - 80, y = 30 }
	end

	-- 调用统一的知识豆处理方法
	local params = {
		score = score,
		difficulty = difficulty,
		play_time = play_time,
	}
	self:ProcessBeanReward(game_id, params, nil, nil, toObject)
end

function MiniGameMgr:GetExchangeIdByBeans(beanNum)
	if not beanNum or beanNum <= 0 then
		return nil, nil
	end

	-- 按照豆子数量排序兑换列表
	local sortedList = commonlib.copy(exchange_beans_list)
	table.sort(sortedList, function(a, b)
		return a[2] < b[2]
	end)

	-- 找到最接近但不超过目标数量的兑换项
	local bestMatch = nil
	for _, item in ipairs(sortedList) do
		if item[2] <= beanNum then
			bestMatch = item
		else
			break
		end
	end

	-- 如果没有找到匹配项，使用最小的
	if not bestMatch and #sortedList > 0 then
		bestMatch = sortedList[1]
	end

	if bestMatch then
		return bestMatch[1], bestMatch[2]
	end

	return nil, nil
end

function MiniGameMgr:LoadGameData()
	self.localGameData = GameLogic.GetPlayerController():LoadLocalData(MiniGameDataKey, nil, true) or {}
	-- 检查是否跨天，如果跨天则重置所有游戏的知识币计数
	local current_date = os.date("%Y-%m-%d")
	local last_save_date = self.localGameData._last_save_date

	if last_save_date and last_save_date ~= current_date then
		-- 跨天了，重置所有游戏的知识币计数
		LOG.std(
			nil,
			"info",
			"MiniGameMgr",
			"日期已更新，重置知识币计数: %s -> %s",
			last_save_date,
			current_date
		)

		-- 遍历所有游戏数据，重置知识币计数
		for game_id, game_data in pairs(self.localGameData) do
			if type(game_data) == "table" and game_id ~= "_last_save_date" then
				game_data.knowledge_bean = 0
				-- 记录重置历史
				game_data.last_reset_date = current_date
				game_data.reset_count = (game_data.reset_count or 0) + 1
			end
		end

		-- 更新日期
		self.localGameData._last_save_date = current_date

		-- 保存更新后的数据
		GameLogic.GetPlayerController():SaveLocalData(MiniGameDataKey, self.localGameData, true)
	end
end

function MiniGameMgr:SaveGameData()
	-- 记录当前日期
	self.localGameData._last_save_date = os.date("%Y-%m-%d")
	GameLogic.GetPlayerController():SaveLocalData(MiniGameDataKey, self.localGameData, true)
end

function MiniGameMgr:PlayGetBeansEffect(beanNum, toObj, finishCallback)
	if not beanNum or beanNum <= 0 then
		return
	end
	local toObject = toObj or GameLogic.DockManager:GetDockByName("skin")
	if not toObject then
		local skinObj = ParaUI.GetUIObject("skin")
		if skinObj and skinObj:IsValid() then
			toObject = skinObj
		end
	end
	if not toObject then
		return
	end
	local dock_x, dock_y -- 2d ui point
	if toObject and toObject.GetAbsPosition and type(toObject.GetAbsPosition) == "function" then
		dock_x, dock_y, _, _ = toObject:GetAbsPosition()
	elseif toObject and toObject.x then
		dock_x, dock_y = toObject.x, toObject.y
	end
	dock_x = dock_x or 10
	dock_y = dock_y or 10
	local x, y, z
	local result = Game.SelectionManager:GetPickingResult()
	if not result or not result.x then
		x, y, z = ParaScene.GetPlayer():GetPosition()
	else
		x, y, z = result.x, result.y, result.z
	end
	local bx, by, bz = BlockEngine:block(x, y + 0.1, z)

	local effectPoints = {}
	local pointNum = math.floor(beanNum / 20 + 1)
	local pointSize = 0
	pointNum = math.max(pointNum, 2)
	for i = bx - pointNum, bx + pointNum do
		for j = bz - pointNum, bz + pointNum do
			local point = { x = i, y = by, z = j }
			table.insert(effectPoints, point)
			pointSize = pointSize + 1
		end
	end
	local effectNum = math.floor(beanNum / 5) + 1
	effectNum = math.max(effectNum, 4) + 6
	local result_index_list = commonlib.GetRandomList(pointSize, effectNum)
	for i = 1, effectNum do
		local point = effectPoints[result_index_list[i]]
		local obtainData = {
			background = "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;464 43 18 18",
			duration = 1000,
			color = "#ffffffff",
			width = 18,
			height = 18,
			from_3d = { bx = point.x, by = point.y, bz = point.z },
			to_2d = { x = dock_x + 8, y = dock_y + 8 },
		}
		if i == effectNum and finishCallback then
			obtainData.finishCallback = finishCallback
		end
		ObtainItemEffect:new(obtainData):Play()
	end
end

function MiniGameMgr:LoadWebviewFinished()
	self.isLoadWebView = true
	print("MiniGameMgr:LoadWebviewFinished=================")
	if self:IsEmscripten() then
		Emscripten:OnMsg(event_name, MiniGameMgr.HandleGameMsg)
	else
		NPLJS:OnMsg(event_name, MiniGameMgr.HandleGameMsg)
	end
	if self.preSendMsgQueue and not self.preSendMsgQueue:empty() then
		self:SendMsgList()
	end
end

function MiniGameMgr:IsVip()
	return KeepWorkItemManager.IsVip()
end

function MiniGameMgr:IsMaisiVip()
	local isMaisiUser = System.options.thirdpartytoken
		and System.options.thirdpartytoken ~= ""
		and System.options.clientId
		and System.options.clientId == "maisi"
	if not isMaisiUser then
		return false
	end
	if type(self.maisiUserInfo) == "table" then
		return self.maisiUserInfo.isVip == true
	end
	return true
end

function MiniGameMgr:GetMaisiUserInfo()
	return self.maisiUserInfo
end

function MiniGameMgr:LoadUserInfo(callback)
	local username = Mod.WorldShare.Store:Get("user/username")
	if not username or username == "" then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	local id = "kp" .. System.Encoding.base64(commonlib.Json.Encode({ username = username }))
	keepwork.user.getinfo({
		cache_policy = "access plus 0",
		router_params = {
			id = id,
		},
	}, function(err, msg, data)
		if err == 200 then
			self.UserData = data
			if callback and type(callback) == "function" then
				callback(data)
			end
		else
			if callback and type(callback) == "function" then
				callback()
			end
		end
	end)
end

function MiniGameMgr:CloseWebview()
	self.isLoadWebView = false
	self.preSendMsgQueue = nil
end

function MiniGameMgr:SendMsgList()
	self.msgTimer = self.msgTimer
		or commonlib.Timer:new({
			callbackFunc = function(timer)
				if not self.preSendMsgQueue or self.preSendMsgQueue:empty() then
					timer:Change()
					return
				end
				local msgData = self.preSendMsgQueue:popleft()
				if msgData then
					NPLJS:SendMsg(msgData.name, msgData.msg)
				end
			end,
		})
	self.msgTimer:Change(100, 30)
end

function MiniGameMgr:LoadMaisiGameInfo(callback)
	if self.maisiAPI then
		self.maisiAPI:LoadMaisiGameInfo(function(data)
			if data then
				self.maisiUserInfo = data.userInfo or {}
				if type(data.userDetail) == "table" then
					for k, v in pairs(data.userDetail) do
						self.maisiUserInfo[k] = v
					end
				end
				self.maisiUserCaps = data.userCaps
			end
			if callback and type(callback) == "function" then
				callback(data)
			end
		end)
	else
		if callback and type(callback) == "function" then
			callback(nil)
		end
	end
end

function MiniGameMgr:GetMaisiToken(callback)
	if self.maisiAPI then
		self.maisiAPI:GetMaisiToken(callback)
	else
		if callback and type(callback) == "function" then
			callback(false)
		end
	end
end

-- 强制刷新Maisi数据
function MiniGameMgr:ForceRefreshMaisiData(cacheType, callback)
	if self.maisiAPI then
		self.maisiAPI:ForceRefresh(cacheType, callback)
	else
		if callback and type(callback) == "function" then
			callback(false)
		end
	end
end

-- 强制刷新所有Maisi数据
function MiniGameMgr:ForceRefreshAllMaisiData(callback)
	if self.maisiAPI then
		self.maisiAPI:ForceRefreshAll(callback)
	else
		if callback and type(callback) == "function" then
			callback(nil)
		end
	end
end

-- 强制刷新Maisi数据
function MiniGameMgr:ClearMaisiData()
	self.maisiUserInfo = nil
	self.maisiUserCaps = nil
	if self.maisiAPI then
		self.maisiAPI:ClearCache()
	end
	self.petInfo = nil
end

function MiniGameMgr:LoadThirdPartyGameInfo(callback)
	self:GetMaisiToken(function(bGetToken)
		self:LoadMaisiGameInfo(function(data)
			if callback and type(callback) == "function" then
				callback(data)
			end
		end)
	end)
end

function MiniGameMgr:UpdateGameRecommend(callback)
	local MiniGameUserProfile = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserProfile.lua")
	MiniGameUserProfile.UpdateScoreByUserCaps(self.maisiUserCaps)
	local maisiRecommends = {}
	if self.maisiUserInfo and type(self.maisiUserInfo) == "table" then
		local gameConfig = {}
		for gameKey, gameData in pairs(self.game_list) do
			if not gameData.ignoreRecommend then
				gameConfig[gameKey] = gameData
			end
		end
		local gameNames = commonlib.split(self.maisiUserInfo.gameName, ",")
		local gameMaps = {}
		for _, gameName in ipairs(gameNames) do
			gameMaps[gameName] = true
		end

		for k, v in pairs(gameConfig) do
			if v.title and gameMaps[v.title] then
				maisiRecommends[#maisiRecommends + 1] = v
			end
		end
	end
	self:LoadTodayGameRecommends(callback, maisiRecommends)
end

function MiniGameMgr:LoadTodayGameConfig(callback, bForceUpdate)
	local today = os.date("%Y-%m-%d")
	local gameConfig = GameLogic.GetPlayerController():LoadLocalData(MiniGameConfigKey, nil, true)
	if
		gameConfig
		and gameConfig.date == today
		and (gameConfig.selectedGames and #gameConfig.selectedGames > 0)
		and not bForceUpdate
	then
		if callback and type(callback) == "function" then
			callback(gameConfig)
		end
		self:SetTodayGameConfig(gameConfig)
		self:LoadThirdPartyGameInfo()
		return
	end
	LOG.std(nil, "info", "MiniGameMgr", "LoadTodayGameConfig: 没有找到今天的游戏配置")
	self:LoadThirdPartyGameInfo(function(data)
		if data and type(data) == "table" then
			self:SetTodayGameConfig(data)
			self:UpdateGameRecommend(callback)
		end
	end)
end

function MiniGameMgr:SetTodayGameConfig(gameConfig)
	self.todayGameConfig = gameConfig
	self:LoadParentControl(function()
		self:CheckTodayGameFinished(2000)
	end)
end

function MiniGameMgr:LoadParentControl(callback)
	GameLogic.PersonalPageStore:LoadPageData("parent_control", "settings", function(data)
		self.parentSettings = data
		if callback and type(callback) == "function" then
			callback(data)
		end
	end)
end

local dailyGamePage = "maisi_userinfo"
local dailyGameKey = "dragon.daily_practice"
function MiniGameMgr:CheckTodayGameFinished(checkTime)
	if not self.parentSettings or not self.parentSettings.requireDailyTraining then
		return
	end
	local today = os.date("%Y%m%d")
	local todayRecommendNum = (self.todayGameConfig and self.todayGameConfig.selectedGames)
			and #self.todayGameConfig.selectedGames
		or 3
	GameLogic.PersonalPageStore:LoadPageData(dailyGamePage, dailyGameKey, function(data)
		if data and type(data) == "table" then
			if tostring(data.time) == today then
				local finishedNum = data.finished and #data.finished or 0
				if finishedNum >= todayRecommendNum then
					return
				end
			end
			self:StartGameCheckTimer(checkTime)
			return
		end
		self:StartGameCheckTimer(checkTime)
	end)
end
local defaultTime = 60000
function MiniGameMgr:StartGameCheckTimer(checkTime)
	self.gameCheckTimer = self.gameCheckTimer
		or commonlib.Timer:new({
			callbackFunc = function()
				-- self:ShowTimeCheckMessage()
			end,
		})
	self.gameCheckTimer:Change(checkTime or defaultTime, nil)
end

function MiniGameMgr:ShowTimeCheckMessage()
	if self.gameCheckTimer then
		self.gameCheckTimer:Change()
	end
	if MiniGamePage.IsVisible() then
		return
	end
	_guihelper.MessageBox(
		L("请先完成今日任务，才能继续游戏！<br/>完成3个训练任务后，将不再弹出本提示。<br/>可在家长控制中心更改此设置。"),
		function(res)
			if res and res == _guihelper.DialogResult.Yes then
				self:StartTodayGame()
			else
				self:CheckTodayGameFinished(3000)
			end
		end,
		_guihelper.MessageBoxButtons.YesNoCancel
	)
end

function MiniGameMgr:StartTodayGame()
	_guihelper.MessageBox(nil)
	local todayRecommendGame = self.todayGameConfig and self.todayGameConfig.selectedGames or {}
	GameLogic.PersonalPageStore:LoadPageData(dailyGamePage, dailyGameKey, function(data)
		local finishedGameKeys = {}
		if data and type(data) == "table" then
			local finishedGames = data.finished or {}
			for _, game in ipairs(finishedGames) do
				finishedGameKeys[game] = true
			end
		end
		for _, game in ipairs(todayRecommendGame) do
			if not finishedGameKeys[game.name] then
				local MiniGameMainPage =
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua")
				MiniGameMainPage.StartWebGame(game.name, nil, true)
				break
			end
		end
	end)
end

function MiniGameMgr:LoadTodayGameRecommends(callback, recommends)
	local todayGameConfig = {}
	-- 获取用户能力配置
	local MiniGameUserProfile = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameUserProfile.lua")
	MiniGameUserProfile.LoadUserData(function(data)
		-- 所有注册的游戏
		local gameConfig = {}
		for gameKey, gameData in pairs(self.game_list) do
			if not gameData.ignoreRecommend then
				gameConfig[gameKey] = gameData
			end
		end
		-- 获取推荐能力
		local recommendedAbilities, untrainedAbilities = MiniGameUserProfile.GetRecommendedAbilities()
		local selectedGames = {}

		-- 根据未训练的能力找到对应的游戏
		if untrainedAbilities and #untrainedAbilities > 0 then
			local untrainedAbilityKeys = {}
			-- 提取未训练能力的key
			for _, ability in ipairs(untrainedAbilities) do
				untrainedAbilityKeys[ability.key] = true
			end
			local untrainedGames = {}
			for gameKey, gameData in pairs(gameConfig) do
				local hasUntrainedAbility = false
				local gameAblities = gameData.abilities or {}
				for _, abilityKey in pairs(gameAblities) do
					if untrainedAbilityKeys[abilityKey] then
						hasUntrainedAbility = true
						break
					end
				end

				if hasUntrainedAbility then
					table.insert(untrainedGames, gameData)
				end
			end
			-- firstScoreOrder
			table.sort(untrainedGames, function(a, b)
				local orderA = a.firstScoreOrder or 999
				local orderB = b.firstScoreOrder or 999
				return orderA < orderB
			end)
			-- 选择前3个游戏
			for i = 1, math.min(3, #untrainedGames) do
				table.insert(selectedGames, untrainedGames[i])
			end
		end
		if #selectedGames < 3 then
			local matchedGames = {}
			local recommendedAbilityKeys = {}
			-- 提取推荐能力的key
			for _, ability in ipairs(recommendedAbilities) do
				recommendedAbilityKeys[ability.key] = true
			end

			-- 记录已选择的游戏
			local selectedGameKeys = {}
			for _, game in ipairs(selectedGames) do
				selectedGameKeys[game.name] = true
			end

			-- 遍历游戏配置，找到包含推荐能力的游戏（排除已选择的）
			for gameKey, gameData in pairs(gameConfig) do
				if not selectedGameKeys[gameData.name] then
					local matchCount = 0
					local gameAbilities = gameData.abilities or {}
					for _, abilityKey in ipairs(gameAbilities) do
						if recommendedAbilityKeys[abilityKey] then
							matchCount = matchCount + 1
						end
					end

					if matchCount > 0 then
						table.insert(matchedGames, {
							gameKey = gameKey,
							gameData = gameData,
							matchCount = matchCount,
						})
					end
				end
			end
			-- 按推荐值排序
			table.sort(matchedGames, function(a, b)
				return a.gameData.recommendedValue > b.gameData.recommendedValue
			end)
			-- 按匹配度排序（匹配度高的在前）
			table.sort(matchedGames, function(a, b)
				return a.matchCount > b.matchCount
			end)

			-- 补充游戏直到达到3个
			for i = 1, math.min(3 - #selectedGames, #matchedGames) do
				table.insert(selectedGames, matchedGames[i].gameData)
			end
		end
		-- 如果匹配的游戏不足3个，从剩余游戏中随机补充
		if #selectedGames < 3 then
			local remainingGames = {}
			local selectedGameKeys = {}
			-- 记录已选择的游戏
			for _, game in ipairs(selectedGames) do
				selectedGameKeys[game.name] = true
			end
			-- 收集未选择的游戏
			for gameKey, gameData in pairs(gameConfig) do
				if not selectedGameKeys[gameData.name] then
					table.insert(remainingGames, gameData)
				end
			end
			-- 随机补充游戏
			while #selectedGames < 3 and #remainingGames > 0 do
				local randomIndex = math.random(1, #remainingGames)
				table.insert(selectedGames, remainingGames[randomIndex])
				table.remove(remainingGames, randomIndex)
			end
		end

		local recommenGames = recommends or {}
		local firstRecommendNum = 0
		-- 记录推荐游戏
		local recommenGameMaps = {}
		for _, game in pairs(recommenGames) do
			recommenGameMaps[game.name] = true
			firstRecommendNum = firstRecommendNum + 1
		end
		for k, v in pairs(selectedGames) do
			if firstRecommendNum < 3 and not recommenGameMaps[v.name] then
				table.insert(recommenGames, v)
				firstRecommendNum = firstRecommendNum + 1
			end
		end
		-- 构建今日游戏配置
		local today = os.date("%Y-%m-%d")
		todayGameConfig = {
			date = today,
			recommendedAbilities = recommendedAbilities,
			selectedGames = recommenGames,
		}
		GameLogic.GetPlayerController():SaveLocalData(MiniGameConfigKey, todayGameConfig, true)
		if callback and type(callback) == "function" then
			callback(todayGameConfig)
		end
	end)
end

function MiniGameMgr:PlayMountOnEffect(callback)
	NPL.load("(gl)script/apps/Aries/Scene/EffectManager.lua")
	local EffectManager = MyCompany.Aries.EffectManager
	local params1 = {
		scale = 1,
		offset_angle = 0,
		asset_file = "character/v5/09effect/Common/Xuanwo02_Xuanzhuan_Blue.x",
		offset_y = 0,
		duration_time = 1500,
	}
	local params2 = {
		scale = 0.7,
		offset_angle = 0,
		asset_file = "character/v5/09effect/Combat_Fire/Fire_Pet_SingleAttack_FireRockyOgresDominance_Missile_yan.x",
		offset_y = 0.7,
		duration_time = 500,
	}

	params1.force_name = "MountOn" .. ParaGlobal.GenerateUniqueID()
	params1.binding_obj_name = "localuser"
	params1.begin_callback = function()
		if callback and type(callback) == "function" then
			callback()
		end
	end
	params1.end_callback = function() end
	params2.force_name = "MountOn" .. ParaGlobal.GenerateUniqueID()
	params2.binding_obj_name = "localuser"
	params2.begin_callback = function() end
	params2.end_callback = function() end

	EffectManager.CreateEffect(params1)
	EffectManager.CreateEffect(params2)
end

function MiniGameMgr:ReportGame(reportMsg)
	local machineId, uuid = MiniGameMgr.GetUniqueId()
	local reportMsg = reportMsg or {}
	local gameMsg = {}
	gameMsg.deviceId = machineId
	gameMsg.uniqueId = uuid
	gameMsg.reportTime = os.time()
	gameMsg.isVip = self:IsVip()
	for k, v in pairs(reportMsg) do
		gameMsg[k] = v
	end
	print("MiniGameMgr:ReportGame=================", commonlib.serialize_compact(gameMsg))
	GameLogic.GetFilters()
		:apply_filters("user_behavior", 1, "paracraft.game.report", { gameMsg = gameMsg, useNoId = true }, nil, true)
end

--消费知识豆
function MiniGameMgr:ConsumeKnowledgeBean(beanNum, callback)
	SkinDrawSystem:ConsumeKnowledgeBean(beanNum, callback)
end

function MiniGameMgr:ConsumeDrawSkins(skinDatas)
	SkinDrawSystem:ConsumeDrawSkins(skinDatas)
end

function MiniGameMgr:PurchaseItems(purchaseItems, bFree, callback)
	SkinDrawSystem:PurchaseItems(purchaseItems, bFree, callback)
end

function MiniGameMgr:ApplySkinToPlayer(skinString)
	SkinDrawSystem:ApplySkinToPlayer(skinString)
end

function MiniGameMgr:UpdateUserExtra(extra, callback, isReplaceExtra)
	if not extra then
		return
	end
	local userinfo = Keepwork:GetUserInfo()
	if not userinfo or not userinfo.id then
		LOG.std(nil, "error", "MiniGameMgr", "UpdateUserExtra: User info not found")
		return
	end
	keepwork.user.setinfo({
		router_params = { id = userinfo.id },
		extra = extra,
		isReplaceExtra = isReplaceExtra,
	}, function(status, msg, data)
		if status >= 200 and status < 300 then
			local profile = KeepWorkItemManager.GetProfile()
			if profile then
				profile.extra = extra
			end
			if callback and type(callback) == "function" then
				callback()
			end
			LOG.std(nil, "info", "MiniGameMgr", "Player extra info updated successfully")
		else
			LOG.std(nil, "error", "MiniGameMgr", "Failed to update player extra info: " .. tostring(status))
		end
	end)
end

--坐骑 宠物
function MiniGameMgr:MountOnDragon(skin, stage)
	if not self.petManager then
		return
	end
	local mountConfig = self.petManager:GetPetConfig(skin, stage)
	if mountConfig and mountConfig.mountId and mountConfig.mountId > 0 then
		local mountId = mountConfig.mountId
		MiniGameMgr:MountOnPets(mountId, true)
		self.isMountDragon = true
	end
end

function MiniGameMgr:IsMountDragon()
	return self.isMountDragon and self:IsSkinContainsDragon()
end

function MiniGameMgr:IsSkinContainsDragon()
	local playerEntity = GameLogic.GetPlayerController():GetPlayer()
	if not playerEntity then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Player entity not found")
		return false
	end
	local skin = playerEntity:GetSkin()
	skin = CustomCharItems:SkinStringToItemIds(skin)
	local skinTable = commonlib.split(skin, ";")
	local mountId
	for _, v in ipairs(skinTable) do
		if CustomCharItems:IsMountPetItem(v) then
			mountId = v
			break
		end
	end
	local itemData = CustomCharItems:GetItemById(mountId)
	local filename = itemData and itemData.filename or ""
	local lowerFileName = string.lower(filename)
	if lowerFileName:find("%.dds$") then
		return true
	end
	return false
end

function MiniGameMgr:MountOnPets(petId)
	local petItem = CustomCharItems:GetPetItem(petId) or {}
	petId = petItem.id
	if not petId or not tonumber(petId) then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Invalid mount ID with nil item")
		return
	end
	if not CustomCharItems:IsMountPetItem(petId) then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Invalid mount ID")
		return
	end
	local mountId = tonumber(petId)
	if mountId < 89000 or mountId > 89999 then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Invalid mount ID")
		return
	end
	local userinfo = Keepwork:GetUserInfo()
	if not userinfo or not userinfo.id then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: User info not found")
		return
	end
	local extra = userinfo.extra or {}
	extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {}
	local skin = extra.ParacraftPlayerEntityInfo.skin
	skin = CustomCharItems:SkinStringToItemIds(skin)
	if skin:find(petId) then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Mount already mounted")
		return
	end
	skin = CustomCharItems:RemovePetIdFromSkinIds(skin)
	local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
	skin = PlayerAssetFile.AddPetIdToSkinIds(skin, petId)
	local playerEntity = GameLogic.GetPlayerController():GetPlayer()
	if not playerEntity then
		LOG.std(nil, "error", "MiniGameMgr", "MountOnPets: Player entity not found")
		return
	end
	local asset = GameLogic.GetPlayerController():GetMainAssetPath() or "character/CC/02human/CustomGeoset/actor.x"
	playerEntity:SetSkin(skin)
	playerEntity:SetMainAssetPath(asset)
end

function MiniGameMgr:UnMountPets()
	local userinfo = Keepwork:GetUserInfo()
	if not userinfo or not userinfo.id then
		LOG.std(nil, "error", "MiniGameMgr", "UnMountPets: User info not found")
		return
	end
	self.isMountDragon = false
	local extra = userinfo.extra or {}
	extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {}
	local skin = extra.ParacraftPlayerEntityInfo.skin
	skin = CustomCharItems:SkinStringToItemIds(skin)
	skin = CustomCharItems:RemovePetIdFromSkinIds(skin)
	local playerEntity = GameLogic.GetPlayerController():GetPlayer()
	if not playerEntity then
		LOG.std(nil, "error", "MiniGameMgr", "ApplySkinToPlayer: Player entity not found")
		return
	end
	local asset = GameLogic.GetPlayerController():GetMainAssetPath() or "character/CC/02human/CustomGeoset/actor.x"
	playerEntity:SetSkin(skin)
	playerEntity:SetMainAssetPath(asset)
end

--宠物
function MiniGameMgr:AddUserPets(petData, callback)
	if not petData then
		return
	end
	local isAddMain = petData.type == "main"
	if isAddMain and self.petManager then
		local petItem = self.petManager:GetPetConfig(petData.skin, petData.stage)
		if petItem and petItem.petId then
			petData.id = petItem.petId
			petData.skin = nil
			petData.stage = nil
		end
	end
	local petInfo = self.petInfo or {}
	if isAddMain then --主宠物只能存在一个
		local newPetInfo = {}
		for _, pet in ipairs(petInfo) do
			if pet.type ~= "main" then
				table.insert(newPetInfo, pet)
			end
		end
		petInfo = newPetInfo
	end
	local petMap = {}
	for _, pet in ipairs(petInfo) do
		if pet.id then
			petMap[pet.id] = pet
		end
	end
	if not petMap[petData.id] then
		table.insert(petInfo, petData)
	end
	self.petInfo = petInfo
	self:UpdatePetStatus(callback)
end

function MiniGameMgr:GetPetInfo()
	return self.petInfo
end

function MiniGameMgr:RemoveUserPets(petIds, callback)
	if not petIds then
		return
	end
	local petInfo = self.petInfo or {}
	local removeMap = {}
	if type(petIds) == "number" or type(petIds) == "string" then
		removeMap[tonumber(petIds)] = true
	elseif type(petIds) == "table" then
		for _, petId in ipairs(petIds) do
			removeMap[tonumber(petId)] = true
		end
	end
	local newPetInfo = {}
	for _, pet in ipairs(petInfo) do
		local id = tonumber(pet.id)
		if not removeMap[id] then
			table.insert(newPetInfo, pet)
		end
	end
	self.petInfo = newPetInfo
	self:UpdatePetStatus(callback)
end

local function isemptytable(t)
	return next(t) == nil
end
function MiniGameMgr:ClearUserPetInfo()
	local userinfo = Keepwork:GetUserInfo()
	if not userinfo or not userinfo.id then
		LOG.std(nil, "error", "MiniGameMgr", "ClearUserPetInfo: User info not found")
		return
	end
	local isNeedUpdate = false
	local extra = userinfo.extra or {}
	local ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {}
	local skin = ParacraftPlayerEntityInfo.skin or ""
	local noPetSkin = CustomCharItems:RemovePetIdFromSkinIds(skin)
	if noPetSkin ~= skin then
		ParacraftPlayerEntityInfo.skin = noPetSkin
		extra.ParacraftPlayerEntityInfo = ParacraftPlayerEntityInfo
		isNeedUpdate = true
	end
	local petInfo = extra.petInfo
	if type(petInfo) == "table" and not isemptytable(petInfo) then --用户信息中有宠物
		extra.petInfo = nil
		isNeedUpdate = true
	end
	if not isNeedUpdate then
		return
	end
	self:UpdateUserExtra(extra, function()
		LOG.std(nil, "info", "MiniGameMgr", "ClearUserPetInfo: Clear user pet info success")
	end, true)
end

function MiniGameMgr:ShowAllPets(bShow)
	if not self.petManager then
		return
	end
	if not bShow then
		self.petManager:HideAllPets()
	else
		self.petManager:ShowAllPets()
	end
end

function MiniGameMgr:ShowUserPets(username, bShow)
	if not self.petManager then
		return
	end
	if not bShow then
		self.petManager:HideUserPets(username)
	else
		self.petManager:ShowUserPets(username)
	end
end

function MiniGameMgr:UpdatePetStatus(callback)
	self:ClearUserPetInfo()
	if not self.petManager then
		return
	end
	self.petManager:UpdatePetStatus(callback, self.petInfo)
end

function MiniGameMgr:ShowMainPet(bShow)
	if not self.petManager then
		return
	end
	if not bShow then
		self.petManager:HideMainPet()
	else
		self.petManager:ShowMainPet()
	end
	self:UpdateMainPetStatus(bShow)
end

function MiniGameMgr:UpdateMainPetStatus(bShow)
	local petInfo = self.petInfo or {}
	for _, pet in ipairs(petInfo) do
		if pet.type == "main" then
			pet.isVisible = bShow
			break
		end
	end
	self:UpdatePetStatus(function()
		print("show hide main pet success")
	end)
end

function MiniGameMgr:GetMainPet()
	if not self.petManager then
		return
	end
	return self.petManager:GetMainPet()
end

function MiniGameMgr:ChangeMainPetAsset(asset)
	if not self.petManager then
		return
	end
	if not asset or asset == "" then
		LOG.std(nil, "warn", "MiniGameMgr", "Asset cannot be empty")
		return false
	end
	local petItem = CustomCharItems:GetPetItem(asset)
	if not petItem then
		LOG.std(nil, "warn", "MiniGameMgr", "Pet item not found")
		return false
	end
	local isNeedUpdate = false
	local petId = tonumber(petItem.id)
	local petInfo = self.petInfo or {}
	for _, pet in ipairs(petInfo) do
		if pet.type == "main" then
			if pet.id ~= petId then
				pet.id = petId
				pet.isVisible = true
				isNeedUpdate = true
				break
			end
		end
	end
	if not isNeedUpdate then
		return
	end
	self:UpdatePetStatus(function()
		print("change main pet asset success")
	end)
end

--坐骑 宠物 end

-- 游戏UI管理
-- 音乐UI刷新
function MiniGameMgr:RefreshMusicUI(bPlay)
	local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua")
	MiniGameMainPage.RefreshMusicUI(bPlay)
end

-- 隐藏关闭按钮
function MiniGameMgr:RefreshCloseBtn(bShow)
	MiniGamePage.RefreshCloseBtn(bShow)
end

function MiniGameMgr:RefreshGameDock()
	GameLogic.RunCommand("/hide quickselectbar")
	GameLogic.RunCommand("/hide dock")
	GameLogic.RunCommand("/hide map")
	GameLogic.RunCommand("/hide miniuserinfo")
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters("MobileUIRegister.IsMobileUIEnabled", false)
	if IsMobileUIEnabled then
		commonlib.TimerManager.SetTimeout(function()
			GameLogic.RunCommand("/show dock_right_bottom")
			GameLogic.RunCommand("/show dock_left_bottom")
		end, 300)
	end
end

function MiniGameMgr:RegisterGameUI(msg)
	if not msg or not msg.name then
		LOG.std(nil, "error", "MiniGameMgr", "RegisterGameUI: Game UI name not found")
		return
	end
	local MiniGameMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMainPage.lua")
	MiniGameMainPage.RegisterGameUI(msg)
end

--精力
function MiniGameMgr:GetStamina()
	return TimeLimitPage.GetStamina()
end

function MiniGameMgr:UpdateStamina(num)
	if not num then
		return
	end
	if num < 0 then
		TimeLimitPage.Reducestamina(-num)
	else
		TimeLimitPage.AddStamina(num)
	end
end

-- 初始化成单列模式
MiniGameMgr:InitSingleton():Init()
