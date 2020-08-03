--[[
Title: KeepWorkMallPage
Author(s): 
Date: 2020/7/14
Desc:  
Use Lib:
-------------------------------------------------------
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.lua");
KeepWorkMallPage.Show();
--]]
local KeepWorkMallPage = NPL.export();


local page;
local level_to_index = {}
local menu_item_index = 0
KeepWorkMallPage.menu_data_sources = {}
KeepWorkMallPage.data_sources = {
	-- 全部
	{
		{
			name="type",attr={category="command",text="全部一级目录1",select_menu_item_index=1,index=1, expanded = true, level = 1},
			{
				name="type",attr={index=1,type_index=2,category="command",name="cmd",text="全部二级目录1", expanded = true, level = 2},
				{name="item",attr={menu_item_index=1,type_index=2,category="command",name="cmd",text="全部三级目录1",},},
				{name="item",attr={menu_item_index=2,type_index=2,category="command",name="actions",text="全部三级目录2",},},
			},
			{
                name="type",attr={index=2,type_index=2,category="command",name="cmd",text="全部二级目录2", level = 2},
				{name="item",attr={menu_item_index=3,type_index=2,category="command",name="cmd",text="全部三级目录3",},},
				{name="item",attr={menu_item_index=4,type_index=2,category="command",name="actions",text="全部三级目录4",},},
			},
		},
		{
            name="type",attr={category="shortcutkey",text="全部一级目录2",select_menu_item_index=1,index=2, level = 1},
			{name="item",attr={menu_item_index=5,type_index=3,category="shortcutkey",name="shortcutkey",text="全部二级目录3",},},
		},
	},

	-- 最新
	{
		{
			{
				name="type",attr={index=1,type_index=2,category="command",name="cmd",text="最新二级目录1",},
				{name="item",attr={menu_item_index=1,type_index=2,category="command",name="cmd",text="最新三级目录1",},},
				{name="item",attr={menu_item_index=2,type_index=2,category="command",name="actions",text="最新三级目录2",},},
			},
			{
				name="type",attr={index=1,type_index=2,category="command",name="cmd",text="最新二级目录2",},
				{name="item",attr={menu_item_index=3,type_index=2,category="command",name="cmd",text="最新三级目录3",},},
				{name="item",attr={menu_item_index=4,type_index=2,category="command",name="actions",text="最新三级目录4",},},
			},

			name="type",attr={category="command",text="最新一级目录1",select_menu_item_index=1,index=2,},
		},
	},

	-- 热门
	{
		{
			{
				name="type",attr={index=1,type_index=2,category="command",name="cmd",text="热门二级目录1",},
				{name="item",attr={menu_item_index=1,type_index=2,category="command",name="cmd",text="热门三级目录1",},},
				{name="item",attr={menu_item_index=2,type_index=2,category="command",name="actions",text="热门三级目录2",},},
			},
			{
				name="type",attr={index=1,type_index=2,category="command",name="cmd",text="热门二级目录2",},
				{name="item",attr={menu_item_index=3,type_index=2,category="command",name="cmd",text="热门三级目录3",},},
				{name="item",attr={menu_item_index=4,type_index=2,category="command",name="actions",text="热门三级目录4",},},
			},

			name="type",attr={category="command",text="热门一级目录1",select_menu_item_index=1,index=2,},
		},
	},
}

KeepWorkMallPage.grid_data_sources = {
	-- 全部
	{
		{{name="1_1"},{name="1_2"},{name="1_3"},{name="1_4"},{name="1_5"},{name="1_6"},{name="1_7"},{name="1_8"},{name="1_9"},{name="1_10"},{name="1_11"},{name="1_12"},{name="1_13"},{name="1_14"}},
		{{name="2_1"},{name="2_2"},{name="2_3"}},
		{{name="3_1"},{name="3_2"},{name="3_3"}},
		{{name="4_1"},{name="4_2"}},
		{{name="5_1"},{name="5_2"}},
	},
	-- 最新
	{
		{{name="1_1"},{name="1_2"},{name="1_3"},{name="1_4"}},
		{{name="2_1"},{name="2_2"},{name="2_3"}},
		{{name="3_1"},{name="3_2"},{name="3_3"}},
		{{name="4_1"},{name="4_2"}},
		{{name="5_1"},{name="5_2"}},
	},
	-- 热门
	{
		{{name="1_1"},{name="1_2"},{name="1_3"},{name="1_4"}},
		{{name="2_1"},{name="2_2"},{name="2_3"}},
		{{name="3_1"},{name="3_2"},{name="3_3"}},
		{{name="4_1"},{name="4_2"}},
		{{name="5_1"},{name="5_2"}},
	}
}
KeepWorkMallPage.cur_select_level = 1
KeepWorkMallPage.cur_select_type_index = 1
KeepWorkMallPage.top_bt_index = 1;

KeepWorkMallPage.defaul_select_menu_item_index = 2
KeepWorkMallPage.menu_item_index = KeepWorkMallPage.defaul_select_menu_item_index
function KeepWorkMallPage.OnInit()
	page = document:GetPageCtrl();
end

function KeepWorkMallPage.Show()


	local func = function(data)
		
		level_to_index = {}
		menu_item_index = 0

		local level = 1
		KeepWorkMallPage.HandleMenuData(KeepWorkMallPage.menu_data_sources, data, level)
		-- KeepWorkMallPage.menu_data_sources = data
	
		local params = {
				url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPage.html",
				name = "KeepWorkMallPage.Show", 
				isShowTitleBar = false,
				DestroyOnClose = true,
				style = CommonCtrl.WindowFrame.ContainerStyle,
				allowDrag = true,
				enable_esc_key = true,
				zorder = -1,
				app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
				directPosition = true,
					align = "_ct",
					x = -650/2,
					y = -450/2,
					width = 650,
					height = 450,
			};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		KeepWorkMallPage.OnChangeTopBt(1);
		KeepWorkMallPage.ChangeMenuType(KeepWorkMallPage.cur_select_level, KeepWorkMallPage.cur_select_type_index);
		commonlib.echo(KeepWorkMallPage.menu_data_sources, true)
	end

	local test = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/test/keepwork.mall.test.lua");
	test.menus_get(nil, func);
end
function KeepWorkMallPage.OnChangeTopBt(index)
	index = tonumber(index)
    KeepWorkMallPage.top_bt_index = index;
    KeepWorkMallPage.OnRefresh()
end
function KeepWorkMallPage.ChangeMenuItem(menu_item_index)
	menu_item_index = tonumber(menu_item_index)
    KeepWorkMallPage.menu_item_index = menu_item_index;

    KeepWorkMallPage.OnRefresh()
end
function KeepWorkMallPage.OnRefresh()
    if(page)then
        page:Refresh(0.05);
    end
end
function KeepWorkMallPage.ClickItem(index)
	
end
function KeepWorkMallPage.ChangeMenuType(level, index)
	KeepWorkMallPage.cur_select_level = level
	KeepWorkMallPage.cur_select_type_index = index
	KeepWorkMallPage.ExpandedNode(KeepWorkMallPage.menu_data_sources, level, index)
    KeepWorkMallPage.OnRefresh()
end

function KeepWorkMallPage.ExpandedNode(data, level, index)
	for k, v in pairs(data) do
		if type(v) == "table" and v.name == "type" then
			if v.attr.level == level and v.attr.index == index then
				for k2, v2 in pairs(data) do
					if type(v2) == "table" and v2.name == "type" then
						v2.attr.expanded = k2 == k
					end
				end
				return true
			else
				local find_result = KeepWorkMallPage.ExpandedNode(v, level, index)
				if (find_result) then
					for k2, v2 in pairs(data) do
						if type(v2) == "table" and v2.name == "type" then
							v2.attr.expanded = k2 == k
						end
					end
					return true
				end
			end
		end
    end

	return false
end

-- children={
-- 	{
-- 	  createdAt="2020-07-16T22:09:55.000Z",
-- 	  id=2,
-- 	  name="保健品2",
-- 	  parentId=1,
-- 	  platform=1,
-- 	  updatedAt="2020-07-16T22:09:55.000Z" 
-- 	} 
--   },
--   createdAt="2020-07-16T22:09:55.000Z",
--   id=1,
--   name="保健品",
--   parentId=0,
--   platform=1,
--   updatedAt="2020-07-16T22:09:55.000Z" 
-- } 

function KeepWorkMallPage.HandleMenuData(parent_t, data, level)
	if level_to_index[level] == nil then
		level_to_index[level] = 0
	end
	
	for k, v in pairs(data) do
		local temp_t = {}
		temp_t.name = v.children == nil and "item" or "type"
		temp_t.server_data = v
		temp_t.attr = {}
		temp_t.attr.type_index = 1
		temp_t.attr.text = v.name
		temp_t.attr.level = level
		level_to_index[level] = level_to_index[level] + 1
		-- 有子节点 说明还需要展开
		if v.children then
			temp_t.attr.index = level_to_index[level]

			local next_level = level + 1
			KeepWorkMallPage.HandleMenuData(temp_t, v.children, next_level)			
		else
			menu_item_index = menu_item_index + 1
			temp_t.attr.menu_item_index = menu_item_index
		end

		parent_t[k] = temp_t

		-- 记录默认展示的索引
		if temp_t.attr.menu_item_index and temp_t.attr.menu_item_index == KeepWorkMallPage.defaul_select_menu_item_index then
			KeepWorkMallPage.cur_select_level = parent_t.attr.level
			KeepWorkMallPage.cur_select_type_index = parent_t.attr.index
		end
	end	
end