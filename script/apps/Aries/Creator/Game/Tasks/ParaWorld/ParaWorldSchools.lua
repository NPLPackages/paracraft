--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldSchools = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSchools.lua");
ParaWorldSchools.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rawfile.lua");
local ParaWorldSchools = NPL.export();

ParaWorldSchools.Templates = {};
ParaWorldSchools.CurrentIndex = 1;

local result = nil;
local page;
function ParaWorldSchools.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldSchools.ShowPage(onClose, delay)
	commonlib.TimerManager.SetTimeout(function()
		result = nil;
		local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSchools.html",
			name = "ParaWorldSchools.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
			align = "_ct",
			x = -720 / 2,
			y = -420 / 2,
			width = 720,
			height = 420,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		
		params._page.OnClose = function()
			if (onClose) then
				onClose(result);
			end
		end

		-- https://keepwork.com/official/paracraft/config/paraworldTemplate
		keepwork.rawfile.get({
				cache_policy =  "access plus 0",
				router_params = {
					repoPath = "official%%2Fparacraft",
					filePath = "official%%2Fparacraft%%2Fconfig%%2FparaworldTemplate.md",
				}
		}, function(err, msg, data)
			local templates = commonlib.LoadTableFromString(data);
			if (templates) then
				ParaWorldSchools.Templates = templates;
				ParaWorldSchools.CurrentIndex = 1;
				page:Refresh(0);
			end
		end);
	end, delay or 2000);
end

function ParaWorldSchools.OnClose()
	page:CloseWindow();
end

function ParaWorldSchools.OnOK()
	if (#ParaWorldSchools.Templates >= ParaWorldSchools.CurrentIndex) then
		local template = ParaWorldSchools.Templates[ParaWorldSchools.CurrentIndex];
		local info = string.format(L"即将使用【%s】替换当前世界", template.name);
		_guihelper.MessageBox(info, function(res)
			if(res and res == _guihelper.DialogResult.OK) then
				result = template.projectId;
				page:CloseWindow();
			end
		end, _guihelper.MessageBoxButtons.OKCancel);
	end
end

function ParaWorldSchools.GetCurrentImage()
	if (#ParaWorldSchools.Templates >= ParaWorldSchools.CurrentIndex) then
		return ParaWorldSchools.Templates[ParaWorldSchools.CurrentIndex].img;
	else
		return "Texture/Aries/Creator/keepwork/ParaWorld/zuopkuang_266X134_32bits.png#0 0 32 32:8 8 8 8";
	end
end

function ParaWorldSchools.GetCurrentName()
	if (#ParaWorldSchools.Templates >= ParaWorldSchools.CurrentIndex) then
		local name = ParaWorldSchools.Templates[ParaWorldSchools.CurrentIndex].name;
		return string.format("%s（%d/%d）", name, ParaWorldSchools.CurrentIndex, #ParaWorldSchools.Templates);
	end
end

function ParaWorldSchools.ShowPrevious()
	if (ParaWorldSchools.CurrentIndex > 1) then
		ParaWorldSchools.CurrentIndex = ParaWorldSchools.CurrentIndex - 1;
	else
		ParaWorldSchools.CurrentIndex = #ParaWorldSchools.Templates;
	end
	page:Refresh(0);
end

function ParaWorldSchools.ShowNext()
	if (ParaWorldSchools.CurrentIndex < #ParaWorldSchools.Templates) then
		ParaWorldSchools.CurrentIndex = ParaWorldSchools.CurrentIndex + 1;
	else
		ParaWorldSchools.CurrentIndex = 1;
	end
	page:Refresh(0);
end