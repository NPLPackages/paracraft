--[[
Title:
Author(s): Leio
Date: 2009/12/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/activationkeys/paraworld.activationkeys.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.activationkeys", {});
--[[
 /// <summary>
        /// 取得指定用户分配到的CDKeys，用户可将其转赠给其他用户
        /// 接收参数：
        ///     nid
        /// 返回值：
        ///     list [list]
        ///         keycode
        ///         owner  -1表示还未被使用，否则表示使用者的NID
        ///     [ errorcode ]
        /// </summary>

--]]
paraworld.create_wrapper("paraworld.activationkeys.GetActivationKeys", "%MAIN%/API/Users/GetActivationKeys");
--[[
 /// <summary>
    /// 指定的用户因推荐用户获得奖励
    /// 接收参数：
    ///     nid 获取奖励的用户
    /// 返回值：
    ///     issuccess
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.activationkeys.IAmInvitedBy", "%MAIN%/API/Users/IAmInvitedBy");