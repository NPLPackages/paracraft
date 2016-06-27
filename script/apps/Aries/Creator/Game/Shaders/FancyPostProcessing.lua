--[[
Title: deferred shading final composite effect 
Author(s): LiXizhi
Date: 2013/10/10
Desc: Reconstructing 3d position from view space depth data and do deferred shading effect on the quad. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/FancyPostProcessing.lua");
local FancyV1 = GameLogic.GetShaderManager():GetFancyShader();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local FancyV1 = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.FancyV1"));
FancyV1:Property({"name", "Fancy",});
FancyV1:Property({"BloomEffect", false, "HasBloomEffect", "EnableBloomEffect", auto=true});
FancyV1:Property({"DepthOfViewEffect", false, "HasDepthOfViewEffect", "EnableDepthOfViewEffect", auto=true});
FancyV1:Property({"DepthOfViewFactor", 0.01, "GetDepthOfViewFactor", "SetDepthOfViewFactor", auto=true});
FancyV1:Property({"EyeBrightness", 0.5, auto=true, desc="(0-1), used for HDR tone mapping"});

FancyV1.BlockRenderMethod = {
	FixedFunction = 0,
	Standard = 1,
	Fancy = 2,
}

function FancyV1:ctor()
end

-- return true if succeed. 
function FancyV1:SetEnabled(bEnable)
	if(bEnable) then
		local res, reason = FancyV1.IsHardwareSupported();
		if(res) then
			ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingScript", "MyCompany.Aries.Game.Shaders.FancyV1.OnRender(0)")
			ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingAlphaScript", "MyCompany.Aries.Game.Shaders.FancyV1.OnRender(1)")
			ParaTerrain.GetBlockAttributeObject():SetField("UseSunlightShadowMap", true);
			ParaTerrain.GetBlockAttributeObject():SetField("UseWaterReflection", true);
			self:SetBlockRenderMethod(self.BlockRenderMethod.Fancy);
			return true;
		elseif(reason == "AA_IS_ON") then
			ParaEngine.GetAttributeObject():SetField("MultiSampleType", 0);
			ParaEngine.WriteConfigFile("config/config.txt");
			LOG.std(nil, "info", "FancyV1", "MultiSampleType must be 0 in order to use deferred shading. We have set it for you. you must restart. ");
			_guihelper.MessageBox("抗锯齿已经关闭, 请重启客户端");
		end
	else
		ParaTerrain.GetBlockAttributeObject():SetField("PostProcessingScript", "");
		self:SetBlockRenderMethod(self.BlockRenderMethod.Standard);
		return true;
	end
end

function FancyV1:IsEnabled()
	return ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1) == 2;
end

-- @param shader_method: type of BlockRenderMethod: 0 fixed function; 1 standard; 2 fancy graphics.
function FancyV1:SetBlockRenderMethod(method)
	ParaTerrain.GetBlockAttributeObject():SetField("BlockRenderMethod", method);
end

-- static function: 
function FancyV1.IsHardwareSupported()
	if( ParaTerrain.GetBlockAttributeObject():GetField("CanUseAdvancedShading", false) ) then
		-- must disable AA. 
		if(ParaEngine.GetAttributeObject():GetField("MultiSampleType", 0) ~= 0) then
			LOG.std(nil, "info", "FancyV1", "MultiSampleType must be 0 in order to use deferred shading. ");
			
			return false, "AA_IS_ON";
		end
		local effect = ParaAsset.LoadEffectFile("composite","script/apps/Aries/Creator/Game/Shaders/composite.fxo");
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
function FancyV1:ComputeShaderUniforms(bIsHDRShader)
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
function FancyV1.OnRender(nPass)
	local ps_scene = ParaScene.GetPostProcessingScene();
	GameLogic.GetShaderManager():GetFancyShader():OnCompositeQuadRendering(ps_scene, nPass);
end

-- @param nPass: 0 for opache pass, 1 for alpha blended pass. 
function FancyV1:OnRenderLite(ps_scene, nPass)
	if(nPass and nPass >= 1) then
		-- no need to alpha pass.
		return;
	end

	local effect = ParaAsset.LoadEffectFile("compositeLite","script/apps/Aries/Creator/Game/Shaders/compositeLite.fxo");
	effect = ParaAsset.GetEffectFile("compositeLite");
		
	if(effect:Begin()) then
		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 

		-- save the current render target
		local old_rt = ParaEngine.GetRenderTarget();
			
		-- create/get a temp render target: "_ColorRT" is an internal name 
		local _ColorRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
			
		----------------------- down sample pass ----------------
		-- copy content from one surface to another
		ParaEngine.StretchRect(old_rt, _ColorRT);
			
		local attr = ParaTerrain.GetBlockAttributeObject();
		local params = effect:GetParamBlock();
		self:ComputeShaderUniforms();
		params:SetParam("mShadowMapTex", "mat4ShadowMapTex");
		params:SetParam("mShadowMapViewProj", "mat4ShadowMapViewProj");
		params:SetParam("ShadowMapSize", "vec2ShadowMapSize");
		
		params:SetParam("gbufferProjectionInverse", "mat4ProjectionInverse");
		params:SetParam("screenParam", "vec2ScreenSize");
			
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
		params:SetVector3("RenderOptions", 
			if_else(attr:GetField("UseSunlightShadowMap", false),1,0), 
			if_else(attr:GetField("UseWaterReflection", false),1,0),
			0);
		params:SetParam("TorchLightColor", "vec3BlockLightColor");
		params:SetParam("SunColor", "vec3SunColor");
								
		-----------------------compose lum texture with original texture --------------
		ParaEngine.SetRenderTarget(old_rt);
		
		effect:BeginPass(0);
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


function FancyV1:OnRenderHighWithHDR(ps_scene, nPass)
	local effect = ParaAsset.LoadEffectFile("composite","script/apps/Aries/Creator/Game/Shaders/composite.fxo");
	effect = ParaAsset.GetEffectFile("composite");
		
	if(effect:Begin()) then
		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 

		-- create/get a temp render target: 
		local _ColorRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
		local _ColorRT2 = ParaAsset.LoadTexture("_ColorRT2", "_ColorRT2", 0); 
		local _HDRColorRT = ParaAsset.LoadTexture("_ColorRT_HDR", "_ColorRT_HDR", 0); 
		local _HDRColorRT2 = ParaAsset.LoadTexture("_ColorRT2_HDR", "_ColorRT2_HDR", 0);
		
		local attr = ParaTerrain.GetBlockAttributeObject();
		local params = effect:GetParamBlock();
		self:ComputeShaderUniforms(true);

		params:SetFloat("timeMidnight", timeMidnight);
		params:SetFloat("timeNoon", timeNoon);

		params:SetParam("mShadowMapTex", "mat4ShadowMapTex");
		params:SetParam("mShadowMapViewProj", "mat4ShadowMapViewProj");
		params:SetParam("ShadowMapSize", "vec2ShadowMapSize");
		
		params:SetParam("gbufferProjectionInverse", "mat4ProjectionInverse");
		params:SetParam("screenParam", "vec2ScreenSize");
			
		params:SetParam("matView", "mat4View");
		params:SetParam("matViewInverse", "mat4ViewInverse");
		params:SetParam("matProjection", "mat4Projection");
		
		params:SetParam("ViewAspect", "floatViewAspect");
		params:SetParam("TanHalfFOV", "floatTanHalfFOV");
		params:SetParam("cameraFarPlane", "floatCameraFarPlane");
		
		params:SetFloat("TimeOfDaySTD", timeOfDaySTD);

		params:SetParam("gbufferWorldViewProjectionInverse", "mat4WorldViewProjectionInverse");
		params:SetParam("cameraPosition", "vec3cameraPosition");
		params:SetParam("sunDirection", "vec3SunDirection");
		params:SetParam("g_FogColor", "vec3FogColor");

		params:SetFloat("rainStrength", math.min(1, GameLogic.options:GetRainStrength()/10));
		params:SetFloat("DepthOfViewFactor", self:GetDepthOfViewFactor());
		params:SetFloat("FogStart", GameLogic.options:GetFogStart());
		params:SetFloat("FogEnd", GameLogic.options:GetFogEnd());
		params:SetFloat("CloudThickness", GameLogic.options:GetCloudThickness());
		params:SetFloat("EyeBrightness", self:GetEyeBrightness());
		
		local effectLevel = 0;
		local UseSunlightShadowMap = attr:GetField("HasSunlightShadowMap", false)
		local UseWaterReflection = attr:GetField("UseWaterReflection", false)
		if(self:HasBloomEffect() == true) then
			effectLevel = effectLevel + 1;
		end
		if(self:HasDepthOfViewEffect() == true) then
			effectLevel = effectLevel + 1;
			local attr = ParaCamera.GetAttributeObject();
			if(attr:GetField("MaxCameraObjectDistance", 0) < 1.0) then
				-- first person view
				params:SetFloat("centerDepthSmooth", 0.0);
			else
				-- third person view
				params:SetFloat("centerDepthSmooth", attr:GetField("CameraObjectDistance", 10));
			end
		end
		params:SetVector3("RenderOptions", 
			1, -- UseSunlightShadowMap (can not be turned off)
			1, -- UseWaterReflection (can not be turned off)
			effectLevel);
		params:SetParam("TorchLightColor", "vec3BlockLightColor");

		params:SetVector3("SunColor", sun_color[1], sun_color[2], sun_color[3]);
		
		if(nPass == 0) then
			-- save the current render target
			self.old_rt = ParaEngine.GetRenderTarget();
			-- copy content from one surface to another
			ParaEngine.StretchRect(self.old_rt, _ColorRT);

			-----------------------compose lum texture with original texture --------------
			ParaEngine.SetRenderTarget(_HDRColorRT);
			ParaEngine.SetRenderTarget(1, "_ColorRT2");

			-- composite 0: calculate real color to HDR
			effect:BeginPass(0);
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
			ParaEngine.SetRenderTarget(1, "");

		elseif(nPass >= 1) then
			-- Make sure the render target isn't still set as a source texture. this will prevent d3d warning in debug mode
			effect:SetTexture(0, "");

			if(self:HasBloomEffect() or self:HasDepthOfViewEffect()) then
				-- composite 1: do surface reflection
				ParaEngine.SetRenderTarget(_HDRColorRT2);
				effect:BeginPass(1);
					params:SetTextureObj(0, _HDRColorRT);
					-- depth channel is now color 2
					params:SetTextureObj(2, _ColorRT2);
					-- normal texture 
					params:SetTextureObj(4, ParaAsset.LoadTexture("_NormalRT", "_NormalRT", 0));
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();

				-- Make sure the render target isn't still set as a source texture. this will prevent d3d warning in debug mode
				effect:SetTexture(0, "");
		
				--[[
				-- composite 2(pre): downsize and prepare glow texture. 1/4 of original size
				local _GlowRT = ParaAsset.LoadTexture("_GlowRT_HDR", "_GlowRT_HDR", 0); 
				_GlowRT:SetSize(_HDRColorRT:GetWidth()/4, _HDRColorRT:GetHeight()/4);
				ParaEngine.SetRenderTarget(_GlowRT);
				effect:BeginPass(4);
					params:SetTextureObj(0, _HDRColorRT2);
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();
				effect:SetTexture(0, "");
				]]

				-- composite 2: calculate bloom
				ParaEngine.SetRenderTarget(_HDRColorRT);
				effect:BeginPass(2);
					-- params:SetTextureObj(0, _GlowRT);
					params:SetTextureObj(0, _HDRColorRT2);
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();
			
				-- Make sure the render target isn't still set as a source texture. this will prevent d3d warning in debug mode
				effect:SetTexture(0, "");
		
				-- composite 3 final: render back to render target. 
				ParaEngine.SetRenderTarget(self.old_rt);
				self.old_rt = nil;
				effect:BeginPass(3);
					-- bloom color
					params:SetTextureObj(0, _HDRColorRT);
					-- composite texture
					params:SetTextureObj(5, _HDRColorRT2);
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();
			else
				-- composite 1: do surface reflection
				ParaEngine.SetRenderTarget(_HDRColorRT2);
				effect:BeginPass(1);
					params:SetTextureObj(0, _HDRColorRT);
					-- depth channel is now color 2
					params:SetTextureObj(2, _ColorRT2);
					-- normal texture 
					params:SetTextureObj(4, ParaAsset.LoadTexture("_NormalRT", "_NormalRT", 0));
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();
				-- Make sure the render target isn't still set as a source texture. this will prevent d3d warning in debug mode
				effect:SetTexture(0, "");

				-- composite 3 final: render back to render target. 
				ParaEngine.SetRenderTarget(self.old_rt);
				self.old_rt = nil;
				effect:BeginPass(3);
					-- composite texture
					params:SetTextureObj(5, _HDRColorRT2);
					effect:CommitChanges();
					ParaEngine.DrawQuad();
				effect:EndPass();
			end
			effect:SetTexture(0, "");
		end
		-- Make sure the render target isn't still set as a source texture. this will prevent d3d warning in debug mode
		effect:SetTexture(1, "");
		effect:SetTexture(2, "");
		effect:SetTexture(3, "");
		effect:SetTexture(4, "");
		effect:SetTexture(5, "");

		effect:End();

		if(nPass == 0) then
			ParaEngine.SetRenderTarget(_HDRColorRT);
		end
	else
		-- revert to normal effect. 
		self:GetEffectManager():SetShaders(1);
	end
end

function FancyV1:IsHDR()
	return (self:HasBloomEffect() or self:HasDepthOfViewEffect());
end

function FancyV1:OnCompositeQuadRendering(ps_scene, nPass)
	if(self:IsHDR()) then
		self:OnRenderHighWithHDR(ps_scene, nPass);
	else
		self:OnRenderLite(ps_scene, nPass)
	end
end
