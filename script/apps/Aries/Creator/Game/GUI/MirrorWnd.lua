--[[
Title: Mirror a block region
Author(s): LiXizhi
Date: 2014/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MirrorWnd.lua");
local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");
MirrorWnd.ShowPage(blocks, function(settings, result)
	if(result) then
		_guihelper.MessageBox(settings)
	end
end);
MirrorWnd.UpdateHintLocation(blocks, pivot_x, pivot_y, pivot_z, mirror_axis)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Display3D/SceneCanvas.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MirrorWnd = commonlib.gettable("MyCompany.Aries.Game.GUI.MirrorWnd");

local settings = {};

-- true or nil.
MirrorWnd.result = nil;

local groupindex_hint = 6; 

local page;
function MirrorWnd.Init()
	page = document:GetPageCtrl();
	page:SetValue("xyz", settings.xyz);
	page:SetValue("method", settings.method);
end

-- @param blocks: block list 
function MirrorWnd.ShowPage(blocks, pivot_x, pivot_y, pivot_z, callbackFunc)
	MirrorWnd.LoadBlocks(blocks, pivot_x, pivot_y, pivot_z);
	
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/MirrorWnd.html", 
			text = "Object Instances Editor",
			name = "PC.MirrorWnd", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_lt",
				x = 124,
				y = 186,
				width = 150,
				height = 220,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		ParaTerrain.DeselectAllBlock(groupindex_hint);
		if(callbackFunc) then
			callbackFunc(settings, MirrorWnd.result);
		end
		page = nil;
	end
end

function MirrorWnd.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function MirrorWnd.LoadBlocks(blocks, pivot_x, pivot_y, pivot_z)
	MirrorWnd.result = nil;
	MirrorWnd.blocks = blocks;
	MirrorWnd.pivot_x = pivot_x;
	MirrorWnd.pivot_y = pivot_y;
	MirrorWnd.pivot_z = pivot_z;
	settings.xyz = "x";
	settings.method = "clone"

	MirrorWnd.UpdateHintLocation();
end

function MirrorWnd.GetMirrorPoint(src_x, src_y, src_z, pivot_x, pivot_y,pivot_z, mirror_axis)
	if(mirror_axis == "x") then
		return pivot_x*2 - src_x, src_y, src_z;
	elseif(mirror_axis == "y") then
		return src_x, pivot_y*2 - src_y, src_z;
	else -- if(mirror_axis == "z") then
		return src_x, src_y, pivot_z*2 - src_z;
	end
end

-- public function
function MirrorWnd.UpdateHintLocation(blocks, pivot_x, pivot_y, pivot_z, mirror_axis)
	ParaTerrain.DeselectAllBlock(groupindex_hint);

	blocks = blocks or MirrorWnd.blocks;
	
	local GetMirrorPoint = MirrorWnd.GetMirrorPoint;
	pivot_x, pivot_y,pivot_z = pivot_x or MirrorWnd.pivot_x, pivot_y or MirrorWnd.pivot_y, pivot_z or MirrorWnd.pivot_z;
	mirror_axis = mirror_axis or settings.xyz;

	MirrorWnd.blocks = blocks;
	MirrorWnd.pivot_x = pivot_x;
	MirrorWnd.pivot_y = pivot_y;
	MirrorWnd.pivot_z = pivot_z;
	settings.xyz = mirror_axis;

	for i = 1, #blocks do
		local b = blocks[i];
		local x,y,z = GetMirrorPoint(b[1], b[2], b[3], pivot_x, pivot_y,pivot_z, mirror_axis);
		ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint);
	end
end

function MirrorWnd.OnChangeAxis()
	local axis_xyz = page:GetUIValue("xyz");
	MirrorWnd.UpdateHintLocation(nil, nil, nil, nil, axis_xyz);
end

function MirrorWnd.OnOK()
	MirrorWnd.result = true;
	local xyz = page:GetUIValue("xyz");
	local method = page:GetUIValue("method");
	settings.xyz = xyz;
	settings.method = method;
	page:CloseWindow();
end