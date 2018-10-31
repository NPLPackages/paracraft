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
	-- FIXME UA-93899485-3 is a test account
	self.UA = UA or "UA-93899485-3"
	-- TODO user_id, fetch the login username, such as keepwork username
	self.user_id = nil
	self.client_id = self.GetClientId()
	self.analyticsClient = GoogleAnalytics:new():init(self.UA, self.user_id, self.client_id);

	-- category: which category that the event belongs
	-- action: which kind of action that the event do
	-- value: what exactly the action does
	GameLogic:GetFilters():add_filter("user_event_stat", function(category, action, value, ...)
										  self:GatherEvent({
												  category = category,
												  action = action,
												  value = value,
												  label = 'paracraft',
										  });
										  return catetory;
									 end)

	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
										  self:SendBatchEvents()
									end})
	self.timer:Change(self.SendInterval, self.SendInterval);

	LOG.std(nil, "info", "ParaWorldAnalytics", "analytics client initialized with UA, user_id, client_id: %s %s %s", self.UA, self.user_id, self.client_id);
	return self;
end

function ParaWorldAnalytics:GetClientId()
	-- try UUID first, then cpu id
	if (System.os.GetPlatform()=="win32") then
		-- FIXME os.run(cmd) brings a flashing terminal window before launching
		-- it's better substitude with a npl method
		uuid = System.os.run('wmic csproduct get UUID'):gsub("^UUID%s*(.-)%s*$", "%1")
		if not uuid:match("^[F-]*$") then
			return uuid
		end

		cpu_id = System.os.run('wmic cpu get ProcessorId'):gsub("^ProcessorId%s*(.-)%s*$", "%1")
		return cpu_id
	end
	-- TODO support other os
	return nil
end


function ParaWorldAnalytics:GatherEvent(event)
	self.event_pool[#self.event_pool+1] = event;
end

function ParaWorldAnalytics:SendBatchEvents()
	if next(self.event_pool) == nil then
		return
	end

	-- WARNING
	-- event gathering and sending are async,
	-- that will cause inconsistency unless running in single thread mode.

	-- TODO maybe we need an api rate limiter in future
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
