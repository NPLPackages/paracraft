--[[
Title: ObjectSelectPage
Author(s): LiXizhi
Date: 2014/1/10
Desc: code is from ObjectListInAreaPage.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ObjectSelectPage.lua");
local ObjectSelectPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ObjectSelectPage");
ObjectSelectPage.SelectByScreenRect(left, top, width, height);
ObjectSelectPage.SelectEntities({})
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local ObjectSelectPage = commonlib.gettable("MyCompany.Aries.Game.GUI.ObjectSelectPage");

local cur_entity;
local page;

ObjectSelectPage.name = "ObjectSelectPage";

function ObjectSelectPage.OnInit()
	page = document:GetPageCtrl();
	ObjectSelectPage.page = page;
end

local last_result = {}; 

-- @param entities: array of entities to show in select dialog
function ObjectSelectPage.SelectEntities(entities)
	last_result = {};
	for _, entity in ipairs(entities) do
		local obj = entity:GetInnerObject();
		if(obj) then
			last_result[#last_result + 1] = obj;
		end
	end
	ObjectSelectPage.ShowPage();
	ObjectSelectPage.UpdateView(true);
end

-- @param left, top, width, height: if nil, default to full screen
function ObjectSelectPage.SelectByScreenRect(left, top, width, height)
	local self = ObjectSelectPage;
	if(not left) then
		left, top, width, height = ParaUI.GetUIObject("root"):GetAbsPosition();
	end
	last_result = {}; 
	local count = ParaScene.GetObjectsByScreenRect(last_result, left, top, left + width, top + height, "4294967295", -1);
	if(count and count>0) then
		ObjectSelectPage.ShowPage();
		ObjectSelectPage.UpdateView();
	end
end

function ObjectSelectPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function ObjectSelectPage.ShowPage()
	local params = {
			name="ObjectSelectPage.ShowPage", 
			url="script/apps/Aries/Creator/Game/GUI/ObjectSelectPage.html", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			DestroyOnClose = true,
			text = L"物体编辑器",
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			directPosition = true,
				align = "_rb",
				x = -220,
				y = -544,
				width = 220,
				height = 464,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ObjectSelectPage.OnClose;
end

function ObjectSelectPage.OnClose()
end

function ObjectSelectPage.GetSelection()
	return last_result;
end


-- search nodes in a area
-- @param includeMyself: whether to include current player
function ObjectSelectPage.UpdateView(includeMyself)
	local self = ObjectSelectPage;
	
	local objList = {};
	local result = ObjectSelectPage.GetSelection();

	local ctl = CommonCtrl.GetControl(self.name.."treeView");
	if(ctl) then
		ctl.RootNode:ClearAllChildren();
		local player_id = ParaScene.GetPlayer():GetID();
		for k,obj in ipairs(result) do
			if(obj and obj:IsValid())then
				local id = obj:GetID();
				local name = obj.name or "";
				local displayName;
				local blockId = 0
				local entity = ObjectSelectPage.GetBlockEntityByObjectId(id, name)
				if(not entity) then
					entity = EntityManager.GetEntityByObjectID(id);
				end
				if(entity) then
					displayName = entity:GetDisplayName();
					blockId = entity:GetBlockId();
				end

				displayName = displayName or (tostring(id)..":"..tostring(name));
				local node = CommonCtrl.TreeNode:new({ Name = name, ID = id, displayName = displayName, blockId = blockId})
				if(not includeMyself and id == player_id)then
					
				else
					ctl.RootNode:AddChild(node);
					table.insert(objList,id);
				end
			end
		end
		ctl:Update();
	end
	self.objList = objList;
	if(#objList == 0) then
		ObjectSelectPage.CloseWindow()
	end
end

function ObjectSelectPage.DeleteAll()
	local self = ObjectSelectPage;
	if(self.objList)then
		local k,id;
		for k,id in ipairs(self.objList) do
			 self.DeleteObj(id);
		end
	end
end

function ObjectSelectPage.GetBlockEntityByObjectId(id, name)
	local entity = EntityManager.GetEntityByObjectID(id);
	if(not entity and name) then
		local x, y, z = name:match("^(%d+),(%d+),(%d+)$");
		if(x and y and z) then
			x,y,z = tonumber(x), tonumber(y), tonumber(z);
			entity = EntityManager.GetBlockEntity(x,y,z)
		end
	end
	if(entity) then
		if(entity:IsBlockEntity()) then
			return entity;
		end
	end
end

function ObjectSelectPage.SelectedObject(id)
	local self = ObjectSelectPage;
	if(not id)then return end
	local obj = ParaScene.GetObject(id);
	if(obj and obj:IsValid())then
		local entity = ObjectSelectPage.GetBlockEntityByObjectId(id, obj.name)
		if(entity) then
			local x, y, z = entity:GetBlockPos();
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
			local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
			local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blockX = x,blockY = y, blockZ = z, blocks=nil})
			task:Run();
		else
			local entity = EntityManager.GetEntityByObjectID(id)
			if(entity) then
				if(entity:isa(EntityManager.EntityLiveModel)) then
					entity:OpenEditor("entity");
				elseif(entity:isa(EntityManager.EntityNPC)) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectModelTask.lua");
					local task = MyCompany.Aries.Game.Tasks.SelectModel:new({obj=obj})
					task:Run();
				elseif(entity.OpenEditor) then
					entity:OpenEditor("entity");
				end
			else
				ParaSelection.AddObject(obj,1);
			end
		end
	end
end

function ObjectSelectPage.DeleteObj(id)
	local self = ObjectSelectPage;
	if(not id)then return end
	local obj = ParaScene.GetObject(id);
	if(obj and obj:IsValid())then
		local entity = EntityManager.GetEntityByObjectID(id);
		if(entity) then
			if(entity:IsBlockEntity()) then
				local bx, by, bz = entity:GetBlockPos();
				local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = bx,blockY = by, blockZ = bz, })
				task:Run();
			else
				entity:SetDead();
			end
		else
			if(not obj:CheckAttribute(0x8000)) then
				-- OBJ_SKIP_PICKING = 0x1<<15:
				ParaScene.Delete(obj);
				return true;
			else
				local x, y, z = obj.name:match("^(%d+),(%d+),(%d+)$");
				if(x and y and z) then
					x,y,z = tonumber(x), tonumber(y), tonumber(z);
					local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = x,blockY = y, blockZ = z, })
					task:Run();
				end
			end
		end
	end
end
function ObjectSelectPage.CreateObjTreeView(params)
	if(not params)then return end
	local self = ObjectSelectPage;
	local _this = ParaUI.GetUIObject("container"..self.name);
	if(not _this:IsValid()) then
		_this = ParaUI.CreateUIObject("container", "container"..self.name, params.alignment, params.left, params.top, params.width, params.height);
		_this.background = params.background or "";
		params.parent:AddChild(_this);
	end	
	local ctl = CommonCtrl.TreeView:new{
		name = self.name.."treeView",
		alignment = "_fi",
		left=0, top=0,
		width = 0,
		height = 0,
		parent = _this,
		DefaultNodeHeight = 22,
		ShowIcon = false,
		DrawNodeHandler = ObjectSelectPage.DrawSingleSelectionNodeHandler,	
	};
	ctl:Show();
	CommonCtrl.AddControl(ctl.name,ctl);
end
function ObjectSelectPage.DrawSingleSelectionNodeHandler(_parent,treeNode)
	if(_parent == nil or treeNode == nil) then
		return
	end
	local _this;
	local left = 2; -- indentation of this node. 
	local top = 2;
	local height = treeNode:GetHeight();
	local nodeWidth = treeNode.TreeView.ClientWidth;
	
	if(treeNode.TreeView.ShowIcon) then
		local IconSize = treeNode.TreeView.DefaultIconSize;
		if(treeNode.Icon~=nil and IconSize>0) then
			_this=ParaUI.CreateUIObject("button","b","_lt", left, (height-IconSize)/2 , IconSize, IconSize);
			_this.background = treeNode.Icon;
			_guihelper.SetUIColor(_this, "255 255 255");
			_parent:AddChild(_this);
		end	
		if(not treeNode.bSkipIconSpace) then
			left = left + IconSize;
		end	
	end	
	if(treeNode.TreeView.RootNode:GetHeight() > 0) then
		left = left + treeNode.TreeView.DefaultIndentation*treeNode.Level + 2;
	else
		left = left + treeNode.TreeView.DefaultIndentation*(treeNode.Level-1) + 2;
	end	
	if(treeNode.ID ~= nil) then
		if(treeNode.blockId ~= 0) then
			_this=ParaUI.CreateUIObject("button","b","_lt", left, 3 , 16, 16);
			_guihelper.SetUIColor(_this, "255 255 255 255");
			local background = "";
			local item = ItemClient.GetItem(treeNode.blockId)
			if(item) then
				background = item:GetIcon();
			end
			_this.background = background;
			_parent:AddChild(_this);
			left = left + 16 + 2;
		end
		_this=ParaUI.CreateUIObject("button","b","_lt", left, 0 , nodeWidth - left-2 - 40, height - 1);
		_this.background = System.mcml_controls.pe_css.default["button_lightgrey"].background;
		_parent:AddChild(_this);
			
		_this.onclick = string.format(";MyCompany.Aries.Game.GUI.ObjectSelectPage.OnSelectNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		local displayName = treeNode.displayName:sub(1, 40);
		_this.text = displayName;
		local tooltip = treeNode.displayName:sub(1, 256)
		_this.tooltip = tooltip
		_this:SetField("TextOffsetX", 5)
		

		_guihelper.SetUIFontFormat(_this, 36);
			
		_this=ParaUI.CreateUIObject("button","b","_rt", -38, top, 16, 16);
		_this.background = "Texture/3DMapSystem/common/searchIcon.png";
		_this.tooltip = "瞬移";
		_this.onclick = string.format(";MyCompany.Aries.Game.GUI.ObjectSelectPage.OnGotoPos(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);	
		_this=ParaUI.CreateUIObject("button","b","_rt", -20, top, 16, 16);
		_this.background = "Texture/3DMapSystem/common/Close.png";
		_this.tooltip = "删除";
		_this.onclick = string.format(";MyCompany.Aries.Game.GUI.ObjectSelectPage.OnDeleteNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
		_parent:AddChild(_this);	
	end	
end
function ObjectSelectPage.OnSelectNode(sCtrlName, nodePath)
	local self = ObjectSelectPage;
	local ctl = CommonCtrl.GetControl(sCtrlName);
	if(ctl)then
		local node = ctl:GetNodeByPath(nodePath);
		if(node ~= nil) then
			self.SelectedObject(node.ID);
		end
	end
end
function ObjectSelectPage.OnDeleteAll()
	local self = ObjectSelectPage;
	self.DeleteAll();
	local ctl = CommonCtrl.GetControl(self.name.."treeView");
	if(ctl)then
		ctl.RootNode:ClearAllChildren();
		ctl:Update();
	end
end
function ObjectSelectPage.OnGotoPos(sCtrlName, nodePath)
	local ctl = CommonCtrl.GetControl(sCtrlName);
	if(ctl)then
		local node = ctl:GetNodeByPath(nodePath);
		if(node ~= nil) then
			local id = node.ID;
			local obj = ParaScene.GetObject(id);
			if(obj and obj:IsValid())then
				local x,y,z = obj:GetPosition();
				Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_TELEPORT_PLAYER, x= x, y = y, z = z});
			end
		end
	end
end
function ObjectSelectPage.OnDeleteNode(sCtrlName, nodePath)
	local self = ObjectSelectPage;
	local ctl = CommonCtrl.GetControl(sCtrlName);
	if(ctl)then
		local node = ctl:GetNodeByPath(nodePath);
		if(node ~= nil) then
			local id = node.ID;
			if(self.DeleteObj(id)) then
				node:Detach();
				ctl:Update();
			end
		end
	end
end