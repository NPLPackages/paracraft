--[[
Title:
Author(s): Leio
Date: 2009/9/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/minigame/paraworld.minigame.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.minigame", {});
--[[
/// <summary>
    /// 提交游戏分数
    /// 接收参数：
    ///     gameName
    ///     score
    /// 返回值：
    ///     issucccess
    ///     [ errorcode ]
    /// </summary>

--]]
paraworld.create_wrapper("paraworld.minigame.SubmitRank", "%MAIN%/API/MiniGame/SubmitRank");
--[[
/// <summary>
    /// 取得指定游戏的积分排行榜
    /// 接收参数：
    ///     gameName
    /// 返回值：
    ///     ranks[list]
    ///         nid
    ///         score
    ///     [ errorcode ]
    /// </summary>
--]]
paraworld.create_wrapper("paraworld.minigame.GetRank", "%MAIN%/API/MiniGame/GetRank");