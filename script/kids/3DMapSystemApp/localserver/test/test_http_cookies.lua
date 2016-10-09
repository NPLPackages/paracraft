--[[
Title: testing cookie map class
Author(s): LiXizhi
Date: 2008/2/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/test/test_http_cookies.lua");
test_cookiemap()
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_cookies.lua");


-- passed by LiXizhi 2008.2.23
function test_cookiemap()
	log("testing test_cookiemap: \n");
	
	local testcases = {
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid=&name2=123",
			RequriedCookie = "uid",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid=value1&name2=123",
			RequriedCookie = "uid = value1",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid = somevalue & name2 = value2",
			RequriedCookie = "name2=NoSuchValue",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid = somevalue & name2 = value2",
			RequriedCookie = "name2=;NONE;",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid = somevalue & name2=",
			RequriedCookie = "name2=;NONE;",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid = somevalue & name2=value2",
			RequriedCookie = "name3=;NONE;",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx?uid=1234-1234",
			RequriedCookie = "uid",
		},
		{
			in_ = "http://www.paraengine.com:3000/getmap.asmx",
			RequriedCookie = "uid",
		},
	}
	local i, case
	for i, case in ipairs(testcases) do
		log("case "..i.."\n")
		log("in: "..case.in_.."\n")
		local CookieMap = Map3DSystem.localserver.CookieMap:new(case.in_)
		log(commonlib.serialize(CookieMap))
		log("Has Requried Value: "..case.RequriedCookie.." is "..tostring(CookieMap:HasLocalServerRequiredCookie(case.RequriedCookie) or false).."\n\n")
	end
end