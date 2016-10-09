--[[
Title: testing resource store
Author(s): LiXizhi
Date: 2008/2/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_resource_store.lua");
test.test_GetFile()
test.test_ResourceStore()

%TESTCASE{"GetFile from Store", func="test.test_GetFile", input={"http://www.paraengine.com/images/index_12.png"}}%
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/factory.lua");
if(not test) then test ={} end

-- passed by LiXizhi 2008.2.27
function test.test_ResourceStore()
	-- test creat resource store
	log("Testing resource store. \n")
	local ls = Map3DSystem.localserver.CreateStore("MyStore");
	if(not ls) then
		log("error: failed creating local server resource store\n")
		return 
	else
		log("MyStore is opened\n")	
	end	
	
	local ls = Map3DSystem.localserver.CreateStore("AnotherStore");
	if(not ls) then
		log("error: failed creating local server resource store\n")
		return 
	else
		log("AnotherStore is opened\n")	
	end
	
	local WebCacheDB = Map3DSystem.localserver.WebCacheDB;
	
	-- test GetItem non-exist item
	local item = ls:GetItem("http://www.minixyz.com/anything.xml")
	if(not item) then
		log("test GetItem non-exist item passed\n")
	end
	
	-- test DeleteAll
	log("test DeleteAll \n")
	if(ls:DeleteAll()) then
		log("Passed\n")
	else	
		log("Failed\n")
	end
	
	-- test PutItem
	log("test PutItem \n")
	
	local item = {
		entry = WebCacheDB.EntryInfo:new({
			url = "http://www.minixyz.com/image.jpg",
		}),
		payload = WebCacheDB.PayloadInfo:new({
			status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
			cached_filepath = "temp/image.jpg,v",
		}),
	}
	local res = ls:PutItem(item) 
	if(res) then log("test passed \n")	else	log("test FAILED \n")	end
	
	-- test overwrite item
	item.payload.cached_filepath = "temp/imageChanged.jpg,v"
	local res = ls:PutItem(item) 
	if(res) then log("test passed \n")	else	log("test FAILED \n")	end
	
	-- test rename
	log("Test rename \n")
	if(ls:Rename(item.entry.url, item.entry.url..".Renamed")) then 	log("passed\n") else log("FAILED\n") end
	
	
	-- test GetItem exist item
	log("test get exist item\n")
	local item = ls:GetItem(item.entry.url..".Renamed")
	if(item) then
		log(commonlib.serialize(item))
	else
		log("FAILED\n")	
	end
	
	-- test PutItem
	log("Test Delete entry:\n")
	if(ls:Delete(item.entry.url)) then
		log(" passed\n")
	else
		log(" FAILED\n")	
	end
	
end

-- passed by LiXizhi 2008.3.3
function test.test_GetFile(input)
	-- test_WebserviceStore
	log("testing ResourceStore\n")
	
	local ls = Map3DSystem.localserver.CreateStore("rs", 1);
	if(not ls) then
		log("error: failed creating local server ResourceStore \n")
		return 
	else
		log("web service store: rs is opened\n")	
	end	
	
	-- clear all. 
	--ls:DeleteAll();
	
	-- testing  get file
	log("testing ResourceStore:GetFile \n") 
	for i=1,2 do
		ls:GetFile(Map3DSystem.localserver.CachePolicy:new("access plus 1 hour"),
			input or "http://www.paraengine.com/images/index_12.png", 
			function (entry)
				log("SUCCEED: resource store\n entry = "..commonlib.serialize(entry));
			end
		);
	end	
end

-- passed by LiXizhi 2008.3.27
-- %TESTCASE{"PutItem", func="test.PutItem", input={data="anystring",url = "http://paraengine.com/test"}}%
function test.PutItem(input)
	input = input or {};
	input.url = input.url or "http://paraengine.com/test"
	input.data = input.data or string.format("A\r\nA")
	
	local ls = Map3DSystem.localserver.CreateStore(nil, 2);
	if(not ls) then
		log("error: failed creating local server web service store\n")
		return 
	else
		log("web service store: ws is opened\n")	
	end
	local WebCacheDB = Map3DSystem.localserver.WebCacheDB;
	
	-- test PutItem
	log("test PutItem: "..input.data.."\n")
	
	local item = {
		entry = WebCacheDB.EntryInfo:new({
			url = input.url,
		}),
		payload = WebCacheDB.PayloadInfo:new({
			status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
			data = input.data,
		}),
	}
	local res = ls:PutItem(item) 
	if(res) then log("test passed \n")	else	log("test FAILED \n")	end
end

-- passed by LiXizhi 2008.3.27
-- %TESTCASE{"GetItem", func="test.GetItem", input={url = "http://paraengine.com/test"}}%
function test.GetItem(input)
	input = input or {};
	input.url = input.url or "http://paraengine.com/test"
	
	local ls = Map3DSystem.localserver.CreateStore(nil, 2);
	if(not ls) then
		log("error: failed creating local server web service store\n")
		return 
	else
		log("web service store: ws is opened\n")	
	end
	local item = ls:GetItem(input.url)
	if(item) then
		log(commonlib.serialize(item))
		if(item.payload.data == string.format("A\r\nA")) then
			log("OK")
		else	
			log("wrong")
		end
	else
		log("FAILED\n")	
	end
end

test.PutItem({data=string.format("%q", string.format("A\r\nA")),url = "http://paraengine.com/test2"})