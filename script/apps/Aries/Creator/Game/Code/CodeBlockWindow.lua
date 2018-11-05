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
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local CodeBlockWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow"));

-- when entity being edited is changed. 
CodeBlockWindow:Signal("entityChanged", function(entity) end)

local code_block_window_name = "code_block_window_";
local page;
local groupindex_hint = 3; 
-- this is singleton class
local self = CodeBlockWindow;

-- show code block window at the right side of the screen
-- @param bShow:
function CodeBlockWindow.Show(bShow)
	if(not bShow) then
		CodeBlockWindow.Close();
	else
		GameLogic:desktopLayoutRequested("CodeBlockWindow");
		GameLogic:Connect("desktopLayoutRequested", CodeBlockWindow, CodeBlockWindow.OnLayoutRequested, "UniqueConnection");
	
		local _this = ParaUI.GetUIObject(code_block_window_name);
		if(not _this:IsValid()) then
			self.width, self.height, self.margin_right, self.bottom = self:CalculateMargins();
			_this = ParaUI.CreateUIObject("container", code_block_window_name, "_mr", 0, 0, self.width, self.bottom);
			_this.zorder = -2;
			_this.background="";
			local refreshTimer = commonlib.Timer:new({callbackFunc = function(timer)
				CodeBlockWindow.Show(true)
			end})
			_this:SetScript("onsize", function()
				CodeBlockWindow:OnViewportChange();
			end)
			local viewport = ViewportManager:GetSceneViewport();
			viewport:SetMarginRight(self.margin_right);
			viewport:SetMarginRightHandler(self);
			viewport:Connect("sizeChanged", CodeBlockWindow, CodeBlockWindow.OnViewportChange, "UniqueConnection");

			_this:SetScript("onclick", function() end); -- just disable click through 
			_guihelper.SetFontColor(_this, "#ffffff");
			_this:AttachToRoot();
			page = System.mcml.PageCtrl:new({url="script/apps/Aries/Creator/Game/Code/CodeBlockWindow.html"});
			page:Create(code_block_window_name.."page", _this, "_fi", 0, 0, 0, 0);
		end

		_this.visible = true;
		CodeBlockWindow:OnViewportChange();
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginRight(self.margin_right);
		viewport:SetMarginRightHandler(self);

		GameLogic:Connect("beforeWorldSaved", CodeBlockWindow, CodeBlockWindow.OnWorldSave, "UniqueConnection");

		CodeBlockWindow:LoadSceneContext();
	end
end

function CodeBlockWindow:OnLayoutRequested(requesterName)
	if(requesterName ~= "CodeBlockWindow") then
		if(CodeBlockWindow.IsVisible()) then
			CodeBlockWindow.Show(false);
		end
	end
end

-- @return margin_right and bottom
function CodeBlockWindow:CalculateMargins()
	local MAX_3DCANVAS_WIDTH = 800;
	local MIN_CODEWINDOW_WIDTH = 200+350;
	local viewport = ViewportManager:GetSceneViewport();
	local width = math.max(math.floor(Screen:GetWidth() * 1/3), MIN_CODEWINDOW_WIDTH);
	local halfScreenWidth = math.floor(Screen:GetWidth()/2);
	if(halfScreenWidth > MAX_3DCANVAS_WIDTH) then
		width = halfScreenWidth;
	elseif((Screen:GetWidth() - width) > MAX_3DCANVAS_WIDTH) then
		width = Screen:GetWidth() - MAX_3DCANVAS_WIDTH;
	end

	local bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2]);
	local margin_right = math.floor(width * Screen:GetUIScaling()[1]);
	return width, Screen:GetHeight()-bottom, margin_right, bottom;
end

function CodeBlockWindow:OnViewportChange()
	if(CodeBlockWindow.IsVisible()) then
		-- TODO: use a scene/ui layout manager here
		local width, height, margin_right, bottom = self:CalculateMargins();
		if(self.width ~= width or self.height ~= height) then
			self.width = width;
			self.height = height;
			self.margin_right = margin_right;
			self.bottom = bottom;
			local viewport = ViewportManager:GetSceneViewport();
			viewport:SetMarginRight(self.margin_right);
			viewport:SetMarginRightHandler(self);
			local _this = ParaUI.GetUIObject(code_block_window_name);
			_this:Reposition("_mr", 0, 0, self.width, self.bottom);
			if(page) then
				CodeBlockWindow.UpdateCodeToEntity();
				page:Rebuild();
			end

			CodeBlockWindow.UpdateBlocklyWindowSize();
		end
	end
end

function CodeBlockWindow.OnWorldSave()
	CodeBlockWindow.UpdateCodeToEntity();
end

function CodeBlockWindow.HighlightCodeEntity(entity)
	if(self.entity) then
		local x, y, z = self.entity:GetBlockPos();
		ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint);
	end
	if(entity) then
		local x, y, z = entity:GetBlockPos();
		ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint);
	end
end

function CodeBlockWindow:OnEntityRemoved()
	CodeBlockWindow.SetCodeEntity(nil);
end

function CodeBlockWindow.RestoreCursorPosition()
	if(self.entity and self.entity.cursorPos) then
		commonlib.TimerManager.SetTimeout(function()  
			local ctrl = CodeBlockWindow.GetTextControl();
			if(ctrl) then
				if(self.entity and self.entity.cursorPos) then
					local cursorPos = self.entity.cursorPos;
					ctrl:moveCursor(cursorPos.line, cursorPos.pos, false, true);
				end
			end
		end, 200);
	end
end

function CodeBlockWindow.SetCodeEntity(entity)
	CodeBlockWindow.HighlightCodeEntity(entity);
	local isEntityChanged = false;
	if(self.entity ~= entity) then
		if(entity) then
			entity:Connect("beforeRemoved", self, self.OnEntityRemoved, "UniqueConnection");
		end
		if(self.entity) then
			self.entity:Disconnect("beforeRemoved", self, self.OnEntityRemoved);
			CodeBlockWindow.UpdateCodeToEntity();
		end
		self.entity = entity;
		if(page) then
			page:Refresh(0.01);
		end
		CodeBlockWindow.RestoreCursorPosition();
		isEntityChanged = true;
	end

	local codeBlock = self.GetCodeBlock();
	if(codeBlock) then
		local text = codeBlock:GetLastMessage() or "";
		if(text == "" and not CodeBlockWindow.GetMovieEntity()) then
			if(self.entity) then
				if(self.entity:AutoCreateMovieEntity()) then
					text = L"我们在代码方块旁边自动创建了一个电影方块! 你现在可以用代码控制电影方块中的演员了!";
				else
					text = L"没有找到电影方块! 请将一个包含演员的电影方块放到代码方块的旁边，就可以用代码控制演员了!";
				end
			end
		end
		self.SetConsoleText(text);

		codeBlock:Connect("message", self, self.OnMessage, "UniqueConnection");
	end
	if(isEntityChanged) then
		self:entityChanged(self.entity);
	end
end

function CodeBlockWindow:OnMessage(msg)
	self.SetConsoleText(msg or "");
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

function CodeBlockWindow.Close()
	if(CodeBlockWindow.isBlocklyOpened) then
		CodeBlockWindow.CloseBlocklyWindow();
	end
	CodeBlockWindow:UnloadSceneContext();
	CodeBlockWindow.RestoreWindowLayout()
	CodeBlockWindow.UpdateCodeToEntity();
	CodeBlockWindow.HighlightCodeEntity(nil);

	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock and codeBlock:GetEntity()) then
		local entity = codeBlock:GetEntity();
		if(entity:IsPowered() and (not codeBlock:IsLoaded() or codeBlock:HasRunningTempCode())) then
			entity:Restart();
		elseif(not entity:IsPowered() and (codeBlock:IsLoaded() or codeBlock:HasRunningTempCode())) then
			entity:Stop();
		end
	end
end

function CodeBlockWindow.RestoreWindowLayout()
	local _this = ParaUI.GetUIObject(code_block_window_name)
	if(_this:IsValid()) then
		_this.visible = false;
	end
	local viewport = ViewportManager:GetSceneViewport();
	if(viewport:GetMarginRightHandler() == self) then
		viewport:SetMarginRightHandler(nil);
		viewport:SetMarginRight(0);
	end
end

function CodeBlockWindow.UpdateCodeToEntity()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(page and entity) then
		local code = page:GetUIValue("code");
		entity:SetCommand(code);
		local ctl = CodeBlockWindow.GetTextControl();
		if(ctl) then
			entity.cursorPos = ctl:CursorPos();
		end
	end
end

function CodeBlockWindow.DoTextLineWrap(text)
	local lines = {};
	for line in string.gmatch(text or "", "([^\r\n]*)\r?\n?") do
		while (line) do
			local remaining_text;
			line, remaining_text = _guihelper.TrimUtf8TextByWidth(line, self.width or 300, "System;12;norm");
			lines[#lines+1] = line;
			line = remaining_text
		end
	end
	return table.concat(lines, "\n");
end

function CodeBlockWindow.SetConsoleText(text)
	if(self.console_text ~= text) then
		self.console_text = text;
		self.console_text_linewrapped = CodeBlockWindow.DoTextLineWrap(self.console_text) or "";
		if(page) then
			page:SetValue("console", self.console_text_linewrapped);
		end
	end
end

function CodeBlockWindow.GetConsoleText()
	return self.console_text_linewrapped or self.console_text;
end

function CodeBlockWindow.OnClickStart()
	GameLogic.RunCommand("/sendevent start");
end

function CodeBlockWindow.OnClickPause()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:Pause();
	end
end

function CodeBlockWindow.OnClickStop()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:StopAll();
	end
end

function CodeBlockWindow.OnClickCompileAndRun()
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	if(codeBlock and codeBlock:GetEntity()) then
		CodeBlockWindow.UpdateCodeToEntity();
		codeBlock:GetEntity():Restart();
	end
end

function CodeBlockWindow.OnClickOpenMovieBlock()
	local movieEntity = CodeBlockWindow.GetMovieEntity();
	if(movieEntity) then
		if(mouse_button=="left") then
			local codeBlock = CodeBlockWindow.GetCodeBlock();
			if(codeBlock) then
				codeBlock:HighlightActors();
			end
		else
			movieEntity:OpenEditor("entity");
		end
	else
		_guihelper.MessageBox(L"没有找到电影方块! 请将一个包含演员的电影方块放到代码方块的旁边，就可以用代码控制演员了!")
	end
end

function CodeBlockWindow.OnChangeFilename()
	if(self.entity) then
		if(page) then
			local filename = page:GetValue("filename");
			self.entity:SetDisplayName(filename);
		end
	end
end

function CodeBlockWindow.GetFilename()
	if(self.entity) then
		return self.entity:GetDisplayName();
	end
end

function CodeBlockWindow.RunTempCode(code, filename)
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:RunTempCode(code, filename);
	end
end

function CodeBlockWindow.ShowHelpWndForCodeName(name)
	CodeBlockWindow.ShowHelpWnd("script/apps/Aries/Creator/Game/Code/CodeHelpItemTooltip.html?showclose=true&name="..name);
end

function CodeBlockWindow.RefreshPage(time)
	CodeBlockWindow.UpdateCodeToEntity()
	if(page) then
		page:Refresh(time or 0.01);
	end
end

function CodeBlockWindow.ShowHelpWnd(url)
	if(url and url~="") then
		self.helpWndUrl = url;
		self.isShowHelpWnd = true;
		if(page) then
			page:SetValue("helpWnd", url);
			CodeBlockWindow.RefreshPage();
		end
	else
		self.isShowHelpWnd = false;
		CodeBlockWindow.RefreshPage();
	end
end

function CodeBlockWindow.GetHelpWndUrl()
	return self.helpWndUrl;
end

function CodeBlockWindow.IsShowHelpWnd()
	return self.isShowHelpWnd;
end

function CodeBlockWindow.OnChangeModel()
	local codeBlock = CodeBlockWindow.GetCodeBlock()
	if(codeBlock) then
		local actor;
		local sceneContext = CodeBlockWindow:GetSceneContext();
		if(sceneContext) then
			actor = sceneContext:GetActor()
		end
		actor = actor or codeBlock:GetActor();
		if(not actor) then
			-- auto create movie block and an NPC entity if no movie actor is found
			if(self.entity) then
				local movieEntity = self.entity:FindNearByMovieEntity()	
				if(not movieEntity) then
					self.entity:AutoCreateMovieEntity()
					movieEntity = self.entity:FindNearByMovieEntity()	
				end
				if(movieEntity and not movieEntity:GetFirstActorStack()) then
					movieEntity:CreateNPC();
					CodeBlockWindow:GetSceneContext():UpdateCodeBlock();
					actor = sceneContext:GetActor();
				end
			end
		end
		if(actor) then
			actor:SetTime(0);
			actor:CreateKeyFromUI("assetfile", function(bIsAdded)
				if(bIsAdded) then
					-- do something?					
				end
				if(codeBlock:IsLoaded()) then
					CodeBlockWindow.OnClickCompileAndRun();
				else
					CodeBlockWindow:GetSceneContext():UpdateCodeBlock();
				end
			end);
		end
	end
end

function CodeBlockWindow.OnDragEnd(name)
end


function CodeBlockWindow.IsMousePointerInCodeEditor()
	if(page) then
		local x, y = Mouse:GetMousePosition()
		local textAreaCtrl = page:FindControl("code");
		if(textAreaCtrl.window) then
			local ctrlX, ctrlY = textAreaCtrl.window:GetScreenPos();
			if(ctrlX and x > ctrlX and y>ctrlY) then
				return true;
			end
		end
	end
end

function CodeBlockWindow.GetTextControl()
	if(page) then
		local textAreaCtrl = page:FindControl("code");
		local textCtrl = textAreaCtrl and textAreaCtrl.ctrlEditbox;
		if(textCtrl) then
			return textCtrl:ViewPort();
		end
	end
end

	
-- @param bx, by, bz: if not nil, we will only insert when they match the current code block.
function CodeBlockWindow.ReplaceCode(code, bx, by, bz)
	if(CodeBlockWindow.IsSameBlock(bx, by, bz)) then
		local textCtrl = CodeBlockWindow.GetTextControl();
		if(textCtrl) then
			textCtrl:SetText(code or "");
			return true;
		end
	else
		if(bx and by and bz) then
			local codeEntity = BlockEngine:GetBlockEntity(bx, by, bz)
			if(codeEntity and codeEntity.class_name == "EntityCode") then
				codeEntity:SetCommand(code);
				return true;
			end
		end
		return false;
	end
end

-- @param bx, by, bz: we will return false if they do not match the current block. 
-- @return  it will also return true if input are nil
function CodeBlockWindow.IsSameBlock(bx, by, bz)
	if(bx and by and bz) then
		local entity = CodeBlockWindow.GetCodeEntity();
		if(entity) then
			local cur_bx, cur_by, cur_bz = entity:GetBlockPos();
			if(cur_bx==bx and cur_by == by and cur_bz==bz) then
				-- same block ready to go
			else
				return false;
			end
		end
	end
	return true;
end

-- @param bx, by, bz: if not nil, we will only insert when they match the current code block.
function CodeBlockWindow.InsertCodeAtCurrentLine(code, forceOnNewLine, bx, by, bz)
	if(not CodeBlockWindow.IsSameBlock(bx, by, bz)) then
		return false;
	end

	if(code and page) then
		local textAreaCtrl = page:FindControl("code");
		
		local textCtrl = textAreaCtrl and textAreaCtrl.ctrlEditbox;
		if(textCtrl) then
			textCtrl = textCtrl:ViewPort();
			if(textCtrl) then
				local text = textCtrl:GetLineText(textCtrl.cursorLine);
				if(text) then
					text = tostring(text);
					if(forceOnNewLine) then
						local newText = "";
						if(text:match("%S")) then
							-- always start a new line if current line is not empty
							textCtrl:LineEnd(false);
							textCtrl:InsertTextInCursorPos("\n");
							textCtrl:InsertTextInCursorPos(code);
						else
							textCtrl:InsertTextInCursorPos(code);
						end
					else
						textCtrl:InsertTextInCursorPos(code);
					end
					-- set focus to control. 
					if(textAreaCtrl and textAreaCtrl.window) then
						textAreaCtrl.window:SetFocus_sys();
						textAreaCtrl.window:handleActivateEvent(true)
					end
					return true;
				end
			end
		end
	end
end

local blocklyWndName = "blocklyWindow";

function CodeBlockWindow.GetChromeBrowserManager()
	if(self.chromeBrowserManager == nil) then
		self.chromeBrowserManager = false;
		NPL.load("(gl)Mod/NplCefBrowser/NplCefBrowserManager.lua");
		local NplCefBrowserManager = commonlib.gettable("Mod.NplCefBrowserManager");	
		if(NplCefBrowserManager.HasCefPlugin and NplCefBrowserManager:HasCefPlugin()) then
			self.chromeBrowserManager = NplCefBrowserManager;
		end
	end
	return self.chromeBrowserManager;
end

-- @param bDestroy: true to destroy window
function CodeBlockWindow.CloseBlocklyWindow(bDestroy)
	CodeBlockWindow.isBlocklyOpened = false;
	local NplCefBrowserManager = CodeBlockWindow.GetChromeBrowserManager();
	if(NplCefBrowserManager) then
		local config = NplCefBrowserManager:GetWindowConfig(blocklyWndName);
		if(config) then
			if(not bDestroy) then
				config.visible = false;
				NplCefBrowserManager:Show(config);
			else
				NplCefBrowserManager:Delete({id = blocklyWndName, });
			end
		end
	end
end

function CodeBlockWindow.UpdateBlocklyWindowSize()
	if(CodeBlockWindow.isBlocklyOpened) then
		local NplCefBrowserManager = CodeBlockWindow.GetChromeBrowserManager();
		if(NplCefBrowserManager) then
			local config = NplCefBrowserManager:GetWindowConfig(blocklyWndName);
			if(config) then
				NplCefBrowserManager:ChangePosSize({id = blocklyWndName, x = 0, y = 0, width = math.max(400, Screen:GetWidth()-self.width+205), height = Screen:GetHeight(), });
			end
		end
	end
end


function CodeBlockWindow.OpenBlocklyEditor()
	local blockpos;
	local entity = CodeBlockWindow.GetCodeEntity();
	if(entity) then
		local bx, by, bz = entity:GetBlockPos();
		if(bz) then
			blockpos = format("%d,%d,%d", bx, by, bz);
		end
	end

	local NplCefBrowserManager = CodeBlockWindow.GetChromeBrowserManager();
	if(NplCefBrowserManager) then
		 -- Open a new window
		if(not CodeBlockWindow.isBlocklyOpened) then
			CodeBlockWindow.isBlocklyOpened = true;
			local config = NplCefBrowserManager:GetWindowConfig(blocklyWndName);
			if(config and not config.visible) then
				config.visible = true;
				NplCefBrowserManager:Show(config);
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/DefaultFilters.lua");
				local DefaultFilters = commonlib.gettable("MyCompany.Aries.Game.DefaultFilters");
				local url = DefaultFilters.cmd_open_url("npl://blockeditor")
				NplCefBrowserManager:Open({id = blocklyWndName, url = url, showTitleBar=false, withControl = false, x = 0, y = 0, width = math.max(400, Screen:GetWidth()-self.width+205), height = Screen:GetHeight(), });
			end
			CodeBlockWindow.UpdateBlocklyWindowSize();
		else
			CodeBlockWindow.CloseBlocklyWindow();
		end
	else
		local requestParams = ""
		if(blockpos) then
			requestParams = format("?blockpos=%s", blockpos);
		end
		GameLogic.RunCommand("/open npl://blockeditor"..requestParams);
	end
end

function CodeBlockWindow.OnOpenBlocklyEditor()
	local code = CodeBlockWindow.GetCodeFromEntity();
	CodeBlockWindow.OpenBlocklyEditor()
end

function CodeBlockWindow.GetBlockList()
	local blockList = {};
	local entity = self.entity;
	if(entity) then
		entity:ForEachNearbyCodeEntity(function(codeEntity)
			blockList[#blockList+1] = {filename = codeEntity:GetFilename() or L"未命名", entity = codeEntity}
		end);
		table.sort(blockList, function(a, b)
			return a.filename < b.filename;
		end)
	end
	return blockList;
end

function CodeBlockWindow.OnOpenTutorials()
	ParaGlobal.ShellExecute("open", L"https://keepwork.com/official/paracraft/codeblock", "", "", 1);
end

-- Redirect this object as a scene context, so that it will receive all key/mouse events from the scene. 
-- as if this task object is a scene context derived class. One can then overwrite
-- `UpdateManipulators` function to add any manipulators. 
function CodeBlockWindow:LoadSceneContext()
	local sceneContext = self:GetSceneContext();
	if(not sceneContext:IsSelected()) then
		sceneContext:activate();
		sceneContext:SetCodeEntity(CodeBlockWindow.GetCodeEntity());
	end
end

function CodeBlockWindow:UnloadSceneContext()
	local sceneContext = self:GetSceneContext();
	if(sceneContext) then
		sceneContext:SetCodeEntity(nil);
	end
	GameLogic.ActivateDefaultContext();
end

function CodeBlockWindow:GetSceneContext()
	if(not self.sceneContext) then
		self.sceneContext = AllContext:GetContext("code");
		CodeBlockWindow:Connect("entityChanged", self.sceneContext, "SetCodeEntity")
	end
	return self.sceneContext;
end

CodeBlockWindow:InitSingleton();