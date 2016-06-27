--[[
Title: statistics names
Author(s): LiXizhi
Date: 2014/1/20
Desc: TODO
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/StatList.lua");
local StatList = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatList");
StatList.Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/StatBase.lua");
local StatBase = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatBase");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local StatList = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatList");

StatList.objectUseStats = {}


function StatList.Init()
	if(StatList.inited) then
		return
	end
	StatList.inited = true;
	StatList.objectUseStats = StatList.InitUsableStats(objectUseStats, "stat.useItem",10000, 0, 300);
end

-- Initializes statistic fields related to usable items and blocks.
function StatList.InitUsableStats(statArray, stat_name, base_id, from_id, to_id)
    statArray = statArray or {};
    for i = from_id, to_id do
		if(ItemClient.GetItem(i)) then
			statArray[i] = StatBase:new():Init(base_id+i, stat_name..ItemClient.GetItem(i):GetStatName(), i);
		end
    end
    return statArray;
end

