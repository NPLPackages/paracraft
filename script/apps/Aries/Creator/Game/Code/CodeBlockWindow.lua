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
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local ChatWindow = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatWindow");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local CodeIntelliSense = commonlib.gettable("MyCompany.Aries.Game.Code.CodeIntelliSense");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Screen = commonlib.gettable("System.Windows.Screen");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local CodeBlockWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow"));
local MobileCodeLogPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/CodeBlockWindow/MobileCodeLogPage.lua");

-- whether we are using big code window size
CodeBlockWindow:Property({"BigCodeWindowSize", false, "IsBigCodeWindowSize", "SetBigCodeWindowSize"});

-- when entity being edited is changed. 
CodeBlockWindow:Signal("entityChanged", function(entity) end)

local code_block_window_name = "code_block_window_";
local page;
local groupindex_hint = 3; 
-- this is singleton class
local self = CodeBlockWindow;
local NplBlocklyEditorPage = nil;

CodeBlockWindow.defaultCodeUIUrl = "script/apps/Aries/Creator/Game/Code/CodeBlockWindow.html";

-- show code block window at the right side of the screen
-- @param bShow:
function CodeBlockWindow.Show(bShow)
	CodeBlockWindow.blocklyTextMode = false;
	if(not bShow) then
		CodeBlockWindow.Close();
	else
		GameLogic.GetFilters():add_filter("ShowTopWindow", CodeBlockWindow.OnShowTopWindow)
		GameLogic.GetFilters():add_filter("OnShowEscFrame", CodeBlockWindow.OnShowEscFrame);
		GameLogic.GetFilters():add_filter("OnCodeBlockLineStep", CodeBlockWindow.OnCodeBlockLineStep);
		GameLogic.GetFilters():add_filter("OnCodeBlockNplBlocklyLineStep", CodeBlockWindow.OnCodeBlockNplBlocklyLineStep);
		GameLogic.GetFilters():add_filter("ChatLogWindowShowAndHide", CodeBlockWindow.OnChatLogWindowShowAndHide);
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
			
			page = System.mcml.PageCtrl:new({url=CodeBlockWindow.GetDefaultCodeUIUrl()});
			page:Create(code_block_window_name.."page", _this, "_fi", 0, 0, 0, 0);
		end
		_this.visible = true;
		CodeBlockWindow.isTextCtrlHasFocus = false;
		CodeBlockWindow:OnViewportChange();
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginRight(self.margin_right);
		viewport:SetMarginRightHandler(self);

		GameLogic:Connect("beforeWorldSaved", CodeBlockWindow, CodeBlockWindow.OnWorldSave, "UniqueConnection");
		GameLogic:Connect("WorldUnloaded", CodeBlockWindow, CodeBlockWindow.OnWorldUnload, "UniqueConnection")

		CodeBlockWindow:LoadSceneContext();
		if(self.entity) then
			EntityManager.SetLastTriggerEntity(self.entity)
			
			local langConfig = CodeHelpWindow.GetLanguageConfigByEntity(self.entity)
			if(langConfig and langConfig.OnOpenCodeEditor) then
				langConfig.OnOpenCodeEditor(self.entity)
			end
		end

		if (CodeBlockWindow.IsSupportNplBlockly()) then
			CodeBlockWindow.OpenBlocklyEditor();
		elseif(CodeBlockWindow.IsBlocklyEditMode() and not CodeBlockWindow.blocklyTextMode) then
			CodeBlockWindow.OpenBlocklyEditor()
		end
		
		GameLogic.GetEvents():DispatchEvent({type = "CodeBlockWindowShow" , bShow = true, width = self.width});	

		if(page and CodeBlockWindow.CalculateActor()) then
			page:Refresh(0);
		end
	end
end

function CodeBlockWindow.GetPageCtrl()
	return page;
end

function CodeBlockWindow.GetDefaultCodeUIUrl()
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		return "script/apps/Aries/Creator/Game/Mobile/CodeBlockWindow/MobileCodeBlockWindow.html";
	end
	local codeUIUrl = GameLogic.GetFilters():apply_filters("CodeBlockUIUrl", CodeBlockWindow.defaultCodeUIUrl)

	return codeUIUrl;
end

-- @param locationInfo: in format of "filename:line:"
function CodeBlockWindow.OnCodeBlockLineStep(locationInfo)
	if(locationInfo) then
		local filename, lineNumber = locationInfo:match("^([^:]+):(%d+)")
		if(filename) then
			lineNumber = tonumber(lineNumber);
			local codeblock = self.GetCodeBlock();
			if(codeblock and codeblock:GetFilename() == filename) then
				-- flash the line for 1000 ms
				if(not CodeBlockWindow.IsBlocklyEditMode()) then
					local ctrl = CodeBlockWindow.GetTextControl();
					if(ctrl) then
						ctrl:FlashLine(lineNumber, 1000);
					end
				else
					-- TODO for WXA: flash line in blockly editor
				end
			end
		end
	end
	return locationInfo;
end


function CodeBlockWindow.OnCodeBlockNplBlocklyLineStep(blockid)
	if (not NplBlocklyEditorPage) then return end 
	local G = NplBlocklyEditorPage:GetG();
	if (type(G.SetRunBlockId) ~= "function") then return end 
	G.SetRunBlockId(blockid);
end

function CodeBlockWindow.OnShowTopWindow(state, winId)
	if(winId ~= "nplbrowser_codeblock" and page) then
		if((not CodeBlockWindow.IsSupportNplBlockly()) and CodeBlockWindow.IsBlocklyEditMode() and not CodeBlockWindow.blocklyTextMode) then
			CodeBlockWindow.SetNplBrowserVisible(false)
		end
	end
end

function CodeBlockWindow.OnShowEscFrame(bShow)
	if(bShow or bShow == nil) then
		CodeBlockWindow.SetNplBrowserVisible(false)
	end
	return bShow;
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
	-- local MAX_3DCANVAS_WIDTH = 800;
	local MAX_3DCANVAS_WIDTH = 600;
	local MIN_CODEWINDOW_WIDTH = 200+350;
	local viewport = ViewportManager:GetSceneViewport();
	local width = math.max(math.floor(Screen:GetWidth() * 1/3), MIN_CODEWINDOW_WIDTH);
	local halfScreenWidth = math.floor(Screen:GetWidth() * 11 / 20);  -- 50% 55%  
	if(halfScreenWidth > MAX_3DCANVAS_WIDTH) then
		width = halfScreenWidth;
	elseif((Screen:GetWidth() - width) > MAX_3DCANVAS_WIDTH) then
		width = Screen:GetWidth() - MAX_3DCANVAS_WIDTH;
	end

	local ui_scaling = Screen:GetUIScaling(true)
	local bottom, sceneMarginBottom = 0, 0;
	if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == self) then
		bottom = 0;
		if(self:IsBigCodeWindowSize()) then
			local sceneWidth = 300;
			width = math.max(Screen:GetWidth() - sceneWidth, MIN_CODEWINDOW_WIDTH);
			local sceneBottom = Screen:GetHeight() - math.floor(sceneWidth / 4 * 3);
			sceneMarginBottom = math.floor(sceneBottom * (ui_scaling[2]))
		end
	else
		bottom = math.floor(viewport:GetMarginBottom() / ui_scaling[2]);	
	end

	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		local sceneWidth = 320;
		width = math.max(Screen:GetWidth() - sceneWidth, MIN_CODEWINDOW_WIDTH);
		if(self:IsBigCodeWindowSize()) then
			local sceneBottom = Screen:GetHeight() - math.floor(sceneWidth / 4 * 3);
			sceneMarginBottom = math.floor(sceneBottom * (ui_scaling[2]))
		end
	end
	
	local margin_right = math.floor(width * ui_scaling[1]);
	local margin_top = math.floor(viewport:GetTop() / ui_scaling[2]);
	return width, Screen:GetHeight()-bottom-margin_top, margin_right, bottom, margin_top, sceneMarginBottom;
end

function CodeBlockWindow:IsVisibleAndFocus()
	if not CodeBlockWindow.IsVisible() then
		return false
	end
	local ctrl = CodeBlockWindow.GetTextControl();
	if(ctrl) then
		return ctrl:hasFocus()
	end
	return false
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
				local ctrl = CodeBlockWindow.GetTextControl();
				if(ctrl) then
					CodeBlockWindow.isTextCtrlHasFocus = ctrl:hasFocus()
				end
				CodeBlockWindow.UpdateCodeToEntity();
				CodeBlockWindow.RestoreCursorPosition()
				page:Rebuild();
				GameLogic.GetEvents():DispatchEvent({type = "CodeBlockWindowShow" , bShow = true, width = self.width});	
			end

			CodeBlockWindow.OpenBlocklyEditor();
		end
		if(sceneMarginBottom ~= viewport:GetMarginBottom())then
			if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == self) then
				viewport:SetMarginBottom(sceneMarginBottom);
				viewport:SetMarginBottomHandler(self);
			end
		end

		if(not CodeBlockWindow.IsBlocklyEditMode() and CodeBlockWindow.isTextCtrlHasFocus) then
			CodeBlockWindow.SetFocusToTextControl();
		end
	end
end

function CodeBlockWindow.OnWorldUnload()
	self.lastBlocklyUrl = nil;
	self.recentOpenFiles = nil;
end

function CodeBlockWindow.OnWorldSave()
	CodeBlockWindow.UpdateCodeToEntity();
	CodeBlockWindow.UpdateNplBlocklyCode();
	GameLogic.RunCommand("/compile")
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
	CodeBlockWindow.SetCodeEntity(nil, nil, true);
end

function CodeBlockWindow:OnCodeChange()
	if(not CodeBlockWindow.IsVisible()) then
		if(CodeBlockWindow.SetCodeEntity(nil, true, true)) then
			return
		end
	end
	if(page) then
		page:Refresh(0.01);
		commonlib.TimerManager.SetTimeout(CodeBlockWindow.UpdateNPLBlocklyUIFromCode, 200, "CodeBlockWindow_OnCodeChangeTimer")
	end
end

function CodeBlockWindow.UpdateNPLBlocklyUIFromCode()
	CodeBlockWindow.isUpdatingNPLBlocklyUIFromCode = true;
	CodeBlockWindow.ShowNplBlocklyEditorPage();
	CodeBlockWindow.isUpdatingNPLBlocklyUIFromCode = false;
end


function CodeBlockWindow.SetFocusToTextControl()
	commonlib.TimerManager.SetTimeout(function()  
		local ctrl = CodeBlockWindow.GetTextControl();
		if(ctrl) then
			local window = ctrl:GetWindow()
			if(window) then
				if(not GameLogic.Macros:IsPlaying()) then
					window:SetFocus_sys(FocusPolicy.StrongFocus)
					window:handleActivateEvent(true);
				else
					window.isEmulatedFocus = true;
					window:handleActivateEvent(true);
					window.isEmulatedFocus = nil;
				end
			end
			ctrl:setFocus("OtherFocusReason")
		end
	end, 400);
end

function CodeBlockWindow.RestoreCursorPositionImp()
	commonlib.TimerManager.SetTimeout(function()  
		local ctrl = CodeBlockWindow.GetTextControl();
		if(ctrl) then
			if(self.entity and self.entity.cursorPos) then
				local cursorPos = self.entity.cursorPos;
				ctrl:moveCursor(cursorPos.line, cursorPos.pos, false, true);
				if(cursorPos.fromLine) then
					ctrl:SetFromLine(cursorPos.fromLine)
				else
					ctrl:SetFromLine(math.max(1, cursorPos.line-10))
				end
			end
		end
	end, 10);
end

function CodeBlockWindow.RestoreCursorPosition(bImmediate)
	CodeBlockWindow.RequestRestoreCursor = true;
	if(bImmediate) then
		if(page) then
			page:Refresh(0.01);
		end
	end
end

function CodeBlockWindow.AddToRecentFiles(entity)
	if(entity) then
		local bx, by, bz = entity:GetBlockPos()
		self.recentOpenFiles = self.recentOpenFiles or {};
		local items = self.recentOpenFiles
		for i, item in ipairs(items) do
			if(item.bx == bx and item.by == by and item.bz==bz) then
				-- already exist, shuffle it to the first item
				for k=i, 2, -1 do
					items[k] = items[k-1]
				end
				items[1] = item;
				return
			end
		end
		for k=#items+1, 2, -1 do
			items[k] = items[k-1]
		end
		items[1] = {bx=bx, by=by, bz=bz};
	end
end

-- @return nil or array of recently opened files in format {bx, by, bz}
function CodeBlockWindow.GetRecentOpenFiles()
	return self.recentOpenFiles
end

function CodeBlockWindow.SetCodeEntity(entity, bNoCodeUpdate, bDelayRefresh)
	CodeBlockWindow.AddToRecentFiles(entity)
	CodeBlockWindow.HighlightCodeEntity(entity);
	local isEntityChanged = false;
	if(self.entity ~= entity) then
		CodeBlockWindow.blocklyTextMode = false;
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
		-- must be called before entity switch, otherwise it will cause a refresh
		CodeBlockWindow.CloseNplBlocklyEditorPage();
		self.entity = entity;
		
		if (CodeBlockWindow.IsSupportNplBlockly()) then 
			-- if npl blockly is used, open and use it. 
			CodeBlockWindow.OpenBlocklyEditor()
		elseif(CodeBlockWindow.IsBlocklyEditMode() and not CodeBlockWindow.blocklyTextMode) then
			CodeBlockWindow.OpenBlocklyEditor()
		end
		
		CodeBlockWindow.OnTryOpenMicrobit();

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
	if(isEntityChanged) then
		if(page) then
			CodeBlockWindow.CalculateActor();
			page:Refresh(bDelayRefresh and 0.01 or 0);
		end
	end
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if not GameLogic.Macros:IsPlaying() and IsMobileUIEnabled and entity and not CodeBlockWindow.IsBlocklyEditMode() then
		local textCtrl = CodeBlockWindow.GetTextControl();
		if(textCtrl)then
			local code = textCtrl:GetText() or "";
			code = string.gsub(code, "%s+", "")
			if string.len(code) ==0 then
				CodeBlockWindow.OnClickEditMode("blockMode")
			end
		end
	end
	return isEntityChanged
end

function CodeBlockWindow:OnMessage(msg)
	self.SetConsoleText(msg or "");
end

function CodeBlockWindow.GetCodeFromEntity()
	if (self.IsSupportNplBlockly()) then 
		return self.entity:GetNPLBlocklyNPLCode(); 
	end

	if(self.entity) then
		return self.entity:GetCommand();
	end
end

function CodeBlockWindow.GetCodeEntity(bx, by, bz)
	if(bx) then
		local codeEntity = BlockEngine:GetBlockEntity(bx, by, bz)
		if(codeEntity and (codeEntity.class_name == "EntityCode" 
			or codeEntity.class_name == "EntityCodeJunior" 
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
	CodeBlockWindow.CloseNplBlocklyEditorPage();
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

		local langConfig = CodeHelpWindow.GetLanguageConfigByEntity(entity)
		if(langConfig and langConfig.OnCloseCodeEditor) then
			langConfig.OnCloseCodeEditor(entity)
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
			if(entity:GetNPLCode() ~= code) then
				entity:BeginEdit()
				entity:SetNPLCode(code);
				entity:EndEdit()
			end

			local ctl = CodeBlockWindow.GetTextControl();
			if(ctl) then
				entity.cursorPos = ctl:CursorPos();
				if(entity.cursorPos) then
					entity.cursorPos.fromLine = ctl:GetFromLine()
				end
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

		MobileCodeLogPage.SetConsoleText()
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
	if CodeBlockWindow.IsCodeReadOnly() then
		GameLogic.AddBBS(nil,L"当前代码方块设置了只读模式，不可编辑")
		return 
	end
	local codeBlock = CodeBlockWindow.GetCodeBlock();
	if(codeBlock) then
		codeBlock:StopAll();
	end
end

function CodeBlockWindow.UpdateCodeReadOnly()
	if not CodeBlockWindow.IsVisible() then
		return
	end
	local textCtrl, multiLineCtrl = CodeBlockWindow.GetTextControl();
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	if(codeEntity) then
		local bReadOnly = CodeBlockWindow.IsBlocklyEditMode();
		textCtrl:setReadOnly(bReadOnly or  CodeBlockWindow.IsCodeReadOnly())
	end
end

function CodeBlockWindow.IsCodeReadOnly()
	if not GameLogic.IsReadOnly() then
		return false
	end
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	return codeEntity and type(codeEntity.IsCodeReadOnly) == "function" and codeEntity:IsCodeReadOnly()
end

function CodeBlockWindow.OnClickCompileAndRun(onFinishedCallback)
	if CodeBlockWindow.IsCodeReadOnly() then
		GameLogic.AddBBS(nil,L"当前代码方块设置了只读模式，不可编辑")
		return 
	end
	ParaUI.GetUIObject("root"):Focus();
	
	if(type(onFinishedCallback) ~= "function") then
		onFinishedCallback = nil;
	end

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
			CodeBlockWindow.UpdateNplBlocklyCode();
			codeEntity:Restart(onFinishedCallback);
		end
	end
end

function CodeBlockWindow.OnClickCodeActor()
	if CodeBlockWindow.IsCodeReadOnly() then
		GameLogic.AddBBS(nil,L"当前代码方块设置了只读模式，不可编辑")
		return 
	end
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

function CodeBlockWindow.OnChangeModel()
	if CodeBlockWindow.IsCodeReadOnly() then
		GameLogic.AddBBS(nil,L"当前代码方块设置了只读模式，不可编辑")
		return 
	end
	local codeBlock = CodeBlockWindow.GetCodeBlock()
	if(codeBlock) then
		-- fixed a bug, when EditCodeActor context is activated when we click the model button. here we will restore the code block context.
		if(CodeBlockWindow:LoadSceneContext()) then
			CodeBlockWindow:GetSceneContext():updateManipulators();
		end
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
				local movieEntity = self.entity and self.entity:FindNearByMovieEntity()	
				if(movieEntity) then
					movieEntity:MarkForUpdate();
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
						textAreaCtrl.window:SetFocus_sys(FocusPolicy.StrongFocus);
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
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		local textCtrl = CodeBlockWindow.GetTextControl();
		if(textCtrl) then
			local bReadOnly = CodeBlockWindow.IsBlocklyEditMode();
			textCtrl:setReadOnly(bReadOnly or CodeBlockWindow.IsCodeReadOnly())
		end

		CodeHelpWindow.SetLanguageConfigFile(entity:GetLanguageConfigFile(),entity:GetCodeLanguageType());
		if (NplBlocklyEditorPage) then 
			CodeBlockWindow.ShowNplBlocklyEditorPage() 
		end

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
			-- local codeUIUrl = CodeBlockWindow.defaultCodeUIUrl;
			local codeUIUrl = CodeBlockWindow.GetDefaultCodeUIUrl();
			if(langConfig.GetCustomCodeUIUrl) then
				codeUIUrl = langConfig.GetCustomCodeUIUrl() or codeUIUrl;
				NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
				local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
				if (not LanguageConfigurations:IsBuildinFilename(entity:GetLanguageConfigFile())) then
					codeUIUrl = Files.FindFile(codeUIUrl)
				end
			end
			if(page.url ~= codeUIUrl or langConfig.GetCustomToolbarMCML) then
				page:Goto(codeUIUrl);
				if(langConfig and langConfig.OnOpenCodeEditor) then
					langConfig.OnOpenCodeEditor(entity)
				end
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

-- return true if actor changed
function CodeBlockWindow.CalculateActor()
	local actorInventoryView, actorBagPos, actorItemId;
	local entity = CodeBlockWindow.GetCodeEntity()
	if(entity) then
		local movie_entity = entity:FindNearByMovieEntity();
		if(movie_entity) then
			if movie_entity and movie_entity.inventory then
				for i = 1, movie_entity.inventory:GetSlotCount() do
					local itemStack = movie_entity.inventory:GetItem(i)
					if (itemStack and itemStack.count > 0) then
						if (itemStack.id == block_types.names.TimeSeriesNPC or 
							itemStack.id == block_types.names.TimeSeriesOverlay or 
							itemStack.id == block_types.names.TimeSeriesLight) then

							actorInventoryView = movie_entity:GetInventoryView();
							actorBagPos = i;
							actorItemId = itemStack.id;
							break;
						end
					end 
				end
			end
		end
		if(not actorInventoryView and (entity:GetFilename() or "") ~= "") then
			-- we will show the agent item if no movie actor is available for this code entity. 
			actorInventoryView = entity:GetAgentInventoryView()
			if(actorInventoryView) then
				actorBagPos = 1;
				local itemStack = actorInventoryView:GetSlotItemStack(1)
				actorItemId = itemStack and itemStack.id;
			end
		end
	end

	if(CodeBlockWindow.actorInventoryView ~= actorInventoryView or CodeBlockWindow.actorBagPos ~= actorBagPos or CodeBlockWindow.actorItemId ~= actorItemId) then
		CodeBlockWindow.actorInventoryView = actorInventoryView
		CodeBlockWindow.actorBagPos = actorBagPos
		CodeBlockWindow.actorItemId = actorItemId
		return true
	end
end

function CodeBlockWindow.IsCodeJunior()
	local entity = CodeBlockWindow.GetCodeEntity()
	return entity and entity:GetLanguageConfigFile() == "npl_junior";
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
		-- <pe:mc_block block_id='CodeActor' style="margin-left: 1px; margin-top: 1px; width:32px;height:32px;" onclick="CodeBlockWindow.OnClickCodeActor" tooltip='<%%="%s"%%>' />
        mcmlText = string.format([[<div class="mc_item" style="float: left; margin-top:3px;margin-left:5px;width:34px; height:34px;">
	<pe:mc_slot class="mc_slot" ContainerView='<%%=CodeBlockWindow.actorInventoryView%%>' uiname='CodeBlockWindow.slot_actor' bagpos ='<%%=CodeBlockWindow.actorBagPos%%>' style="margin:1px;width:32px;height:32px;" tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnClickCodeActor"></pe:mc_slot>
</div>
<input type="button" uiname = "code_block_window_page1/1/2/1/2/2/2" value='<%%="%s"%%>' tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnChangeModel" style="margin-left:5px;min-width:80px;margin-top:7px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
]],
		L"左键查看代码方块中的角色, 右键打开电影方块", L"角色模型", L"也可以通过电影方块编辑");
	end

	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if IsMobileUIEnabled then
		mcmlText = string.format([[<input type="button" uiname = "code_block_window_page1/1/2/1/2/2/2" value='<%%="%s"%%>' tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnChangeModel" style="margin-left:14px;min-width:128px;margin-top:5px;color:#333333;font-size:16px;font-weight:bold;height:40px;background:url(Texture/Aries/Creator/keepwork/Mobile/CodeBlockWindow/role_model_128x40_32bits.png#0 0 128 40)" />
		<div class="mc_item" style="float: left; margin-top:5px;margin-left:4px;width:40px; height:40px;">
			<pe:mc_slot class="mc_slot" ContainerView='<%%=CodeBlockWindow.actorInventoryView%%>' uiname='CodeBlockWindow.slot_actor' bagpos ='<%%=CodeBlockWindow.actorBagPos%%>' style="margin:1px;width:40px;height:40px;" tooltip='<%%="%s"%%>' onclick="CodeBlockWindow.OnClickCodeActor"></pe:mc_slot>
		</div>
		
		]],
		L"角色模型",L"也可以通过电影方块编辑",L"左键查看代码方块中的角色, 右键打开电影方块" );
	end
	return mcmlText;
end

function CodeBlockWindow.CheckCanChangeMode()
	if CodeBlockWindow.IsCodeReadOnly() then
		return not GameLogic.IsReadOnly() or GameLogic.Macros:IsPlaying() or GameLogic.Macros:IsRecording()
	end
	return true
end

function CodeBlockWindow.OnClickEditMode(name,bForceRefresh)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(not entity) then
		return
	end
	local isBlocklyEditMode = CodeBlockWindow.IsBlocklyEditMode()
	local isModeChanged;

	if(name == "blockMode" and isBlocklyEditMode) then
		CodeBlockWindow.blocklyTextMode = not CodeBlockWindow.blocklyTextMode;
	else
		CodeBlockWindow.blocklyTextMode = false;
	end
		
	if(isBlocklyEditMode) then
		if(name == "codeMode" and CodeBlockWindow.CheckCanChangeMode()) then
			CodeBlockWindow.CloseNplBlocklyEditorPage();
			entity:SetBlocklyEditMode(false);
			CodeBlockWindow.UpdateCodeEditorStatus();
			isModeChanged = true;
		end
	else
		if(name == "blockMode" and CodeBlockWindow.CheckCanChangeMode()) then
			CodeBlockWindow.UpdateCodeToEntity();
			if(GameLogic.Macros:IsRecording() or GameLogic.Macros:IsPlaying()) then
				entity:SetUseNplBlockly(true);
			end
			entity:SetBlocklyEditMode(true);
			CodeBlockWindow.UpdateCodeEditorStatus();
			isModeChanged = true;
		end
	end
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if not IsMobileUIEnabled then
		if(mouse_button == "right" and CodeBlockWindow.CheckCanChangeMode()) then
			CodeBlockWindow.OnClickSelectLanguageSettings()
		end
	end
	if(name == "blockMode") then
		CodeBlockWindow.OpenBlocklyEditor(bForceRefresh);
	end
	if(page) then
		page:Refresh(0.01);
	end
end

function CodeBlockWindow:ChangeCodeMode(name,bForceRefresh)
	local entity = CodeBlockWindow.GetCodeEntity()
	if(not entity) then
		return
	end
	if(CodeBlockWindow.IsBlocklyEditMode()) then
		if(name == "codeMode") then
			CodeBlockWindow.CloseNplBlocklyEditorPage();
			entity:SetBlocklyEditMode(false);
			CodeBlockWindow.UpdateCodeEditorStatus();
		end
	else
		if(name == "blockMode") then
			CodeBlockWindow.UpdateCodeToEntity();
			if(GameLogic.Macros:IsRecording() or GameLogic.Macros:IsPlaying()) then
				entity:SetUseNplBlockly(true);
			end
			entity:SetBlocklyEditMode(true);
			CodeBlockWindow.UpdateCodeEditorStatus();
		end
	end
	if(name == "blockMode") then
		CodeBlockWindow.OpenBlocklyEditor(bForceRefresh);
	end
	if(page) then
		page:Refresh(0.01);
	end
end

function CodeBlockWindow.PrettyCode(code)
	local entity = CodeBlockWindow.GetCodeEntity();
	local language = entity and entity:GetLanguageConfigFile();
	local prettyCode = code;
	local LanguageConfig = NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
	if (LanguageConfig.GetLanguageType(language) == "npl") then
		local LuaFmt = NPL.load("script/ide/System/UI/Blockly/LuaFmt.lua");
		local ok, errinfo = pcall(function()
			prettyCode = LuaFmt.Pretty(code);
			prettyCode = string.gsub(prettyCode, "\t", "    ");
		end);
		if (not ok) then 
			print("=============code error==========", errinfo);
			prettyCode = code;
		end
	end
	return prettyCode;
end

function CodeBlockWindow.UpdateEditModeUI()
	local textCtrl, multiLineCtrl = CodeBlockWindow.GetTextControl();
	local textPrefix = "";
	local isCodeJunior = CodeBlockWindow.IsCodeJunior()
	if(page and textCtrl) then
		local codeEntity = CodeBlockWindow.GetCodeEntity();
		if(codeEntity) then
			local bReadOnly = CodeBlockWindow.IsBlocklyEditMode();
			textCtrl:setReadOnly(bReadOnly or CodeBlockWindow.IsCodeReadOnly())
		end
		
		local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
		if(CodeBlockWindow.IsBlocklyEditMode()) then
			if not isCodeJunior then
				_guihelper.SetUIColor(page:FindControl("blockMode"), "#0b9b3a")
				_guihelper.SetUIColor(page:FindControl("codeMode"), "#808080")
			end
			if(CodeBlockWindow.IsNPLBrowserVisible()) then
				CodeBlockWindow.SetNplBrowserVisible(true);
			end
			multiLineCtrl:SetBackgroundColor("#cccccc")
			local tipCtrl = page:FindControl("blocklyTip");
			if(tipCtrl) then
				tipCtrl.visible = true;
				textPrefix = "\n\n";  -- 空两行给提示
			end
			CodeBlockWindow.ShowTextEditor(CodeBlockWindow.blocklyTextMode == true)
		else
			CodeBlockWindow.ShowTextEditor(true)
			if not isCodeJunior then
				_guihelper.SetUIColor(page:FindControl("blockMode"), "#808080")
				_guihelper.SetUIColor(page:FindControl("codeMode"), "#0b9b3a")
			end
			CodeBlockWindow.SetNplBrowserVisible(false);
			multiLineCtrl:SetBackgroundColor("#00000000")
			local tipCtrl = page:FindControl("blocklyTip");
			if(tipCtrl) then
				tipCtrl.visible = false;
			end
		end
		
		local code_text = CodeBlockWindow.GetCodeFromEntity() or "";
		if (CodeBlockWindow.IsBlocklyEditMode()) then
			code_text = CodeBlockWindow.PrettyCode(code_text);
		end
		if(textPrefix and textPrefix~="") then
			code_text = textPrefix .. code_text;
		end
		textCtrl:SetText(code_text);

		textCtrl:Connect("userTyped", CodeBlockWindow, CodeBlockWindow.OnUserTypedCode, "UniqueConnection");
		textCtrl:Connect("keyPressed", CodeIntelliSense, CodeIntelliSense.OnUserKeyPress, "UniqueConnection");
		
		CodeIntelliSense.Close()
		if(CodeBlockWindow.RequestRestoreCursor) then
			CodeBlockWindow.RequestRestoreCursor = false;
			CodeBlockWindow.RestoreCursorPositionImp()
		end
	end
end

-- @param bForceRefresh: whether to refresh the content of the browser according to current blockly code. If nil, it will refresh if url has changed. 
function CodeBlockWindow.SetNplBrowserVisible(bVisible, bForceRefresh)
	if not System.options.enable_npl_brower then 
		bVisible = false
	end
    if(page)then
		-- block NPL.activate "cef3/NplCefPlugin.dll" if npl browser isn't loaded
		-- so that we can run auto updater normally
        if(bVisible and not CodeBlockWindow.NplBrowserIsLoaded())then
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
			ctl.visible = bVisible and not CodeBlockWindow.blocklyTextMode;
		end

        local ctl = page:FindControl("helpContainer")
		if(ctl) then
			ctl.visible = not (bVisible == true) or  CodeBlockWindow.blocklyTextMode
		end
		local ctl = page:FindControl("codeContainer")
		if(ctl) then
			ctl.visible = not (bVisible == true)  or  CodeBlockWindow.blocklyTextMode
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
	if(codeConfigType == "microbit")then
		local Microbit = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Microbit/Microbit.lua");
		request_url = Microbit.GetWebEditorUrl();
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
	local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
	local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)	end)
	if(bStarted) then
		return request_url:gsub("^npl:?/*", site_url);
	end
end

function CodeBlockWindow.OpenBlocklyEditor(bForceRefresh)
	if(not CodeBlockWindow.IsBlocklyEditMode()) then
		return
	end
	if (CodeBlockWindow.IsSupportNplBlockly()) then
		if (CodeBlockWindow.blocklyTextMode) then
			CodeBlockWindow.CloseNplBlocklyEditorPage();
			CodeBlockWindow.ShowTextEditor(true)
		else
			CodeBlockWindow.ShowTextEditor(false)
			CodeBlockWindow.ShowNplBlocklyEditorPage();
		end
		return;
	end
	
	if not CodeBlockWindow.CheckCanChangeMode() then
		return
	end

	local entity = CodeBlockWindow.GetCodeEntity();
	local blockpos;
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
	local bForceShow;
	if(codeConfigType == "microbit")then
		local Microbit = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/Microbit/Microbit.lua");
		request_url = Microbit.GetWebEditorUrl();
		bForceShow = true;
	end
	local function OpenInternalBrowser_()
		if((bForceShow or (not CodeBlockWindow.blocklyTextMode))) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
			local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
			local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
				if(bStarted) then
					CodeBlockWindow.SetNplBrowserVisible(true, bForceRefresh)
				end
			end)
		else
			CodeBlockWindow.SetNplBrowserVisible(false)
		end
	end
	if(not CodeBlockWindow.NplBrowserIsLoaded() and System.options.enable_npl_brower) then
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
		return true
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
	if not CodeBlockWindow.CheckCanChangeMode() then
		return	
	end
	if(mouse_button == "left") then
		if(CodeBlockWindow.IsNPLBrowserVisible()) then
			CodeBlockWindow.SetNplBrowserVisible(false);
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockSettings.lua");
		local CodeBlockSettings = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockSettings");
		CodeBlockSettings.Show(true)
	else
		CodeBlockWindow.GotoCodeBlock()
	end
end

function CodeBlockWindow.GotoCodeBlock()
	local codeblock = CodeBlockWindow.GetCodeBlock()
	if(codeblock) then
		local x, y, z = codeblock:GetBlockPos()
		if(x and y and z) then
			GameLogic.RunCommand(format("/goto %d %d %d", x, y+1, z));
		end
	end
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
				task:ShowFindFile(text, function(lastGotoItemIndex)
					if(not lastGotoItemIndex) then
						CodeBlockWindow.SetFocusToTextControl();
					end
				end)
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

function CodeBlockWindow.IsSupportNplBlockly()
	local entity = CodeBlockWindow.GetCodeEntity();
	local language = entity and entity:GetCodeLanguageType();
	return language ~= "python" and not CodeBlockWindow.IsMicrobitEntity() and entity and type(entity.IsBlocklyEditMode) and type(entity.IsUseNplBlockly) == "function" and entity:IsBlocklyEditMode() and entity:IsUseNplBlockly();
end
		
function CodeBlockWindow.OnTryOpenMicrobit()
	if(CodeBlockWindow.IsMicrobitEntity() and CodeBlockWindow.IsVisible())then
		local entity = CodeBlockWindow.GetCodeEntity();
		entity:SetBlocklyEditMode(true);
		CodeBlockWindow.OpenBlocklyEditor(true);	
	end
end
function CodeBlockWindow.IsMicrobitEntity()
	local entity = CodeBlockWindow.GetCodeEntity();
	if(entity)then
		local configFile = entity:GetLanguageConfigFile()
		if(configFile == "microbit") then
			return true;
		end
	end
end
function CodeBlockWindow.UpdateNplBlocklyCode()
	local codeEntity = CodeBlockWindow.GetCodeEntity();
	if (not NplBlocklyEditorPage or not codeEntity or CodeBlockWindow.isUpdatingNPLBlocklyUIFromCode) then return end
	if (not CodeBlockWindow.IsSupportNplBlockly()) then return end
	if (not CodeBlockWindow.IsBlocklyEditMode()) then return print("---------------------------NOT IsBlocklyEditMode---------------------------") end 

	local G = NplBlocklyEditorPage:GetG();
	local code = type(G.GetCode) == "function" and G.GetCode() or "";
	local xml = type(G.GetXml) == "function" and G.GetXml() or "";

	local hasCodeChanged = codeEntity:GetNPLBlocklyNPLCode() ~= code;
	if(hasCodeChanged) then
		codeEntity:BeginEdit();
	end
	codeEntity:SetNPLBlocklyXMLCode(xml);
	codeEntity:SetNPLBlocklyNPLCode(code);
	if(hasCodeChanged) then
		codeEntity:EndEdit();
	end
end

function CodeBlockWindow.PrepareNplBlocklyConfig(entity)
	local config = {};
	local LanguageConfig = NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
	local language = entity:GetLanguageConfigFile();
	language = LanguageConfig.GetLanguageName(language);
	language = entity:IsUseCustomBlock() and "CustomWorldBlock" or language;

	local toolbox_xmltext = entity:GetNplBlocklyToolboxXmlText();
    toolbox_xmltext = string.gsub(toolbox_xmltext or "", "^%s*", "");
    toolbox_xmltext = string.gsub(toolbox_xmltext, "%s*$", "");

	config.language = language;
	config.toolbox_xmltext = toolbox_xmltext;
	config.workspace_xmltext = entity:GetNPLBlocklyXMLCode() or "";
	
	local version = entity:GetLanguageVersion();
	config.version = version;

	local bx, by, bz = entity:GetBlockPos();

	-- 如果是录制
    if (GameLogic.Macros:IsRecording()) then
        GameLogic.Macros:AddMacro("NplBlocklyMacroConfig", {
            language = language,
            version = version,
			bx = bx, by = by, bz = bz,
        });
    end
	
    -- 如果是播放
    if (GameLogic.Macros:IsPlaying()) then
		local offset = 0;
		local macro = nil;
		-- 查找最近的宏配置
		while (true) do
			local last_macro = GameLogic.Macros:PeekNextMacro(-offset);
			local next_macro = GameLogic.Macros:PeekNextMacro(offset);
			if (last_macro == nil and next_macro == nil) then 
				break;
			elseif (last_macro and last_macro.name == "NplBlocklyMacroConfig") then
				macro = last_macro;
				break;
			elseif (next_macro and next_macro.name == "NplBlocklyMacroConfig") then
				macro = next_macro;
				break;
			else
				offset = offset + 1;
			end
		end
		local bFoundConfig = false;
		if (macro ~= nil) then
			local params = macro:GetParams();
			params = type(params) == "table" and params[1] or params;
			if (type(params) == "table" and params.bx == bx and params.by == by and params.bz == bz) then
				config.language = params.language or language;
				config.version = params.version or version;
				bFoundConfig = true;
			end
		end
		-- 未找配置
		if (not bFoundConfig) then
			config.version = "0.0.0"; -- 版本使用初始版本
		end
    end
	if (toolbox_xmltext == "") then 
		config.toolbox_xmltext = LanguageConfig.GetToolBoxXmlText(config.language, config.version);
	end 

	-- 初始cad版本使用程序自动转换的图块定义
	if (config.language == "cad" and config.version == "0.0.0") then config.language = "old_cad" end 
	
	return config;
end

function CodeBlockWindow.ShowNplBlocklyEditorPage()
	if(CodeBlockWindow.IsNPLBrowserVisible()) then
		CodeBlockWindow.SetNplBrowserVisible(false);
	end

	CodeBlockWindow.CloseNplBlocklyEditorPage();
	if (not CodeBlockWindow.IsSupportNplBlockly()) then return end
	local entity = CodeBlockWindow.GetCodeEntity();
	if (not entity) then return end 

	CodeHelpWindow.SetLanguageConfigFile(entity:GetLanguageConfigFile(),entity:GetCodeLanguageType());
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	local isCodeJunior = CodeBlockWindow.IsCodeJunior()
	local offsetY =  (isCodeJunior or (IsMobileUIEnabled and entity:GetLanguageConfigFile() ~="npl_cad" and entity:GetCodeLanguageType() ~= "python" and entity:GetLanguageConfigFile() ~="npl_camera")) and 64 or 45
	local offsetHeight = isCodeJunior and 22 or (IsMobileUIEnabled and 36 or 0)
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	local width, height, margin_right, bottom, top, sceneMarginBottom = self:CalculateMargins();
	local config = CodeBlockWindow.PrepareNplBlocklyConfig(entity);
	NplBlocklyEditorPage = Page.Show({
		-- Language = (language == "npl" or language == "") and "SystemNplBlock" or "npl",
		Language = config.language,
		ReadOnly = CodeBlockWindow.IsCodeReadOnly(),
		xmltext = config.workspace_xmltext,
		ToolBoxXmlText = config.toolbox_xmltext,
		OnChange = function()
			CodeBlockWindow.UpdateNplBlocklyCode();
		end,
		OnGenerateBlockCodeBefore = function(block)
			if (not entity:IsStepMode() or block:IsOutput()) then return end
			return "checkstep_nplblockly(" .. block:GetId() ..", true, 0.5)\n";
		end,
		OnGenerateBlockCodeAfter = function(block)
			if (not entity:IsStepMode() or block:IsOutput()) then return end
			return "checkstep_nplblockly(0, false, 0)\n";
		end,
	}, { 
		url = "%ui%/Blockly/Pages/NplBlockly.html",
		alignment="_rt",
		x = 0, y = offsetY + top,
		height = height - 45 - 54 + offsetHeight,
		width = width,
		isAutoScale = false,
		windowName = "UICodeBlockWindow",
		minRootScreenWidth = 0,
		minRootScreenHeight = 0,
		zorder = -2,
	});
end

function CodeBlockWindow.IsShowTextEditor()
	return CodeBlockWindow.bShowTextEditor ~= false;
end

function CodeBlockWindow.ShowTextEditor(bShow)
	CodeBlockWindow.bShowTextEditor = bShow == true;
	if(page) then
		local helpCtrl = page:FindUIControl("helpContainer")
		if(helpCtrl) then
			helpCtrl.visible = CodeBlockWindow.bShowTextEditor;
		end
		local codeCtrl = page:FindUIControl("codeContainer")
		if(codeCtrl) then
			codeCtrl.visible = CodeBlockWindow.bShowTextEditor;
		end
	end
end

function CodeBlockWindow.CloseNplBlocklyEditorPage()
	if (not NplBlocklyEditorPage) then return end
	CodeBlockWindow.UpdateNplBlocklyCode();
	NplBlocklyEditorPage:CloseWindow();
	NplBlocklyEditorPage = nil;
end

function CodeBlockWindow.HasNplBlocklyEditorPage()
	return NplBlocklyEditorPage ~= nil
end

function CodeBlockWindow.IsNormalCode()
	local entity = CodeBlockWindow.GetCodeEntity();
	if (not entity) then return  false end 
	local id = entity:GetBlockId()
	local re = entity:GetLanguageConfigFile() ~="npl_cad" and entity:GetCodeLanguageType() ~= "python" and entity:GetLanguageConfigFile() ~="npl_camera" and entity:GetLanguageConfigFile() ~= "microbit"
	return re
end

function CodeBlockWindow.SetFontSize(value)
	CodeBlockWindow.fontSize = value or 13;
	if(page) then
		page:Refresh(0.01);
	end
end

function CodeBlockWindow.GetFontSize()
	local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	local defaultFontSize = 13;
	if (IsMobileUIEnabled and not GameLogic.Macros:IsRecording() and not GameLogic.Macros:IsPlaying()) then
		defaultFontSize = 24;
	end
	return CodeBlockWindow.fontSize or defaultFontSize;
end

function CodeBlockWindow.OnClickShowConsoleText()
	ChatWindow.ShowAllPage();
	ChatWindow.HideEdit();
	ChatWindow.OnSwitchChannelDisplay(ChatChannel.EnumChannels.NearBy);
end

function CodeBlockWindow.OnClickHideConsoleText()
	ChatWindow.HideChatLog();
end

function CodeBlockWindow.OnClickClearConsoleText()
	CodeBlockWindow.SetConsoleText("");
	ChatChannel.ClearChat(ChatChannel.EnumChannels.NearBy);
	ChatWindow.OnSwitchChannelDisplay("0");
end

function CodeBlockWindow.OnClickShowHideConsoleText()
	if (CodeBlockWindow.bShowChatLogWindow) then
		CodeBlockWindow.OnClickHideConsoleText();
	else
		CodeBlockWindow.OnClickShowConsoleText();
	end
end

function CodeBlockWindow.OnChatLogWindowShowAndHide(bShow)
	if(page) then
		if (bShow) then
			page:SetUIBackground("OnClickHideConsoleTextIcon", "Texture/Aries/Creator/keepwork/icons/yincang_16x16_32bits.png#0 0 16 16");
		else
			page:SetUIBackground("OnClickHideConsoleTextIcon", "Texture/Aries/Creator/keepwork/icons/xianshi_16x10_32bits.png#0 0 16 16");
		end
	end
	CodeBlockWindow.bShowChatLogWindow = bShow;
	-- if(page) then page:Refresh(0.01) end
end

-- beautify and format code
-- @param spacing: default to "    ", it can also be "\t"
function CodeBlockWindow.FormatCode(spacing)
	local ctrl = CodeBlockWindow.GetTextControl()
	if(not CodeBlockWindow.IsBlocklyEditMode() and ctrl) then
		local text = CodeBlockWindow.PrettyCode(ctrl:GetText())
		if(text) then
			ctrl:SetText(text)
		end

		--[[
		NPL.load("(gl)script/ide/System/Compiler/nplc.lua");
		local nplp = System.Compiler.nplp:new()
		local nplGenerator = System.Compiler.nplgen:new()
		nplGenerator:SetIgnoreNewLine(false)
		nplGenerator:SetIgnoreIdentation(false)
		nplGenerator:SetCurrentIndentation(-1)
		nplGenerator:SetIdentStepString(spacing or "    ")
		local ast = nplp:src_to_ast(ctrl:GetText(), CodeBlockWindow.GetFilename() or "")
		if(ast) then
			local compiled_src = nplGenerator:run(ast)
			if(compiled_src) then
				ctrl:SetText(compiled_src)
			end
		end
		]]
	end
end

CodeBlockWindow:InitSingleton();
