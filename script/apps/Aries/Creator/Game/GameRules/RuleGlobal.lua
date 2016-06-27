--[[
Title: RuleGlobal
Author(s): LiXizhi
Date: 2014/1/27
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleGlobal.lua");
local RuleGlobal = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleGlobal");
-------------------------------------------------------
]]
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local RuleGlobal = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"), commonlib.gettable("MyCompany.Aries.Game.Rules.RuleGlobal"));

function RuleGlobal:ctor()
end

function RuleGlobal:Init(rule_name, rule_value)
end

function RuleGlobal:OnRemove()
end