--[[
Title: lobby services
Author(s): LiXizhi
Date: 2008/1/21
Desc: for JGSL
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.lobby", {});

--[[
	/// <summary>
	/// 创建房间。当一个用户成功创建一个房间后，该用户之前所创建的所有房间都将被删除
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" (*) //用户凭证
	///		[ "worldid" ] = int //房间所关联的World的ID，worldid与worldpath必须有一个有值，如果worldid有值，则忽略worldpath
	///		[ "worldpath" ] = string //房间所关联的World的Path，worldid与worldpath必须有一个有值，如果worldid有值，则忽略worldpath
	///		[ "joinpassword" ] = string //加入此房间需要的密码。如果不设密码，则不传此参数。
	///		[ "description" ] = string //房间的描述信息
	///		[　"maxclients"　] = int //此房间最多可容纳的人数，默认值为100
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		newroomid = int //若创建房间成功，则返回新创建房间的ID，否则，返回０
	///		[ errorcode ] = int //错误码，当发生异常时会有此节点。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.CreateRoom", "%LOBBY%/CreateRoom.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");


--[[
	/// <summary>
	/// 取得指定页的房间数据
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		[ "pageindex" ] = int //以０开始的页码，默认值为０
	///		[ "pagesize" ] = string //每页的最大数据量，默认值为５０
	///		[ "worldid" ] = int //取得与该World相关联的所有房间，若指定了worldid，将忽略worldpath
	///		[ "worldpath" ] = string //取得与该World相关联的所有房间
	///		[ "orderfield" ] = int //排序字段。１：roomid，２：CreateDate，３：ActivityDate，　默认值为２
	///		[ "orderdirection" ] = string //排序方式。１：正序；２：倒序，默认值为２
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		pagecount (int) 共有多少页
	///		rooms [list]{
	///			roomid (int) 主键
	///			worldid (int) 该房间关联的World的ID
	///			worldpath (string) 该房间关联的World的Path
	///			hostuid (string) 创建者用户ID
	///			joinpassword (string) 加入房间需要的密码
	///			description (string) 房间描述
	///			maxclients (int) 该房间最多可容纳多少人
	///			createDate (string) 房间创建时间
	///			activityDate (string) 该房间最后一位加入者的时间
	///		}
	///		[ errorcode ] (int) 错误码，发生异常时会有此节点
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.GetRoomList", "%LOBBY%/GetRoomList.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");


--[[
	db.clientnumber ++;
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.JoinRoom", "%LOBBY%/JoinRoom.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");

--[[
	db.clientnumber --;
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.LeaveRoom", "%LOBBY%/LeaveRoom.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");


--[[
	/// <summary>
	/// 取得某个频道的某个时间之后的所有消息
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string //用户凭证
	///		"channel" = string //频道名称
	///		[ "afterDate" ] = string //指定时间后的消息，如果为空，则不计
	///		[ "pageindex" ] = int //以０开始的页码，默认值为０
	///		[ "pagesize" ] = int //每页的最大数据量，默认值为５０
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"channel"  string //频道名称
	///		"msgs" [list]{
	///			"uid" = string,
	///			"date" = string,
	///			"content" = string,
	///		}
	///		[ errorcode ] int //发生异常时会有此节点
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.GetBBS", "%LOBBY%/GetBBS.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");


--[[
	/// <summary>
	/// 发布MCML String 到某个频道
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string //用户凭证
	///		"channel" = string //频道名称
	///		"content" = string //消息内容
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		"issuccess" boolean //发送是否成功
	///		[ "errorcode" ] int //错误码，发生异常时会有此节点
	///		}
	/// }
	/// </returns>
]] 
paraworld.CreateRESTJsonWrapper("paraworld.lobby.PostBBS", "%LOBBY%/PostBBS.ashx",	paraworld.prepLoginRequried, nil, nil,nil, "bbs");
