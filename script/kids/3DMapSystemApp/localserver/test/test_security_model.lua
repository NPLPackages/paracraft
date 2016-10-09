--[[
Title: testing security model
Author(s): LiXizhi
Date: 2008/2/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_security_model.lua");
test_security_model()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/security_model.lua");


-- passed by LiXizhi 2008.2.23
function test_security_model()
	log("testing test_security_model: \n");
	
	local testcases = {
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx",
			out_ = "http://www.paraengine.com:3000",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx",
			out_ = "http://www.paraengine.com:3000",
		},
		{
			in_ = "file://www.paraengine.com/getmap.asmx",
			out_ = "file://www.paraengine.com",
		},
		{
			in_ = "http://www.PARAENGINE.com:80/getmap.asmx",
			out_ = "http://www.paraengine.com",
		},
		{
			in_ = "www.paraengine.com:80",
			out_ = "http://www.paraengine.com",
		},
		{
			in_ = "www.paraengine.com:80/",
			out_ = "http://www.paraengine.com",
		},
		{
			in_ = "www.paraengine.com:20/",
			out_ = "http://www.paraengine.com:20",
		},
		{
			in_ = "http://192.168.0.101:3000/",
			out_ = "http://192.168.0.101:3000",
		},
		{
			in_ = "http://192.168.0.101/",
			out_ = "http://192.168.0.101",
		},
	}
	local i, case
	for i, case in ipairs(testcases) do
		log("case "..i.."\n")
		log("in: "..case.in_.."\n")
		local s1 = Map3DSystem.localserver.SecurityOrigin:new(case.in_);
		log("result: "..s1.url.."\n")
		if(not s1:IsSameOrigin(case.out_)) then
			log("result matched. test SUCCEED!\n")
		else
			log("result mismatched. test FAILED!\n")
		end
	end
end