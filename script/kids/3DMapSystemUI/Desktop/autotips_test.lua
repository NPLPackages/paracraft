--[[
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/autotips_test.lua");
CommonCtrl.Animation.autotips_test.show();
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/Animation/StoryboardRecorder.lua");
local autotips_test = {};
commonlib.setfield("CommonCtrl.Animation.autotips_test",autotips_test);
function CommonCtrl.Animation.autotips_test.show()
	NPL.load("(gl)script/kids/3DMapSystemUI/Windows.lua");
	local _app = CommonCtrl.os.CreateGetApp("autotips_test_MyAPP");
	local _wnd = _app:FindWindow("autotips_test") or _app:RegisterWindow("autotips_test", nil,nil);
	
	local _appName, _wndName, _document, _frame;
	_frame = Map3DSystem.UI.Windows.GetWindowFrame(_wnd.app.name, _wnd.name);
	if(_frame) then
		_appName = _frame.wnd.app.name;
		_wndName = _frame.wnd.name;
		_document = ParaUI.GetUIObject(_appName.."_".._wndName.."_window_document");
	else
		local param = {
			wnd = _wnd,
			--isUseUI = true,
			icon = "Texture/3DMapSystem/MainBarIcon/Modify.png",
			iconSize = 48,
			text = "测试",
			style = Map3DSystem.UI.Windows.Style[1],
			maximumSizeX = 900,
			maximumSizeY = 1000,
			minimumSizeX = 200,
			minimumSizeY = 200,
			isShowIcon = true,
			--opacity = 100, -- [0, 100]
			isShowMaximizeBox = false,
			isShowMinimizeBox = false,
			isShowAutoHideBox = false,
			allowDrag = true,
			allowResize = true,
			initialPosX = 300,
			initialPosY = 200,
			initialWidth = 600,
			initialHeight = 200,
			
			ShowUICallback =CommonCtrl.Animation.autotips_test.CreateDlg,
		};
		_appName, _wndName, _document, _frame = Map3DSystem.UI.Windows.RegisterWindowFrame(param);
	end
	Map3DSystem.UI.Windows.ShowWindow(true, _appName, _wndName);
	--_guihelper.ShowDialogBox("autotips_test", 0,200, 400, 400, CommonCtrl.Animation.autotips_test.CreateDlg, CommonCtrl.Animation.autotips_test.OnDlgResult,3);
end
function CommonCtrl.Animation.autotips_test.CreateDlg(bShow, _parent, parentWindow)
	local _this;
	CommonCtrl.Animation.autotips_test.parentWindow = parentWindow;
	_this = ParaUI.CreateUIObject("container", "autotips_test", "_fi", 0,0,0,0)	
	--_this.background = "Texture/whitedot.png;";
	_parent:AddChild(_this);
	_parent = _this;
	local left,top,width,height=10,10,100,20;	
	
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="新建";
	_this.onclick=";CommonCtrl.Animation.autotips_test.onNew();";
	_parent:AddChild(_this);
	
	left,top,width,height=left+110,top,width,height
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="AddMessageTips";
	_this.onclick=";CommonCtrl.Animation.autotips_test.AddMessageTips();";
	_parent:AddChild(_this);
	
	left,top,width,height=left+110,top,width,height
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="AddTips";
	_this.onclick=";CommonCtrl.Animation.autotips_test.AddTips();";
	_parent:AddChild(_this);
	
	left = 10
	left,top,width,height=left,top+30,width,height
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="AddTips2";
	_this.onclick=";CommonCtrl.Animation.autotips_test.AddTips2();";
	_parent:AddChild(_this);
	
	left,top,width,height=left+110,top,width,height
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="AddTips3";
	_this.onclick=";CommonCtrl.Animation.autotips_test.AddTips3();";
	_parent:AddChild(_this);
	
	left,top,width,height=left+110,top,width,height
	_this = ParaUI.CreateUIObject("button", "start", "_lt", left,top,width,height)
	_this.text="AddTips4";
	_this.onclick=";CommonCtrl.Animation.autotips_test.AddTips4();";
	_parent:AddChild(_this);
	
	CommonCtrl.Animation.autotips_test.index = 0;
end

-----------------
function CommonCtrl.Animation.autotips_test.onNew()
	--autotips.AddTips("nextaction", "nextaction", 10);
	--autotips.AddTips("nextaction", nil, 10);
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
end
function CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.index = CommonCtrl.Animation.autotips_test.index + 1;
	autotips.AddMessageTips("+++++++++++++++++++++++"..CommonCtrl.Animation.autotips_test.index)

end
function CommonCtrl.Animation.autotips_test.AddTips()
	CommonCtrl.Animation.autotips_test.index = CommonCtrl.Animation.autotips_test.index + 1;
	autotips.AddTips("nextaction", "AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
end
function CommonCtrl.Animation.autotips_test.AddTips2()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.index = CommonCtrl.Animation.autotips_test.index + 1;
	autotips.AddTips("nextaction22222", "222222AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
	--autotips.AddTips("nextaction22222", nil);
	--autotips.AddTips("nextaction22222", "222222AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
	--autotips.AddTips("nextaction22222", nil);
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
end
function CommonCtrl.Animation.autotips_test.AddTips3()
	--CommonCtrl.Animation.autotips_test.AddTips2()
	autotips.AddTips("nextaction22222", nil);
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
end
function CommonCtrl.Animation.autotips_test.AddTips4()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	--CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.index = CommonCtrl.Animation.autotips_test.index + 1;
	autotips.AddTips("nextaction22222", "222222AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
	autotips.AddTips("nextaction22222", nil);
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	autotips.AddTips("nextaction22222", "222222AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
	autotips.AddTips("nextaction22222", nil);
	CommonCtrl.Animation.autotips_test.AddMessageTips()
	--autotips.AddTips("nextaction22222", nil);
	autotips.AddTips("nextaction22222", "222222AddTipsAddTipsAddTipsAddTips"..CommonCtrl.Animation.autotips_test.index, 10);
	--autotips.AddTips("nextaction22222", nil);
end

function CommonCtrl.Animation.autotips_test.MSGProc(window, msg)
	----------------------------------------------------
	-- normal windows messages here
	----------------------------------------------------
	if(msg.type == CommonCtrl.os.MSGTYPE.WM_CLOSE) then
		--Map3DSystem.UI.Windows.ShowWindow(false,CommonCtrl.Animation.autotips_test.parentWindow.app.name, msg.wndName);
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SIZE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_HIDE) then
		
		
	elseif(msg.type == CommonCtrl.os.MSGTYPE.WM_SHOW) then
		
	end
end

