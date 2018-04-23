--[[
Title: litemail info
Author(s): Leio
Date: 2009/11/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/litemail/paraworld.litemail.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.litemail", {});
----------------------------------------------------------------------------------------------

--[[
	/// <summary>
	/// 用户提交投稿
	/// 接收参数：
	/// nid 当前用户的NID
	/// cid 稿件类别1：镇长信箱，2：哈奇故事，3:用户心愿，100：其它 101:小调查
	/// title 投稿的标题（最大200个字符）
	/// msg 投稿内容（最大1000个字符）
	/// 返回值：
	/// issuccess
	/// [errorcode]
	/// </summary> 
--]]
paraworld.create_wrapper("paraworld.litemail.Add", "%MAIN%/API/Posts/Add");


