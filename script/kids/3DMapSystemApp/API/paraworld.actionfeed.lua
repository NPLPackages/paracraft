--[[
Title: a central place per application for selling and buying tradable items. 
Author(s): LiXizhi, WangTian
Date: 2008/1/21
NOTE: change all userid to nid, WangTian, 2009/6/30
NOTE: Aquarius and Map3DSystem related feed functions are NOT imported to the new feed API, WangTian, 2009/6/30
NOTE: paraworld.actionfeed.sendEmail
	  paraworld.actionfeed.UploadScreenshot
	  paraworld.actionfeed.SubmitArticle
	  these three APIs are NOT imprted to the new API, WangTian, 2009/6/30
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.actionfeed", {});

----[[Returns information on outstanding notifications for current session user.
--]] 
--paraworld.CreateRESTJsonWrapper("paraworld.actionfeed.get", "http://actionfeed.paraengine.com/get.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// Usually public messages visible to all visitors on the user's profile page
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"to_nids" = string() 以英文逗号（,）分隔的用户数字ID集合。当to_nids为空时表示发给当前登录用户自己和其所有好友
	///		"story" = string (*)
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.actionfeed.PublishStoryToUser", "%ACTIONFEED%/PublishStoryToUser.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// 
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"to_nids" = string() 以英文逗号（,）分隔的用户数字ID集合。当to_nids为空时表示发给当前登录用户自己和其所有好友
	///		"action" = string (*)
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.actionfeed.PublishActionToUser", "%ACTIONFEED%/PublishActionToUser.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// Usually private request messages only visible to the specified uid. such as friend request message. 
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"to_nids" = string() 以英文逗号（,）分隔的用户数字ID集合。当to_nids为空时表示发给当前登录用户自己和其所有好友
	///		"request" = string (*)
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.actionfeed.PublishRequestToUser", "%ACTIONFEED%/PublishRequestToUser.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// Usually private messages only visible to the specified uid. such as poke message. 
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"to_nids" = string() 以英文逗号（,）分隔的用户数字ID集合。当to_nids为空时表示发给当前登录用户自己和其所有好友
	///		"message" = string (*)
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.actionfeed.PublishMessageToUser", "%ACTIONFEED%/PublishMessageToUser.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// 
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*) 当前登录用户的用户凭证
	///		"to_nids" = string() 以英文逗号（,）分隔的用户数字ID集合。当to_nids为空时表示发给当前登录用户自己和其所有好友
	///		"item" = string (*)
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" = boolean 操作是否成功
	///		[ errorcode ] = int  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除
	/// }
	/// </returns>
]] 
paraworld.create_wrapper("paraworld.actionfeed.PublishItemToUser", "%ACTIONFEED%/PublishItemToUser.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// 使用系统服务邮箱发送电子邮件（只可给当前登录用户的好友发送邮件）
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" (*) //用户凭证
	///		"to" = string (*) //以英文逗号（,）分隔的用户ID集合
	///		"title" = string (*) //邮件标题
	///		"body" = string (*) //邮件正文
	///		[ "isbodyhtml" ] = boolean //邮件正文是否为HTML格式。默认值为true
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		issuccess = boolean //发送邮件是否成功
	///		errorcode = int //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.actionfeed.sendEmail", "%ACTIONFEED%/sendEmail.ashx", paraworld.prepLoginRequried);


--[[ TODO: move from kids movie site to Pala5.com, remove the number of files that can be uploaded by paraworld
Upload screenshot to ParaWorld in KidsMovieSite. 
msg = {
		"sessionkey" (*) //用户凭证
		"ImgIn" = file, REQUIRED FIELD
		"username" = KidsMoive username, default to "paraworld"
		"password" = KidsMoive password, default "paraworld"
		"FileName" = file path, default to "auto.jpg"
		Overwrite = whether overwrite, default to true
}
<returns>
msg = {
	fileURL = string
}
</returns>
]]
paraworld.CreateRPCWrapper("paraworld.actionfeed.UploadScreenshot", "http://www.kids3dmovie.com/UploadUserFile.asmx", 
function (self, msg, id, callbackFunc, callbackParams)
	local res = paraworld.prepLoginRequried(self, msg, id, callbackFunc, callbackParams)
	if(res ~= nil) then return res end
	-- this works like a cookie. 
	msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	
	msg.username = msg.username or "paraworld";
	msg.password = msg.password or "paraworld";
	msg.FileName = msg.FileName or "auto.jpg";
	msg.Overwrite = true;
end,
function (self, msg, id)
	if(msg and msg.fileURL) then
		if(string.sub(msg.fileURL, 1, 4)~= "http") then
			commonlib.echo(msg);
			msg.fileURL = nil;
		end
	end
end);

--[[ TODO: move from kids movie site to Pala5.com
Submit an article to KidsMovieSite. 
msg = {
		"sessionkey" (*) //用户凭证
		ImageURL = fileURL, REQUIRED FIELD
		"username" = KidsMoive username, default to "paraworld"
		"password" = KidsMoive password, default "paraworld"
		category = 101,102, ... Default to 101
		Title = string, default to paraworld title
		Abstract = string, default to paraworld abstract
}
<returns>
msg = {
	id = article id,  needs to >0
	articleURL = "",
}
</returns>
]]
paraworld.CreateRPCWrapper("paraworld.actionfeed.SubmitArticle", "http://www.kids3dmovie.com/SubmitArticle.asmx", 
function (self, msg, id, callbackFunc, callbackParams)
	local res = paraworld.prepLoginRequried(self, msg, id, callbackFunc, callbackParams)
	if(res ~= nil) then return res end
	-- this works like a cookie. 
	msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	
	msg.username = msg.username or "paraworld";
	msg.password = msg.password or "paraworld";
	msg.category = msg.category or 101;
	msg.Title = msg.Title or "www.pala5.com";
	msg.Abstract = msg.Abstract or string.format("By %s: screenshot preview from http://www.pala5.com. A social web3d platform for everyone.", Map3DSystem.User.Name or "");
end);

