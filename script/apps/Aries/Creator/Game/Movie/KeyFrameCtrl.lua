--[[
Title: for rendering keyframes in a timeline
Author(s): LiXizhi
Date: 2014/4/6
Desc: rendering keyframes in a timeline
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFrameCtrl.lua");
local KeyFrameCtrl = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFrameCtrl");
local ctl = KeyFrameCtrl:new({
	name = "KeyFrameCtrl",
	onclick_frame = function(time)
	end, 
})
-------------------------------------------------------
]]
local KeyFrameCtrl = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFrameCtrl");

local tostring = tostring;
local math_floor = math.floor;

KeyFrameCtrl.start_time = 0;
KeyFrameCtrl.key_button_width = 8;
KeyFrameCtrl.key_button_height = 12;
KeyFrameCtrl.key_button_background = "Texture/whitedot.png";
-- white grey: standard keyframe
KeyFrameCtrl.key_button_color = "#808080";
-- light blue: this is more like a bookmark position of user's last click on timeline. 
KeyFrameCtrl.key_button_color_lastclick = "#00ffffc0";
KeyFrameCtrl.key_button_background_lastclick = "Texture/Aries/Creator/imageboarder.png:3 3 3 3";

-- red denotes current time frame
KeyFrameCtrl.key_button_color_curtime = "#ff0000c0";
KeyFrameCtrl.key_button_curtime_width = 2;
-- when key is being shifted
KeyFrameCtrl.key_button_color_shifting = "#ff0000ff"
KeyFrameCtrl.width = 512;
KeyFrameCtrl.height = 12;
-- callback function(time) end
KeyFrameCtrl.onclick_frame = nil;
-- callback function(shift_begin_time, offset_time)
KeyFrameCtrl.onshift_keyframe = nil;
-- callback function(keytime)
KeyFrameCtrl.onremove_keyframe = nil;
-- callback function(keytime, from_keytime)
KeyFrameCtrl.oncopy_keyframe = nil;
-- callback function(keytime, from_keytime)
KeyFrameCtrl.onmove_keyframe = nil;
-- whether to show data on tooltip
KeyFrameCtrl.isShowDataOnTooltip = false;

-- create a new object
-- @param o: {name="my_texture_grid"}
function KeyFrameCtrl:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self;

	-- instance of TimeSeries/AnimBlock.lua
	o.variable = nil; 
	-- the center of the viewpoint. 
	o.x = o.x or 0;
	o.y = o.y or 0;
	o.name = o.name or "KeyFrameCtrl";
	o.width = o.width or 512;
	o.height = o.height or 16;
	return o
end

-- clear all objects
function KeyFrameCtrl:clear()
	self.variable = nil;
end

-- clip the texture using a rectangular shape
-- this is the single most important function to clip and draw to the render target
-- @param left, top, right, bottom: or in logics units
function KeyFrameCtrl:clip(left, top, right, bottom)
	self.left, self.top, self.right, self.bottom = left, top, right, bottom;
end

--@param variable: instance of TimeSeries/AnimBlock.lua
function KeyFrameCtrl:SetVariable(variable)
	if(self.variable ~= variable) then
		self.variable = variable;
		self:OnEndShiftFrame(false);
	end
end

function KeyFrameCtrl:GetVariable()
	return self.variable;
end

function KeyFrameCtrl:GetValue(time)
	if(self.variable) then
		return self.variable:getValue(1, time);
	end
end

function KeyFrameCtrl:SetStartTime(time)
	self.start_time = time or 0;
end

function KeyFrameCtrl:GetStartTime()
	return self.start_time;
end

-- in ms seconds
function KeyFrameCtrl:SetEndTime(time)
	self.end_time = time or 0;
end

function KeyFrameCtrl:GetLength()
	return self:GetEndTime() - self:GetStartTime();
end

function KeyFrameCtrl:GetEndTime()
	if(self.end_time) then
		return self.end_time;
	elseif(self.variable) then
		return self.variable:GetLastTime() or 0;
	else
		return 0;
	end
end

-- whether time is inside the view
function KeyFrameCtrl:intersect(time)
	-- TODO: since we are showing all times, it will always return true.
    return true;
end

function KeyFrameCtrl:OnClickKeyFrame(uiobj)
	if(uiobj) then
		local time_index = tonumber(uiobj.name);
		local time = self:GetTimeFromUIObj(uiobj);
		if(time) then
			local shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
			local alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
			if(time_index) then
				if(shift_pressed and time and self.onremove_keyframe) then
					-- shift click to remove key
					self.onremove_keyframe(time);
					return;
				end
			end

			if(not shift_pressed and time_index and not self.is_shifting and mouse_button == "left") then
				-- left click to begin shift move all keys after current one. 
				self.single_shift = nil;
				self.single_copy = nil;
				if(alt_pressed) then
					self.single_shift = true;
				elseif(ctrl_pressed) then
					self.single_copy = true;
				end
				self:OnBeginShiftFrame(time, uiobj.x);
			else
				-- right click to goto that frame. 
				if(time and self.onclick_frame) then
					self.onclick_frame(time);
				end
			end
		end
	end
end

-- shift all key frames
function KeyFrameCtrl:OnBeginShiftFrame(time, ui_x)
	local _parent = self:GetParent();
	if(time and _parent and _parent:IsValid()) then
		self.is_shifting = true;
		self.shift_begin_time = time;
		self.shift_begin_ui_x = ui_x;

		local ui_obj_name = "shift_click_canvas";
		local ui_obj = _parent:GetChild(ui_obj_name);
		if(not ui_obj:IsValid()) then
			ui_obj = ParaUI.CreateUIObject("container",ui_obj_name, "_fi", 0, 0, 0, 0);
			ui_obj.zorder = 10;
			ui_obj.background = "";
			ui_obj:SetScript("onmousedown", function(uiobj)
				if(mouse_button == "right") then
					self:OnEndShiftFrame();
				else
					self:OnEndShiftFrame(true);
				end
			end)
			ui_obj:SetScript("onframemove", function()
				self:OnFrameMoveShifting();
			end);
			_parent:AddChild(ui_obj);
		end
		ui_obj.enabled = true;
		ui_obj.visible = true;
	end
end

function KeyFrameCtrl:OnFrameMoveShifting()
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local _parent = self:GetParent();
	if(_parent and _parent:IsValid()) then
		local x, y, width, height = _parent:GetAbsPosition();
		self.shift_ui_x_offset = math.floor((mouse_x-self.key_button_width/2)-x - self.shift_begin_ui_x);
		self:Update();
	end
end

-- @param bIsOK:true to perform the final shift operation. otherwise cancel it. 
function KeyFrameCtrl:OnEndShiftFrame(bIsOK)
	if(not self.is_shifting) then
		return;
	end
	self.is_shifting = false;
	local _parent = self:GetParent();
	if(_parent and _parent:IsValid()) then
		local ui_obj_name = "shift_click_canvas";
		local ui_obj = _parent:GetChild(ui_obj_name);
		ui_obj.visible = false;
		ui_obj.enabled = false;
	end
	if(bIsOK and self.shift_ui_x_offset) then
		-- do the shifting
		local new_time = self:GetKeyTimeByUIPos(self.shift_ui_x_offset+self.shift_begin_ui_x) -- -self.key_button_width/2
		local offset_time = new_time - self.shift_begin_time;
		
		if(self.single_shift) then
			if(self.onmove_keyframe) then
				self.onmove_keyframe(new_time, self.shift_begin_time);
			end
		elseif(self.single_copy) then
			if(self.oncopy_keyframe) then
				self.oncopy_keyframe(new_time, self.shift_begin_time);
			end
		else
			if(self.onshift_keyframe) then
				self.onshift_keyframe(self.shift_begin_time, offset_time);
			end
		end
	end
	self.single_shift = nil;
	self.single_copy = nil;
end

-- @param value: if nil, it will be set value
function KeyFrameCtrl:SetUIObjTooltip(ui_obj, time, value)
	if(not value and self.isShowDataOnTooltip) then
		value = self:GetValue(time);
	end
	local tooltip;
	if(not value) then
		tooltip = format("%d", time);
	else
		if(type(value) == "table") then
			tooltip = format("%d:%s", time, commonlib.serialize_compact(value));
		else
			tooltip = format("%d:%s", time, tostring(value));
		end
	end
	ui_obj.tooltip = format("%s\n%s", tooltip or "", L"右键选;左键移;Shift左:删;Alt左:单移;Ctrl左:复制");
end

function KeyFrameCtrl:GetTimeFromUIObj(ui_obj)
	local tooltip = ui_obj.tooltip or "";
	local time = tooltip:match("^%d+");
	if(time) then
		return tonumber(time);
	end
end

-- get time and ui_x from relative mouse position. It will automatically snap to closest key time. 
-- @param rx: relative x pixel
-- @return time, ui_x: key time and corrected ui_x position. 
function KeyFrameCtrl:GetKeyTimeByUIPos(rx)
	local _parent = self:GetParent();
	local x, y, width, height = _parent:GetAbsPosition();
	local totalTime = math.max(1, self:GetLength());
	
	local key_button_width = self.key_button_width;
	local time = math_floor((rx)/(width-key_button_width)*totalTime);
	time = self:GetStartTime() + math.max(math.min(totalTime, time),0)
	
	-- check to see if we are clicking close to keyframe, 
	-- if so, we will goto the frame next to the keyframe. 
	local nUIIndex = 0;
	local ui_obj;
	local ui_obj_name;

	local ui_x;
	local bFinished = false;
	while(not bFinished) do
		ui_obj_name = tostring(nUIIndex);
		ui_obj = _parent:GetChild(ui_obj_name);
		if(ui_obj:IsValid() and ui_obj.visible) then
			local x = ui_obj.x;
			if(rx < x and (rx+key_button_width)>x) then
				time = self:GetTimeFromUIObj(ui_obj) - 1;
				ui_x = x - key_button_width;
				bFinished = true;
			elseif(x < rx and (x+key_button_width*2)>rx) then
				time = self:GetTimeFromUIObj(ui_obj) + 1;
				ui_x = x + key_button_width;
			end
		else
			bFinished = true;
		end
		nUIIndex = nUIIndex + 1;
	end
	return time, ui_x;
end

-- goto a given frame by clicking on the blanck space. .
-- if we are clicking close to keyframe, we will goto the frame next to the keyframe. 
function KeyFrameCtrl:OnClickTimeLine(uiobj)
	if(uiobj) then
		local x, y, width, height = uiobj:GetAbsPosition();
		local rx = mouse_x - x;
		local time, ui_x = self:GetKeyTimeByUIPos(rx);

		if(time and self.onclick_frame) then
			self:UpdateLastClickFrame(time, ui_x)
			self.onclick_frame(time);
		end
	end
end

-- @param ui_x: force using the given x position 
function KeyFrameCtrl:UpdateLastClickFrame(time, ui_x)
	local _parent = self:GetParent();
	if(time and _parent and _parent:IsValid()) then
		local key_button_width = self.key_button_width;

		local ui_obj_name = "lastclick";
		local ui_obj = _parent:GetChild(ui_obj_name);
		if(not ui_obj:IsValid()) then
			ui_obj = ParaUI.CreateUIObject("button",ui_obj_name, "_lt", 0, 0, key_button_width,self.key_button_height or self.height);
			ui_obj.zorder = -1;
			ui_obj.background = self.key_button_background_lastclick;
			_guihelper.SetUIColor(ui_obj, self.key_button_color_lastclick);
			ui_obj:SetScript("onclick", function(uiobj)
				self:OnClickKeyFrame(uiobj);
			end)
			_parent:AddChild(ui_obj);
		end	
		if(not ui_x) then
			local totalTime = math.max(1, self:GetLength());
			local frame_width = (self.width-key_button_width) / totalTime;
			ui_x = math_floor((time-self:GetStartTime()) * frame_width);
		end
		self:SetUIObjTooltip(ui_obj, time, nil);
		ui_obj.x = ui_x;
	end
end

function KeyFrameCtrl:UpdateAndGetParent(_parent, width, height)
	if(width) then
		self.width = width;
	end
	if(height) then
		self.height = height;
	end
	width, height = width or self.width, height or self.height;
	
	if(not _parent) then
		_parent = self:GetParent();
		return _parent, width, height;
	end
	if(_parent) then
		local tex_cont = _parent:GetChild(self.name)
		if(not tex_cont:IsValid()) then
			tex_cont = ParaUI.CreateUIObject("container",self.name, "_lt", 0, 0, width, height);
			tex_cont.background = "";
			tex_cont.fastrender = false;
			tex_cont:SetScript("onmousedown", function(uiobj)
				self:OnClickTimeLine(uiobj);
			end);
			_parent:AddChild(tex_cont);
		end
		tex_cont.x = 0;
		tex_cont.y = 0;
		tex_cont.width = width;
		tex_cont.height = height;
		_parent = tex_cont;
	end
	self.parent = _parent;
	return _parent, width, height;
end

function KeyFrameCtrl:GetParent()
	return self.parent;
end

-- @param bSnapToGrid: [not implemented] whether to snap to closest keyframe grid. 
function KeyFrameCtrl:UpdateCurrentTime(curTime, bSnapToGrid)
	local _parent = self:GetParent();
	if(_parent and _parent:IsValid()) then
		local key_button_width = self.key_button_width;
		local totalTime = math.max(1, self:GetLength() or 1);
		local frame_width = (self.width-key_button_width) / totalTime;

		if(not self.btn_curtime or not self.btn_curtime:IsValid()) then
			local ui_obj = ParaUI.CreateUIObject("button","curtime", "_lt", 0, 0, self.key_button_curtime_width,self.key_button_height or self.height);
			ui_obj.enabled = false;
			ui_obj.zorder = 1;
			ui_obj.background = self.key_button_background;
			_guihelper.SetUIColor(ui_obj, self.key_button_color_curtime);
			_parent:AddChild(ui_obj);
			self.btn_curtime = ui_obj;
		end
		
		local x = math_floor((curTime-self:GetStartTime()) * frame_width);
		
		if(bSnapToGrid) then
			-- TODO: 
			self.btn_curtime.x = x;
		else
			self.btn_curtime.x = x;
		end
	end
end

-- @param parent: if nil, it will use last one. 
-- @param width, height: if nil, it will be self.width, self.height. 
function KeyFrameCtrl:Update(_parent, width, height)
	local _parent, width, height = self:UpdateAndGetParent(_parent, width, height);

	if(not _parent) then
		return;
	end

	local nUIIndex = 0;
	local ui_obj;
	local ui_obj_name;
	
	local name, obj;
		
	local totalTime = math.max(1, self:GetLength() or 1);
	local variable = self:GetVariable();

	local key_button_width = self.key_button_width;
	local frame_width = (width-key_button_width) / totalTime;
	local start_time = self:GetStartTime();
	local end_time = self:GetEndTime();
	if(variable and variable.GetKeys_Iter) then
		
		local last_x = -key_button_width;
		local single_mode = self.single_shift or self.single_copy;
		for time, value in variable:GetKeys_Iter(1, start_time-1, end_time) do
			if( start_time <= time and time<=end_time ) then	
				ui_obj_name = tostring(nUIIndex);
				ui_obj = _parent:GetChild(ui_obj_name);
				if(not ui_obj:IsValid()) then
					ui_obj = ParaUI.CreateUIObject("button",ui_obj_name, "_lt", 0, 0, key_button_width,self.key_button_height or self.height);
					_parent:AddChild(ui_obj);
					ui_obj:SetScript("onclick", function(uiobj)
						self:OnClickKeyFrame(uiobj);
					end)
				end
				local x = math_floor((time-start_time) * frame_width);
				if((last_x + key_button_width) >= x) then
					x = last_x + key_button_width;
				end
				last_x = x;

				ui_obj.background = self.key_button_background;
				ui_obj.visible = true;
				self:SetUIObjTooltip(ui_obj, time, nil);
				
				if(self.is_shifting and self.shift_ui_x_offset and 
					(not single_mode and self.shift_begin_time <= time) or (single_mode and self.shift_begin_time==time) ) then
					ui_obj.x = x + self.shift_ui_x_offset;
					_guihelper.SetUIColor(ui_obj, self.key_button_color_shifting);
				else
					ui_obj.x = x;
					_guihelper.SetUIColor(ui_obj, self.key_button_color);
				end
				
				nUIIndex = nUIIndex + 1;
			end
		end
	end 
	
	-- here we will remove all objects. 
	local bFinished = false;
	while(not bFinished) do
		ui_obj_name = tostring(nUIIndex);
		ui_obj = _parent:GetChild(ui_obj_name);
		if(ui_obj:IsValid() and ui_obj.visible) then
			ui_obj.visible = false;
			nUIIndex = nUIIndex + 1;
		else
			bFinished = true;
		end
	end
end