--[[
Title: DesktopMenu interface
Author(s): LiXizhi
Date: 2014/11/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua");
local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu");
DesktopMenu.Init();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu");

local menu_items;
local menu_name_map = {};
local edit_mode_menu = {};
local game_mode_menu = {};

function DesktopMenu.LoadMenuItems(bForceReload)
	if(menu_items and not bForceReload) then
		return menu_items;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Rebranding.lua");
	Rebranding = commonlib.gettable("MyCompany.Aries.Creator.Game.Rebranding");

	-- all menu items, both edit and game mode.  if mode="edit", it will only show in edit mode. 
	-- if onclick is nil, we will run command "/menu [name]" when the named menu item is clicked. 
	menu_items = {
		{text = L"世界", order=1, name = "file", children = 
			{
				{text = L"保存世界(Ctrl+S)",name = "file.saveworld",onclick=nil},
				{text = L"打开所在目录...",name = "file.openworlddir",onclick=nil},
				{text = L"创建世界...",name = "file.createworld",onclick=nil},
				{text = L"加载世界...",name = "file.loadworld",onclick=nil},
				{text = L"分享上传世界...",name = "file.uploadworld",onclick=nil},
				{text = L"世界备份...",name = "file.worldrevision",onclick=nil},
				{text = L"导出...",name = "file.export",onclick=nil},
				{text = L"设置...(ESC)", name = "file.settings", cmd="/menu file.settings", },
				{text = L"退出...",name = "file.exit",onclick=nil},
			},
		},
		{text = L"编辑", order=3, mode="edit", name = "edit",children = 
			{
				{text = L"撤销(Ctrl+Z)",name = "edit.undo",onclick=nil},
				{text = L"反向撤销(Ctrl+Y)",name = "edit.redo",onclick=nil},
				{text = L"删除(Del)",name = "edit.delete",onclick=nil},
				{text = L"复制(Ctrl+C)",name = "edit.copy",onclick=nil},
				{text = L"粘贴(Ctrl+V)",name = "edit.paste",onclick=nil},
				{text = L"Goto Next(F2)",name = "edit.goto",onclick=nil},
				{text = L"Goto Prev(Shift+F2)",name = "edit.goto",onclick=nil},
				{text = L"向上一层(Tab)",name = "edit.upstairs",onclick=nil},
				{text = L"向下一层(Shift+Tab)",name = "edit.downstairs",onclick=nil},
			},
		},
		{text = L"多人联网",order=4, name = "online",children = 
			{
				{text = L"服务器...",name = "online.server",onclick=nil},
				{text = L"换装...",name = "window.changeskin", onclick=nil},
			},
		},
		{text = L"窗口", order=5, mode="edit", name = "window",children = 
			{
				{text = L"创作百科...",name = "window.template", onclick=nil},
				{text = L"换装...",name = "window.changeskin", onclick=nil},
				{text = L"材质包...",name = "window.texturepack",onclick=nil},
				{text = L"信息(F3)",name = "window.info",onclick=nil},
				{text = L"位置坐标...",name = "window.pos",onclick=nil},
				{text = "NPL Debugger... (Ctrl+Alt+I)",name = "window.debugger", cmd="/open npl://debugger"},
				{text = L"MOD插件加载...",name = "window.mod",cmd="/show mod"},
			},
		},
		{text = L"帮助", order=6, name = "help",children = 
			{
				{text = L"操作提示(F1)",name = "help.actiontutorial", onclick=nil},
				{text = L"教学视频",name = "help.videotutorials", onclick=nil},
				{text = L"帮助...(Ctrl+F1)",name = "help.help", onclick=nil},
				{text = L"快捷键",name = "help.help.shortcutkey", onclick=nil},
				{text = L"提交Bug",name = "help.bug", onclick=nil},
				{text = L"NPL Code Wiki...(F11)",name = "help.npl_code_wiki", autoclose=true, onclick=nil},
				{text = L"开发文档",name = "help.ParacraftSDK", onclick=nil},
				{text = L"关于Paracraft...",name = "help.about", onclick=nil},
				{text = L"Credits",name = "help.Credits", onclick=nil},
			},
		},
	};

	-- apply filter
	menu_items = GameLogic.GetFilters():apply_filters("desktop_menu", menu_items);

	edit_mode_menu = {};
	game_mode_menu = {};

	for _, menuItem in ipairs(menu_items) do
		if(menuItem.children) then
			menuItem.ctl = CommonCtrl.ContextMenu:new{
				name = "ParaCraft.DesktopMenu."..menuItem.name,
				width = 220,
				height = 30,
				DefaultNodeHeight = 26,
				-- style = CommonCtrl.ContextMenu.DefaultStyleThick,
				onclick = DesktopMenu.OnClickMenuNode,
			};
			menuItem.ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
			DesktopMenu.RebuildMenuItem(menuItem);
			if(menuItem.mode == "edit") then
				edit_mode_menu[#edit_mode_menu+1] = menuItem;
			else
				game_mode_menu[#game_mode_menu+1] = menuItem;
				edit_mode_menu[#edit_mode_menu+1] = menuItem;
			end
			menu_name_map[menuItem.name] = menuItem;
		end
	end
	local function menu_sort_function(a, b)
		return (a.order or 0) < (b.order or 0);
	end
	table.sort(game_mode_menu, menu_sort_function);
	table.sort(edit_mode_menu, menu_sort_function);
end

function DesktopMenu.Init()
	if(DesktopMenu.bInited) then
		return;
	end
	DesktopMenu.bInited = true;
	DesktopMenu.LoadMenuItems();
end

-- return the main menu object, that one can add new object to. 
function DesktopMenu.GetCurrentMenu()
	if(GameLogic.GameMode:IsEditor()) then
		return edit_mode_menu;
	else
		return game_mode_menu;
	end
end

-- get one of the top level menu item. 
function DesktopMenu.GetMenuItem(name)
	return menu_name_map[name];
end

-- call this function to rebuild context menu items, at init time or when status of sub menu items need refresh. 
function DesktopMenu.RebuildMenuItem(menuItem)
	if(menuItem and menuItem.ctl and menuItem.children) then
		local ctl = menuItem.ctl;
		local node = ctl.RootNode:GetChild(1);
		if(node) then
			node:ClearAllChildren();
			for index, item in ipairs(menuItem.children) do
				node:AddChild(CommonCtrl.TreeNode:new({Text = item.text, Name = item.name, Type = "Menuitem", onclick = item.onclick, }));
				menu_name_map[item.name] = item;
			end
			ctl.height = #(menuItem.children) * 26 + 4;
		end
	end
end

function DesktopMenu.CloseEscFramePage()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EscFramePage.lua");
	local EscFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EscFramePage");
	EscFramePage.ShowPage(false);
end


function DesktopMenu.OnClickMenuNode(node)
	if(node and node.Name) then
		-- open menu item. 
		DesktopMenu.OnClickMenuItem(node.Name);
	end
end

-- click top menu item, normally this will show context menu
function DesktopMenu.OnClickMenuItem(name)
	local menuItem = DesktopMenu.GetMenuItem(name);
	if(menuItem) then
		if(menuItem.ctl and menuItem.children) then
			local ctl = menuItem.ctl;
			local x, y, width, height = _guihelper.GetLastUIObjectPos();
			if(x and y)then
				ctl:Show(x, y + height);
			end
		else
			if(type(menuItem.onclick) == "function") then
				menuItem.onclick(menuItem);
			elseif(menuItem.cmd) then
				GameLogic.RunCommand(menuItem.cmd);
			else
				GameLogic.RunCommand(format("/menu %s", menuItem.name));
			end
			
			-- close the esc frame page if any
			DesktopMenu.CloseEscFramePage();	
			local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");
			DesktopMenuPage.ActivateMenu(false);
		end
	end
end
