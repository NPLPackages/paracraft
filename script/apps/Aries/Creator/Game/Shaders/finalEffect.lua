--[[
Title: finalEffect
Author(s): LiXizhi
Date: 2015/5/5
Desc: This effect should work together with the fancy shader (composite.fx) effect. 
It adds depth of view, bloom, HDR, motion blur, etc. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/finalEffect.lua");
local finalEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.finalEffect");
local effect = finalEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("finalEffect");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local finalEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.finalEffect"));
finalEffect:Property({"BloomEffect", false, "HasBloomEffect", "EnableBloomEffect", auto=true});
finalEffect:Property({"DepthOfViewEffect", false, "HasDepthOfViewEffect", "EnableDepthOfViewEffect", auto=true});

finalEffect.name = "final";

function finalEffect:ctor()
end

--virtual function:
function finalEffect:SetEnabled(bEnable)
	self._super.SetEnabled(self, bEnable);
	if(bEnable) then
		-- enable advanced shader
		self:GetEffectManager():SetShaders(2);
	end
end

-- do the per frame scene rendering here. 
function finalEffect:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("final","script/apps/Aries/Creator/Game/Shaders/final.fxo");
	effect = ParaAsset.GetEffectFile("final");

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
		params:SetParam("gbufferProjectionInverse", "mat4ProjectionInverse");
		params:SetParam("screenParam", "vec2ScreenSize");
			
		params:SetParam("matView", "mat4View");
		params:SetParam("matViewInverse", "mat4ViewInverse");
		params:SetParam("matProjection", "mat4Projection");
		
		params:SetParam("ViewAspect", "floatViewAspect");
		params:SetParam("TanHalfFOV", "floatTanHalfFOV");
		params:SetParam("cameraFarPlane", "floatCameraFarPlane");
		
		local attr = ParaCamera.GetAttributeObject();
		if(attr:GetField("MaxCameraObjectDistance", 0) < 1.0) then
			-- first person view
			params:SetFloat("centerDepthSmooth", 0.0);
		else
			-- third person view
			params:SetFloat("centerDepthSmooth", attr:GetField("CameraObjectDistance", 10));
		end

		params:SetParam("gbufferWorldViewProjectionInverse", "mat4WorldViewProjectionInverse");
		params:SetParam("cameraPosition", "vec3cameraPosition");
		params:SetParam("sunDirection", "vec3SunDirection");
		params:SetVector3("RenderOptions", 
			if_else(self:HasDepthOfViewEffect(),1,0), 
			if_else(self:HasBloomEffect(),1,0),
			0);
		effect:BeginPass(0);
			-- color render target. 
			params:SetTextureObj(0, ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0));
			-- entity and lighting texture
			params:SetTextureObj(1, ParaAsset.LoadTexture("_BlockInfoRT", "_BlockInfoRT", 0));
			-- shadow map
			params:SetTextureObj(2, ParaAsset.LoadTexture("_SMColorTexture_R32F", "_SMColorTexture_R32F", 0));
			-- depth texture 
			params:SetTextureObj(3, ParaAsset.LoadTexture("_DepthTexRT_R32F", "_DepthTexRT_R32F", 0));
			-- normal texture 
			params:SetTextureObj(4, ParaAsset.LoadTexture("_NormalRT", "_NormalRT", 0));

			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();

		effect:SetTexture(0, "");
		effect:SetTexture(1, "");
		effect:SetTexture(2, "");
		effect:SetTexture(3, "");

		effect:End();
	else
		-- revert to normal effect. 
		self:GetEffectManager():SetShaders(1);
		self:SetEnabled(false);
	end
end