--[[
Title: ParaWorldAnalytics
Author(s): DavidZhang, LiXizhi
Date: 2018/10/29
Desc: send user event every 30 seconds to google analytics in batch.
visit: https://analytics.google.com/ to see the result, using `dafuwangluo@gmail.com`

use the lib:
-------------------------------------------------------
ParaWorldAnalytics = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua");
-- send directly
ParaWorldAnalytics:Send("category", "action", 0, "labelTag")
ParaWorldAnalytics:Send("category", "action", 0, ParaWorldAnalytics:AppendDateToTag("user"))
-- send via user event filter
GameLogic.GetFilters():apply_filters("user_event_stat", "tool", "pick.62", 1, "tag");
-------------------------------------------------------
]]



------------------------------------------------------------------------------------------------------------------------
local GoogleAnalytics = NPL.load("GoogleAnalytics")
local ParaWorldAnalytics = commonlib.inherit()

function ParaWorldAnalytics:ctor()
end

function ParaWorldAnalytics:CheckLoadDate()
	if(self.installedDate) then
		return 
	end
	local startTime = ParaGlobal.GetDateFormat("yyyy-MM-dd").." "..ParaGlobal.GetTimeFormat("H-mm-ss")
	NPL.load("(gl)script/ide/DateTime.lua");
	local filename = "temp/ParaWorldAnalyticsInstalledDate.txt";
	local file = ParaIO.open(filename, "r")
	if(file:IsValid()) then
		self.installedDate = file:GetText()
		file:close()
	end
	if(not self.installedDate or not self.installedDate:match("^(%d+)%D(%d+)%D(%d+)")) then
		ParaIO.CreateDirectory(filename);
		file = ParaIO.open(filename, "w")
		self.installedDate = startTime
		file:WriteString(self.installedDate)
		file:close();
	end
	self.daysSinceInstalled = math.abs(commonlib.timehelp.GetDaysTweenDate(self.installedDate, startTime) or 0)
	LOG.std(nil, "info", "ParaWorldAnalytics", "installed date:%s,  %d days since last installed", self.installedDate, self:GetDaysSinceInstalled());
end

-- return 0 for initial installed user. 
function ParaWorldAnalytics:GetDaysSinceInstalled()
	if(not self.daysSinceInstalled) then
		self:CheckLoadDate();
		self.daysSinceInstalled = self.daysSinceInstalled or 0;
	end
	return self.daysSinceInstalled;
end

-- zero day is usually new user, we need to pay more attention
function ParaWorldAnalytics:IsDay0()
	return self:GetDaysSinceInstalled() == 0
end

function ParaWorldAnalytics:GetInstalledDate()
	if(not self.installedDate) then
		self:CheckLoadDate();
		self.installedDate = self.installedDate or "";
	end
	return self.installedDate;
end

-- return day0, day1, day2, day3,day4, day5, day6, week1, week2, week3, week4, month1, month2, ..., year1, ...
function ParaWorldAnalytics:AppendDateToTag(tag)
	local days = self:GetDaysSinceInstalled()
	local tagDate = "";
	if(days<7) then
		tagDate = "_day"..days;
	elseif(days<35) then
		tagDate = "_week"..math.floor(days/7);
	elseif(days<365) then
		tagDate = "_month"..math.floor(days/30);
	else
		tagDate = "_year"..math.floor(days/365);
	end
	return (tag or "")..tagDate;
end

function ParaWorldAnalytics:Init(UA)
	if(self.inited) then
		return
	end
	self.inited = true;
	self:CheckLoadDate();

	-- official ua number
	self.UA = UA or "UA-129101625-1"

	self.user_id = self:_user_id()
	self.client_id = self:_client_id()
	self.app_name = self:_app_name()
	self.app_version = System.options.ClientVersion
	self.api_rate = 4

	if(not GoogleAnalytics) then
		LOG.std(nil, "error", "ParaWorldAnalytics", "GoogleAnalytics npl_mod not found");
		return self;
	end

	self.analyticsClient = GoogleAnalytics:new():init(self.UA, self.user_id, self.client_id,
													  self.app_name, self.app_version, self.api_rate);
	
	LOG.std(nil, "info", "ParaWorldAnalytics", "analytics client initialized with UA, user_id, client_id, app_name, app_version, api_rate: %s %s %s %s %s %d",
			self.UA, self.user_id or "", self.client_id or "", self.app_name, self.app_version, self.api_rate);
	
	NPL.load("(gl)script/ide/debug.lua");
	if(GoogleAnalytics.LogCollector and commonlib.debug.SetNPLRuntimeErrorCallback) then
		ParaWorldAnalytics.logger = ParaWorldAnalytics.logger or GoogleAnalytics.LogCollector:new():init(nil, self.app_name);
		commonlib.debug.SetNPLRuntimeErrorCallback(ParaWorldAnalytics.OnNPLErrorCallBack)
		if(commonlib.debug.SetNPLRuntimeDebugTraceLevel) then
			commonlib.debug.SetNPLRuntimeDebugTraceLevel(5);
		end
		LOG.std(nil, "info", "ParaWorldAnalytics", "log server enabled: %s", self.logger.server_url or "");
	else
		LOG.std(nil, "warn", "ParaWorldAnalytics", "log collector client not found");
	end

	return self;
end

function ParaWorldAnalytics:_user_id()
	token = System.User.keepworktoken
	if not token then
		return nil
	end

	-- token format, xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx
	-- the middle part(seperated by .) is user info in base64 format
	base64_info = string.gsub(token, '[^.]*.([^.]*).[^.]*', '%1')

	-- padding '=' until info len reaches multiple of 4
	mod = string.len(base64_info) % 4
	if mod ~= 0 then
		mod = 4 - mod
	end
	base64_info = base64_info .. string.rep('=', mod)

	NPL.load("(gl)script/ide/System/Encoding/base64.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	-- user_json content like below
	-- "{\"username\":\"dreamanddead\",\"userId\":1234,\"exp\":1542093124}"
	json_info = Encoding.unbase64(base64_info)

	NPL.load("(gl)script/ide/Json.lua");
	user = commonlib.Json.Decode(json_info)

	if user and user.username then
		return user.username
	end
end

function ParaWorldAnalytics:_app_name()
	local name;
	if System.options.mc then
		name = "paracraft"
	elseif System.options.version == 'kids' then
		name = "haqi"
	elseif System.options.version == 'teen' then
		name = "haqi2"
	end

	if(System.options.isFromQQHall) then
		name = (name or "").."_QQHall"
	end
	local src_app = ParaEngine.GetAppCommandLineByParam("src_paraworldapp", "");
	if(src_app ~= "") then
		name = (name or "").." from "..src_app;
	end
	return name;
end

function ParaWorldAnalytics:_client_id()
	return commonlib.Encoding.PasswordEncodeWithMac("uid")
end


function ParaWorldAnalytics:GetAnalyticsClient()
	return self.analyticsClient;
end

function ParaWorldAnalytics:SendEvent(event)
    if(self:GetAnalyticsClient())then
        self:GetAnalyticsClient():SendEvent(event);
    end
end

-- @param category: string, which category that the event belongs
-- @param action: string, details about the event
-- @param value: nil or a number, how important this action is. 
-- @param label: string, additional tag or label of the action. if nil, we will add user with date
function ParaWorldAnalytics:Send(category, action, value, label)
	self:Init()

	if(not label) then
		label = self:AppendDateToTag("user");
	end

	return self:SendEvent({
		category = category,
		action = action,
		value = value,
		label = label,
	});
end

-- send runtime error log to our log service
function ParaWorldAnalytics:SendErrorLog(title, body)
	if(ParaWorldAnalytics.logger) then
		ParaWorldAnalytics.logger:collect("error", title, body)
	end
end

-- @param callback: function(errorMessage, stackInfo) end
function ParaWorldAnalytics.SetNPLErrorCallback(callback)
	ParaWorldAnalytics.errorCallback = callback;
end

function ParaWorldAnalytics.OnNPLErrorCallBack(errorMessage)
	log(errorMessage);
	local stackInfo;
	if(type(errorMessage) == "string") then
		local title;
		title, stackInfo = errorMessage:match("^([^\r\n]+)\r?\n(.*)$")
		if(stackInfo) then
			errorMessage = title;
		end
	end
	ParaWorldAnalytics:SendErrorLog(errorMessage, stackInfo);
	if(ParaWorldAnalytics.errorCallback) then
		ParaWorldAnalytics.errorCallback(errorMessage, stackInfo);
	end
end

-------------------------------------------------------------埋点时长实现 暂时存放-----------------------------------------------------------------------
----------------------------------------------------以下是waiter引用--------------------------------------------------------------------
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

function ParaWorldAnalytics:behaviorStateEnter(action , state , otherParam)
	--print("behaviorStateEnter",action , state , otherParam)
	local behaviorParamMap 	= self.behaviorParamMap 				
	if not behaviorParamMap[action] then 
		--print("ParaWorldAnalytics:behaviorStateEnter not exist action" , action)
		return
	end
	local nowTime 	= os.time()

	if action == 'editWorld' and (not otherParam) then
		return 
	elseif state == nil then

		return 
	end

	--需要根据不一样的行为判断
	--初始化的流程
	if action == 'editWorld' then
		if behaviorParamMap[action].state ~= 'enter' and state =='enter' then
			--print("ParaWorldAnalyticsbehaviorStateEnter editWorld11111111111111111")
			behaviorParamMap[action].beginTime 	= nowTime
			behaviorParamMap[action].state 	= 'enter'
			behaviorParamMap[action].timeCount 	= 0
			behaviorParamMap[action].worldId 	= otherParam
			return
		end
	else
		if behaviorParamMap[action].state == 'init' then
			--print("ParaWorldAnalytics behaviorStateEnter stayWorld11111111111111")
			behaviorParamMap[action].beginTime 	= nowTime
			behaviorParamMap[action].state 	= state
			behaviorParamMap[action].timeCount 	= 0
			return
		end
	end
	--进入存储流程

	if action == 'editWorld' then
		if behaviorParamMap[action].state == 'enter' and state == 'leave' then
			--print("ParaWorldAnalytics behaviorStateEnter editWorld222222222222222222222")
			self:checkSendData(action , otherParam , behaviorParamMap[action].beginTime )
			behaviorParamMap[action].beginTime 	= nowTime
			behaviorParamMap[action].state 	= 'inActive'
			behaviorParamMap[action].timeCount 	= 0
			behaviorParamMap[action].worldId 	= otherParam
		end
	else

		if behaviorParamMap[action].state == state then 
			--print("ParaWorldAnalytics:behaviorStateEnter state keep same " , action , state)
			return 
		end
		--print("behaviorStateEnter stayWorld22222222222222222222222222222")
		self:checkSendData(action , behaviorParamMap[action].state , behaviorParamMap[action].beginTime )
		behaviorParamMap[action].beginTime 	= nowTime
		local tempState 	= behaviorParamMap[action].state
		behaviorParamMap[action].state 	= state
		behaviorParamMap[action].timeCount 	= 0

		if action == 'stayWolrd' then
			self:behaviorStateEnter("editWorld" , "leave" , tempState)
		end
	end
end

function ParaWorldAnalytics:checkSendData( action , stateInfo ,beginTime  )
	local nowTime 	= os.time()
	local timeInterval 	= nowTime - beginTime
	if (nowTime - beginTime) < self.timeSaveLimit then -- 不足时间长度的抛弃
		return
	end
	self:sendBehaviorData(action , stateInfo , beginTime , nowTime)
end

function ParaWorldAnalytics:sendBehaviorData(action , stateInfo , beginTime , endTime )
	--生成数据包
	local unitInfo 	= {}
	unitInfo.userId 	= self.userId
	unitInfo.worldId 	= stateInfo --假如是世界id 就是留在世界的时间
	unitInfo.beginAt 	= beginTime
	unitInfo.endAt 		= endTime
	unitInfo.duration 	= endTime - beginTime
	unitInfo.traceId	= string.format("%s_%s_%s_%s" , unitInfo.userId , beginTime , action , stateInfo)

	if KeepworkServiceSession:IsSignedIn() then -- 是否是登录模式
		--print('ParaWorldAnalytics sendBehaviorData1111111111111111111111')
		for i,v in pairs(unitInfo) do
			--print(i,v)
		end
	    keepwork.burieddata.sendSingleBuriedData({
	        category 	= 'behavior',
	        action 		= action,
	        data 		= unitInfo
	    },function(err, msg, data)
	        commonlib.echo("==========burieddata");
	        commonlib.echo(err);
	        commonlib.echo(msg);
	        commonlib.echo(data,true);
	    end)
	else
		--print('ParaWorldAnalytics sendBehaviorData222222222222222222222222')
		--离线模式
		local keyName 	= string.format('paraData_%s' , action )

		local infoStr 				= GameLogic.GetPlayerController():LoadLocalData(keyName , self.defaultJasonInfo)
		local infoMap  				= commonlib.Json.Decode(infoStr)
		infoMap[unitInfo.beginAt] 	= unitInfo
		infoStr 					= commonlib.Json.Encode(infoMap)
		GameLogic.GetPlayerController():SaveLocalData(keyName , infoStr)
	end
end

function ParaWorldAnalytics:staticInit( ... )
	if self.firstInit then
		return 
	end
	self.firstInit 	= true
	local behaviorParamMap 	= {}
	behaviorParamMap.stayWolrd 	= {state  = 'init' , beginTime 	= -1 , timeCount = 0 }
	behaviorParamMap.editWorld 	= {state  = 'init' , beginTime 	= -1 , timeCount = 0 }
	self.behaviorParamMap 	= behaviorParamMap
	self.timeInterval 	= 5000 	-- 间隔两秒
	self.timeSaveLimit 	= 10 	-- 120秒
    if(Mod and Mod.WorldShare and Mod.WorldShare.Store)then
	    self.userId 	= Mod.WorldShare.Store:Get("user/userId")
    end
	self.defaultJasonInfo 	= commonlib.Json.Encode({});

	self:sendLastData()
	self:timerInit()
end

function ParaWorldAnalytics:sendLastData()	
	if System.options.isCodepku or not KeepworkServiceSession or not KeepworkServiceSession:IsSignedIn() then
		return 
	end
	local behaviorParamMap 	= self.behaviorParamMap
	for key , unit in pairs(behaviorParamMap) do
		local keyName 	= string.format('paraData_%s' , action )
		local infoStr 				= GameLogic.GetPlayerController():LoadLocalData(keyName , self.defaultJasonInfo)
		if infoStr ~= self.defaultJasonInfo then
			local infoMap  				= commonlib.Json.Decode(infoStr)
			self:sendDataSet(infoMap ,key)
		end
	end

end

--发送本地存储数据的方法
function ParaWorldAnalytics:sendDataSet( infoMap , action)
	local array 	= {}
	for i,v in pairs(infoMap) do
		local unit 	= {category = 'behavior' ,action = action , data = v}
		table.insert(array , unit)
	end

	if #array == 1 then
	    keepwork.burieddata.sendSingleBuriedData(arrays[1],function(err, msg, data)
	        commonlib.echo("==========burieddata");
	        commonlib.echo(err);
	        commonlib.echo(msg);
	        commonlib.echo(data,true);
	    end)
	else
	    keepwork.burieddata.sendBuriedData(arrays,function(err, msg, data)
	        commonlib.echo("==========burieddata");
	        commonlib.echo(err);
	        commonlib.echo(msg);
	        commonlib.echo(data,true);
	    end)
	end
	local keyName 	= string.format('paraData_%s' , action )
	GameLogic.GetPlayerController():SaveLocalData(keyName , self.defaultJasonInfo)
end

--存储本地的数据
function ParaWorldAnalytics:saveLastData(unit ,action , nowTime , otherParam )
	local keyName 	= string.format('paraData_%s' , action )
	local infoStr 				= GameLogic.GetPlayerController():LoadLocalData(keyName , self.defaultJasonInfo)
	local infoMap  				= commonlib.Json.Decode(infoStr)
	local unitInfo 				= {}
	unitInfo.userId 	= self.userId
	unitInfo.worldId 	= otherParam --假如是世界id 就是留在世界的时间
	unitInfo.beginAt 	= unit.beginTime
	unitInfo.endAt 		= nowTime
	unitInfo.duration 	= nowTime - unit.beginTime
	unitInfo.traceId	= string.format("%s_%s_%s_%s" , unitInfo.userId , unit.beginTime , action , stateInfo)
	unit.timeCount 		= 0
	infoMap[unitInfo.beginAt] 	= unitInfo
	infoStr 					= commonlib.Json.Encode(infoMap)
	GameLogic.GetPlayerController():SaveLocalData(keyName , infoStr)	
end

function ParaWorldAnalytics:timerInit()
	self.countTimer = self.countTimer or commonlib.Timer:new({callbackFunc = function()
		self:behaviorCallback();
	end})
	self.countTimer:Change(0 , self.timeInterval)
end

function ParaWorldAnalytics:behaviorCallback()
	local behaviorParamMap 	= self.behaviorParamMap
	local nowTime 			= os.time()
	--print("ParaWorldAnalytics behaviorCallback",nowTime)
	for key , unit in pairs(behaviorParamMap) do
		if unit.state ~= 'init' and unit.state ~= 'inActive' then
			unit.timeCount 	= unit.timeCount + self.timeInterval / 1000
			if unit.timeCount > 120 then
				if key == 'editWorld' then
					--print('ParaWorldAnalytics behaviorCallback editWorld')
					self:saveLastData(unit , key , nowTime , unit.worldId )
				else
					--print('ParaWorldAnalytics behaviorCallback stayworld')
					self:saveLastData(unit , key , nowTime , unit.state)
				end
				
			end
		end
	end
end

-- create a singleton
local singleton = NPL.export();
ParaWorldAnalytics:new(singleton);
