--[[
Title: ItemTimeSeriesNPC
Author(s): LiXizhi
Date: 2014/3/29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesNPC.lua");
local ItemTimeSeriesNPC = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesNPC");
local item_ = ItemTimeSeriesNPC:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
local ActorNPC = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesNPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesNPC"));

block_types.RegisterItemClass("ItemTimeSeriesNPC", ItemTimeSeriesNPC);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesNPC:ctor()
end

-- create actor from item stack. 
function ItemTimeSeriesNPC:CreateActorFromItemStack(itemStack, movieclipEntity)
	local actor = ActorNPC:new():Init(itemStack, movieclipEntity);
	return actor;
end

function ItemTimeSeriesNPC:GetTooltipFromItemStack(itemStack)
	local name = itemStack:GetDisplayName();
	if(not name and name~="") then
		return self:GetTooltip();
	else
		return format(L"%s:右键编辑", name);
	end
end