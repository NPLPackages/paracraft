--[[
Title: Normal world
Author(s): LiXizhi
Date: 2023/7/12
Desc: A normal world is the same as normal pattern, except that it is dynamically generated from the current world.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/NormalWorld.lua");
local NormalWorld = commonlib.gettable("MyCompany.Aries.Game.Memory.NormalWorld");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/NormalPattern.lua");
local NormalWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Memory.NormalPattern"), commonlib.gettable("MyCompany.Aries.Game.Memory.NormalWorld"));
NormalWorld:Property("Name", "NormalWorld");

function NormalWorld:ctor()
end

function NormalWorld:Init()
	return self;
end

-- compare two patterns. it is possible that two patterns are not of the same size. But if one pattern contains the other, we can still compare them.
-- @param target: another NormalPattern
-- @return [0,1] how similar two patterns are. 
function NormalWorld:Compare(target)
	return 0;
end