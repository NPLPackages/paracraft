--[[
Title: Teacher Panel
Author(s): LiXizhi
Date: 2020/3/13
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Admin/TeacherPanel.lua");
local TeacherPanel = commonlib.gettable("MyCompany.Aries.Game.Network.Admin.TeacherPanel");
TeacherPanel.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetworkMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerManager.lua");
local ServerManager = commonlib.gettable("MyCompany.Aries.Game.Network.ServerManager");
local NetworkMain = commonlib.gettable("MyCompany.Aries.Game.Network.NetworkMain");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local TeacherPanel = commonlib.gettable("MyCompany.Aries.Game.Network.Admin.TeacherPanel");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local page;

TeacherPanel.bEnabled = false

function TeacherPanel.OnInit()
	page = document:GetPageCtrl();
end

function TeacherPanel.ShowPage(bShow)
	GameLogic.IsVip("OnlineTeaching", true, function(result)
		if (result) then
			if(not GameLogic.IsServerWorld()) then
				GameLogic.AddBBS(nil, L"请先启动服务器", 3000, "255 0 0");
				return
			end
			local params = {
					url = "script/apps/Aries/Creator/Game/Network/Admin/TeacherPanel.html", 
					name = "TeacherPanel.ShowPage", 
					isShowTitleBar = false,
					DestroyOnClose = true,
					bToggleShowHide=true, 
					style = CommonCtrl.WindowFrame.ContainerStyle,
					allowDrag = true,
					bShow = bShow,
					click_through = false, 
					app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
					directPosition = true,
						align = "_ctt",
						x = 0,
						y = 5,
						width = 300,
						height = 78,
				};
			System.App.Commands.Call("File.MCMLWindowFrame", params);
			TeacherPanel.bEnabled = true
		end
	end);
end

function TeacherPanel.OnClickItem(name)
	if(not TeacherPanel.bEnabled) then
		return
	end	
	if(name == "lock") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/LockDesktop.lua");
		local LockDesktop = commonlib.gettable("MyCompany.Aries.Game.Tasks.LockDesktop");
		if(LockDesktop.IsLocked()) then
			GameLogic.RunCommand("/runat @all /lock 0")
		else
			GameLogic.RunCommand("/runat @all /lock 60 "..L"同学们，请看老师")
		end
		
	elseif(name == "chat") then
		TeacherPanel.OnQuickword();
	elseif(name == "summon") then
		local player = EntityManager.GetPlayer();
		if(player) then
			local x, y, z = player:GetBlockPos()
			GameLogic.RunCommand(format("/runat @all /goto %d %d %d", x, y, z))
		end
	elseif(name == "skins") then
		GameLogic.RunCommand("/menu window.changeskin")
	elseif(name == "scale") then
		local player = EntityManager.GetPlayer();
		if(player) then
			if(player:GetScaling() >= 1.5) then
				GameLogic.RunCommand("/scaling 1")
			else
				GameLogic.RunCommand("/scaling 1.5")
			end
		end
	elseif(name == "teleport") then
		GameLogic.RunCommand("/menu online.server")
	end
end

function TeacherPanel.OnQuickword(x,y, width, height)
	if(TeacherPanel.ctlQuickWords == nil)then
		TeacherPanel.ctlQuickWords = CommonCtrl.ContextMenu:new{
			name = "Aries_Creator_Quickword",
			width = 220,
			height = 30,
			DefaultNodeHeight = 26,
			onclick = TeacherPanel.SendQuickword,
		};
		TeacherPanel.RefreshQuickword();
	end
	
	if(not x or not width) then
		x, y, width, height = _guihelper.GetLastUIObjectPos();
	end
	-- Note: 2009.9.29. Xizhi: if u ever added new menu items, please modify the height of the menu item, because animation only support "_lt" alignment. 
	if(x and width) then
		TeacherPanel.ctlQuickWords:Show(x, y+height);
	end
end

function TeacherPanel.RefreshQuickword()
	if(TeacherPanel.ctlQuickWords) then
		local node = TeacherPanel.ctlQuickWords.RootNode;
		-- clear all children first
		node:ClearAllChildren();
		node:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		local node = node:GetChild(1);
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"大家请安静", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"大家现在自由练习5分钟", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"还有1分钟, 大家抓紧时间", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"我们继续上课", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"有问题, 请举手", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"上课了", Name = "xx", Type = "Menuitem",  }));
		node:AddChild(CommonCtrl.TreeNode:new({Text = L"下课了，记得上传世界", Name = "xx", Type = "Menuitem",  }));
	end
end

function TeacherPanel.SendQuickword(node)
	GameLogic.RunCommand("/runat @all /tip -teacher "..node.Text);
end