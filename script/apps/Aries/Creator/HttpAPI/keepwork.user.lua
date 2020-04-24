--[[
Title: keepwork.user
Author(s): leio
Date: 2020/4/23
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua");
]]
NPL.load("(gl)script/ide/System/localserver/localserver.lua");

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

local getInfo_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");

--http://yapi.kp-para.cn/project/32/interface/api/cat_97
HttpWrapper.Create("keepwork.user.login", "%MAIN%/core/v0/users/login", "POST",
-- PreProcessor
function(self, inputParams, callbackFunc, option)
    -- Is this unique?
    local username = inputParams.username;
    if(not username)then
		LOG.std("", "error","keepwork.user.login", "username is required!");
        return
    end
    cache_policy = inputParams.cache_policy or getInfo_cache_policy;
    if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end

    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"username", username, "method", self.method})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
		    LOG.std("", "info","keepwork.user.login", "loaded user info of %s from local server", url);
			if(callbackFunc) then
				callbackFunc(200, {}, output_msg);
			end	
            return true;
		end
	end
end,
-- Post Processor
function(self, err, msg, data)
    if(not err or err ~= 200)then
        if(callbackFunc)then
            callbackFunc(err, msg, data);
        end
        return
    end
    local user_info = data;
    local username = user_info.username;
     if(not username)then
		LOG.std("", "error","keepwork.user.login", "username is required!");
        return
    end

    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make output msg
	local output_msg = user_info;
    -- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"username", username, "method", self.method})
   -- make entry
	local item = {
		entry = System.localserver.WebCacheDB.EntryInfo:new({url = url,}),
		payload = System.localserver.WebCacheDB.PayloadInfo:new({
			status_code = System.localserver.HttpConstants.HTTP_OK,
			data = (output_msg),
		}),
	}
	-- save to database entry
	local res = ls:PutItem(item) 
    if(res) then 
		LOG.std("", "info","keepwork.user.login", "User info of %s saved to local server", url);
	else	
		LOG.std("", "warning","keepwork.user.login", LOG.tostring("warning: failed saving user info of %s to local server\n", tostring(url))..LOG.tostring(output_msg));
	end
end)
