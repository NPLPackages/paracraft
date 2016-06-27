--[[
Title: TerraFormPage
Author(s): LiXizhi
Date: 2009/1/29
Desc: Instructions:
	- click a filter to transform the terrain
	- press esc key to exit editing mode
	- use -/+ key to scale brush size
	- hold and click/drag on terrain surface to repeatedly apply terrain filter. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/TerraFormPage.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

local TerraFormPage = commonlib.gettable("MyCompany.Aries.Creator.TerraFormPage")

NPL.load("(gl)script/apps/Aries/Creator/Env/TerrainBrush.lua");

-- singleton page instance. 
local page;

-- Terrain texture db table
TerraFormPage.terrainFilterList = {
	{filtername = "GaussianHill", heightScaleSign=1, tooltip="增加地面高度", icon="Texture/Aries/Creator/raise64_32bits.png"},
	{filtername = "GaussianHill", heightScaleSign=-1, tooltip="降低地面高度", icon="Texture/Aries/Creator/dig64_32bits.png"},
	{filtername = "Flatten", tooltip="铲平地面到人物高度", icon="Texture/Aries/Creator/flatten64_32bits.png"},
	{filtername = "Ramp", tooltip="制造斜面：按住鼠标左键从低处向高处拖拽", icon="Texture/Aries/Creator/sloop64_32bits.png"},
	
	{filtername = "Roughen_Smooth", bRoughen=false, tooltip="平滑", icon="Texture/Aries/Creator/smooth64_32bits.png"},
	{filtername = "Roughen_Smooth", bRoughen=true, tooltip="锐化", icon="Texture/Aries/Creator/rough64_32bits.png"},
	{filtername = "RadialScale", heightScaleSign=1, tooltip="四面环山", icon="Texture/Aries/Creator/waterup64_32bits.png"},
	{filtername = "RadialScale", heightScaleSign=-1, tooltip="反向四面环山", icon="Texture/Aries/Creator/waterlower64_32bits.png"},
	--{filtername = "SetHole", tooltip="制造山洞", icon="Texture/Aries/Creator/nowater64_32bits.png"},
	
};

-- selected index. 
TerraFormPage.SelectedIndex = nil;
-- return current filter params or nil.
function TerraFormPage.GetCurFilter()
	if(TerraFormPage.SelectedIndex~=nil) then
		return TerraFormPage.terrainFilterList[TerraFormPage.SelectedIndex]
	end	
end

-- how many milliseconds to paint repeatedly when user hold the key. 
TerraFormPage.PaintTimerInterval = 100;

-- default brushes
local defaultBrushes = {
	{
		BrushSize = 5, 
		BrushStrength = 0.1,
		BrushSoftness = 0.5,
	},
	{
		BrushSize = 10, 
		BrushStrength = 0.1,
		BrushSoftness = 0.5,
	},
	{
		BrushSize = 25, 
		BrushStrength = 0.1,
		BrushSoftness = 0.5,
	},
};

local DefaultBrush = MyCompany.Aries.Creator.TerrainBrush:new({})
-- current brush
TerraFormPage.CurBrush = DefaultBrush;

function TerraFormPage.DS_TerrainTex_Func(index)
	if(index == nil) then
		return #(TerraFormPage.terrainFilterList);
	else
		return TerraFormPage.terrainFilterList[index];
	end	
end

-- called to init page
function TerraFormPage.OnInit()
	page = document:GetPageCtrl();
	NPL.load("(gl)script/apps/Aries/Creator/Env/SwitchEnvEditorMode.lua");
	MyCompany.Aries.Creator.SwitchEnvEditorMode("TerraFormPage");

	if(TerraFormPage.SelectedIndex~=nil) then
		-- make the params blocks visible according to currently selected filter
		local filtername = TerraFormPage.terrainFilterList[TerraFormPage.SelectedIndex].filtername;
		TerraFormPage.CurBrush = MyCompany.Aries.Creator.TerrainBrush.Brushes[filtername] or DefaultBrush
		
		local paramBlocks = {"GaussianHill","Flatten"}
		local _, blockName;
		for _, blockName in ipairs(paramBlocks) do
			local node = page:GetNode(blockName);
			if(node) then
				if(blockName ~= filtername) then
					node:SetAttribute("display", "none")
				else
					node:SetAttribute("display", "")
				end
			end	
		end
		
		TerraFormPage.BeginEditing();
	end
	
	page:SetNodeValue("BrushSize", TerraFormPage.CurBrush.BrushSize);
	page:SetNodeValue("BrushStrength", TerraFormPage.CurBrush.BrushStrength);
	page:SetNodeValue("BrushSoftness", TerraFormPage.CurBrush.BrushSoftness);
	
	page:SetNodeValue("FlattenOperation", tostring(TerraFormPage.CurBrush.FlattenOperation));
	page:SetNodeValue("Elevation", TerraFormPage.CurBrush.Elevation);
	page:SetNodeValue("HeightScale", TerraFormPage.CurBrush.HeightScale);
	page:SetNodeValue("gaussian_deviation", TerraFormPage.CurBrush.gaussian_deviation);
end

------------------------
-- page events
------------------------

-- Close the page
function TerraFormPage.OnClose()
	TerraFormPage.EndEditing()
end

-- reset the page
function TerraFormPage.OnReset()
	TerraFormPage.EndEditing();
	page:Refresh(0);
end

-- selected a detail terrain filter to paint.
-- @param index: if nil, it will select nothing
function TerraFormPage.OnSelectFilter(index)
	if(TerraFormPage.SelectedIndex ~= index or index~=nil) then
		TerraFormPage.SelectedIndex = index;
		if(index) then
			local tex = TerraFormPage.terrainFilterList[index];
			if(tex) then
				local filtername = tex.filtername;
				if(filtername) then
					TerraFormPage.UpdateCurrentBrush({filtername = filtername});
					if(filtername == "Flatten") then
						-- tricky: click to set current elevation to current player's height. 
						TerraFormPage.OnSetElevationToCur()
					end
					TerraFormPage.BeginEditing()
				end	
			end	
		else
			TerraFormPage.EndEditing()
		end
		page:Refresh(0);
	end	
end

function TerraFormPage.OnDeselectFilter()
	TerraFormPage.OnSelectFilter(nil)
end

function TerraFormPage.OnSetBrushSoftness(value)
	TerraFormPage.UpdateCurrentBrush({BrushSoftness = value});
end

function TerraFormPage.OnSetBrushStrength(value)
	TerraFormPage.UpdateCurrentBrush({BrushStrength = value});
end

function TerraFormPage.OnSetBrushSize(value)
	TerraFormPage.UpdateCurrentBrush({BrushSize = value});
end

function TerraFormPage.OnSetGaussianDeviation(value)
	TerraFormPage.UpdateCurrentBrush({gaussian_deviation = value});
end

function TerraFormPage.OnSetHeightScale(value)
	TerraFormPage.UpdateCurrentBrush({HeightScale = value});
end

function TerraFormPage.OnSetFlattenOperation(name, value)
	local op = tonumber(value);
	if(op) then
		TerraFormPage.UpdateCurrentBrush({FlattenOperation = op});
	end
end

function TerraFormPage.OnElevationChanged(value)
	TerraFormPage.UpdateCurrentBrush({Elevation = value});
	-- tricky: we will modify the default elevation of the flatten brush, since the current brush is not flatten brush yet when this function is called.
	MyCompany.Aries.Creator.TerrainBrush.Brushes["Flatten"].Elevation = value;
end

-- lock flatten elevation
function TerraFormPage.OnLockElevation(value)
	if(value) then
		TerraFormPage.LockFlattenElevation = true;
	else
		TerraFormPage.LockFlattenElevation = false;
	end
end

function TerraFormPage.OnSetElevationToCur()
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	local old_value = page:GetValue("Elevation");
	if(old_value ~= y) then
		page:SetValue("Elevation", y);
		TerraFormPage.OnElevationChanged(y)
	end
end

function TerraFormPage.OnClickBrush(btnName)
	local brushIndex = tonumber(btnName)
	if(brushIndex~=nil) then
		local brush = defaultBrushes[brushIndex];
		TerraFormPage.UpdateCurrentBrush(brush, true);
	end
end

function TerraFormPage.OnSetBrushRepeatInterval(value)
	TerraFormPage.PaintTimerInterval = math.floor((1-value)*1000);
end

------------------------
-- public methods
------------------------

-- when user select a tool it will enter 3d editing mode, where the miniscenegraph should draw markers
function TerraFormPage.BeginEditing()
	TerraFormPage.mytimer = TerraFormPage.mytimer or commonlib.Timer:new({callbackFunc = TerraFormPage.OnBrushTimer})
	ParaCamera.GetAttributeObject():SetField("EnableMouseLeftButton", false)
	TerraFormPage.RegisterHooks()
end
-- when user pressed esc key, it will quit the 3d editing mode. and the mini scenegraph should be deleted. 
function TerraFormPage.EndEditing()
	ParaCamera.GetAttributeObject():SetField("EnableMouseLeftButton", true)
	TerraFormPage.UnregisterHooks()
	TerraFormPage.OnSelectFilter(nil);
	TerraFormPage.CurBrush:ClearMarker();
	if(TerraFormPage.mytimer) then
		-- kill timer
		TerraFormPage.mytimer:Change();
	end
end

-- update the terrain brush. it will also cause the marker to be redrawn. 
-- @param brush: {x,y,z,BrushSize,BrushSoftness, BrushStrength}, all fields can be nil. 
-- @param bRefreshUI: if true the UI will be updated according to input
function TerraFormPage.UpdateCurrentBrush(brush, bRefreshUI)
	if(brush) then
		commonlib.partialcopy(TerraFormPage.CurBrush, brush);
	end
	
	-- validate data
	if(TerraFormPage.CurBrush.BrushSize < 2) then
		TerraFormPage.CurBrush.BrushSize = 2;
	end
	
	if(bRefreshUI) then
		page:SetUIValue("BrushSize", TerraFormPage.CurBrush.BrushSize);
		page:SetUIValue("BrushStrength", TerraFormPage.CurBrush.BrushStrength);
		page:SetUIValue("BrushSoftness", TerraFormPage.CurBrush.BrushSoftness);
	end	
	
	TerraFormPage.RefreshMarker();
end

-- refresh the marker. 
function TerraFormPage.RefreshMarker()
	if(TerraFormPage.SelectedIndex~=nil) then
		TerraFormPage.CurBrush:RefreshMarker();
	end
end

function TerraFormPage.RegisterHooks()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraForm_mouse_down_hook", appName = "input", wndName = "mouse_down", 
		callback = TerraFormPage.OnMouseDown});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraForm_mouse_move_hook", appName = "input", wndName = "mouse_move",
		callback = TerraFormPage.OnMouseMove});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraForm_mouse_up_hook", appName = "input", wndName = "mouse_up",
		callback = TerraFormPage.OnMouseUp});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraForm_key_down_hook", appName = "input", wndName = "key_down",
		callback = TerraFormPage.OnKeyDown});
end

function TerraFormPage.UnregisterHooks()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraForm_mouse_down_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraForm_mouse_move_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraForm_mouse_up_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraForm_key_down_hook", hookType = hookType});
end

------------------------
-- input hooked event handler
------------------------
function TerraFormPage.OnMouseDown(nCode, appName, msg)
	if(nCode==nil) then return end
	local input = Map3DSystem.InputMsg;
	
	if(input.mouse_button == "left") then
		if(TerraFormPage.mytimer) then
			TerraFormPage.mytimer:Change(0, TerraFormPage.PaintTimerInterval)
		end
		local filter = TerraFormPage.GetCurFilter()
		if(filter.filtername == "Ramp") then
			local pt = ParaScene.MousePick(70, "walkpoint"); -- pick a object
			if(pt:IsValid())then
				local x,y,z = pt:GetPosition();
				TerraFormPage.CurBrush.x1 = x;
				TerraFormPage.CurBrush.z1 = z;
			end	
		end
		return;
	elseif(input.mouse_button == "right") then	
		if(input.dragDist<=5) then 
			-- exit editing mode. 
			TerraFormPage.EndEditing();
			return;
		end
	end
	
	return nCode; 
end
function TerraFormPage.OnMouseMove(nCode, appName, msg)
	if(nCode==nil) then return end
	
	local input = Map3DSystem.InputMsg;
	
	local pt = ParaScene.MousePick(70, "point"); -- pick a object
	if(pt:IsValid())then
		local x,y,z = pt:GetPosition();
		TerraFormPage.UpdateCurrentBrush({x=x,y=y,z=z});
		return;
	end	
	return nCode; 
end
function TerraFormPage.OnMouseUp(nCode, appName, msg)
	if(nCode==nil) then return end
	local input = Map3DSystem.InputMsg;
	
	if(TerraFormPage.mytimer) then
		TerraFormPage.mytimer:Change()
	end
	
	local filter = TerraFormPage.GetCurFilter()
	if(input.mouse_button == "left") then
		if(filter.filtername == "Ramp") then
			TerraFormPage.ApplyCurFilter();
			TerraFormPage.CurBrush.x1 = nil;
			TerraFormPage.CurBrush.z1 = nil;
		end
		return;
	end	
	
	return nCode; 
end
function TerraFormPage.OnKeyDown(nCode, appName, msg)
	if(nCode==nil) then return end
	if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_ESCAPE))then
		-- exit editing mode. 
		TerraFormPage.EndEditing();
		return;
	elseif(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_EQUALS))then
		-- DoScaling +
		TerraFormPage.UpdateCurrentBrush({BrushSize = TerraFormPage.CurBrush.BrushSize + 0.2});
		return;
	elseif(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_MINUS))then
		-- DoScaling -
		TerraFormPage.UpdateCurrentBrush({BrushSize = TerraFormPage.CurBrush.BrushSize - 0.2});
		return;
	end	
	return nCode; 
end

-- apply the current filter
function TerraFormPage.ApplyCurFilter()
	local filter = TerraFormPage.GetCurFilter()
	if(not filter or not TerraFormPage.CurBrush.filtername) then
		TerraFormPage.EndEditing();
	end	
	local brush = {
		type = filter.filtername,
		x=TerraFormPage.CurBrush.x,
		y=TerraFormPage.CurBrush.y,
		z=TerraFormPage.CurBrush.z,
		radius = TerraFormPage.CurBrush.BrushSize,
		BrushStrength = TerraFormPage.CurBrush.BrushStrength,
		smooth_factor = (1-TerraFormPage.CurBrush.BrushSoftness),
		
		-- for roughen and smoothing
		bRoughen = filter.bRoughen,
		bIsHole = TerraFormPage.CurBrush.BrushStrength <= 0.5,
		-- whether to use big filter grid in roughen and smoothing
		big_grid = TerraFormPage.CurBrush.BrushStrength > 0.5,
		Elevation = TerraFormPage.CurBrush.Elevation,
		heightScale = (filter.heightScaleSign or 1)*TerraFormPage.CurBrush.HeightScale * TerraFormPage.CurBrush.BrushStrength,
		gaussian_deviation = TerraFormPage.CurBrush.gaussian_deviation,
		FlattenOperation = TerraFormPage.CurBrush.FlattenOperation,
	};
	if(filter.filtername == "Ramp") then
		brush.x1 = TerraFormPage.CurBrush.x1;
		brush.z1 = TerraFormPage.CurBrush.z1;
		brush.x2 = TerraFormPage.CurBrush.x;
		brush.z2 = TerraFormPage.CurBrush.z;
	end

	Map3DSystem.SendMessage_env({type = Map3DSystem.msg.TERRAIN_SET_HeightFieldBrush, brush = brush,})
	Map3DSystem.SendMessage_env({type = Map3DSystem.msg.TERRAIN_HeightField, disableSound = true,})	
	-- force update even the camera does not move
	ParaTerrain.UpdateTerrain(true);
end

-- called every few milliseconds when user click and hold the left mouse button 
function TerraFormPage.OnBrushTimer(timer)
	local filter = TerraFormPage.GetCurFilter()
	if(not filter or not TerraFormPage.CurBrush.filtername) then
		TerraFormPage.EndEditing()
	else
		if(filter.filtername == "Flatten") then
			if(not TerraFormPage.LockFlattenElevation) then
				TerraFormPage.OnSetElevationToCur();
			end
		end
		if(filter.filtername ~= "Ramp") then
			TerraFormPage.ApplyCurFilter();
		end
		-- refresh the marker. 
		TerraFormPage.RefreshMarker()
	end
end
