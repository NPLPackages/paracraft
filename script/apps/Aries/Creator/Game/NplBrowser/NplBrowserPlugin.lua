--[[
Title: NplBrowserPlugin
Author(s): leio
Date: 2019.3.24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
local id = "nplbrowser_wnd";
NplBrowserPlugin.Start({id = id, url = "http://www.keepwork.com", withControl = true, x = 0, y = 0, width = 800, height = 600, });
NplBrowserPlugin.OnCreatedCallback(function()
    NplBrowserPlugin.Open({id = id, url = "http://www.baidu.com", resize = true, x = 100, y = 100, width = 300, height = 300, });
    NplBrowserPlugin.Show({id = id, visible = false});
    NplBrowserPlugin.Show({id = id, visible = true});
    NplBrowserPlugin.Zoom({id = id, zoom = 1}); --200%
    NplBrowserPlugin.EnableWindow({id = id, enabled = false});
    NplBrowserPlugin.ChangePosSize({id = id, x = 100, y = 100, width = 800, height = 400, });
    NplBrowserPlugin.Quit({id = id,});
end)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");
NplBrowserPlugin.is_registered = false;
local default_window_title = default_window_title;
local default_id = "nplbrowser_wnd";
local default_dll_name = "cef3/NplCefPlugin.dll";
local debug = ParaEngine.GetAppCommandLineByParam("debug", false);
if(debug == true or debug =="true" or debug == "True")then
    default_dll_name = "cef3/NplCefPlugin_d.dll";
end
local default_client_name = "cef3\\cefclient.exe";
local callback_file = "script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua";

NplBrowserPlugin.cmds_queue = nil; --commands queue
NplBrowserPlugin.cef_connection_pending_windows = {};  -- the array list to save the pending state of each new cef window
NplBrowserPlugin.windows = {}; -- save existing windows
NplBrowserPlugin.windows_caches = {}; -- the configs of window
NplBrowserPlugin.interval = 0.2 * 1000;

-- create or get the commands queue
function NplBrowserPlugin.CreateOrGetCmdsQueue()
    local cmds_queue = NplBrowserPlugin.cmds_queue;
    if(not cmds_queue)then
        cmds_queue = commonlib.Queue:new();
        NplBrowserPlugin.cmds_queue = cmds_queue;
    end
    return cmds_queue;
end
function NplBrowserPlugin.CanRunCmd(cmd)
    if(not cmd)then return end
    local id = cmd.id;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.WindowIsExisted(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin", "the window [%s] isn't existed, cmd name:%s", id, cmd.cmd or "");
        return
    end
    return true;
end
-- push a command at last
function NplBrowserPlugin.PushBack(cmd)
    if(not cmd)then return end
    local cmds_queue = NplBrowserPlugin.CreateOrGetCmdsQueue();
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
    if(NplBrowserPlugin.IsEmpty())then
        return
    end
    local cmd = NplBrowserPlugin.GetFront();
    if(NplBrowserPlugin.CanRunCmd(cmd))then
        cmd = NplBrowserPlugin.PopFront();
        local dll_name =  cmd.dll_name or default_dll_name;
        NPL.activate(dll_name,cmd); 
        NplBrowserPlugin.UpdateCache(id,cmd)
    else
        NplBrowserPlugin.PopFront();
    end
end

function NplBrowserPlugin.PushPendingWindow(id)
    if(not id)then return end
    NplBrowserPlugin.cef_connection_pending_windows[id] = true;
end
function NplBrowserPlugin.IsPendingWindow(id)
    if(not id)then return end
    return NplBrowserPlugin.cef_connection_pending_windows[id];
end
function NplBrowserPlugin.ClearPendingWindow(id)
    if(not id)then return end
    NplBrowserPlugin.cef_connection_pending_windows[id] = nil;
end
function NplBrowserPlugin.RunRefreshTimer()
     local timer = NplBrowserPlugin.timer;
    if(not timer)then
        timer = commonlib.Timer:new({callbackFunc = function(timer)
            local id,__;
            for id,__ in pairs(NplBrowserPlugin.cef_connection_pending_windows) do
                if(NplBrowserPlugin.IsPendingWindow(id))then
                    NplBrowserPlugin.CheckCefWindow({id = id})
                end
            end
            NplBrowserPlugin.RunNextCmd();
        end})
        timer:Change(0, NplBrowserPlugin.interval)
        NplBrowserPlugin.timer = timer;
    end
end
-- check if exist a window
function NplBrowserPlugin.WindowIsExisted(id)
    if(not id)then
        return
    end
    return NplBrowserPlugin.windows[id];
end
function NplBrowserPlugin.SetWindowExisted(id,v)
    NplBrowserPlugin.windows[id] = v;
end
function NplBrowserPlugin.UpdateCache(id,input)
    if(id)then
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
    local window_title = p.window_title or default_window_title;
    local id = p.id or default_id;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.Start", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(NplBrowserPlugin.WindowIsExisted(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the window [%s] is existed", id);
        return
    end
    if(NplBrowserPlugin.IsPendingWindow(id))then
        LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the window [%s] is pending for launch", id);
        return
    end
    NplBrowserPlugin.RunRefreshTimer();

    local dll_name =  p.dll_name or default_dll_name;
    local client_name =  p.client_name or default_client_name;
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    parent_handle = tostring(parent_handle);
    local tag_hide_controls;
    if(p.withControl)then
        tag_hide_controls = ""
    else
        tag_hide_controls = "-hide-controls"
    end
     
    local x = p.x or 0;
    local y = p.y or 0;
    local width = p.width or 100;
    local height = p.height or 100;
    local url = p.url or "";
    local bounds = string.format("%d,%d,%d,%d,",x,y,width,height);
    local cmdline = string.format([[
        -window_title="%s" 
        -window_name="%s" 
        %s
        -hide-top-menu 
        -url="%s" 
        -bounds="%s"
        -parent_handle="%s"
    ]],window_title,id,tag_hide_controls,url,bounds,parent_handle);
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
    }
    -- waiting for create 
    NplBrowserPlugin.PushPendingWindow(id);

    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
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
        callback_file = callback_file,
    }
    NplBrowserPlugin.PushBack(input);
end
-- push ChangePosSize command or NPL.activate dll directly
function NplBrowserPlugin.ChangePosSize(p,bActivedMode)
    local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
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
    if(bActivedMode)then
        NPL.activate(dll_name,input); 
        NplBrowserPlugin.UpdateCache(id,input)
    else
        NplBrowserPlugin.PushBack(input);
    end
end
-- push a command of Show
function NplBrowserPlugin.Show(p)
	local id = p.id or default_id;
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "Show", 
        id = id, 
        parent_handle = parent_handle, 
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
    local parent_handle = NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "CheckCefWindow", 
        id = id, 
        parent_handle = parent_handle, 
        callback_file = callback_file,
    }
    NPL.activate(dll_name,input); 
end

function NplBrowserPlugin.CheckCefClientExist()
    return ParaIO.DoesFileExist(default_client_name);
end
function NplBrowserPlugin.OsSupported()
	if(NplBrowserPlugin.isSupported == nil) then
		NplBrowserPlugin.isSupported = (System.os.GetPlatform()=="win32" and not System.os.Is64BitsSystem());

		-- disable for windows XP
		if(NplBrowserPlugin.isSupported) then
			local stats = System.os.GetPCStats();
			if(stats and stats.os) then
				if(stats.os:lower():match("windows xp")) then
					NplBrowserPlugin.isSupported = false;
				end
			end
		end
	end
    return NplBrowserPlugin.isSupported;
end
function NplBrowserPlugin.OnCreatedCallback(callback)
    NplBrowserPlugin.on_created_callback = callback;
end
local function activate()
    if(msg)then
        local cmd = msg["cmd"];
        local id = msg["id"];
        if(cmd == "CheckCefWindow")then
            local value = msg["value"];
            if(value == true)then
                NplBrowserPlugin.ClearPendingWindow(id);
                NplBrowserPlugin.SetWindowExisted(id,true);
                -- send a message of create window finished
                if(NplBrowserPlugin.on_created_callback)then
                    NplBrowserPlugin.on_created_callback(msg);
                end
            end
        elseif(cmd == "Quit")then
            -- clear window
            NplBrowserPlugin.SetWindowExisted(id,nil);
            NplBrowserPlugin.UpdateCache(id,{})
        end
    end
    
end
NPL.this(activate);