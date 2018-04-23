--[[
Title: App profile management API
Author(s): LiXizhi, CYF, WangTian
Date: 2008/1/21
NOTE: change all userid to nid, WangTian, 2009/6/30

Desc: get a given or all application profiles of a given user; 
set a given application's profile for the current user or any user(needs providing application signature)
LocalServer is used for caching, so the GetMCML function can be used offline. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.profile", {});

--[[
	/// <summary>
	/// 登录用户修改、设置其本人的Profile
	/// </summary>
	/// <param name="msg">
	///		msg = {
	///			sessionkey = string (*) 用户必须登录才能修改数据，并且暂时只修改自己的Profile
	///			appkey = string(*) 修改的是哪个App的Profile
	///			profile = XmlElement (*) 某个用户的Profile的MCML表示形式。若未提供Profile或Profile值为String.Empty，表示将该条数据删除
	///		}
	/// </param>
	/// <returns>
	///		msg = {
	///			issuccess = boolean 操作是否成功。
	///			[ errorcode ] = int  //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问
	///			[ info ] = string (发生异常或不能正常操作数据时则返回此节点)
	///		}
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.profile.SetMCML", "%MAIN%/API/Profile/SetMCML.ashx",	paraworld.prepLoginRequried);

--[[
	/// <summary>
	/// 取得指定用户的Profile的MCML
	/// </summary>
	/// <param name="msg">
	///		msg = {
	/// 取得指定用户的Profile的MCML，若指定了APPKEY，但该用户没有该APPKEY的Profile，则返回该Profile的值为"{}"
	/// 接收参数：
	///		appKey = string, 若没有提供AppKey，则返回指定用户的所有Profile
	///		nid = string (*)
	///		}
	/// </param>
	/// <returns>
	///		msg = {
	///			nid = string 客户端传过来的用户数字ID
	///			appkey = string 客户端传过来的App Key
	///			apps = list{
	///				appkey = string
	///				profile = string
	///			}
	///         profile = string, for single app, data may be here. one need to check both msg.profile and msg.apps[appkey] for max compatibilities.
	///			[ errorcode ] = int //错误码。  未知的错误 = 500,  提供的数据不完整 = 499,  非法的访问 = 498,  数据不存在或已被删除 = 497,  未登录或没有权限 = 496
	///			[ info ] = string  //发生异常时有此节点
	///		}
	/// </returns>
]] 
-- getMCML with modified preprocessor and postprocessor and local server cache policy
-- the local server will cache each app MCML entry, if caller queries for multiple entries at one call, they are saved in local server as multiple entries. 
-- _Note_: if appkey is nil, local server is not used. if appkey is not nil, local server is used and expired result, if any, will be returned followed by an unexpired or latest result. 
local GetMCML_cache_policy = System.localserver.CachePolicy:new("access plus 2 hours");
paraworld.create_wrapper("paraworld.profile.GetMCML", "%MAIN%/API/Profile/GetMCML.ashx", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end
	msg.nid = msg.nid or Map3DSystem.User.nid;
	
	-- if asking for all apps, it will not retrieve from local server. 
	if(not msg.appkey) then
		if(paraworld.OfflineMode) then
			-- nothing to return for offline mode if appkey is empty. 
			if(callbackFunc) then
				callbackFunc(nil, callbackParams)
			end
			return true;
		end
		return
	end
	local cache_policy = msg.cache_policy or GetMCML_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	if(paraworld.OfflineMode) then
		cache_policy = System.localserver.CachePolicies["always"];
	end
	
	if(cache_policy==nil) then
		return;
	end
		
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return 
	end
	
	-- if local server has an unexpired result, return the result
	local HasResult;
	-- make input msg
	local input_msg = {
		appkey = msg.appkey,
		nid = msg.nid,
	};
	-- make url
	local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", msg.nid, "appkey", msg.appkey, })
	
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload) then
		if(not cache_policy:IsExpired(item.payload.creation_date)) then
			-- we found an unexpired result for nid, return the result to callbackFunc
			HasResult = true	
			-- log("Unexpired local version is used for "..url.."\n")
			
			-- make output msg
			local output_msg = {
				appkey = msg.appkey,
				nid = msg.nid,
				profile = item.payload.data,
			};
			if(callbackFunc) then
				callbackFunc(output_msg, callbackParams)
			end
		end
	end
	if(HasResult) then
		return true;	
	end	
end,

-- Post Processor
function (self, msg, id,callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	if(type(msg) == "table" and (msg.apps or msg.profile or msg.appkey)) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(not ls) then
			return 
		end
		-- make the url
		if(msg.appkey and (msg.apps==nil or #(msg.apps)==0))then
			-- make input msg
			local input_msg = {
				appkey = msg.appkey,
				nid = msg.nid,
			};
			-- make output msg
			local output_msg = {
				nid = msg.nid,
				appkey = msg.appkey,
				profile = msg.profile
			};
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", msg.nid, "appkey", msg.appkey, })
			
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = msg.profile,
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item) 
			if(res) then 
				log("local server put MCML profile for "..url.."\n")
			else
				log("warning: failed saving profile item to local server. see below\n")
				commonlib.log(output_msg);
			end
		elseif(msg.apps) then
			local i, app
			for i, app in ipairs(msg.apps) do
				-- make input msg
				local input_msg = {
					appkey = app.appkey,
					nid = msg.nid,
				};
				-- make output msg
				local output_msg = {
					nid = msg.nid,
					appkey = app.appkey,
					profile = app.profile
				};
				-- make url
				local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", msg.nid, "appkey", app.appkey, })
				
				-- make entry
				local item = {
					entry = System.localserver.WebCacheDB.EntryInfo:new({
						url = url,
					}),
					payload = System.localserver.WebCacheDB.PayloadInfo:new({
						status_code = System.localserver.HttpConstants.HTTP_OK,
						data = app.profile,
					}),
				}
				-- save to database entry
				local res = ls:PutItem(item) 
				if(res) then 
					log("ls put MCML profile for "..url.."\n")
				else
					log("warning: failed saving profile item to local server. see below\n")
					commonlib.log(output_msg);
				end
			end		
		end	
	else
		if(msg and msg.info) then
			commonlib.log("warning: %s return with errorcode %s and info: %s\n", self:GetUrl(), tostring(msg.errorcode), tostring(msg.info));
		end
		-- at least one appkey is specified. 
		if(inputMsg and inputMsg.appkey) then
			local ls = System.localserver.CreateStore(nil, 3);
			if(not ls) then
				return 
			end
			
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "nid", inputMsg.nid, "appkey", inputMsg.appkey, })
			
			local item = ls:GetItem(url)
			if(item and item.entry and item.payload) then
				-- we found an result for nid, return the result to callbackFunc
				-- make output msg
				local output_msg = {
					appkey = inputMsg.appkey,
					nid = inputMsg.nid,
					profile = item.payload.data,
				};
				log("Expired local version is used for "..url.."\n")
				return output_msg;
			end
		end
	end
end);
