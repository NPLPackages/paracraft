--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderDock.lua");
local BuilderDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderDock");
BuilderDock.ShowPage(true)
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BuilderDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderDock");

function BuilderDock.OnInit()
	BuilderDock.RegisterCmds();
end

function BuilderDock.ShowPage(bShow)
	if(not GameLogic.GameMode:CanShowDock()) then
		return 
	end

	if(bShow==false) then
		BuilderDock.HideAllWindows()
	end
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/BuilderDock.html", 
			name = "BuilderDock.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			app_key = Desktop.App.app_key, 
			--allowDrag = true,
			bShow = bShow,
			zorder = -5,
			directPosition = true,
				align = "_rb",
				x = -260,
				y = -66,
				width = 240,
				height = 60,
		});
end

function BuilderDock.RegisterCmds()
	if(not BuilderDock.cmds)then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/NatureBuilder.lua");
		local NatureBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.NatureBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/StaticBlockBuilder.lua");
		local StaticBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.StaticBlockBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SpecialBlockBuilder.lua");
		local SpecialBlockBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SpecialBlockBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DecoBuilder.lua");
		local DecoBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DecoBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TaskBuilder.lua");
		local TaskBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TaskBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
		local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");

		BuilderDock.cmds = {
			["nature"] = { wndName = "NatureBuilder.ShowPage", show_func = NatureBuilder.ShowPage, },
			-- ["static_blocks"] = { wndName = "StaticBlockBuilder.ShowPage", show_func = StaticBlockBuilder.ShowPage, },
			["creator_desktop"] = { wndName = "CreatorDesktop.ShowPage", show_func = function()
				GameLogic.ToggleDesktop("builder");
			end, },
			["special_blocks"] = { wndName = "SpecialBlockBuilder.ShowPage", show_func = SpecialBlockBuilder.ShowPage, },
			["deco"] = { wndName = "DecoBuilder.ShowPage", show_func = DecoBuilder.ShowPage, },
			["task"] = { wndName = "TaskBuilder.ShowPage", show_func = TaskBuilder.ShowPage, },
			["system"] = { wndName = "SystemMenuPage.ShowPage", show_func = function()
				GameLogic.ToggleDesktop("esc");
			end, },
		}
	end

end

function BuilderDock.FireCmd(cmd,...)
	if(not cmd)then return end
	if(BuilderDock.last_cmd and BuilderDock.last_cmd ~= cmd)then
		local node = BuilderDock.cmds[BuilderDock.last_cmd];
		local wndName = node.wndName or "";
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name = wndName, app_key=Desktop.App.app_key, bShow = false,}); -- bDestroy = true,
	end
	BuilderDock.__FireCmd(cmd,...);
	BuilderDock.last_cmd = cmd;
end

function BuilderDock.__FireCmd(cmd,...)
	if(not cmd)then return end
	local node = BuilderDock.cmds[cmd];
	local wndName = node.wndName or "";
	local _wnd = BuilderDock.FindWindow(wndName);
	if(_wnd)then
		if(_wnd:IsVisible())then
			Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name = wndName, app_key=Desktop.App.app_key, bShow = false,}); -- bDestroy = true,
		else
			if(node and node.show_func)then
				if(node.show_params) then
					node.show_func(unpack(node.show_params));
				else
					node.show_func(...);
				end
			end
		end
	else
		if(node and node.show_func)then
			if(node.show_params) then
				node.show_func(unpack(node.show_params));
			else
				node.show_func(...);
			end
		end
	end
end

function BuilderDock.WindowIsShow()
	if(BuilderDock.cmds)then
		local k,v;
		for k,v in pairs(BuilderDock.cmds) do
			local wndName = v.wndName;
			local _wnd = BuilderDock.FindWindow(wndName);
			if(_wnd)then
				if(_wnd:IsVisible())then
					return true;
				end
			end
		end
	end
end

function BuilderDock.HideAllWindows()
	if(BuilderDock.cmds)then
		local k,v;
		for k,v in pairs(BuilderDock.cmds) do
			local wndName = v.wndName;
			local _wnd = BuilderDock.FindWindow(wndName);
			if(_wnd)then
				if(_wnd:IsVisible())then
					Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name = wndName, app_key=Desktop.App.app_key, bShow = false,}); -- bDestroy = true,
				end
			end
		end
	end
end

function BuilderDock.FindWindow(wndName)
	if(not wndName)then return end
	if(Desktop.App) then
		local _wnd = Desktop.App:FindWindow(wndName);
		return _wnd;
	end
end

function BuilderDock.OnToggleBuilder(name)
	BuilderDock.FireCmd(name);
end
