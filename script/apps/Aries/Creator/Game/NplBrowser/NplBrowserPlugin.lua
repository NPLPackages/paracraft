--[[
Title: NplBrowserPlugin
Author(s): leio, big, lixizhi
Date: 2019.3.24
Desc: webview support for all platforms. two way communications between webview and npl runtime are supported. 
Multiple webviews can be created on windows. It is recommended to use webview via pe_nplbrowser.
- win32 uses native webview2 (parawebview.dll) or if not available fall back to cef3 plugin: https://github.com/tatfook/NplBrowser
- mac, ios, android: uses native webview interface. 
- wasm(emscripten): uses native iframe, but with https cross domain restrictions. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local id = "nplbrowser_wnd";
NplBrowserPlugin.Start({id = id, url = "http://www.keepwork.com", withControl = true, x = 200, y = 200, width = 800, height = 600, });
NplBrowserPlugin.OnCreatedCallback(id,function()
    NplBrowserPlugin.Open({id = id, url = "http://www.keepwork.com", resize = true, x = 100, y = 100, width = 300, height = 300, });
    NplBrowserPlugin.Show({id = id, visible = false});
    NplBrowserPlugin.Show({id = id, visible = true});
    NplBrowserPlugin.Zoom({id = id, zoom = 1}); --200%
    NplBrowserPlugin.EnableWindow({id = id, enabled = false});
    NplBrowserPlugin.ChangePosSize({id = id, x = 100, y = 100, width = 800, height = 400, });
    NplBrowserPlugin.Quit({id = id,});
end)

GameLogic.GetFilters():add_filter("ShowTopWindow", function(nil, winId)
    if(wndId ~= "myId") then
        -- close this page. 
    end
end)

-- send message to all browsers
NplBrowserPlugin.NPL_Activate(nil, filename, {})

-- npl receiver for javascript like NPL.activate("MyNPLFileName", {cmd:"hello"})
NPL.this(function()
	local msg = NplBrowserPlugin.TranslateJsMessage(msg)
	if(msg.cmd == "hello")then
	end
end, {filename="MyNPLFileName"});
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/os/WebView.lua");
NPL.load("(gl)script/ide/Json.lua");

local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local WebView = commonlib.gettable("System.os.WebView");

local default_window_title = default_window_title;
local default_id = "nplbrowser_wnd";
local default_dll_name = "cef3/NplCefPlugin.dll";
local debug = ParaEngine.GetAppCommandLineByParam("cef_debug", false);
if(debug == true or debug =="true" or debug == "True")then
    default_dll_name = "cef3/NplCefPlugin_d.dll";
end
local default_client_name = "cef3\\cefclient.exe";
local callback_file = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua";
local cefclient_config_filename = "cefclient_config.json"; -- same value in NplCefPlugin

local DISABLE_WINDOW_WEBVIEW2 = false;
local is_windows_webview2_found = false;
local window_webview_dll_name = ParaEngine.IsDebugging() and "ParaWebView_d.dll" or "ParaWebView.dll";
local window_webview_auto_install = true;

NplBrowserPlugin.is_registered = false;
NplBrowserPlugin.cmds_queue = nil; --commands queue
NplBrowserPlugin.windows = {}; -- save existing windows
NplBrowserPlugin.window_states = {}; -- the states of window
NplBrowserPlugin.messageLoopInterval = 0.2 * 1000;
NplBrowserPlugin.webview = nil; -- webview instance
NplBrowserPlugin.on_created_callback_map = {};

function NplBrowserPlugin.IsWindowWebView2Found()
	NplBrowserPlugin.OneTimeInitWebview2()
    return is_windows_webview2_found;
end

-- create or get the commands queue
function NplBrowserPlugin.CreateOrGetCmdsQueue()
    local cmds_queue = NplBrowserPlugin.cmds_queue;

    if not cmds_queue then
        cmds_queue = commonlib.Queue:new();
        NplBrowserPlugin.cmds_queue = cmds_queue;
    end

    return cmds_queue;
end

function NplBrowserPlugin.CanRunCmd(cmd)
    if not cmd then return end

    local id = cmd.id;

    if (is_windows_webview2_found) then return true end 
	
	if (System.os.IsEmscripten()) then return true end

    if not NplBrowserPlugin.OsSupported() then
	    LOG.std(nil, "info", "NplBrowserPlugin", "npl browser isn't supported on %s", System.os.GetPlatform());
        return false;
    end

    return true;
end

-- push a command to be executed in the next loop frame move. 
function NplBrowserPlugin.PushBack(cmd)
    if not cmd then
        return false;
    end

    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();
    
	if(NplBrowserPlugin.IsSupportFullWebView()) then
		local last_cmd = NplBrowserPlugin.GetFront()
		if(last_cmd and last_cmd.cmd == cmd.cmd and last_cmd.id == cmd.id) then
			-- remove duplicated command
			local bRemoveDuplicated;
			if(cmd.cmd == "ChangePosSize") then
				bRemoveDuplicated = true;
			elseif(cmd.cmd == "Show" and last_cmd.visible == cmd.visible ) then
				bRemoveDuplicated = true;
			elseif(cmd.cmd == "Open" and last_cmd.url == cmd.url ) then
				bRemoveDuplicated = true;
			end

			if(bRemoveDuplicated) then
				-- LOG.std(nil, "debug", "NplBrowserPlugin.RemoveDuplicated", "cmd:%s %s", cmd.cmd, cmd.id);
				NplBrowserPlugin.PopFront()
			end
		end
	end
    cmds_queue:pushright(cmd);

	LOG.std(nil, "info", "NplBrowserPlugin.PushBack", "cmd:%s %s", cmd.cmd, cmd.id);
end

-- pop a command from the first
function NplBrowserPlugin.PopFront()
    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();
    return cmds_queue:popleft();
end

function NplBrowserPlugin.GetFront()
    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();
    return cmds_queue:front();
end

function NplBrowserPlugin.IsEmpty()
    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();
    return cmds_queue:empty();
end

function NplBrowserPlugin.RunNextCmd()
    if NplBrowserPlugin.IsEmpty() then
        return false;
    end

    local cmd = NplBrowserPlugin.GetFront();
    cmd = cmd or {};
    
    if NplBrowserPlugin.CanRunCmd(cmd) then
        cmd = NplBrowserPlugin.PopFront();

	    LOG.std(nil, "debug", "NplBrowserPlugin.RunNextCmd", "[%s] ======= %s ==============", cmd.id, cmd.cmd);
        LOG.std(nil, "debug", "NplBrowserPlugin.RunNextCmd", cmd);

        if (System.os.GetPlatform() == 'win32') then
			local state = NplBrowserPlugin.GetWindowState(cmd.id)
			if state and (NplBrowserPlugin.IsWindowCreated(cmd.id) or cmd.cmd == "Start")then
                if(cmd.cmd == "Start" and NplBrowserPlugin.IsCef3WebView() and state.state ~= "WindowCreated") then
                    -- for cef3 we will use callback to check for window creation. 
                    state.state = "OpenningWindow"
                end
				local dll_name = cmd.dll_name or default_dll_name;
				NPL.activate(dll_name, cmd);
			end
        elseif (System.os.IsEmscripten()) then
            local uiScales = System.Windows.Screen:GetUIScaling();
            cmd.scale_x = uiScales[1];
            cmd.scale_y = uiScales[2];
            cmd.from_filename = callback_file;
            cmd.to_filename = "";
            cmd.target = "webview";
            ParaEngine.GetAttributeObject():SetField("SendMsgToJS", commonlib.Json.Encode(cmd));
        elseif (System.os.GetPlatform() == 'mac' or
                System.os.GetPlatform() == 'ios' or
                System.os.GetPlatform() == 'android') then
            local x, y = cmd.x, cmd.y;
            local width, height = cmd.width, cmd.height;

            if (x) then
                x = math.floor(x / System.options.default_ui_scaling[1]);
            end

            if (y) then
                y = math.floor(y / System.options.default_ui_scaling[2]);
            end

            if (width) then
                width = math.floor(width / System.options.default_ui_scaling[1]);
            end

            if (height) then
                height = math.floor(height / System.options.default_ui_scaling[2]);
            end

            local state = NplBrowserPlugin.GetWindowState(cmd.id);
            local isLoadWebview;
            local webview;

            if (System.os.CompareParaEngineVersion('1.4.1.0')) then
                -- runtime 1.4.1.0 and above use multiple webviews.
                local state = NplBrowserPlugin.GetWindowState(cmd.id);

                isLoadWebview = state.isLoadWebview;
                webview = state.webview;
            else
                isLoadWebview = NplBrowserPlugin.isLoadWebview;
                webview = NplBrowserPlugin.webview;
            end

            if (cmd.cmd == "Start") then
                if (System.os.CompareParaEngineVersion('1.4.1.0')) then
                    if (not webview) then
                        state.webview = WebView:new():init(0, 0, 0, 0, true);
                        state.isLoadWebview = true;
                    end

                    webview = state.webview;
                    isLoadWebview = state.isLoadWebview;
                else
                    if (not NplBrowserPlugin.isLoadWebview) then
                        NplBrowserPlugin.webview = WebView:new():init(0, 0, 0, 0, true);
                        -- NplBrowserPlugin.webview:IgnoreCloseWhenClickBack(true)
                        NplBrowserPlugin.isLoadWebview = true
                    end

                    webview = NplBrowserPlugin.webview;
                    isLoadWebview = state.isLoadWebview;
                end

                webview:resize(0, 0);
                webview:move(0, 0);

                webview:loadUrl(cmd.url);
                webview._url = cmd.url;
                webview:setVisible(true);
           elseif (cmd.cmd == 'Show') then
                if (isLoadWebview) then
                    if (cmd.visible) then
                        if (width and height) then
                            webview:resize(width, height);
                        end
    
                        if (x and y) then
                            webview:move(x, y);
                        end
    
                        if (cmd and cmd.url) then
                            webview:loadUrl(cmd.url);
                        end
    
                        webview:setVisible(cmd.visible);
                    else
                        webview:setVisible(cmd.visible);
    
                        if (System.os.GetPlatform() == "ios") then
                            -- Temporaily fixed not sound on iOS.
                            NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
                            local AudioEngine = commonlib.gettable("AudioEngine");
        
                            AudioEngine.ResetAudioDevice();
                        end
                    end
                end
            elseif (cmd.cmd == "ChangePosSize") then
                if (isLoadWebview) then
                    webview:resize(width, height);
                    webview:move(x, y);
                    webview:bringToTop();
                end
            elseif (cmd.cmd == "Open") then
                if (isLoadWebview) then
                    webview:setVisible(cmd.visible);
    
                    webview:resize(width, height);
                    webview:move(x, y);
    
                    webview:loadUrl(cmd.url);
                end
            end
        end

        NplBrowserPlugin.UpdateWindowState(cmd.id, cmd);
        if(cmd.cmd == "Start" or (cmd.cmd == "Show" and cmd.visible)) then
            NplBrowserPlugin.ApplyFilters_WebviewShowWindow(cmd.id)
        end
    else
	    NplBrowserPlugin.PopFront();
    end
end

function NplBrowserPlugin.RunMessageloopTimer()    
	NplBrowserPlugin.OneTimeInitWebview2()
    NplBrowserPlugin.timer = NplBrowserPlugin.timer or commonlib.Timer:new({callbackFunc = function(timer)
        if(NplBrowserPlugin.IsCef3WebView()) then
		    for id, state in pairs(NplBrowserPlugin.window_states) do
			    if(state.visible~=false and state.state == "OpenningWindow") then
				    NplBrowserPlugin.CheckCefWindowCreated(state)
			    end
		    end
        end
		while(not NplBrowserPlugin.IsEmpty()) do
			NplBrowserPlugin.RunNextCmd();
		end
    end})
	NplBrowserPlugin.timer:Change(0, NplBrowserPlugin.messageLoopInterval)
end

function NplBrowserPlugin.ApplyFilters_WebviewShowWindow(windowId)
    if(GameLogic and GameLogic.GetFilters) then
        GameLogic.GetFilters():apply_filters("WebviewShowWindow", nil, windowId)
		GameLogic.GetFilters():apply_filters("ShowTopWindow", nil, windowId, "webview")
    end
end

-- TODO: mobile version shall also support full webview
-- @return true if the NPLRuntime can support bi-directional communication. 
function NplBrowserPlugin.IsSupportFullWebView()
	if(NplBrowserPlugin.isSupportFullWebView_ == nil) then
		NplBrowserPlugin.isSupportFullWebView_ = System.os.GetPlatform() == 'win32' or 
            System.os.IsEmscripten() or WebView:IsSupportFullWebview();

        if(NplBrowserPlugin.isSupportFullWebView_) then
            NplBrowserPlugin.isSupportFullWebView_ = true;
        else
            NplBrowserPlugin.isSupportFullWebView_ = false;
        end
	end
	return NplBrowserPlugin.isSupportFullWebView_
end

-- check if exist a window
function NplBrowserPlugin.IsWindowCreated(id)
    local states = NplBrowserPlugin.GetWindowState(id)
	return states and states.state == "WindowCreated"
end

-- actual window state and window state in memory are synchronized in both ways. 
-- @param id: window id
-- @param input: key, value pairs of data to add.  {url, state, x, y, width, height, visible, ...}
function NplBrowserPlugin.UpdateWindowState(id, input)
    if id then
        local result = NplBrowserPlugin.window_states[id] or {};

        for k,v in pairs(input) do
            result[k] = v;
        end

        NplBrowserPlugin.window_states[id] = result;
    end
end

-- actual window state and window state in memory are synchronized in both ways. 
-- @return current cached window state: {url, state, x, y, width, height, visible, ...}
function NplBrowserPlugin.GetWindowState(id)
    if(id)then
        return NplBrowserPlugin.window_states[id] or {};
    end
end

-- sync cached window states from meomory to webview, such as position, size and visibility. This is usually called after window is created. 
-- @param id: window id.
function NplBrowserPlugin.SynchronizeWindowState(id)
	local param = NplBrowserPlugin.GetWindowState(id)
	if(param) then
		NplBrowserPlugin.ChangePosSize(param)
		if(param.visible == false) then
			NplBrowserPlugin.Show(param);
		end
	end
end

-- return parent Handle HWND as a string
function NplBrowserPlugin.GetParentHandleAsString()
	local parent_handle = NplBrowserPlugin.sParentHwnd
	if(not parent_handle) then
		parent_handle = ParaEngine.GetAttributeObject():GetField("AppHWND", 0);
		parent_handle = tostring(parent_handle);
		NplBrowserPlugin.sParentHwnd = parent_handle;
	end
    return parent_handle;
end

-- send a NPL.activate to webview. 
-- @param browserId: the id of the browser window. if nil, it will send to all activate windows.
-- @param filename: the file to be activate in js.
-- @param params: the params message to be passed to the js file.
function NplBrowserPlugin.NPL_Activate(browserId, filename, params)
    if(not browserId) then
        for id, _ in pairs(NplBrowserPlugin.window_states) do
            NplBrowserPlugin.NPL_Activate(id, filename, params)
        end
        return
    end
    local state = NplBrowserPlugin.GetWindowState(browserId);
    local message = {};
    message.file = filename or "";
    message.params = commonlib.Json.Encode(params)

    if System.os.GetPlatform() == 'win32' then
		local state = NplBrowserPlugin.GetWindowState(browserId)
		if (state and NplBrowserPlugin.IsWindowCreated(browserId))then
			local message_content = commonlib.Json.Encode(message)
			local input = {
				id = browserId, 
				parent_handle = NplBrowserPlugin.GetParentHandleAsString(), 
				cmd = "CallJsFunc", 
				callback_file = "",
				message_content = message_content,
			}
			local dll_name = default_dll_name;
			NPL.activate(dll_name, input);
		end
    elseif (System.os.GetPlatform() == "mac" ) then
        local filepath = message.file;
        local msg = message.params;
        if NplBrowserPlugin.isLoadWebview then
            NplBrowserPlugin.webview:activate(filepath, msg);
        end
    elseif (System.os.IsEmscripten()) then
        ParaEngine.GetAttributeObject():SetField("SendMsgToJS", commonlib.Json.Encode({
            target = "webview",
            from_filename = "script/apps/Aries/Creator/Game/PapaAdventures/PapaAPI.lua",
            to_filename = message.file,
            params = message.params,
        }));
    end
end

-- send a msg to webview
-- @param p: {id,...}
-- @param params: {jsFile, ...} 
function NplBrowserPlugin.SendMessage(p, params)
    NplBrowserPlugin.NPL_Activate(p and p.id, params.jsFile or "", params)
end

-- create a webview window
function NplBrowserPlugin.Start(p)
	NplBrowserPlugin.OneTimeInitWebview2()

    if (System.os.GetPlatform() == 'win32') then
		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
        NplBrowserLoaderPage.Check(function()
            -- TODO: refresh page after downloaded cef3
        end)
        if (not NplBrowserLoaderPage.IsLoaded()) then
            return false
        end
    end

    local window_title = p.window_title or default_window_title;
    local id = p.id or default_id;

    if (not NplBrowserPlugin.OsSupported()) then
	    LOG.std(nil, "info", "NplBrowserPlugin.Start", "npl browser isn't supported on %s", System.os.GetPlatform());
        return false;
    end

    if (System.os.GetPlatform() == 'win32' and not NplBrowserPlugin.CheckCefClientExist()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
		NplBrowserLoaderPage.SetChecked(false);

		--only install chrome cef3 and webview2 is valid
        NplBrowserLoaderPage.CheckCef3(function(loaded)
            if(loaded) then
                NplBrowserPlugin.Start(p)
            end
        end, true)
		-- _guihelper.MessageBox(L"NPL Chrome浏览器插件丢失，是否重新安装?", function(res)
		-- 	if(res and res == _guihelper.DialogResult.Yes) then
		-- 		local bForceReinstall = true
				
		-- 		NplBrowserLoaderPage.Check(function(loaded)
		-- 			if(loaded) then
		-- 				NplBrowserPlugin.Start(p)
		-- 			end
		-- 		end, bForceReinstall)
		-- 	end
		-- end, _guihelper.MessageBoxButtons.YesNo);
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the client [%s] does not exist, cannot start npl browser", default_client_name);
        return false;
    end

    local client_name = p.client_name or default_client_name;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    parent_handle = tostring(parent_handle);
    local tag_hide_controls;

    if (p.withControl) then
        tag_hide_controls = "";
    else
        tag_hide_controls = "-hide-controls";
    end

    local pid = tostring(System.os.GetCurrentProcessId());

    local x = p.x or 0;
    local y = p.y or 0;
    local width = p.width or 100;
    local height = p.height or 100;
    local url = p.url or "";
    local bounds = string.format("%d,%d,%d,%d,",x,y,width,height);
    local zoom = p.zoom or 0.0;
    local cmdline = string.format(
        [[
            -window_title="%s" 
            -window_name="%s" 
            %s
            -hide-top-menu 
            -url="%s" 
            -bounds="%s"
            -parent_handle="%s"
            -cefclient_config_filename="%s"
            -pid="%s"
            -autoplay-policy=no-user-gesture-required
        ]],
        window_title,
        id,
        tag_hide_controls,
        url,
        bounds,
        parent_handle,
        cefclient_config_filename,
        pid
    );

    local input = {
        cmd = "Start", 
        id = id, 
        parent_handle = parent_handle, 
        cmdline = cmdline, 
        client_name = client_name, 
        url = url,
        x = x,
        y = y,
        width = width,
        height = height,
        callback_file = callback_file,
        cefclient_config_filename = cefclient_config_filename,
        pid = pid,
        debug = System.options.isPapaAdventure
    };

    LOG.std(nil, "info", "NplBrowserPlugin.Start", "the window [%s] requests to launch %s", id, url or "");

	if(not NplBrowserPlugin.IsCef3WebView()) then
		-- assume window is immediately created except for cef3, which we need to check periodically. 
		NplBrowserPlugin.UpdateWindowState(id, {state="WindowCreated"});
	end

    NplBrowserPlugin.UpdateWindowState(id, input);
	NplBrowserPlugin.PushBack(input);
	
    NplBrowserPlugin.RunMessageloopTimer();
end

-- push a command of Open
function NplBrowserPlugin.Open(p)
    local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = {
        cmd = "Open", 
        id = id, 
        parent_handle = parent_handle, 
        url = p.url,
        resize = p.resize,
        x = p.x,
        y = p.y,
        width = p.width,
        height = p.height,
        zoom = p.zoom,
        visible = p.visible,
        callback_file = callback_file,
    }
	NplBrowserPlugin.UpdateWindowState(id, input);
    NplBrowserPlugin.PushBack(input);
end

-- push ChangePosSize command or NPL.activate dll directly
function NplBrowserPlugin.ChangePosSize(p)
    local id = p.id or default_id;
    local dll_name = p.dll_name or default_dll_name;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = {
        cmd = "ChangePosSize", 
        id = id, 
        parent_handle = parent_handle, 
        x = p.x,
        y = p.y,
        width = p.width,
        height = p.height,
        callback_file = callback_file,
    }

	NplBrowserPlugin.UpdateWindowState(id, input);
    NplBrowserPlugin.PushBack(input);
end


-- push a command of Show
function NplBrowserPlugin.Show(p)
	local id = p.id or default_id;
	local param = NplBrowserPlugin.GetWindowState(id)
	if(not param) then 
		return 
	end
	
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = {
        cmd = "Show", 
        id = id, 
        parent_handle = parent_handle, 
        zoom = p.zoom,
        visible = p.visible,
		x = p.x or param.x,
        y = p.y or param.y,
		url = param.url,
        width = p.width or param.width,
        height = p.height or param.height,
        callback_file = callback_file,
    }
	NplBrowserPlugin.UpdateWindowState(id, input);
    NplBrowserPlugin.PushBack(input);
end

-- push a command of Zoom
-- p.zoom = 0 scale: 1
-- p.zoom = 1 scale: 1 * (1+1)
-- p.zoom = -1 scale: 1 / (1+1)
function NplBrowserPlugin.Zoom(p)
	local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = { 
        cmd = "Zoom", 
        id = id, 
        parent_handle = parent_handle, 
        zoom = p.zoom,
        callback_file = callback_file,
    }
    NplBrowserPlugin.PushBack(input);
end

-- push a command of EnableWindow
function NplBrowserPlugin.EnableWindow(p)
	local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = { 
        cmd = "EnableWindow", 
        id = id, 
        parent_handle = parent_handle, 
        enabled = p.enabled,
        callback_file = callback_file,
    }
    NplBrowserPlugin.PushBack(input);
end

-- push a command of Quit
function NplBrowserPlugin.Quit(p)
	local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
    local input = { 
        cmd = "Quit", 
        id = id, 
        parent_handle = parent_handle, 
        callback_file = callback_file,
    }; 
    NplBrowserPlugin.PushBack(input);
end

function NplBrowserPlugin.IsCef3WebView()
    return System.os.GetPlatform() == 'win32' and not is_windows_webview2_found;
end

-- NPL.activate to dll directly
function NplBrowserPlugin.CheckCefWindowCreated(p)
    if (NplBrowserPlugin.IsCef3WebView()) then 
        local id = p.id or default_id;
        local dll_name =  p.dll_name or default_dll_name;
        local client_name =  p.client_name or default_client_name;
        local parent_handle = NplBrowserPlugin.GetParentHandleAsString();
        local input = {
            cmd = "CheckCefWindow", 
            id = id, 
            parent_handle = parent_handle, 
            callback_file = callback_file,
            client_name = client_name,
            cefclient_config_filename = cefclient_config_filename,
            cmdline = "-autoplay-policy=no-user-gesture-required",
            pid = tostring(System.os.GetCurrentProcessId()),
        }
        NPL.activate(dll_name, input); 
    end
end

function NplBrowserPlugin.CheckCefClientExist()
    return ParaIO.DoesFileExist(default_client_name);
end

function NplBrowserPlugin.OsSupported()
    if NplBrowserPlugin.isSupported == nil then
        if (is_windows_webview2_found) then
            NplBrowserPlugin.isSupported = true;
        elseif System.os.GetPlatform() == 'win32' and not System.os.Is64BitsSystem() then
            NplBrowserPlugin.isSupported = true;

            -- disable for windows XP
            if(NplBrowserPlugin.isSupported) then
                if(System.os.IsWindowsXP()) then
                    NplBrowserPlugin.isSupported = false;
                end
            end
        elseif System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'ios' or System.os.GetPlatform() == 'android' or System.os.IsEmscripten() then
            NplBrowserPlugin.isSupported = true;
        else
            NplBrowserPlugin.isSupported = false;
        end
    end

    return NplBrowserPlugin.isSupported;
end

function NplBrowserPlugin.OnCreatedCallback(id, callback)
    if not id then
        return
    end

    NplBrowserPlugin.on_created_callback_map[id] = callback;
end

function NplBrowserPlugin.ReadCefClientJsonConfg(filename)
    local file = ParaIO.open(filename,"r");

    if(file:IsValid())then
        local content = file:GetText();
		file:close();

        local out={};
        if(NPL.FromJson(content, out)) then
            local pid = tostring(System.os.GetCurrentProcessId());
            pid = tostring(pid);
            return out[pid];
        end
    else
	    LOG.std(nil, "info", "NplBrowserPlugin", "can't open cefclient config:%s",filename);
    end
end

function NplBrowserPlugin.CloseAllBrowsers()
    if (not NplBrowserPlugin.window_states or type(NplBrowserPlugin.window_states) ~= 'table') then
        return false;
    end

    for key, config in pairs(NplBrowserPlugin.window_states) do
        if (key ~= 'NplBrowserFrame_browser_instance_TeachingQuest_BrowserPage') then
            config.visible = false;
            NplBrowserPlugin.Show(config);
        end
    end
end

-- silently download and install webview2
function NplBrowserPlugin.InstallWin32Webview2()
	if (System.os.GetPlatform() == 'win32') then
		NPL.activate(window_webview_dll_name, {
				cmd = "Support",
				callback_file = callback_file,
				auto_install = true,
				parent_handle = NplBrowserPlugin.GetParentHandleAsString()
			});
	end
end

function NplBrowserPlugin.UpdateWebview2(callback,bAutoInstall)
    if (System.os.GetPlatform() == 'win32') then
        if not ParaIO.DoesFileExist(window_webview_dll_name) then
            is_windows_webview2_found = false
            if callback then
                callback()
            end
            return
        end
        NPL.activate(window_webview_dll_name, {
            cmd = "Support",
            callback_file = callback_file,
            auto_install = bAutoInstall or false,
            parent_handle = NplBrowserPlugin.GetParentHandleAsString()
        });
    end
end

function NplBrowserPlugin.OnReceiveWebView2Support(msg)
    if not msg then
        return
    end
    local cmd = msg["cmd"];
    if (cmd == "Support") then
		if (DISABLE_WINDOW_WEBVIEW2) then
			msg["ok"] = false;
		end
        is_windows_webview2_found = msg["ok"];
        if (is_windows_webview2_found) then
            default_dll_name = window_webview_dll_name;
        end
		if(is_windows_webview2_found) then
			echo("========= webview2 is found ==========")
		else
			echo("========= webview2 NOT installed ==========")
		end

		if(NplBrowserPlugin.WebviewInitCallback) then
			NplBrowserPlugin.WebviewInitCallback(msg);
			NplBrowserPlugin.WebviewInitCallback = nil;
		end
    end
end

-- call this at start up to try init (detect) webview2 (parawebview.dll)
-- it does not init cef3 only check for local installation of webview2 in the OS. 
-- @return true if support webview2
function NplBrowserPlugin.OneTimeInitWebview2()
	if (not NplBrowserPlugin.hasCheckedWebview2)  then
		NplBrowserPlugin.hasCheckedWebview2 = true
		if(System.os.GetPlatform() == 'win32') then
			local isFileExist = ParaIO.DoesFileExist(window_webview_dll_name)
			if not isFileExist then
				is_windows_webview2_found = false
				if callback then
					callback()
				end
			else
				NplBrowserPlugin.WebviewInitCallback = callback;
				NPL.call(window_webview_dll_name, {
					cmd = "Support",
					callback_file = callback_file,
					auto_install = false,
					parent_handle = NplBrowserPlugin.GetParentHandleAsString()
				});
			end
		end
    end
	return is_windows_webview2_found;
end

local function activate()
	local msg = msg;
    if msg then
        local cmd = msg["cmd"];
        local id = msg["id"] or "";
        local parent_handle = msg["parent_handle"] or "";
		
        if(cmd == "Support")then
			-- from parawebview.dll
			NplBrowserPlugin.OnReceiveWebView2Support(msg)
		elseif(cmd == "CheckCefWindow")then
			-- callback message for each "Start" for cef3.dll
            local json_config = NplBrowserPlugin.ReadCefClientJsonConfg(cefclient_config_filename);

            if json_config then
                local key = string.format("%s_%s",id,parent_handle);
                local value = json_config[key];

                if value == true then
					NplBrowserPlugin.UpdateWindowState(id, {state="WindowCreated"});
                    LOG.std(nil, "info", "NplBrowserPlugin", "============= webview window created: %s ================", id);
                    -- send a message after created window
                    local callback = NplBrowserPlugin.on_created_callback_map[id];
                    if(callback)then
                        callback(msg);
                    end
                    NplBrowserPlugin.on_created_callback_map[id] = nil;

					NplBrowserPlugin.SynchronizeWindowState(id)
                end
            end
        elseif(cmd == "WebViewStarted")then
            -- callback message for each "Start" for parawebview.dll
            local ok = msg["ok"];
			local id = msg["id"];
			if not ok then
				LOG.std(nil, "error", "NplBrowserPlugin", "failed to create webview2 window when we report to support webview2");
				local NplBrowserDialog = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserDialog.lua");
                NplBrowserDialog.ShowPage()
            else
				if(id) then
					NplBrowserPlugin.UpdateWindowState(id, {state="WindowCreated"});
					LOG.std(nil, "info", "NplBrowserPlugin", "============= webview window created: %s ================", id);
					NplBrowserPlugin.SynchronizeWindowState(id)
                end
            end
		elseif(cmd == "Quit")then
            -- clear window
            NplBrowserPlugin.UpdateWindowState(id, {state="Quit"});
        end
    end
end

NPL.this(activate);

-- public: convert from NPL activation message received from webview. 
-- @return the same msg as from the javascript's NPL.activate function. 
function NplBrowserPlugin.TranslateJsMessage(msg)
	msg = msg or {};
    local message = msg.msg
    if type(message) == "string" and message ~= "" then
        local message_data = commonlib.Json.Decode(message)
		if (System.os.GetPlatform() == "mac") then
            message_data = { msg = message_data }
        end
        if message_data and message_data.msg then
            msg = message_data.msg
		end
	end
	return msg;
end

-- receiver for javascript:
-- NPL.activate("NplBrowserPlugin", {cmd:"log", "hello"})
NPL.this(function()
	local msg = NplBrowserPlugin.TranslateJsMessage(msg)
	if(msg.cmd == "log")then
		LOG.std(nil, "info", "NplBrowserPlugin.log", msg);
	end
end, {filename="NplBrowserPlugin"});


