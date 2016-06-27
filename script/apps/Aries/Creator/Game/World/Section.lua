--[[
Title: Section
Author(s): LiXizhi
Date: 2013/8/27
Desc: 16*16*16 block 
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/Section.lua");
local Section = commonlib.gettable("MyCompany.Aries.Game.World.Section");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

local tostring = tostring;
local format = format;
local type = type;
local Section = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.World.Section"))

local HALFSIZE = 16 * 16 * 8;


function Section:ctor()
	
end

function Section.Load(parent_chunk, sectionId)
	return Section:new({_Parent = parent_chunk, SectionId = sectionId});
end
