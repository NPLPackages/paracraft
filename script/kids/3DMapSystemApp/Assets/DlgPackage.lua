--[[
Title: create and edit package dialog.
Note: can only be used with asset Manager
Author(s): LiXizhi
Date: 2008/1/31
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/DlgPackage.lua");
Map3DSystem.App.Assets.ShowCreatePackageDlg()
Map3DSystem.App.Assets.ShowEditPackageDlg(package)
-------------------------------------------------------
]]

-- current package binding context
local bindingContext;

-- show the create package dialog
function Map3DSystem.App.Assets.ShowCreatePackageDlg()
	-- create a new package.
	local package = Map3DSystem.App.Assets.CreatePackage({text="未命名资源包"});
	bindingContext = commonlib.BindingContext:new();
	
	bindingContext:AddBinding(package, "text", "AssetManager.NewAsset#packageName", commonlib.Binding.ControlTypes.ParaUI_editbox, "text")
	bindingContext:AddBinding(package, "icon", "AssetManager.NewAsset#textBoxIconPath", commonlib.Binding.ControlTypes.ParaUI_editbox, "text")
	bindingContext:AddBinding(package, "Category", "AssetManager.comboBoxCategory", commonlib.Binding.ControlTypes.IDE_dropdownlistbox, "text")
	bindingContext:AddBinding(package, "bDisplayInMainBar", "AssetManager.checkBoxShowInMainbar", commonlib.Binding.ControlTypes.IDE_checkbox, "value")
	
	_guihelper.ShowDialogBox("新建资源包", nil, nil, 263, 114, 
	Map3DSystem.App.Assets.CreateEditPackageDlg, 
	function(dialogResult)
		if(dialogResult == _guihelper.DialogResult.OK) then
			bindingContext:UpdateControlsToData();
			-- add to package list and update UI controls.
			Map3DSystem.App.Assets.AddPackage(package);
			Map3DSystem.App.Assets.SelectPackage(package);
			Map3DSystem.App.Assets.AssetManager.UpdateComboBoxSelectPkg();
			Map3DSystem.App.Assets.AssetManager.RebuildAssetsTreeView();
		end
		return true;
	end)
end

-- show the edit package dialog
function Map3DSystem.App.Assets.ShowEditPackageDlg(package)
	bindingContext = commonlib.BindingContext:new();
	bindingContext:AddBinding(package, "text", "AssetManager.NewAsset#packageName", commonlib.Binding.ControlTypes.ParaUI_editbox, "text")
	bindingContext:AddBinding(package, "icon", "AssetManager.NewAsset#textBoxIconPath", commonlib.Binding.ControlTypes.ParaUI_editbox, "text")
	bindingContext:AddBinding(package, "Category", "AssetManager.comboBoxCategory", commonlib.Binding.ControlTypes.IDE_dropdownlistbox, "text")
	bindingContext:AddBinding(package, "bDisplayInMainBar", "AssetManager.checkBoxShowInMainbar", commonlib.Binding.ControlTypes.IDE_checkbox, "value")
	
	_guihelper.ShowDialogBox("编辑资源包", nil, nil, 263, 114, 
	Map3DSystem.App.Assets.CreateEditPackageDlg, 
	function(dialogResult)
		if(dialogResult == _guihelper.DialogResult.OK) then
			bindingContext:UpdateControlsToData();
			-- add to package list and update UI controls.
			Map3DSystem.App.Assets.AssetManager.UpdateComboBoxSelectPkg();
			Map3DSystem.App.Assets.AssetManager.UpdateAssetsTreeView();
		end
		return true;
	end)
end

-- create the dialog
function Map3DSystem.App.Assets.CreateEditPackageDlg(_parent)
	_this = ParaUI.CreateUIObject("container", "AssetManager.NewAsset", "_fi", 0,0,0,0)
	_this.background = "";
	_parent:AddChild(_this);
	_parent = _this;

	_this = ParaUI.CreateUIObject("text", "label4", "_lt", 3, 35, 42, 14)
	_this.text = "类型:";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("text", "label9", "_lt", 3, 61, 42, 14)
	_this.text = "图标:";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("text", "label5", "_lt", 3, 6, 70, 14)
	_this.text = "资源名称:";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("editbox", "packageName", "_mt", 85, 3, 3, 23)
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("editbox", "textBoxIconPath", "_mt", 85, 58, 3, 23)
	_parent:AddChild(_this);

	NPL.load("(gl)script/ide/dropdownlistbox.lua");
	local ctl = CommonCtrl.dropdownlistbox:new{
		name = "AssetManager.comboBoxCategory",
		alignment = "_mt",
		left = 85,
		top = 32,
		width = 3,
		height = 22,
		dropdownheight = 106,
		parent = _parent,
		text = "",
		items = {"Creations.BCS.doors", "Creations.BCS.windows", "Creations.Normals.Trees", },
	};
	ctl:Show();

	NPL.load("(gl)script/ide/CheckBox.lua");
	local ctl = CommonCtrl.checkbox:new{
		name = "AssetManager.checkBoxShowInMainbar",
		alignment = "_lt",
		left = 3,
		top = 91,
		width = 166,
		height = 18,
		parent = _parent,
		isChecked = false,
		text = "添加到我的创作工具栏",
	};
	ctl:Show();
	
	bindingContext:UpdateDataToControls();
end