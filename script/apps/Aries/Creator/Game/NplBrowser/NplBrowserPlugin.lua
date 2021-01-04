--[[
Title: NplBrowserPlugin
Author(s): leio, big
Date: 2019.3.24
Desc: 
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

-- the source of plugin is here:
https://github.com/tatfook/NplBrowser
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/os/WebView.lua");

local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local WebView = commonlib.gettable("System.os.WebView");

local default_window_title = default_window_title;
local default_id = "nplbrowser_wnd";
local default_dll_name = "cef3/NplCefPlugin.dll";
local debug = ParaEngine.GetAppCommandLineByParam("debug", false);
if(debug == true or debug =="true" or debug == "True")then
    default_dll_name = "cef3/NplCefPlugin_d.dll";
end
local default_client_name = "cef3\\cefclient.exe";
local callback_file = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua";
local cefclient_config_filename = "cefclient_config.json"; -- same value in NplCefPlugin

NplBrowserPlugin.is_registered = false;
NplBrowserPlugin.cmds_queue = nil; --commands queue
NplBrowserPlugin.cef_connection_pending_windows = {};  -- the array list to save the pending state of each new cef window
NplBrowserPlugin.windows = {}; -- save existing windows
NplBrowserPlugin.windows_caches = {}; -- the configs of window
NplBrowserPlugin.interval = 0.2 * 1000;
NplBrowserPlugin.webview = nil; -- webview instance

NplBrowserPlugin.on_created_callback_map = {};

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

    if not NplBrowserPlugin.OsSupported() then
	    LOG.std(nil, "info", "NplBrowserPlugin", "npl browser isn't supported on %s", System.os.GetPlatform());
        return false;
    end

    if System.os.GetPlatform() == 'win32' and not NplBrowserPlugin.CheckCefClientExist() then
		LOG.std(nil, "warn", "NplBrowserPlugin", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return false;
    end

    if not NplBrowserPlugin.WindowIsExisted(id) then
		LOG.std(nil, "warn", "NplBrowserPlugin", "the window [%s] isn't existed, cmd name:%s", id, cmd.cmd or "");
        return false;
    end

    return true;
end

-- push a command at last
function NplBrowserPlugin.PushBack(cmd)
    if not cmd then
        return false;
    end

    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();

    LOG.std(nil, "info", "NplBrowserPlugin.PushBack", "cmd:%s %s", cmd.cmd, cmd.id);
    cmds_queue:pushright(cmd);
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

    LOG.std(nil, "info", "NplBrowserPlugin.RunNextCmd", "before running:%s %s", cmd.cmd, cmd.id);

    if NplBrowserPlugin.CanRunCmd(cmd) then
        cmd = NplBrowserPlugin.PopFront();

	    LOG.std(nil, "info", "NplBrowserPlugin.RunNextCmd", "running:%s %s", cmd.cmd,cmd.id);
        LOG.std(nil, "info", "NplBrowserPlugin.RunNextCmd activate", cmd);

        if System.os.GetPlatform() == 'win32' then
            local dll_name = cmd.dll_name or default_dll_name;
            NPL.activate(dll_name, cmd); 
        end

        if System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'ios' then
            if cmd.cmd == 'Show' then
                local p = NplBrowserPlugin.GetCache(cmd.id)

                if cmd.visible then
                    if not p.isLoadWebview then
                        local x
                        local y
                        local width
                        local height

                        if System.os.GetPlatform() == 'ios' then
                            local uiScales = System.Windows.Screen:GetUIScaling();

                            if(uiScales[1] ~= 1 or uiScales[2] ~= 1) then
                                x = math.floor((p.x - 55) / uiScales[1]);
                                y = math.floor(p.y / uiScales[2]);
                                width = math.floor((p.width - 55) / uiScales[1]);
                                height = math.floor(p.height / uiScales[2]);
                            end
                        else
                            x = p.x
                            y = p.y
                            width = p.width
                            height = p.height
                        end
                        NplBrowserPlugin.webview = WebView:new():init(x, y, width, height, true);

                        NplBrowserPlugin.webview:loadUrl(p.url);
                        p.isLoadWebview = true
                    else
                        NplBrowserPlugin.webview:move(p.x, p.y);
                        NplBrowserPlugin.webview:resize(p.width, p.height);
                    end
                else
                    NplBrowserPlugin.webview:setVisible(cmd.visible);
                    NplBrowserPlugin.webview:loadUrl("");
                    p.isLoadWebview = false
                end
            end

            if cmd.cmd == 'ChangePosSize' then
                local p = NplBrowserPlugin.GetCache(cmd.id)
                NplBrowserPlugin.webview:move(p.x, p.y);
                NplBrowserPlugin.webview:resize(p.width, p.height);
            end

            if cmd.cmd == 'Zoom' then
                -- //TODO
            end

            if cmd.cmd == 'Open' then
                -- // TODO
            end
        end

        NplBrowserPlugin.UpdateCache(id, cmd)
    else
	    LOG.std(nil, "info", "NplBrowserPlugin.RunNextCmd", "found an invalid cmd:%s %s", cmd.cmd,cmd.id);
        NplBrowserPlugin.PopFront();
    end
end

function NplBrowserPlugin.PushPendingWindow(id)
    if not id then
        return false;
    end

    NplBrowserPlugin.cef_connection_pending_windows[id] = true;
end

function NplBrowserPlugin.IsPendingWindow(id)
    if not id then
        return false;
    end

    return NplBrowserPlugin.cef_connection_pending_windows[id];
end

function NplBrowserPlugin.ClearPendingWindow(id)
    if not id then
        return false;
    end

    NplBrowserPlugin.cef_connection_pending_windows[id] = nil;
end

function NplBrowserPlugin.RunRefreshTimer()
    local timer = NplBrowserPlugin.timer;

    if not timer then
        timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    local id, __;
                    for id, __ in pairs(NplBrowserPlugin.cef_connection_pending_windows) do
                        if NplBrowserPlugin.IsPendingWindow(id) then
                            NplBrowserPlugin.CheckCefWindow({id = id})
                        end
                    end

                    NplBrowserPlugin.RunNextCmd();                  
                end
            }
        )

        timer:Change(0, NplBrowserPlugin.interval)

        NplBrowserPlugin.timer = timer;
    end
end

-- check if exist a window
function NplBrowserPlugin.WindowIsExisted(id)
    if not id then
        return nil;
    end

    return NplBrowserPlugin.windows[id];
end

function NplBrowserPlugin.SetWindowExisted(id,v)
    NplBrowserPlugin.windows[id] = v;
end

function NplBrowserPlugin.UpdateCache(id, input)
    if id then
        local result = NplBrowserPlugin.windows_caches[id] or {};

        for k,v in pairs(input) do
            result[k] = v;
        end

        NplBrowserPlugin.windows_caches[id] = result;
    end
end

function NplBrowserPlugin.GetCache(id)
    if(id)then
        return NplBrowserPlugin.windows_caches[id] or {};
    end
end

-- reutrn a string
function NplBrowserPlugin.GetParentHandle()
    local parent_handle = ParaEngine.GetAttributeObject():GetField("AppHWND", 0);
    parent_handle = tostring(parent_handle);
    return parent_handle;
end

-- create a cef window
function NplBrowserPlugin.Start(p)
    if System.os.GetPlatform() == 'win32' then
		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
        NplBrowserLoaderPage.Check(function()
            -- TODO: refresh page after download cef3
        end)
    
        if not NplBrowserLoaderPage.IsLoaded() then
            return false
        end
    end

    local window_title = p.window_title or default_window_title;
    local id = p.id or default_id;

    if not NplBrowserPlugin.OsSupported() then
	    LOG.std(nil, "info", "NplBrowserPlugin.Start", "npl browser isn't supported on %s", System.os.GetPlatform());
        return false;
    end

    if System.os.GetPlatform() == 'win32' and not NplBrowserPlugin.CheckCefClientExist() then
		NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
		local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
		NplBrowserLoaderPage.SetChecked(false);
		-- we will reinstall chrome cef3
		_guihelper.MessageBox(L"NPL Chrome浏览器插件丢失，是否重新安装?", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				local bForceReinstall = true
				
				NplBrowserLoaderPage.Check(function(loaded)
					if(loaded) then
						NplBrowserPlugin.Start(p)
					end
				end, bForceReinstall)
			end
		end, _guihelper.MessageBoxButtons.YesNo);
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return false;
    end

    if(NplBrowserPlugin.WindowIsExisted(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the window [%s] is existed", id);
        return false;
    end

    if(NplBrowserPlugin.IsPendingWindow(id))then
        LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the window [%s] is pending for launch", id);
        return false;
    end

    NplBrowserPlugin.RunRefreshTimer();

    local client_name = p.client_name or default_client_name;
    local parent_handle = NplBrowserPlugin.GetParentHandle();
    parent_handle = tostring(parent_handle);
    local tag_hide_controls;

    if p.withControl then
        tag_hide_controls = ""
    else
        tag_hide_controls = "-hide-controls"
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
    };

    -- waiting for create
    LOG.std(nil, "info", "NplBrowserPlugin.Start", "the window [%s] requests to launch", id);
    NplBrowserPlugin.PushPendingWindow(id);

    if System.os.GetPlatform() == 'win32' then
        local dll_name = p.dll_name or default_dll_name;
        NPL.activate(dll_name, input);
    end

    if System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'ios' then
        NplBrowserPlugin.ClearPendingWindow(id);
        NplBrowserPlugin.SetWindowExisted(id, true);
    end

    NplBrowserPlugin.UpdateCache(id, input)
end

-- push a command of Open
function NplBrowserPlugin.Open(p)
    local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandle();
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
    NplBrowserPlugin.PushBack(input);
end

-- push ChangePosSize command or NPL.activate dll directly
function NplBrowserPlugin.ChangePosSize(p, bActivedMode)
    local id = p.id or default_id;
    local dll_name = p.dll_name or default_dll_name;
    local parent_handle = NplBrowserPlugin.GetParentHandle();
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

    if bActivedMode then
        if System.os.GetPlatform() == 'win32' then
            NPL.activate(dll_name, input);
        end

        if System.os.GetPlatform() == 'mac' then
            if not NplBrowserPlugin.webview then
                return false;
            end

            NplBrowserPlugin.webview:move(input.x, input.y);
            NplBrowserPlugin.webview:resize(input.width, input.height);
        end

        NplBrowserPlugin.UpdateCache(id, input)
    else
        NplBrowserPlugin.PushBack(input);
    end
end

-- push a command of Show
function NplBrowserPlugin.Show(p)
	local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandle();
    local input = {
        cmd = "Show", 
        id = id, 
        parent_handle = parent_handle, 
        zoom = p.zoom,
        visible = p.visible,
        callback_file = callback_file,
    }
    NplBrowserPlugin.PushBack(input);
end

-- push a command of Zoom
-- p.zoom = 0 scale: 1
-- p.zoom = 1 scale: 1 * (1+1)
-- p.zoom = -1 scale: 1 / (1+1)
function NplBrowserPlugin.Zoom(p)
	local id = p.id or default_id;
    local parent_handle = NplBrowserPlugin.GetParentHandle();
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
    local parent_handle = NplBrowserPlugin.GetParentHandle();
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
    local parent_handle = NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "Quit", 
        id = id, 
        parent_handle = parent_handle, 
        callback_file = callback_file,
    }; 
    NplBrowserPlugin.PushBack(input);
end

-- NPL.activate to dll directly
function NplBrowserPlugin.CheckCefWindow(p)
    local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    local client_name =  p.client_name or default_client_name;

    local parent_handle = NplBrowserPlugin.GetParentHandle();
    local input = {
        cmd = "CheckCefWindow", 
        id = id, 
        parent_handle = parent_handle, 
        callback_file = callback_file,
        client_name = client_name,
        cefclient_config_filename = cefclient_config_filename,
        pid = tostring(System.os.GetCurrentProcessId()),
    }
    NPL.activate(dll_name, input); 
end

function NplBrowserPlugin.CheckCefClientExist()
    return ParaIO.DoesFileExist(default_client_name);
end

function NplBrowserPlugin.OsSupported()
    if NplBrowserPlugin.isSupported == nil then
        if System.os.GetPlatform() == 'win32' and not System.os.Is64BitsSystem() then
            NplBrowserPlugin.isSupported = true;

            -- disable for windows XP
            if(NplBrowserPlugin.isSupported) then
                local stats = System.os.GetPCStats();
                if(stats and stats.os) then
                    if(stats.os:lower():match("windows xp")) then
                        NplBrowserPlugin.isSupported = false;
                    end
                end
            end
        elseif System.os.GetPlatform() == 'mac' or System.os.GetPlatform() == 'ios' then
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
    if (not NplBrowserPlugin.windows_caches or type(NplBrowserPlugin.windows_caches) ~= 'table') then
        return false;
    end

    for key, config in pairs(NplBrowserPlugin.windows_caches) do
        if (key ~= 'NplBrowserFrame_browser_instance_TeachingQuest_BrowserPage') then
            config.visible = false;
            NplBrowserPlugin.Show(config);
        end
    end
end

local function activate()
    if msg then
        local cmd = msg["cmd"];
        local id = msg["id"] or "";
        local parent_handle = msg["parent_handle"] or "";

		if(cmd == "CheckCefWindow")then
            local json_config = NplBrowserPlugin.ReadCefClientJsonConfg(cefclient_config_filename);

            if json_config then
                local key = string.format("%s_%s",id,parent_handle);
                local value = json_config[key];

                if value == true then
                    NplBrowserPlugin.ClearPendingWindow(id);
                    NplBrowserPlugin.SetWindowExisted(id, true);

                    LOG.std(nil, "info", "NplBrowserPlugin", "================ the window is created:%s ================",id);
                    -- send a message after created window
                    local callback = NplBrowserPlugin.on_created_callback_map[id];
                    if(callback)then
                        callback(msg);
                    end
                    NplBrowserPlugin.on_created_callback_map[id] = nil;
                end
            end
        elseif(cmd == "Quit")then
            -- clear window
            NplBrowserPlugin.SetWindowExisted(id, nil);
            NplBrowserPlugin.UpdateCache(id, {});
        end
    end
end

NPL.this(activate);
