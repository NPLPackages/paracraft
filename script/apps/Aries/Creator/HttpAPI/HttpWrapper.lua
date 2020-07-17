--[[
Title: HttpWrapper
Author(s): leio
Date: 2020/4/22
Desc:  
Use Lib:
-------------------------------------------------------
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

NOTE: 
config cmd line param "Config.defaultEnv" to load different development env
local httpwrapper_version = ParaEngine.GetAppCommandLineByParam("httpwrapper_version", "ONLINE");  - "ONLINE" or "STAGE" or "RELEASE" or "LOCAL"
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
local UrlConverter = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/UrlConverter.lua");

local HttpWrapper = NPL.export()


HttpWrapper.keepworkServerList = {
    ONLINE = "https://api.keepwork.com",
    STAGE = "http://api-dev.kp-para.cn",
    RELEASE = "http://api-rls.kp-para.cn",
    LOCAL = "http://api-dev.kp-para.cn",
}
HttpWrapper.api_host = nil;
-- get version for load different development env
-- return 
-- "ONLINE" or 
-- "STAGE" or 
-- "RELEASE" or 
-- "LOCAL" or 
function HttpWrapper.GetDevVersion()
    local httpwrapper_version = ParaEngine.GetAppCommandLineByParam("httpwrapper_version", "ONLINE");
    httpwrapper_version = string.upper(httpwrapper_version);
    return httpwrapper_version;
end
function HttpWrapper.GetUrl(key)
    key = key or "keepworkServerList";
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local url;
    local url  = HttpWrapper[key][httpwrapper_version];
    if(not url)then
	    LOG.std(nil, "error", "HttpWrapper", "read url failed key = '%s' , httpwrapper_version = '%s'", key, httpwrapper_version);
    else
	    LOG.std(nil, "info", "HttpWrapper", "read url %s by key = '%s' , defaultEnv = '%s'", url, key, httpwrapper_version);
    end
    return url;
end
-- depends on https://github.com/tatfook/WorldShare/blob/master/Mod/WorldShare/store/UserStore.lua#L32
function HttpWrapper.GetToken()
    local token = commonlib.getfield("System.User.keepworktoken")
    return token;
end
local default_cache_policy = System.localserver.CachePolicy:new("access plus 1 hour");

-- create url for caching
function HttpWrapper.get_default_cache_url(self)
    if(not self)then
        return
    end
    local url_queries = { "method", self.method };
    if(self.tokenRequired)then
        local username = commonlib.getfield("System.User.username")
        if(username)then
            table.insert(url_queries,"localserver_username");
            table.insert(url_queries,username);
        end
    end
	local url = NPL.EncodeURLQuery(self.GetUrl(), url_queries)
    return url;
end
function HttpWrapper.default_prepFunc(self, inputParams, callbackFunc, option)
    cache_policy = inputParams.cache_policy or default_cache_policy;
    if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end

    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make url
	local url = HttpWrapper.get_default_cache_url(self);
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- make output msg
			local output_msg = commonlib.LoadTableFromString(item.payload.data);
            local fullname = self.fullname or "";
		    LOG.std("", "info",fullname, "loaded from local server: %s", url);
			if(callbackFunc) then
				callbackFunc(200, {}, output_msg);
			end	
            return true;
		end
	end
end
function HttpWrapper.default_postFunc(self, err, msg, data)
    if(not err or err ~= 200)then
        return
    end
    local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
    -- make output msg
	local output_msg = data;

    -- make url
	local url = HttpWrapper.get_default_cache_url(self);
   -- make entry
	local item = {
		entry = System.localserver.WebCacheDB.EntryInfo:new({url = url,}),
		payload = System.localserver.WebCacheDB.PayloadInfo:new({
			status_code = System.localserver.HttpConstants.HTTP_OK,
			data = (output_msg),
		}),
	}
    local fullname = self.fullname or "";
	-- save to database entry
	local res = ls:PutItem(item) 
    if(res) then 
		LOG.std("", "info",fullname, "%s saved to local server", url);
        return true;
	else	
		LOG.std("", "warning",fullname, LOG.tostring("warning: failed saving to local server %s \n", tostring(url))..LOG.tostring(output_msg));
	end
end
-- NOTE: only cache method == "GET"
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
    local keyword_params = {
        ["cache_policy"] = true,
        ["headers"] = true,
        ["router_params"] = true,
    }
    local function activate(self, inputParams, callbackFunc, option)
        inputParams = inputParams or {};

        if(inputParams.router_params)then
             url = UrlConverter.ToPath(url,inputParams.router_params)
        end
        local res;
        -- only cache method == "GET"
        if(method == "GET" and prepFunc)then
			res = prepFunc(self, inputParams, callbackFunc, option);
        end
        
        if(not res)then
            local raw_input = commonlib.deepcopy(inputParams);
            local input;
            if(method == "GET")then
                input = raw_input;
                local url_queries = {}
                for k,v in pairs(raw_input) do
                    -- remove keywords
                    if(not keyword_params[k])then
                        table.insert(url_queries,k);
                        table.insert(url_queries,v);
                    end
                end
	            local input_url = NPL.EncodeURLQuery(url, url_queries);
                input.url = input_url;
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
		    LOG.std(nil, "debug","HttpWrapper input", input);
            System.os.GetUrl(input, function(err, msg, data)
                -- only cache method == "GET"
                if(method == "GET" and postFunc)then
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
        fullname = fullname,
        method = method,
        tokenRequired = tokenRequired,
	}, {
		__call = activate,
		__tostring = function(self)
            return string.format("%s:(%s)(%s)",fullname,url,method);
		end
	});
	commonlib.setfield(fullname, o);
end
