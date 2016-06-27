--[[
Title: post processing effect base class
Author(s): LiXizhi
Date: 2014/7/5
Desc: see shaders/*Effect.lua for derived classes
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local ShaderEffectBase = commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local ShaderEffectBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"));

ShaderEffectBase.name = "none";

function ShaderEffectBase:ctor()
end

function ShaderEffectBase:GetName()
	return self.name;
end

-- @param name: can be nil to use default name
function ShaderEffectBase:Init(effect_manager, name)
	self.name = name or self.name;
	self.effect_manager = effect_manager;
	return self;
end

function ShaderEffectBase:GetEffectManager()
	return self.effect_manager;
end

-- priority in shader effect. the larger the earlier executed in post processing pipeline. can be negative values. 
function ShaderEffectBase:GetPriority()
	return 0;
end

function ShaderEffectBase:CheckIsHardwardSupported()
	return true;
end

-- virtual function: base class assume it is a post processing effect. Other effect should overwrite this function. 
function ShaderEffectBase:SetEnabled(bEnable)
	if(bEnable ~= false) then
		self:GetEffectManager():AddPostProcessingEffect(self);
	else
		self:GetEffectManager():RemovePostProcessingEffect(self);
	end
end

-- virtual function
function ShaderEffectBase:IsEnabled()
	return self:GetEffectManager():IsEffectEnabled(self);
end

-- virtul function: called per frame to do post processing. 
function ShaderEffectBase:OnRenderPostProcessing(ps_scene)
end