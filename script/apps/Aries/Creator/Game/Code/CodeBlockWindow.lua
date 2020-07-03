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
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/WebServer/WebServer.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeIntelliSense.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local CodeIntelliSense = commonlib.gettable("MyCompany.Aries.Game.Code.CodeIntelliSense");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Screen = commonlib.gettable("System.Windows.Screen");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local CodeBlockWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow"));

-- whether we are using big code window size
CodeBlockWindow:Property({"BigCodeWindowSize", false, "IsBigCodeWindowSize", "SetBigCodeWindowSize"});

-- when entity being edited is changed. 
CodeBlockWindow:Signal("entityChanged", function(entity) end)

local code_block_window_name = "code_block_window_";
local page;
local groupindex_hint = 3; 
-- this is singleton class
local self = CodeBlockWindow;

CodeBlockWindow.defaultCodeUIUrl = "script/apps/Aries/Creator/Game/Code/CodeBlockWindow.html";

-- show code block window at the right side of the screen
-- @param bShow:
function CodeBlockWindow.Show(bShow)
	if(not bShow) then
		CodeBlockWindow.Close();
	else
		GameLogic.GetFilters():add_filter("OnShowEscFrame", CodeBlockWindow.OnShowEscFrame);
		GameLogic.GetFilters():add_filter("ShowExitDialog", CodeBlockWindow.OnShowExitDialog);
		
		GameLogic:desktopLayoutRequested("CodeBlockWindow");
		GameLogic:Connect("desktopLayoutRequested", CodeBlockWindow, CodeBlockWindow.OnLayoutRequested, "UniqueConnection");
		GameLogic.GetCodeGlobal():Connect("logAdded", CodeBlockWindow, CodeBlockWindow.AddConsoleText, "UniqueConnection");
	
		local _this = ParaUI.GetUIObject(code_block_window_name);
		if(not _this:IsValid()) then
			self.width, self.height, self.margin_right, self.bottom, self.top, sceneMarginBottom = self:CalculateMargins();
			_this = ParaUI.CreateUIObject("container", code_block_window_name, "_mr", 0, self.top, self.width, self.bottom);
			_this.zorder = -2;
			_this.background="";
			_this:SetScript("onsize", function()
				CodeBlockWindow:OnViewportChange();
			end)
			local viewport = ViewportManager:GetSceneViewport();
			viewport:SetMarginRight(self.margin_right);
			viewport:SetMarginRightHandler(self);

			if(sceneMarginBottom~=0) then
				if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == self) then
					viewport:SetMarginBottom(sceneMarginBottom);
					viewport:SetMarginBottomHandler(self);
				end
			end

			viewport:Connect("sizeChanged", CodeBlockWindow, CodeBlockWindow.OnViewportChange, "UniqueConnection");

			_this:SetScript("onclick", function() end); -- just disable click through 
			_guihelper.SetFontColor(_this, "#ffffff");
			_this:AttachToRoot();
			page = System.mcml.PageCtrl:new({url=CodeBlockWindow.defaultCodeUIUrl});
			page:Create(code_block_window_name.."page", _this, "_fi", 0, 0, 0, 0);
		end

		_this.visible = true;
		CodeBlockWindow:OnViewportChange();
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginRight(self.margin_right);
		viewport:SetMarginRightHandler(self);

		GameLogic:Connect("beforeWorldSaved", CodeBlockWindow, CodeBlockWindow.OnWorldSave, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", CodeBlockWindow, CodeBlockWindow.OnWorldUnload, "UniqueConnection")

		CodeBlockWindow:LoadSceneContext();
		if(self.entity) then
			EntityManager.SetLastTriggerEntity(self.entity)
		end
		GameLogic.GetEvents():DispatchEvent({type = "CodeBlockWindowShow" , bShow = true, width = self.width});	
	end
end


function CodeBlockWindow.OnShowEscFrame(bShow)
	if(bShow or bShow == nil) then
		CodeBlockWindow.SetNplBrowserVisible(false)
	end
	return bShow;
end

function CodeBlockWindow.OnShowExitDialog(p1)
	CodeBlockWindow.SetNplBrowserVisible(false);
	return p1;
end

function CodeBlockWindow:OnLayoutRequested(requesterName)
	if(requesterName ~= "CodeBlockWindow") then
		if(CodeBlockWindow.IsVisible()) then
			CodeBlockWindow.Show(false);
		end
	end
end


function CodeBlockWindow:IsBigCodeWindowSize()
	return self.BigCodeWindowSize;
end

function CodeBlockWindow:SetBigCodeWindowSize(enabled)
	if(self.BigCodeWindowSize ~= enabled) then
		self.BigCodeWindowSize = enabled;
		self:OnViewportChange();
	end
end

function CodeBlockWindow.ToggleSize()
	local self = CodeBlockWindow;
	self:SetBigCodeWindowSize(not self:IsBigCodeWindowSize());
end

-- @return width, height, margin_right, margin_bottom, margin_top
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

	local bottom, sceneMarginBottom = 0, 0;
	if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == self) then
		bottom = 0;
		if(self:IsBigCodeWindowSize()) then
			local sceneWidth = 300;
			width = math.max(Screen:GetWidth() - sceneWidth, MIN_CODEWINDOW_WIDTH);
			local sceneBottom = Screen:GetHeight() - math.floor(sceneWidth / 4 * 3);
			sceneMarginBottom = math.floor(sceneBottom * (Screen:GetUIScaling()[2]))
		end
	else
		bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2]);	
	end
	
	local margin_right = math.floor(width * Screen:GetUIScaling()[1]);
	local margin_top = math.floor(viewport:GetTop() / Screen:GetUIScaling()[2]);
	return width, Screen:GetHeight()-bottom-margin_top, margin_right, bottom, margin_top, sceneMarginBottom;
end

function CodeBlockWindow:OnViewportChange()
	if(CodeBlockWindow.IsVisible()) then
		local viewport = ViewportManager:GetSceneViewport();
		
		-- TODO: use a scene/ui layout manager here
		local width, height, margin_right, bottom, top, sceneMarginBottom = self:CalculateMargins();
		if(self.width ~= width or self.height ~= height) then
			self.width = width;
			self.height = height;
			self.margin_right = margin_right;
			self.bottom = bottom;
			self.top = top;
			
			viewport:SetMarginRight(self.margin_right);
			viewport:SetMarginRightHandler(self);

			local _this = ParaUI.GetUIObject(code_block_window_name);
			_this:Reposition("_mr", 0, self.top, self.width, self.bottom);
			if(page) then
				CodeBlockWindow.UpdateCodeToEntity();
				page:Rebuild();
				GameLogic.GetEvents():DispatchEvent({type = "CodeBlockWindowShow" , bShow = true, width = self.width});	
			end
		end
		if(sceneMarginBottom ~= viewport:GetMarginBottom())then
			if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == self) then
				viewport:SetMarginBottom(sceneMarginBottom);
				viewport:SetMarginBottomHandler(self);
			end
		end
	end
end

function CodeBlockWindow.OnWorldUnload()
	self.lastBlocklyUrl = nil;
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

function CodeBlockWindow:OnCodeChange()
	if(not CodeBlockWindow.IsVisible()) then
		CodeBlockWindow.SetCodeEntity(nil, true);
	end
	if(page) then
		page:Refresh(0.01);
	end
end

function CodeBlockWindow.RestoreCursorPosition()
	if(self.entity and self.entity.cursorPos) then
		commonlib.TimerManager.SetTimeout(function()  
			local ctrl = CodeBlockWindow.GetTextControl();
			if(ctrl) then
				if(self.entity and self.entity.cursorPos) then
					local cursorPos = self.entity.cursorPos;
					ctrl:moveCursor(cursorPos.line, cursorPos.pos, false, true);
					ctrl:GetWindow():handleActivateEvent(true);
				end
			end
		end, 200);
	end
end

function CodeBlockWindow.SetCodeEntity(entity, bNoCodeUpdate)
	CodeBlockWindow.HighlightCodeEntity(entity);
	local isEntityChanged = false;
	if(self.entity ~= entity) then
		if(entity) then
			EntityManager.SetLastTriggerEntity(entity);
			entity:Connect("beforeRemoved", self, self.OnEntityRemoved, "UniqueConnection");
			entity:Connect("editModeChanged", self, self.UpdateEditModeUI, "UniqueConnection");
			entity:Connect("remotelyUpdated", self, self.OnCodeChange, "UniqueConnection");
		end
		if(self.entity) then
			local codeBlock = self.entity:GetCodeBlock();
			if(not self.entity:IsPowered() and (codeBlock and (codeBlock:IsLoaded() or codeBlock:HasRunningTempCode()))) then
				if(not self.entity:IsEntitySameGroup(entity)) then
					self.entity:Stop();
				end
			end

			self.entity:Disconnect("beforeRemoved", self, self.OnEntityRemoved);
			self.entity:Disconnect("editModeChanged", self, self.UpdateEditModeUI);
			self.entity:Disconnect("remotelyUpdated", self, self.OnCodeChange);
			if(not bNoCodeUpdate) then
				CodeBlockWindow.UpdateCodeToEntity();
			end
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
			if(self.entity and self.entity:IsCodeEmpty() and self.entity.AutoCreateMovieEntity) then
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
		CodeBlockWindow.UpdateCodeEditorStatus()

		if(EditCodeActor.GetInstance() and EditCodeActor.GetInstance():GetEntityCode() ~= entity and entity) then
			local task = EditCodeActor:new():Init(CodeBlockWindow.GetCodeEntity());
			task:Run();
		end

		self:entityChanged(self.entity);
	end
	if(not entity) then
		CodeBlockWindow.CloseEditorWindow()
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

function CodeBlockWindow.GetCodeEntity(bx, by, bz)
	if(bx) then
		local codeEntity = BlockEngine:GetBlockEntity(bx, by, bz)
		if(codeEntity and (codeEntity.class_name == "EntityCode" 
			or codeEntity.class_name == "EntitySign" 
			or codeEntity.class_name == "EntityCommandBlock"
			or codeEntity.class_name == "EntityCollisionSensor")) then

			return codeEntity;
		end
	else
		return CodeBlockWindow.entity;
	end
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
	GameLogic.GetCodeGlobal():Disconnect("logAdded", CodeBlockWindow, CodeBlockWindow.AddConsoleText);
	CodeBlockWindow:UnloadSceneContext();
	CodeBlockWindow.CloseEditorWindow();
	CodeBlockWindow.lastBlocklyUrl = nil;
	EntityManager.SetLastTriggerEntity(nil);
	CodeIntelliSense.Close()
	GameLogic.GetEvents():DispatchEvent({type = "CodeBlockWindowShow" , bShow = false});	
end

function CodeBlockWindow.CloseEditorWindow()
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
    CodeBlockWindow.SetNplBrowserVisible(false);
end

function CodeBlockWindow.RestoreWindowLayout()
	local _this = ParaUI.GetUIObject(code_block_window_name)
	if(_this:IsValid()) then
		_this.visible = false;
		_this:LostFocus();
	end
	local viewport = ViewportManager:GetSceneViewport();
	if(viewport:GetMarginBottomHandler() == self) then
		viewport:SetMarginBottomHandler(nil);
		viewport:SetMarginBottom(0);
	end
	if(viewport:GetMarginRightHandler() == self) then
		viewport:SetMarginRightHandler(nil);
		viewport:SetMarginRight(0);
	end
end

function CodeBlockWindow.UpdateCodeToEntity()
	if(CodeBlockWindow.updateCodeTimer) then
		CodeBlockWindow.updateCodeTimer:Change();
	end
	local entity = CodeBlockWindow.GetCodeEntity()
	if(page and entity) then
		local code = page:GetUIValue("code");
		if(not entity:IsBlocklyEditMode()) then
			entity:BeginEdit()
			entity:SetNPLCode(code);
			entity:EndEdit()

			local ctl = CodeBlockWindow.GetTextControl();
			if(ctl) then
				entity.cursorPos = ctl:CursorPos();
			end
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

function CodeBlockWindow:AddConsoleText(text)
	if(page) then
		local textAreaCtrl = page:FindControl("console");
		local textCtrl = textAreaCtrl and textAreaCtrl.ctrlEditbox;
		if(textCtrl) then
			textCtrl = textCtrl:ViewPort();
			if(textCtrl) then
				for line in text:gmatch("[^\r\n]+") do
					textCtrl:AddItem(line)
				end
				textCtrl:DocEnd();
			end
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
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	if(codeEntity) then
		if(codeEntity:GetCodeLanguageType() == "python") then
			GameLogic.IsVip("PythonCodeBlock", false, function(result)
				if (result) then
					CodeBlockWindow.UpdateCodeToEntity();
					codeEntity:Restart();
				else
					GameLogic.AddBBS(nil, L"非VIP用户只能免费运行3次Python语言代码", 15000, "255 0 0")
					CodeBlockWindow.python_run_times = (CodeBlockWindow.python_run_times or 0) + 1;
				end
			end);
		else
			-- GameLogic.GetFilters():apply_filters("user_event_stat", "code", "execute", nil, nil);
			CodeBlockWindow.UpdateCodeToEntity();
			codeEntity:Restart();
		end
	end
end

function CodeBlockWindow.OnClickCodeActor()
	local movieEntity = CodeBlockWindow.GetMovieEntity();
	if(movieEntity) then
		if(mouse_button=="left") then
			local codeBlock = CodeBlockWindow.GetCodeBlock();
			if(codeBlock) then
				codeBlock:HighlightActors();

				local task = EditCodeActor:new():Init(CodeBlockWindow.GetCodeEntity());
				task:Run();
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
			local codeBlock = CodeBlockWindow.GetCodeBlock();
			if(codeBlock) then
				codeBlock:SetModified(true);
			end
		end
	end
end

function CodeBlockWindow.GetFilename()
	if(self.entity) then
		return self.entity:GetFilename();
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

function CodeBlockWindow.OnPreviewPyConversionPage()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodePyToNplPage.lua");
    local CodePyToNplPage = commonlib.gettable("MyCompany.Aries.Game.Code.CodePyToNplPage");

    local txt;
    if(CodeBlockWindow.IsBlocklyEditMode()) then
        txt = CodeBlockWindow.GetCodeFromEntity()
	else
		local textCtrl = CodeBlockWindow.GetTextControl();
        if(textCtrl)then
            txt = textCtrl:GetText();
        end
	end
    CodePyToNplPage.ShowPage(txt,function(codes)
    end);
end
function CodeBlockWindow.OnChangeModel()
	local codeBlock = CodeBlockWindow.GetCodeBlock()
	if(codeBlock) then
		local actor;
		local movieEntity = self.entity:FindNearByMovieEntity()	
		if(movieEntity and not movieEntity:GetFirstActorStack()) then
			movieEntity:CreateNPC();
			CodeBlockWindow:GetSceneContext():UpdateCodeBlock();
		end

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
		CodeBlockWindow.SetNplBrowserVisible(false)
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

-- @return textcontrol, multilineEditBox control.
function CodeBlockWindow.GetTextControl()
	if(page) then
		local textAreaCtrl = page:FindControl("code");
		local textCtrl = textAreaCtrl and textAreaCtrl.ctrlEditbox;
		if(textCtrl) then
			return textCtrl:ViewPort(), textCtrl;
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
			local codeEntity = CodeBlockWindow.GetCodeEntity(bx, by, bz)
			if(codeEntity) then
				if(not codeEntity:IsBlocklyEditMode()) then
					codeEntity:SetNPLCode(code);
				end
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

-- @param blockly_xmlcode: xml text for blockly
-- @param code: this is the generated NPL code, should be readonly until we have two way binding. 
-- @param bx, by, bz: if not nil, we will only insert when they match the current code block.
function CodeBlockWindow.UpdateBlocklyCode(blockly_xmlcode, code, bx, by, bz)
	local codeEntity = CodeBlockWindow.GetCodeEntity(bx, by, bz);
	if(codeEntity) then
		codeEntity:BeginEdit()
		codeEntity:SetBlocklyEditMode(true);
		codeEntity:SetBlocklyXMLCode(blockly_xmlcode);
		codeEntity:SetBlocklyNPLCode(code);
		codeEntity:EndEdit()

		if(CodeBlockWindow.IsSameBlock(bx, by, bz)) then
			CodeBlockWindow.ReplaceCode(code, bx, by, bz)
		end
	end
end

-- @param bx, by, bz: if not nil, we will only insert when they match the current code block.
function CodeBlockWindow.InsertCodeAtCurrentLine(code, forceOnNewLine, bx, by, bz)
	if(not CodeBlockWindow.IsSameBlock(bx, by, bz) or CodeBlockWindow.IsBlocklyEditMode()) then
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

function CodeBlockWindow.IsBlocklyEditMode()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		return entity:IsBlocklyEditMode()
	end
end

function CodeBlockWindow.UpdateCodeEditorStatus()
	local textCtrl = CodeBlockWindow.GetTextControl();
	if(textCtrl) then
		local bReadOnly = CodeBlockWindow.IsBlocklyEditMode();
		textCtrl:setReadOnly(bReadOnly)
	end
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		CodeHelpWindow.SetLanguageConfigFile(entity:GetLanguageConfigFile(),entity:GetCodeLanguageType());
		
		local sceneContext = self:GetSceneContext();
		if(sceneContext) then
			local langConfig = CodeHelpWindow.GetLanguageConfigByEntity(entity)
			-- whether to show bones 
			local bShowBones = false;
			if(langConfig.IsShowBones) then
				bShowBones = langConfig.IsShowBones()
			end
			sceneContext:SetShowBones(bShowBones);

			-- custom code block theme
			local codeUIUrl = CodeBlockWindow.defaultCodeUIUrl;
			if(langConfig.GetCustomCodeUIUrl) then
				codeUIUrl = langConfig.GetCustomCodeUIUrl() or codeUIUrl;
				codeUIUrl = Files.FindFile(codeUIUrl)
			end
			if(page.url ~= codeUIUrl) then
				page:Goto(codeUIUrl);
			end
		end
	end
end

-- default to standard NPL language. One can create domain specific language configuration files. 
function CodeBlockWindow.OnClickSelectLanguageSettings()
	local entity = CodeBlockWindow.GetCodeEntity()
	if(not entity) then
		return
	end
	local old_value = entity:GetLanguageConfigFile();
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
	local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
	OpenFileDialog.ShowPage('<a class="linkbutton_yellow" href="https://github.com/nplpackages/paracraft/wiki/languageConfigFile">'..L"点击查看帮助"..'</a>', function(result)
		if(result) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
			local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
			if(not LanguageConfigurations:IsBuildinFilename(result)) then
				local filename = Files.GetWorldFilePath(result)
				if(not filename) then
					filename = result:gsub("%.npl$", "");
					filename = filename..".npl";

					_guihelper.MessageBox(format("是否要新建语言配置文件:%s", filename), function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							local fullPath = Files.WorldPathToFullPath(filename);
							ParaIO.CopyFile("script/apps/Aries/Creator/Game/Code/Examples/HelloLanguage.npl", fullPath, false);
							entity:SetLanguageConfigFile(filename);
							CodeBlockWindow.UpdateCodeEditorStatus()
						end
					end, _guihelper.MessageBoxButtons.YesNo);
					_guihelper.MessageBox(L"文件不存在");
					return;
				end
			end
			entity:SetLanguageConfigFile(result);
			CodeBlockWindow.UpdateCodeEditorStatus()
		end
	end, old_value or "", L"选择语言配置文件", "npl");
end

function CodeBlockWindow.GetCustomToolbarMCML()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
	local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
	local entity = CodeBlockWindow.GetCodeEntity()
	local mcmlText;
	if(entity) then
		CodeHelpWindow.SetLanguageConfigFile(entity:GetLanguageConfigFile(),entity:GetCodeLanguageType());
		mcmlText = LanguageConfigurations:GetCustomToolbarMCML(entity:GetLanguageConfigFile())
	end
	if(not mcmlText) then
        -- testing python conversion
        local b_pytonpl = ParaEngine.GetAppCommandLineByParam("pytonpl", false);
        if(b_pytonpl == "true")then
                mcmlText = string.format([[<div class="mc_item" style="float: left; margin-top:3px;margin-left:5px;width: 34px; height: 34px;">
                <pe:mc_block block_id='CodeActor' style="margin-left: 1px; margin-top: 1px; width:32px;height:32px;" onclick="CodeBlockWindow.OnClickCodeActor" tooltip='<%%="%s"%%>' />
            </div>
            <input type="button" value='<%%="%s"%%>' tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnPreviewPyConversionPage" style="margin-left:5px;min-width:80px;margin-top:7px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
    ]],
		    L"左键查看代码方块中的角色, 右键打开电影方块",  L"Python", L"python -> npl");
        else
            mcmlText = string.format([[<div class="mc_item" style="float: left; margin-top:3px;margin-left:5px;width: 34px; height: 34px;">
                <pe:mc_block block_id='CodeActor' style="margin-left: 1px; margin-top: 1px; width:32px;height:32px;" onclick="CodeBlockWindow.OnClickCodeActor" tooltip='<%%="%s"%%>' />
            </div>
            <input type="button" value='<%%="%s"%%>' tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnChangeModel" style="margin-left:5px;min-width:80px;margin-top:7px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
    ]],
		    L"左键查看代码方块中的角色, 右键打开电影方块", L"角色模型", L"也可以通过电影方块编辑");
        end
        
	end
	return mcmlText;
end

function CodeBlockWindow.OnClickEditMode(name,bForceRefresh)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(not entity) then
		return
	end
	if(CodeBlockWindow.IsBlocklyEditMode()) then
		if(name == "codeMode") then
			entity:SetBlocklyEditMode(false);
			CodeBlockWindow.UpdateCodeEditorStatus()
		end
	else
		if(name == "blockMode") then
			CodeBlockWindow.UpdateCodeToEntity();
			entity:SetBlocklyEditMode(true);
			CodeBlockWindow.UpdateCodeEditorStatus();
		end
	end
	if(mouse_button == "right") then
		CodeBlockWindow.OnClickSelectLanguageSettings()
	end
	if(name == "blockMode") then
		CodeBlockWindow.OpenBlocklyEditor(bForceRefresh);
	end
end

function CodeBlockWindow.UpdateEditModeUI()
	local textCtrl, multiLineCtrl = CodeBlockWindow.GetTextControl();
	if(page and textCtrl) then
		if(CodeBlockWindow.IsBlocklyEditMode()) then
			_guihelper.SetUIColor(page:FindControl("blockMode"), "#0b9b3a")
			_guihelper.SetUIColor(page:FindControl("codeMode"), "#808080")
			if(CodeBlockWindow.IsNPLBrowserVisible()) then
				CodeBlockWindow.SetNplBrowserVisible(true);
			end
			multiLineCtrl:SetBackgroundColor("#cccccc")
			local tipCtrl = page:FindControl("blocklyTip");
			if(tipCtrl) then
				tipCtrl.visible = true;
			end
		else
			_guihelper.SetUIColor(page:FindControl("blockMode"), "#808080")
			_guihelper.SetUIColor(page:FindControl("codeMode"), "#0b9b3a")
			CodeBlockWindow.SetNplBrowserVisible(false);
			multiLineCtrl:SetBackgroundColor("#00000000")
			local tipCtrl = page:FindControl("blocklyTip");
			if(tipCtrl) then
				tipCtrl.visible = false;
			end
		end
		
		textCtrl:SetText(CodeBlockWindow.GetCodeFromEntity());

		textCtrl:Connect("userTyped", CodeBlockWindow, CodeBlockWindow.OnUserTypedCode, "UniqueConnection");
		textCtrl:Connect("keyPressed", CodeIntelliSense, CodeIntelliSense.OnUserKeyPress, "UniqueConnection");
		
		CodeIntelliSense.Close()
	end
end

-- @param bForceRefresh: whether to refresh the content of the browser according to current blockly code. If nil, it will refresh if url has changed. 
function CodeBlockWindow.SetNplBrowserVisible(bVisible, bForceRefresh)
    if(page)then
		-- block NPL.activate "cef3/NplCefPlugin.dll" if npl browser isn't loaded
		-- so that we can running auto updater normally
        if(not CodeBlockWindow.NplBrowserIsLoaded())then
            return
		end
		page.isNPLBrowserVisible = bVisible;

		if(bVisible and not CodeBlockWindow.temp_nplbrowser_reload)then
			-- tricky: this will create the pe:npl_browser control on first use. 
            CodeBlockWindow.temp_nplbrowser_reload = true;
            page:Rebuild();
        end

		page:CallMethod("nplbrowser_codeblock","SetVisible",bVisible)

        if(bVisible) then
			if(bForceRefresh == nil) then
				if(self.lastBlocklyUrl ~= CodeBlockWindow.GetBlockEditorUrl()) then
					self.lastBlocklyUrl = CodeBlockWindow.GetBlockEditorUrl();
					bForceRefresh = true;
				end
			end
			if(bForceRefresh) then
				page:CallMethod("nplbrowser_codeblock","Reload",CodeBlockWindow.GetBlockEditorUrl());
			end
        end
		local ctl = page:FindControl("browserLoadingTips")
		if(ctl) then
			ctl.visible = bVisible
		end

        local ctl = page:FindControl("helpContainer")
		if(ctl) then
			ctl.visible = not (bVisible == true)
		end
		local ctl = page:FindControl("codeContainer")
		if(ctl) then
			ctl.visible = not (bVisible == true)
		end
    end
end

function CodeBlockWindow.IsNPLBrowserVisible()
	return page and page.isNPLBrowserVisible;
end

function CodeBlockWindow.GetBlockEditorUrl()
    local blockpos;
	local entity = CodeBlockWindow.GetCodeEntity();
    local codeLanguageType;
    local codeConfigType;
	if(entity) then
		local bx, by, bz = entity:GetBlockPos();
	    local langConfig = CodeHelpWindow.GetLanguageConfigByBlockPos(bx,by,bz)
        if(langConfig)then
            codeConfigType = langConfig.type;
        end
		if(bz) then
			blockpos = format("%d,%d,%d", bx, by, bz);
		end
        codeLanguageType = entity:GetCodeLanguageType();
	end

	local request_url = "npl://blockeditor"
	if(blockpos) then
		request_url = request_url..format("?blockpos=%s&codeLanguageType=%s&codeConfigType=%s", blockpos, codeLanguageType or "npl", codeConfigType or "");
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
	local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
	local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)	end)
	if(bStarted) then
		return request_url:gsub("^npl:?/*", site_url);
	end
end

function CodeBlockWindow.OpenBlocklyEditor(bForceRefresh)
	local blockpos;
	local entity = CodeBlockWindow.GetCodeEntity();
    local codeLanguageType;
    local codeConfigType;
	if(entity) then
		local bx, by, bz = entity:GetBlockPos();
        local langConfig = CodeHelpWindow.GetLanguageConfigByBlockPos(bx,by,bz)
        if(langConfig)then
            codeConfigType = langConfig.type;
        end
		if(bz) then
			blockpos = format("%d,%d,%d", bx, by, bz);
		end

        codeLanguageType = entity:GetCodeLanguageType();
	end

	local request_url = "npl://blockeditor"
	if(blockpos) then
		request_url = request_url..format("?blockpos=%s&codeLanguageType=%s&codeConfigType=%s", blockpos, codeLanguageType or "npl", codeConfigType or "");
	end
	local function OpenInternalBrowser_()
		if(not CodeBlockWindow.IsNPLBrowserVisible()) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
			local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
			local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
				if(bStarted) then
					CodeBlockWindow.SetNplBrowserVisible(true,bForceRefresh)
				end
			end)
		else
			CodeBlockWindow.SetNplBrowserVisible(false)
		end
	end
	if(not CodeBlockWindow.NplBrowserIsLoaded()) then
		local isDownloading
		isDownloading = NplBrowserLoaderPage.Check(function(result)
			if(result) then
				if(isDownloading) then
					_guihelper.CloseMessageBox();
				end
				if(CodeBlockWindow.IsVisible()) then
					OpenInternalBrowser_()
				end
			end
		end)
		if(isDownloading) then
			_guihelper.MessageBox(L"正在更新图块编程系统，请等待1-2分钟。<br/>如果有杀毒软件提示安全警告请允许。", function(res)
				
			end, _guihelper.MessageBoxButtons.Nothing);
			return;
		end
	end

	if(System.os.GetPlatform() == "mac")then
		OpenInternalBrowser_();
        return
    end

    if(CodeBlockWindow.NplBrowserIsLoaded() and not Keyboard:IsCtrlKeyPressed())then
		OpenInternalBrowser_()
	else
		GameLogic.RunCommand("/open "..request_url);
    end
end

function CodeBlockWindow.OnOpenBlocklyEditor()
	local code = CodeBlockWindow.GetCodeFromEntity();
	CodeBlockWindow.OpenBlocklyEditor()
end

function CodeBlockWindow.GetBlockList()
	local blockList = {};
	local entity = self.entity;
	if(entity and entity.ForEachNearbyCodeEntity) then
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
	CodeHelpWindow.OnClickLearn()
end

function CodeBlockWindow.OpenExternalFile(filename)
	local filepath = Files.WorldPathToFullPath(filename);
	if(filepath) then
		GameLogic.RunCommand("/open npl://editcode?src="..filepath);
	end
end

-- Redirect this object as a scene context, so that it will receive all key/mouse events from the scene. 
-- as if this task object is a scene context derived class. One can then overwrite
-- `UpdateManipulators` function to add any manipulators. 
function CodeBlockWindow:LoadSceneContext()
	local sceneContext = self:GetSceneContext();
	if(not sceneContext:IsSelected()) then
		sceneContext:activate();
		sceneContext:SetCodeEntity(CodeBlockWindow.GetCodeEntity());
		CameraController.SetFPSMouseUIMode(true, "codeblockwindow");
	end
end

function CodeBlockWindow:UnloadSceneContext()
	local sceneContext = self:GetSceneContext();
	if(sceneContext) then
		sceneContext:SetCodeEntity(nil);
	end
	GameLogic.ActivateDefaultContext();
	CameraController.SetFPSMouseUIMode(false, "codeblockwindow");
end

function CodeBlockWindow:GetSceneContext()
	if(not self.sceneContext) then
		self.sceneContext = AllContext:GetContext("code");
		CodeBlockWindow:Connect("entityChanged", self.sceneContext, "SetCodeEntity")
	end
	return self.sceneContext;
end

function CodeBlockWindow.NplBrowserIsLoaded()
    return NplBrowserLoaderPage.IsLoaded();
end

function CodeBlockWindow.OnClickSettings()
	if(CodeBlockWindow.IsNPLBrowserVisible()) then
		CodeBlockWindow.SetNplBrowserVisible(false);
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockSettings.lua");
	local CodeBlockSettings = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockSettings");
	CodeBlockSettings.Show(true)
end

function CodeBlockWindow.OnMouseOverWordChange(word, line, from, to)
	CodeIntelliSense.OnMouseOverWordChange(word, line, from, to)
end

function CodeBlockWindow.OnRightClick(event)
	local ctrl = CodeBlockWindow.GetTextControl()
	if(ctrl) then
		local info = ctrl:getMouseOverWordInfo()
		if(info and info.word) then
			CodeIntelliSense.ShowContextMenuForWord(info.word, info.lineText, info.fromPos, info.toPos)	
		else
			CodeIntelliSense.ShowContextMenuForWord();
		end
	end
end

function CodeBlockWindow.OnLearnMore()
	return CodeIntelliSense.OnLearnMore(CodeBlockWindow.GetTextControl())
end

function CodeBlockWindow.FindTextGlobally()
	local ctrl = CodeBlockWindow.GetTextControl()
	if(ctrl) then
		if(ctrl:hasSelectedText()) then
			local text = ctrl:selectedText()
			if(text and not text:match("\n")) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
				local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
				local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
				task:ShowFindFile(text)
				return true;
			end
		end
	end
end

function CodeBlockWindow:OnUserTypedCode(textCtrl, newChar)
	CodeIntelliSense:OnUserTypedCode(textCtrl, newChar)
	CodeBlockWindow.updateCodeTimer = CodeBlockWindow.updateCodeTimer or commonlib.Timer:new({callbackFunc = function(timer)
		CodeBlockWindow.UpdateCodeToEntity();
	end})
	CodeBlockWindow.updateCodeTimer:Change(1000, nil);
end

CodeBlockWindow:InitSingleton();
