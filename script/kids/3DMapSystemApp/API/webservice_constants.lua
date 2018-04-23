--[[
Title: constants used by web services, such as return values
Author(s): LiXizhi
Date: 2008/1/21
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/webservice_constants.lua");
log(paraworld.TranslateURL("%MAIN%/CheckvVersion.asmx"))
-------------------------------------------------------
]]
-- create class
if(not paraworld) then paraworld = {} end

-- url that contains the left part in the mapping will be replaced by the right part. 
-- _note_: EDIT THIS TO CHANGE SERVER

NPL.load("(gl)script/ide/rulemapping.lua");
local urlMapping = CommonCtrl.rulemapping:new({
	-- an optional regular expression. If this is present, the value must match this test string, in order for any output replaceables to be applied. 
	replaceables_test = "%%",

	replaceables_replace = {
		{name="%%domain%%", value="test.pala5.cn"},
		--{name="%%domain%%", value="pala5.com"},
	},
	-- output path replaceables, multiples replaceables may appear in the same output
	replaceables = {
		-- post log
		["%%LOG%%"] = "http://192.168.0.51:84",
		-- common
		["%%MAIN%%"] = "http://api.%%domain%%",
		["%%AUTH%%"] = "http://api.%%domain%%",
		["%%MAP%%"] = "http://map.%%domain%%/",
		["%%EMAIL%%"] = "http://email.%%domain%%/",
		["%%INVENTORY%%"] = "http://api.%%domain%%:85/",
		["%%PROFILE%%"] = "http://api.%%domain%%",
		["%%APP%%"] = "http://appdir.%%domain%%",
		["%%FILE%%"] = "http://files.%%domain%%",
		["%%MQL%%"] = "http://api.%%domain%%/MQL",
		--["%%ACTIONFEED%%"] = "http://api.%%domain%%/ActionFeed",
		["%%ACTIONFEED%%"] = "http://api.%%domain%%/API/ActionFeed",
		["%%LOBBY%%"] = "http://lobby.%%domain%%",
		-- wiki root path: e.g. "%WIKI%/Main/ParaWorldFrontPageMCML"
		["%%WIKI%%"] = "http://pedn.paraengine.com/twiki/bin/view",
		-- chat domain
		["%%CHATDOMAIN%%"] = "%%domain%%",
		-- asset stats domain 
		["%%ASSETSTATS%%"] = "http://tm.assetupdate.pala5.cn:81",
	},
	
	-- an optional regular expression. If this is present, the input must match this test string, in order for any general rules to be applied. 
	general_test = nil,
	
	-- general rules are evaluated in the order given below
	general = nil,
	
	-- special rules are strict mapping using hash find.
	special = nil,
})

-- change the domain replaceables.  
-- @param input: a table of name value pairs. {domain="test.pala5.cn", chatdomain="pala5.cn"}, 
-- known fields are domain, chatdomain, logserver
function paraworld.ChangeDomain(input)
	if(input.domain) then
		local _, v 
		for _,v in ipairs(urlMapping.replaceables_replace) do
			if(v.name == "%%domain%%") then
				if(v.value~=input.domain) then
					v.value = input.domain;
					commonlib.log("domain reset: %s\n", input.domain);
				end	
			end	
		end
	end
	if(input.chatdomain) then
		urlMapping.replaceables["%%CHATDOMAIN%%"] = input.chatdomain;
	end
	if(input.logserver) then
		urlMapping.replaceables["%%LOG%%"] = input.logserver;
	end
	if(input.fileserver) then
		urlMapping.replaceables["%%FILE%%"] = input.fileserver;
	end
	if(input.asset_stats) then
		urlMapping.replaceables["%%ASSETSTATS%%"] = input.asset_stats;
	end	
end
-- get the domain name in rulemapping replaceables.
-- @return: current domain set to the rulemapping
function paraworld.GetDomain()
	local _, v 
	for _,v in ipairs(urlMapping.replaceables_replace) do
		if(v.name == "%%domain%%") then
			return v.value;
		end	
	end
end

-- tranlation url containing paraworld.URL_parameters
-- e.g. paraworld.TranslateURL("%MAIN%/CheckvVersion.asmx") will return the full url 
-- by replacing %MAIN% with the one defined in paraworld.URL_parameters
-- @return url.
function paraworld.TranslateURL(url)
	return urlMapping(url, true);	
end

-- various error code of paraworld api. 
paraworld.errorcode = {
	----------------------------------------
	-- general service error (1-100)
	----------------------------------------
	-- An unknown error occurred. Please try again later
	unknown = nil, 
	-- The service is not available at this time. 
	ServiceNotAvailable = 1,
	-- The application has reached the maximum number of requests allowed. More requests are allowed once the time window has completed. 
	MaxAppRequestsReached = 2,
	-- returned when calling the same RPC twice with the same id, if the previous one does not response. 
	RepeatCall = 3,	
	-- RPC times out. server does not respond
	Timeout = 4,
	-- general access denied 
	AccessDenied = 5,
	-- The request came from a remote address not allowed by this application.
	IPDenied = 6,
	-- The api key submitted is not associated with any known application. 
	Unknownappkey = 7,
	-- The user is not logged in, should direct user to login page
	LoginRequired = 8,
	
	----------------------------------------
	-- general validation error (100-200)
	----------------------------------------
	-- One of the parameters specified was missing or invalid. 
	InvalidParameters = 100,
	-- The session key was improperly submitted or has reached its timeout. Direct the user to log in again to obtain another key. 
	Invalidsessionkey = 101,
	-- The submitted call_id was not greater than the previous call_id for this session.
	InvalidCall_id = 102,
	-- Incorrect signature. (md5 sig is wrong)
	InvalidSig = 103,
	
	----------------------------------------
	-- per RPC error (400-500)
	----------------------------------------
	-- if value is larger than 400, it is a per RPC specific error message. one needs to check the declaration of each RPC for exact meaning. 
	PerCallError = 400,
};
