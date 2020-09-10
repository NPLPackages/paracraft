--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldTakeSeat = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTakeSeat.lua");
ParaWorldTakeSeat.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
local ParaWorldTakeSeat = NPL.export();

ParaWorldTakeSeat.WorldList = {};

local result = false;
local worldId = nil;
local page;
function ParaWorldTakeSeat.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldTakeSeat.ShowPage(onClose)
	result = false;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTakeSeat.html",
		name = "ParaWorldTakeSeat.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -400 / 2,
		y = -200 / 2,
		width = 400,
		height = 200,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	params._page.OnClose = function()
		if (onClose) then
			onClose(result, worldId);
		end
	end

	commonlib.TimerManager.SetTimeout(function()
		keepwork.miniworld.mylist(nil, function(err, msg, data)
			if (data and data.rows and #data.rows > 0) then
				ParaWorldTakeSeat.WorldList = data.rows;
				page:Refresh(0);
			else
				_guihelper.MessageBox(L"您还未上传任何世界，请先上传您自己创造的世界！");
				if (page) then
					page:CloseWindow();
				end
			end
		end);
	end, 100);
end

function ParaWorldTakeSeat.OnOK()
	worldId = page:GetValue("WorldList", nil);
	if (worldId) then
		worldId = tonumber(worldId);
		result = (worldId ~= nil);
	end
	page:CloseWindow();
end

function ParaWorldTakeSeat.OnClose()
	result = false;
	page:CloseWindow();
end

function ParaWorldTakeSeat.GetMiniWorldList()
	local worldList = {};
	for i = 1, #ParaWorldTakeSeat.WorldList do
		local world = ParaWorldTakeSeat.WorldList[i];
		worldList[i] = {text = world.name.."（"..world.projectId.."）", value = world.projectId};
	end
	return worldList;
end
