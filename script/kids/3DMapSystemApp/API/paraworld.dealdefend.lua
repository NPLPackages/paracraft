--[[
Title:
Author(s): Leio
Date: 2012/3/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/paraworld.dealdefend.lua");
local dealdefend = commonlib.gettable("paraworld.dealdefend");
-------------------------------------------------------
]]
local dealdefend = commonlib.gettable("paraworld.dealdefend");
--[[
/// <summary>
/// 申请重置安全密码
/// 接收参数：
///     sessionkey
/// 返回值：
///     issuccess
///     [ errorcode ] 403:安全问题的答案不正确；493:参数不正确；419:用户不存在
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.ApplyResetSecPass", "%MAIN%/API/Users/ApplyResetSecPass");
--[[
/// <summary>
/// 检测指定用户的安全密码是否已通过验证
/// 接收参数：
///     sessionkey
/// 返回值：
///     issuccess
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.CheckSecPass", "%MAIN%/API/Users/CheckSecPass");
--[[
/// <summary>
/// 修改安全密码
/// 接收参数：
///     sessionkey
///     oldsecpass 旧安全密码
///     newsecpass 新安全密码
///     newsecpasspt 新安全密码的提示信息
/// 返回值：
///     issuccess
///     [ errorcode ] 419:用户不存在；493:参数错误；420:提供的旧密码不正确
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.ChgSecPass", "%MAIN%/API/Users/ChgSecPass");
--[[
/// <summary>
/// 设置安全密码
/// 接收参数：
///     sessionkey
///     logonpass 登录密码
///     secapt 安全问题答案的提示信息 ＝》安全密码的提示信息
///     secpass 安全密码
///     [ from ] = number 是从哪个平台过来的用户。0:TM 1:快玩。默认为０
/// 返回值：
///     issuccess
///     [ errorcode ] 419:用户不存在；417:已设置过了；493:参数错误；407:登录密码不正确
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.SetSecPass", "%MAIN%/API/Users/SetSecPass.ashx",
-- PreProcessor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
	LOG.std(nil, "debug", "SetSecPass.begin", msg);
end,
-- Post Processor
function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
	LOG.std(nil, "debug", "SetSecPass.result", msg);
end
);

--[[
/// <summary>
/// 验证安全密码
/// 接收参数：
///     sessionkey
///     secpass 安全密码
/// 返回值：
///     issuccess
///     [ errorcode ] 419:用户不存在；493:参数错误；420:安全密码不正确
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.VerifySecPass", "%MAIN%/API/Users/VerifySecPass");
--[[
/// <summary>
/// 取得指定用户的二级密码提示信息
/// 接收参数：
///     sessionkey
/// 返回值：
///     secpasspt 用户的二级密码提示信息
///     [ errorcode ] 493:参数错误 419:用户不存在
/// </summary>

--]]
paraworld.create_wrapper("paraworld.dealdefend.GetSecPassPt", "%MAIN%/API/Users/GetSecPassPt");