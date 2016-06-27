--[[
Title: TerraPaintPage
Author(s): LiXizhi
Company: ParaEnging Co. & Taomee Inc.
Date: 2010/1/26
Desc: Instructions:
	- click texture to paint on terrain
	- click set texture to replace or assign new detail texture brush
	- press esc key to exit editing mode
	- use -/+ key to scale brush size
	- hold and click/drag on terrain surface to repeatedly apply terrain paint. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/TerraPaintPage.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

local TerraPaintPage = commonlib.gettable("MyCompany.Aries.Creator.TerraPaintPage")

NPL.load("(gl)script/apps/Aries/Creator/Env/TerrainBrushMarker.lua");
local TerrainBrushMarker = MyCompany.Aries.Creator.TerrainBrushMarker;

-- singleton page instance. 
local page;

-- image to display when detail texture slot is empty. 
TerraPaintPage.EmptyDetailTex = "Texture/Aries/Creator/eraser.png;0 0 48 48"; -- "Texture/tileset/generic/GridMarker.dds";

-- Terrain texture db table
TerraPaintPage.terrainTexList = {
	{filename = TerraPaintPage.EmptyDetailTex},
};
-- selected index. 
TerraPaintPage.SelectedIndex = nil;
-- max number of textures to display. although the engine support unlimited textures, we will only allow the user to use 8 at most. 
TerraPaintPage.MaxDetailTexCount = 32;
-- how many milliseconds to paint repeatedly when user hold the key. 
TerraPaintPage.PaintTimerInterval = 100;
-- default brushes
local defaultBrushes = {
	{
		BrushSize = 1, 
		BrushStrength = 0.25,
		BrushSoftness = 1,
	},
	{
		BrushSize = 2, 
		BrushStrength = 0.25,
		BrushSoftness = 1,
	},
	{
		BrushSize = 3, 
		BrushStrength = 0.25,
		BrushSoftness = 1,
	},
};
-- current brush
TerraPaintPage.CurBrush = {
	filename = nil,
	BrushSize = 1, 
	BrushStrength = 0.25,
	BrushSoftness = 1,
}

function TerraPaintPage.DS_TerrainTex_Func(index)
	if(index == nil) then
		return #(TerraPaintPage.terrainTexList);
	else
		return TerraPaintPage.terrainTexList[index];
	end	
end

-- default textures for people to use. 
local terrainTexList = {
	TerraPaintPage.EmptyDetailTex,
	"Texture/tileset/generic/env_landroad_deco_yellow.dds",
	"Texture/tileset/generic/c_grass_light_green.dds",
	"Texture/tileset/generic/env_snowhill_blue.dds",
	"Texture/tileset/generic/c_grassdeco_light_green.dds",
	
	"Texture/tileset/generic/env_landroad_light_yellow.dds",
	"Texture/tileset/generic/env_beachsand_dark_yellow.dds",
	"Texture/tileset/generic/c_rockroad_light_pink.dds",
	"Texture/tileset/generic/c_garssbackdeco_light_green.dds",
	
	"Texture/tileset/generic/c_mudroad_light_yellow.dds",
	"Texture/tileset/generic/env_cliff_dark_yellow.dds",

	"Texture/tileset/generic/c_bigroad_dark_blue.dds",
	"Texture/tileset/generic/c_bigroad_light_blue.dds",
	"Texture/tileset/generic/c_rockroad_dark_pink.dds",
	"Texture/tileset/generic/Darkforest/ground01.dds",
	"Texture/tileset/generic/Darkforest/ground02.dds",
	"Texture/tileset/generic/Darkforest/ground03.dds",
	"Texture/tileset/generic/Darkforest/huoshan01.dds",
	"Texture/tileset/generic/Darkforest/huoshan02.dds",
	"Texture/tileset/generic/Darkforest/huoshan03.dds",
	"Texture/tileset/generic/Darkforest/huoshan04.dds",
	"Texture/tileset/generic/Darkforest/riverstone04.dds",
	"Texture/tileset/generic/firebirdland/a_11.dds",
	"Texture/tileset/generic/firebirdland/a_10.dds",
};
local max_textures = #terrainTexList;
TerraPaintPage.MaxDetailTexCount = max_textures;

local function GetNextUnUsedTextures(used_textures)
	local _, filename
	for _, filename  in ipairs(terrainTexList) do
		if(not used_textures[filename] and filename~="") then
			used_textures[filename] = true;
			return filename;
		end
	end
end

-- called to init page
function TerraPaintPage.OnInit()
	page = document:GetPageCtrl();
	local used_textures = {};
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	local nCount = ParaTerrain.GetTextureCount(x,z);
	local i;
	local HasEmpty;
	for i = 1,TerraPaintPage.MaxDetailTexCount do 
		TerraPaintPage.terrainTexList[i] = TerraPaintPage.terrainTexList[i] or {};
		if(i<=nCount) then
			local filename = ParaTerrain.GetTexture(x, z, i-1):GetKeyName();
			TerraPaintPage.terrainTexList[i].filename = filename;	
			used_textures[filename] = true;
		else
			-- fill in some predefined textures. 
			TerraPaintPage.terrainTexList[i].filename = GetNextUnUsedTextures(used_textures) or TerraPaintPage.EmptyDetailTex;
			
			if(TerraPaintPage.terrainTexList[i].filename == TerraPaintPage.EmptyDetailTex) then
				if(not HasEmpty) then
					HasEmpty = true;
				else
					TerraPaintPage.terrainTexList[i].filename = "";
				end	
			end
		end
		TerraPaintPage.terrainTexList[i].InCell = nil;
	end
	
	local cell_texs = {};
	ParaTerrain.GetTexturesInCell(x,z,cell_texs);
	local index;
	for i, index in pairs(cell_texs) do
		local tex = TerraPaintPage.terrainTexList[index+1];
		if(tex) then
			tex.InCell = true;
		end
	end
	
	page:SetNodeValue("BrushSize", TerraPaintPage.CurBrush.BrushSize);
	page:SetNodeValue("BrushStrength", TerraPaintPage.CurBrush.BrushStrength);
	page:SetNodeValue("BrushSoftness", TerraPaintPage.CurBrush.BrushSoftness);
	
	NPL.load("(gl)script/apps/Aries/Creator/Env/SwitchEnvEditorMode.lua");
	MyCompany.Aries.Creator.SwitchEnvEditorMode("TerraPaintPage");
	
	TerrainBrushMarker.ShowTextureCellRegion(true);
	
	if(TerraPaintPage.SelectedIndex~=nil) then
		TerraPaintPage.BeginEditing();
	end
end

------------------------
-- page events
------------------------

-- Close the page
function TerraPaintPage.OnClose()
	TerraPaintPage.EndEditing()
end

-- reset the page
function TerraPaintPage.OnReset()
	TerraPaintPage.EndEditing();
	page:Refresh(0);
end

-- display a dialog to select or replace currently selected textures.
function TerraPaintPage.OnSetTexture()
	if(TerraPaintPage.SelectedIndex == nil) then
		_guihelper.MessageBox("请先选择一个图层通道, 来设置它的贴图");
		return
	end
	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local ctl = CommonCtrl.OpenFileDialog:new{
		name = "OpenFileDialog1",
		alignment = "_ct",
		left=-256, top=-150,
		width = 512,
		height = 380,
		parent = nil,
		fileextensions = {"images(*.jpg; *.png; *.dds)",},
		folderlinks = {
			{path = "Texture/tileset/generic/", text = "Texture"},
			{path = "worlds/", text = "worlds"},
		},
		onopen = function(ctrlName, filename)
			if(TerraPaintPage.SelectedIndex) then
				TerraPaintPage.ReplaceTexture(TerraPaintPage.SelectedIndex-1, filename)
			end
		end
	};
	ctl:Show(true);
end

-- delete the currently selected texture layer. 
function TerraPaintPage.OnDeleteTexture()
	if(TerraPaintPage.SelectedIndex == nil) then
		_guihelper.MessageBox([[<div style="margin-top:32px;">请先选择你想要删除的地表贴图</div>]]);
		return
	end
	
	_guihelper.MessageBox(string.format([[<div style="margin-top:32px;">你确定要将选择的地表贴图 全部删除吗？</div>]]), function(res)
			if(TerraPaintPage.SelectedIndex) then
				if(res and res == _guihelper.DialogResult.Yes) then
					TerraPaintPage.ReplaceTexture(TerraPaintPage.SelectedIndex-1, nil)
				elseif(res and res == _guihelper.DialogResult.No) then
					-- This is too advanced for kids, so we removed it. 
					-- TerraPaintPage.ReplaceTexture(TerraPaintPage.SelectedIndex-1, nil, true)
				else
					-- cancel	
				end
			end
		end, _guihelper.MessageBoxButtons.YesNo)
end

-- selected a detail terrain to paint.
-- @param index: if nil, it will select nothing
function TerraPaintPage.OnSelectTexture(index)
	if(TerraPaintPage.SelectedIndex ~= index or index~=nil) then
		TerraPaintPage.SelectedIndex = index;
		if(index) then
			local tex = TerraPaintPage.terrainTexList[index];
			if(tex) then
				local filename = tex.filename;
				if(filename) then
					TerraPaintPage.UpdateCurrentBrush({filename = filename});
					TerraPaintPage.BeginEditing()
				end	
			end	
		else
			TerraPaintPage.EndEditing()
		end
		page:Refresh(0);
	end	
end

-- select an empty eraser. 
function TerraPaintPage.OnSelectEraser()
	local nEraserIndex;
	for i = 1,TerraPaintPage.MaxDetailTexCount do 
		local tex = TerraPaintPage.terrainTexList[i] or {};
		if(tex and tex.filename == TerraPaintPage.EmptyDetailTex) then
			nEraserIndex = i;
			break;
		end
	end
	if(nEraserIndex) then
		TerraPaintPage.OnSelectTexture(nEraserIndex)
	end	
end

-- deselect current one 
function TerraPaintPage.OnDeselectTexture()
	TerraPaintPage.OnSelectTexture(nil);
end

function TerraPaintPage.OnSetBrushSoftness(value)
	TerraPaintPage.UpdateCurrentBrush({BrushSoftness = value});
end

function TerraPaintPage.OnSetBrushStrength(value)
	TerraPaintPage.UpdateCurrentBrush({BrushStrength = value});
end

function TerraPaintPage.OnSetBrushSize(value)
	TerraPaintPage.UpdateCurrentBrush({BrushSize = value});
end

function TerraPaintPage.OnClickBrush(btnName)
	local brushIndex = tonumber(btnName)
	if(brushIndex~=nil) then
		local brush = defaultBrushes[brushIndex];
		TerraPaintPage.UpdateCurrentBrush(brush, true);
	end
end

function TerraPaintPage.OnSetBrushRepeatInterval(value)
	TerraPaintPage.PaintTimerInterval = math.floor((1-value)*1000);
end

------------------------
-- public methods
------------------------

-- replace a given texture in texture cell set specified at position x,z
-- @param OldIndex: the old texture index to replace, this is zero based index. if nil, new detail texture will be added. 
-- @param newfilename: the new texture to replace with. If nil, texture will be deleted at the given index.  
-- @param bCellOnly: if true, texture is only removed from the texture cell, instead of the entire terrain tile. 
-- @param x,y,z: if nil, the current player location is used. 
function TerraPaintPage.ReplaceTexture(OldIndex, newfilename, bCellOnly, x,y,z)
	if(x == nil or z ==nil) then
		x,y,z = ParaScene.GetPlayer():GetPosition();
	end	
	local nCount = ParaTerrain.GetTextureCount(x,z);
	if(OldIndex == nil) then 
		OldIndex = nCount;
	end
	if(OldIndex >= 0) then
		if(not bCellOnly) then
			ParaTerrain.ReplaceTexture(x, z, OldIndex, newfilename);
		else
			if(newfilename == nil) then
				ParaTerrain.RemoveTextureInCell(x, z, OldIndex);
			else
				_guihelper.MessageBox("replacing in the cell is not supported. Please delete in the cell and paint again.");
			end
		end
	end
	TerraPaintPage.OnReset();
end

-- when user select a tool it will enter 3d editing mode, where the miniscenegraph should draw markers
function TerraPaintPage.BeginEditing()
	TerraPaintPage.mytimer = TerraPaintPage.mytimer or commonlib.Timer:new({callbackFunc = TerraPaintPage.OnBrushTimer})
	ParaCamera.GetAttributeObject():SetField("EnableMouseLeftButton", false)
	TerraPaintPage.RegisterHooks()
end
-- when user pressed esc key, it will quit the 3d editing mode. and the mini scenegraph should be deleted. 
function TerraPaintPage.EndEditing()
	ParaCamera.GetAttributeObject():SetField("EnableMouseLeftButton", true)
	TerraPaintPage.UnregisterHooks()
	TerraPaintPage.OnSelectTexture(nil);
	TerrainBrushMarker.Clear()
	if(TerraPaintPage.mytimer) then
		-- kill timer
		TerraPaintPage.mytimer:Change();
	end
end

-- update the terrain brush. 
-- @param brush: {x,y,z,BrushSize,BrushSoftness, BrushStrength}, all fields can be nil. 
-- @param bRefreshUI: if true the UI will be updated according to input
function TerraPaintPage.UpdateCurrentBrush(brush, bRefreshUI)
	if(brush) then
		commonlib.partialcopy(TerraPaintPage.CurBrush, brush);
	end
	-- validate data
	if(TerraPaintPage.CurBrush.BrushSize < 0.1) then
		TerraPaintPage.CurBrush.BrushSize = 0.1;
	end
	
	if(bRefreshUI) then
		page:SetUIValue("BrushSize", TerraPaintPage.CurBrush.BrushSize);
		page:SetUIValue("BrushStrength", TerraPaintPage.CurBrush.BrushStrength);
		page:SetUIValue("BrushSoftness", TerraPaintPage.CurBrush.BrushSoftness);
	end	
	
	if(TerraPaintPage.SelectedIndex~=nil) then
		TerrainBrushMarker.DrawBrush({x=TerraPaintPage.CurBrush.x,y=TerraPaintPage.CurBrush.y,z=TerraPaintPage.CurBrush.z,radius = TerraPaintPage.CurBrush.BrushSize});
	end	
end

function TerraPaintPage.RegisterHooks()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraPaint_mouse_down_hook", appName = "input", wndName = "mouse_down", 
		callback = TerraPaintPage.OnMouseDown});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraPaint_mouse_move_hook", appName = "input", wndName = "mouse_move",
		callback = TerraPaintPage.OnMouseMove});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraPaint_mouse_up_hook", appName = "input", wndName = "mouse_up",
		callback = TerraPaintPage.OnMouseUp});
	CommonCtrl.os.hook.SetWindowsHook({hookType = hookType, 		 
		hookName = "TerraPaint_key_down_hook", appName = "input", wndName = "key_down",
		callback = TerraPaintPage.OnKeyDown});
end

function TerraPaintPage.UnregisterHooks()
	local hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC;
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraPaint_mouse_down_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraPaint_mouse_move_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraPaint_mouse_up_hook", hookType = hookType});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "TerraPaint_key_down_hook", hookType = hookType});
end

------------------------
-- input hooked event handler
------------------------
function TerraPaintPage.OnMouseDown(nCode, appName, msg)
	if(nCode==nil) then return end
	local input = Map3DSystem.InputMsg;
	
	if(input.mouse_button == "left") then
		if(TerraPaintPage.mytimer) then
			TerraPaintPage.mytimer:Change(0, TerraPaintPage.PaintTimerInterval)
		end
		return;
	end
	
	return nCode; 
end
function TerraPaintPage.OnMouseMove(nCode, appName, msg)
	if(nCode==nil) then return end
	local input = Map3DSystem.InputMsg;
	
	local pt = ParaScene.MousePick(70, "walkpoint"); -- pick a object
	if(pt:IsValid())then
		local x,y,z = pt:GetPosition();
		TerraPaintPage.UpdateCurrentBrush({x=x,y=y,z=z});
		return;
	end	
	return nCode; 
end
function TerraPaintPage.OnMouseUp(nCode, appName, msg)
	if(nCode==nil) then return end
	local input = Map3DSystem.InputMsg;
	
	if(input.mouse_button == "left") then
		if(TerraPaintPage.mytimer) then
			TerraPaintPage.mytimer:Change()
		end
		return;
	elseif(input.mouse_button == "right") then	
		if(input.dragDist<=5) then 
			-- exit editing mode. 
			TerraPaintPage.EndEditing();
			return;
		end
	end	
	return nCode; 
end
function TerraPaintPage.OnKeyDown(nCode, appName, msg)
	if(nCode==nil) then return end
	if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_ESCAPE))then
		-- exit editing mode. 
		TerraPaintPage.EndEditing();
		return
	elseif(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_EQUALS))then
		-- DoScaling +
		TerraPaintPage.UpdateCurrentBrush({BrushSize = TerraPaintPage.CurBrush.BrushSize + 0.2});
		return
	elseif(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_MINUS))then
		-- DoScaling -
		TerraPaintPage.UpdateCurrentBrush({BrushSize = TerraPaintPage.CurBrush.BrushSize - 0.2});
		return
	end	
	return nCode; 
end

-- called every few milliseconds when user click and hold the left mouse button 
function TerraPaintPage.OnBrushTimer(timer)
	local filename = TerraPaintPage.CurBrush.filename;
	if(filename == nil or filename == TerraPaintPage.EmptyDetailTex) then
		filename = ""; -- it means painting the base layer, erasing other textures. 
	end
	Map3DSystem.SendMessage_env({type = Map3DSystem.msg.TERRAIN_SET_PaintBrush, brush = {
			filename = filename,
			x=TerraPaintPage.CurBrush.x,
			y=TerraPaintPage.CurBrush.y,
			z=TerraPaintPage.CurBrush.z,
			radius = TerraPaintPage.CurBrush.BrushSize,
			BrushStrength = TerraPaintPage.CurBrush.BrushStrength,
			BrushSoftness = TerraPaintPage.CurBrush.BrushSoftness,
			bErase = nil,
		},})
	Map3DSystem.SendMessage_env({type = Map3DSystem.msg.TERRAIN_Paint, 
		forcelocal = true, disableSound = true,
		})
end
