--[[
Title: ODSStereo Effect
Author(s): hyz, lixizhi
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
ODSStereoEffect.SetDebugMode(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ShaderEffectBase.lua");
local ODSStereoEffect = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Effects.ShaderEffectBase"), commonlib.gettable("MyCompany.Aries.Game.Shaders.ODSStereoEffect"));

ODSStereoEffect.name = "ODSStereo";

local cubeTextureRect = {0,0,1,1};

local needCompositeUI = false;
local dftTextureRect = {0,0,1,1};
local ui_fov_v = 60*math.pi/180;
local ui_fov_h = 90*math.pi/180;

ODSStereoEffect.isIgnoreUI = false;

function ODSStereoEffect:ctor()
end

function ODSStereoEffect.SetDebugMode(bIsDebugMode)
	ODSStereoEffect.bIsDebugMode = bIsDebugMode == true;
end

-- adjust screen resolution to display for ods single eye, this is usually a square resolution like 1280*1280
-- @param callbackFunc: called when screen is adjusted to N*N
function ODSStereoEffect.AutoAdjustODS_SingleResolution(callbackFunc)
	local att = ParaEngine.GetAttributeObject();
	local oldsize = att:GetField("ScreenResolution", {1280,720});
	if (oldsize[2] - oldsize[1]/2) < 200 then
		att:SetField("ScreenResolution", {oldsize[1],oldsize[1]}); 
		att:CallField("UpdateScreenMode");
		commonlib.TimerManager.SetTimeout(function()
			ODSStereoEffect.AutoAdjustODS_SingleResolution(callbackFunc)
		end, 200)
	else
		if(callbackFunc) then
			callbackFunc(true);
		end
	end
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

	local cubeWidth = math.floor(frame_size[1]/4)
	local cubeTextureRect = {0,0,cubeWidth*4/frame_size[1],cubeWidth*2/frame_size[2]};

	return frame_size[2] - cubeWidth*2>200
end

-- set layout to ods_render_target
function ODSStereoEffect:SetEnabled(bEnable)
	self._bEnable = bEnable
	local frame_size = {System.Windows.Screen:GetWindowSolution()}
	local viewPortManager = ParaEngine.GetAttributeObject():GetChild("ViewportManager")
	
	local stereoMode = viewPortManager:GetField("layout")

	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	if(viewport) then
		viewport:SetAlignment(bEnable and "_lt" or "_fi");
	end

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

		effect:BeginPass(ODSStereoEffect.bIsDebugMode and 1 or 0);
			params:SetTextureObj(0, _ColorRT);
			effect:CommitChanges();
			ParaEngine.DrawQuad();
		effect:EndPass();
			
		effect:End();
	end
end