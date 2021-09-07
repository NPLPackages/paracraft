NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local CartoonEffect = commonlib.inherit(
    commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), 
    commonlib.gettable("MyCompany.Aries.Game.Shaders.CartoonEffect"));
CartoonEffect.name = "Cartoon";

function CartoonEffect:ctor()
end

-- priority in shader effect
function CartoonEffect:GetPriority()
	return -1;
end

--virtual function:
function CartoonEffect:SetEnabled(bEnable)
	CartoonEffect._super.SetEnabled(self, bEnable);
end

-- do the per frame scene rendering here. 
function CartoonEffect:OnRenderPostProcessing(ps_scene)
	local effect = ParaAsset.LoadEffectFile("Cartoon","script/apps/Aries/Creator/Game/Shaders/CartoonEffect.fxo");
	effect = ParaAsset.GetEffectFile("Cartoon");
		
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