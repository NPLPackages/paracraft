--[[
Title: GreyBlurEffect
Author(s): LiXizhi
Date: 2014/7/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/GreyBlurEffect.lua");
local GreyBlurEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyBlurEffect");
local effect = GreyBlurEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("GreyBlur");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local GreyBlurEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.GreyBlurEffect"));

GreyBlurEffect.name = "GreyBlur";

function GreyBlurEffect:ctor()
end

-- enable blur effect
function GreyBlurEffect:SetEnabled(bEnable)
	if(bEnable ~= false) then
		self:GetEffectManager():AddPostProcessingEffect(self);
	else
		self:GetEffectManager():RemovePostProcessingEffect(self);
	end
end

-- priority in shader effect
function GreyBlurEffect:GetPriority()
	return -1;
end

-- do the per frame scene rendering here. 
function GreyBlurEffect:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("GreyBlur","script/apps/Aries/Creator/Game/Shaders/GreyBlur.fxo");
	effect = ParaAsset.GetEffectFile("GreyBlur");
		
	if(effect:Begin()) then
		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		
		-- save the current render target
		local old_rt = ParaEngine.GetRenderTarget();
			
		-- create/get a temp render target. 
		local _downSampleRT = ParaAsset.LoadTexture("_blueRT", "_blueRT", 0); 
		local down_sample_size = 256;
		_downSampleRT:SetSize(down_sample_size, down_sample_size);
			
		----------------------- down sample pass ----------------
		-- copy content from one surface to another
		ParaEngine.StretchRect(old_rt, _downSampleRT);
			
		local params = effect:GetParamBlock();
		params:SetMatrix43("colorMatrix", "0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0.33,0,0,0");
		params:SetVector2("screenParam", down_sample_size, down_sample_size);	

		-----------------------compose lum texture with original texture --------------
		ParaEngine.SetRenderTarget(old_rt);
		effect:BeginPass(0);
			params:SetTextureObj(0, _downSampleRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end