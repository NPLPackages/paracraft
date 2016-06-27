--[[
Title: Block Minimap
Author(s): LiXizhi
Date: 2013/6/22
Desc:  
block minimap
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockMinimap.lua");
local BlockMinimap = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockMinimap");
BlockMinimap.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local AddFlowerToWorks = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.AddFlowerToWorks");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BlockMinimap = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockMinimap");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");

local page;

BlockMinimap.interval = 200;

BlockMinimap.nid = nil;

function BlockMinimap.OnInit()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/AddFlowerToWorks.lua");
	page = document:GetPageCtrl();
end

function BlockMinimap.RefreshPage()
	BlockMinimap.timer = BlockMinimap.timer or commonlib.Timer:new({callbackFunc = BlockMinimap.OnTimer})
	BlockMinimap.timer:Change(BlockMinimap.interval, BlockMinimap.interval);

	local nid = BlockMinimap.GetOwnerNid();
	BlockMinimap.nid = nid;
	
	if(nid and nid~="") then

		local item = ItemManager.GetOPCItemByBagAndGsid(nid, AddFlowerToWorks.DonatedFlowerBag, AddFlowerToWorks.FlowerItemGsid);
		if(item and item.guid == 0) then
			ItemManager.GetItemsInOPCBag(nid, AddFlowerToWorks.DonatedFlowerBag, "pe:aries_nid"..nid, function(msg)
					local item = ItemManager.GetOPCItemByBagAndGsid(nid, AddFlowerToWorks.DonatedFlowerBag, AddFlowerToWorks.FlowerItemGsid);
				
					AddFlowerToWorks.opc_item = item;
					AddFlowerToWorks.parent_page = page;
					if(item and item.copies and item.copies>0) then
						AddFlowerToWorks.FlowerCount = item.copies;
					end

					if(page) then
						page:Refresh();
					end
				end, "access plus 35 minutes");
		elseif(item) then
			AddFlowerToWorks.FlowerCount = item.copies or 0;
		end
	end
	if(page) then
		page:Refresh();
	end
end

function BlockMinimap.GetOwnerNid()
    return WorldCommon.GetWorldTag("nid");
end

function BlockMinimap.GetFlowerCount()
	return AddFlowerToWorks.FlowerCount or 0;
end

function BlockMinimap.ShowPage(bShow, bForceShow)
	if(not bForceShow and System.options.mc) then
		return;
	end

	BlockMinimap.LoadWorldTexture();
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/BlockMinimap.html", 
			name = "BlockMinimap.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			zorder = -2,
			click_through = true,
			directPosition = true,
				align = "_rt",
				x = -200,
				y = 0,
				width = 200,
				height = 182,
		});

	if(bShow) then
		BlockMinimap.RefreshPage();
	end
end

function BlockMinimap.OnTimer(timer)
	if(not page:IsVisible()) then
		timer:Change();
	end
	local x, y, z = ParaScene.GetPlayer():GetPosition();
	page:SetUIValue("pos", string.format("%d %d %d", x, y, z));
end

local texdata = { 
    -- {left=18000,top=18000,right=22000,bottom=22000,background="Texture/Aries/WorldMaps/Teen/FlamingPhoenixIsland.png",}, 
};

local minimap_data = {}
function BlockMinimap.LoadWorldTexture(bForceRefresh)
	local world_path = ParaWorld.GetWorldDirectory();

	if(minimap_data and minimap_data[world_path] and not bForceRefresh) then
		return minimap_data[world_path];
	end

	texdata = {};

	local parent_dir = world_path.."minimap/";
	local output = {};
	commonlib.SearchFiles(output, parent_dir, "*.*", 1, 100, true, nil, "*.*");

	local _, file;
	for _, file in ipairs(output) do
		local filename = parent_dir..file;
		local region_x, region_z = file:match("^minimap_(%d+)_(%d+)");
		if(region_x and region_z) then
			region_x = tonumber(region_x);
			region_z = tonumber(region_z);
			local left, top;
			local tile_size = BlockEngine.region_width / 4;
			left = region_x * tile_size;
			top = region_z * tile_size;
			texdata[#texdata+1] = {
				left = left,
				top = top,
				right = left + tile_size,
				bottom = top + tile_size,
				background = filename,
			};
		end
	end
	minimap_data[world_path] = texdata;

	LOG.std(nil, "info", "BlockMiniMap.load", texdata);
	return texdata;
end

function BlockMinimap.DS_Func_MapTexture(index)
	if(index==nil)then
        return #texdata;
    else
        return texdata[index];
    end
end

function BlockMinimap.OnClickGenMinimap()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildMinimapTask.lua");
    local task = MyCompany.Aries.Game.Tasks.BuildMinimap:new({callbackFunc = BlockMinimap.OnMinimapTextureChanged})
    task:Run();
end

function BlockMinimap.OnMinimapTextureChanged(imagepath)
	local _, data;
	for _, data in ipairs(texdata) do
		if(data.background == imagepath) then
			CommonCtrl.OneTimeAsset.Unload(imagepath);
			return;
		end
	end
	BlockMinimap.LoadWorldTexture(true);
	if(page) then
		page:Refresh(0.01);
	end
end

function BlockMinimap.OnChangeMode()
	if(BlockMinimap.ui_mode == "map") then
        BlockMinimap.ui_mode = "social"
    else
		if(not EnterGamePage.CheckRight("minimap")) then
			return;
		end
        BlockMinimap.ui_mode = "map"
    end
	if(page) then
		page:Refresh(0.01);
	end
end

function BlockMinimap.OnDonateFlower()
    NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/AddFlowerToWorks.lua");
    local AddFlowerToWorks = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.AddFlowerToWorks");
    AddFlowerToWorks.ShowPage(true)
end


-- show context menu functions for the current world owner. 
function BlockMinimap.OnClickMenu()
    local ctl = CommonCtrl.GetControl("mc_func_buttons");
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "mc_func_buttons",
			width = 170,
			subMenuWidth = 300,
			height = 285, -- add 30(menuitemHeight) for each new line. 
			--style = CommonCtrl.ContextMenu.DefaultStyle,
			style = if_else(System.options.version=="teen", nil, {
				borderTop = 4,
				borderBottom = 4,
				borderLeft = 4,
				borderRight = 4,
				
				fillLeft = 0,
				fillTop = 0,
				fillWidth = 0,
				fillHeight = 0,
				
				titlecolor = "#283546",
				level1itemcolor = "#283546",
				level2itemcolor = "#3e7320",
				
				iconsize_x = 24,
				iconsize_y = 21,
				
				menu_bg = "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3",
				menu_lvl2_bg = "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3",
				shadow_bg = nil,
				separator_bg = "Texture/Aries/Dock/menu_separator_32bits.png", -- : 1 1 1 4
				item_bg = "Texture/Aries/Dock/menu_item_bg_32bits.png: 10 6 10 6",
				expand_bg = "Texture/Aries/Dock/menu_expand_32bits.png; 0 0 34 34",
				expand_bg_mouseover = "Texture/Aries/Dock/menu_expand_mouseover_32bits.png; 0 0 34 34",
				
				menuitemHeight = 24,
				separatorHeight = 2,
				titleHeight = 24,
				
				titleFont = "System;12;bold";
			}),
		};
	end

    ctl.RootNode:ClearAllChildren();
    local parent_node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "func", Name = "actions", Type = "Group", NodeHeight = 0 });
    local node;
    node = parent_node:AddChild(CommonCtrl.TreeNode:new({Text = "投鲜花", Name = "flower", Type = "Menuitem", onclick = BlockMinimap.OnDonateFlower}));
	node = parent_node:AddChild(CommonCtrl.TreeNode:new({Text = "----------------------", Name = "titleseparator", Type="separator", NodeHeight = 4 }));
    node = parent_node:AddChild(CommonCtrl.TreeNode:new({Text = "作者信息", Name = "owner_info", Type = "Menuitem", onclick = function()
        NPL.load("(gl)script/apps/Aries/NewProfile/NewProfileMain.lua");
        local NewProfileMain = commonlib.gettable("MyCompany.Aries.NewProfileMain");
        NewProfileMain.ShowPage(BlockMinimap.GetOwnerNid());
    end }));
	
	local x,y,width, height = _guihelper.GetLastUIObjectPos();
    
	ctl:Show(x, y+height);
end