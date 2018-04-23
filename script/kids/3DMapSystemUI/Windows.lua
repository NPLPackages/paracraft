--[[
Title: windows UI for 3D Map system
Author(s): WangTian
Date: 2007/9/20
Desc: manage the windows UI in 3D Map system
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemData/WindowData.lua");
if(not Map3DSystem.UI.Windows) then  Map3DSystem.UI.Windows = {} end
if(not Map3DSystem.UI.Windows.WndSet) then  Map3DSystem.UI.Windows.WndSet = {} end

local param = {
	wnd = _wnd,
	--isUseUI = true,
	mainBarIconSetID = 19, -- or nil
	icon = "Texture/3DMapSystem/MainBarIcon/Setting_1.png",
	iconSize = 48,
	text = "ParaWorld Setting",
	style = Map3DSystem.UI.Windows.Style[1],
	maximumSizeX = 600,
	maximumSizeY = 600,
	minimumSizeX = 400,
	minimumSizeY = 400,
	isShowIcon = true,
	--opacity = 100, -- [0, 100]
	isShowMaximizeBox = false,
	isShowMinimizeBox = false,
	isShowAutoHideBox = false,
	allowDrag = true,
	allowResize = false,
	initialPosX = 250,
	initialPosY = 100,
	initialWidth = 500,
	initialHeight = 500,
	
	-- set the window to top level
	-- NOTE: be careful with this setting. in some cases 
	--		top level window will ruin mouse enter-and-leave pairs 
	--		and currently drag-and-drop UI control
	isTopLevel = false, -- false or nil will set the window to normal UI container
	
	ShowUICallback = nil,
	
};


local newParam = {
	wnd = _wnd,
	--isUseUI = true,
	--mainBarIconSetID = 19, -- or nil -- DEPRECATED
	
	width = nil,
	height = nil,
	
	alignment = nil, -- Free|Left|Right|Bottom
	
	appkey = nil,
	windowName = nil,
	
	windowIcon = "Texture/3DMapSystem/MainBarIcon/Setting_1.png", --  window icon is shown in middle with the text
	windowText = "window text", --  window icon is shown in middle with the text
	iconSize = 48,
	text = "ParaWorld Setting",
	style = Map3DSystem.UI.Windows.Style[1],
	maximumSizeX = 600,
	maximumSizeY = 600,
	minimumSizeX = 400,
	minimumSizeY = 400,
	isShowIcon = true,
	--opacity = 100, -- [0, 100]
	isShowMaximizeBox = false,
	isShowMinimizeBox = false,
	isShowAutoHideBox = false,
	allowDrag = true,
	allowResize = false,
	initialPosX = 250,
	initialPosY = 100,
	initialWidth = 500,
	initialHeight = 500,
	
	-- set the window to top level
	-- NOTE: be careful with this setting. in some cases 
	--		top level window will ruin mouse enter-and-leave pairs 
	--		and currently drag-and-drop UI control
	isTopLevel = false, -- false or nil will set the window to normal UI container
	
	ShowUICallback = nil,
	
};


--------------------- This is the new window class ---------------------

--function Map3DSystem.UI.Windows:new(o)
--end
--
---- show the window on the screen
--function Map3DSystem.UI.Windows:Show(bShow)
	--
	--local taskBarHeight = 0;
	--
	--local windowMainContName = self.windowName.."@"..self.appkey;
	--
	----local _resizer_BG = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_resizerBG", "_rb", 
		----_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
	----_resizer_BG.background = _style.resizer;
	----_window:AddChild(_resizer_BG);
	--
	--local _window = ParaUI.GetUIObject(windowMainContName);
	--if(_window:IsValid() == false) then
		--if(alignment == "Free") then
			--_window = ParaUI.CreateUIObject("container", windowMainContName, "_ml", 0, 0, self.width or 200, 0);
			--_window:AttachToRoot();
		--elseif(alignment == "Left") then
			--_window = ParaUI.CreateUIObject("container", windowMainContName, "_ml", 0, 0, self.width or 200, 0);
			--_window:AttachToRoot();
		--elseif(alignment == "Right") then
			--_window = ParaUI.CreateUIObject("container", windowMainContName, "_mr", 0, 0, self.width or 200, 0);
			--_window:AttachToRoot();
		--elseif(alignment == "Bottom") then
			--_window = ParaUI.CreateUIObject("container", windowMainContName, "_ctb", 0, 0, self.width or 500, self.height or 150);
			--_window:AttachToRoot();
		--end
	--else
		--if(bShow == nil) then
			--bShow = not _window.visible;
		--end
		--_window.visible = bShow;
	--end
--end

------------------------------------------------------------------------



--function Map3DSystem.UI.Windows:new(o)
	--if(type(o) == "table") then
		--log("error: Map3DSystem.UI.Windows:new(o) fail, table expected got none table.");
	--end
	--
	--setmetatable(o, self)
	--self.__index = self
	--
	--local _wnd = param.wnd;
	----local _isUseUI = param.isUseUI;
	--local _mainBarIconSetID = param.mainBarIconSetID; -- can be nil
	--local _appID = param.appid; -- can be nil
	--local _iconPath = param.iconPath;
	--local _iconSize = param.iconSize;
	--local _text = param.text;
	--local _style = param.style;
	--local _maximumSizeWidth = param.maximumSizeWidth;
	--local _maximumSizeHeight = param.maximumSizeHeight;
	--local _minimumSizeWidth = param.minimumSizeWidth;
	--local _minimumSizeHeight = param.minimumSizeHeight;
	--local _isShowIcon = param.isShowIcon;
	----local _opacity = param.opacity;
	--local _isShowMaximizeBox = param.isShowMaximizeBox;
	--local _isShowMinimizeBox = param.isShowMinimizeBox;
	--local _isShowAutoHideBox = param.isShowAutoHideBox;
	--local _allowDrag = param.allowDrag;
	--local _allowResize = param.allowResize;
	--local _initialPosX = param.initialPosX;
	--local _initialPosY = param.initialPosY;
	--local _initialWidth = param.initialWidth;
	--local _initialHeight = param.initialHeight;
	--
	--local _ShowUICallback = param.ShowUICallback;
	--
	---- windows style
	--local _frameBG = _style.frameBG;
	--local _minBox = _style.min;
	--local _maxBox = _style.max;
	--local _autoHideBox = _style.autoHide;
	--local _closeBox = _style.close;
	--local _resizerBox = _style.resizer;
	--
	--local _appName = _wnd.app.name;
	--local _wndName = _wnd.name;
	--
	---- find in WndSet table if application exists
	--if(not Map3DSystem.UI.Windows.WndSet[_appName]) then
		--Map3DSystem.UI.Windows.WndSet[_appName] = {};
		----log("log: Create window set:".._appName..". \r\n");
	--end
	--
	---- find in WndSet table if window exists
	--if(not Map3DSystem.UI.Windows.WndSet[_appName][_wndName]) then
		----Map3DSystem.UI.Windows.WndSet[_appName][_wndName] = {};
		---- write the window param to window set
		--Map3DSystem.UI.Windows.WndSet[_appName][_wndName] = param;
		----log("log: Create window:".._wndName..". \r\n");
	--else
		--log("Warning: window to be registered: ".._wndName.." already exists. \r\n");
		--local _document = ParaUI.GetUIObject(_appName.."_".._wndName.."_window_document");
		--if(_document:IsValid()) then
			--return _appName, _wndName, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName];
		--else
			--log("error: document UIObject not exist in WndSet[".._appName.."][".._wndName.."]. UI recreate\n");
			----return _appName, _wndName, nil, nil;
		--end
	--end
	--
	--local _window = ParaUI.GetUIObject(_appName.."_".._wndName.."_wnd");
	--
	--if(_window:IsValid() == true) then
		--log("Error: window: ".._wndName.." UI information already initialized. \r\n");
		--return nil;
	--else
		---- main window UI container
		--_window = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window", 
			--"_lt", _initialPosX, _initialPosY, _initialWidth, _initialHeight);
		--_window.candrag = _allowDrag;
		---- so that drag can be ended on any where on the screen. 
		--_window.ondragbegin = [[;ParaUI.AddDragReceiver("root");]];
		--_window.background = _frameBG;
		--_window:AttachToRoot();
		--
		--if(_isShowMinimizeBox) then
			--local _min = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_min", 
				--"_rt", _style.minPos[1], _style.minPos[2], _style.boxSize, _style.boxSize);
			--_min.background = _minBox;
			--_min.onclick = ";Map3DSystem.UI.Windows.OnClickMin(\"".._appName.."\", \"".._wndName.."\");";
			--_window:AddChild(_min);
		--end
		--
		--if(_isShowMaximizeBox) then
			--local _max = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_max", 
				--"_rt", _style.maxPos[1], _style.maxPos[2], _style.boxSize, _style.boxSize);
			--_max.background = _maxBox;
			--_max.onclick = ";Map3DSystem.UI.Windows.OnClickMax(\"".._appName.."\", \"".._wndName.."\");";
			--_window:AddChild(_max);
		--end
		--
		--if(_isShowAutoHideBox) then
			--local _autohide = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_autohide", 
				--"_rt", _style.autoHidePos[1], _style.autoHidePos[2], _style.boxSize, _style.boxSize);
			--_autohide.background = _autoHideBox;
			--_autohide.onclick = ";Map3DSystem.UI.Windows.OnClickAutoHide(\"".._appName.."\", \"".._wndName.."\");";
			--_window:AddChild(_autohide);
		--end
		--
		--local _close = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_close", 
			--"_rt", _style.closePos[1], _style.closePos[2], _style.boxSize, _style.boxSize);
		--_close.background = _closeBox;
		--_close.onclick = ";Map3DSystem.UI.Windows.OnClickClose(\"".._appName.."\", \"".._wndName.."\");";
		--_window:AddChild(_close);
		--
		--if(_isShowIcon) then
			--local _icon = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_icon", 
				--"_lt", 0, _style.topHeight - _iconSize, _iconSize, _iconSize);
			--_icon.background = _iconPath;
			--_window:AddChild(_icon);
		--end
		--
		--local _toptext = ParaUI.CreateUIObject("text", _appName.."_".._wndName.."_window_toptext", 
			--"_lt", _iconSize + _style.textPosXAdd, _style.textPosY, 70, 16);
		--_toptext.text = _text;
		--_guihelper.SetUIFontFormat(_toptext, 36); -- single lined vertical centered text. 
		--_window:AddChild(_toptext);
		--
		---- document container
		--local _document_frame = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_document_frame", 
			--"_lt", _style.leftBorderWidth, _style.topHeight, 
			--_initialWidth - _style.leftBorderWidth - _style.rightBorderWidth, 
			--_initialHeight - _style.topHeight - _style.bottomHeight);
		--_document_frame.background = "";
		--_window:AddChild(_document_frame);
		--
		--local _document = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_document", "_fi", 0, 0, 0, 0);
		--_document.background = "";
		--_document_frame:AddChild(_document);
		--
		--
		--if(_allowResize) then
			---- resizer container
			--local _resizer_BG = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_resizerBG", "_rb", 
				--_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
			--_resizer_BG.background = _style.resizer;
			--_window:AddChild(_resizer_BG);
			--
			--local _resizer = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_resizer", "_rb", 
				--_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
			--_resizer.background = "";
			--_resizer.candrag = true;
			--_resizer.ondragbegin = ";Map3DSystem.UI.Windows.OnDragBegin(\"".._appName.."\", \"".._wndName.."\");";
			--_resizer.ondragmove = ";Map3DSystem.UI.Windows.OnDragMove(\"".._appName.."\", \"".._wndName.."\");";
			--_resizer.ondragend = ";Map3DSystem.UI.Windows.OnDragEnd(\"".._appName.."\", \"".._wndName.."\");";
			--_window:AddChild(_resizer);
		--end
		--
		---- show the internal UI
		--_ShowUICallback(true, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName].wnd);
		--
		--return _appName, _wndName, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName];
	--end
	--
	--return o;
--end
--
--function Map3DSystem.UI.Windows:destroy()
--end
--
--if(not Map3DSystem.UI.WindowFrame) then
	--Map3DSystem.UI.WindowFrame = {};
--end
--
--function Map3DSystem.UI.WindowFrame:Show(bShow)
	--Map3DSystem.UI.Windows.ShowWindow(bShow, self.wnd.app.name, self.wnd.name);
--end
--
--function Map3DSystem.UI.WindowFrame:new(param)
	--local _appName, _wndName, _document, _frame = Map3DSystem.UI.Windows.RegisterWindowFrame(param);
	--setmetatable(_frame, self);
	--self.__index = self;
	--return _frame;
--end

-- Register Window UI

-- TODO: param

-- @return [1]: application name
--         [2]: window name
--         [3]: document UI object
--         [4]: window frame object
function Map3DSystem.UI.Windows.RegisterWindowFrame(param)

	if(not param) then
		log("Error: call function Map3DSystem.UI.Windows.RegisterWindow(). param nil value. \r\n");
		return nil;
	end
	
	local _wnd = param.wnd;
	--local _isUseUI = param.isUseUI;
	local _mainBarIconSetID = param.mainBarIconSetID; -- can be nil
	local _iconPath = param.icon;
	local _iconSize = param.iconSize or 48;
	local _text = param.text;
	local _style = param.style or Map3DSystem.UI.Windows.Style[1];
	local _maximumSizeX = param.maximumSizeX;
	local _maximumSizeY = param.maximumSizeY;
	local _minimumSizeX = param.minimumSizeX;
	local _minimumSizeY = param.minimumSizeY;
	local _isShowIcon = param.isShowIcon;
	--local _opacity = param.opacity;
	local _isShowMaximizeBox = param.isShowMaximizeBox;
	local _isShowMinimizeBox = param.isShowMinimizeBox;
	local _isShowAutoHideBox = param.isShowAutoHideBox;
	local _allowDrag = param.allowDrag;
	local _allowResize = param.allowResize;
	local _initialPosX = param.initialPosX;
	local _initialPosY = param.initialPosY;
	local _initialWidth = param.initialWidth;
	local _initialHeight = param.initialHeight;
	
	local _ShowUICallback = param.ShowUICallback;
	
	-- windows style
	local _frameBG = _style.frameBG;
	local _minBox = _style.min;
	local _maxBox = _style.max;
	local _autoHideBox = _style.autoHide;
	local _closeBox = _style.close;
	local _resizerBox = _style.resizer;
	
	local _appName = _wnd.app.name;
	local _wndName = _wnd.name;
	
	-- find in WndSet table if application exists
	if(not Map3DSystem.UI.Windows.WndSet[_appName]) then
		Map3DSystem.UI.Windows.WndSet[_appName] = {};
		--log("log: Create window set:".._appName..". \r\n");
	end
	
	-- find in WndSet table if window exists
	if(not Map3DSystem.UI.Windows.WndSet[_appName][_wndName]) then
		--Map3DSystem.UI.Windows.WndSet[_appName][_wndName] = {};
		-- write the window param to window set
		Map3DSystem.UI.Windows.WndSet[_appName][_wndName] = param;
		--log("log: Create window:".._wndName..". \r\n");
	else
		log("Warning: window to be registered: ".._wndName.." already exists. \r\n");
		local _document = ParaUI.GetUIObject(_appName.."_".._wndName.."_window_document");
		if(_document:IsValid()) then
			return _appName, _wndName, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName];
		else
			log("error: document UIObject not exist in WndSet[".._appName.."][".._wndName.."]. UI recreate\n");
			--return _appName, _wndName, nil, nil;
		end
	end
	
	local _window = ParaUI.GetUIObject(_appName.."_".._wndName.."_wnd");
	
	if(_window:IsValid() == true) then
		log("Error: window: ".._wndName.." UI information already initialized. \r\n");
		return nil;
	else
		
		------------------ add the new alignment window mode ------------------
		if(param.alignment == "Free" or param.alignment == nil) then
			-- free window mode
			-- main window UI container
			_window = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window", 
				"_lt", _initialPosX, _initialPosY, _initialWidth, _initialHeight);
			_window.candrag = _allowDrag;
			-- so that drag can be ended on any where on the screen. 
			_window.ondragbegin = [[;ParaUI.AddDragReceiver("root");]];
			_window.background = _frameBG;
			if(param.isTopLevel == true) then
				_window:SetTopLevel(true);
			end
			_window:AttachToRoot();
		elseif(param.alignment == "Right") then
		elseif(param.alignment == "Bottom") then
			-- disable the drag and resize function
			_allowResize = false;
			_allowDrag = false;
			
			local taskbarHeight = 48;
			
			-- main window UI container
			_window = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window", 
				"_ctb", 0, -taskbarHeight, _initialWidth, _initialHeight);
			_window.candrag = _allowDrag;
			-- so that drag can be ended on any where on the screen. 
			_window.ondragbegin = [[;ParaUI.AddDragReceiver("root");]];
			_window.background = _frameBG;
			if(param.isTopLevel == true) then
				_window:SetTopLevel(true);
			end
			_window:AttachToRoot();
		end
		-----------------------------------------------------------------------
		
		---- main window UI container
		--_window = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window", 
			--"_lt", _initialPosX, _initialPosY, _initialWidth, _initialHeight);
		--_window.candrag = _allowDrag;
		---- so that drag can be ended on any where on the screen. 
		--_window.ondragbegin = [[;ParaUI.AddDragReceiver("root");]];
		--_window.background = _frameBG;
		--if(param.isTopLevel == true) then
			--_window:SetTopLevel(true);
		--end
		--_window:AttachToRoot();
		
		if(_isShowMinimizeBox) then
			local _min = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_min", 
				"_rt", _style.minPos[1], _style.minPos[2], _style.boxSize, _style.boxSize);
			_min.background = _minBox;
			_min.onclick = ";Map3DSystem.UI.Windows.OnClickMin(\"".._appName.."\", \"".._wndName.."\");";
			_window:AddChild(_min);
		end
		
		if(_isShowMaximizeBox) then
			local _max = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_max", 
				"_rt", _style.maxPos[1], _style.maxPos[2], _style.boxSize, _style.boxSize);
			_max.background = _maxBox;
			_max.onclick = ";Map3DSystem.UI.Windows.OnClickMax(\"".._appName.."\", \"".._wndName.."\");";
			_window:AddChild(_max);
		end
		
		if(_isShowAutoHideBox) then
			local _autohide = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_autohide", 
				"_rt", _style.autoHidePos[1], _style.autoHidePos[2], _style.boxSize, _style.boxSize);
			_autohide.background = _autoHideBox;
			_autohide.onclick = ";Map3DSystem.UI.Windows.OnClickAutoHide(\"".._appName.."\", \"".._wndName.."\");";
			_window:AddChild(_autohide);
		end
		
		local _close = ParaUI.CreateUIObject("button", _appName.."_".._wndName.."_window_close", 
			"_rt", _style.closePos[1], _style.closePos[2], _style.boxSize, _style.boxSize);
		_close.background = _closeBox;
		_close.onclick = ";Map3DSystem.UI.Windows.OnClickClose(\"".._appName.."\", \"".._wndName.."\");";
		_window:AddChild(_close);
		
		if(_isShowIcon) then
			local _icon = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_icon", 
				"_lt", 0, _style.topHeight - _iconSize, _iconSize, _iconSize);
			_icon.background = _iconPath;
			_window:AddChild(_icon);
		end
		
		local _toptext = ParaUI.CreateUIObject("text", _appName.."_".._wndName.."_window_toptext", 
			"_lt", _iconSize + _style.textPosXAdd, _style.textPosY, 70, 16);
		_toptext.text = _text;
		_guihelper.SetUIFontFormat(_toptext, 36); -- single lined vertical centered text. 
		_window:AddChild(_toptext);
		
		-- document container
		local _document_frame = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_document_frame", 
			"_lt", _style.leftBorderWidth, _style.topHeight, 
			_initialWidth - _style.leftBorderWidth - _style.rightBorderWidth, 
			_initialHeight - _style.topHeight - _style.bottomHeight);
		_document_frame.background = "";
		_window:AddChild(_document_frame);
		
		local _document = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_window_document", "_fi", 0, 0, 0, 0);
		_document.background = "";
		_document_frame:AddChild(_document);
		
		
		if(_allowResize) then
			-- resizer container
			local _resizer_BG = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_resizerBG", "_rb", 
				_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
			_resizer_BG.background = _style.resizer;
			_window:AddChild(_resizer_BG);
			
			local _resizer = ParaUI.CreateUIObject("container", _appName.."_".._wndName.."_resizer", "_rb", 
				_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
			_resizer.background = "";
			_resizer.candrag = true;
			_resizer.ondragbegin = ";Map3DSystem.UI.Windows.OnDragBegin(\"".._appName.."\", \"".._wndName.."\");";
			_resizer.ondragmove = ";Map3DSystem.UI.Windows.OnDragMove(\"".._appName.."\", \"".._wndName.."\");";
			_resizer.ondragend = ";Map3DSystem.UI.Windows.OnDragEnd(\"".._appName.."\", \"".._wndName.."\");";
			_window:AddChild(_resizer);
		end
		
		if(type(param.zorder) == "number") then
			_window.zorder = param.zorder;
		end
		-- show the internal UI
		
		_ShowUICallback(true, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName].wnd);
		
		return _appName, _wndName, _document, Map3DSystem.UI.Windows.WndSet[_appName][_wndName];
	end
end


function Map3DSystem.UI.Windows.OnDragBegin(appName, wndName)
	local _resizer = ParaUI.GetUIObject(appName.."_"..wndName.."_resizer");
	--ParaUI.AddDragReceiver("root");
	local _window = ParaUI.GetUIObject(appName.."_"..wndName.."_window");
	local _doc = ParaUI.GetUIObject(appName.."_"..wndName.."_window_document_frame");
	Map3DSystem.UI.Windows.DraggingResizer = _resizer;
	Map3DSystem.UI.Windows.DraggingWindow = _window;
	Map3DSystem.UI.Windows.DraggingDoc = _doc;
end

function Map3DSystem.UI.Windows.OnDragMove(appName, wndName)
	
	--local _resizer = Map3DSystem.UI.Windows.DraggingResizer;
	--local _window = Map3DSystem.UI.Windows.DraggingWindow;
	--local _doc = Map3DSystem.UI.Windows.DraggingDoc;
	local _resizer = ParaUI.GetUIObject(appName.."_"..wndName.."_resizer");
	local _window = ParaUI.GetUIObject(appName.."_"..wndName.."_window");
	local _doc = ParaUI.GetUIObject(appName.."_"..wndName.."_window_document_frame");
	
	local x_resizer, y_resizer, width_resizer, height_resizer = _resizer:GetAbsPosition();
	local x_window, y_window, width_window, height_window = _window:GetAbsPosition();
	local x_doc, y_doc, width_doc, height_doc = _doc:GetAbsPosition();
	
	local newWidth = x_resizer - x_window + width_resizer;
	local newHeight = y_resizer - y_window + height_resizer;
	
	local _param = Map3DSystem.UI.Windows.WndSet[appName][wndName];
	
	local maxWidth = _param.maximumSizeX;
	local maxHeight = _param.maximumSizeY;
	local minWidth = _param.minimumSizeX;
	local minHeight = _param.minimumSizeY;
	
	-- not exceed the min and max
	if(newWidth < minWidth) then
		newWidth = minWidth;
	end
	if(newWidth > maxWidth) then
		newWidth = maxWidth;
	end
	if(newHeight < minHeight) then
		newHeight = minHeight;
	end
	if(newHeight > maxHeight) then
		newHeight = maxHeight;
	end
	
	_window.width = newWidth;
	_window.height = newHeight;
	
	_doc.width = newWidth - _param.style.leftBorderWidth - _param.style.rightBorderWidth;
	_doc.height = newHeight - _param.style.topHeight - _param.style.bottomHeight;
	
	NPL.load("(gl)script/ide/os.lua");
	local _wnd = Map3DSystem.UI.Windows.WndSet[appName][wndName].wnd;
	_wnd:SendMessage(wndName, CommonCtrl.os.MSGTYPE.WM_SIZE);
	
	--log("move: x:".._temp.width.." y:".._temp.height.."\r\n");
end

function Map3DSystem.UI.Windows.OnDragEnd(appName, wndName)
	
	--ParaUI.Destroy(appName.."_"..wndName.."_resizer");
	
	local _style = Map3DSystem.UI.Windows.WndSet[appName][wndName].style;
	
	-------------------------------------------------------------------
	-- NOTE: the dragging process is now improved
	--			dragging object no longer needs destroy and recreation process
	--			ParaUI.AddDragReceiver logics is implemented by ParaUIObject, (only one object is dragging at any time)
	--			which allows dragable objects to specify which UI receiver can receive it.
	-------------------------------------------------------------------
	
	--local _resizer = ParaUI.CreateUIObject("container", appName.."_"..wndName.."_resizer", "_rb", 
		--_style.resizerPos[1], _style.resizerPos[2], _style.resizerSize, _style.resizerSize);
		--
	----_resizer.background = "";
	--_resizer.candrag = true;
	--_resizer.ondragbegin = ";Map3DSystem.UI.Windows.OnDragBegin(\""..appName.."\", \""..wndName.."\");";
	--_resizer.ondragmove = ";Map3DSystem.UI.Windows.OnDragMove(\""..appName.."\", \""..wndName.."\");";
	--_resizer.ondragend = ";Map3DSystem.UI.Windows.OnDragEnd(\""..appName.."\", \""..wndName.."\");";
	--
	--local _window = Map3DSystem.UI.Windows.DraggingWindow;
	--_window:AddChild(_resizer);
	
	--Map3DSystem.UI.Windows.DraggingResizer = nil;
	--Map3DSystem.UI.Windows.DraggingWindow = nil;
	--Map3DSystem.UI.Windows.DraggingDoc = nil;
	
	NPL.load("(gl)script/ide/os.lua");
	local _wnd = Map3DSystem.UI.Windows.WndSet[appName][wndName].wnd;
	_wnd:SendMessage(wndName, CommonCtrl.os.MSGTYPE.WM_SIZE);
	
	--local x_drag, y_drag, width_drag, height_drag = _drag:GetAbsPosition();
	--local x_temp, y_temp, width_temp, height_temp = _temp:GetAbsPosition();
	--
	--_drag.x = x_temp + width_temp -64;
	--_drag.y = y_temp + height_temp - 16;
	--log("end: x:".._drag.x.." y:".._drag.y.."\r\n");
end

function Map3DSystem.UI.Windows.OnClickMin(appName, wndName)
	-- _guihelper.MessageBox("OnClickMin: "..appName.." "..wndName.."\r\n");
	NPL.load("(gl)script/ide/os.lua");
	local _wnd = Map3DSystem.UI.Windows.WndSet[appName][wndName].wnd;
	_wnd:SendMessage(wndName, CommonCtrl.os.MSGTYPE.WM_MINIMIZE);
end

function Map3DSystem.UI.Windows.OnClickMax(appName, wndName)
	_guihelper.MessageBox("OnClickMax: "..appName.." "..wndName.."\r\n");
end

function Map3DSystem.UI.Windows.OnClickAutoHide(appName, wndName)
	_guihelper.MessageBox("OnClickAutoHide: "..appName.." "..wndName.."\r\n");
end

function Map3DSystem.UI.Windows.OnClickClose(appName, wndName)
	--_guihelper.MessageBox("OnClickClose: "..appName.." "..wndName.."\r\n");
	
	NPL.load("(gl)script/ide/os.lua");
	local _wnd = Map3DSystem.UI.Windows.WndSet[appName][wndName].wnd;
	_wnd:SendMessage(wndName, CommonCtrl.os.MSGTYPE.WM_CLOSE);
end

function Map3DSystem.UI.Windows.UnRegisterWindowFrame(appName, wndName)
	
	-- find in WndSet table if window exist
	if(Map3DSystem.UI.Windows.WndSet[appName]) then
		if(Map3DSystem.UI.Windows.WndSet[appName][wndName]) then
		
			Map3DSystem.UI.Windows.WndSet[appName][wndName] = nil;
			-- destroy the UI container
			local _wnd = ParaUI.GetUIObject(appName.."_"..wndName.."_window");
			
			if(_wnd:IsValid() == false) then
				log("Error: window container is not yet registered.\r\n");
			else
				ParaUI.Destroy(appName.."_"..wndName.."_window");
			end
			
		else
			log("Warning: wndName not exists. \r\n");
		end
	else
		log("Warning: appName not exists. \r\n");
	end
	
end

function Map3DSystem.UI.Windows.GetWindowFrame(appName, wndName)
	if(Map3DSystem.UI.Windows.WndSet[appName]) then
		return Map3DSystem.UI.Windows.WndSet[appName][wndName];
	else
		return nil;
	end
end

function Map3DSystem.UI.Windows.GetWindowFrameDocument(appName, wndName)
	return ParaUI.GetUIObject(appName.."_"..wndName.."_window_document");
end

function Map3DSystem.UI.Windows.PaintWindow(appName, wndName, color)
	local _frame = ParaUI.GetUIObject(appName.."_"..wndName.."_window");
	
	NPL.load("(gl)script/ide/gui_helper.lua");
	_guihelper.SetUIColor(_frame, color);
end

--@param bShow: boolean to show or hide. if nil, it will toggle current setting.
function Map3DSystem.UI.Windows.ShowWindow(bShow, appName, wndName)
	
	-- find in WndSet table if window exist
	local app = Map3DSystem.UI.Windows.WndSet[appName]
	if(not app) then return end
	local param = app[wndName];	
	if(param~=nil) then
		local _wnd = ParaUI.GetUIObject(appName.."_"..wndName.."_window");
		
		if(_wnd:IsValid() == false) then
			log("Error: window container is not yet initialized."..appName.."\r\n");
			Map3DSystem.UI.Windows.RegisterWindowFrame(param);
			
			-- comment off by Andy 08.4.29
			---- show the internal UI
			--local _document = Map3DSystem.UI.Windows.GetWindowFrameDocument(appName, wndName);
			--param.ShowUICallback(true, _document, param.wnd);
			
		else
			if(bShow == nil) then
				bShow = not _wnd.visible;
			end
			_wnd.visible = bShow;
			if(bShow) then
				_wnd:BringToFront();
			end	
			
			-- show the internal UI
			local _document = Map3DSystem.UI.Windows.GetWindowFrameDocument(appName, wndName);
			param.ShowUICallback(bShow, _document, param.wnd);
		end
	else
		log("Warning: window not exists. \r\n");
	end
end

function Map3DSystem.UI.Windows.ShowApplication(appName)
	
	-- find in WndSet table if application exist
	local app = Map3DSystem.UI.Windows.WndSet[appName]
	if(app~=nil) then
		local k, v;
		for k, v in pairs(app) do
			Map3DSystem.UI.Windows.ShowWindow(true, appName,k);
		end
	else
		log("Warning: application not exists when calling Map3DSystem.UI.Windows.ShowApplication. \r\n");
	end
end


function Map3DSystem.UI.Windows.HideApplication(appName)
	
	-- find in WndSet table if application exist
	local app = Map3DSystem.UI.Windows.WndSet[appName]
	if(app~=nil) then
		local k, v;
		for k, v in pairs(app) do
			Map3DSystem.UI.Windows.ShowWindow(false, appName,k);
		end
	else
		log("Warning: application not exists when calling Map3DSystem.UI.Windows.HideApplication. \r\n");
	end
end