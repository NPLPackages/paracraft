--[[
Title: pe_nplbrowser
Author(s): leio
Date: 2019/5/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/pe_nplbrowser.lua");
local pe_nplbrowser = commonlib.gettable("NplBrowser.pe_nplbrowser");
Map3DSystem.mcml_controls.RegisterUserControl("pe:nplbrowser", pe_nplbrowser);
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/timer.lua");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");

local pe_nplbrowser = commonlib.gettable("NplBrowser.pe_nplbrowser");
function pe_nplbrowser.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
    local page_ctrl = mcmlNode:GetPageCtrl();
	local id = mcmlNode:GetInstanceName(rootName);
    local url = mcmlNode:GetAttributeWithCode("url");
	local withControl = mcmlNode:GetAttributeWithCode("withControl",false);
	local enabledResize = mcmlNode:GetBool("enabledResize");
	local min_width = mcmlNode:GetNumber("min_width");
	local screen_x, screen_y, screen_width, screen_height = _parent:GetAbsPosition();
    local x = screen_x + left;
	local y = screen_y + top;
    local input = {id = id, url = url, withControl = withControl, x = x, y = y, width = screen_width, height = screen_height, resize = true, };
    if(min_width and min_width > 0 and screen_width < min_width)then
        input.zoom = -1;
    else
        input.zoom = 0;
    end
    NplBrowserPlugin.OnCreatedCallback(function(msg)
        if(msg)then
            local cmd = msg["cmd"];
            if(cmd == "CheckCefWindow")then
                local config = NplBrowserPlugin.GetCache(id);
                if(config)then
                    NplBrowserPlugin.Open(config);
                end
            end
        end
    end)
    if(NplBrowserPlugin.WindowIsExisted(id))then
        NplBrowserPlugin.Open(input);
    else
	    NplBrowserPlugin.Start(input);
    end
    -- force save cache for zooming 
    NplBrowserPlugin.UpdateCache(id,input)
	CommonCtrl.AddControl(id, id);

    local function resize(id,_parent)
        if(_parent and _parent.GetAbsPosition)then
		    local screen_x, screen_y, screen_width, screen_height = _parent:GetAbsPosition();
		    local config = NplBrowserPlugin.GetCache(id);
		    if(config)then
			    local x = screen_x + left;
			    local y = screen_y + top;
			    local width = screen_width;
			    local height = screen_height;
			    NplBrowserPlugin.ChangePosSize({id = id, x = x, y = y, width = width, height = height, },true);
		    end
        end
    end

    _parent:SetScript("onsize", function()
        if(enabledResize)then
            resize(id,_parent);
        end
	end)
end

function pe_nplbrowser.Reload(mcmlNode,name,url)
	local id = mcmlNode:GetInstanceName(name);
	local config = NplBrowserPlugin.GetCache(id);
	if(config)then
		config.url = url;
		NplBrowserPlugin.Open(config);
	end
end
function pe_nplbrowser.SetVisible(mcmlNode,name,visible)
    local id = mcmlNode:GetInstanceName(name);
	local config = NplBrowserPlugin.GetCache(id);
	if(config)then
		config.visible = visible;
		NplBrowserPlugin.Show(config);
        if(visible)then
            NplBrowserPlugin.Zoom(config)
        end
		if(not visible) then
			commonlib.TimerManager.SetTimeout(function()  
				ParaUI.GetUIObject("root"):Focus();
			end, 200)
		end
	end
end
