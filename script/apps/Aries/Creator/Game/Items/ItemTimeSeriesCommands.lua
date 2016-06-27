--[[
Title: ItemTimeSeriesCommands
Author(s): LiXizhi
Date: 2014/4/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesCommands.lua");
local ItemTimeSeriesCommands = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesCommands");
local item_ = ItemTimeSeriesCommands:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorCommands.lua");
NPL.load("(gl)script/ide/math/vector.lua");
local ActorCommands = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorCommands");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesCommands = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesCommands"));

block_types.RegisterItemClass("ItemTimeSeriesCommands", ItemTimeSeriesCommands);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesCommands:ctor()
end

-- create actor from item stack. 
function ItemTimeSeriesCommands:CreateActorFromItemStack(itemStack, movieclipEntity)
	local actor = ActorCommands:new():Init(itemStack, movieclipEntity);
	return actor;
end
