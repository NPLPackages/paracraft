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
    RuleGlobal._super.Init(rule_name, rule_value);

    local name, value = rule_name:match("^(%S+)%s+(.*)$");
	if(name) then
		rule_name = name;
		rule_value = value;
	end
	self.name = name;
    self.value = rule_value
    
    if(rule_name == "DisableDropFile") then
		self:SetCanDropFile(rule_value)
        GameLogic.GetFilters():apply_filters('OnPlayerRuleChange')
		return self;
    end
    if(rule_name == "DisablePasteBlock") then
        self:SetPasteBlock(rule_value)
        GameLogic.GetFilters():apply_filters('OnPlayerRuleChange')
        return self;
    end
    if(rule_name == "DisablePasteBlockly") then
        self:SetPasteBlockly(rule_value)
        GameLogic.GetFilters():apply_filters('OnPlayerRuleChange')
        return self;
    end
end

function RuleGlobal:SetCanDropFile(isEnabled)
    self.isEnabled = self:GetBool(isEnabled, true);
    GameLogic.options:SetCanDropFile(not self.isEnabled)
end

function RuleGlobal:SetPasteBlock(isEnabled)
    self.isEnabled = self:GetBool(isEnabled, true);
    GameLogic.options:SetCanPasteBlock(not self.isEnabled)
end

function RuleGlobal:SetPasteBlockly(isEnabled)
    self.isEnabled = self:GetBool(isEnabled, true);
    GameLogic.options:SetCanPasteBlockly(not self.isEnabled)
end

function RuleGlobal:OnRemove()
    RuleGlobal._super.OnRemove(self);

	local rule_name = self.name;
	if(rule_name == "DisableDropFile") then
		GameLogic.options:SetCanDropFile(true)
    end   
    if(rule_name == "DisablePasteBlock") then
		GameLogic.options:SetCanPasteBlock(true)
    end
    if(rule_name == "DisablePasteBlockly") then
		GameLogic.options:SetCanPasteBlockly(true)
    end
    GameLogic.GetFilters():apply_filters('OnPlayerRuleChange') 
end