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
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserPlugin.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");

local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local Screen = commonlib.gettable("System.Windows.Screen");
local NplBrowserPlugin = commonlib.gettable("NplBrowser.NplBrowserPlugin");

local pe_nplbrowser = commonlib.gettable("NplBrowser.pe_nplbrowser");

function pe_nplbrowser.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
    if System.os.GetPlatform() == 'win32' and not NplBrowserLoaderPage.IsLoaded() then
        return
	end
	
	if System.os.GetPlatform() == 'android' then
		return
	end

	local page_ctrl = mcmlNode:GetPageCtrl();
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
    local url = mcmlNode:GetAttributeWithCode("url","",true);
	local withControl = mcmlNode:GetAttributeWithCode("withControl",false);
	local visible = mcmlNode:GetAttributeWithCode("visible", nil, true);
	visible = not (visible == false or visible=="false");
	local enabledResize = mcmlNode:GetBool("enabledResize");
	local min_width = mcmlNode:GetNumber("min_width");
	local min_height = mcmlNode:GetNumber("min_height");
	width = mcmlNode:GetNumber("width") or width;
	height = mcmlNode:GetNumber("height") or height;
	local screen_x, screen_y, screen_width, screen_height = _parent:GetAbsPosition();

    local x = screen_x + left;
	local y = screen_y + top;
    local input = {
		id = id,
		url = url,
		withControl = withControl,
		x = x,
		y = y,
		width = width or screen_width,
		height = height or screen_height,
		resize = true,
		visible = visible,
		_parent = _parent,
	};

	if( (min_width and min_width > 0 and screen_width < min_width) or 
		(min_height and min_height > 0 and screen_height < min_height))then
        input.zoom = -1;
    else
        input.zoom = 0;
    end

	if System.os.GetPlatform() == 'win32' then
		local uiScales = Screen:GetUIScaling();
	
		if(uiScales[1] ~= 1 or uiScales[2] ~= 1) then
			input.x = math.floor(input.x*uiScales[1]);
			input.y = math.floor(input.y*uiScales[2]);
			input.width = math.floor(input.width*uiScales[1]);
			input.height = math.floor(input.height*uiScales[2]);
		end
	end

	if NplBrowserPlugin.WindowIsExisted(id) then
		local config = NplBrowserPlugin.GetCache(id);
	    if(config and config.url == input.url and config.x == input.x  and config.y == input.y  and config.width == input.width  and config.height == input.height) then
			if(config.zoom ~= 0) then
				NplBrowserPlugin.Zoom({id = id, zoom = config.zoom});
			end
		else
            if(enabledResize and config.url == input.url)then
			    NplBrowserPlugin.ChangePosSize({id = id, x = input.x, y = input.y, width = input.width, height = input.height, });
            else
				NplBrowserPlugin.Open(input);
            end
		end
	else
		NplBrowserPlugin.Start(input);
		if(input.zoom ~= 0) then
			-- set zoom at 1, 3, 6, 10 seconds
			local i = 1;
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				local config = NplBrowserPlugin.GetCache(id);
				if(config.visible and input.zoom ~= 0)then
					NplBrowserPlugin.Zoom({id = id, zoom = input.zoom});
					i = i + 1;
					if(i<=4) then
						timer:Change(i*1000, nil)
					end
				end
			end})
			mytimer:Change(i*1000, nil)
		end
	end

	-- force save cache for zooming when run pe_nplbrowser.SetVisible after opened cef browser
	NplBrowserPlugin.UpdateCache(id, input);

	CommonCtrl.AddControl(id, id);

	local function resize(id, _parent)
        if(_parent and _parent.GetAbsPosition)then
		    local screen_x, screen_y, screen_width, screen_height = _parent:GetAbsPosition();
		    local config = NplBrowserPlugin.GetCache(id);
		    if(config)then
			    local x = screen_x + left;
			    local y = screen_y + top;
				local width = width or screen_width;
				local height = height or screen_height;

				if System.os.GetPlatform() == 'win32' then
					local uiScales = Screen:GetUIScaling();
					if(uiScales[1] ~= 1 or uiScales[2] ~= 1) then
						x = math.floor(x*uiScales[1]);
						y = math.floor(y*uiScales[2]);
						width = math.floor(width*uiScales[1]);
						height = math.floor(height*uiScales[2]);
					end
				end

			    NplBrowserPlugin.ChangePosSize({id = id, x = x, y = y, width = width, height = height}, true);
		    end
        end
	end

	if System.os.GetPlatform() == 'mac' then
		local config = NplBrowserPlugin.GetCache(id);

		local function resizeInterval()
			commonlib.TimerManager.SetTimeout(function()
				if config.isLoadWebview and config.bResizeInterval then
					resize(id, _parent);
					resizeInterval();
				else
					config.bResizeInterval = false
				end
			end, 0)
		end

		config.resizeInterval = resizeInterval;
	end

	_parent:SetScript("onsize", function()
		if enabledResize then
            resize(id, _parent);
		end
	end)
end

function pe_nplbrowser.Reload(mcmlNode,name,url)
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
	local config = NplBrowserPlugin.GetCache(id);
	if(config)then
		config.url = url;
		NplBrowserPlugin.Open(config);
	end
end

function pe_nplbrowser.SetVisible(mcmlNode, name, visible)
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
	local config = NplBrowserPlugin.GetCache(id);

	if(config)then
		config.visible = visible;
		NplBrowserPlugin.Show(config);

		if System.os.GetPlatform() == 'mac' then
			config.bResizeInterval = false;

			if config.visible then
				commonlib.TimerManager.SetTimeout(function()
					if config.resizeInterval and not config.bResizeInterval then
						config.bResizeInterval = true;
						config.resizeInterval();
					end
				end, 100)
			end
		end

		if(not visible) then
			commonlib.TimerManager.SetTimeout(function()  
				ParaUI.GetUIObject("root"):Focus();
			end, 200)
		end
	end
end
