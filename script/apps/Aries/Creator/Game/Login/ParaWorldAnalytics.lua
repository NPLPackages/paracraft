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
local ParaWorldAnalyticss = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldAnalyticss")

local ParaWorldAnalytics = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.MainLogin.ParaWorldAnalytics"))

-- send events in batch every 10 seconds if queue is not empty. 
ParaWorldAnalytics.SendInterval= 10000;

function ParaWorldAnalytics:ctor()
	self.finishedQuizCount = 0;
	self.clientData = {};
	self.event_pool = {};

	
end

-- @param UA: 
function ParaWorldAnalytics:Init(UA)
	self.UA = UA or "UA-127983943-1" -- your ua number

	self.googleAnalitics = GoogleAnalytics:new():init(UA);

	self.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		self:OnTimer();
	end})
	self.mytimer:Change(self.SendInterval, self.SendInterval);

	GameLogic.GetFilters():add_filter("user_event_stat", function(key, ...) 
		self:SendEvent({
			location = key, 
			language = 'zh-CN',
			category = 'test',
			action = 'create',
			label = 'keepwork',
			value = 123
		});
		return key;
	end)

	LOG.std(nil, "info", "ParaWorldAnalytics", "google analytics initialized with user agent: %s", self.UA);
	return self;
end

function ParaWorldAnalytics:GetGoogleClient()
	return self.googleAnalitics
end

function ParaWorldAnalytics:OnTimer()
	-- TODO :  self.event_pool;
end

--local options = {
--    location = 'www.keepwork.com/lesson',
--    language = 'zh-CN',
--    category = 'test',
--    action = 'create',
--    label = 'keepwork',
--    value = 123
--}
function ParaWorldAnalytics:SendEvent(options)
	-- TODO add to pool and send in batch. 
	-- self.event_pool[#self.event_pool+1] = options;

	LOG.std(nil, "debug", "ParaWorldAnalytics_sendEvent", options);
	self:GetGoogleClient():send_event(options);
end