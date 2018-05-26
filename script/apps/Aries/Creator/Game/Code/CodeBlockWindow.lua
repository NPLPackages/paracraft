--[[
Title: CodeBlockWindow
Author(s): LiXizhi
Date: 2018/5/22
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
CodeBlockWindow.Show(true)
CodeBlockWindow.SetCodeEntity(entityCode);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua")
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local CodeBlockWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow"));

local code_block_window_name = "code_block_window_";
local page;
-- this is singleton class
local self = CodeBlockWindow;

-- show code block window at the right side of the screen
-- @param bShow:
function CodeBlockWindow.Show(bShow)
	if(not bShow) then
		CodeBlockWindow.Close();
	else
		local _this = ParaUI.GetUIObject(code_block_window_name);
		if(not _this:IsValid()) then
			_this = ParaUI.CreateUIObject("container", code_block_window_name, "_mr", 0, 0, 200, 0);
			_this.zorder = -2;
			_this.background="";
			local refreshTimer = commonlib.Timer:new({callbackFunc = function(timer)
				CodeBlockWindow.Show(true)
			end})
			_this:SetScript("onsize", function()
				if(CodeBlockWindow.IsVisible()) then
					CodeBlockWindow.Show(true);
					page:Rebuild();
				end
			end)
			_this:SetScript("onclick", function() end); -- just disable click through 
			_guihelper.SetFontColor(_this, "#ffffff");
			_this:AttachToRoot();
			page = System.mcml.PageCtrl:new({url="script/apps/Aries/Creator/Game/Code/CodeBlockWindow.html"});
			page:Create(code_block_window_name.."page", _this, "_fi", 0, 0, 0, 0);
		end

		-- TODO: use a scene/ui layout manager here
		NPL.load("(gl)script/ide/System/Windows/Screen.lua");
		local Screen = commonlib.gettable("System.Windows.Screen");
		self.width = math.floor(Screen:GetWidth() * 1/3);
		_this.width = self.width;
		_this.visible = true;
		ViewportManager:GetSceneViewport():SetMarginRight(math.floor(self.width * (Screen:GetUIScaling()[2])));
	end
end

function CodeBlockWindow.SetCodeEntity(entity)
	self.entity = entity;
	local codeBlock = self.GetCodeBlock();
	if(codeBlock) then
		self.SetConsoleText(codeBlock:GetLastMessage());
		codeBlock:Connect("message", self, self.OnMessage, "UniqueConnection");
	end
	
	if(page) then
		page:SetValue("code", self.GetCodeFromEntity());
	end
end

function CodeBlockWindow:OnMessage(msg)
	self.SetConsoleText(msg);
end

function CodeBlockWindow.GetCodeFromEntity()
	if(self.entity) then
		return self.entity:GetCommand();
	end
end

function CodeBlockWindow.GetCodeEntity()
	return CodeBlockWindow.entity;
end

function CodeBlockWindow.GetCodeBlock()
	if(self.entity) then
		return self.entity:GetCodeBlock(true);
	end
end

function CodeBlockWindow.GetMovieEntity()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		return codeBlock:GetMovieEntity();
	end
end

function CodeBlockWindow.IsVisible()
	return page and page:IsVisible();
end

function CodeBlockWindow.Refresh()
	if(page) then
		page:Refresh();
	end
end

function CodeBlockWindow.Close()
	CodeBlockWindow.RestoreWindowLayout()
	CodeBlockWindow.UpdateCodeToEntity();
end

function CodeBlockWindow.RestoreWindowLayout()
	local _this = ParaUI.GetUIObject(code_block_window_name)
	if(_this:IsValid()) then
		_this.visible = false;
	end
	ViewportManager:GetSceneViewport():SetMarginRight(0);
end

function CodeBlockWindow.UpdateCodeToEntity()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(page and entity) then
		local code = page:GetUIValue("code");
		entity:SetCommand(code);
	end
end

function CodeBlockWindow.DoTextLineWrap(text)
	local lines = {};
	for line in string.gmatch(text or "", "([^\r\n]*)\r?\n?") do
		while (line) do
			local remaining_text;
			line, remaining_text = _guihelper.TrimUtf8TextByWidth(line, self.width or 300);
			lines[#lines+1] = line;
			line = remaining_text
		end
	end
	return table.concat(lines, "\n");
end

function CodeBlockWindow.SetConsoleText(text)
	if(self.console_text ~= text) then
		self.console_text = text;
		if(page) then
			page:SetValue("console", CodeBlockWindow.DoTextLineWrap(self.console_text));
		end
	end
end

function CodeBlockWindow.GetConsoleText()
	return self.console_text;
end

function CodeBlockWindow.OnClickStart()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
	end
end

function CodeBlockWindow.OnClickPause()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:Stop();
	end
end

function CodeBlockWindow.OnClickCompileAndRun()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	if(codeBlock) then
		CodeBlockWindow.UpdateCodeToEntity();

		codeBlock:CompileCode(codeEntity:GetCommand());
		codeBlock:Run();
	end
end

function CodeBlockWindow.OnClickOpenMovieBlock()
	local movieEntity = CodeBlockWindow.GetMovieEntity();
	if(movieEntity) then
		movieEntity:OpenEditor("entity");
	end
end

CodeBlockWindow:InitSingleton();