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
	if System.options.mc then
		return "paracraft"
	end

	if System.options.version == 'kids' then
		return "haqi"
	end

	if System.options.version == 'teen' then
		return "haqi2"
	end
end

function ParaWorldAnalytics:_client_id()
	return commonlib.Encoding.PasswordEncodeWithMac("uid")
end


function ParaWorldAnalytics:GetAnalyticsClient()
	return self.analyticsClient;
end

function ParaWorldAnalytics:SendEvent(event)
	self:GetAnalyticsClient():SendEvent(event);
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

-- create a singleton
local singleton = NPL.export();
ParaWorldAnalytics:new(singleton);
