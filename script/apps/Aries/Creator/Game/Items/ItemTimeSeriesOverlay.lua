--[[
Title: ItemTimeSeriesOverlay
Author(s): LiXizhi
Date: 2016/1/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesOverlay.lua");
local ItemTimeSeriesOverlay = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesOverlay");
local item_ = ItemTimeSeriesOverlay:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorOverlay.lua");
local ActorOverlay = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorOverlay");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesOverlay = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesOverlay"));

block_types.RegisterItemClass("ItemTimeSeriesOverlay", ItemTimeSeriesOverlay);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesOverlay:ctor()
end

-- create actor from item stack. 
function ItemTimeSeriesOverlay:CreateActorFromItemStack(itemStack, movieclipEntity)
	local actor = ActorOverlay:new():Init(itemStack, movieclipEntity);
	return actor;
end

function ItemTimeSeriesOverlay:GetTooltipFromItemStack(itemStack)
	local name = itemStack:GetDisplayName();
	if(not name and name~="") then
		return self:GetTooltip();
	else
		return format(L"%s:右键编辑", name);
	end
end