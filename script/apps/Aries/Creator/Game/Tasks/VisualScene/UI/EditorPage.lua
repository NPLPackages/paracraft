--[[
Title: EditorPage
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local EditorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/EditorPage.lua");
EditorPage.Show(true);

local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
VisualSceneLogic.onSelectedEditorByName(VisualSceneLogic.PresetEditors.GlobalEditor);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Windows/Window.lua")
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");

local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");

local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");

local EditorPage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local page;
EditorPage.Current_Item_DS = {};
EditorPage.name = "EditorPage_page";
EditorPage.url = "script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/EditorPage.html";
function EditorPage.Show(bShow)
    if(not bShow) then
		EditorPage.Close();
        return
	else
		GameLogic.GetFilters():add_filter("VisualSceneLogic.nofityChanged", EditorPage.OnRefreshCallback);
		GameLogic.GetFilters():add_filter("VisualSceneLogic.onSelectedEditorByName", EditorPage.OnRefreshCallback);
		GameLogic.GetFilters():add_filter("Editor.createBlockCodeNode", EditorPage.OnRefreshCallback);

		local _this = ParaUI.GetUIObject(EditorPage.name);
		if(not _this:IsValid()) then
			EditorPage.width, EditorPage.height, EditorPage.margin_right, EditorPage.bottom, EditorPage.top, sceneMarginBottom = EditorPage.CalculateMargins();
			_this = ParaUI.CreateUIObject("container", EditorPage.name, "_mr", 0, EditorPage.top, EditorPage.width, EditorPage.bottom);
			_this.zorder = -2;
			_this.background="";
			_this:SetScript("onsize", function()
				EditorPage.OnViewportChange();
			end)
			local viewport = ViewportManager:GetSceneViewport();
			viewport:SetMarginRight(EditorPage.margin_right);
			viewport:SetMarginRightHandler(EditorPage);

			if(sceneMarginBottom~=0) then
				if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == EditorPage) then
					viewport:SetMarginBottom(sceneMarginBottom);
					viewport:SetMarginBottomHandler(EditorPage);
				end
			end

			viewport:Connect("sizeChanged", EditorPage, EditorPage.OnViewportChange, "UniqueConnection");

			_this:SetScript("onclick", function() end); -- just disable click through 
			_guihelper.SetFontColor(_this, "#ffffff");
			_this:AttachToRoot();
			
			page = System.mcml.PageCtrl:new({url = EditorPage.url});
			page:Create(EditorPage.name.."page", _this, "_fi", 0, 0, 0, 0);
		end

		_this.visible = true;
		EditorPage.OnViewportChange();
		local viewport = ViewportManager:GetSceneViewport();
		viewport:SetMarginRight(EditorPage.margin_right);
		viewport:SetMarginRightHandler(EditorPage);


        VisualSceneLogic.reSelectedEditor();
		
	end
end

function EditorPage.IsBigCodeWindowSize()
	return EditorPage.BigCodeWindowSize;
end

function EditorPage.SetBigCodeWindowSize(enabled)
	if(EditorPage.BigCodeWindowSize ~= enabled) then
		EditorPage.BigCodeWindowSize = enabled;
		EditorPage.OnViewportChange();
	end
end

function EditorPage.ToggleSize()
	local EditorPage = EditorPage;
	EditorPage.SetBigCodeWindowSize(not EditorPage.IsBigCodeWindowSize());
end

-- @return width, height, margin_right, margin_bottom, margin_top
function EditorPage.CalculateMargins()
	local MAX_3DCANVAS_WIDTH = 800;
	local MIN_CODEWINDOW_WIDTH = 200+350;
	local viewport = ViewportManager:GetVisualSceneEditorViewport();
	local width = math.max(math.floor(Screen:GetWidth() * 1/3), MIN_CODEWINDOW_WIDTH);
	local halfScreenWidth = math.floor(Screen:GetWidth()/2);
	if(halfScreenWidth > MAX_3DCANVAS_WIDTH) then
		width = halfScreenWidth;
	elseif((Screen:GetWidth() - width) > MAX_3DCANVAS_WIDTH) then
		width = Screen:GetWidth() - MAX_3DCANVAS_WIDTH;
	end

	local bottom, sceneMarginBottom = 0, 0;
	if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == EditorPage) then
		bottom = 0;
		if(EditorPage.IsBigCodeWindowSize()) then
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

function EditorPage.OnViewportChange()
	if(EditorPage.IsVisible()) then
		local viewport = ViewportManager:GetSceneViewport();
		
		-- TODO: use a scene/ui layout manager here
		local width, height, margin_right, bottom, top, sceneMarginBottom = EditorPage.CalculateMargins();
		if(EditorPage.width ~= width or EditorPage.height ~= height) then
			EditorPage.width = width;
			EditorPage.height = height;
			EditorPage.margin_right = margin_right;
			EditorPage.bottom = bottom;
			EditorPage.top = top;
			
			viewport:SetMarginRight(EditorPage.margin_right);
			viewport:SetMarginRightHandler(EditorPage);

			local _this = ParaUI.GetUIObject(EditorPage.name);
			_this:Reposition("_mr", 0, EditorPage.top, EditorPage.width, EditorPage.bottom);
			if(page) then
				page:Rebuild();
			end
		end
		if(sceneMarginBottom ~= viewport:GetMarginBottom())then
			if(viewport:GetMarginBottomHandler() == nil or viewport:GetMarginBottomHandler() == EditorPage) then
				viewport:SetMarginBottom(sceneMarginBottom);
				viewport:SetMarginBottomHandler(EditorPage);
			end
		end
	end
end
function EditorPage.IsVisible()
	return page and page:IsVisible();
end
function EditorPage.Close()
    EditorPage.RestoreWindowLayout();
end

function EditorPage.RestoreWindowLayout()
	local _this = ParaUI.GetUIObject(EditorPage.name)
	if(_this:IsValid()) then
		_this.visible = false;
		_this:LostFocus();
	end
	local viewport = ViewportManager:GetVisualSceneEditorViewport();
	if(viewport:GetMarginBottomHandler() == EditorPage) then
		viewport:SetMarginBottomHandler(nil);
		viewport:SetMarginBottom(0);
	end
	if(viewport:GetMarginRightHandler() == EditorPage) then
		viewport:SetMarginRightHandler(nil);
		viewport:SetMarginRight(0);
	end
end

function EditorPage.OnRefreshCallback()
    if(not EditorPage.IsVisible())then
        return
    end
    EditorPage.OnRefresh()
end
function EditorPage.OnRefresh(time)
    if(page) then
	    page:Refresh(time or 0.01);
    end
end
