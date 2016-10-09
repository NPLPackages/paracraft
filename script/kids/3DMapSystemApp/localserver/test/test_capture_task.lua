--[[
Title: testing capture tast
Author(s): LiXizhi
Date: 2008/3/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_capture_task.lua");
test.test_WS_CaptureTask()
test.test_WS_duplicateCall()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/factory.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/capture_task.lua");

if(not test) then test ={} end

-- passed by LiXizhi 2008.3.3:
-- Note: web service sometimes failed when calling the same one multiple times at once. 
function test.test_WS_CaptureTask()
	-- Testing web service using capture task. 
	local ls = Map3DSystem.localserver.CreateStore("MyStore");
	if(not ls) then
		log("error: failed creating local server resource store\n")
		return 
	else
		log("MyStore is opened\n")	
	end	
	
	-- test single url in a request 
	log("test single request \n")
	local request = Map3DSystem.localserver.TaskManager:new_request("http://www.kids3dmovie.com/CheckVersion.asmx")
	--local request = Map3DSystem.localserver.TaskManager:new_request("http://202.104.149.47/AuthUser.asmx?aaa=bbb")
	if(request) then
		-- add message
		request.msg = {aaa="bbb"};
		request.callbackFunc = function(msg, url) 
			log("SUCCEED: web service store:"..url.."\n msg = "..commonlib.serialize(msg));
		end
		request.OnTaskComplete = function(succeed) 
			log("task completed: result is "..tostring(succeed).."\n");
		end
		
		local task = Map3DSystem.localserver.CaptureTask:new(ls, request);
		if(task) then
			task:Run();
		end
	end
	
	-- test multiple requests in a single url task
	log("test multiple requests in a single url task \n")
	
	local request = Map3DSystem.localserver.TaskManager:new_request({
			"http://www.kids3dmovie.com/CheckVersion.asmx",
			"http://www.kids3dmovie.com/CheckVersion.asmx?aaa=bbb",
			-- test duplicates: this one should be removed automatically. 
			"http://www.kids3dmovie.com/CheckVersion.asmx",
			"http://www.kids3dmovie.com/CheckVersion.asmx?bbb",
		})
	if(request) then
		-- add message
		request.callbackFunc = function(msg, url) 
			log("SUCCEED: web service store:"..url.."\n msg = "..commonlib.serialize(msg));
		end
		request.OnTaskComplete = function(succeed) 
			log("task completed: result is "..tostring(succeed).."\n");
		end
		
		local task = Map3DSystem.localserver.CaptureTask:new(ls, request);
		if(task) then
			task:Run();
		end
	end
end

-- passed by LiXizhi 2008.3.3
function test.test_WS_duplicateCall()
	local wsAddr = "http://www.kids3dmovie.com/CheckVersion.asmx"
	NPL.RegisterWSCallBack(wsAddr, "test.ws_result()");
	NPL.CallWebservice(wsAddr, {aaa="bbb"});
	
	NPL.RegisterWSCallBack(wsAddr, "test.ws_result()");
	NPL.CallWebservice(wsAddr, {});
end

function test.ws_result()
	if (msg == nil)  then
		log("returns an error msg: "..tostring(msgerror).."\n"); 
	else
		log("SUCCEED:"..commonlib.serialize(msg))
	end	
end	