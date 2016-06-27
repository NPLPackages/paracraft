--[[
Title: CommandHelpPage 
Author(s): zrf, refactored by LiXizhi
Date: 2011/3/9
Desc:  show the command help for the command key input by ChatEdit

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/CommandHelpPage.lua");
local CommandHelpPage = commonlib.gettable("MyCompany.Aries.ChatSystem.CommandHelpPage");
CommandHelpPage.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CommandHelpPage = commonlib.gettable("MyCompany.Aries.ChatSystem.CommandHelpPage");

local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");

local page;
local last_chat_edit_text;
local cur_chat_edit_text;
local Key_Up_Funs;

CommandHelpPage.page_be_show = false;

CommandHelpPage.HasGotCommandName = false;
CommandHelpPage.cmd_name = "";
CommandHelpPage.cmd_helps = nil;
CommandHelpPage.cur_ds = {};

function CommandHelpPage.Init()
	page = document:GetPageCtrl();
	--CommandHelpPage.OnInit()
--	CommandHelpPage.cmd_helps = CommandManager:GetCmdHelpDS();
end

function CommandHelpPage.OnInit(page_pos)
	local x,y,rows = page_pos.x + (page_pos.offset_x or 0),page_pos.y + (page_pos.offset_y or 0),page_pos.rows;
	--local row;
	--if(System.options.mc) then
        --row = 10;
    --else
        --row = 5;
    --end

	local _, _, resWidth, resHeight = ParaUI.GetUIObject("root"):GetAbsPosition();

	CommandHelpPage.gridview_row = rows;
	CommandHelpPage.height = rows * 29;

	CommandHelpPage.x = x;

	if(y + CommandHelpPage.height > resHeight) then
		CommandHelpPage.y = y - 20 - CommandHelpPage.height;
	else
		CommandHelpPage.y = y + 20;
	end
	
	if(CommandHelpPage.inited) then
		return;
	end
	CommandHelpPage.inited = true;
	
	CommandHelpPage.gridview_cell_hight = 29;

	Key_Up_Funs = {
		[Event_Mapping.EM_KEY_RETURN] = CommandHelpPage.OnKeyUp_RETURN,
		[Event_Mapping.EM_KEY_NUMPADENTER] = CommandHelpPage.OnKeyUp_RETURN,
		[Event_Mapping.EM_KEY_UP] = CommandHelpPage.OnKeyUp_UP,
		[Event_Mapping.EM_KEY_DOWN] = CommandHelpPage.OnKeyUp_DOWN,
		[Event_Mapping.EM_KEY_TAB] = CommandHelpPage.OnKeyUp_TAB,
		["other"] = CommandHelpPage.HandlerOtherKeyUp,
	};
end

function CommandHelpPage.ShowPage()
	if(System.options.IsMobilePlatform) then
		return;
	end
	CommandHelpPage.page_be_show = true;
	--local x,y,width,height;
	--if(System.options.mc) then
		--x = -1;
		--y = -337;
		--width = 600;
		--height = 300;
	--else
		--x = -5;
		--y = -287;
		--width = 600;
		--height = 150;
	--end
	local x = CommandHelpPage.x;
	local y = CommandHelpPage.y;
	local width = 600;
	local height = CommandHelpPage.height;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/CommandHelpPage.html", 
			name = "CommandHelpPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			--bShow = bShow,
			zorder = 2,
			click_through = false,
			directPosition = true,
				align = "_lt",
				x = x,
				y = y,
				width = width,
				height = height,
		});

		--left = 2, top = -330, width = 320, height = 300},
end

function CommandHelpPage.ShowCommandHelpInfo(text)
	--CommandHelpPage.OnInit();
	if(not CommandHelpPage.cmd_helps) then
		CommandHelpPage.cmd_helps = CommandManager:GetCmdHelpDS();
	end

	local cmd_name,space = string.match(text,"^/([%S]+)(%s*).*$");
	if(space ~= "") then
		CommandHelpPage.cmd_name_complete = true;
	else
		CommandHelpPage.cmd_name_complete = false;
	end

	if(not cmd_name) then
		if(string.match(text,"^/")) then
			CommandHelpPage.cmd_name = "";
			--need_refresh_page = true;
		else
			CommandHelpPage.ClosePage();
			return;
		end
	else
		CommandHelpPage.cmd_name = cmd_name;
	end
	if(CommandHelpPage.cmd_name_complete and CommandHelpPage.cmd_name and CommandHelpPage.cmd_name~="") then
		local cmd = CommandHelpPage.cmd_helps[CommandHelpPage.cmd_name]
		if(cmd) then
			GameLogic:UserAction("cmd "..CommandHelpPage.cmd_name);
		end
	end

	CommandHelpPage.ShowOrRefreshPage();
	last_chat_edit_text = cur_chat_edit_text;
	cur_chat_edit_text = text;
end

function CommandHelpPage.ShowOrRefreshPage()
	-- when the content of page switched between "cmds list" and "cmd detail" or "cmds list" changed,wo need refresh the page;
	local need_refresh_page = false;
	--CommandHelpPage.HasGotCommandName = false;

	local ds = CommandHelpPage.GetDS();
	if(CommandHelpPage.cur_ds_num == 1) then
		local cmd_name = ds[1].name;
		if(cmd_name == CommandHelpPage.cmd_name) then
			if(CommandHelpPage.HasGotCommandName) then
				-- we have found the cmd and displayed the detail info in the help page,so nedd not display it again;
				return;
			else
				CommandHelpPage.HasGotCommandName = true;
				-- from "cmds list" to "cmd detail"(we first find the cmd,we need display the detail info of this cmd in the help page)
				need_refresh_page = true;
			end
		else
			CommandHelpPage.HasGotCommandName = false;
			-- from "cmds list" to "cmd detail" or "cmds list"
			need_refresh_page = true;

		end
	else
		if(CommandHelpPage.HasGotCommandName) then
			-- from "cmds list" to "cmd detail"
			need_refresh_page = true;
		end
		CommandHelpPage.HasGotCommandName = false;
	end

	if(not CommandHelpPage.page_be_show) then
		CommandHelpPage.ShowPage();
	else
		if(need_refresh_page) then
			page:Refresh(0.01);
		else
			CommandHelpPage.RefreshCmdGrid();
		end
	end
end

local cmd_gvw_name = "gvwCmds";

function CommandHelpPage.RefreshCmdGrid()
	local node = page:GetNode(cmd_gvw_name);
	pe_gridview.DataBind(node, cmd_gvw_name, false);

	if(CommandHelpPage.scroll_value) then
		local treeview_node = node:GetChild("pe:treeview")
		if(treeview_node) then
			local ctl = treeview_node.control;
			ctl:ScrollByStep(CommandHelpPage.scroll_value)
		end
	end
end

function CommandHelpPage.GetDS()
	local ds = {};
	
	if(CommandHelpPage.cmd_name == "") then
		if(not CommandHelpPage.all_cmd_list) then
			CommandHelpPage.all_cmd_list = {};
			local all_cmd_list = CommandHelpPage.all_cmd_list;
			for cmd_name,command in pairs(CommandHelpPage.cmd_helps) do
				all_cmd_list[#all_cmd_list + 1] = command;	
			end
		end
		ds = CommandHelpPage.all_cmd_list;
	elseif(CommandHelpPage.cmd_name_complete) then
		local cmd = CommandHelpPage.cmd_helps[CommandHelpPage.cmd_name]
		if(cmd) then
			table.insert(ds,cmd);
		end
	else
		for cmd_name,command in pairs(CommandHelpPage.cmd_helps) do
			local begin_pos = string.find(cmd_name,CommandHelpPage.cmd_name);
			if(begin_pos and begin_pos == 1) then
				ds[#ds + 1] = command;	
			end
		end
	end
	table.sort(ds,function(a,b)
		return string.lower(a.name) < string.lower(b.name);
	end);
	CommandHelpPage.cur_cmd_index = 1;
	CommandHelpPage.client_top_index = 1;
	CommandHelpPage.client_bottom_index = CommandHelpPage.gridview_row;
	CommandHelpPage.cur_ds_num = #ds;
	CommandHelpPage.cur_ds = ds;
	return ds;
end

function CommandHelpPage.ClosePage()
	if(CommandHelpPage.page_be_show) then
		page:CloseWindow();
		CommandHelpPage.page_be_show = false;
	end
end

function CommandHelpPage.SelectCmd(offsetIndex)
	CommandHelpPage.cur_cmd_index = CommandHelpPage.cur_cmd_index or 0;
	local new_index = CommandHelpPage.cur_cmd_index + offsetIndex;
	if(new_index > CommandHelpPage.cur_ds_num or new_index < 1) then
		return;
	else
		CommandHelpPage.cur_cmd_index = new_index;
	end
	if(CommandHelpPage.cur_cmd_index < CommandHelpPage.client_top_index or CommandHelpPage.cur_cmd_index > CommandHelpPage.client_bottom_index) then
		CommandHelpPage.client_top_index = CommandHelpPage.client_top_index + offsetIndex;
		CommandHelpPage.client_bottom_index = CommandHelpPage.client_bottom_index + offsetIndex;
		CommandHelpPage.scroll_value = offsetIndex * CommandHelpPage.gridview_cell_hight;
	else
		CommandHelpPage.scroll_value = nil;
	end

	CommandHelpPage.RefreshCmdGrid();
end

function CommandHelpPage.SelectNextCmd()
	CommandHelpPage.SelectCmd(1);
end

function CommandHelpPage.SelectLastCmd()
	CommandHelpPage.SelectCmd(-1);
end

function CommandHelpPage.OnKeyUp_UP(callback)
	if(CommandHelpPage.page_be_show) then
		CommandHelpPage.SelectLastCmd()
	else
		if(callback) then
			callback(callback);
		end
	end
end

function CommandHelpPage.OnKeyUp_TAB(callback)
	if(CommandHelpPage.page_be_show) then
		--if(CommandHelpPage.cur_ds_num == 1) then
			CommandHelpPage.cur_cmd_index = if_else(CommandHelpPage.cur_cmd_index < 1 or CommandHelpPage.cur_cmd_index > CommandHelpPage.cur_ds_num,1,CommandHelpPage.cur_cmd_index);
			local cmd = CommandHelpPage.cur_ds[CommandHelpPage.cur_cmd_index]
			if(cmd and cmd.name) then
				local text = string.format("/%s ",cmd.name);
				ChatEdit.SetEditorText(text);
				CommandHelpPage.ShowCommandHelpInfo(text)
			end
		--end
	else
		if(callback) then
			callback(callback);
		end
	end
end

function CommandHelpPage.OnKeyUp_DOWN(callback)
	if(CommandHelpPage.page_be_show) then
		CommandHelpPage.SelectNextCmd();
	else
		if(callback) then
			callback();
		end
	end
end

function CommandHelpPage.HandlerOtherKeyUp(callback,cmd_text)
	CommandHelpPage.ShowCommandHelpInfo(cmd_text);
end

function CommandHelpPage.HandlerKeyUp(page_pos,virtual_key,callbacks,cmd_text)
	CommandHelpPage.OnInit(page_pos);
	local key_up_fun = Key_Up_Funs[virtual_key] or Key_Up_Funs["other"];
	local callback;
	if(callbacks) then
		callback = callbacks[virtual_key] or callbacks["other"];
	end
	if(System.options.is_mcworld) then
		if(key_up_fun) then
			key_up_fun(callback,cmd_text);
		end
	else
		if(callback) then
			callback();
		end
	end
	--if(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
		--if(System.options.is_mcworld and CommandHelpPage.page_be_show) then
			--CommandHelpPage.OnClickKEY_RETURN(ChatEdit.OnClickSend);
		--end		
	--elseif(virtual_key == Event_Mapping.EM_KEY_UP) then
		--if(System.options.is_mcworld and CommandHelpPage.page_be_show) then
			--CommandHelpPage.SelectLastCmd();
		--end
	--elseif(virtual_key == Event_Mapping.EM_KEY_DOWN) then	
		--if(System.options.is_mcworld and CommandHelpPage.page_be_show) then
			--CommandHelpPage.SelectNextCmd();
		--end
	--else
		--if(System.options.is_mcworld) then
			--CommandHelpPage.ShowCommandHelpInfo(sentText);
		--end
	--end
	--if(callbacks[virtual_key]) then
		--callbacks[virtual_key]();
	--end
end

function CommandHelpPage.OnKeyUp_RETURN(callback)
	if(CommandHelpPage.page_be_show) then
		-- if CommandHelpPage.cur_ds is empty(not find the cmd in xml,may can find in script),wo still allow send the cmd message to system
		if(CommandHelpPage.HasGotCommandName or (not next(CommandHelpPage.cur_ds))) then
			if(callback) then
				callback();
			end
		else
			local cmd = CommandHelpPage.cur_ds[CommandHelpPage.cur_cmd_index]
			if(cmd and cmd.name) then
				local text = string.format("/%s ",cmd.name);
				ChatEdit.SetEditorText(text);
				CommandHelpPage.ShowCommandHelpInfo(text)
			end
		end
	else
		if(callback) then
			callback();
		end
	end
end