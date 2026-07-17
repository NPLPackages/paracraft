--[[
Title: Head-on Number Effect
Author(s): LiXizhi
Date: 2025/11/26
Desc: Show an animated number (text) above a 3D position or entity. The number will move up and fade out.
Usage:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/HeadOnNumberEffect.lua");
local HeadOnNumberEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.HeadOnNumberEffect");
HeadOnNumberEffect.ShowNumberAtEntity(GameLogic.EntityManager.GetPlayer(), "+10 Exp", "#00ff00ff", 1200);
HeadOnNumberEffect.ShowNumberAtEntity(GameLogic.EntityManager.GetPlayer(), "-10", "#ff0000", 1200, {fontsize=24, shadow=true, move_up=80});
HeadOnNumberEffect.ShowNumberAtUI({x=300, y=200}, "+100", "#00ff00", 1000);
HeadOnNumberEffect.ShowNumberAtUI("ui_name", "+100", "#00ff00", 1000);
--------------------------------------------------------
]]

NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");
local mathlib = commonlib.gettable("mathlib");

local HeadOnNumberEffect = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.HeadOnNumberEffect"));

function HeadOnNumberEffect:ctor()
	-- defaults
	self.text = self.text or "";
	self.duration = self.duration or 1200; -- milliseconds
	self.move_up = self.move_up or 50; -- pixels to move up
	if(self.fontsize and not self.font) then
		self.font = string.format("System;%d;bold", self.fontsize);
	end
	self.font = self.font or "System;20;bold";
	self.color = self.color or "#ffffffff";
	self.width = self.width or 200;
	self.height = self.height or 28;
	self.alignment = self.alignment or "_lt";
	self.shadow = (self.shadow == nil) and true or self.shadow;
end

-- convert 3d position (table with x,y,z or bx,by,bz) to screen 2d screen coords
function HeadOnNumberEffect:Convert3Dto2D(from_3d)
	if(not from_3d) then return end
	if(not from_3d.x) then
		if(from_3d.bx) then
			-- convert block to real coords
			local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
			from_3d.x, from_3d.y, from_3d.z = BlockEngine:real(from_3d.bx, from_3d.by, from_3d.bz);
		else
			-- fallback to player pos
			local px, py, pz = ParaScene.GetPlayer():GetPosition();
			from_3d.x, from_3d.y, from_3d.z = px, py, pz;
		end
	end
	if(from_3d.x) then
		local screen_pos = {};
		ParaScene.GetScreenPosFrom3DPoint(from_3d.x, from_3d.y, from_3d.z, screen_pos);
		return screen_pos;
	end
end

function HeadOnNumberEffect:Prepare()
	if(not self.from_2d) then
		self.from_2d = self:Convert3Dto2D(self.from_3d);
	end
	-- validate
	if(self.from_2d and self.from_2d.x and self.from_2d.y) then
		return true
	end
end

-- create ui text object, return id
function HeadOnNumberEffect:CreateUI()
	local x = (self.from_2d.x or 0) - (self.width or 200)/2;
	local y = (self.from_2d.y or 0) - (self.height or 28)/2;
	local _this = ParaUI.CreateUIObject("text", "HeadOnNumberEffect", self.alignment or "_lt", x, y, self.width or 200, self.height or 28);
	_this.enabled = false;
	_this.autosize = false;
	_this.font = self.font;
	_this.text = tostring(self.text or "");
	_this.background = "";
	if(self.shadow) then _this.shadow = true end
	-- set font color
	if(type(_guihelper)~="nil" and self.color) then
		_guihelper.SetFontColor(_this, self.color);
	else
		_this:GetFont("text").color = self.color or "255 255 255";
	end
	-- center align
	_this:GetFont("text").format = 1+16; -- center
	_this:AttachToRoot();
	return _this.id;
end

-- Play the effect. optional start_time for delayed play (ms)
function HeadOnNumberEffect:Play(start_time)
	if(start_time and start_time>0) then
		UIAnimManager.PlayCustomAnimation(start_time, function(elapsedTime)
			if(elapsedTime == start_time) then
				self:Play();
			end
		end, nil, start_time)
		return
	end

	if(not self:Prepare()) then return end

	local id = self:CreateUI();
	local duration = self.duration or 1200;
	local move_up = self.move_up or 50;

	UIAnimManager.PlayCustomAnimation(duration, function(elapsedTime)
		local _this = ParaUI.GetUIObject(id);
		if(elapsedTime < duration) then
			if(_this and _this:IsValid()) then
				local t = elapsedTime / duration;
				-- vertical move: easing out
				local dy = move_up * (1 - (1 - t)^1.5);
				_this.x = (self.from_2d.x or 0) - (_this.width or self.width)/2;
				_this.y = (self.from_2d.y or 0) - (_this.height or self.height)/2 - dy;
				-- fade out in the last 30% of the animation
				local alpha = 1;
				local fadeStart = 0.6;
				if(t >= fadeStart) then
					alpha = (1 - (t - fadeStart)/(1 - fadeStart));
				end
				local a = math.floor((alpha or 1) * 255);
				_this.colormask = string.format("255 255 255 %d", a);
			end
		else
			if(_this and _this:IsValid()) then
				ParaUI.Destroy(id);
			end
			if(self.finishCallback and type(self.finishCallback) == "function") then
				self.finishCallback();
				self.finishCallback = nil;
			end
		end
	end, nil, 30)
end

-- convenience: create-and-play
function HeadOnNumberEffect.ShowNumberAt(params)
	params = params or {};
	local eff = HeadOnNumberEffect:new(params);
	eff:Play();
	return eff;
end

-- convenience: show at an entity (uses entity:GetPosition())
function HeadOnNumberEffect.ShowNumberAtEntity(entity, text, color, duration, from_3d_extra)
	if(not entity or type(entity.GetPosition)~="function") then return end
	local x, y, z = entity:GetPosition();
    y =  y + entity:GetHeight();
	local params = commonlib.copy(from_3d_extra) or {};
	params.text = text;
	params.color = color;
	params.duration = duration;
	params.from_3d = {x = x, y = y, z = z};
	return HeadOnNumberEffect.ShowNumberAt(params);
end

-- @param ui: can be ui_name or {x,y} or uiobject
function HeadOnNumberEffect.ShowNumberAtUI(ui, text, color, duration, extra_params)
	local x, y;
	if(type(ui) == "string") then
		local uiobject = ParaUI.GetUIObject(ui);
		if(uiobject and uiobject:IsValid()) then
			ui = uiobject;
		end
	end

	if(type(ui) == "table" and ui.x and ui.y) then
		x, y = ui.x, ui.y;
	elseif(type(ui) == "userdata" and ui:IsValid()) then
		local left, top, width, height = ui:GetAbsPosition();
		x = left + width/2;
		y = top + height/2;
	end
	
	if(x and y) then
		local params = commonlib.copy(extra_params) or {};
		params.text = text;
		params.color = color;
		params.duration = duration;
		params.from_2d = {x = x, y = y};
		return HeadOnNumberEffect.ShowNumberAt(params);
	end
end



