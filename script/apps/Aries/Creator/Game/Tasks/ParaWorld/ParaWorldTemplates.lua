--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldTemplates = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTemplates.lua");
ParaWorldTemplates.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rawfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local ParaWorldTemplates = NPL.export();

ParaWorldTemplates.Templates = {};
ParaWorldTemplates.CurrentIndex = 1;

local result = nil;
local page;
function ParaWorldTemplates.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldTemplates.ShowPage(onClose)
	commonlib.TimerManager.SetTimeout(function()
		result = nil;
		local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTemplates.html",
			name = "ParaWorldTemplates.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
			align = "_ct",
			x = -840 / 2,
			y = -500 / 2,
			width = 840,
			height = 500,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		
		params._page.OnClose = function()
			if (onClose) then
				onClose(result);
			end
		end

		-- https://keepwork.com/official/paracraft/config/schoolTemplate
		keepwork.rawfile.get({
				cache_policy =  "access plus 0",
				router_params = {
					repoPath = "official%%2Fparacraft",
					filePath = "official%%2Fparacraft%%2Fconfig%%2FschoolTemplate.md",
				}
		}, function(err, msg, data)
			local templates = commonlib.LoadTableFromString(data);
			if (templates) then
				ParaWorldTemplates.Templates = templates;
				ParaWorldTemplates.CurrentIndex = 1;
				page:Refresh(0);
			end
		end);
	end, 2000);
end

function ParaWorldTemplates.OnClose()
	page:CloseWindow();
end

function ParaWorldTemplates.OnOK()
	if (#ParaWorldTemplates.Templates >= ParaWorldTemplates.CurrentIndex) then
		local template = ParaWorldTemplates.Templates[ParaWorldTemplates.CurrentIndex];
		local name = commonlib.Encoding.Utf8ToDefault(template.name);
		local template_file = ParaIO.GetCurDirectory(0)..BlockTemplatePage.global_template_dir..name..".xml";
		FileDownloader:new():Init(template.name, template.url, template_file, function(res, localFile)
			result = localFile;
			page:CloseWindow();
		end);
	end
end

function ParaWorldTemplates.GetCurrentImage()
	if (#ParaWorldTemplates.Templates >= ParaWorldTemplates.CurrentIndex) then
		return ParaWorldTemplates.Templates[ParaWorldTemplates.CurrentIndex].img;
	else
		return "Texture/Aries/Creator/keepwork/ParaWorld/zuopkuang_266X134_32bits.png#0 0 32 32:8 8 8 8";
	end
end

function ParaWorldTemplates.GetCurrentName()
	if (#ParaWorldTemplates.Templates >= ParaWorldTemplates.CurrentIndex) then
		local name = ParaWorldTemplates.Templates[ParaWorldTemplates.CurrentIndex].name;
		return string.format("%s（%d/%d）", name, ParaWorldTemplates.CurrentIndex, #ParaWorldTemplates.Templates);
	end
end

function ParaWorldTemplates.GetPreviousImage()
	if (ParaWorldTemplates.CurrentIndex > 1) then
		return ParaWorldTemplates.Templates[ParaWorldTemplates.CurrentIndex-1].img;
	else
		return "";
	end
end

function ParaWorldTemplates.GetNextImage()
	if (ParaWorldTemplates.CurrentIndex < #ParaWorldTemplates.Templates) then
		return ParaWorldTemplates.Templates[ParaWorldTemplates.CurrentIndex+1].img;
	else
		return "";
	end
end

function ParaWorldTemplates.ShowPrevious()
	if (ParaWorldTemplates.CurrentIndex > 1) then
		ParaWorldTemplates.CurrentIndex = ParaWorldTemplates.CurrentIndex - 1;
	else
		ParaWorldTemplates.CurrentIndex = #ParaWorldTemplates.Templates;
	end
	page:Refresh(0);
end

function ParaWorldTemplates.ShowNext()
	if (ParaWorldTemplates.CurrentIndex < #ParaWorldTemplates.Templates) then
		ParaWorldTemplates.CurrentIndex = ParaWorldTemplates.CurrentIndex + 1;
	else
		ParaWorldTemplates.CurrentIndex = 1;
	end
	page:Refresh(0);
end