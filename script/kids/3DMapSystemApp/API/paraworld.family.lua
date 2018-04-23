--[[
Title: family servers related api
Author(s): gosling
Date: 2010.01.11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.family.lua");
-------------------------------------------------------
]]
-- create class
commonlib.setfield("paraworld.Family", {});
local LOG = LOG;
--[[
/// <summary>
/// 获得麻烦树种子
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
/// 返回值：
///     issuccess
///     [ errorcode ]  (用户不存在或不可用  条件不符)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.GainTroubleTree", "%MAIN%/API/Family/GainTroubleTree");

--[[
/// <summary>
/// 创建家族
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     name 家族名称
///     desc 家族宣言
/// 返回值：
///     issuccess
///     [ newid ]  新创建的家族的ID
///     [ errorcode ]  (提供的参数不符合要求  用户不存在或不可用  条件不符  家族名称已被使用  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.Create", "%MAIN%/API/Family/Create",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	msg.log2db = 1;
	msg.logremark = "Family.Create";
end);

--[[
/// <summary>
/// 邀请朋友加入家族
/// 接收参数
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
///     tonid  邀请对象的NID
/// 返回值：
///     issuccess
///     [ errorcode ]  (参数不符合要求  数据不存在或已被删除<家族不存在>  条件不符<当前用户不是族长或副族长>  重复数据<被邀请的用户已是该家族成员>  已达最大值<家族成员数已达到上限>)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.Invite", "%MAIN%/API/Family/Invite");

--[[
/// <summary>
/// 当前登录用户接受来自一个家族的邀请
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
/// 返回值：
///     issuccess
///     [ errorcode ]  (数据不存在或已被删除<家族不存在>  已达最大值<家族成员数已达最大值>  重复数据<当前用户已在此家族中>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.AcceptInvite", "%MAIN%/API/Family/AcceptInvite");

--[[
/// <summary>
/// 当前登录用户申请加入一个家族
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  申请加入的家族的ID
/// 返回值：
///     issuccess
///     [ errorcode ]  (数据不存在或已被删除<家族不存在>  重复数据<已是该家族成员>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.Request", "%MAIN%/API/Family/Request");

--[[
/// <summary>
/// 当前用户（家族族长或副族长）接受一个用户的加入申请
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     requestnid  申请者的NID
///     familyid  家族ID
/// 返回值：
///     issuccess
///     [ errorcode ]  (参数不符合要求  数据不存在或已被删除<家族不存在>  条件不符<当前用户非族长或副族长>  重复数据<申请者已在家族中>  已达最大值<家族成员数已达最大值>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.AcceptRequest", "%MAIN%/API/Family/AcceptRequest");

--[[
/// <summary>
/// 设置副族长
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
///     newdeputynid  新设置的副族长的NID
/// 返回值：
///     issuccess
///     [ errorcode ] (参数不符合要求  条件不符<当前用户非族长>  非家族成员<被设置者非家族成员>  重复数据<被设置者已是族长或副族长>  已达最大值<副族长人数已达最大值>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.SetDeputy", "%MAIN%/API/Family/SetDeputy");

--[[
/// <summary>
/// 设置族长
/// 接收参数
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
///     newadmin  新设置的族长的NID
/// 返回值：
///     issuccess
///     [ errorcode ]  (数据不存在或已被删除<家族不存在>  条件不符<当前用户非族长>  非家族成员<被设置者非家族成员>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.SetAdmin", "%MAIN%/API/Family/SetAdmin");

--[[
/// <summary>
/// 修改家族宣言
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
///     desc  新设置的宣言, should be exceed 30 letters.
///     [optional] blacklist 黑名单, nil or a table of {nid, nid, ...}
///     [optional] join_requirement 加入条件 nil or a small table {number,number,number}
/// 返回值：
///     issuccess
///     [ errorcode ] (参数不符合要求  数据不存在或已被删除<家族不存在>  条件不符<当前用户非族长>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.UpdateDesc", "%MAIN%/API/Family/UpdateDesc",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	-- secretly, merge backlist and join_requirement into desc
	local desc = msg.desc;
	if(type(msg.blacklist) == "table" and #(msg.blacklist)>0) then
		local black_list_str;
		local i, nid;
		local max_black_count = 10;
		for i, nid in ipairs(msg.blacklist) do
			if(i<=max_black_count) then
				if(black_list_str) then
					black_list_str = black_list_str..","..tostring(nid);
				else
					black_list_str = tostring(nid);
				end
			else
				LOG.std(nil, "warn", "Family", "blacklist ignored since there are over 10 people in the list.")
			end
		end
		if(black_list_str) then
			desc = (desc or "").."$bl{"..black_list_str.."}";
		end
	end
	if(type(msg.join_requirement) == "table") then
		local join_req_str = "";
		local max_field_count = 3;
		local i, value;
		local has_value;
		for i = 1, max_field_count do
			if(msg.join_requirement[i]) then
				has_value = true;
				if(i == 1)then
					join_req_str = tostring(msg.join_requirement[i]);
				else
					join_req_str = join_req_str..","..tostring(msg.join_requirement[i]);
				end
			elseif(i<max_field_count) then
				join_req_str = join_req_str..",";
			end
			
		end
		if(has_value) then
			desc = (desc or "").."$rq{"..join_req_str.."}";
		end
	end
	msg.desc = desc;
end
);

--[[
/// <summary>
/// 取得指定的家族的详细信息
/// 接收参数：
///     idorname  家族ID或家族名称
/// 返回值：
///     id  家族ID
///     name  家族名称
///     desc  家族宣言
///     [optional] blacklist 黑名单, nil or a table of {nid, nid, ...}
///     [optional] join_requirement 加入条件 nil or a small table {number,number,number}
///     level  家族级别
///     admin  家族家族的NID
///     deputy  String，家族所有的副族长的NID，多个NID之间用英文逗号分隔
///     members[list]  家族所有成员
///         nid  NID
///         contribute  对家族的贡献度
///         last  最后签到的时间，yyyy-MM-dd
///     maxcontain  最大可拥有的家族成员数
///     createdate  创建时间 yyyy-MM-dd HH:mm:ss
///     familyworld  家族服务器，若为String.Empty，则表示该家族未设置家族服务器
///     [ errorcode ]  (提供的参数不符合要求  数据不存在或已被删除<家族不存在>  未知的错误)
/// </summary>
--]]
local familyget_cache_policy = "access plus 30 minutes";
paraworld.create_wrapper("paraworld.Family.Get", "%MAIN%/API/Family/Get", 
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	if(not paraworld.use_game_server) then
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	end	
	msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
	
	-- cache policy
	local cache_policy = msg.cache_policy or familyget_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy);
	end
	msg.cache_policy = nil;
	
	local ls = System.localserver.CreateStore(nil, 3);
	if(not ls) then
		return;
	end
	
	if(msg.idorname) then
		-- if local server has an unexpired result, return the result to callbackFunc, otherwise continue. 
		local HasResult;
		-- make url
		local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "idorname", msg.idorname});
		local item = ls:GetItem(url)
		if(item and item.entry and item.payload) then
			if(not cache_policy:IsExpired(item.payload.creation_date)) then
				-- we found an unexpired result, return the result to callbackFunc
				HasResult = true;
				-- make output msg
				local output_msg = commonlib.LoadTableFromString(item.payload.data);
				
				LOG.std("", "debug", "API", "unexpired local version for : %s", url)
				
				if(callbackFunc) then
					callbackFunc(output_msg, callbackParams)
				end	
			end
		end
		if(HasResult) then
			-- don't require web API call
			return true;
		end	
		-- LOG.std("", "debug", "API", "fetching : "..url)
	end
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg and not msg.errorcode) then
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			-- make output msg
			local output_msg = msg;

			if(output_msg.desc) then
				-- secretly parse blacklist and join_requirement from desc. 
				local blacklist = output_msg.desc:match("%$bl(%{[0-9,]+%})");
				if(blacklist) then
					output_msg.blacklist = NPL.LoadTableFromString(blacklist);
					output_msg.desc = output_msg.desc:gsub("%$bl(%{[0-9,]+%})", "");
				end
				local join_requirement = output_msg.desc:match("%$rq(%{[0-9,]+%})");
				if(join_requirement) then
					output_msg.join_requirement = NPL.LoadTableFromString(join_requirement);
					output_msg.desc = output_msg.desc:gsub("%$rq(%{[0-9,]+%})", "");
				end
			end

			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "idorname", msg.name});
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = (output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", "family info of %s saved to local server during paraworld.Family.Get", tostring(url));
			else	
				LOG.warn("failed saving family info of %s to local server during paraworld.Family.Get", tostring(url))
				LOG.warn(output_msg);
			end
			-- make output msg
			local output_msg = msg;
			-- make url
			local url = NPL.EncodeURLQuery(self.GetUrl(), {"format", 1, "idorname", msg.id});
			-- make entry
			local item = {
				entry = System.localserver.WebCacheDB.EntryInfo:new({
					url = url,
				}),
				payload = System.localserver.WebCacheDB.PayloadInfo:new({
					status_code = System.localserver.HttpConstants.HTTP_OK,
					data = (output_msg),
				}),
			}
			-- save to database entry
			local res = ls:PutItem(item);
			if(res) then 
				LOG.std("", "debug", "API", "family info of %s saved to local server during paraworld.Family.Get", tostring(url));
			else	
				LOG.warn("failed saving family info of %s to local server during paraworld.Family.Get", tostring(url))
				LOG.warn(output_msg);
			end
		end -- if(ls) then
	else
		LOG.std("", "debug", "API", "error: paraworld.Family.Get: unsupported message format:")	
		LOG.std("", "debug", "API", msg);
	end
end);

--[[
/// <summary>
/// 当前登录用户从家族中移除一个家族成员
/// 接收参数：
///     nid  当前登录用户的NID
///     familyid  家族ID
///     removenid  被从家族中移除的成员的NID
/// 返回值：
///     issuccess
///     [ errorcode ]  (参数不符合要求  数据不存在或已被删除<家族不存在>  条件不符<当前用户没有权力移除指定的成员>  非家族成员<被移除者非家族成员>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.RemoveMember", "%MAIN%/API/Family/RemoveMember");

--[[
/// <summary>
/// 当前登录用户主动从一个家族中退出
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
/// 返回值：
///     issuccess
///     [ errorcode ]  (参数不符合要求  数据不存在或已被删除<家族不存在>  非家族成员<当前用户指定家族成员>  条件不符<当前用户为族长，不可退出>  未知的错误)
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.Quit", "%MAIN%/API/Family/Quit");

--[[
/// <summary>
/// 取得最新成立的100个家族
/// 接收参数：
///     无
/// 返回值：
///     list [list]
///         id  家族ID
///         name  家族名称
///         membercnt  家族成员数
///         maxcontain  当前该家族可容纳的最大成员数
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.GetNewest", "%MAIN%/API/Family/GetNewest",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		if(not MyCompany.Aries.ExternalUserModule:GetConfig().is_share_friends) then
			msg.region = MyCompany.Aries.ExternalUserModule:GetRegionID();
		end
		LOG.std(nil, "system", "Family.GetNewest", msg);
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "system", "Family.GetNewest", msg);
	end
);
--[[
[host]/API/Family/RemoveDeputy         
/// <summary>
/// 当前登录用户从家族中移除一个副族长（只是将其副族长权限移除，并未从家族成员中移除）
/// 接收参数：
///     sessionkey  当前登录用户的sessionKey
///     familyid  家族ID
///     removenid  被移除的副族长的NID
/// 返回值：
///     issuccess
///     [ errorcode ]  (提供的参数不符合要求  数据不存在或已被删除[家族不存在]  条件不符[当前用户非族长])
/// </summary>

--]]
paraworld.create_wrapper("paraworld.Family.RemoveDeputy", "%MAIN%/API/Family/RemoveDeputy");
--[[
/// <summary>
/// 家族管理员删除家族
/// 接收参数：
///     sessionkey  当前登录用户的SessionKey
///     familyid  家族ID
/// 返回值：
///     issuccess
///     [ errorcode ]  数据不存在或已被删除[家族不存在]  条件不符[当前用户非管理员]  不可进行此操作[家族中有其他用户]  未知的错误
/// </summary>

--]]
paraworld.create_wrapper("paraworld.Family.Delete", "%MAIN%/API/Family/Delete");
--[[
/// <summary>
/// 家族成员签到，可提升家族活跃度和个人对家族的贡献度
/// 接收参数：
///     sessionkey  当前登录用户的SessionKey
///     familyid  家族ID
/// 返回值：
///     issuccess
///     [ errorcode ]  提供的参数不符合要求  数据不存在或已被删除[家族不存在]  非家族成员[当前用户非该家族成员]  已达最大值[当日已签到过了]
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.SignIn", "%MAIN%/API/Family/SignIn");
--[[
/// <summary>
/// 取得最热门的100个家族
/// 接收参数：
///     无
/// 返回值：
///     list [list]
///         id  家族ID
///         name  家族名称
///         membercnt  家族成员数
///         maxcontain  当前该家族可容纳的最大成员数
///         admin  家族族长的NID
///         deputy  String，家族所有的副族长的NID，多个NID之间用英文逗号分隔
///         desc  家族宣言
/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.GetHot", "%MAIN%/API/Family/GetHot",
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
		if(not MyCompany.Aries.ExternalUserModule:GetConfig().is_share_friends) then
			msg.region = MyCompany.Aries.ExternalUserModule:GetRegionID();
		end
		LOG.std(nil, "system", "Family.GetHot", msg);
	end,
	function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
		LOG.std(nil, "system", "Family.GetHot", msg);
	end
);

--[[
/// <summary>
/// 修改家族服务器
/// 接收参数：
///     nid  当前登录用户的NID
///     familyid  家族ID
///     worldid  新设置的家族服务器的ID
/// 返回值：
///     issuccess
///     [ updates ][list] 输出叠加在旧数据上的物品
///         guid
///         bag
///         cnt
///     [ adds ][list] 输出新增的数据
///         guid
///         gsid
///         bag
///         cnt
///         position
///     [ stats ][list] 输出兑换后各属性值的变化，其中-12表示当前的健康状态（0：健康；1：生病；2：死亡），-1000表示抱抱龙升级到下一级所需的亲密度
///         gsid  -1:P币；0:E币；-2:亲密度；-3:爱心值；-4:力量值；-5:敏捷值；-6:智慧值；-7:建筑熟练度；-8:抱抱龙等级；-9:体力值；-10:清洁值；-11:心情值；-12:健康状态；-13:战斗经验值；-14:战斗等级；
///         cnt
///     [ errorcode ] (497:家族不存在  417:新设置的家族服务器与旧家族服务器相同  427:当前用户非族长  500:未知的错误)
/// </summary>
]]
paraworld.create_wrapper("paraworld.Family.SetFamilyWorld", "%MAIN%/API/Family/SetFamilyWorld", nil,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg, originalMsg)
	if(msg and not msg.errorcode) then
		-- TODO: for andy, do the Item manager updates here.
	end
end);


--[[
	/// <summary>
	/// 家族中的某成员使用家族人气帖
	/// 接收参数：
	///     sessionkey 当前登录用户
	///     familyid 家族ID
	/// 返回值：
	///     issuccess
	///     [ errorcode ] 497: 家庭不存在 493:参数不正确 434:非家族成员 419:用户不存在 427:无家族人气帖 500:异常了
	/// </summary>
--]]
paraworld.create_wrapper("paraworld.Family.UseContributeCard", "%MAIN%/API/Family/UseContributeCard");