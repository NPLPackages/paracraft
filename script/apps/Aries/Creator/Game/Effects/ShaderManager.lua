--[[
Title: Shader and post processing effect manager
Author(s): LiXizhi
Date: 2014/7/5
Desc: GameLogic.GetShaderManager():GetFancyShader();
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderManager.lua");
local ShaderManager = commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderManager");
GameLogic.GetShaderManager():GetFancyShader():SetEnabled(true);
local effect = GameLogic.GetShaderManager():GetEffect("GreyBlur");
if(effect) then
	effect:SetEnabled(true);
end
GameLogic.GetShaderManager():RemoveAllPostProcessingEffects();
GameLogic.GetShaderManager():RegisterEffect(effect);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/PostProcessor.lua");
local ShaderManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderManager"));

function ShaderManager:ctor()
	-- mapping from effects names to post processing effect objects. 
	self.effects = {};
	-- post processing effect
	self.post_processing_effects = {};
end

function ShaderManager:Init()
	self:RegisterAllEffects();
	return self;
end

function ShaderManager:RegisterAllEffects()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/FancyPostProcessing.lua");
	local FancyV1 = commonlib.gettable("MyCompany.Aries.Game.Shaders.FancyV1");
	local effect = FancyV1:new():Init(self);
	self:RegisterEffect(effect);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/GreyBlurEffect.lua");
	local GreyBlurEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyBlurEffect");
	local effect = GreyBlurEffect:new():Init(self);
	self:RegisterEffect(effect);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/GreyEffect.lua");
	local GreyEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyEffect");
	local effect = GreyEffect:new():Init(self);
	self:RegisterEffect(effect);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/ColorEffect.lua");
	local ColorEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.ColorEffect");
	local effect = ColorEffect:new():Init(self);
	self:RegisterEffect(effect);

	NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/finalEffect.lua");
	local finalEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.finalEffect");
	local effect = finalEffect:new():Init(self);
	self:RegisterEffect(effect);
	-- TODO: add more
end

-- register new effects such as from external mod. 
-- official effects are already registered. 
function ShaderManager:RegisterEffect(effect)
	if(effect:CheckIsHardwardSupported()) then
		self.effects[effect:GetName()] = effect;
		return true;
	end
end


-- this is the fancy deferred shading pipeline for the block world rendering. 
function ShaderManager:GetFancyShader()
	return self:GetEffect("Fancy");
end

-- get a given effect
function ShaderManager:GetEffect(name)
	return self.effects[name];
end

-- @param shader_method: 0 fixed function; 1 standard; 2 fancy graphics.
-- @param return true if succeed;
function ShaderManager:SetShaders(shader_method)
	if(type(shader_method) == "number" and shader_method>=0 and shader_method<=2) then
		local bSucceed;
		if(shader_method == 2) then
			bSucceed = self:GetFancyShader():SetEnabled(true);
		else
			bSucceed = self:GetFancyShader():SetEnabled(false);
		end
		if(bSucceed) then
			ParaTerrain.GetBlockAttributeObject():SetField("BlockRenderMethod", shader_method)
		end
		return bSucceed;
	end
end


-- this mode is used to blur the 3d scene so to focus on UI. 
function ShaderManager:SetUse3DGreyBlur(bEnable)
	local effect = self:GetEffect("GreyBlur");
	if(effect) then
		effect:SetEnabled(bEnable);
	end
end

-- add effect to post processing effect, so that the OnRenderPostProcessing will be called.
function ShaderManager:AddPostProcessingEffect(theEffect)
	if(self:GetPostProcessingEffectIndex(theEffect)) then
		return 
	end
	
	local nOrderIndex = 1;
	for i, effect in ipairs(self.post_processing_effects) do
		if(effect:GetPriority() >= theEffect:GetPriority()) then
			nOrderIndex = i;
		end
	end
	commonlib.insertArrayItem(self.post_processing_effects, nOrderIndex, theEffect);
	if(#(self.post_processing_effects)>0) then
		commonlib.ps.EnablePostProcessing(true, function(ps_scene)
			self:OnRenderPostProcessing(ps_scene);
		end);
	end
	return true;
end

function ShaderManager:IsEffectEnabled(effect)
	if(self:GetPostProcessingEffectIndex(effect)) then
		return true;
	end
end

-- this function can also be used to test if effect is valid. 
function ShaderManager:GetPostProcessingEffectIndex(theEffect)
	for i, effect in ipairs(self.post_processing_effects) do
		if(effect == theEffect) then
			return i;
		end
	end
end

function ShaderManager:RemovePostProcessingEffect(theEffect)
	local index = self:GetPostProcessingEffectIndex(theEffect);
	if(index) then
		commonlib.removeArrayItem(self.post_processing_effects, index);
		if(#(self.post_processing_effects) == 0) then
			self:RemoveAllPostProcessingEffects();
		end
	end
end

function ShaderManager:RemoveAllPostProcessingEffects()
	self.post_processing_effects = {};
	commonlib.ps.EnablePostProcessing(false);
end

-- callback function
function ShaderManager:OnRenderPostProcessing(ps_scene)
	for i, effect in ipairs(self.post_processing_effects) do
		effect:OnRenderPostProcessing(ps_scene);
	end
end