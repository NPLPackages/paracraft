--[[
Title: testing web service store
Author(s): LiXizhi
Date: 2008/3/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_webservice_store.lua");
test.test_callXML()
test.test_WebserviceStore()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/factory.lua");

if(not test) then test ={} end

-- passed by LiXizhi 2008.3.3
function test.test_WebserviceStore()
	-- test_WebserviceStore
	log("testing WebserviceStore\n")
	
	local ls = Map3DSystem.localserver.CreateStore("ws", 2);
	if(not ls) then
		log("error: failed creating local server web service store\n")
		return 
	else
		log("web service store: ws is opened\n")	
	end	
	
	-- testing  CallWebserviceEx
	log("testing WebserviceStore:CallWebserviceEx duplicates 2X\n") 
	for i=1,2 do
		ls:CallWebserviceEx(Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
			"http://www.kids3dmovie.com/CheckVersion.asmx", 
			-- msg
			{aaa="bbb"},
			{"aaa"},
			function (msg)
				log("SUCCEED: web service store\n msg = "..commonlib.serialize(msg));
			end
		);
	end	
	
	-- test never cache
	log("testing UNCACHED WebserviceStore:CallWebserviceEx \n") 
	ls:CallWebserviceEx(Map3DSystem.localserver.CachePolicy:new("access plus 0"),
			"http://www.kids3dmovie.com/CheckVersion.asmx", 
			-- msg
			{aaa="bbb"},
			{"aaa"},
			function (msg)
				log("SUCCEED: web service store\n msg = "..commonlib.serialize(msg));
			end
		);
end

-- passed by LiXizhi 2008.3.9
-- %TESTCASE{"get HTML page", func="test.test_callXML", input={cache_policy = "access plus 10 minute",url = "http://wiki/twiki/bin/view/Main/LoginApp"}}%
function test.test_callXML(input)
	local ls = Map3DSystem.localserver.CreateStore(nil, 2);
	if(not ls) then
		log("error: failed creating local server web service store\n")
		return 
	else
		log("web service store: ws is opened\n")	
	end
	if(not input) then
		input = {cache_policy = "access plus 10 minute",url = "http://wiki/twiki/bin/view/Main/LoginApp"}
	end
	ls:CallXML(Map3DSystem.localserver.CachePolicy:new(input.cache_policy or "access plus 10 minute"), input.url, function (xmlRoot, entry)
		log("HTML page retrieved\n")
		commonlib.log(entry)
	end)
	
	--ls:GetFile(Map3DSystem.localserver.CachePolicy:new("access plus 2 minute"), "http://www.paraengine.com/en/business.html", function (entry)
		--commonlib.log(entry)
		--log("Last modified: "..entry.payload:GetHeader(Map3DSystem.localserver.HttpConstants.kLastModifiedHeader))
		--log("Content length: "..entry.payload:GetHeader(Map3DSystem.localserver.HttpConstants.kContentLengthHeader))
	--end)
end


-- passed by LiXizhi 2008.12.13
-- %TESTCASE{"test.localserver_GetURL", func="test.localserver_GetURL", input={cache_policy = "access plus 1 minute",url = "http://www.paraengine.com"}}%
function test.localserver_GetURL(input)
	NPL.load("(gl)script/kids/3DMapSystemApp/localserver/URLResourceStore.lua");

	local ls = Map3DSystem.localserver.CreateStore(nil, 3);
	if(ls) then
		ls:GetURL(input.cache_policy or Map3DSystem.localserver.CachePolicy:new("access plus 1 day"),
			input.url or "http://www.paraengine.com", commonlib.echo, "SecondUserParam"
		);
	else
		log("error: unable to open default local server store \n");
	end
end
