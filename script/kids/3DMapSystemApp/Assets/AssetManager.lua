--[[
Title: Advanced asset manager window 
It allows user to edit, upload asset owned by the user. It uses a folder hierachy like VSS and allow users to set the working directory to synchronize from local directory to asset file (and remote server).
AssetData contains data structure for asset, folder and package. AssetProvider contains methods to load an save package from file or remote server.
Author(s): LiXizhi
Date: 2008/1/31
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManager.lua");
Map3DSystem.App.Assets.ShowAssetManager(_app)
-------------------------------------------------------
]]

-- common control library
NPL.load("(gl)script/ide/common_control.lua");
commonlib.setfield("Map3DSystem.App.Assets.AssetManager", {});

NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetData.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetProvider.lua");

-- a list of packages to be displayed by the current asset manager window
Map3DSystem.App.Assets.AssetManager.Packages = {};
-- the currently selected package
Map3DSystem.App.Assets.AssetManager.CurPak = nil;

-- add package to the package list. It does not update UI. 
function Map3DSystem.App.Assets.AddPackage(package)
	Map3DSystem.App.Assets.AssetManager.Packages[table.getn(Map3DSystem.App.Assets.AssetManager.Packages)+1] = package;
end

-----------------------------------------------------------------
-- UI stuffs
-----------------------------------------------------------------
-- display the package window. 
function Map3DSystem.App.Assets.ShowAssetManager(_app)
	local _wnd = _app:FindWindow("AssetManager") or _app:RegisterWindow("AssetManager", nil, Map3DSystem.App.Assets.AssetManager.MSGProc);
	
	-- Change to new window frame
	
	local _wndFrame = _wnd:GetWindowFrame();
	if(not _wndFrame) then
		_wndFrame = _wnd:CreateWindowFrame{
			wnd = _wnd,
			--isUseUI = true,
			icon = "Texture/3DMapSystem/common/color_swatch.png",
			iconSize = 48,
			text = "高级资源编辑",
			
			maxWidth = 1024,
			maxHeight = 1024,
			minWidth = 340,
			minHeight = 400,
			
			isShowIcon = true,
			--opacity = 100, -- [0, 100]
			isShowMaximizeBox = false,
			isShowMinimizeBox = false,
			isShowAutoHideBox = false,
			allowDrag = true,
			allowResize = true,
			initialPosX = 0,
			initialPosY = 100,
			initialWidth = 490,
			initialHeight = 430,
			
			style = CommonCtrl.WindowFrame.DefaultStyle,
			
			ShowUICallback =Map3DSystem.App.Assets.AssetManager.Show,
		};
	end	
	_wnd:ShowWindowFrame(true);
end

function Map3DSystem.App.Assets.AssetManager.MSGProc(window, msg)
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	if(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		window:ShowWindowFrame(false);
	end
end

--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
-- @param _parent: parent window inside which the content is displayed. it can be nil.
function Map3DSystem.App.Assets.AssetManager.Show(bShow, _parent, parentWindow)
	local _this;
	Map3DSystem.App.Assets.AssetManager.parentWindow = parentWindow;
	
	_this=ParaUI.GetUIObject("AssetManager_cont");
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		if(_parent==nil) then
			_this=ParaUI.CreateUIObject("container","AssetManager_cont","_lt",0,50, 500, 430);
			_this:AttachToRoot();
		else
			_this = ParaUI.CreateUIObject("container", "AssetManager_cont", "_fi",0,0,0,0);
			_this.background = ""
			_parent:AddChild(_this);
		end	
		_parent = _this;


		NPL.load("(gl)script/ide/TreeView.lua");
		local ctl = CommonCtrl.TreeView:new{
			name = "AssetManager.treeViewAssetList",
			alignment = "_fi",
			left = 0,
			top = 31,
			width = 182,
			height = 6,
			parent = _parent,
			DefaultIndentation = 12,
			DefaultNodeHeight = 25,
			container_bg = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4",
			DrawNodeHandler = Map3DSystem.App.Assets.AssetManager.DrawAssetsNodeHandler,
			onclick = Map3DSystem.App.Assets.AssetManager.OnClickAssetsNode,
		};
		local node = ctl.RootNode;
		ctl:Show();

		_this = ParaUI.CreateUIObject("text", "labelPkgCount", "_lt", 3, 6, 80, 14)
		_this.text = "资源包:";
		_guihelper.SetUIFontFormat(_this, 36); -- single line and vertical align
		_parent:AddChild(_this);

		-- list of all packages
		NPL.load("(gl)script/ide/dropdownlistbox.lua");
		local ctl = CommonCtrl.dropdownlistbox:new{
			name = "AssetManager.comboBoxSelectPkg",
			alignment = "_mt",
			left = 81,
			top = 3,
			width = 247,
			height = 22,
			dropdownheight = 106,
 			parent = _parent,
			text = "",
			items = items,
			onselect = Map3DSystem.App.Assets.AssetManager.OnSelectPackage,
			AllowUserEdit = false,
		};
		ctl:Show();

		_this = ParaUI.CreateUIObject("button", "b", "_rt", -241, 4, 59, 21)
		_this.text = "新建";
		_this.onclick = ";Map3DSystem.App.Assets.AssetManager.OnClickCreatePackage();";
		_parent:AddChild(_this);
		
		-- create the asset view control on the right. 
		NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetViewCtl.lua");
		Map3DSystem.App.Assets.AssetViewCtl.Show(_parent);
	else
		if(bShow == nil) then
			bShow = not _this.visible;
		end
		_parent = _this;
	end	
	if(bShow) then
		Map3DSystem.App.Assets.AssetManager.UpdateComboBoxSelectPkg();
		Map3DSystem.App.Assets.AssetManager.RebuildAssetsTreeView();
	else
		Map3DSystem.App.Assets.AssetManager.OnDestroy()
	end
end

-- owner draw function to treeViewAssetsNodeList
function Map3DSystem.App.Assets.AssetManager.DrawAssetsNodeHandler(_parent, treeNode)
	if(_parent == nil or treeNode == nil) then
		return
	end
	local _this;
	local left = 2; -- indentation of this node. 
	local top = 2;
	local height = treeNode:GetHeight();
	local nodeWidth = treeNode.TreeView.ClientWidth;
	
	if(treeNode.TreeView.RootNode:GetHeight() > 0) then
		left = left + treeNode.TreeView.DefaultIndentation*treeNode.Level + 2;
	else
		left = left + treeNode.TreeView.DefaultIndentation*(treeNode.Level-1) + 2;
	end	
	
	if(treeNode.TreeView.ShowIcon) then
		
		if(treeNode.type == "asset" and treeNode.asset) then
			local IconSize = 25
			local filename = treeNode.asset:getIcon()
			if(filename~=nil and ParaIO.DoesFileExist(string.gsub(filename, ":.*$", ""), true) or string.find(filename,"^http")~=nil) then	
				_this=ParaUI.CreateUIObject("button","b","_lt", left, 0, IconSize, IconSize);
				_this.background = filename;
				_guihelper.SetUIColor(_this, "255 255 255");
				_parent:AddChild(_this);
			end
			left = left + IconSize+3;
		else	
			local IconSize = treeNode.TreeView.DefaultIconSize;
			if(treeNode.Icon~=nil and IconSize>0) then
				_this=ParaUI.CreateUIObject("button","b","_lt", left, top , IconSize, IconSize);
				_this.background = treeNode.Icon;
				_guihelper.SetUIColor(_this, "255 255 255");
				_parent:AddChild(_this);
			end	
			left = left + IconSize+3;
		end
	end	
	
	if(treeNode.type == "package") then
		--
		-- draw package node
		-- 
		_this = ParaUI.CreateUIObject("text", "label8", "_lt", left+2, 3, 63, 14)
		_this.text = treeNode.package.text;
		_guihelper.SetUIFontFormat(_this, 32);
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button10", "_rt", -105, 3, 50, 20)
		_this.text = "编辑";
		_this.onclick = ";Map3DSystem.App.Assets.AssetManager.OnClickEditPackage()"
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button6", "_rt", -53, 3, 50, 20)
		_this.text = "保存";
		_this.onclick = ";Map3DSystem.App.Assets.AssetManager.OnClickSavePackage()"
		_parent:AddChild(_this);
		
	elseif(treeNode.type == "folders") then
		--
		-- draw folders node
		-- 
		width = 12 -- check box width
		
		_this=ParaUI.CreateUIObject("button","b","_lt", left, top , width, width);
		_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		left = left + width + 2;
		
		if(treeNode.Expanded) then
			_this.background = "Texture/3DMapSystem/common/itemopen.png";
		else
			_this.background = "Texture/3DMapSystem/common/itemclosed.png";
		end
	
		_this = ParaUI.CreateUIObject("button", "label3", "_fi", left+2, 1, 54, 1)
		_this.text = "同步文件夹";
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button3", "_rt", -53, 3, 50, 20)
		_this.text = "添加";
		_this.onclick = ";Map3DSystem.App.Assets.AssetManager.AddNewFolder()"
		_parent:AddChild(_this);	
		
	elseif(treeNode.type == "folder") then
		--
		-- draw folder node
		-- 
		width = 12 -- check box width
		_this=ParaUI.CreateUIObject("button","b","_lt", left, top , width, width);
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickToggleFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		left = left + width + 2;
		
		if(treeNode.Expanded) then
			_this.background = "Texture/3DMapSystem/common/itemopen.png";
		else
			_this.background = "Texture/3DMapSystem/common/itemclosed.png";
		end
		
		_this = ParaUI.CreateUIObject("button", "l", "_mt", left+3, 3, 64, 22)
		_this.text = treeNode.Text;
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickToggleFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button5", "_rt", -63, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Department.png"
		_this.tooltip = "全部展开";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickFullExpandFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button5", "_rt", -42, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Refresh.png"
		_this.tooltip = "刷新";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickRefreshFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button4", "_rt", -21, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Trash.png"
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickDeleteFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_this.tooltip = "删除";
		_parent:AddChild(_this);

	elseif(treeNode.type == "assets") then
		--
		-- draw assets node
		-- 
		width = 12 -- check box width
		
		_this=ParaUI.CreateUIObject("button","b","_lt", left, top , width, width);
		_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		left = left + width + 2;
		
		if(treeNode.Expanded) then
			_this.background = "Texture/3DMapSystem/common/itemopen.png";
		else
			_this.background = "Texture/3DMapSystem/common/itemclosed.png";
		end
		
		_this = ParaUI.CreateUIObject("button", "label3", "_fi", left+2, 1, 54, 1)
		local nAssetCount = 0;
		local package = Map3DSystem.App.Assets.AssetManager.CurPak;
		if(package~=nil) then		
			nAssetCount = table.getn(package.assets);
		end
		_this.text = string.format("资源清单(%d)", nAssetCount);
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_parent:AddChild(_this);
			
		_this = ParaUI.CreateUIObject("button", "button3", "_rt", -53, 3, 50, 20)
		_this.text = "添加";
		_this.onclick = ";Map3DSystem.App.Assets.AssetManager.AddNewAsset()"
		_parent:AddChild(_this);
		
	elseif(treeNode.type == "asset") then
		--
		-- draw asset node
		-- 
		_this = ParaUI.CreateUIObject("button", "l", "_mt", left+3, 3, 44, 22)
		_this.text = treeNode.Text or treeNode.asset.filename;
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_this.onclick = string.format(";CommonCtrl.TreeView.OnClickNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button5", "_rt", -42, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Refresh.png"
		_this.tooltip = "刷新";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickRefreshAssetNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button4", "_rt", -21, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Trash.png"
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickDeleteAssetNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_this.tooltip = "删除";
		_parent:AddChild(_this);
	elseif(treeNode.type == "directory") then
		--
		-- directory
		-- 
		width = 12 -- check box width
		_this=ParaUI.CreateUIObject("button","b","_lt", left, top , width, width);
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickToggleFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		left = left + width + 2;
		
		if(treeNode.Expanded) then
			_this.background = "Texture/3DMapSystem/common/itemopen.png";
		else
			_this.background = "Texture/3DMapSystem/common/itemclosed.png";
		end
		
		_this = ParaUI.CreateUIObject("button", "l", "_mt", left+3, 3, 44, 22)
		_this.text = treeNode.Text;
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickToggleFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button5", "_rt", -42, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Refresh.png"
		_this.tooltip = "刷新";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickRefreshFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button4", "_rt", -21, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Department.png"
		_this.tooltip = "全部展开";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickFullExpandFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);	
	elseif(treeNode.type == "file") then
		--
		-- file
		-- 
		_this = ParaUI.CreateUIObject("button", "checkbox", "_lt", left+3, 6, 16, 16)
		local package = Map3DSystem.App.Assets.AssetManager.CurPak;
		if(package~=nil) then
			if(package:GetAsset(treeNode.Text))then
				_this.background = "Texture/checkbox.png";
			else
				_this.background = "Texture/uncheckbox.png";
			end
		end	
		_this.tooltip = "是否添加到资源包中"
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnCheckFileNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "l", "_mt", left+20, 3, 22, 22)
		_this.text = treeNode.Text;
		_guihelper.SetUIFontFormat(_this, 0+4);-- make text align to left and vertically centered. 
		_this.background = "";
		_guihelper.SetVistaStyleButton(_this, nil, "Texture/alphadot.png");
		_this.onclick = string.format(";CommonCtrl.TreeView.OnClickNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button5", "_rt", -21, 6, 16, 16)
		_this.background = "Texture/3DMapSystem/common/Refresh.png"
		_this.tooltip = "刷新";
		_this.onclick = string.format(";Map3DSystem.App.Assets.AssetManager.OnClickRefreshFolderNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);
	end	
end

-- destory the control
function Map3DSystem.App.Assets.AssetManager.OnDestroy()
	ParaUI.Destroy("AssetManager_cont");
	-- deselect package 
	Map3DSystem.App.Assets.SelectPackage(nil);
	-- remove selection
	ParaSelection.ClearGroup(1);
end

---------------------------------------------------------------
-- update UI functions
---------------------------------------------------------------

-- update the select package combo box
function Map3DSystem.App.Assets.AssetManager.UpdateComboBoxSelectPkg()
	
	local ctl = CommonCtrl.GetControl("AssetManager.comboBoxSelectPkg");
	if(ctl~=nil)then
		local items = {
			-- add names in Map3DSystem.App.Assets.AssetManager.packages
		}
		local index, pkg; 
		for index, pkg in ipairs(Map3DSystem.App.Assets.AssetManager.Packages) do
			items[index] = pkg.text;
		end
		ctl.items = items;
		if(Map3DSystem.App.Assets.AssetManager.CurPak~=nil) then
			ctl:SetText(Map3DSystem.App.Assets.AssetManager.CurPak.text);
		else
			ctl:SetText("");
		end
		ctl:RefreshListBox();
		
		-- update the pkg count. 
		commonlib.GetUIObject("AssetManager_cont#labelPkgCount").text = string.format("资源包(%d)", table.getn(items));
	end
end
			
-- update the 3d helper in the miniscenegraph.
function Map3DSystem.App.Assets.UpdateScenegraphHelper(asset)
	if(package== nil) then	
		package = Map3DSystem.App.Assets.AssetManager.CurPak
	end
	
	local scene = ParaScene.GetMiniSceneGraph("Asset");
	
	-- reset scene, in case this is called multiple times
	scene:Reset();
	-- show display
	scene:ShowHeadOnDisplay(true);
	if(asset ~= nil) then
		local _asset = ParaAsset.LoadStaticMesh("",asset.filename)
		obj = ParaScene.CreateMeshPhysicsObject("model", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
		obj:SetPosition(0,0,0);
		-- TODO: scale it properly
		obj:GetAttributeObject():SetField("progress",1);
		obj:SetHeadOnText(asset.text or asset.filename,0);
		scene:AddChild(obj);
	end
end

-- private: rebuild the package tree view according to the current package 's assets
function Map3DSystem.App.Assets.AssetManager.RebuildAssetsTreeView()
	local package = Map3DSystem.App.Assets.AssetManager.CurPak;
	if(package~=nil) then
		local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetList");
		if(ctl~=nil)then
			local node;
			local parent = ctl.RootNode;
			parent:ClearAllChildren();
			-- add the package node
			parent:AddChild( CommonCtrl.TreeNode:new({type = "package", Text = package.text or "未命名", Name = "package", Icon = package.icon, package = package}) );
			-- add assets node
			node = parent:AddChild( CommonCtrl.TreeNode:new({type = "assets", Text = "全部资源", Name = "assets", Icon = "Texture/3DMapSystem/common/Briefcase.png", package = package, Expanded = false}) );
				-- add all assets
				if(package.assets~=nil) then
					local i, asset;
					for i, asset in ipairs(package.assets) do
						node:AddChild( CommonCtrl.TreeNode:new({type = "asset", Text = asset.text, Name = tostring(i), asset = asset}) );
					end
				end	
			-- add folders node
			node = parent:AddChild( CommonCtrl.TreeNode:new({type = "folders", Text = "本地文件夹同步", Name = "folders", Icon = "Texture/3DMapSystem/common/Refresh.png", package = package, }) );
				-- add all folders
				if(package.folders~=nil) then
					local i, folder;
					for i, folder in ipairs(package.folders) do
						node:AddChild( CommonCtrl.TreeNode:new({type = "folder", Text = folder.filename, Name = tostring(i), Icon = "Texture/3DMapSystem/common/Catalog.png", folder = folder, Expanded = false}) );
					end
				end
			ctl:Update();	
		end
	end
end
-- just update tree view
function Map3DSystem.App.Assets.AssetManager.UpdateAssetsTreeView()
	local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetList");
	if(ctl~=nil)then
		ctl:Update();
	end
end

---------------------------------------------------------------
-- methods
---------------------------------------------------------------

-- select a package as the current package and display its AssetManager. 
-- when a package is (de)selected, it will (un)hook object creation events. 
-- @param package: the package object to be selected. if nil, nothing will be selected. 
function Map3DSystem.App.Assets.SelectPackage(package)
	Map3DSystem.App.Assets.AssetManager.CurPak = package;
	if(package == nil) then
		-- delete mini scene graph 
		ParaScene.DeleteMiniSceneGraph("Asset");
	else
		-- show the miniscenegraph
		Map3DSystem.App.Assets.UpdateScenegraphHelper(nil);
	end
end

-------------------------------------------------------
-- tree view event handlers
-------------------------------------------------------
-- user clicked to create a new package
function Map3DSystem.App.Assets.AssetManager.OnClickCreatePackage()
	NPL.load("(gl)script/kids/3DMapSystemApp/Assets/DlgPackage.lua");
	Map3DSystem.App.Assets.ShowCreatePackageDlg()
end

-- user clicked to display a given package
function Map3DSystem.App.Assets.AssetManager.OnSelectPackage(sCtrlName, item)
	local index, pkg; 
	for index, pkg in ipairs(Map3DSystem.App.Assets.AssetManager.Packages) do
		if(pkg.text == item) then
			Map3DSystem.App.Assets.SelectPackage(pkg);
			Map3DSystem.App.Assets.AssetManager.UpdateComboBoxSelectPkg();
			Map3DSystem.App.Assets.AssetManager.RebuildAssetsTreeView();
			break;
		end
	end
end

-- user clicks to add a new asset to the current package
function Map3DSystem.App.Assets.AssetManager.AddNewAsset()
	local package = Map3DSystem.App.Assets.AssetManager.CurPak;
	if(package~=nil) then
		-- show the open file dialog to let the user select a asset filename 
		NPL.load("(gl)script/ide/OpenFileDialog.lua");
		local ctl = CommonCtrl.OpenFileDialog:new{
			name = "OpenFileDialog1",
			title = "打开图片、3D模型等资源文件",
			alignment = "_ct",
			left=-256, top=-150,
			width = 512,
			height = 380,
			parent = nil,
			fileextensions = {"全部文件(*.*)", "3D模型(*.x; *.xml)", "图片(*.jpg; *.png; *.dds)", "视频(*.avi; *.wmv; *.swf)", },
			folderlinks = {
				{path = "model/", text = "3D模型"},
				{path = "character/", text = "3D角色"},
				{path = "Texture/", text = "图片"},
			},
			onopen = function(sCtrlName, filename) 
				-- add asset to package
				if(package:GetAsset(filename)==nil) then
					local asset,i = package:AddAsset(Map3DSystem.App.Assets.asset:new{filename=filename});
					
					-- add a tree node in UI. 
					local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetList");
					if(ctl~=nil)then
						local node;
						local parent = ctl.RootNode;
						local node = parent:GetChildByName("assets");
						node:AddChild( CommonCtrl.TreeNode:new({type = "asset", Text = asset.text or ParaIO.GetFileName(asset.filename), Name = tostring(i), asset = asset}) );
						ctl:Update();
					end
				else
					_guihelper.MessageBox(string.format("资源文件:%s 已经存在", filename));
				end	
			end
		};
		ctl:Show(true);
	end
end

-- user clicks to add a new folder. 
function Map3DSystem.App.Assets.AssetManager.AddNewFolder()
	local package = Map3DSystem.App.Assets.AssetManager.CurPak;
	if(package~=nil) then
		-- show the open file dialog to let the user select a asset filename 
		NPL.load("(gl)script/ide/OpenFileDialog.lua");
		local ctl = CommonCtrl.OpenFileDialog:new{
			name = "OpenFileDialog1",
			title = "选择需要同步的文件夹",
			alignment = "_ct",
			left=-256, top=-150,
			width = 512,
			height = 380,
			parent = nil,
			fileextensions = {"文件夹(*.)", },
			folderlinks = {
				{path = "model/", text = "3D模型"},
				{path = "character/", text = "3D角色"},
				{path = "Texture/", text = "图片"},
			},
			onopen = function(sCtrlName, filename) 
				-- folder should end with /
				if(string.find(filename, "/$")==nil) then
					filename = filename.."/";
				end
				-- add folder to package
				if(package:GetFolder(filename)==nil) then
					local folder, i = package:AddFolder(Map3DSystem.App.Assets.folder:new{filename=filename});
					
					-- add a tree node in UI. 
					local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetList");
					if(ctl~=nil)then
						local node;
						local parent = ctl.RootNode;
						local node = parent:GetChildByName("folders");
						node:AddChild( CommonCtrl.TreeNode:new({type = "folder", Text = folder.filename, Name = tostring(i), Icon = "Texture/3DMapSystem/common/Catalog.png", folder = folder, Expanded = false}) );
						ctl:Update();
					end
				else
					_guihelper.MessageBox(string.format("文件夹:%s 已经存在", filename));
				end	
			end
		};
		ctl:Show(true);
	end
end

-- user clicked to edit or show an asset node.
function Map3DSystem.App.Assets.AssetManager.OnClickAssetsNode(treeNode)
	-- only one node is selected for editing at a time
	if(Map3DSystem.App.Assets.AssetManager.SelectedAssetNode~=nil) then
		Map3DSystem.App.Assets.AssetManager.SelectedAssetNode.NodeHeight = nil;
		Map3DSystem.App.Assets.AssetManager.SelectedAssetNode.Selected = nil;
	end
	--treeNode.NodeHeight = 100;
	treeNode.Selected = true;
	Map3DSystem.App.Assets.AssetManager.SelectedAssetNode = treeNode;
	
	if(treeNode.type == "asset" or treeNode.type == "file" ) then	
		-- update attributes
		--log(commonlib.serialize(treeNode.asset));
		local asset;
		if(treeNode.type == "asset") then
			asset = treeNode.asset;
		else
			local package = Map3DSystem.App.Assets.AssetManager.CurPak;
			if(package~=nil) then
				asset = package:GetAsset(treeNode.Text);
			end	
			-- if the asset is not in package, we will creat a temp one for preview only. 
			if(asset == nil) then
				asset = Map3DSystem.App.Assets.asset:new({filename = treeNode.Text});
			end
		end
		
		-- set the current asset
		Map3DSystem.App.Assets.AssetManager.CurAsset = asset;
		
		-- update the view control.
		Map3DSystem.App.Assets.AssetViewCtl.Update(asset);
		
		local ctl = CommonCtrl.GetControl("AssetManager.treeViewAssetAttributes");
		if(ctl~=nil)then
			ctl:Update();
		end	
	end
	-- update view
	--treeNode.TreeView:Update(nil, treeNode);
end

-- user clicks to delete an asset node
function Map3DSystem.App.Assets.AssetManager.OnClickDeleteAssetNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		_guihelper.MessageBox(string.format("您确定要从资源包中将文件: %s 删除么?", node.asset.filename), function ()
			local package = Map3DSystem.App.Assets.AssetManager.CurPak;
			if(package~=nil) then
				package:RemoveAsset(node.asset.filename);
				node:Detach();
				self:Update();
			end	
		end)
	end
end

-- user clicks to refresh an asset node
function Map3DSystem.App.Assets.AssetManager.OnClickRefreshAssetNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		-- TODO: display a dialog to sync with the remote server. 
		Map3DSystem.App.Assets.AssetManager.OnClickAssetsNode(node);
	end
end

-- user clicks to delete an asset node
function Map3DSystem.App.Assets.AssetManager.OnClickDeleteFolderNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		_guihelper.MessageBox(string.format("您确定要从资源包中将文件夹: %s 删除么?", node.folder.filename), function ()
			local package = Map3DSystem.App.Assets.AssetManager.CurPak;
			if(package~=nil) then
				package:RemoveFolder(node.folder.filename);
				node:Detach();
				self:Update();
			end	
		end)
	end
end

-- user clicks to refresh a folder or directory node
-- @param bDoNotUpdate: if true ctl:Update() is not called.
function Map3DSystem.App.Assets.AssetManager.OnClickRefreshFolderNode(sCtrlName, nodePath, bDoNotUpdate)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(Map3DSystem.App.Assets.AssetManager.RefreshFolderNode(node)) then
		-- update UI if needed. 
		if(not bDoNotUpdate) then
			node.TreeView:Update(nil, node);
		end
	end	
end

-- refresh a given folder or directory node. 
-- @param bRefreshChild: whether to refresh child node. 
-- return true if refreshed
function Map3DSystem.App.Assets.AssetManager.RefreshFolderNode(node, bRefreshChild)
	if(node ~= nil and node.Text~=nil) then
		-- remove all sub nodes. 
		node:ClearAllChildren();
		
		-- add directory nodes under the current node first
		local folders = {};
		commonlib.SearchFiles(folders, ParaIO.GetCurDirectory(0)..node.Text, "*.", 0, 150, true);
		for i,v in ipairs(folders) do
			local workingdir = node.Text..v.."/";
			local newNode = node:AddChild( CommonCtrl.TreeNode:new({type = "directory", Text = workingdir, Icon = "Texture/3DMapSystem/common/Folder.png", folder = node.folder, Expanded = false}) );
			if(bRefreshChild) then
				-- refresh recursively here and make it expanded. 
				newNode.Expanded = true;
				Map3DSystem.App.Assets.AssetManager.RefreshFolderNode(newNode, bRefreshChild);
			end
		end
		
		-- add file nodes under the current node first
		local files = {};
		commonlib.SearchFiles(files, ParaIO.GetCurDirectory(0)..node.Text, node.folder.fileExt, 0, 300, true);
		for i,v in ipairs(files) do
			local filename = node.Text..v;
			node:AddChild( CommonCtrl.TreeNode:new({type = "file", Text = filename, Icon = nil, folder = node.folder, Expanded = false}));
		end
		return true;
	end
end

-- refresh all child nodes. 
function Map3DSystem.App.Assets.AssetManager.OnClickFullExpandFolderNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		-- refresh node recusively 
		node:Expand();
		if(Map3DSystem.App.Assets.AssetManager.RefreshFolderNode(node, true)) then
			node.TreeView:Update(nil, node);
		end	
	end
end

-- toggle display. it will refresh node on nodes that does not have children. 
-- so that folder hierachy is dynamically built with user interactions.
function Map3DSystem.App.Assets.AssetManager.OnClickToggleFolderNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		if(node:GetChildCount()>0) then
			CommonCtrl.TreeView.OnToggleNode(sCtrlName, nodePath);
		else
			-- empty node is always expanded and dynamically from local disk file built upon expanding. 
			node:Expand();
			Map3DSystem.App.Assets.AssetManager.OnClickRefreshFolderNode(sCtrlName, nodePath);
		end
	end
end

-- user checks a file in the folder to include/exclude from the assets
function Map3DSystem.App.Assets.AssetManager.OnCheckFileNode(sCtrlName, nodePath)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting IDE's TreeView instance "..sCtrlName.."\r\n");
		return;
	end
	local node = self:GetNodeByPath(nodePath);
	if(node ~= nil) then
		local package = Map3DSystem.App.Assets.AssetManager.CurPak;
		if(package~=nil) then
			local asset,i = package:GetAsset(node.Text);
			if(asset == nil) then
				-- add asset to package
				local asset,i = package:AddAsset(Map3DSystem.App.Assets.asset:new{filename=node.Text});
				-- add a tree node in UI. 
				node.TreeView.RootNode:GetChildByName("assets"):AddChild( CommonCtrl.TreeNode:new({type = "asset", Text = asset.text or ParaIO.GetFileName(asset.filename), Name = tostring(i), asset = asset}) );
			else
				-- remove asset
				package:RemoveAsset(asset.filename);
				
				-- detach the asset node from UI 
				local oldnode = node.TreeView.RootNode:GetChildByName("assets"):GetChildByName(tostring(i));
				if(oldnode~=nil) then
					oldnode:Detach();
				end
			end
			node.TreeView:Update(nil, node);
		end
	end
end

-- user clicks to edit the current package
function Map3DSystem.App.Assets.AssetManager.OnClickEditPackage()
	local package = Map3DSystem.App.Assets.AssetManager.CurPak;
	if(package~=nil) then
		NPL.load("(gl)script/kids/3DMapSystemApp/Assets/DlgPackage.lua");
		Map3DSystem.App.Assets.ShowEditPackageDlg(package)
	end
end

-- user clicks to save the current package
-- save the package to file and optional publish it to app server. 
function Map3DSystem.App.Assets.AssetManager.OnClickSavePackage()
	local package = Map3DSystem.App.Assets.AssetManager.CurPak;
	if(package~=nil) then
		-- TODO: currently we just save as local package
		local filename = Map3DSystem.App.Assets.SaveAsLocalPackage(package);
		if(filename) then
			_guihelper.MessageBox(string.format("资源被成功保存到文件: %s", filename));
		end
	end
end


