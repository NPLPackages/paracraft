--[[
Title: stat base
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/StatBase.lua");
local StatBase = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatBase");
local stat = StatBase:new():Init(id, name, statType);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local StatBase = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatBase"));

function StatBase:ctor()
end

function StatBase:Init(id, name, statType)
	self.id = id;
	if(not name) then
		self.name = tostring(name).."_"..tostring(statType);
	else
		self.name = name;
	end
	self.statType = statType;

	return self;
end
