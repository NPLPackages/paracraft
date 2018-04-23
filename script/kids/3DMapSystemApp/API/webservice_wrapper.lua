--[[
Title: NPL remote web service call wrapper with a pre function and post function. 
Author(s): LiXizhi
Date: 2008/1/21
Desc: 

Change by Andy 2009/9/2: originalMsg added to postFunc params

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/webservice_wrapper.lua");
paraworld.CreateRPCWrapper(fullname, url, prepFunc, postFunc)
-- see paraworld.* files for more examples. 
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/NPLExtension.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/webservice_constants.lua");
-- create class
if(not paraworld) then paraworld = {} end
local npl_thread_name = __rts__:GetName();
if(npl_thread_name == "main") then
	npl_thread_name = "";
end
----------------------------------------------
-- web service wrapper functions 
----------------------------------------------
--[[
Create an rpc wrapper function using closures. it will override existing one with identical name. 
@param fullName: by which name we name the RPC, it should contains at least one namespace. such as "paraworld.auth.AuthUser"
@param url: url of the RPC path, such as "http://auth.paraengine.com/AuthUser.asmx"
@param prepFunc: nil or an input message validation function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator) end 
 the function is called before making the RPC call to validate the input msg and preconditions. e.g. If user is not logged in, it will open a login window for user authentication. 
 the function should return nil if should continue with web service call, otherwise either true or a paraworld.errorcode is returned. If there is an error in preprocessing, the user callback is not called. and the error code is returned immediately from the rpc wrapper function. 
 One can create custom preprocessorFunc for each RPC wrapper, or use one of the predefined processor. 
 Another usage of prepFunc is that it can secretly translate input message to whatever the remote format message is. 
@param postFunc: nil or an output message validation function (self, msg, id) end 
 the function is called after the RPC returns to validate the output msg and then send the result to the user callback. e.g. It may report and handle certain common error, such as sesssion key expirations, etc. 
 the function should return nil if successful, otherwise a paraworld.errorcode is returned.  whether there is error or not the user callback is always called. 
@param preMsgTranslator: preprocessing msg input when activate is called. 
@param postMsgTranslator: postprocessing msg output when callback is called. 
@param requestPoolName: each request is made with a connection pool. And if the connections exceeds the pool size, they will have to wait in a queue. 
	if nil, it is "r"(REST), which has maximum of 5 connections. "d"(download) has 2 connections, "w"(web) has 5, and any other other has 1 connection by default. 
@Note by LiXizhi: all resource of the rpc is kept in a closure and there is only one global table "fullname" created.  I overwrite the table's __call method to make it callable with ease. 
 -- For example: after calling 
	 paraworld.CreateRPCWrapper("paraworld.auth.AuthUser", "http://auth.paraengine.com/AuthUser.asmx");
 -- we can call the rpc via wrapper paraworld.auth.AuthUser like this
     paraworld.auth.AuthUser({username="", Password=""}, "test", function (msg, params)  log(commonlib.serialize(msg)) end, "ABC");
 -- The above call is identical to 
     paraworld.auth.AuthUser:activate(...);
 -- The url of the web service can be get/set via 
     local url = paraworld.auth.AuthUser.GetUrl() 
     paraworld.auth.AuthUser.SetUrl("anything here")
 -- tostring() can also be used like this
	 log(tostring(paraworld.auth.AuthUser).."\n")
	 
@example code: see "script/kids/3DMapSystemApp/API/test/paraworld.auth.test.lua"
]]
function paraworld.CreateRPCWrapper(fullname, url_, prepFunc, postFunc, preMsgTranslator, postMsgTranslator, requestPoolName)
	local url = url_;
	local activateCount;
	-- closures: fullname, url, namespace, rpcName
	local namespace = string.gsub(fullname, "%.%w+$", "");
	local _,_, rpcName = string.find(fullname, "%.(%w+)$");
	-- a table of callback pool of {id, callback} pairs
	local pool = nil;
	
	local o = commonlib.getfield(fullname);
	if(o ~= nil) then 
		-- return if we already created it before.
		LOG.std(nil, "warn","RPC", "RPC "..fullname.." is overriden by paraworld.CreateRPCWrapper\n Remove duplicate calls with the same name.");
	end
	
	-- add a new call back for a given RPC
	-- @param id, callbackFunc, callbackParams: are the same as defined in each RPC wrapper. 
	-- @return: it will return true if succeed. or paraworld.errorcode.RepeatCall
	local function AddCallback(id, callbackFunc, callbackParams, inputMsg, originalMsg)
		if(pool== nil) then
			-- create the pool if not exist. 
			pool = {};
		end
		if(id == nil) then
			id = "nil";
		end
		local callback = pool[id];
		if(callback == nil) then
			-- create the callback entity if not exist. 
			callback = {callbackFunc = callbackFunc, callbackParams=callbackParams, inputMsg = inputMsg, originalMsg = originalMsg};
			pool[id] = callback;
			return true;
		else
			if(callback.IsRemoved or id=="nil") then
				callback.callbackFunc = callbackFunc;
				callback.callbackParams = callbackParams;
				callback.inputMsg = inputMsg;
				callback.originalMsg = originalMsg;
				callback.IsRemoved = false;
				return true;
			else
				return paraworld.errorcode.RepeatCall;
			end
		end
	end

	-- return the callback {callbackFunc, callbackParams}. Otherwise return nil. 
	local function GetCallback(id)
		if(pool~=nil) then
			local callback = pool[id or "nil"];
			if(callback ~= nil and not (callback.IsRemoved)) then
				return callback;
			end
		end
	end

	-- remove a rpc call back. when an RPC returns it should call this to remove from the waiting pool so that the same function can be called again. 
	local function RemoveCallback(id)
		if(pool~=nil) then
			local callback = pool[id or "nil"];
			if(callback ~= nil) then
				callback.IsRemoved = true;
				callback.inputMsg = nil;
				callback.originalMsg = nil;
			end	
		end
	end
	
	---------------------------------------
	-- the activation function that calls the remote RPC
	---------------------------------------
	local function activate(self, msg, id, callbackFunc, callbackParams)
		local originalMsg = commonlib.deepcopy(msg);
		if(preMsgTranslator) then
			msg = preMsgTranslator(msg);
		end
		if(not activateCount) then
			activateCount = 0;
			-- this allows use to parse url replaceables only when it is used. 
			url = paraworld.TranslateURL(url);
		end
		activateCount = activateCount + 1;
		local res;
		if(prepFunc~=nil) then
			res = prepFunc(self, msg, id, callbackFunc, callbackParams, postMsgTranslator);
		end
		if(res == nil) then
			if(type(id) == "function") then
				LOG.std(nil, "error","RPC", url.." should be called with a string id. Have you missed it?");
			end
			res = AddCallback(id, callbackFunc, callbackParams, msg, originalMsg);
			if(res==true) then
				-- NPL.RegisterWSCallBack(url, string.format(fullname..".callbackFunc(%q)", tostring(id)));
				-- NPL.CallWebservice(url, msg);
				-- commonlib.echo({"requesting: "..url, msg});
				NPL.AppendURLRequest(url, format("(%s)%s.callbackFunc(\"%s\")", npl_thread_name, fullname, tostring(id)), msg, requestPoolName or "r");
			end
		end
		return res;
	end
	
	---------------------------------------
	-- the callback function after the RPC returns. 
	---------------------------------------
	local function callbackFunc(id)
		local callback = GetCallback(id);
		if(callback ~= nil) then
			callback.IsRemoved = true;
			if(callback.callbackFunc~=nil) then
				if(msg == nil or msg.code~=0 or msg.rcode~=200) then
					LOG.std(nil, "error","RPC", fullname.." returns an error CURLCode\n"..LOG.tostring(msg));
				end
				
				local raw_msg = msg;
				if(postMsgTranslator) then
					msg = postMsgTranslator(msg, url);
				end
				if(postFunc~=nil) then
					local newMsg = postFunc(o, msg, id, callback.callbackFunc, callback.callbackParams, postMsgTranslator, raw_msg, callback.inputMsg, callback.originalMsg);
					if(newMsg) then
						msg = newMsg;
					end
				end
				
				callback.callbackFunc(msg, callback.callbackParams);
			end
		end
	end
	
	-- expose RPC class via global environment.   	
	o = setmetatable({
		GetUrl = function() return url end,
		SetUrl = function(new_url) 
				url = paraworld.TranslateURL(new_url)
			end,
		activate = activate,
		callbackFunc = callbackFunc,
	}, {
		__call = activate,
		__tostring = function(self)
			return fullname..": (" ..url..")";
		end
	});
	commonlib.setfield(fullname, o);
end

---------------------------------------------------------
-- helper functions
---------------------------------------------------------

-- show a status message. 
function paraworld.ShowMessage(text,...)
	_guihelper.CloseMessageBox();
	if(text~=nil) then
		_guihelper.MessageBox(text, ...);
	end	
end

-- return whether the result msg is a success. optionally, it can report most error messages via standard popup dialog. 
-- it will check msg, msg.issuccess, msg.info and msg.errorcode
-- @param msg: the message
-- @param bShowErrorToUser: if true, it will show error message to user via standard popup dialog. 
-- @return: bSuccess, errormsg: return true if msg is a general success, or nil if otherwise. and the second return parameter contains the translated errormsg. 
function paraworld.check_result(msg, bShowErrorToUser)
	local bSuccess, errormsg;
	if(not msg) then
		errormsg = "对不起, 暂时无法连接服务器"
		-- msgerror is in the log. 
	elseif(type(msg) == "table") then
		if(msg.issuccess == nil or msg.issuccess) then
			bSuccess = true;
		else
			if(type(msg.info) == "string") then
				errormsg = msg.info;
			elseif(type(msg.errorcode) == "number") then
				-- TODO: translate errorcode to text
				errormsg = "错误代码:"..msg.errorcode;
			else
				errormsg = "未知错误";
			end
		end
	end
	if(not bSuccess and bShowErrorToUser and errormsg) then
		paraworld.ShowMessage(errormsg);
	end
	return bSuccess, errormsg;
end

---------------------------------------------------------
-- predefined preprocessor and postprocessor functions
---------------------------------------------------------
-- if the current user is not authenticated, it will return paraworld.errorcode.LoginRequired. and display the login dialog 
-- if the current user is authenticated, it will add the sessionkey and userid to the msg. 
function paraworld.prepLoginRequried(self, msg, id, callbackFunc, callbackParams)
	if(not Map3DSystem.User.IsAuthenticated) then
		-- TODO: display the default login dialog 
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoginCommand(), "您需要先登录才能使用此功能");
		LOG.std("", "warning","API", "ParaWorldAPI requires that you login first");
		return paraworld.errorcode.LoginRequired;
	end
	-- this works like a cookie. 
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
		-- msg.userid = msg.userid or Map3DSystem.User.userid;
	end	
end

-- whether the current user is authenticated. 
function paraworld.IsAuthenticated()
	return Map3DSystem.User.IsAuthenticated;
end


---------------------------------------------
-- message translators 
-- it translates the input msg={header, code, rcode, data} before it is passed to callbackFunc
---------------------------------------------
-- translate msg.data from json to npl table
function paraworld.JsonTranslator(msg, url)
	if(msg and msg.code==0 and msg.data and msg.rcode==200) then
		-- use C++ version of json parser. It is safer than lua version, since it will never call lua panic 
		local out={};
		if(NPL.FromJson(msg.data, out)) then
			return out;
		else
			LOG.std("", "warning","RPC", "can not translate message to json|"..LOG.tostring("url: %s|", tostring(url))..LOG.tostring(msg.header).."|--> data|"..LOG.tostring(msg.data));
		end
		--return commonlib.Json.Decode(msg.data);
	end
	return nil;
end

function paraworld.DataTranslator(msg)
end

function paraworld.XmlTranslator(msg)
end

function paraworld.HTMLTranslator(msg)
	if(msg and msg.code==0 and msg.data and msg.rcode==200) then
		-- use C++ version of json parser. It is safer than lua version, since it will never call lua panic 
		return ParaXML.LuaXML_ParseString(msg.data)
		--return commonlib.Json.Decode(msg.data);
	end
	return nil;
end

function paraworld.SoapTranslator(msg)
end

-- inject the format=1 into the parameter, this tells paraworld server to use json as output. 
function paraworld.PreMsgJson(msg)
	if(msg) then
		if(#msg>=1) then
			msg[#msg + 1] = "format";
			msg[#msg + 1] = "1";
		else
			msg["format"] = 1;
		end
	end
	return msg;
end

----------------------------------------------
-- REST (with json as output) wrapper functions 
----------------------------------------------
--[[
-- create REST once and for all
paraworld.CreateRESTJsonWrapper("PWAPI.auth.AuthUser", "%MAIN%/Auth/AuthUser.ashx")

-- invoke with HTTP POST, where the second parameter is rpc instance name. the same instance share the same callback function. 
PWAPI.auth.AuthUser({username="LiXizhi1", password="1234567"}, "test", function(msg)  
	commonlib.echo(msg)
end)
-- invoke with HTTP GET. Notice that the msg is an array of name value pairs, this way the function knows the sequence of how to encode them in the url. 
PWAPI.auth.AuthUser({"username","LiXizhi2", "password", "1234567"}, "test", function(msg)  
	commonlib.echo(msg)
end)
]]
function paraworld.CreateRESTJsonWrapper(fullname, url_, prepFunc, postFunc, preMsgTranslator, postMsgTranslator, requestPoolName)
	paraworld.CreateRPCWrapper(fullname, url_, prepFunc, postFunc, preMsgTranslator or paraworld.PreMsgJson, postMsgTranslator or paraworld.JsonTranslator, requestPoolName or "r")
end

----------------------------------------------
-- HTTP raw message wrapper functions 
----------------------------------------------
--[[ It is similar to CreateRESTJsonWrapper, except that it does not decode the msg to json, instead the msg is always of the raw http format {header, data, type}
-- create REST once and for all
paraworld.CreateHttpWrapper("PWAPI.auth.GetServerList", "http://www.paraengine.com/index.html")
-- invoke with HTTP POST, where the second parameter is rpc instance name. the same instance share the same callback function. 
PWAPI.auth.GetServerList({ClientVersion="1", ServerVersion="1"}, "test", function(msg)  
	commonlib.echo(msg)
end)
]]
function paraworld.CreateHttpWrapper(fullname, url_, prepFunc, postFunc, preMsgTranslator, postMsgTranslator, requestPoolName)
	paraworld.CreateRPCWrapper(fullname, url_, prepFunc, postFunc, preMsgTranslator, postMsgTranslator, requestPoolName)
end