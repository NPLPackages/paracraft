--[[
Title: RedBlueStereo Effect
Author(s): LiXizhi
Email: lixizhi@yeah.net
Date: 2016.8.18
Desc: convert from left/right eye image to red/blue stereo image 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/RedBlueStereoEffect.lua");
local RedBlueStereoEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.RedBlueStereoEffect");
local effect = RedBlueStereoEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("RedBlueStereo");
if(effect) then
	effect:SetEnabled(true);
	effect:SetRedBlueMode();
	-- effect:SetInterfacedMode();
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local RedBlueStereoEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.RedBlueStereoEffect"));

RedBlueStereoEffect.name = "RedBlueStereo";

function RedBlueStereoEffect:ctor()
end

-- enable blur effect
function RedBlueStereoEffect:SetEnabled(bEnable)
	-- "final_composite" is internal viewport name when stereo mode is on. 
	local attr = ParaEngine.GetAttributeObject();
	local viewport = attr:GetChild("ViewportManager"):GetChild("final_composite");
	if(viewport) then
		if(bEnable ~= false) then
			if(System.os.GetPlatform()=="win32") then
				local effect = ParaAsset.GetEffectFile("RedBlueStereo");
				effect:LoadAsset();
				if(System.os.GetRendererName() == "DirectX") then
					LOG.std(nil, "info", "RedBlueStereoEffect", "loading RedBlueStereo.fx effect file, fallback to RedBlueStereo.fxo");
					effect = ParaAsset.LoadEffectFile("RedBlueStereo","script/apps/Aries/Creator/Game/Shaders/RedBlueStereo.fxo");
				end
			end
			viewport:SetField("RenderScript", "MyCompany.Aries.Game.Shaders.RedBlueStereoEffect.OnRender()");
		else
			viewport:SetField("RenderScript", "");
		end
	end
end

-- static callback function
function RedBlueStereoEffect.OnRender()
	local self = GameLogic.GetShaderManager():GetEffect(RedBlueStereoEffect.name);
	if(self) then
		self:OnRenderPostProcessing();
	end
end

-- displayed vertically left, right, left, right, ...
function RedBlueStereoEffect:SetInterfacedMode()
	self.mode = "interlaced";
end

-- this is the default mode
function RedBlueStereoEffect:SetRedBlueMode()
	self.mode = "redblue";
end

function RedBlueStereoEffect:IsInterlacedMode()
	return self.mode == "interlaced";
end

-- do the per frame scene rendering here. 
function RedBlueStereoEffect:OnRenderPostProcessing()
	local effect = ParaAsset.GetEffectFile("RedBlueStereo");
		
	if(effect:Begin()) then
		local params = effect:GetParamBlock();

		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		
		-- "_LeftViewRT" is internal left viewport image.
		local _LeftViewRT = ParaAsset.LoadTexture("_LeftViewRT", "_LeftViewRT", 0); 
			
		-- right viewport image is on "_ColorRT"
		local _RightViewRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
		
		local nPass = 0;
		if(self:IsInterlacedMode()) then
			params:SetParam("screenParam", "vec2ScreenSize");
			nPass = 1;
		end

		effect:BeginPass(nPass);
			params:SetTextureObj(0, _LeftViewRT);
			params:SetTextureObj(1, _RightViewRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end