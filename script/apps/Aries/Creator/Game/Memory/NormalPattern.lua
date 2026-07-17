--[[
Title: Normal Pattern
Author(s): LiXizhi
Date: 2023/7/12
Desc: A normal pattern contains a group of normalized Normal blocks that are stored in a 3d space.

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/NormalPattern.lua");
local NormalPattern = commonlib.gettable("MyCompany.Aries.Game.Memory.NormalPattern");
-------------------------------------------------------
]]
local NormalPattern = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.NormalPattern"));
NormalPattern:Property("Name", "NormalPattern");

function NormalPattern:ctor()
end

function NormalPattern:Init()
	return self;
end

-- compare two patterns. it is possible that two patterns are not of the same size. But if one pattern contains the other, we can still compare them.
-- @param target: another NormalPattern
-- @return [0,1] how similar two patterns are. 
function NormalPattern:Compare(target)
	return 0;
end