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

local api_host = "http://api-dev.kp-para.cn"

function HttpWrapper.Create(fullname, url, method, prepFunc, postFunc)
    if(not fullname or not url)then
        return 
    end
    url = string.gsub(url,"%%MAIN%%",api_host);
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
        if(not res)then
            inputParams = inputParams or {};
            local raw_input = commonlib.deepcopy(inputParams);
            local input;
            if(method == "POST")then
                input = {};
                input.url = url;
                input.method = method;
                input.form = raw_input;
            else
                input = raw_input;
                input.url = url;
                input.method = method;
            end
            if(input.json == nil)then
                input.json = true
            end
		    LOG.std("", "debug","HttpWrapper", "request from: %s", url);
            System.os.GetUrl(input, function(err, msg, data)
                if(callbackFunc)then
                    callbackFunc(err, msg, data);
                end
                if(postFunc)then
                    postFunc(self, err, msg, data);
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
