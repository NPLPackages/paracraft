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

-- do the per frame scene rendering here. 
function RedBlueStereoEffect:OnRenderPostProcessing()
	local effect = ParaAsset.LoadEffectFile("RedBlueStereo","script/apps/Aries/Creator/Game/Shaders/RedBlueStereo.fxo");
	effect = ParaAsset.GetEffectFile("RedBlueStereo");
		
	if(effect:Begin()) then
		local params = effect:GetParamBlock();

		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		
		-- save the current render target
		local old_rt = ParaEngine.GetRenderTarget();
		
		-- "_LeftViewRT" is internal left viewport image.
		local _LeftViewRT = ParaAsset.LoadTexture("_LeftViewRT", "_LeftViewRT", 0); 
			
		-- right viewport image is on backbuffer
		local _RightViewRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
		ParaEngine.StretchRect(old_rt, _RightViewRT);
		
		ParaEngine.SetRenderTarget(old_rt);
		effect:BeginPass(0);
			params:SetTextureObj(0, _LeftViewRT);
			params:SetTextureObj(1, _RightViewRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end