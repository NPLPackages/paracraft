--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TaskBuilder.lua");
local TaskBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TaskBuilder");
TaskBuilder.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local TaskBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TaskBuilder");
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names");

-- all block templates;
TaskBuilder.ds_task_items = ds_task_items;


local page;

function TaskBuilder.OnInit()
	page = document:GetPageCtrl();
	TaskBuilder.ds_task_items = ItemClient.GetBlockDS("task");
end

function TaskBuilder.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/TaskBuilder.html", 
			name = "TaskBuilder.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_rb",
				x = -260,
				y = -500,
				width = 250,
				height = 400,
		});
end

function TaskBuilder.OnClickBlock(block_id)
	if(GameLogic.CheckReadOnly()) then
		return;
	end
    if(block_id) then
		local item = ItemClient.GetItem(block_id)
		if(item and item.CreateAtPlayerFeet) then
   
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({block_id = block_id})
			task:Run();

			if(item.auto_equip) then
				-- nothing
			elseif(item.gold_count and item.gold_count>0) then
				GameLogic.SetBlockInRightHand(block_id);
			end
		else
			-- normal block
			GameLogic.SetBlockInRightHand(block_id);
		end
	end
end
