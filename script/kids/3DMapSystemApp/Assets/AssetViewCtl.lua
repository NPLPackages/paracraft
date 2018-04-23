--[[
Title: asset view control: For previewing and editing asset properties. it is shown on the right side of asset manager window
Note: can only be used with asset Manager
Author(s): LiXizhi
Date: 2008/1/31
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetViewCtl.lua");
Map3DSystem.App.Assets.AssetViewCtl.Show(_parent)
Map3DSystem.App.Assets.AssetViewCtl.Update(asset)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/OneTimeAsset.lua");
commonlib.setfield("Map3DSystem.App.Assets.AssetViewCtl", {});

-- the current binding
local bindingContext;


-- display the preview control. 
function Map3DSystem.App.Assets.AssetViewCtl.Show(_parent)
	_this = ParaUI.CreateUIObject("button", "btnGenerateThumbNail", "_rt", -106, 45, 90, 22)
	_this.text = "生成缩略图";
	_this.onclick = ";Map3DSystem.App.Assets.AssetViewCtl.OnClickSaveThumbNail();";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("button", "addToScene", "_rb", -150, -34, 125, 28)
	_this.text = "添加到场景";
	_this.onclick = ";Map3DSystem.App.Assets.AssetViewCtl.OnClickAddToScene();";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("text", "label2", "_rb", -176, -225, 42, 14)
	_this.text = "预览:";
	_parent:AddChild(_this);
	
	NPL.load("(gl)script/ide/TreeView.lua");
	local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetAttributes");
	if(not ctl) then
		ctl = CommonCtrl.TreeView:new{
			name = "AssetManager.treeViewAssetAttributes",
			alignment = "_mr",
			left = 5,
			top = 73,
			width = 171,
			height = 234,
			parent = _parent,
			DefaultIndentation = 5,
			DefaultNodeHeight = 25,
			DrawNodeHandler = CommonCtrl.TreeView.DrawPropertyNodeHandler,
			container_bg = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
		};
		local node = ctl.RootNode;
		node:AddChild( CommonCtrl.TreeNode:new({Text = "名字", Name = "text", Type="string", }) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "图标", Name = "icon", Type="file",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "模型路径", Name = "filename", Type="string",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "价格", Name = "price", Type="int",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "分类", Name = "type", Type="int",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "物理半径", Name = "physicsradius", Type="float",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "密度", Name = "density", Type="float",}) );
		node:AddChild( CommonCtrl.TreeNode:new({Text = "放缩", Name = "scale", Type="float",}) );
	else
		ctl.parent = _parent;
	end	
	
	ctl:Show();

	------------------------------------
	-- canvas
	------------------------------------
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = "AssetManager.canvas",
		alignment = "_rb",
		left=-173, top=-208,
		width = 168,
		height = 168,
		background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
		minZoomDist = 0.01,
		parent = _parent,
		IsActiveRendering = true,
	};
	ctl:Show();

	_this = ParaUI.CreateUIObject("button", "AssetManager.thumbnailBtn", "_rt", -176, 3, 64, 64)
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4";
	_guihelper.SetUIColor(_this, "255 255 255");
	_parent:AddChild(_this);
		
end

-- binding an asset object to the AssetViewCtl
function Map3DSystem.App.Assets.AssetViewCtl.Update(asset)
	bindingContext = commonlib.BindingContext:new();
	bindingContext._asset = asset;
	-- attribute bind
	bindingContext:AddBinding(asset, "filename", "AssetManager.treeViewAssetAttributes", commonlib.Binding.ControlTypes.IDE_treeview, "RootNode#filename")
	bindingContext:AddBinding(asset, "text", "AssetManager.treeViewAssetAttributes", commonlib.Binding.ControlTypes.IDE_treeview, "RootNode#text")
	bindingContext:AddBinding(asset, "price", "AssetManager.treeViewAssetAttributes", commonlib.Binding.ControlTypes.IDE_treeview, "RootNode#price")
	bindingContext:AddBinding(asset, "icon", "AssetManager.treeViewAssetAttributes", commonlib.Binding.ControlTypes.IDE_treeview, "RootNode#icon")
	-- icon bind: it provides a default icon if no icon is found
	bindingContext:AddBinding(asset, "getIcon", "AssetManager.thumbnailBtn", commonlib.Binding.ControlTypes.ParaUI_button, "background", 
		commonlib.Binding.DataSourceUpdateMode.ReadOnly, "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4")
	-- canvas binding: two data source to the same 3d canvas control. 
	bindingContext:AddBinding(asset, "getModelParams", "AssetManager.canvas", commonlib.Binding.ControlTypes.IDE_canvas3d, "model", commonlib.Binding.DataSourceUpdateMode.ReadOnly)
	-- uncomment to preview image as well. NOT tested. 
	--bindingContext:AddBinding(asset, "getImageFile", "AssetManager.canvas", commonlib.Binding.ControlTypes.IDE_canvas3d, "image", commonlib.Binding.DataSourceUpdateMode.ReadOnly)
	
	bindingContext:UpdateDataToControls();
end


------------------------
-- event handlers
------------------------

-- User clicks to add the current object to the scene 
function Map3DSystem.App.Assets.AssetViewCtl.OnClickAddToScene()
	local asset = bindingContext._asset;
	if(asset) then
		local objParams = asset:getModelParams()
		if(objParams~=nil) then
			-- create object by sending a message
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CreateObject, obj_params=objParams});
		end
	end
end

-- User clicks to create a thumbnail image for the current asset
function Map3DSystem.App.Assets.AssetViewCtl.OnClickSaveThumbNail()
	local asset = bindingContext._asset;
	if(asset) then
		local icon = asset:getIcon();
		-- only save for Non-http icon to disk. 
		if(icon and string.find(icon,"^http")==nil) then
			icon = string.gsub(icon, ":.*$", "")
			local ctl = CommonCtrl.GetControl("AssetManager.canvas");
			if(ctl) then
				local dlgText;
				if(ParaIO.DoesFileExist(icon, true)) then	
					dlgText = string.format("文件: %s 已经存在, 您确定要覆盖它么?", icon);
				else
					dlgText = string.format("您确定要保存到文件: %s 么?", icon);
				end
				_guihelper.MessageBox(dlgText, function ()
					ctl:SaveToFile(icon, 64);
					-- reload asset.
					CommonCtrl.OneTimeAsset.Unload(icon);
					-- refresh all controls to reflect the changes. 
					bindingContext:UpdateDataToControls();
				end)
			end
		end	
	end
end