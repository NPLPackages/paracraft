--[[
Title:
Author(s): Leio
Date: 2009/10/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.background_loader.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.background_loader", {});

local background_loader_cache_policy = System.localserver.CachePolicies["access plus 1 sec"];
paraworld.CreateHttpWrapper("paraworld.background_loader.GetList", "%ASSETSTATS%/userdownload.list",

function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	local cache_policy = msg.cache_policy or background_loader_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3, "background_loader");
	if(not ls) then
		return;
	end
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			HasResult = true;
			-- make output msg
			local output_msg = item.payload.data;
			if(output_msg) then
				if(callbackFunc) then
					callbackFunc({data = output_msg}, callbackParams)
				end
				commonlib.echo("unexpired local backgound download list is used");
				return true;
			end
			
		end
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table" and msg.data) then
		local ls = System.localserver.CreateStore(nil, 3, "background_loader");
		if(ls) then
			-- make entry
			local url = self.GetUrl();
			local output_msg = msg.data;
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = output_msg,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				commonlib.log("background download list of %s saved to local server\n", tostring(url));
			else	
				commonlib.log("warning: failed backgound download list of of %s to local server\n", tostring(url))
				commonlib.log(output_msg);
			end
		end
	end
end
);