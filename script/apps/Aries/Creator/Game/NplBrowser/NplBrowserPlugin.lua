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
NplBrowserPlugin.Open({id = id, url = "http://www.keepwork.com", resize = true, x = 100, y = 100, width = 1024, height = 768, });
NplBrowserPlugin.Show({id = id, visible = false});
NplBrowserPlugin.Zoom({id = id, zoom = 1}); --200%
NplBrowserPlugin.EnableWindow({id = id, enabled = false});
NplBrowserPlugin.ChangePosSize({id = id, x = 100, y = 100, width = 400, height = 400, });
NplBrowserPlugin.Quit({id = id,});

-- start with cmdline directly
local parent_handle = ParaEngine.GetAttributeObject():GetField("AppHWND", 0);
parent_handle = tostring(parent_handle);
local cmdLine = string.format('
    -window_title="NplBrowser" 
    -window_name="nplbrowser_wnd" 
    -hide-top-menu 
    -url="http://www.keepwork.com" 
    -bounds="0,0,800,600"
    -parent_handle="%s"
',parent_handle);
ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."cef3\\cefclient.exe", cmdLine, "", 1); 
------------------------------------------------------------
]]
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
local windows = {};
local windows_caches = {};

function NplBrowserPlugin.HasWindow(id)
    if(not id)then
        return
    end
    return windows[id];
end
function NplBrowserPlugin.UpdateCache(id,input)
    if(id)then
        local result = windows_caches[id] or {};
        for k,v in pairs(input) do
            result[k] = v;
        end
        windows_caches[id] = result;
    end
end
function NplBrowserPlugin.GetCache(id)
    if(id)then
        return windows_caches[id] or {};
    end
end
-- reutrn a string
function NplBrowserPlugin.GetParentHandle()
    local parent_handle = ParaEngine.GetAttributeObject():GetField("AppHWND", 0);
    parent_handle = tostring(parent_handle);
    return parent_handle;
end
function NplBrowserPlugin.StartOrOpen(p)
    p = p or {};
    if(NplBrowserPlugin.HasWindow(p.id))then
        NplBrowserPlugin.Open(p);
    else
        NplBrowserPlugin.Start(p);
    end
end
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
    if(NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Start", "the window [%s] is existed", id);
        return
    end
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
     
    windows[id] = true;
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
        cmdline = cmdline, 
        client_name = client_name, 
        url = url,
        x = x,
        y = y,
        width = width,
        height = height,
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end
function NplBrowserPlugin.Open(p)
    local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.Open", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.Open", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Open", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
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
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end
function NplBrowserPlugin.ChangePosSize(p)
    local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.ChangePosSize", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.ChangePosSize", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.ChangePosSize", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "ChangePosSize", 
        id = id, 
        parent_handle = parent_handle, 
        x = p.x,
        y = p.y,
        width = p.width,
        height = p.height,
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end
function NplBrowserPlugin.Show(p)
	local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.Show", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.Show", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Show", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "Show", 
        id = id, 
        parent_handle = parent_handle, 
        visible = p.visible,
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end
-- p.zoom = 0 scale: 1
-- p.zoom = 1 scale: 1 * (1+1)
-- p.zoom = -1 scale: 1 / (1+1)
function NplBrowserPlugin.Zoom(p)
	local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.Zoom", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.Zoom", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Zoom", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "Zoom", 
        id = id, 
        parent_handle = parent_handle, 
        zoom = p.zoom,
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end

function NplBrowserPlugin.EnableWindow(p)
	local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.EnableWindow", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.EnableWindow", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.EnableWindow", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    local input = { 
        cmd = "EnableWindow", 
        id = id, 
        parent_handle = parent_handle, 
        enabled = p.enabled,
    }
    NPL.activate(dll_name,input); 
    NplBrowserPlugin.UpdateCache(id,input)
end
function NplBrowserPlugin.Quit(p)
	local id = p.id or default_id;
    local dll_name =  p.dll_name or default_dll_name;
    if(not NplBrowserPlugin.OsSupported())then
	    LOG.std(nil, "info", "NplBrowserPlugin.Quit", "npl browser isn't supported on %s",System.os.GetPlatform());
        return
    end
    if(not NplBrowserPlugin.CheckCefClientExist())then
		LOG.std(nil, "warn", "NplBrowserPlugin.Quit", "the client [%s] isn't existed, can't start npl browser", default_client_name);
        return
    end
    if(not NplBrowserPlugin.HasWindow(id))then
		LOG.std(nil, "warn", "NplBrowserPlugin.Quit", "the window [%s] isn't existed", id);
        return
    end
    local parent_handle =NplBrowserPlugin.GetParentHandle();
    NPL.activate(dll_name,{ 
        cmd = "Quit", 
        id = id, 
        parent_handle = parent_handle, 
    }); 
    windows[id] = nil;
    NplBrowserPlugin.UpdateCache(id,{})
end
function NplBrowserPlugin.CheckCefClientExist()
    local v = ParaIO.DoesFileExist(default_client_name);
    return v;
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