--[[
Title: HttpWrapper
Author(s): leio
Date: 2020/4/22
Desc:  
Use Lib:
-------------------------------------------------------
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");

local HttpWrapper = NPL.export()


HttpWrapper.keepworkServerList = {
    ONLINE = "https://api.keepwork.com",
    STAGE = "http://api-dev.kp-para.cn",
    RELEASE = "http://api-rls.kp-para.cn",
    LOCAL = "http://api-dev.kp-para.cn",
}
HttpWrapper.api_host = nil;
function HttpWrapper.GetUrl(key)
    key = key or "keepworkServerList";
    local url;
    local Config = NPL.load("./Config.lua")
    local defaultEnv;
    if(Config and Config.defaultEnv)then
        defaultEnv = Config.defaultEnv;
        url  = HttpWrapper[key][defaultEnv];
    end
    if(not url)then
	    LOG.std(nil, "error", "HttpWrapper", "read url failed key = '%s' , defaultEnv = '%s'", key, defaultEnv);
    else
	    LOG.std(nil, "info", "HttpWrapper", "read url %s by key = '%s' , defaultEnv = '%s'", url, key, defaultEnv);
    end
    return url;
end

function HttpWrapper.SetToken(token)
    local User = commonlib.gettable('System.User');
    System.User.keepworktoken = token;
end
-- depends on https://github.com/tatfook/WorldShare/blob/master/Mod/WorldShare/store/UserStore.lua#L32
function HttpWrapper.GetToken()
    local User = commonlib.gettable('System.User');
    local token = System.User.keepworktoken;
    return token;
end
local default_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");

function HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option, fullname)
    cache_policy = inputParams.cache_policy or default_cache_policy;
    if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end

    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), { "method", self.method})
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
		    LOG.std("", "info",fullname, "loaded %s from local server", url);
			if(callbackFunc) then
				callbackFunc(200, {}, output_msg);
			end	
            return true;
		end
	end
end
function HttpWrapper.default_postFunc(self, err, msg, data, fullname, callbackFunc)
    if(not err or err ~= 200)then
        if(callbackFunc)then
            callbackFunc(err, msg, data);
        end
        return
    end
    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make output msg
	local output_msg = data;

    -- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), { "method", self.method})
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
		LOG.std("", "info",fullname, "%s saved to local server", url);
	else	
		LOG.std("", "warning",fullname, LOG.tostring("warning: failed saving %s to local server\n", tostring(url))..LOG.tostring(output_msg));
	end
end
function HttpWrapper.Create(fullname, url, method, tokenRequired, configs, prepFunc, postFunc)
    if(not fullname or not url)then
        return 
    end
    if(not HttpWrapper.api_host)then
        HttpWrapper.api_host = HttpWrapper.GetUrl();
    end
    url = string.gsub(url,"%%MAIN%%",HttpWrapper.api_host);
    -- for more config
    configs = configs or {};
    method = method or "GET"
    method = string.upper(method);
    local o = commonlib.getfield(fullname);
	if(o ~= nil) then 
		-- return if we already created it before.
		LOG.std(nil, "warn","HttpWrapper", "The "..fullname.." is overriden by HttpWrapper.Create\n Remove duplicate calls with the same name.");
	end
    local function activate(self, inputParams, callbackFunc, option)
        local res;
        if(prepFunc)then
			res = prepFunc(self, inputParams, callbackFunc, option);
        end
        commonlib.echo("=========res");
        commonlib.echo(res);
        if(not res)then
            inputParams = inputParams or {};
            local raw_input = commonlib.deepcopy(inputParams);
            local input;
            if(method == "GET")then
                input = raw_input;
                input.url = url;
                input.method = method;
            else
                input = {};
                input.url = url;
                input.method = method;
                input.form = raw_input;
            end
            if(input.json == nil)then
                input.json = true
            end
            local headers = raw_input.headers or {};
            if(tokenRequired)then
                headers["Authorization"] = string.format("Bearer %s",HttpWrapper.GetToken());
            end
            input.headers = headers;
            commonlib.echo("=========input");
            commonlib.echo(url);
            commonlib.echo(input);
		    LOG.std(nil, "info","HttpWrapper", "request from: %s", url);
            System.os.GetUrl(input, function(err, msg, data)
                if(postFunc)then
                    postFunc(self, err, msg, data);
                end
                if(callbackFunc)then
                    callbackFunc(err, msg, data);
                end
            end, option)
        end
	end
    o = setmetatable({
		GetUrl = function() return url end,
        method = method,
	}, {
		__call = activate,
		__tostring = function(self)
            return string.format("%s:(%s)(%s)",fullname,url,method);
		end
	});
	commonlib.setfield(fullname, o);
end
