--[[
Title: ItemTimeSeriesLight
Author(s): LiXizhi
Date: 2016/1/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesLight.lua");
local ItemTimeSeriesLight = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesLight");
local item_ = ItemTimeSeriesLight:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorLight.lua");
local ActorLight = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorLight");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesLight = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesLight"));

block_types.RegisterItemClass("ItemTimeSeriesLight", ItemTimeSeriesLight);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesLight:ctor()
end

-- create actor from item stack. 
-- @param isReuseActor: whether we will reuse actor in the scene with the same name instead of creating a new entity. default to false.
-- @param name: if not provided, it will use the name in itemStack
function ItemTimeSeriesLight:CreateActorFromItemStack(itemStack, movieclipEntity, isReuseActor, name, movieclip)
	local actor = ActorLight:new():Init(itemStack, movieclipEntity, isReuseActor, name, movieclip);
	return actor;
end

function ItemTimeSeriesLight:GetTooltipFromItemStack(itemStack)
	local name = itemStack:GetDisplayName();
	if(not name and name~="") then
		return self:GetTooltip();
	else
		return format(L"%s:右键编辑", name);
	end
end