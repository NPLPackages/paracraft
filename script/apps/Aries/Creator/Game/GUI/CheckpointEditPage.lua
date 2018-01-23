--[[
Title: Edit CheckPoint Page
Author(s): dummy
Date: 2017/12/06
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.lua");
local CheckpointEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointEditPage");
CheckpointEditPage.ShowPage(block_entity);
-------------------------------------------------------

NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local CheckpointEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CheckpointEditPage");
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");

------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");

------------------------------------------------------------

local cur_checkpoint;
local cur_entity;
local page;

local function getUserPath(worldName)
	local keepWorkUserName;
	local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");
	if loginMain then
		keepWorkUserName = loginMain.username;
	end	
	if not keepWorkUserName or keepWorkUserName == "" then
		keepWorkUserName = "tempUser";
	end
	
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local world_name = worldName or WorldCommon.GetWorldTag("name");
	local userPath = "temp/saves/" .. keepWorkUserName .. "/" .. world_name .. "/";
	ParaIO.CreateDirectory(userPath);
	return userPath;
end
	
local function getWorldPath()
	local path = GameLogic.current_worlddir .. "mod/";
	ParaIO.CreateDirectory(path);
	return path;
end

function CheckpointEditPage.OnInit()
	page = document:GetPageCtrl();	
end

function CheckpointEditPage.OnClose()
    page:CloseWindow();
	page = nil;
	
	CheckpointEditPage.select_checkpoint_index = nil;
	cur_checkpoint = nil;
	CheckpointEditPage.previewImagePath = nil;
	cur_entity = nil;	
end

function CheckpointEditPage.snapshot()
--	if cur_checkpoint then
		ShareWorldPage.TakeSharePageImage();
		CheckpointEditPage.previewImagePath = ShareWorldPage.GetPreviewImagePath();
		page:SetUIValue("previewimg", CheckpointEditPage.previewImagePath);
--	end
end

function CheckpointEditPage.OnSelectImage()
	local local_filename = "";
	OpenFileDialog.ShowPage(L"请输入存盘点图片文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
		if(result and result~="" and result~=local_filename) then
			CheckpointEditPage.previewImagePath = result;
			CheckpointEditPage.UpdateImage(true);
			page:SetUIValue("previewimg", result);
		end
	end, local_filename, L"选择图片文件", "texture", nil, nil, getWorldPath())
end

function CheckpointEditPage.GetPreviewImagePath()
	if CheckpointEditPage.previewImagePath then
		if ParaIO.DoesFileExist(CheckpointEditPage.previewImagePath) then
			return CheckpointEditPage.previewImagePath;
		end	
	end
	return ShareWorldPage.GetPreviewImagePath();
end

function CheckpointEditPage.UpdateImage(bRefreshAsset)
	if(page) then
		local filepath = CheckpointEditPage.GetPreviewImagePath();
		if(bRefreshAsset) then
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end
	end
end

function CheckpointEditPage.GetEntity()
	return cur_entity;
end

function CheckpointEditPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function CheckpointEditPage.isSelected(index)
	if(CheckpointEditPage.select_checkpoint_index == index) then
		return true;
	else
		return false;
	end	
end	

function CheckpointEditPage.RefreshPreviewImagePath()
	if cur_checkpoint and cur_checkpoint.attr.previewImagePath then
		CheckpointEditPage.previewImagePath = cur_checkpoint.attr.previewImagePath;
	else
		CheckpointEditPage.previewImagePath = ShareWorldPage.GetPreviewImagePath();
	end
end

function CheckpointEditPage.SetCurCheckpoint(index)
	CheckpointEditPage.select_checkpoint_index = index;
	cur_checkpoint = CheckPointIO.world_points[index];
	
	if cur_checkpoint then		
		if cur_checkpoint[1] and cur_checkpoint[1].name == "cmpBag" and cur_entity then
			cur_entity.cmpBag:Clear();
			cur_entity.cmpBag:LoadFromXMLNode(cur_checkpoint[1]);
		end
	end
	
	if page then
		CheckpointEditPage.RefreshPreviewImagePath();
		page:SetUIValue("previewimg", CheckpointEditPage.GetPreviewImagePath());
		page:Refresh(0.01);
	end	
end	

function CheckpointEditPage.GetRulebagView()
	return cur_entity.cmpBagView;
end

function CheckpointEditPage.GetItemName()
	local name;
	if(cur_entity) then
		name = cur_entity:GetDisplayName();
	end
	local type_name;
    local block = block_types.get(CheckpointEditPage.GetItemID())
    if(block) then
        type_name = block:GetDisplayName();
	else
		local item = ItemClient.GetItem(CheckpointEditPage.GetItemID());
		if(item) then
			type_name = item:GetDisplayName();
		end
    end
	if(not name) then
		return type_name;
	else
		return name..":"..(type_name or "");
	end
end

function CheckpointEditPage.GetCheckPointCommand()
	if (cur_checkpoint) then
		return cur_checkpoint.attr.cmdList;
	else
		if (cur_entity) then	
			local x,y,z = cur_entity:GetBlockPos();
			return string.format("/goto %d %d %d", x, y + 1, z);
		else
			return "";
		end
	end
end

function CheckpointEditPage.GetBindName()
	if(cur_entity) then
		return cur_entity:GetBindName();
	end
end

function CheckpointEditPage.GetCheckpointName()
	if cur_checkpoint then
		return cur_checkpoint.name;
	elseif cur_entity then
		return cur_entity:GetDefaultCheckPointName();
	end
end

function CheckpointEditPage.ShowPage(entity, triggerEntity)
	if(not entity) then
		return;
	end
	EntityManager.SetLastTriggerEntity(entity);
	
	if(page) then
		CheckpointEditPage.OnClose();
	end
	cur_entity = entity;
	cur_checkpoint = cur_entity:GetBindCheckPoint();
	
	if cur_checkpoint then
		CheckpointEditPage.previewImagePath = cur_checkpoint.attr.previewImagePath;
		for inx, wp in ipairs(CheckPointIO.world_points) do
			if wp.name == cur_checkpoint.name then
				CheckpointEditPage.SetCurCheckpoint(inx);
				break;
			end
		end
	end

	entity:BeginEdit();
	local params = {
			url = format("script/apps/Aries/Creator/Game/GUI/CheckpointEditPage.html?id=%d", entity:GetBlockId()), 
			name = "CheckpointEditPage.ShowPage", 
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
	params._page.OnClose = function()
		EntityManager.SetLastTriggerEntity(nil);
		entity:EndEdit();
		page = nil;
	end
end

function CheckpointEditPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function CheckpointEditPage.OnClickDelete()
	local entity = cur_entity;
	if(entity) then
		local cpname = page:GetValue("cpname", "");
		if CheckPointIO.writeEmpty(cpname) then
			if page then
				page:Refresh(0.01);
			end
		end
	end
end

function CheckpointEditPage.OnClickSave()
	local entity = cur_entity;
	if(entity) then		
		local cpname = page:GetValue("cpname", "")
		local command = page:GetValue("command", "")
		command = command:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]+$", "");
		
		if CheckpointEditPage.previewImagePath ==  ShareWorldPage.GetPreviewImagePath() then
			CheckpointEditPage.previewImagePath = getWorldPath() .. cpname .. "auto.jpg";
			ParaIO.CopyFile(ShareWorldPage.GetPreviewImagePath(), CheckpointEditPage.previewImagePath, true);
		end
		
		entity:writeCheckPoint({cmdList = command, previewImagePath = CheckpointEditPage.previewImagePath}, cpname);

		entity:Refresh(true);
		
		cur_checkpoint = CheckPointIO.read(cpname);
		
		if cur_checkpoint then
			for inx, wp in ipairs(CheckPointIO.world_points) do
				if wp.name == cur_checkpoint.name then
					CheckpointEditPage.SetCurCheckpoint(inx);
					break;
				end
			end
		end
	end

end

function CheckpointEditPage.OnClickEmptyRuleSlot(slotNumber)
--[[
	local entity = cur_entity
	if(entity) then
		local contView = entity.cmpBagView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);

		end
	end
--]]	
end

function CheckpointEditPage.getCheckPointDs()
	local worldPointDs = {};
	
	
	for kk, vv in ipairs(CheckPointIO.world_points) do
		worldPointDs[kk] = {};
		worldPointDs[kk].name = vv.name;
		worldPointDs[kk].id = kk;
	end
	return worldPointDs;
end

function CheckpointEditPage.OnClickBind()
	if(cur_entity and cur_checkpoint) then
		cur_entity:SetBindName(cur_checkpoint.name);
		if page then
			page:Refresh(0.01);
		end
	end
end

function CheckpointEditPage.OnClickCreate()
	CheckpointEditPage.select_checkpoint_index = nil;
	cur_checkpoint = nil;
	
	cur_entity.cmpBag:Clear();
	--cur_entity:SetCheckpointName();
	if page then
		page:Refresh(0.01);
	end
end

function CheckpointEditPage.OnClickUp()
	if CheckpointEditPage.select_checkpoint_index > 1 then
		CheckPointIO.switchWorldPos(CheckpointEditPage.select_checkpoint_index, CheckpointEditPage.select_checkpoint_index - 1);
		CheckPointIO._writeWorld();
		CheckpointEditPage.SetCurCheckpoint(CheckpointEditPage.select_checkpoint_index - 1)
	end	
end

function CheckpointEditPage.OnClickDown()
	if CheckpointEditPage.select_checkpoint_index < #CheckPointIO.world_points then
		CheckPointIO.switchWorldPos(CheckpointEditPage.select_checkpoint_index, CheckpointEditPage.select_checkpoint_index + 1);
		CheckPointIO._writeWorld();
		CheckpointEditPage.SetCurCheckpoint(CheckpointEditPage.select_checkpoint_index + 1)
	end	
end