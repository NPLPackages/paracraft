--[[
Title: text-based test framework for paracraft
Author(s): LiXizhi
Date: 2023/6/1
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/TextToWorld/TextToTest.lua");
local TextToTest = commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToTest")
local test = TextToTest:new()
-------------------------------------------------------
]]
local TextToTest = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.TextToWorld.TextToTest"));

function TextToTest:ctor()
end

function TextToTest:Init()
end
