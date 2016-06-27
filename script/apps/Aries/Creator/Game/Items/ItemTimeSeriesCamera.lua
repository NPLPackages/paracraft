--[[
Title: ItemTimeSeriesCamera
Author(s): LiXizhi
Date: 2014/3/29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesCamera.lua");
local ItemTimeSeriesCamera = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesCamera");
local item_ = ItemTimeSeriesCamera:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorCamera.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local ActorCamera = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCamera");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesCamera = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesCamera"));

block_types.RegisterItemClass("ItemTimeSeriesCamera", ItemTimeSeriesCamera);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesCamera:ctor()
end

-- create actor from item stack. 
function ItemTimeSeriesCamera:CreateActorFromItemStack(itemStack, movieclipEntity)
	local actor = ActorCamera:new():Init(itemStack, movieclipEntity);
	return actor;
end
