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
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");	

function pe_nplbrowser.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout)
	if System.os.GetPlatform() == 'android' then
		local runtimeVer,paraEngineMajorVer,paraEngineMinorVer = System.os.GetParaEngineVersion()
		if paraEngineMajorVer==nil or (paraEngineMajorVer<1 or paraEngineMinorVer<2) then --1.2.1.0才支持的 （2022/12/23）
			return
		end
	end

	local page_ctrl = mcmlNode:GetPageCtrl();
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
    local url = mcmlNode:GetAttributeWithCode("url","",true);
	local video_url = mcmlNode:GetAttributeWithCode("video_url","",true);
	local mobile_video_urls = mcmlNode:GetAttributeWithCode("mobile_video_urls","",true);

	if (mobile_video_urls and mobile_video_urls ~= "" and System.options.IsTouchDevice) then
		video_url = mobile_video_urls
	end

	if (video_url ~= "") then
		NplBrowserManager:SetVideoUrl(video_url)
		if(NplBrowserPlugin.IsSupportFullWebView()) then
			local src_url = NplBrowserManager:GetVideoUrlSrc("mp4")
			if(src_url) then
				local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
				local online_url = "https://keepwork.com/official/open/apps/video"
				url = online_url.."?video_url="..src_url;
				local videoParams = RedSummerCampPPtPage.GetVideoParams()
				if GameLogic.GetFilters():apply_filters('is_signed_in') and videoParams then
					url = online_url.."?"..videoParams.."&video_url="..src_url
				end
				LOG.std(nil, "info", "pe_nplbrowser", "create url===%s",url);
			end
		else
			GameLogic.RunCommand("/webserver -silent")
			url = "npl://video" .. "?video_url=" .. NplBrowserManager:GetVideoUrlSrc()
		end
		url = pe_nplbrowser.cmd_open_url(url)
	end

	if (System.os.GetPlatform() == "win32") then
		if(not NplBrowserLoaderPage.IsLoaded())then
			if(not pe_nplbrowser.isBrowserLoading) then
				pe_nplbrowser.isBrowserLoading = true
				NplBrowserLoaderPage.Check(function(bLoaded)
					if(bLoaded) then
						if mcmlNode:GetPageCtrl():IsVisible() then --避免已经关闭界面了，突然还加载一个独立的web窗口出来
							--pe_nplbrowser.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout) 
							mcmlNode:GetPageCtrl():Refresh()
							return
						end
					end
					pe_nplbrowser.isBrowserLoading = false
				end)
			end
			return
		end
	end
	local userControl = mcmlNode:GetAttributeWithCode("userControl",false);
	local withControl = mcmlNode:GetAttributeWithCode("withControl",false);
	local visible = mcmlNode:GetAttributeWithCode("visible", nil, true);
	if(visible and visible=="true") then
		visible = true
	end
	local min_width = mcmlNode:GetNumber("min_width");
	local min_height = mcmlNode:GetNumber("min_height");
	width = mcmlNode:GetNumber("width");
	height = mcmlNode:GetNumber("height");
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

	-- if ((min_width and min_width > 0 and screen_width < min_width) or 
	-- 	(min_height and min_height > 0 and screen_height < min_height))then
    --     input.zoom = -1;
    -- else
    --     input.zoom = 0;
    -- end

	if (System.os.GetPlatform() == "win32" or
		System.os.GetPlatform() == "mac" or
		System.os.GetPlatform() == "ios" or
		System.os.GetPlatform() == "android") then
		local uiScales = Screen:GetUIScaling(true);

		if (uiScales[1] ~= 1 or uiScales[2] ~= 1) then
			input.x = math.floor(input.x * uiScales[1]);
			input.y = math.floor(input.y * uiScales[2]);
			input.width = math.floor(input.width * uiScales[1]);
			input.height = math.floor(input.height * uiScales[2]);
		end
	end
	
	if (NplBrowserPlugin.IsWindowCreated(id)) then
		local config = NplBrowserPlugin.GetWindowState(id);
		if (config and config.url ~= input.url) then
			NplBrowserPlugin.Open(input);
		else
			NplBrowserPlugin.ChangePosSize(input);
		end
	else
		NplBrowserPlugin.Start(input);
	end
	if(visible) then
		NplBrowserPlugin.Show(input)
	end
	CommonCtrl.AddControl(id, id);

	local function resize(id, _parent)
        if (_parent and _parent.GetAbsPosition) then
		    local screen_x, screen_y, screen_width, screen_height = _parent:GetAbsPosition();
		    local config = NplBrowserPlugin.GetWindowState(id);

		    if (config) then
			    local x = screen_x + left;
			    local y = screen_y + top;
				local width = width or screen_width;
				local height = height or screen_height;

				if (System.os.GetPlatform() == "win32" or
					System.os.GetPlatform() == "ios" or
					System.os.GetPlatform() == "mac" or
					System.os.GetPlatform() == "android") then
					local uiScales = Screen:GetUIScaling(true);

					if (uiScales[1] ~= 1 or uiScales[2] ~= 1) then
						x = math.floor(x * uiScales[1]);
						y = math.floor(y * uiScales[2]);
						width = math.floor(width * uiScales[1]);
						height = math.floor(height * uiScales[2]);
					end
				end

			    NplBrowserPlugin.ChangePosSize(
					{
						id = id,
						x = x,
						y = y,
						width = width,
						height = height
					}
				);
		    end
        end
	end
	_parent:SetScript("onsize", function()
		if not userControl then
			resize(id, _parent);
		end
	end);
	
	local parent_id = _parent.id
	NplBrowserPlugin.UpdateWindowState(id, {parent_id = parent_id});

	_parent:SetScript("ondestroy", function()
		-- tricky: only make it invisible if the browser is not binded to another parent control
		local config = NplBrowserPlugin.GetWindowState(id);
		if (config and config.parent_id == parent_id) then
			NplBrowserPlugin.Show({id=id, visible = false});
		end
	end);
end

function pe_nplbrowser.Reload(mcmlNode,name,url)
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
	local config = NplBrowserPlugin.GetWindowState(id);
	if(config)then
		config.url = url;
		NplBrowserPlugin.Open(config);
	end
end

function pe_nplbrowser.SetVisible(mcmlNode, name, visible)
	local id = mcmlNode:GetAttributeWithCode("name") or mcmlNode.name or mcmlNode:GetInstanceName(rootName);
	local config = NplBrowserPlugin.GetWindowState(id);

	if (config) then
		config.visible = visible;
		NplBrowserPlugin.Show(config);

		if (not visible) then
			commonlib.TimerManager.SetTimeout(function()  
				ParaUI.GetUIObject("root"):Focus();
			end, 200)
		end
	end
end

function pe_nplbrowser.cmd_open_url(url)
	if(url and url:match("^npl")) then
		if(GameLogic.IsReadOnly()) then
			-- _guihelper.MessageBox(L"安全警告: NPL code wiki 只能在你自己创建的非只读世界中运行, 命令被终止");
			-- return;
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
		local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");
		local isReturned;
		local bStarted, site_url = NPLWebServer.CheckServerStarted(function(bStarted, site_url)
			if(bStarted and isReturned) then
				-- GameLogic.RunCommand("/open "..url);
			end
		end)
		isReturned = true;
		if(bStarted) then
			url = url:gsub("^npl:?/*", site_url);
		else
			return;
		end
	end
	return url;
end