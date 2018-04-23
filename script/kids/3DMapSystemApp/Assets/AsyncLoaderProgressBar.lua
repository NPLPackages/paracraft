--[[
Title: Asyncloader Progress bar
Author(s): LiXizhi
Date: 2009/9/23
Desc: Display a rotating image and text with the number of items left in the async loader queue. 
Usually there is one global instance of the progress bar to inform user about the background asset loading progress. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AsyncLoaderProgressBar.lua");
local AsyncLoaderProgressBar = commonlib.gettable("Map3DSystem.App.Assets.AsyncLoaderProgressBar");
local ctl = AsyncLoaderProgressBar:new{
	name = "DefaultAsyncLoaderProgressBar",
	alignment = "_ct",
	left = -32,
	top = -180,
	width = 64,
	height = 64,
	zorder = 2010,
	parent = nil,
};
ctl:Show(true);

-- handy function 
Map3DSystem.App.Assets.AsyncLoaderProgressBar.CreateDefaultAssetBar(true);
Map3DSystem.App.Assets.AsyncLoaderProgressBar.CreateDefaultAssetBar(true, "_ct", -80, -60, 32, 160);

-- To test the UI, simply uncomment -- return 1234; in GetDownloadSpeed() function
-------------------------------------------------------
]]

local AsyncLoaderProgressBar = commonlib.createtable("Map3DSystem.App.Assets.AsyncLoaderProgressBar", {
	-- name 
	name = "DefaultAsyncLoaderProgressBar",
	-- layout
	alignment = "_ct",
	left = -32,
	top = -180,
	width = 64,
	height = 64,
	zorder = 2010,
	parent = nil,
	
	-- this is text format to display. it must contain %d to include the {item left} in the text. 
	textformat = "%s\n%dKB/s",
	-- the private timer
	timer = nil;
	-- how often (milliseconds) to check for new loader progress with the game engine.
	interval = 500,
	-- fade in /fade out animation length in milliseconds
	fade_in_out_anim_interval = 200,
	-- time in ms that downloader is downloading. 
	download_duration = 0,
	-- time remained in seconds. 
	remaining_time = 0,

	image_layout = {
		align = "_lt",
		left = 0,
		top = 0,
		width = 64,
		height = 64,
		--background = "Texture/Aquarius/Common/Waiting_32bits.png; 0 0 24 24",
		background = "Texture/Aries/Common/AssetLoader_32bits.png",
		animstyle = 47,
	},
	text_layout = {
		align = "_lt",
		left = 0,
		top = 48,
		width = 300,
		height = 60,
		font = "System;13;bold",
		-- text scaling
		scaling = 1.05,
		shadow = true, 
		color = "157 255 155",
	},
});

-- create a new asset. the asset's filename must not be nil. 
function AsyncLoaderProgressBar:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function AsyncLoaderProgressBar:Destroy()
	ParaUI.Destroy(self.name);
end

local  DefaultAssetBar;
-- Handy function: a default bar showing at the center of the screen. 
-- @param bShow: true to show, false to destroy. 
-- @param alignment, left, top, width, height: optional
function AsyncLoaderProgressBar.CreateDefaultAssetBar(bShow, alignment, left, top, width, height)
	if(not DefaultAssetBar) then
		local self = AsyncLoaderProgressBar;
		self.alignment = alignment or self.alignment;
		self.left = left or self.left;
		self.top = top or self.top;
		self.width = width or self.width;
		self.height = height or self.height;
		DefaultAssetBar = Map3DSystem.App.Assets.AsyncLoaderProgressBar:new{
			name = "DefaultAsyncLoaderProgressBar",
			alignment = alignment,
			left = left,
			top = top,
			width = width,
			height = height,
			parent = nil,
		};
	end

	if(DefaultAssetBar~=false) then
		DefaultAssetBar:Show(true);
		DefaultAssetBar:Reposition()
	else	
		DefaultAssetBar:Destroy();
	end	
end

-- return nil if default asset bat is not created yet. 
function AsyncLoaderProgressBar.GetDefaultAssetBar()
	return DefaultAssetBar;
end

-- this allow us to temporarily change the position to avoid UI intervening. 
function AsyncLoaderProgressBar:Reposition(alignment, left, top, width, height)
	local _this = ParaUI.GetUIObject(self.name);
	if(_this:IsValid())then
		local changed_ = ((alignment and self.alignment ~= alignment) or 
			(left and self.left ~= left) or
			(top and self.top ~= top) or
			(width and self.width ~= width) or
			(height and self.height ~= height));
		if( self.changed_ or changed_) then
			self.changed_ = changed_;
			_this:Reposition(alignment or self.alignment, left or self.left, top or self.top, width or self.width, height or self.height);
			LOG.std(nil, "debug", "AsyncLoaderProgressBar", "UI control pos changed");
		else
			self.changed_ = nil;
		end
		-- echo({"AsyncLoaderProgressBar", changed_, alignment, left, top, width, height});
	else
		LOG.std(nil, "warn", "AsyncLoaderProgressBar", "UI control is not found");
	end
end

-- it will automatically change the skin even after the UI is already created. 
function AsyncLoaderProgressBar:RefreshStyle()
	local _this = ParaUI.GetUIObject(self.name)
	if(_this:IsValid()) then
		local bIsVisible = _this.visible;
		ParaUI.Destroy(self.name);
		self:Show(bIsVisible);
	end
end

function AsyncLoaderProgressBar:Show(bShow)
	local _this,_parent;
	if(self.name == nil)then
		log("AsyncLoaderProgressBar instance name can not be nil \n");
		return;
	end
	
	_this = ParaUI.GetUIObject(self.name);
	if(_this:IsValid() == false)then
		_this = ParaUI.CreateUIObject("container",self.name,self.alignment,self.left,self.top,self.width,self.height);
		_this.background = "";
		_this.zorder = self.zorder;
		_this.enabled = false; -- disable it
		_this.visible = false;
		_parent = _this;
		
		if(self.parent == nil)then
			_this:AttachToRoot();
		else
			self.parent:AddChild(_this);
		end
		
		CommonCtrl.AddControl(self.name,self);
		
		_this = ParaUI.CreateUIObject("button","b",self.image_layout.align,self.image_layout.left,self.image_layout.top,self.image_layout.width,self.image_layout.height);
		_this.background = self.image_layout.background;
		_this.animstyle = self.image_layout.animstyle;
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("text","text",self.text_layout.align,self.text_layout.left,self.text_layout.top,self.text_layout.width,self.text_layout.height);
		_this.font = self.text_layout.font;
		_this.textscale = self.text_layout.scaling;
		_this.shadow = self.text_layout.shadow;
		_this:GetFont("text").color = _guihelper.ConvertColorToRGBAString(self.text_layout.color);
		_parent:AddChild(_this);


		-- define some fade in/out animation 
		NPL.load("(gl)script/ide/Transitions/TweenLite.lua");
		self.fadein_tween = CommonCtrl.TweenLite:new{
			instance_id = self.name,
			duration = self.fade_in_out_anim_interval,-- millisecond
			ApplyAnim = true,
			props = {alpha = 1,},
		}
		self.fadeout_tween = CommonCtrl.TweenLite:new{
			instance_id = self.name,
			duration = self.fade_in_out_anim_interval,-- millisecond
			props = {alpha = 0,},
			ApplyAnim = true,
			OnEndFunc = function(self)
				ParaUI.GetUIObject(self.instance_id).visible = false;
			end,
		}
				
		if(self.timer == nil) then
			NPL.load("(gl)script/ide/timer.lua");
			self.timer = commonlib.Timer:new({callbackFunc = function(timer)
				self:OnTimer(timer);	
			end})	
		end
		
		-- start the timer after 0 milliseconds
		self.timer:Change(self.interval, self.interval);
	
	else
		if(bShow == nil) then
			_this.visible = not _this.visible;
		else
			_this.visible = bShow;
		end		
	end
end

-- called every 0.5 seconds. 
function AsyncLoaderProgressBar:OnTimer(timer)
	self:UpdateDownloadSpeed();
	self:Update();
end

if(not ParaEngine.GetAsyncLoaderBytesReceived) then
	ParaEngine.GetAsyncLoaderBytesReceived = function() return 0 end;
end

-- call this function at small interval regularly to update download speed. 
function AsyncLoaderProgressBar:UpdateDownloadSpeed()
	local cur_time = ParaGlobal.timeGetTime();
	if(self.last_tick_time and self.last_tick_bytes) then
		local delta_time = cur_time - self.last_tick_time
		-- interval should be over 1 second. 
		if( delta_time > 1000) then
			local current_bytes = ParaEngine.GetAsyncLoaderBytesReceived(-1);
			local delta_bytes = current_bytes - self.last_tick_bytes;
			self.download_speed = delta_bytes / (delta_time * 0.001);
			self.last_tick_time = cur_time;
			self.last_tick_bytes = self.current_bytes;
			self.current_bytes = current_bytes;
			local remaining_bytes = ParaEngine.GetAttributeObject():GetField("AsyncLoaderRemainingBytes", 0);
			if(remaining_bytes == self.remaining_bytes) then
				self.remaining_bytes_real = (self.remaining_bytes_real or remaining_bytes) - delta_bytes;
				if(self.remaining_bytes_real < 0) then
					self.remaining_bytes_real = self.remaining_bytes;
				end
			else
				self.remaining_bytes = remaining_bytes;
				self.remaining_bytes_real = remaining_bytes;
			end
			-- echo({self.remaining_bytes, self.remaining_bytes_real, delta_bytes, current_bytes})

			if(self.download_speed>0 or self.remaining_bytes>0) then
				if(self.start_download_time) then
					self.download_duration = cur_time - self.start_download_time;
				else
					self.start_download_time = cur_time;
				end
				local nRemainingBytes = self:GetRemainingBytes();
				if(nRemainingBytes > 0) then
					if(self.download_speed>0) then
						self.remaining_time = nRemainingBytes / self.download_speed;
					else
						self.remaining_time = -1;
					end
				end
			else
				self.start_download_time = nil;
				self.download_duration = 0;
				self.remaining_time = 0;
			end
		end
	else
		self.last_tick_time = cur_time;
		self.last_tick_bytes = ParaEngine.GetAsyncLoaderBytesReceived(-1);
	end
	return self.download_speed or 0;
end

-- get download speed. 
function AsyncLoaderProgressBar:GetDownloadSpeed()
	return self.download_speed or 0;
	--return 1234;
end

-- remaning bytes. 
function AsyncLoaderProgressBar:GetRemainingBytes()
	return self.remaining_bytes_real or self.remaining_bytes or 0;
end
-- get total download bytes. 
function AsyncLoaderProgressBar:GetTotalDownloadBytes()
	return self.current_bytes or 0;
end

local last_index = 1;
-- update the user interface according to current value. 
function AsyncLoaderProgressBar:Update()
	local _this = ParaUI.GetUIObject(self.name);
	if(not _this:IsValid())then
		if(self.timer) then
			-- delete the timer
			self.timer:Change();
		end	
		self.timer = nil;
		return;
	end
	
	local nItemLeft = ParaEngine.GetAsyncLoaderItemsLeft(-2);
		
	-- this just test code
	--local samples = {5,4,3,2,1,0,0,0,0,0,1,2,3}
	--last_index = last_index + 1
	--if(last_index >= 13)  then
		--last_index = 1;
	--end
	--nItemLeft = nItemLeft + samples[last_index]
	local nDownloadSpeed = self:GetDownloadSpeed();
	local nRemainingBytes = self:GetRemainingBytes();
	if(nItemLeft > 0 or self.download_duration>2000) then
		local remain_count_str = "";
		if(nRemainingBytes > 1000) then
			remain_count_str = string.format("%.2fMB", nRemainingBytes*0.000001);
		elseif(nRemainingBytes > 0) then
			remain_count_str = string.format("%.3fMB", nRemainingBytes*0.000001);
		else
			remain_count_str = tostring(nItemLeft).."个";
		end
		local text = string.format(self.textformat, remain_count_str, math.floor(nDownloadSpeed*0.001+0.5));
		if(self.remaining_time > 600) then
			text = string.format(L"%s\n预计%.1f分钟后完成\n首次需下载, 请耐心等待", text, self.remaining_time/60);
			if(nDownloadSpeed < 50000) then
				text = string.format("%s\n%s", text, L"您的网速很慢, 请关闭其他网页或下载进程");
			end
		elseif(self.remaining_time > 60) then
			text = string.format(L"%s\n预计%.1f分钟后完成", text, self.remaining_time/60);
		elseif(self.remaining_time >= 5) then
			text = string.format(L"%s\n预计%d秒后完成", text, math.floor(self.remaining_time));
		elseif(self.remaining_time < 0) then
			text = string.format(L"%s\n您的网速很慢, 请关闭其他网页或下载进程", text);
		end
		_this:GetChild("text").text = text;
		
		self.fadeout_tween:Pause();
		if(not _this.visible or (self.fadein_tween:IsPaused() and _this.colormask ~= "255 255 255 255")) then
			_this.visible = true;
			_this.colormask = "255 255 255 0";
			_this:ApplyAnim();
			-- play a fade in animation here
			self.fadein_tween:Start();
		end
	else
		self.fadein_tween:Pause();
		if(_this.visible) then
			-- play a fade out animation here. 
			if(not self.fadeout_tween:IsPlaying()) then
				_this.colormask = "255 255 255 255";
				_this:ApplyAnim();
				self.fadeout_tween:Start();
			end	
		end	
	end
end
