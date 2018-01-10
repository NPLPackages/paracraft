--[[
Title: Edit CheckPoint Page
Author(s): dummy
Date: 2017/12/06
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/BuildTaskEditPage.lua");
local BuildTaskEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BuildTaskEditPage");
BuildTaskEditPage.ShowPage(block_entity);
-------------------------------------------------------

NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BuildTaskEditPage = commonlib.gettable("MyCompany.Aries.Game.GUI.BuildTaskEditPage");
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");

------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");

------------------------------------------------------------

local cur_entity;
local page;

local taskKeyTable =
{
	["-free"] = L"自由(默认)";
	["-strict"] = L"严格";	
}

function BuildTaskEditPage.OnInit()
	page = document:GetPageCtrl();
	BuildTaskEditPage._init();
end

function BuildTaskEditPage._init()
	if page and cur_entity then
		local buildTaskType = taskKeyTable[cur_entity.taskType];
		if not buildTaskType then
			buildTaskType = taskKeyTable["-free"];
		end
		BuildTaskEditPage.bmaxPath = cur_entity.bindBmaxPath;
		page:SetNodeValue("buildTaskType", buildTaskType) -- 分辨率			
	end
end

function BuildTaskEditPage.OnClose()
	if cur_entity then
		local value = page:GetValue("buildTaskType");
		cur_entity:setRule(BuildTaskEditPage.bmaxPath, value);
		--cur_entity.bindBmaxPath = ;
	end
    page:CloseWindow();
	page = nil;
	cur_entity = nil;
	BuildTaskEditPage.bmaxPath = nil;
end

function BuildTaskEditPage.ShowPage(entity, triggerEntity)
	if(not entity) then
		return;
	end
	EntityManager.SetLastTriggerEntity(entity);
	cur_entity = entity;	
	if(page) then
		BuildTaskEditPage.OnClose();

		BuildTaskEditPage._init();	
	end
	


	entity:BeginEdit();
	local params = {
			url = format("script/apps/Aries/Creator/Game/GUI/BuildTaskEditPage.html?id=%d", entity:GetBlockId()), 
			name = "BuildTaskEditPage.ShowPage", 
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

function BuildTaskEditPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function BuildTaskEditPage.GetText()
	if BuildTaskEditPage.bmaxPath then
		return BuildTaskEditPage.bmaxPath;
	elseif cur_entity and cur_entity.bindBmaxPath then
		return cur_entity.bindBmaxPath;
	else
		return "";
	end
	
end

function BuildTaskEditPage.OnSelectBmax()
	local local_filename = "";
	OpenFileDialog.ShowPage(L"请输入bmax模板文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
		if(result and result~="" and result~=local_filename) then
			BuildTaskEditPage.bmaxPath = result;
			--page:SetNodeValue("aaaaa", BuildTaskEditPage.text)
			page:Refresh(0.01);
		end
	end, local_filename, L"选择bmax模型", "bmax")
end