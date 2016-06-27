--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/StaticBlockBuilder.lua");
local StaticBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.StaticBlockBuilder");
StaticBlockBuilder.ShowPage(true)
StaticBlockBuilder.LoadFromCurrentWorld()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local StaticBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.StaticBlockBuilder");

-- all block templates;
StaticBlockBuilder.ds_blocks_obstructed = {};

local page;

function StaticBlockBuilder.OnInit()
	page = document:GetPageCtrl();
	StaticBlockBuilder.ds_blocks_obstructed = ItemClient.GetBlockDS("static");
end

function StaticBlockBuilder.OneTimeInit()
	if(StaticBlockBuilder.is_inited) then
		return;
	end
	StaticBlockBuilder.is_inited = true;

	GameLogic.GetEvents():AddEventListener("block_texture_pack_changed", StaticBlockBuilder.OnBlockTexturePackChanged, StaticBlockBuilder, "StaticBlockBuilder");
end

-- called when block texture changes. 
function StaticBlockBuilder.OnBlockTexturePackChanged(self, event)
	local count = #(StaticBlockBuilder.ds_blocks_obstructed)
	
	local item_index, item;

	for item_index , item in ipairs(StaticBlockBuilder.ds_blocks_obstructed) do
		if(item and item.block_id and item.block_id>0) then
			local block_template = block_types.get(item.block_id);
			if(block_template) then
				item.icon = block_template:GetIcon() or "";
			end
		end
	end
	if(page) then
		page:Refresh();
	end
end

function StaticBlockBuilder.ShowPage(bShow)
	StaticBlockBuilder.OneTimeInit();

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/StaticBlockBuilder.html", 
			name = "StaticBlockBuilder.ShowPage", 
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
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage("getting_started_mc");
end

function StaticBlockBuilder.OnClickBlock(block_id)
    local x,y,z = ParaScene.GetPlayer():GetPosition();
    x,y,z = BlockEngine:block(x,y+0.1,z);
    local block_template = block_types.get(tonumber(block_id));
	if(block_template) then
		GameLogic.SetBlockInRightHand(block_id);
	end
end
