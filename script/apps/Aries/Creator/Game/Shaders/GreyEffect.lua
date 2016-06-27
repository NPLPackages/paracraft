--[[
Title: GreyEffect
Author(s): LiXizhi
Date: 2014/7/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/GreyEffect.lua");
local GreyEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyEffect");
local effect = GreyEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("Grey");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local GreyEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyEffect"));

GreyEffect.name = "Grey";

function GreyEffect:ctor()
	self:SetColorMultiply(1,1,1);
end

-- priority in shader effect
function GreyEffect:GetPriority()
	return -1;
end

--virtual function:
function GreyEffect:SetEnabled(bEnable)
	GreyEffect._super.SetEnabled(self, bEnable);
end

-- @param r,g,b: in [0,2]. default to 1,1,1 where a grey image is used. 
-- @param glow_r, glow_g, glow_b: color glow
function GreyEffect:SetColorMultiply(r,g,b, glow_r, glow_g, glow_b)
	r,g,b = 0.33*r, 0.33*g, 0.33*b;
	self.color_matrix = string.format("%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f", r,g,b, r,g,b, r,g,b, glow_r or 0, glow_g or 0, glow_b or 0);
end

-- do the per frame scene rendering here. 
function GreyEffect:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("Grey","script/apps/Aries/Creator/Game/Shaders/Grey.fxo");
	effect = ParaAsset.GetEffectFile("Grey");
		
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
		params:SetMatrix43("colorMatrix", self.color_matrix);
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