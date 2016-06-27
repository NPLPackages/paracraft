--[[
Title: World Frame Page
Author(s): LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldFramePage.lua");
local WorldFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldFramePage");
WorldFramePage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local WorldFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldFramePage");

local page;

WorldFramePage.category_index = 1;
WorldFramePage.Current_Item_DS = {};

WorldFramePage.category_ds = {
    {text="世界设置", name="save"},
    {text="推广世界", name="share"},
}

function WorldFramePage.OnInit()
	WorldFramePage.OneTimeInit();
	page = document:GetPageCtrl();

	WorldFramePage.OnChangeCategory(nil, false);
end

function WorldFramePage.OneTimeInit()
	if(WorldFramePage.is_inited) then
		return;
	end
	WorldFramePage.is_inited = true;
end

-- clicked a block
function WorldFramePage.OnClickBlock(block_id)
end

-- @param bRefreshPage: false to stop refreshing the page
function WorldFramePage.OnChangeCategory(index, bRefreshPage)
    WorldFramePage.category_index = index or WorldFramePage.category_index;
	
	local category = WorldFramePage.category_ds[WorldFramePage.category_index];
	if(category) then
		-- WorldFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
	end
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end