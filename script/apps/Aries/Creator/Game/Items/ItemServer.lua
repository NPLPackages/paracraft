--[[
Title: Item Server
Author(s): LiXizhi
Date: 2013/7/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemServer.lua");
local ItemServer = commonlib.gettable("MyCompany.Aries.Game.Items.ItemServer");
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemServer = commonlib.gettable("MyCompany.Aries.Game.Items.ItemServer");

function ItemServer.OnInit()
end
