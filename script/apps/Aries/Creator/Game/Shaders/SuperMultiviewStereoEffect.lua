--[[
Title: SuperMultiviewStereo Effect
Author(s): LiXizhi
Email: lixizhi@yeah.net
Date: 2023.12.26
Desc: for naked eye effect of super multiview stereo. we will generate 50-96 views from different angle for each frame.

TODO: how to render alpha blended objects? simply disable them for now.

use the lib:
------------------------------------------------------------
local effect = GameLogic.GetShaderManager():GetEffect("SuperMultiviewStereo");
effect:SetEnabled(true);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local SuperMultiviewStereoEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.SuperMultiviewStereoEffect"));
SuperMultiviewStereoEffect:Property({"name", "SuperMultiviewStereo",});
SuperMultiviewStereoEffect:Property({"BloomEffect", false, "HasBloomEffect", "EnableBloomEffect", auto=true});
SuperMultiviewStereoEffect:Property({"DepthOfViewEffect", false, "HasDepthOfViewEffect", "EnableDepthOfViewEffect", auto=true});
SuperMultiviewStereoEffect:Property({"DepthOfViewFactor", 0.01, "GetDepthOfViewFactor", "SetDepthOfViewFactor", auto=true});
SuperMultiviewStereoEffect:Property({"EyeBrightness", 0.2, auto=true, desc="(0-1), used for HDR tone mapping"});
SuperMultiviewStereoEffect:Property({"EyeContrast", 0.5, auto=true, desc="(0-1), used for HDR tone mapping"});
SuperMultiviewStereoEffect:Property({"BloomScale", 1.1, "GetBloomScale", "SetBloomScale", auto=true});
SuperMultiviewStereoEffect:Property({"BloomCount", 2, "GetBloomCount", "SetBloomCount", auto=true});
SuperMultiviewStereoEffect:Property({"AOFactor", 0.8, "GetAOFactor", "SetAOFactor", auto=true});
SuperMultiviewStereoEffect:Property({"AOWidth", 0.2, "GetAOWidth", "SetAOWidth", auto=true});

SuperMultiviewStereoEffect.BlockRenderMethod = {
	FixedFunction = 0,
	Standard = 1,
	Fancy = 2,
}

-- return true if succeed. 
function SuperMultiviewStereoEffect:SetEnabled(bEnable)
	if(bEnable) then
		local res, reason = SuperMultiviewStereoEffect.IsHardwareSupported();
		if(res) then
			ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingScript", "MyCompany.Aries.Game.Shaders.SuperMultiviewStereoEffect.OnRender(0)")
			ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingAlphaScript", "MyCompany.Aries.Game.Shaders.SuperMultiviewStereoEffect.OnRender(1)")
			ParaTerrain.GetBlockAttributeObject():SetField("UseSunlightShadowMap", true);
			ParaTerrain.GetBlockAttributeObject():SetField("UseWaterReflection", true);
			self:SetBlockRenderMethod(self.BlockRenderMethod.Fancy);
			return true;
		elseif(reason == "AA_IS_ON") then
			ParaEngine.GetAttributeObject():SetField("MultiSampleType", 0);
			ParaEngine.WriteConfigFile("config/config.txt");
			LOG.std(nil, "info", "SuperMultiviewStereoEffect", "MultiSampleType must be 0 in order to use deferred shading. We have set it for you. you must restart. ");
			_guihelper.MessageBox("抗锯齿已经关闭, 请重启客户端");
		end
	else
		ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingScript", "");
		self:SetBlockRenderMethod(self.BlockRenderMethod.Standard);
		return true;
	end
end

function SuperMultiviewStereoEffect:IsEnabled()
	return ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1) == self.BlockRenderMethod.Fancy;
end

-- @param shader_method: type of BlockRenderMethod: 0 fixed function; 1 standard; 2 fancy graphics.
function SuperMultiviewStereoEffect:SetBlockRenderMethod(method)
	ParaTerrain.GetBlockAttributeObject():SetField("BlockRenderMethod", method);
end

-- static function: 
function SuperMultiviewStereoEffect.IsHardwareSupported()
	if( ParaTerrain.GetBlockAttributeObject():GetField("CanUseAdvancedShading", false) ) then
		-- must disable AA. 
		if(ParaEngine.GetAttributeObject():GetField("MultiSampleType", 0) ~= 0) then
			LOG.std(nil, "info", "SuperMultiviewStereoEffect", "MultiSampleType must be 0 in order to use deferred shading. ");
			
			return false, "AA_IS_ON";
		end
		local effect = ParaAsset.LoadEffectFile("SuperMultiviewStereo","script/apps/Aries/Creator/Game/Shaders/SuperMultiviewStereo.fxo");
		effect:LoadAsset();
		return effect:IsValid();		
	end
	return false;
end

----------------------------
-- shader uniforms
----------------------------
local sun_diffuse = {1,1,1};
local sun_color = {1,1,1};
local timeOfDaySTD = 0;
local timeNoon = 0;
local timeMidnight = 0;
-- compute according to current setting. 
function SuperMultiviewStereoEffect:ComputeShaderUniforms(bIsHDRShader)
	timeOfDaySTD = ParaScene.GetTimeOfDaySTD();
	timeNoon = math.max(0, (0.5 - math.abs(timeOfDaySTD)) * 2.0);
	timeMidnight = math.max(0, (math.abs(timeOfDaySTD) - 0.5) * 2.0);
	if(bIsHDRShader) then
		local att = ParaScene.GetAttributeObjectSunLight();
		sun_diffuse = att:GetField("Diffuse", sun_diffuse);
		sun_color[1] = sun_diffuse[1] * timeNoon * 1.6;
		sun_color[2] = sun_diffuse[2] * timeNoon * 1.6;
		sun_color[3] = sun_diffuse[3] * timeNoon * 1.6;
		-- colorSunlight = sunrise_sun * timeSunrise  +  noon_sun * timeNoon  +  sunset_sun * timeSunset  +  midnight_sun * timeMidnight;
	end
end

-- static function: engine callback function
-- @param nPass: 0 for opache pass, 1 for alpha blended pass. 
function SuperMultiviewStereoEffect.OnRender(nPass)
	local ps_scene = ParaScene.GetPostProcessingScene();
	if(nPass == 0) then
		GameLogic.GetShaderManager():GetEffect("SuperMultiviewStereo"):OnCompositeQuadRendering(ps_scene, nPass);
	end
end

-- @param nPass: 0 for opache pass, 1 for alpha blended pass. 
function SuperMultiviewStereoEffect:OnRenderLite(ps_scene, nPass)
	local effect = ParaAsset.LoadEffectFile("SuperMultiviewStereo","script/apps/Aries/Creator/Game/Shaders/SuperMultiviewStereo.fxo");
	effect = ParaAsset.GetEffectFile("SuperMultiviewStereo");
		
	if(effect:Begin()) then
		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		local params = effect:GetParamBlock();
		params:SetParam("screenParam", "vec2ScreenSize");
		if(nPass == 0) then
			-- save the current render target
			local old_rt = ParaEngine.GetRenderTarget();
			
			-- create/get a temp render target: "_ColorRT" is an internal name 
			local _ColorRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
			
			----------------------- down sample pass ----------------
			-- copy content from one surface to another
			ParaEngine.StretchRect(old_rt, _ColorRT);
			

			local attr = ParaTerrain.GetBlockAttributeObject();
			self:ComputeShaderUniforms();
			params:SetParam("mShadowMapTex", "mat4ShadowMapTex");
			params:SetParam("mShadowMapViewProj", "mat4ShadowMapViewProj");
			params:SetParam("ShadowMapSize", "vec2ShadowMapSize");
			params:SetParam("ShadowRadius", "floatShadowRadius");
		
			params:SetParam("gbufferProjectionInverse", "mat4ProjectionInverse");
			params:SetParam("screenParam", "vec2ScreenSize");
			params:SetParam("viewportOffset", "vec2ViewportOffset");
			params:SetParam("viewportScale", "vec2ViewportScale");
			
			params:SetParam("matView", "mat4View");
			params:SetParam("matViewInverse", "mat4ViewInverse");
			params:SetParam("matProjection", "mat4Projection");
		
			params:SetParam("g_FogColor", "vec3FogColor");
			params:SetParam("ViewAspect", "floatViewAspect");
			params:SetParam("TanHalfFOV", "floatTanHalfFOV");
			params:SetParam("cameraFarPlane", "floatCameraFarPlane");
			params:SetFloat("FogStart", GameLogic.options:GetFogStart());
			params:SetFloat("FogEnd", GameLogic.options:GetFogEnd());

			params:SetFloat("timeMidnight", timeMidnight);
			local sunIntensity = attr:GetField("SunIntensity", 1);
			params:SetFloat("sunIntensity", sunIntensity);
		
			params:SetParam("gbufferWorldViewProjectionInverse", "mat4WorldViewProjectionInverse");
			params:SetParam("cameraPosition", "vec3cameraPosition");
			params:SetParam("sunDirection", "vec3SunDirection");
			params:SetParam("sunAmbient", "vec3SunAmbient");

			params:SetVector3("RenderOptions", 
				if_else(attr:GetField("UseSunlightShadowMap", false),1,0), 
				if_else(attr:GetField("UseWaterReflection", false),1,0),
				0);
			params:SetParam("TorchLightColor", "vec3BlockLightColor");
			params:SetParam("SunColor", "vec3SunColor");
								
			-----------------------compose lum texture with original texture --------------
			ParaEngine.SetRenderTarget(old_rt);
		
			if(effect:BeginPass(0)) then
				-- color render target. 
				params:SetTextureObj(0, _ColorRT);
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
			end
		end
		-- Make sure the render target isn't still set as a source texture
		-- this will prevent d3d warning in debug mode
		effect:SetTexture(0, "");
		effect:SetTexture(1, "");
		effect:SetTexture(2, "");
		effect:SetTexture(3, "");

		effect:End();
	else
		-- revert to normal effect. 
		self:GetEffectManager():SetShaders(1);
	end
end

function SuperMultiviewStereoEffect:IsHDR()
	return (self:HasBloomEffect() or self:HasDepthOfViewEffect());
end

function SuperMultiviewStereoEffect:OnCompositeQuadRendering(ps_scene, nPass)
	self:OnRenderLite(ps_scene, nPass)
end
