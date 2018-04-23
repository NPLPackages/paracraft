--[[
Title: Microcomos Query Language (MQL)
Author(s): LiXizhi
Date: 2008/5/22
Desc: MQL is a way to query the same ParaWorld data you can access through the ParaWorldAPI functions, but with a SQL-style interface. 
In fact, many of the normal API calls are simple wrappers for MQL queries. All of the usual privacy checks are still applied. A typical query looks something like this: 
<verbatim>
	select uid,createDate from users where pageindex = 0 and pagesize = 5 and createDate > '2008-1-1' order by createDate desc
</verbatim>
So, with all that said, why would you use MQL? The key advantages of using MQL over our more traditional API methods are as follows: 
   * Condensed XML reduces bandwidth and parsing costs. Instead of getting all of the information available about a large set of items, 
   you can get just the fields you want for only the set of items matching a specific condition. You can request the specific set of information 
   by adding constraints to the WHERE clause and only listing certain fields in the SELECT clause. 
   * More complex requests can reduce the number of requests necessary. Often the data that you are trying to get depends upon the results of a previous method call. 
   * Provides a single consistent, unified interface for all of your data. Instead of having to learn numerous different methods 
   that each have their own idiosyncrasies, you can make all of your requests with one function that has a consistent return type. 
   Additionally, if you do need to call any of the traditional methods, the return XML is very similar, so the switching cost is negligible. 

It's fun! Check out the examples available at paraworld.MQL.query and then try playing around with it in the UnitTest console - you can do some cool stuff with it! 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.MQL", {});

--[[
	/// <summary>
	/// 执行传入的MQL语句，并将结果返回（参考文档： http://wiki/twiki/bin/view/Main/Paraworld_MQL_query）
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		[ appkey ] App Key
	///		[ sessionkey ] 用户凭证
	///		query(string) (*) 规范的MQL语句
	///			MQL语法类似于简化了的T-SQL。MQL必须以select、update、delete、insert into起始（目前只支持select）。 
	///
	///			不区分大小字 
	///
	///			保留关键字：
	///			select　　top　　from　　where　　order　　by　　desc　　asc　　group　　in　　like　　is　　not　　null　　between　　and　　or　　case　　as　　when　　then　　over　　begin　　end　　inner　　join　　union　　all 
	///
	///			支持的函数：
	///			cast　　count　　max　　min　　avg　　sum　　isnull　　nullif　　charindex　　len　　str　　substring　　left　　right　　
	///			语法与T-SQL相同 
	///
	///			MQL特有函数：
	///			Page(pageindex, pagesize, order column)：pageindex是以1开始的页码，pagesize是每页的数据量，order column是排序字段与排序规则。Page函数只能用在最外层的select语句中；若已使用了Page函数，则不可再在where从句中指定order by语句。示例：取得当前所有在线用户，按用户创建时间倒序排序，并按每页10条数据分页，取得第一页的数据：select page(1,10,order by createDate desc), * from users where isOnline = 1 
	/// }
	/// </param>
	/// <returns>
	/// 若是select语句，则返回：
	/// msg = {
	///		T[list]{ 
	///			(具体字段由select语句决定)
	///		}
	///		[ query ] 将输入的query参数返回
	///		[ errorcode ]  错误码。发生异常时会有此节点 错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除  494：语法错误
	/// }
	/// 若是update、delete、insert语句，则返回：
	/// msg = {
	///		issuccess  操作是否成功
	///		[ query ] 将输入的query参数返回
	///		[ errorcode ]  错误码
	/// }
	/// </returns>
]] 
-- the local server will cache each MQL query result, if caller queries for multiple entries at one call, they are saved in local server as multiple entries. 
-- Note: if this function wants to use game server, replace  ls:GetURL with pure local server. 
local MQL_query_cache_policy = System.localserver.CachePolicy:new("access plus 2 hours");
paraworld.CreateRESTJsonWrapper("paraworld.MQL.query", "%MAIN%/MQL/query.ashx",
function(self, msg, id, callbackFunc, callbackParams, postMsgTranslator) 
	msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	
	local cache_policy = msg.cache_policy or MQL_query_cache_policy;
	if(type(cache_policy) == "string") then
		cache_policy = System.localserver.CachePolicy:new(cache_policy)
	end
	if(cache_policy:IsCacheEnabled()) then
		-- DEMO of local server
		local ls = System.localserver.CreateStore(nil, 3);
		if(ls) then
			ls:GetURL(cache_policy,
				NPL.EncodeURLQuery(self.GetUrl(), {"format", msg.format, "query", msg.query}),
				callbackFunc, callbackParams, postMsgTranslator
			);
		else
			log("error: unable to open default local server store \n");
		end	
		-- since we process via local server, there is no need to call RPC. 
		return true;
	end	
end)
