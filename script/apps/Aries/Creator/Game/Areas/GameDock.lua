--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GameDock.lua");
local GameDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameDock");
GameDock.ShowPage(true)
-------------------------------------------------------
]]
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameDock = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameDock");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

function GameDock.OnInit()
	GameDock.RegisterCmds();
end

function GameDock.ShowPage(bShow)
	if(not GameLogic.GameMode:CanShowDock()) then
		return 
	end

	if(bShow==false) then
		GameDock.HideAllWindows()
	end
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/GameDock.html", 
			name = "GameDock.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			app_key = Desktop.App.app_key, 
			--allowDrag = true,
			bShow = bShow,
			zorder = -5,
			directPosition = true,
				align = "_rb",
				x = -150,
				y = -66,
				width = 135,
				height = 60,
		});
end

function GameDock.RegisterCmds()
	if(not GameDock.cmds)then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/PlayerModeBuilder.lua");
		local PlayerModeBuilder = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.PlayerModeBuilder");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorMachine.lua");
		local CreatorMachine = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorMachine");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/CreatorDesktop.lua");
		local CreatorDesktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.CreatorDesktop");

		GameDock.cmds = {
			["player_builder"] = { wndName = "PlayerModeBuilder.ShowPage", show_func = PlayerModeBuilder.ShowPage, },
			["creator_machine"] = { wndName = "CreatorMachine.ShowPage", show_func = CreatorMachine.ShowPage, },
			["screenshot"] = { wndName = "screenshot.ShowPage", show_func = function() 
				MyCompany.Aries.Desktop.Dock.DoSharePhotos();
			 end, },
			["system"] = { wndName = "SystemMenuPage.ShowPage", show_func = function()
				GameLogic.ToggleDesktop("esc");
			end, },
		}
	end

end

function GameDock.FireCmd(cmd,...)
	if(not cmd)then return end
	if(GameDock.last_cmd and GameDock.last_cmd ~= cmd)then
		local node = GameDock.cmds[GameDock.last_cmd];
		local wndName = node.wndName or "";
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name = wndName, app_key=Desktop.App.app_key, bShow = false,}); -- bDestroy = true,
	end
	GameDock.__FireCmd(cmd,...);
	GameDock.last_cmd = cmd;
end

function GameDock.__FireCmd(cmd,...)
	if(not cmd)then return end
	local node = GameDock.cmds[cmd];
	local wndName = node.wndName or "";
	local _wnd = GameDock.FindWindow(wndName);
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
		if(cmd == "Aries.LocalMapMCML")then
			LocalMap.Show();
			return;
		end
		if(node and node.show_func)then
			if(node.show_params) then
				node.show_func(unpack(node.show_params));
			else
				node.show_func(...);
			end
		end
	end
end

function GameDock.WindowIsShow()
	if(GameDock.cmds)then
		local k,v;
		for k,v in pairs(GameDock.cmds) do
			local wndName = v.wndName;
			local _wnd = GameDock.FindWindow(wndName);
			if(_wnd)then
				if(_wnd:IsVisible())then
					return true;
				end
			end
		end
	end
end

function GameDock.HideAllWindows()
	if(GameDock.cmds)then
		local k,v;
		for k,v in pairs(GameDock.cmds) do
			local wndName = v.wndName;
			local _wnd = GameDock.FindWindow(wndName);
			if(_wnd)then
				if(_wnd:IsVisible())then
					Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name = wndName, app_key=Desktop.App.app_key, bShow = false,}); -- bDestroy = true,
				end
			end
		end
	end
end

function GameDock.FindWindow(wndName)
	if(not wndName)then return end
	if(Desktop.App) then
		return Desktop.App:FindWindow(wndName);
	end
end

function GameDock.OnToggleBuilder(name)
	GameDock.FireCmd(name);
end