--[[
Title: ItemTimeSeries
Author(s): LiXizhi
Date: 2014/3/29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeries.lua");
local ItemTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries");
local item_ = ItemTimeSeries:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeries = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"));

block_types.RegisterItemClass("ItemTimeSeries", ItemTimeSeries);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeries:ctor()
end


-- virtual: convert entity to item stack. 
-- such as when alt key is pressed to pick a entity in edit mode. 
function ItemTimeSeries:ConvertEntityToItem(entity)
	if(entity and entity.GetActor and entity:GetActor()) then
		local itemStack = entity:GetActor():GetItemStack();
		if(itemStack) then
			return itemStack:Copy();
		end
	end
end

-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemTimeSeries:OnItemRightClick(itemStack, entityPlayer)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
	local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
	MovieClipController.OnRightClickItemStack(itemStack)
    return itemStack, true;
end

function ItemTimeSeries:SerializeServerData(serverdata, bSort)
	if(serverdata and serverdata.timeseries) then
		-- this will skip empty time series, usually saves lots of disk space and band width.
		local o = {};
		local originalTimeSeries = serverdata.timeseries;
		for k, v in pairs(originalTimeSeries) do
			if(type(v) == "table") then
				if(v.data and #v.data == 0) then
					-- skip
				else
					o[k] = v;
				end
			else
				o[k] = v;
			end
		end
		serverdata.timeseries = o;
		local text = commonlib.serialize_compact(serverdata, bSort);	
		serverdata.timeseries = originalTimeSeries;
		return text;
	else
		return commonlib.serialize_compact(serverdata, bSort);	
	end
end