--[[
Title: for editing a collection of instance positions. 
Author(s): LiXizhi
Date: 2014/3/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TeleportListPage.lua");
local TeleportListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.TeleportListPage");
local ds = {
	{position="0,0,0", facing=0, scaling=10},
	{position="1,0,0", facing="2", scaling="1"},
	{position="2,0,0", facing="2", scaling="1"},
	{position="3,0,0", facing="2", scaling="1"},
}
TeleportListPage.ShowPage(ds);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Display3D/SceneCanvas.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TeleportListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.TeleportListPage");

-- the current data source
local instance_ds = {};

-- the mini_scene to display instances
local mini_scene = nil;
local mini_scene_name = "TeleportListPage"
local page;
function TeleportListPage.Init()
	page = document:GetPageCtrl();
end

-- create/get the mini scene
local function GetMiniScene()
	if(mini_scene) then
		return mini_scene;
	else
		mini_scene = {};
		mini_scene.scene = CommonCtrl.Display3D.SceneManager:new({uid=mini_scene_name, type = "miniscene"});
		mini_scene.rootNode = CommonCtrl.Display3D.SceneNode:new{
				root_scene = mini_scene.scene,
				visible = true,
			};
		return mini_scene;
	end
end


-- @param data_source: it should be a table array, where each item is {position="0,0,0", facing=0, scaling=10}
-- if nil, it will just show up the window
function TeleportListPage.ShowPage(data_source, bUpdateDataSource)
	if(not data_source) then
		data_source = EntityManager.GetPlayer():GetPosList();
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/TeleportListPage.html", 
			text = "Object Instances Editor",
			name = "PC.TeleportListPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_lt",
				x = 5,
				y = 70,
				width = 260,
				height = 410,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(bUpdateDataSource) then
			TeleportListPage.WriteBackToDataSource(data_source);
		end
		-- delete mini scene graph when page is closed. 
		TeleportListPage.editor_instance = nil;
		TeleportListPage.name = nil;
		TeleportListPage.SetDataSource({}, false);	
		-- TeleportListPage.RefreshMiniScene();
		page = nil;
	end

	TeleportListPage.SetDataSource(data_source, false);
	TeleportListPage.RefreshPage()
end

-- @param instance:  this is special data source type from NPC.entity.xml used by NPCList in Aries. 
function TeleportListPage.ShowForEditorInstance(instance)
	if(instance.copies) then
		local ds = {}; 
		local i;
		for i=1, instance.copies do
			local position, facing, scaling
			if(instance.positions and instance.positions[i]) then
				position = table.concat(instance.positions[i], ",")
			end
			if(instance.facings) then
				facing = tonumber(instance.facings[i])
			end
			if(instance.scalings) then
				scaling = tonumber(instance.scalings[i])
			end
			ds[#ds+1] = {position = position, facing=facing, scaling=scaling}
		end
		TeleportListPage.name = instance.name;
		TeleportListPage.editor_instance = instance;
		TeleportListPage.ShowPage(ds);
	end
end

-- this function is called whenever the user modified the data source via our editor,
-- we can inform the data source here.
function TeleportListPage.OnDataChanged()
	if(TeleportListPage.editor_instance) then
		local positions = {};
		local facings = {};
		local scalings = {};

		local copy_count = #instance_ds;
		local index, instance
		for index, instance in ipairs(instance_ds) do
			local x,y,z = instance.attr.position:match("([^,]+),([^,]+),([^,]+)");
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
			local facing = tonumber(instance.attr.facing);
			local scaling = tonumber(instance.attr.scaling);
			positions[#positions+1] = {x,y,z};
			facings[#facings+1] = facing;
			scalings[#scalings+1] = scaling;
		end
		TeleportListPage.editor_instance:SetValue("copies", copy_count);
		TeleportListPage.editor_instance:SetValue("positions", positions);
		TeleportListPage.editor_instance:SetValue("facings", facings);
		if(TeleportListPage.editor_instance.scalings) then
			TeleportListPage.editor_instance:SetValue("scalings", scalings);
		end
	end
end


function TeleportListPage.GetDataSource()
	return instance_ds;
end

function TeleportListPage.RefreshPage()
	if(page) then
		page:Refresh(0.01);
		-- TeleportListPage.RefreshMiniScene();
	end
end

local gotoCmd = {name="goto"}
local useCurPosCmd = {name="set_current"}

-- append a node to the data source 
-- @param position: string "0,0,0"
-- @param facing: number or string
-- @param scaling: number or string
function TeleportListPage.AppendNode(position, facing, scaling, name)
	local index = #instance_ds+1;
	local attr = {
		index=index, position=tostring(position or ""), 
		facing=tostring(facing or 0), 
		scaling=tostring(scaling or 1),
		name = name,
	};
	instance_ds[index] = {name="instance", attr=attr, gotoCmd, useCurPosCmd, {name="view", attr=attr}};
	TeleportListPage.SetCurrentIndex(index);
end

function TeleportListPage.OnClickInstance(treenode)
	local index = treenode.mcmlNode:GetPreValue("this").index;
	if(index) then
		if(TeleportListPage.selected_index ~= index) then
			TeleportListPage.selected_index = index;
			-- TeleportListPage.RefreshMiniScene();
		end
	end
end

-- rebuild all miniscene graph
-- Not called. 
function TeleportListPage.RefreshMiniScene()
	local miniscene = GetMiniScene();
	miniscene.rootNode:ClearAllChildren();
	local index, instance
	for index, instance in ipairs(instance_ds) do
		local x,y,z = instance.attr.position:match("([^,]+),([^,]+),([^,]+)");
		x = tonumber(x);
		y = tonumber(y);
		z = tonumber(z);
		x,y,z = BlockEngine:real(x,y,z);

		local facing = tonumber(instance.attr.facing);
		if(x and y and z) then
			if(TeleportListPage.selected_index == index) then
				-- current selected 
				-- TODO: shall we display something differently?
			end
			local node = CommonCtrl.Display3D.SceneNode:new{
				x = x,
				y = y,
				z = z,
				headontext = format("%s_%d", instance.attr.name or TeleportListPage.name or "point", index),
				headontextcolor = "0 255 0",
				facing = facing, 
				ischaracter = true,
				-- assetfile = "character/v5/06quest/DisorderRobot/DisorderRobot.x",
				assetfile = "character/common/tutorial_pointer/tutorial_pointer.x",
			};
			miniscene.rootNode:AddChild(node);
		end
	end
end

-- Internally it will make a copy of the input data source. 
-- @param data_source: it should be a table array, where each item is {position="0,0,0", facing=0, scaling=10}
-- @param bRefreshUI: true to refresh UI. 
function TeleportListPage.SetDataSource(data_source, bRefreshUI)
	if(data_source) then
		instance_ds = {};
		local _, instance;
		for _, instance in ipairs(data_source) do
			if(instance.position) then
				TeleportListPage.AppendNode(instance.position, instance.facing, instance.scaling, instance.name);
			end
		end
		TeleportListPage.selected_index = nil;
	end
	if(bRefreshUI and page) then
		TeleportListPage.RefreshPage()
	end
end

-- write data back to data source
function TeleportListPage.WriteBackToDataSource(data_source)
	if(data_source and instance_ds) then
		commonlib.resize(data_source, #instance_ds);
		for index, instance in ipairs(instance_ds) do
			data_source[index] = data_source[index] or {};
			data_source[index].position = instance.attr.position;
			data_source[index].name = instance.attr.name;
		end
	end
end

-- goto the selected node
function TeleportListPage.GotoNode(treenode)
	local index = treenode.mcmlNode:GetParent():GetPreValue("this").index;
	if(index and instance_ds[index]) then
		local instance = instance_ds[index];
		if(instance and instance.attr.position) then
			local x,y,z = instance.attr.position:match("([^,]+),([^,]+),([^,]+)");
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
			local facing = tonumber(instance.attr.facing);
			if(x and y and z) then
				TeleportListPage.TeleportToPos(x,y,z);
			end
		end
	end
end

function TeleportListPage.TeleportToPos(x,y,z)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
	local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX=x, blockY=y, blockZ=z})
	task:Run();
end

-- assign current player position to the selected node. 
function TeleportListPage.UserCurrentPosition(treenode)
	local index = treenode.mcmlNode:GetParent():GetPreValue("this").index;
	if(index and instance_ds[index]) then
		local instance = instance_ds[index];
		local player = EntityManager.GetPlayer();
		local x,y,z = player:GetBlockPos();
		local facing = player:GetFacing();
		instance.attr.position = string.format("%d,%d,%d", x,y,z);
		instance.attr.facing = string.format("%.2f", facing);
		TeleportListPage.RefreshPage()
		TeleportListPage.OnDataChanged();
	else
		_guihelper.MessageBox("Please select a node first")
	end
end

function TeleportListPage.OnSetName(name, mcmlNode)
	local index = mcmlNode:GetPreValue("this", true).index;
	if(index and instance_ds[index]) then
		local instance = instance_ds[index];
		instance.attr.name = mcmlNode:GetUIValue();
	else
		_guihelper.MessageBox("Please select a node first")
	end
end

function TeleportListPage.AddInstance()
	local player = EntityManager.GetPlayer();
    local x,y,z = player:GetBlockPos();
    local facing = player:GetFacing();
	TeleportListPage.AppendNode(string.format("%d,%d,%d", x,y,z), string.format("%.2f", facing), 1);
	TeleportListPage.RefreshPage()
	TeleportListPage.OnDataChanged();
end

function TeleportListPage.RemoveInstance()
	local treeViewCtrl = page:FindControl("tvwObjInstances");
	if(treeViewCtrl and treeViewCtrl.SelectedNode and treeViewCtrl.SelectedNode.mcmlNode) then	
		local mcmlNode = treeViewCtrl.SelectedNode.mcmlNode;
		local index = mcmlNode:GetPreValue("this").index;
		if(index) then
			local k;
			local t = instance_ds;
			local nSize = #(t);
			for k=index, nSize do
				t[k] = t[k+1];
				if(t[k]) then
					t[k].attr.index = k;
				end
			end
		end
		-- _guihelper.MessageBox({mcmlNode:GetPreValue("this"), mcmlNode.attr});
		TeleportListPage.RefreshPage()
		TeleportListPage.OnDataChanged()
	else
		_guihelper.MessageBox("Please select a node first")
	end
end

function TeleportListPage.GetPlayerLocationList()
	return EntityManager.GetPlayer():GetPosList();
end

function TeleportListPage.Refresh()
	if(page) then
		page:Refresh(0.01);
	end
end

function TeleportListPage.ClearAll()
	commonlib.resize(TeleportListPage.GetPlayerLocationList(), 0);
	TeleportListPage.Refresh();
	BroadcastHelper.PushLabel({id="TeleportListPage", label = L"跳转点清空了", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
end

local curLocation;
function TeleportListPage.GetCurrentIndex()
	return curLocation or 1;
end

function TeleportListPage.SetCurrentIndex(index)
	curLocation = index;
end

function TeleportListPage.GotoCurrentPos()
	local list = TeleportListPage.GetPlayerLocationList();
	if(#list > 0) then
		local index = TeleportListPage.GetCurrentIndex()

		local x,y,z = list[index].position:match("([^,]+),([^,]+),([^,]+)");
		x = tonumber(x);
		y = tonumber(y);
		z = tonumber(z);
		TeleportListPage.TeleportToPos(x,y,z);

		BroadcastHelper.PushLabel({id="TeleportListPage", label = L"转点到:"..list[index].position, max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

function TeleportListPage.AddCurrentLocation()
	local player = EntityManager.GetPlayer();
	local x,y,z = player:GetBlockPos();
	local facing = player:GetFacing();
	local record = {
		position = string.format("%d,%d,%d", x,y,z),
		facing = string.format("%.2f", facing),
	}
	local list = TeleportListPage.GetPlayerLocationList();
	list[#list+1] = record;
	TeleportListPage.SetCurrentIndex(#list-1);
	BroadcastHelper.PushLabel({id="TeleportListPage", label = "成功建立跳转点:"..record.position, max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
end

function TeleportListPage.GotoPreviousLocation()
	local list = TeleportListPage.GetPlayerLocationList();
	if(#list > 0) then
		 local index = (TeleportListPage.GetCurrentIndex() - 2) % (#list) + 1
		 TeleportListPage.SetCurrentIndex(index);
		 TeleportListPage.GotoCurrentPos()
	else
		BroadcastHelper.PushLabel({id="TeleportListPage", label = L"没有跳转点. Ctrl+F2建立或用/tp指令", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end

function TeleportListPage.GotoNextLocation()
	local list = TeleportListPage.GetPlayerLocationList();
	if(#list > 0) then
		 local index = (TeleportListPage.GetCurrentIndex()) % (#list) + 1
		 TeleportListPage.SetCurrentIndex(index);
		 TeleportListPage.GotoCurrentPos();
	else
		BroadcastHelper.PushLabel({id="TeleportListPage", label = L"没有跳转点. Ctrl+F2建立或用/tp指令", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
	end
end