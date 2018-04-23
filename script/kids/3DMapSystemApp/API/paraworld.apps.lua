--[[
Title: a central place per application for selling and buying tradable items. 
Author(s): LiXizhi，CYF
Date: 2008/1/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.apps", {});


paraworld.CreateRPCWrapper("paraworld.apps.GetUserApp", "http://apps.paraengine.com/GetUserApp.asmx");

--[[
	/// <param name="msg">
	/// if(operation = "add") //新增一个NPLApp，返回该NPLApp的Key
	/// msg = {
	///		"operation" = ["add"],(*)
	///		"sessionkey" = string,(*)
	///		["appkey"] = string, 指定此应用程序唯一键。如果没有指定此值，则系统会随机分配一个
	///		"nplappname" = string,(*)
	///		"userid" = string,(*)
	///		"username" = string,
	///		"desc" = string,
	///		"downloadurl" = string,(*)
	///		"size" = int (*)
	/// }
	/// </param>
	/// <returns>
	/// if(operation = "add")
	/// {
	///		msg = 
	///		{
	///			issuccess = boolean //操作是否成功
	///			appkey = string
	///			[ info ] = string 发生异常时有此节点
	///		}
	/// }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.apps.AddApp", "%APP%/NPLAppHandler.asmx",
	-- pre validation function
	function (self, msg)
		msg.operation = "add";
		msg.sessionkey = Map3DSystem.User.sessionkey;
		msg.userid = Map3DSystem.User.userid;
	end);


paraworld.CreateRPCWrapper("paraworld.apps.RemoveApp", "http://apps.paraengine.com/RemoveApp.asmx");
paraworld.CreateRPCWrapper("paraworld.apps.UpdateApp", "http://apps.paraengine.com/UpdateApp.asmx");


--[[
/// <param name="msg">
	///if(operation = "get") //返回所有已开发完成的应用程序（NPLApp） 或 依主键取得一个应用程序的信息（NPLApp）
	/// msg = {
	///    "operation" = ["get"],(*)
	///		"sessionkey" = string,(*)
	///		"appid" = string  //如果有值，表示“依主键取得一个应用程序的信息（NPLApp）”，否则，“返回所有已开发完成的应用程序（NPLApp）”
	/// }
	/// </param>
	/// <returns>
	///if(operation = "get")
	/// {
	///		if(appid is null)
	///			msg =
	///			{
	///				apps[list]
	///				{
	///					<param>
	///						nplappid(string)
	///						nplappname(string)
	///						userid(string)
	///						username(string)
	///						desc(string)
	///						downloadurl(string)
	///						size(int)
	///						approved(boolean)
	///						showindirectory(boolean)
	///						finished(boolean)
	///						installedCount(int)
	///					</param>
	///				}
	///			}
	/// </returns>

]]
paraworld.CreateRPCWrapper("paraworld.apps.GetDirectory", "%APP%/NPLAppHandler.asmx",
	-- pre validation function
	function (self, msg)
		msg.operation = "get";
	end);
