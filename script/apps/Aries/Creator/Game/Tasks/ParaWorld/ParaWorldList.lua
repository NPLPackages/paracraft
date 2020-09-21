--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldList.lua");
ParaWorldList.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
local ParaWorldList = NPL.export();

ParaWorldList.Current_Item_DS = {};

local page;
function ParaWorldList.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldList.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldList.html",
		name = "ParaWorldList.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -860 / 2,
		y = -420 / 2,
		width = 860,
		height = 420,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
		ParaWorldList.Current_Item_DS[i] = nil;
	end
	commonlib.TimerManager.SetTimeout(function()
		keepwork.world.mylist(nil, function(err, msg, data)
			if (err == 200 and data) then
				for i = 1, #data do
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data[i];
				end
			end

			keepwork.world.list(nil, function(err, msg, data)
				if (data and data.rows) then
					for i = 1, #(data.rows) do
						local exist = false;
						for j = 1, #ParaWorldList.Current_Item_DS do
							if (ParaWorldList.Current_Item_DS[j].projectId == data.rows[i].projectId and ParaWorldList.Current_Item_DS[j].name == data.rows[i].name) then
								exist = true;
								break;
							end
						end
						if (not exist) then
							ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data.rows[i];
						end
					end
					page:Refresh(0);
				end
			end);
		end);
	end, 100);
end

function ParaWorldList.OnClose()
	page:CloseWindow();
end

function ParaWorldList.OnClickItem(index)
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.projectId) then
		page:CloseWindow();
		GameLogic.RunCommand("/loadworld -force "..item.projectId);
	end
end