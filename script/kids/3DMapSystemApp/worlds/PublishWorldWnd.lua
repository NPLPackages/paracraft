--[[
Title: the publish world wizard window. 
Author(s): LiXizhi
Date: 2008/2/14
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/PublishWorldWnd.lua");
Map3DSystem.App.worlds.PublishWorldWnd.ShowWindow(_app)
-------------------------------------------------------
]]
if(not Map3DSystem.App.worlds.PublishWorldWnd) then Map3DSystem.App.worlds.PublishWorldWnd={}; end

-- show the wizard
function Map3DSystem.App.worlds.PublishWorldWnd.ShowWindow(_app)
	NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
	_app = _app or Map3DSystem.App.worlds.app._app;
	local _wnd = _app:FindWindow("PublishWorld") or _app:RegisterWindow("PublishWorld", nil, Map3DSystem.App.worlds.PublishWorldWnd.MSGProc);
	
	NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");

	local _appName, _wndName, _document, _frame;
	_frame = Map3DSystem.App.worlds.Windows.GetWindowFrame(_wnd.app.name, _wnd.name);
	if(_frame) then
		_appName = _frame.wnd.app.name;
		_wndName = _frame.wnd.name;
		_document = ParaUI.GetUIObject(_appName.."_".._wndName.."_window_document");
	else
		local param = {
			wnd = _wnd,
			icon = "Texture/3DMapSystem/MainBarIcon/PublishWorld_1.png",
			iconSize = 48,
			text = "Load World",
			style = Map3DSystem.App.worlds.Windows.Style[1],
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
			initialPosY = 50,
			initialWidth = 530,
			initialHeight = 600,
			
			ShowUICallback = Map3DSystem.App.worlds.PublishWorldWnd.Show,
			
		};
		NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
		_appName, _wndName, _document, _frame = Map3DSystem.App.worlds.Windows.RegisterWindowFrame(param);
	end
	Map3DSystem.App.worlds.Windows.ShowWindow(true, _appName, _wndName);
end

function Map3DSystem.App.worlds.PublishWorldWnd.MSGProc(window, msg)
	if(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		Map3DSystem.App.worlds.Windows.ShowWindow(false, Map3DSystem.App.worlds.PublishWorldWnd.parentWindow.app.name, msg.wndName);
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
	end
end

-- @param bShow: show or hide the panel 
-- @param _parent: parent window inside which the content is displayed. it can be nil.
function Map3DSystem.App.worlds.PublishWorldWnd.Show(bShow,_parent,parentWindow)
	local _this;
	local left, top, width, height;

	Map3DSystem.App.worlds.PublishWorldWnd.parentWindow = parentWindow;

	_this=ParaUI.GetUIObject("Map3DSystem.App.worlds.PublishWorldWnd");
	if(_this:IsValid()) then
		if(bShow == nil) then
			bShow = not _this.visible;
		end
		_this.visible = bShow;
		if(bShow == false) then
			Map3DSystem.App.worlds.PublishWorldWnd.OnDestory();
		end
	else
		if(bShow == false) then return	end
		
		if(_parent==nil) then
			width, height = 480, 512
			_this = ParaUI.CreateUIObject("container", "Map3DSystem.App.worlds.PublishWorldWnd", "_ct", -width/2, -height/2, width, height)
			_this:AttachToRoot();
		else
			_this = ParaUI.CreateUIObject("container", "Map3DSystem.App.worlds.PublishWorldWnd", "_fi", 0,0,0,0)
			_this.background="";
			_parent:AddChild(_this);
		end
		_parent = _this;
	end
end

-- destory the control
function Map3DSystem.App.worlds.PublishWorldWnd.OnDestory()
	ParaUI.Destroy("Map3DSystem.App.worlds.PublishWorldWnd");
end

function Map3DSystem.App.worlds.PublishWorldWnd.OnClose()
	if(Map3DSystem.App.worlds.PublishWorldWnd.parentWindow~=nil) then
		-- send a message to its parent window to tell it to close. 
		Map3DSystem.App.worlds.PublishWorldWnd.parentWindow:SendMessage(Map3DSystem.App.worlds.PublishWorldWnd.parentWindow.name, CommonCtrl.os.MSGTYPE.WM_CLOSE);
	else
		ParaUI.Destroy("Map3DSystem.App.worlds.PublishWorldWnd");
	end
end
