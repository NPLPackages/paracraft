--[[
Title: Vignetting
Author(s): DreamAndDead
Date: 2020/3/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/Vignetting.lua");
local Vignetting = commonlib.gettable("MyCompany.Aries.Game.Shaders.Vignetting");
local effect = Vignetting:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("Vignetting");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local Vignetting = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.Vignetting"));

Vignetting.name = "Vignetting";

function Vignetting:ctor()
	self.amount = 0;
	self.midpoint = 0.5;
	self.roundness = 0;
	self.feather = 0;
end

-- priority in shader effect
function Vignetting:GetPriority()
	return -1;
end

--virtual function:
function Vignetting:SetEnabled(bEnable)
	Vignetting._super.SetEnabled(self, bEnable);
end

function Vignetting:SetParam(amount, midpoint, roundness, feather)
	self.amount = amount;
	self.midpoint = midpoint;
	self.roundness =roundness;
	self.feather =feather;
end

-- do the per frame scene rendering here. 
function Vignetting:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("Vignetting","script/apps/Aries/Creator/Game/Shaders/Vignetting.fxo");
	effect = ParaAsset.GetEffectFile("Vignetting");
		
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
		params:SetFloat("amountParam", self.amount);
		params:SetFloat("midpointParam", self.midpoint);
		params:SetFloat("roundnessParam", self.roundness);
		params:SetFloat("featherParam", self.feather);
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