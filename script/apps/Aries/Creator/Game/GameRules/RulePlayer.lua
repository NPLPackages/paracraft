--[[
Title: RulePlayer
Author(s): LiXizhi
Date: 2014/1/27
Desc: 
---++ example
<verbatim>
this:AddRule("Player", "AutoWalkupBlock", false);

/addrule Player AllowRunning false
</verbatim>
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RulePlayer.lua");
local RulePlayer = commonlib.gettable("MyCompany.Aries.Game.Rules.RulePlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local RulePlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase"), commonlib.gettable("MyCompany.Aries.Game.Rules.RulePlayer"));

function RulePlayer:ctor()
end

function RulePlayer:Init(rule_name, rule_value)
	RulePlayer._super.Init(rule_name, rule_value);

	local name, value = rule_name:match("^(%S+)%s+(.*)$");
	if(name) then
		rule_name = name;
		rule_value = value;
	end
	self.name = name;
	if(rule_name == "AutoWalkupBlock") then
		self:SetAutoWalkupBlock(rule_value);
		return self;
	elseif(rule_name == "CanJump") then
		self:SetCanJump(rule_value);
		return self;
	elseif(rule_name == "PickingDist") then
		self:SetPickingDist(rule_value);
		return self;
	elseif(rule_name == "CanJumpInAir" or rule_name == "CanFly") then
		self:SetCanJumpInAir(rule_value);
		return self;
	elseif(rule_name == "CanJumpInWater") then
		self:SetCanJumpInWater(rule_value);
		return self;
	elseif(rule_name == "JumpUpSpeed") then
		self:SetJumpUpSpeed(rule_value);
		return self;
	elseif(rule_name == "AllowRunning") then
		self:SetAllowRunning(rule_value);
		return self;
	end
end

-- set picking distance
function RulePlayer:SetPickingDist(distance)
	local distance = self:GetNumber(distance);
	if(distance) then
		GameLogic.options:SetPickingDist(distance);
	end
end

-- set jump up speed
function RulePlayer:SetJumpUpSpeed(speed)
	local speed = self:GetNumber(speed);
	if(speed) then
		GameLogic.options:SetJumpUpSpeed(speed);
	end
end

-- whether player can jump
function RulePlayer:SetCanJump(isEnabled)
	self.isEnabled = self:GetBool(isEnabled);
	GameLogic.options:SetCanJump(self.isEnabled);
end

-- whether player can run
function RulePlayer:SetAllowRunning(isEnabled)
	self.isEnabled = self:GetBool(isEnabled);
	GameLogic.options:SetAllowRunning(self.isEnabled);
end

-- whether player can jump in air(Can Fly)
function RulePlayer:SetCanJumpInAir(isEnabled)
	self.isEnabled = self:GetBool(isEnabled);
	GameLogic.options:SetCanJumpInAir(self.isEnabled);
end

-- whether player can jump in water
function RulePlayer:SetCanJumpInWater(isEnabled)
	self.isEnabled = self:GetBool(isEnabled);
	GameLogic.options:SetCanJumpInWater(self.isEnabled);
end


function RulePlayer:SetAutoWalkupBlock(isEnabled)
	self.isEnabled = self:GetBool(isEnabled);
	LOG.std(nil, "info", "RulePlayer", "AutoWalkupBlock %s", tostring(self.isEnabled));
	ParaScene.GetPlayer():SetField("AutoWalkupBlock", self.isEnabled);
	return true;
end

function RulePlayer:OnRemove()
	RulePlayer._super.OnRemove(self);

	local rule_name = self.name;
	if(rule_name == "AutoWalkupBlock") then
		if(not self.isEnabled) then
			ParaScene.GetPlayer():SetField("AutoWalkupBlock", true);
		end
	elseif(rule_name == "CanJump") then
		GameLogic.options:SetCanJump(true);
	elseif(rule_name == "CanJumpInAir" or rule_name == "CanFly") then
		GameLogic.options:SetCanJumpInAir(true);
	elseif(rule_name == "CanJumpInWater") then
		GameLogic.options:SetCanJumpInWater(true);
	elseif(rule_name == "PickingDist") then
		GameLogic.options:SetPickingDist();
	end
end