--[[
Title: List CheckPoint Page
Author(s): dummy
Date: 2017/12/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointListPage.lua");
local CheckpointListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointListPage");
CheckpointListPage.ShowPage(block_entity);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local CheckpointListPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointListPage");
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");


local page;

function CheckpointListPage.OnInit()
	page = document:GetPageCtrl();
end

function CheckpointListPage.OnClose()
    page:CloseWindow();
	page = nil;
end

function CheckpointListPage.isSelected(index)
	if(CheckpointListPage.select_checkpoint_index == index) then
		return true;
	else
		return false;
	end	
end

function CheckpointListPage.GetPreviewImagePath(cpname)
	local cpData = CheckPointIO.read(cpname);
	if cpData and cpData.attr.previewImagePath then
		return cpData.attr.previewImagePath;
	end
	--return ParaWorld.GetWorldDirectory().."preview.jpg";
end

function CheckpointListPage.getCheckPointDs()
	local worldPointDs = {};
	
	
	for kk, vv in ipairs(CheckPointIO.world_points) do
		worldPointDs[kk] = {};
		worldPointDs[kk].name = vv.name;
		worldPointDs[kk].id = kk;
		
		local cpData = CheckPointIO.read(vv.name);
		if cpData then
			worldPointDs[kk].isOpen = cpData.isOpen;
		end
	end
	return worldPointDs;
end

function CheckpointListPage.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/GUI/CheckpointListPage.html", 
		name = "CheckpointListPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		bShow = true,
		click_through = true, 
		zorder = -1,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		bAutoSize = true,
		bAutoHeight = true,
		-- cancelShowAnimation = true,
		directPosition = true,
			align = "_ct",
			x = -200,
			y = -250,
			width = 800,
			height = 500,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CheckpointListPage.GetShowList()
	local str_list = "";
	for _, v in pairs(CheckPointIO.check_points) do
		str_list = str_list .. string.format("check point name:%s status:%s\n", v.name, tostring(v.isOpen or false));
	end
	return str_list;
end

function CheckpointListPage.SetCurCheckpoint(index, isOpen)
	CheckpointListPage.select_checkpoint_index = index;
	CheckpointListPage.select_checkpoint_open = isOpen;
	--if page then
	--	page:Refresh(0.01);
	--end	
end

function CheckpointListPage.LoadCheckPoint()
	if CheckpointListPage.select_checkpoint_open then
		local cpData = CheckPointIO.world_points[CheckpointListPage.select_checkpoint_index];
		if cpData then
			local save_cmd = string.format("/checkpoint save %s", cpData.name);
			local load_cmd = string.format("/checkpoint load %s", cpData.name);
			GameLogic.RunCommand(save_cmd);
			GameLogic.RunCommand(load_cmd);
			return true;
		end
	else
		return false;
	end
end