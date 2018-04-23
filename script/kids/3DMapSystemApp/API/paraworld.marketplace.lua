--[[
Title: a central place per application for selling and buying tradable items. 
Author(s): LiXizhi
Date: 2008/1/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.marketplace", {});

--[[
/// <param name="msg">
///if(operation = "get") //获取某个App的所有Product
/// msg = {
///    "operation"=["get"],(*)
///    "sessionkey"= string (*),
///		"appid" = string(*)
/// }
///if(operation = "get")
/// {
///     msg =
///     {
///         products[list]
///         {
///             <product>
///                 proid(string)
///                 proname(string)
///                 appid(string)
///                 price(int)
///                 price2(int)
///                 price2start(string)
///					price2end(string)
///					desc(string)
///					num(int)
///             </product>
///         }
///     }
/// }
/// Return: 
/// if(operation = "add")
/// {
///		msg = 
///		{
///			result = boolean //操作是否成功
///		}
/// }
/// </returns>
]] 
paraworld.CreateRPCWrapper("paraworld.marketplace.GetBags", "%MAIN%/MarketService/ProductHandler.asmx");

paraworld.CreateRPCWrapper("paraworld.marketplace.AddBag", "http://marketplace.paraengine.com/AddBag.asmx");


--[[
]] 
paraworld.CreateRPCWrapper("paraworld.marketplace.RemoveBag", "http://marketplace.paraengine.com/RemoveBag.asmx");
