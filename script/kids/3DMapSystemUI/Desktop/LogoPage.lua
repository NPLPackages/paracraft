--[[
Title: Logo page UI, 
Author(s): LiXizhi
Date: 2008.6.18
Desc: this page is shown when application starts or exits. User needs to press anykey to exit. Press P key to pause.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/LogoPage.lua");
-- it will only be shown for once. subsequent calls do nothing. 
Map3DSystem.UI.Desktop.LogoPage.Show()
-- show custom logo
Map3DSystem.UI.Desktop.LogoPage.Show(79, {
	{name = "LogoPage_PE_bg", bg="Texture/3DMapSystem/Loader/loading_bg.png", alignment = "_fi", left=0, top=0, width=0, height=0, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
	{name = "LogoPage_PE_logoTxt", bg="Texture/3DMapSystem/brand/ParaEngineLogoText.png", alignment = "_rb", left=-512, top=-32, width=512, height=32, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
	{name = "LogoPage_PE_logo", bg="Texture/3DMapSystem/brand/paraworld_text_256X128.png", alignment = "_ct", left=-256/2, top=-128/2, width=256, height=128, color="255 255 255 0", anim="script/kids/3DMapSystemUI/Desktop/Motion/Logo_motion.xml"},
	{name = "LogoPage_product_cover", bg="Texture/3DMapSystem/brand/ParaworldPoster.png;0 0 878 486", alignment = "_ct", left=-878/2, top=-486/2, width=878, height=486, color="255 255 255 0", anim="script/kids/3DMapSystemUI/Desktop/Motion/MainPoster_motion.xml"},
})
------------------------------------------------------------
]]
-- common control library
NPL.load("(gl)script/ide/OneTimeAsset.lua");
NPL.load("(gl)script/ide/Motion/AnimatorEngine.lua");
local LogoPage = {};
commonlib.setfield("Map3DSystem.UI.Desktop.LogoPage", LogoPage)

LogoPage.Name = "ParaWorldUI_logo_cont";
LogoPage.KeyDownCount = nil;

-- When the user clicks or key down, the animation is immediately set to this frame. This is usually the longest (last) frame in the animation files.
-- this value is based on all of its motion xml,you need to have to look at all of its motion xml before you set it value 
LogoPage.KeyTime = 79;
-- UI layers
LogoPage.items = {
	{name = "LogoPage_PE_bg", bg="Texture/3DMapSystem/Loader/loading_bg.png", alignment = "_fi", left=0, top=0, width=0, height=0, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
	{name = "LogoPage_PE_logoTxt", bg="Texture/3DMapSystem/brand/ParaEngineLogoText.png", alignment = "_rb", left=-512, top=-32, width=512, height=32, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},
	{name = "LogoPage_PE_logo", bg="Texture/3DMapSystem/brand/paraworld_text_256X128.png", alignment = "_ct", left=-256/2, top=-128/2, width=256, height=128, color="255 255 255 0", anim="script/kids/3DMapSystemUI/Desktop/Motion/Logo_motion.xml"},
	{name = "LogoPage_product_cover", bg="Texture/3DMapSystem/brand/ParaworldPoster.png;0 0 878 486", alignment = "_ct", left=-878/2, top=-486/2, width=878, height=486, color="255 255 255 0", anim="script/kids/3DMapSystemUI/Desktop/Motion/MainPoster_motion.xml"},
}
-- if true, the logo will exit to windows when finished, otherwise it just closes itself. 
LogoPage.Exiting = nil;

LogoPage.engine = nil;
LogoPage.Create = nil;
LogoPage.isGoto = false;

-- it will only be shown for once. subsequent calls do nothing. if inputs are nil,  the default logo page is shown
-- @param LastAnimFrame: When the user clicks or key down, the animation is immediately set to this frame. This is usually the longest (last) frame in the animation files.
-- @param items: array of UI layers. e.g.{ {name = "LogoPage_PE_bg", bg="Texture/3DMapSystem/Loader/loading_bg.png", alignment = "_fi", left=0, top=0, width=0, height=0, color="255 255 255 255", anim="script/kids/3DMapSystemUI/Desktop/Motion/Bg_motion.xml"},}
function LogoPage.Show(LastAnimFrame, items)
	if(LogoPage.Create == nil) then
		if(LastAnimFrame~=nil) then
			LogoPage.KeyTime = LastAnimFrame;
		end
		if(items~=nil) then
			LogoPage.items = items;
		end
		LogoPage.Create = true;
		LogoPage.Init()		
	end
end
function LogoPage.Init()
	ParaUI.Destroy(LogoPage.Name);
	local _this, _parent;
	-- this allows any key to continue
	ParaScene.RegisterEvent("_k_logopage_keydown", ";Map3DSystem.UI.Desktop.LogoPage.OnKeyDown();");
	_parent=ParaUI.CreateUIObject("container",LogoPage.Name, "_fi",0,0,0,0);
	_parent.background="";
	_parent.zorder=2;
	_parent:AttachToRoot();	
	--
	-- create UI controls
	--		
	local _, info;
	for _, info in ipairs(LogoPage.items) do
		_this=ParaUI.CreateUIObject("container",info.name, info.alignment,info.left,info.top,info.width,info.height);
		if(info.bg) then
			_this.background=info.bg;
			CommonCtrl.OneTimeAsset.Add(info.name, info.bg)
		end
		if(info.color) then
			_this.color=info.color;
		end	
		_parent:AddChild(_this);
	end
	
	-- any mouse click to continue, this is rather application specific, remove this line.
	_this=ParaUI.CreateUIObject("button","b", "_fi",0,0,0,0);
	_parent:AddChild(_this);
	_this.background="Texture/whitedot.png;0 0 0 0";
	_this.onclick = ";Map3DSystem.UI.Desktop.LogoPage.OnKeyDown()";
	
	--
	-- bind it to animation engine
	--
	local engine = CommonCtrl.Motion.AnimatorEngine:new();

	local animatorManager = CommonCtrl.Motion.AnimatorManager:new();
	
	local animator,layerManager;
	
	for _, info in ipairs(LogoPage.items) do
		animator = CommonCtrl.Motion.Animator:new();
		animator:Init(info.anim, info.name);
		layerManager = CommonCtrl.Motion.LayerManager:new();	 

		layerManager:AddChild(animator);
		animatorManager:AddChild(layerManager);
	end
	
	--set AnimatorManager value must be at last  
	engine:SetAnimatorManager(animatorManager);

	engine.OnMotionEnd = LogoPage.OnEnd;
	engine.OnTimeChange = LogoPage.OnTimeChange;

	engine:doPlay();
	LogoPage.engine = engine;
end
function LogoPage.OnTimeChange(sControlName,time)
	if(time == LogoPage.KeyTime)then
		LogoPage.isGoto =true; 
		main_state=nil;
		ParaUI.GetUIObject(LogoPage.Name).enabled = false;
	end
end	

function LogoPage.OnEnd()	
	LogoPage.Exit()
end

function LogoPage.OnKeyDown()	
	if(virtual_key == Event_Mapping.EM_KEY_P) then
		-- pause at the logo page
		if(not LogoPage.isPaused)then
			LogoPage.isPaused = true;
			LogoPage.engine:doPause();
		else
			LogoPage.isPaused = nil;
			LogoPage.engine:doResume();
		end
	else	
		if(LogoPage.isGoto ==false)then				
			LogoPage.engine:gotoAndPlay(LogoPage.KeyTime);	
		end
	end
end
function LogoPage.Exit()
	ParaUI.Destroy(LogoPage.Name);
	ParaScene.UnregisterEvent("_k_logopage_keydown");
	
	local _, info;
	for _, info in ipairs(LogoPage.items) do
		if(info.bg) then
			CommonCtrl.OneTimeAsset.Add(info.name, nil)
		end
	end
end
