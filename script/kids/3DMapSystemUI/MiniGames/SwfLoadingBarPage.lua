--[[
Title: 
Author(s): Leio
Date: 2009/10/15
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/FileLoader.lua");
local FileLoader = commonlib.gettable("CommonCtrl.FileLoader");
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.lua");
--绑定下载器
local filepath = "installer/aries/Aries_PreloadList.txt";
local downloader = FileLoader:new{
	sequenceMode = 0,
};
downloader:LoadFile(filepath);
downloader:Start();
Map3DSystem.App.MiniGames.SwfLoadingBarPage.BindLoaderAndShowPage(
	{
		downloader = downloader,
		state = "normal", -- normal or advanced
	}
);
--没有绑定下载器
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.lua");
Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
	{
		top = -240,
		--state = "advanced", -- normal or advanced
	}
);
Map3DSystem.App.MiniGames.SwfLoadingBarPage.Update(0.9);

-- show with background. 
Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
	{
		top = -100,
		show_background = true,
	}
);
Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage();
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/GameScorePage.lua");
NPL.load("(gl)script/ide/FlashPlayerWindow.lua");
NPL.load("(gl)script/ide/FlashExternalInterface.lua");

local LOG = LOG;
-- default member attributes
local SwfLoadingBarPage = commonlib.createtable("Map3DSystem.App.MiniGames.SwfLoadingBarPage", {
	page = nil,
	align = "_ct",
	left = -275,
	top = -254,
	width = 630,
	height = 435,  
	downloader = nil, --被绑定的下载器
	isTopLevel = false,
	
	showCloseBtn = false,--是否显示关闭面板按钮，只在normal状态下有效
	isShow = false,--是否已经显示
	state = "normal", -- normal or advanced
	gamestate = "close", --close or open
	maxSize = 200000,
	percent = 0,--当前下载进度
	
	-- one can overwrite this to use a different template. 
	url = "script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.html",
	txt = {},
	default_txt = nil, -- loading text set in config file config/Aries/Loading.SwfLoadingText.xml
			--{
			--"春天来了，大地都披上了新绿。",
			--"呼噜大叔胃口大，一口气能吃五个西瓜。",
			--"找安吉奶奶寄养抱抱龙。",
			--"农场也可以买种子了。",
			--"西瓜仔捡回新的蒲公英种子，快给家里种上吧。",
			--},
	txt_timer = nil,
	txt_index = 0,
	txt_duration = 3000,
	last_txt = nil,
	--事件
	loaderUpdateFunc = nil,
	loaderFinishedFunc = nil,
	loaderEndFunc = nil,
	loaderCancelFunc = nil,--取消加载 只停止了面板的显示，没有停止真正的下载
});

function SwfLoadingBarPage.BuildSource()
	if(not SwfLoadingBarPage.loadingtexts)then
		local filename;
		if(System.options.version == "teen")then
			filename = "config/Aries/Loading.SwfLoadingText.teen.xml";
		else
			filename = "config/Aries/Loading.SwfLoadingText.xml";
		end
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(not xmlRoot) then
			commonlib.log("error: failed loading swfloadingtext config file %s\n", filename);
			-- use default config file xml root
			xmlRoot = 
			{
			  {
				{
				  attr={ name="default" },
				  n=1,
				  name="loadingtext" 
				},
				n=1,
				name="loadingbar" 
			  },
			  n=1 
			};
		end

		local loadingtexts = {};
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/loadingbar/loadingtext") do
			if(node.attr and node.attr.name) then
				table.insert(loadingtexts, node.attr.name)
			end
		end
		SwfLoadingBarPage.loadingtexts = loadingtexts;
	end
	return SwfLoadingBarPage.loadingtexts;
end
function SwfLoadingBarPage.OnInit()
	local self = SwfLoadingBarPage;
	self.page = document:GetPageCtrl();
	
	local percent = SwfLoadingBarPage.percent;
	local t = SwfLoadingBarPage.last_txt;

	local page = document:GetPageCtrl();
	if(page)then
		if(t)then
			page:SetValue("txt_info_normal",t);
			page:SetValue("txt_info_advanced",t);
		end
		if(percent)then
			local p = string.format("%.2f%%",percent);
			page:SetValue("txt_percent_advanced_open",p);
			page:SetValue("txt_percent_advanced_close",p);
			page:SetValue("txt_percent_normal",p);
		end

		local progressbar = page:FindControl("progressbar_normal");
		if(progressbar) then 
			page:SetValue("progressbar_normal",percent);
		end
		progressbar = page:FindControl("progressbar_advanced_open");
		if(progressbar) then 
			page:SetValue("progressbar_advanced_open",percent);
		end
		progressbar = page:FindControl("progressbar_advanced_close");
		if(progressbar) then 
			page:SetValue("progressbar_advanced_close",percent);
		end
	end
end

-----------------
-- page functions
-----------------

function SwfLoadingBarPage.OnCreate_Pe_Custom_Close(params)
    local _this = ParaUI.CreateUIObject("button", "b", "_lt", params.left,params.top,params.width,params.height)
    _this.background = "Texture/Aries/MiniGame/SwfLoadingBar/swf_loadingbar_btn_close_32bits.png;0 0 68 68";
    _this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowGame();";
    params.parent:AddChild(_this);
    --local _mark = _this;
	-- _this.visible = false;
    --
    --local left, top, width, height = _this:GetAbsPosition();
    --local _this = ParaUI.CreateUIObject("button", params.name, "_lt", left, top, width, height)
    --_this.zorder = 2000;
    --_this.background = "Texture/Aries/MiniGame/SwfLoadingBar/swf_loadingbar_btn_close_32bits.png;0 0 68 68";
    --_this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowGame();";
    --_this:AttachToRoot();
    --
    --_mark.ondestroy = string.format(";ParaUI.Destroy(%d);", _this.id);
end

function SwfLoadingBarPage.OnCreate_Pe_Custom_Open(params)
	local _this = ParaUI.CreateUIObject("button", "b", "_lt", params.left,params.top,params.width,params.height)
    
    _this.background = "Texture/Aries/MiniGame/SwfLoadingBar/swf_loadingbar_btn_open_32bits.png;0 0 68 68";
    _this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowGame();";
    _this.tooltip = "在下载资源的过程中，你可以赚些奇豆";
    params.parent:AddChild(_this);

    --local _mark = _this;
    --_this.visible = false;
    --local left, top, width, height = _this:GetAbsPosition();
    --local _this = ParaUI.CreateUIObject("button", params.name, "_lt", left, top, width, height)
    --_this.zorder = 2000;
    --_this.background = "Texture/Aries/MiniGame/SwfLoadingBar/swf_loadingbar_btn_open_32bits.png;0 0 68 68";
    --_this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowGame();";
    --_this.tooltip = "在下载资源的过程中，你可以赚些奇豆";
    --_this:AttachToRoot();
    --
    --_mark.ondestroy = string.format(";ParaUI.Destroy(%d);", _this.id);
end
--关闭面板按钮
function SwfLoadingBarPage.OnCreate_Pe_Custom_NormalCloseBtn(params)
    local _this = ParaUI.CreateUIObject("button", "b", "_lt", params.left,params.top,params.width,params.height)
    _this.background = "Texture/Aries/Common/Close_Big_54_32bits.png;0 0 54 54";
    _this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage_Manual();";
    params.parent:AddChild(_this);

    --local _mark = _this;
    --_this.visible = false;
    --local left, top, width, height = _this:GetAbsPosition();
    --local _this = ParaUI.CreateUIObject("button", params.name, "_lt", left, top, width, height)
    --_this.zorder = 2000;
    --_this.background = "Texture/Aries/Common/Close_Big_54_32bits.png;0 0 54 54";
    --_this.onclick = ";Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage_Manual();";
    --_this:AttachToRoot();
    --
    --_mark.ondestroy = string.format(";ParaUI.Destroy(%d);", _this.id);
end
function SwfLoadingBarPage.getShowState()
    return SwfLoadingBarPage.state;
end
--game state : open or close
function SwfLoadingBarPage.getGameState()
    return SwfLoadingBarPage.gamestate;
end

function SwfLoadingBarPage.isNormal()
    if(SwfLoadingBarPage.state == "normal")then
        return true;
    end
end

function SwfLoadingBarPage.isAdvance()
	if(SwfLoadingBarPage.state == "advanced") then
		return true;
	end
end

function SwfLoadingBarPage.isAdvance_Open()
   if(SwfLoadingBarPage.state == "advanced" and SwfLoadingBarPage.gamestate == "open")then
        return true;
    end
end

function SwfLoadingBarPage.isAdvance_Close()
    if(SwfLoadingBarPage.state == "advanced" and SwfLoadingBarPage.gamestate == "close")then
        return true;
    end
end

function SwfLoadingBarPage.isShowBackground()
    if(SwfLoadingBarPage.show_background)then
        return true;
    end
end

-----------------
-- public functions
-----------------

-- get the next loading text.
function SwfLoadingBarPage.GetNextLoadingText()
	local self = SwfLoadingBarPage;
	if(self.page and self.txt and not self.has_text)then
		local len = table.getn(self.txt);
		if(self.txt_index > len)then
			self.txt_index = 1;
		else
			self.txt_index = self.txt_index + 1;
		end
		local info = self.txt[self.txt_index];
		if(info)then
			self.last_txt = info;
			return info;
		end
	end
end

function SwfLoadingBarPage.UpdateTimer_Text()
	local self = SwfLoadingBarPage;
	local info = self.GetNextLoadingText();
	if(info) then
		self.last_txt = info;
		self.page:SetUIValue("txt_info_normal",info);
		self.page:SetUIValue("txt_info_advanced",info);
	end
end

function SwfLoadingBarPage.OnUpdateFunc()
	local self = SwfLoadingBarPage;
	local p = 0;
	if(self.downloader)then
		p = self.downloader:GetPercent();
		self.Update(p);
	end
	if(self.loaderUpdateFunc and type(self.loaderUpdateFunc) == "function")then
		self.loaderUpdateFunc(p);	
	end
end
function SwfLoadingBarPage.OnLoadFinished()
	local self = SwfLoadingBarPage;
	--要在close之前触发
	if(self.loaderFinishedFunc and type(self.loaderFinishedFunc) == "function")then
		self.loaderFinishedFunc();	
	end
	if(self.page)then
		if(self.state == "advanced")then
			--获取捡金币的个数，关闭flash
			local score = self.GetScore();
			self.CloseFlashGame();
			LOG.std("", "system","minigame","get score from catch bean game:"..LOG.tostring(score));
			self.PutBean(score);
		end
		self.ClosePage();
	end
end
function SwfLoadingBarPage.OnEndFunc()
	local self = SwfLoadingBarPage;
	--要在close之前触发
	if(self.loaderEndFunc and type(self.loaderEndFunc) == "function")then
		self.loaderEndFunc();	
	end
	if(self.page)then
		self.ClosePage();
	end
	
end
function SwfLoadingBarPage.OpenFlashGame()
	local self = SwfLoadingBarPage;
	if(self.page)then
		local ctl = self.page:FindControl("flashctl");
		if(ctl)then
			local index = ctl.FlashPlayerIndex;
			local func_args = {
				funcName = "StartGame",
				args = {
					
				}
			} 
			commonlib.CallFlashFunction(index, func_args);
		end
	end
end
function SwfLoadingBarPage.CloseFlashGame()
	local self = SwfLoadingBarPage;
	if(self.page  and self.gamestate == "open")then
		local ctl = self.page:FindControl("flashctl");
		if(ctl)then
			local index = ctl.FlashPlayerIndex;
			local func_args = {
				funcName = "EndGame",
				args = {
					
				}
			} 
			commonlib.CallFlashFunction(index, func_args);
		end
	end
end
function SwfLoadingBarPage.GetScore()
	local self = SwfLoadingBarPage;
	if(self.page and self.gamestate == "open")then
		local ctl = self.page:FindControl("flashctl");
		if(ctl)then
			local index = ctl.FlashPlayerIndex;
			local func_args = {
				funcName = "GetScore",
				args = {
					
				}
			} 
			local score = commonlib.CallFlashFunction(index, func_args);
			return score;
		end
	end
end
function SwfLoadingBarPage.ShowGame()
	local self = SwfLoadingBarPage;
	if(self.page)then
		if(self.gamestate == "close")then
			self.gamestate = "open";
		else
			--记录获取的分数
			local score = self.GetScore();
			self.CloseFlashGame();
			LOG.std("", "system","minigame","get score from catch bean game:"..LOG.tostring(score));
			self.PutBean(score);
			self.gamestate = "close";
		end
		self.page:Refresh(0);
		if(self.gamestate == "open")then
			self.OpenFlashGame();
		end
	end
end
function SwfLoadingBarPage.UpdateText(txt)
	local self = SwfLoadingBarPage;
	if(self.page)then
		if(txt)then
			self.has_text = true;
			
			self.page:SetUIValue("txt_info_normal",txt);
			self.page:SetUIValue("txt_info_advanced",txt);
		else
			self.has_text = false;
		end
	end
end
function SwfLoadingBarPage.Update(percent)
	local self = SwfLoadingBarPage;
	if(self.page and percent)then
		percent = percent * 100;
		percent = math.min(percent,100);
		self.percent = percent;
		local p = string.format("%.2f%%",percent);
		--commonlib.echo("========================percent");
		--commonlib.echo(self.percent);
		if(self.state == "advanced")then
			if(self.gamestate == "open")then
				local ctl = self.page:FindControl("flashctl");
				if(ctl)then
					local index = ctl.FlashPlayerIndex;
					local func_args = {
						funcName = "Update",
						args = {
							percent
						}
					} 
					commonlib.CallFlashFunction(index, func_args);
				end
			end
			self.page:SetValue("progressbar_advanced_open",percent);
			self.page:SetValue("progressbar_advanced_close",percent);
		else
			self.page:SetValue("progressbar_normal",percent);
		end
		self.page:SetValue("txt_percent_advanced_open",p);
		self.page:SetValue("txt_percent_advanced_close",p);
		self.page:SetValue("txt_percent_normal",p);
	end
end
--[[如果没有downloader 或者downloader已经结束，面板不会被显示
@param msg = {
		downloader = downloader,--下载器
		state = state,-- normal or advanced,default value is normal
		align = align,--default value is "_ct"
		left = left,
		top = top,
		width = width,
		height = height,
		txt = {},--下载过程当中显示的文字
		show_background = show_background, --true to show background, nil to disable it. 
		isTopLevel = true,
		showCloseBtn = true,--true or false,
		notShowTxt = true,
	}
e.g.
	NPL.load("(gl)script/ide/FileLoader.lua");
	local downloader = CommonCtrl.FileLoader:new{download_list = {}, logname = "log/magazine_loader",}
	Map3DSystem.App.MiniGames.SwfLoadingBarPage.BindLoaderAndShowPage({ downloader = downloader, state = "advanced",  notShowTxt = true, });
	Map3DSystem.App.MiniGames.SwfLoadingBarPage.BindLoaderAndShowPage({ downloader = downloader, notShowTxt = true, });
]]
function SwfLoadingBarPage.BindLoaderAndShowPage(msg)
	local self = SwfLoadingBarPage;
	if(not msg)then return end
	local downloader = msg.downloader;
	if(not downloader)then return end
	
	if(self.downloader)then
		--unhook 前一个下载
		self.downloader.OnUpdateFunc = nil;
		self.downloader.OnLoadFinished = nil;
		self.downloader.OnEndFunc = nil;
	end
	self.percent = 0;
	self.downloader = downloader;
	--self.downloader.OnUpdateFunc = SwfLoadingBarPage.OnUpdateFunc;
	--self.downloader.OnLoadFinished = SwfLoadingBarPage.OnLoadFinished;
	--self.downloader.OnEndFunc = SwfLoadingBarPage.OnEndFunc;

	downloader:AddEventListener("start",function(self,event)
		
	end,{});
	downloader:AddEventListener("loading",function(self,event)
		SwfLoadingBarPage.OnUpdateFunc();
	end,{});
	downloader:AddEventListener("finish",function(self,event)
		SwfLoadingBarPage.OnLoadFinished();
	end,{});
	downloader:AddEventListener("cancel",function(self,event)
		--SwfLoadingBarPage.OnEndFunc();
	end,{});
	
	-- tricky: this is really tricky by LiXizhi. several caller may race closing the page, we will ignore 
	-- any try_close calls when swf loader is binded with a downloader. 
	SwfLoadingBarPage.ClosePage();
	self.ignore_try_close = true;

	self.ShowPage(msg);
end

-- Show page with display options. 
-- @param state:normal or advanced,default value is normal
-- @param align,left,top,width,height: they can be nil. 
-- @param show_background: true to show background, nil to disable it. 
--[[
	msg = {
		state = state,-- normal or advanced,default value is normal
		align = align,--default value is "_ct"
		left = left,
		top = top,
		width = width,
		height = height,
		txt = {},--下载过程当中显示的文字
		show_background = show_background, --true to show background, nil to disable it. 
		isTopLevel = true,
		showCloseBtn = true,--true or false,
		notShowTxt = true,
	}
--]]
--function SwfLoadingBarPage.ShowPage(state,align,left,top,width,height, show_background)
function SwfLoadingBarPage.ShowPage(msg)
	local self = SwfLoadingBarPage;
	local state = msg.state or self.state;
	local align = msg.align or self.align;
	local left = msg.left or self.left;
	local top = -100;
	if(state == "normal" and not msg.top)then
		top = -100;
	else
		top = msg.top or self.top;
	end
	local notShowTxt = msg.notShowTxt;
	--是否显示关闭面板 在normal状态下有效
	if(msg.showCloseBtn and state == "normal")then
		self.showCloseBtn = true;
	else
		self.showCloseBtn = false;
	end
	local width = msg.width or self.width;
	local height = msg.height or self.height;
	local txt = msg.txt or self.BuildSource();
	local show_background = msg.show_background ;
	local worldname = msg.worldname;
	
	if(self.isShow)then
		-- LOG.std("", "info","minigame","warning:you must manually close SwfLoadingBarPage!");
		return
	end
	
	self.isShow = true;
	--文字
	self.txt = txt;
	self.state = state;
	--self.gamestate = "open";
	local url = self.url;
	if(show_background) then
		url = url.."?showbg=true";
		if(worldname)then
			url = url.."&worldname="..worldname;
		end
	end
	
	self.cur_alignment = align; -- not used
	self.cur_block_style = format("margin-left:%dpx;margin-top:%dpx;width:%dpx;height:%dpx", left, top, width, height);

	local params = {
			url = url, 
			name = "MiniGames.SwfLoadingBarPage", 
			--app_key=MyCompany.Taurus.app.app_key, 
			--app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = msg.zorder or 1001,
			allowDrag = false,
			isTopLevel = msg.isTopLevel,
			-- enabled window if there is interactive element. 
			frameEnabled = self.showCloseBtn or state=="advanced" or false,
			cancelShowAnimation = true,
			isPinned = true, -- this will skip HideAllExceptPinned()
			click_through = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	if(not self.txt_timer)then
		self.txt_timer = commonlib.Timer:new{
			callbackFunc = SwfLoadingBarPage.UpdateTimer_Text
		}
	end
	self.has_text = false;
	if(not notShowTxt)then
		self.txt_timer:Change(0,self.txt_duration);
	end
	--self.UpdateTimer_Text()
end

-- close the page if self.sConditionName is true. display sText for nDelayTime before closing the page 
-- when this function is returned self.sConditionName is made nil.
-- @param callbackOnClose: nil or function() end, that is invoked when page is closed. 
function SwfLoadingBarPage.TryClosePageIfTrue(sConditionName, sText, nDelayTime, callbackOnClose)
	if(SwfLoadingBarPage[sConditionName]) then
		if(nDelayTime~=0) then
			if(sText) then
				SwfLoadingBarPage.UpdateText(sText);
			end
			UIAnimManager.PlayCustomAnimation(nDelayTime, function(elapsedTime)
				if(elapsedTime == nDelayTime) then
					if(SwfLoadingBarPage[sConditionName]) then
						SwfLoadingBarPage[sConditionName] = nil;
						if(not SwfLoadingBarPage.ignore_try_close) then
							SwfLoadingBarPage.ClosePage();
						end
						if(callbackOnClose) then
							callbackOnClose();
						end
					end
				end
			end);
		else
			SwfLoadingBarPage[sConditionName] = nil;
			if(not SwfLoadingBarPage.ignore_try_close) then
				SwfLoadingBarPage.ClosePage();
			end
			if(callbackOnClose) then
				callbackOnClose();
			end
		end
	end
end

function SwfLoadingBarPage.ClosePage()
	local self = SwfLoadingBarPage;
	self.ignore_try_close = nil;
	if(self.page)then
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="MiniGames.SwfLoadingBarPage", 
			-- app_key=MyCompany.Aries.app.app_key, 
			bShow = false,bDestroy = true,});
		
		self.page = nil;
		self.percent = 0;
		self.state = "normal";
		self.gamestate = "close";
		self.isShow = false;
		
		
		self.loaderUpdateFunc = nil;
		self.loaderFinishedFunc = nil;
		self.loaderEndFunc = nil;
		if(self.downloader)then
			--unhook 前一个下载
			self.downloader.OnUpdateFunc = nil;
			self.downloader.OnLoadFinished = nil;
		end
		
		self.txt_index = 0;
		self.last_txt = nil;
		if(self.txt_timer)then
			self.txt_timer:Change();
		end
		self.has_text = false;
	else
		self.isShow = false;
	end
end

function SwfLoadingBarPage.ClosePage_Manual()
	local self = SwfLoadingBarPage;
	self.ClosePage();
	if(self.loaderCancelFunc and type(self.loaderCancelFunc) == "function")then
		self.loaderCancelFunc();
	end
end
function SwfLoadingBarPage.PutBean(bean)
	if(bean and bean > 0)then
		bean = math.min(bean,Map3DSystem.App.MiniGames.GameScorePage.maxBean);
		-- hard code the AddMoney here, move to the game server in the next release candidate
		local AddMoneyFunc = commonlib.getfield("MyCompany.Aries.Player.AddMoney");
		if(AddMoneyFunc) then
			AddMoneyFunc(bean or 0, function(msg) 
				LOG.std("", "system","minigame","======== SwfLoadingBarPage.PutBean returns: ========"..LOG.tostring(msg));
				-- send log information
				if(msg.issuccess == true) then
					paraworld.PostLog({action = "joybean_obtain_from_minigame", joybeancount = (bean or 0), gamename = "SwfLoadingBar"}, 
						"joybean_obtain_from_minigame_log", function(msg)
					end);
				end
			end);
		end
	end
end