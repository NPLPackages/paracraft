--[[
Title: character geometry set table
Author(s): LiXizhi
Date: 2014/8/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/CharGeosets.lua");
local CharGeosets = commonlib.gettable("MyCompany.Aries.Game.Common.CharGeosets");
-------------------------------------------------------
]]

--[[
CSET_HAIR = 0,
CSET_FACIAL_HAIR1 = 1,
CSET_FACIAL_HAIR2 = 2,
CSET_FACIAL_HAIR3 = 3,
CSET_GLOVES = 4,
CSET_BOOTS = 5,
CSET_EARS = 7,
CSET_ARM_SLEEVES = 8,
CSET_PANTS = 9,
CSET_WINGS = 10, // newly added 2007.7.7
CSET_TABARD = 12,
CSET_ROBE = 13,
CSET_SKIRT = 14,// newly added 2007.7.8
CSET_CAPE = 15,
]]
local CharGeosets = commonlib.createtable("MyCompany.Aries.Game.Common.CharGeosets", {
	["hair"] = 0,
	["hair1"] = 1,
	["hair2"] = 2,
	["hair3"] = 3,
	["shirt"] = 8,
	["pant"] = 9,
	["boot"] = 5,
	["hand"] = 4,
	["wing"] = 10,
	["skirt"] = 14,
	["eye"] = 7,
});