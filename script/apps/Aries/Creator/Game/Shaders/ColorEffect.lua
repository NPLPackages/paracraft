--[[
Title: ColorEffect
Author(s): LiXizhi
Date: 2014/7/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/ColorEffect.lua");
local ColorEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.ColorEffect");
local effect = ColorEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("ColorEffect");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local ColorEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.ColorEffect"));

ColorEffect.name = "ColorEffect";

function ColorEffect:ctor()
	self:SetHSVAdd(0,0,0);
	self:SetHSVMultiply(1,1,1);
	self:SetColorMultiply(1,1,1)
end

-- priority in shader effect
function ColorEffect:GetPriority()
	return -1;
end

--virtual function:
function ColorEffect:SetEnabled(bEnable)
	self._super.SetEnabled(self, bEnable);
end

-- @param h,s,v: hue, saturation, value(brightness)
function ColorEffect:SetHSVAdd(h,s,v)
	self.colorHSVAdd = {h,s,v};
end

function ColorEffect:SetHSVMultiply(h,s,v)
	self.colorHSVMultiply = {h,s,v};
end

function ColorEffect:SetColorMultiply(r,g,b)
	self.colorMultiply = {r,g,b};
end

-- do the per frame scene rendering here. 
function ColorEffect:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("ColorEffect","script/apps/Aries/Creator/Game/Shaders/ColorEffect.fxo");
	effect = ParaAsset.GetEffectFile("ColorEffect");
		
	if(effect:Begin()) then
		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		
		-- save the current render target
		local old_rt = ParaEngine.GetRenderTarget();
			
		-- create/get a temp render target. 
		local _ColorRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
		-- copy content from one surface to another
		ParaEngine.StretchRect(old_rt, _ColorRT);
			
		local params = effect:GetParamBlock();
		params:SetVector3("colorHSVAdd", self.colorHSVAdd[1], self.colorHSVAdd[2], self.colorHSVAdd[3]);
		-- params:SetVector3("colorHSVMultiply", self.colorHSVMultiply[1], self.colorHSVMultiply[2], self.colorHSVMultiply[3]);
		params:SetVector3("colorMultiply", self.colorMultiply[1], self.colorMultiply[2], self.colorMultiply[3]);
		params:SetParam("screenParam", "vec2ScreenSize");
		
		-----------------------compose lum texture with original texture --------------
		ParaEngine.SetRenderTarget(old_rt);
		effect:BeginPass(0);
			params:SetTextureObj(0, _ColorRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end