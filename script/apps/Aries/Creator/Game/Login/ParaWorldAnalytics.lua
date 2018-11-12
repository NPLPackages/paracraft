--[[
	Title: ParaWorldAnalytics
	Author(s): LiXizhi
	Date: 2018/10/29
	Desc: send user event every 30 seconds to google analytics in batch.

	use the lib:
	-------------------------------------------------------
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua");
	local ParaWorldAnalytics = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldAnalytics")
	ParaWorldAnalytics:new():Init()
	-------------------------------------------------------
]]
local GoogleAnalytics = NPL.load("GoogleAnalytics")
local ParaWorldAnalytics = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldAnalytics"))

-- send events in batch every 5 seconds if pool is not empty.
ParaWorldAnalytics.SendInterval= 5000;

function ParaWorldAnalytics:ctor()
	self.event_pool = {};
end


function ParaWorldAnalytics:Init(UA)
	-- official ua number
	self.UA = UA or "UA-129101625-1"

	self.user_id = self._user_id()
	self.client_id = self._client_id()
	self.app_name = self._app_name()
	self.app_version = System.options.ClientVersion

	self.analyticsClient = GoogleAnalytics:new():init(self.UA, self.user_id, self.client_id, self.app_name, self.app_version);

	-- category: which category that the event belongs
	-- action: which kind of action that the event do
	-- value: what exactly the action does
	-- label: more details about action
	GameLogic:GetFilters():add_filter("user_event_stat", function(category, action, value, label)
										  self:GatherEvent({
												  category = category,
												  action = action,
												  value = value,
												  label = label,
										  });
										  return catetory;
									 end)

	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
										  self:SendBatchEvents()
									end})
	self.timer:Change(self.SendInterval, self.SendInterval);

	LOG.std(nil, "info", "ParaWorldAnalytics", "analytics client initialized with UA, user_id, client_id, app_name, app_version: %s %s %s %s %s",
			self.UA, self.user_id, self.client_id, self.app_name, self.app_version);
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


function ParaWorldAnalytics:GatherEvent(event)
	self.event_pool[#self.event_pool+1] = event;
end

function ParaWorldAnalytics:SendBatchEvents()
	if next(self.event_pool) == nil then
		return
	end

	for i, event in pairs(self.event_pool) do
		self:SendEvent(event);
	end

	self.event_pool = {};
end

function ParaWorldAnalytics:GetAnalyticsClient()
	return self.analyticsClient;
end

function ParaWorldAnalytics:SendEvent(event)
	self:GetAnalyticsClient():SendEvent(event);
end
