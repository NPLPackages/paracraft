--[[
Title: a simple mcml web page browser window
Author(s): LiXizhi
Date: 2008/3/10
Desc: a thin wrapper of PageCtrl in a web browser style API. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/BrowserWnd.lua");
local ctl = Map3DSystem.mcml.BrowserWnd:new{
	name = "McmlBrowserWnd1",
	alignment = "_lt",
	left=0, top=0,
	width = 512,
	height = 290,
	parent = nil,
};
ctl:Show();
-- One can also create NavBar elsewhere, like below
ctl:CreateNavBar(_parent, "_mt", 0, 0, 0,32)
ctl:Goto("%WIKI%/Main/ParaWorldFrontPageMCML");
ctl:Goto(url, System.localserver.CachePolicy:new("access plus 1 day"));
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");
NPL.load("(gl)script/ide/System/localserver/factory.lua");

--------------------------------------------------------------------
-- a browser window instance: internally it is a PageCtrl
--------------------------------------------------------------------
local BrowserWnd = {
	-- the top level control name
	name = "BrowserWnd1",
	-- normal window size
	alignment = "_lt",
	left = 0,
	top = 0,
	width = 300,
	height = 290, 
	parent = nil,
	background = "",
	-- current url
	url = nil,
	-- boolean: whether to create the nav bar, if nil NavBar will not be created. if false, it will be created but not visible.
	DisplayNavBar = nil,
	-- whether to display nav address combo box, if this is DisplayNavBar is not true, this parameter takes no effect. 
	DisplayNavAddress = true,
	-- a file containing url addresses
	historyFileName = "config/mcmlbrowser_urls.txt";
	-- max number of history files 
	max_history_items = 200,
	-- window object that will be passed to the internal pageCtrl.
	window = nil,
}
Map3DSystem.mcml.BrowserWnd = BrowserWnd;

-- constructor
function BrowserWnd:new (o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Destroy the UI control
function BrowserWnd:Destroy ()
	ParaUI.Destroy(self.name);
end

-- create navigation bar for this window
function BrowserWnd:CreateNavBar(_parent, alignment, left, right, width, height)
	if(_parent==nil) then
		_parent = ParaUI.GetUIObject(self.name);
	end
	
	if(ParaUI.GetUIObject(self.name.."navBar"):IsValid())  then
		return
	end
	
	local _this = ParaUI.CreateUIObject("container", self.name.."navBar", alignment or "_mt", left or 0, right or 0, width or 0, height or 28)
	_this.background = "";
	_parent:AddChild(_this);
	_parent = _this;
	
	local left, width = 8, 28;
	_this = ParaUI.CreateUIObject("button", "RefreshBtn", "_lt", left, 5, width, 23)
	_this.background = "Texture/3DMapSystem/webbrowser/PreviousPage_32bits.png; 0 0 28 23";
	_this.tooltip= "返回上一页";
	_this.onclick = string.format(";Map3DSystem.mcml.BrowserWnd.OnClickNavBackward(%q);", self.name);
	--_this.animstyle = 12;
	_parent:AddChild(_this);
	left = left + width - 1;
		
	_this = ParaUI.CreateUIObject("button", "RefreshBtn", "_lt", left, 5, width, 23)
	_this.background = "Texture/3DMapSystem/webbrowser/NextPage_32bits.png; 0 0 28 23";
	_this.tooltip= "返回下一页";
	_this.onclick = string.format(";Map3DSystem.mcml.BrowserWnd.OnClickNavForward(%q);", self.name);
	--_this.animstyle = 12;
	_parent:AddChild(_this);
	left = left + width + 9;

	_this = ParaUI.CreateUIObject("button", "RefreshBtn", "_lt", left, 5, width, 23)
	_this.background = "Texture/3DMapSystem/webbrowser/RefreshPage_32bits.png; 0 0 28 23";
	_this.tooltip= "刷新网页";
	_this.onclick = string.format(";Map3DSystem.mcml.BrowserWnd.OnClickNavRefresh(%q);", self.name);
	--_this.animstyle = 12;
	_parent:AddChild(_this);
	left = left + width + 8;
	
	-- address bar is here. 
	_this = ParaUI.CreateUIObject("container", "navAddressBar", "_fi", left, 0, 0, 0)
	_this.background = "";
	_parent:AddChild(_this);
	_parent = _this;
	
	left, width = 10, 29;
	--_this = ParaUI.CreateUIObject("button", "RefreshBtn", "_rt", -(left+width), 3, width, width)
	--_this.background = "Texture/3DMapSystem/webbrowser/refresh.png"
	--_this.tooltip= "刷新网页";
	--_this.onclick = string.format(";Map3DSystem.mcml.BrowserWnd.OnClickNavRefresh(%q);", self.name);
	--_this.animstyle = 12;
	--_parent:AddChild(_this);
	
	_this = ParaUI.CreateUIObject("button", "navTo", "_rt", -(left+width), 5, width, 23)
	_this.background = "Texture/3DMapSystem/webbrowser/Browse_32bits.png; 0 0 29 23";
	--_this.background = "Texture/3DMapSystem/webbrowser/goto.png"
	_this.tooltip= "打开";
	_this.onclick = string.format(";Map3DSystem.mcml.BrowserWnd.OnClickNavTo(%q);", self.name);
	_parent:AddChild(_this);
	left = left + width + 6;
	
	
	NPL.load("(gl)script/ide/dropdownlistbox.lua");
	local ctl = CommonCtrl.dropdownlistbox:new{
		name = self.name.."comboBoxAddress",
		alignment = "_mt",
		left = addrLeft,
		top = 5,
		width = left,
		height = 24,
		dropdownheight = 106,
		parent = _parent,
		
		container_bg = nil, -- the background of container that contains the editbox and the dropdown button.
		editbox_bg = "Texture/3DMapSystem/webbrowser/AddressBar_32bits.png: 6 6 6 6",
		--dropdownbutton_bg = "Texture/3DMapSystem/webbrowser/DropDownBox_32bits.png; 0 0 20 24",-- drop down button background texture
		listbox_bg = nil, -- list box background texture
		
		
		text = "",
		items = {},
		onselect = string.format("Map3DSystem.mcml.BrowserWnd.OnClickNavTo(%q);", self.name),
	};
	ctl:Show();
	
	if(not self.DisplayNavAddress) then
		_parent.visible = false;
	end	
	
	if(not self.DisplayNavBar) then
		_parent.parent.visible = false;
	end
	
	-- update address bar history. 
	self:UpdateHistoryFiles();
end

--@param bShow: boolean to show or hide. if nil, it will toggle current setting. 
--@return true if UI is created
function BrowserWnd:Show(bShow)
	local _this,_parent, UICreated;
	if(self.name==nil)then
		log("BrowserWnd instance name can not be nil\r\n");
		return
	end
	
	_this=ParaUI.GetUIObject(self.name);
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		_this=ParaUI.CreateUIObject("container",self.name,self.alignment,self.left,self.top,self.width,self.height);
		if(self.background) then
			_this.background=self.background;
		end
		_parent = _this;
		if(self.parent==nil) then
			_this:AttachToRoot();
		else
			_this.background="";
			self.parent:AddChild(_this);
		end
		
		CommonCtrl.AddControl(self.name, self);
		
		local top = 0;
		
		-------------------------
		-- navbar
		if(self.DisplayNavBar) then
			self:CreateNavBar(_parent, "_mt", 0,top,0,32);
			top = top+32;
		end
		-------------------------
		-- create PageCtrl 
		if(self.pageCtrl == nil) then
			NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
			self.pageCtrl = Map3DSystem.mcml.PageCtrl:new({
				url = self.url,
				OnPageDownloaded = string.format("Map3DSystem.mcml.BrowserWnd.OnPage_CallBack(%q)", self.name),
				window = self.window,
			});
		end	
		self.pageCtrl:Create(self.name.."_pageCtrl", _parent, "_fi", 0, top, 0, 0);
		UICreated = true;
	else
		if(bShow == nil) then
			bShow = (_this.visible == false);
		end
		_this.visible = bShow;
	end	
	return UICreated;
end

--------------------------------------
-- public method
--------------------------------------

-- go to a given url, refresh
-- @param url: if nil it will clear the browser. it can also be string "backward", "forward" which opens last page and forward page. 
function BrowserWnd:Goto(url, cache_policy, bRefresh)
	if(self.pageCtrl~= nil) then
		self.pageCtrl:Goto(url, cachePolicy, bRefresh);
	end
end

-- return nil or current url 
function BrowserWnd:GetUrl()
	if(self.pageCtrl~= nil) then
		return self.pageCtrl.url;
	else
		return self.url
	end
end

-- show or hide the nav bar on top. 
function BrowserWnd:ShowNavBar(bShow)
	if(self.DisplayNavBar ~= bShow) then
		self.DisplayNavBar = bShow;
		ParaUI.GetUIObject(self.name.."navBar").visible = bShow
		--if(self.pageCtrl) then
			--local top = 0;
			--if(bShow)then
				--top = 32;
			--end
			--commonlib.echo({ParaUI.GetUIObject(self.name.."_pageCtrl"):IsValid(), top})
			--ParaUI.GetUIObject(self.name.."_pageCtrl"):Reposition("_fi", 0, top, 0, 0);
			--self.pageCtrl:Refresh(0)
		--end	
	end
end

-- show or hide the nav address bar on top. 
function BrowserWnd:ShowAddressBar(bShow)
	if(self.DisplayNavAddress~=bShow) then
		self.DisplayNavAddress = bShow;
		ParaUI.GetUIObject(self.name.."navBar"):GetChild("navAddressBar").visible = bShow
	end
end
--------------------------------------
-- private method and event handlers
--------------------------------------

-- load history test files
function BrowserWnd:UpdateHistoryFiles()
	local ctl = CommonCtrl.GetControl(self.name.."comboBoxAddress");
	if(ctl==nil)then
		log("error getting instance "..self.name.."comboBoxAddress".."\r\n");
		return;
	end
	
	if(ParaIO.DoesFileExist(self.historyFileName, true)) then
		ctl.items = commonlib.LoadTableFromFile(self.historyFileName) or {};
		ctl:RefreshListBox();
	end
end

-- save recently opened file to history
function BrowserWnd:SaveToHistoryFile(url)
	local ctl = CommonCtrl.GetControl(self.name.."comboBoxAddress");
	if(ctl~=nil)then
		local index = ctl:InsertItem(url)
		log("saving file to "..self.historyFileName.."\n")	
		if(index) then
			-- save to file
			if(index>1) then
				-- shuffle selected to front
				commonlib.moveArrayItem(ctl.items, index, 1)
			end	
			if(table.getn(ctl.items)>self.max_history_items) then
				commonlib.resize(ctl.items, self.max_history_items);
			end	
			commonlib.SaveTableToFile(ctl.items, self.historyFileName);
		else
			log("error: saving file to "..self.historyFileName.."\n")	
		end
	end
end

-- called when a new page is downloaded.
function BrowserWnd.OnPage_CallBack(sCtrlName)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting BrowserWnd instance "..sCtrlName.."\r\n");
		return;
	end
	self:SaveToHistoryFile(self:GetUrl())
	local ctl = CommonCtrl.GetControl(self.name.."comboBoxAddress");
	if(ctl)then
		ctl:SetText(self:GetUrl());
	end
end

-- replace the context in this window with input mcmlNode. 
-- @param mcmlNode: must be a raw mcmlNode, such as from a url or local server. 
function BrowserWnd:open(mcmlNode)
	if(self.pageCtrl) then
		self:ShowMessage(nil);
		self.pageCtrl:Init(mcmlNode, nil, true)
	end	
end

-- show a message to inform the user about a background action or status. 
-- @param text: string or nil. if nil, it will clear the message box. 
function BrowserWnd:ShowMessage(text)
	-- TODO: use a child window to display, such as in firefox. Currently just a plain popup message box. 
	--paraworld.ShowMessage(text)
	if(text == nil) then
		_guihelper.CloseMessageBox()
	else	
		_guihelper.MessageBox(text);
	end	
end


-- call back function. This function is called by MCMLBrowserWnd whenever OnClose Windows message is received. 
-- @param bDestroy:
function BrowserWnd:OnClose(bDestroy)
	if(self.pageCtrl and self.pageCtrl.OnClose) then
		self.pageCtrl:OnClose(bDestroy);
	end
end

-- navigate to last url
function BrowserWnd.OnClickNavBackward(sCtrlName)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting BrowserWnd instance "..sCtrlName.."\r\n");
		return;
	end
	self:Goto("backward");
end


-- navigate to next url
function BrowserWnd.OnClickNavForward(sCtrlName)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting BrowserWnd instance "..sCtrlName.."\r\n");
		return;
	end
	self:Goto("forward");
end

-- navigate to the current url in combo box
function BrowserWnd.OnClickNavTo(sCtrlName)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting BrowserWnd instance "..sCtrlName.."\r\n");
		return;
	end
	
	local ctl = CommonCtrl.GetControl(self.name.."comboBoxAddress");
	if(ctl)then
		local url = ctl:GetText();
		if(url) then
			self:Goto(url)
		end
	end
end

-- do not use cached version and refresh 
function Map3DSystem.mcml.BrowserWnd.OnClickNavRefresh(sCtrlName)
	local self = CommonCtrl.GetControl(sCtrlName);
	if(self==nil)then
		log("error getting BrowserWnd instance "..sCtrlName.."\r\n");
		return;
	end
	self:Goto(self:GetUrl(), System.localserver.CachePolicy:new("access plus 0"), true)
end

