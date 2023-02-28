--[[
Title: ODSStereo Effect
Author(s): hyz
Email: 
Date: 2022.18.48
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Shaders/ODSStereoEffect.lua");
local ODSStereoEffect = commonlib.gettable("MyCompany.Aries.Game.Shaders.ODSStereoEffect");
local effect = ODSStereoEffect:new():Init(effect_manager, name);
local effect = GameLogic.GetShaderManager():GetEffect("ODSStereo");
if(effect) then
	effect:SetEnabled(true);
end
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local ODSStereoEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.ODSStereoEffect"));

ODSStereoEffect.name = "ODSStereo";

local viewPortManager;
local stereoMode;
local frame_size;
local cubeTextureRect = {0,0,1,1};--立方体的6张贴图的实际区域（不一定等于全屏的）

local needCompositeUI = false;--是否需要合成UI
local dftTextureRect = {0,0,1,1};--默认UI和3D场景的纹理区域
local ui_fov_v = 60*math.pi/180;
local ui_fov_h = 90*math.pi/180;

ODSStereoEffect.isIgnoreUI = false;

function ODSStereoEffect:ctor()
end

function ODSStereoEffect.SetIsIgnoreUI(val)
	ODSStereoEffect.isIgnoreUI = val
	if GameLogic.options:IsSingleEyeOdsStereo() then
		local effect = GameLogic.GetShaderManager():GetEffect("ODSStereo");
		if(effect) then
			effect:SetEnabled(effect._bEnable);
		end
	end

	local frame_size = {System.Windows.Screen:GetWindowSolution()}

	local cubeWidth = math.floor(frame_size[1]/4) --立方体宽度
	local cubeTextureRect = {0,0,cubeWidth*4/frame_size[1],cubeWidth*2/frame_size[2]};

	return frame_size[2] - cubeWidth*2>200
end

-- 重新排版ods_render_target
function ODSStereoEffect:SetEnabled(bEnable)
	self._bEnable = bEnable
	frame_size = {System.Windows.Screen:GetWindowSolution()}
	viewPortManager = ParaEngine.GetAttributeObject():GetChild("ViewportManager")
	
	stereoMode = viewPortManager:GetField("layout")

	if GameLogic.options:IsSingleEyeOdsStereo() then
		local viewport = viewPortManager:GetChild("ods_final_composite");
		if(viewport) then
			if(bEnable ~= false) then
				viewport:SetField("RenderScript", "MyCompany.Aries.Game.Shaders.ODSStereoEffect.OnRenderSingleEye_1()");
			else
				viewport:SetField("RenderScript", "");
			end
		end
		local cubeWidth = math.floor(frame_size[1]/4) --立方体宽度
		cubeTextureRect = {0,0,cubeWidth*4/frame_size[1],cubeWidth*2/frame_size[2]};

		needCompositeUI = frame_size[2] - cubeWidth*2>200
		if needCompositeUI then
			--正常区域
			local aspect = math.tan(ui_fov_h / 2) / math.tan(ui_fov_v / 2)
			local _width = cubeWidth*2;
			local _height = cubeWidth
			if _width>_height*aspect then
				_width = math.floor(_height*aspect)
			else
				_height = math.floor(_width/aspect)
			end

			dftTextureRect = {cubeTextureRect[3]/2,cubeTextureRect[4]/2,_width/frame_size[1],_height/frame_size[2]}
		end
		if ODSStereoEffect.isIgnoreUI then
			needCompositeUI = false
		end
		if cubeWidth*4~=frame_size[1] or cubeWidth*2~=frame_size[2] then
			-- GameLogic.RunCommand("/shader 1")
		end
	else
		ODSStereoEffect.isIgnoreUI = false
		-- ODSStereoEffect._super.SetEnabled(self, bEnable);
	end 

end

-- static callback function
function ODSStereoEffect.OnRenderSingleEye_1()
	local self = GameLogic.GetShaderManager():GetEffect(ODSStereoEffect.name);
	if(self) then
		self:OnRenderPostProcessingSingle_1();
	end
end

local debugAcc = 0
function ODSStereoEffect:OnRenderPostProcessingSingle_1()
	local effect;
	ParaAsset.LoadEffectFile("ODSStereoSingleEye","script/apps/Aries/Creator/Game/Shaders/ODSStereoSingleEye.fxo");
	effect = ParaAsset.GetEffectFile("ODSStereoSingleEye");
	-- if true then
	-- 	ParaAsset.LoadEffectFile("ODSStereo","script/apps/Aries/Creator/Game/Shaders/ODSStereo.fxo");
	-- 	effect = ParaAsset.GetEffectFile("ODSStereo");
	-- end

	if(effect:Begin()) then
		local params = effect:GetParamBlock();

		-- 0 stands for S0_POS_TEX0,  all data in stream 0: position and tex0
		ParaEngine.SetVertexDeclaration(0); 
		
		-- create/get a temp render target: "_ColorRT" is an internal name 
		local _ColorRT = ParaAsset.LoadTexture("_ColorRT", "_ColorRT", 0); 
		
		local old_rt = ParaEngine.GetRenderTarget();
		ParaEngine.StretchRect(old_rt, _ColorRT);

		-- debugAcc = debugAcc + 1
		-- GameLogic.AddBBS(1,"debugAcc:"..tostring(debugAcc))
		-- if debugAcc%100==0 then
		-- 	_ColorRT:SaveTextureToPNG("D:/work/test_fx__ColorRT.png",1280,1280)
		-- end
			
		params:SetParam("screenParam", "vec2ScreenSize");
		params:SetVector4("cubeTextureRect",cubeTextureRect[1],cubeTextureRect[2],cubeTextureRect[3],cubeTextureRect[4]);

		params:SetBoolean("needCompositeUI",needCompositeUI)
		if needCompositeUI then
			params:SetVector4("dftTextureRect",dftTextureRect[1],dftTextureRect[2],dftTextureRect[3],dftTextureRect[4]);
			params:SetFloat("ui_fov_v",ui_fov_v)
			params:SetFloat("ui_fov_h",ui_fov_h)
		end

		effect:BeginPass(0);
			params:SetTextureObj(0, _ColorRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end