--[[
Title: Obtain Item Effect
Author(s): LiXizhi
Date: 2013/11/25
Desc: an UI object that flys from a 3d position to a 2d position
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
ObtainItemEffect.FlyImageFromEntityToUI(GameLogic.EntityManager.GetPlayer(), "Texture/whitedot.png", {x=0,y=0}, 1000, 32, 32);
ObtainItemEffect.FlyTextFromEntityToUI(GameLogic.EntityManager.GetPlayer(), "hello world", "QuickSelectBar.btn1", "#00ffff", 16, 2000);
-- Fly text to entity from UI
ObtainItemEffect.FlyTextToEntity("Critical Hit!", GameLogic.EntityManager.GetPlayer(), "QuickSelectBar.btn1", "#ff0000", 20, 1000);
ObtainItemEffect.FlyTextToEntity("Critical Hit!", GameLogic.EntityManager.GetPlayer(), nil, "#ff0000", 20, 1000);
-- Fly text to entity from another entity
local npc = GameLogic.EntityManager.GetEntity("myNPC");
ObtainItemEffect.FlyTextToEntity("Healing +50", GameLogic.EntityManager.GetPlayer(), npc, "#00ff00", 16, 1500);
-- Fly image to entity from 2D position
ObtainItemEffect.FlyImageToEntity("Texture/whitedot.png", GameLogic.EntityManager.GetPlayer(), {x=200, y=200}, 2000, 48, 48);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local mathlib = commonlib.gettable("mathlib");

local ObtainItemEffect = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect"));

function ObtainItemEffect:ctor()
	self.fontsize = self.fontsize or 14;
	if(self.fontsize and not self.font) then
		self.font = string.format("System;%d;bold", self.fontsize);
	end
end

function ObtainItemEffect:Convert3Dto2D(from_3d)
	if(from_3d) then
		if(not from_3d.x) then
			if(from_3d.bx) then
				from_3d.x, from_3d.y, from_3d.z = BlockEngine:real(from_3d.bx, from_3d.by, from_3d.bz);
			else
				from_3d.x, from_3d.y, from_3d.z = ParaScene.GetPlayer():GetPosition();
			end
		end
		if(from_3d.x) then
			local screen_pos = {};
			ParaScene.GetScreenPosFrom3DPoint(from_3d.x, from_3d.y, from_3d.z, screen_pos);
			
			if(screen_pos.x and from_3d.offset_x) then
				screen_pos.x = screen_pos.x + from_3d.offset_x;
			end
			if(screen_pos.y and from_3d.offset_y) then
				screen_pos.y = screen_pos.y + from_3d.offset_y;
			end
			return screen_pos;
		end
	end
end

function ObtainItemEffect:Prepare()
	if(not self.from_2d) then
		self.from_2d = self:Convert3Dto2D(self.from_3d);
	end

	if(type(self.to_2d) == "string") then
		local uiobj = ParaUI.GetUIObject(self.to_2d);
		if(uiobj and uiobj:IsValid()) then
			local x, y, width, height = uiobj:GetAbsPosition();
			local target_w = self.width or 32;
			local target_h = self.height or target_w;
			if(self.from_2d) then
				target_w = self.from_2d.width or target_w;
				target_h = self.from_2d.height or target_h;
			end
			self.to_2d = {x = x + width/2 - target_w/2, y = y + height/2 - target_h/2};
		end
	end

	if(not self.to_2d) then
		self.to_2d = self:Convert3Dto2D(self.to_3d);
	end
	self.duration = self.duration or 2000;
	if(self.from_2d and self.from_2d.x and self.from_2d.y and self.to_2d and self.to_2d.x and self.to_2d.y) then
		return true;
	end
end

-- virtual function
-- @return ui object id;
function ObtainItemEffect:CreateUI()
	local _this=ParaUI.CreateUIObject("button","effect", self.from_2d.alignment or "_lt", self.from_2d.x or 0, self.from_2d.y or 0,self.from_2d.width or self.width or 32, self.from_2d.height or self.height or self.width or 32);
	_this.enabled = false;
	if(self.text) then
		_this.text = self.text;
		if(self.color) then
			_guihelper.SetFontColor(_this, self.color);
		end
		_this.font = self.font or "System;14;bold";
		_this.shadow = true;
		if(not self.background) then
			_guihelper.SetUIFontFormat(_this, 32+256); -- single line, left align and noclip
		end
	end
	_this.background = self.background or "";
	_guihelper.SetUIColor(_this, self.color or "#ffffffff");
	if(self.fadeIn) then
		_this.colormask = "255 255 255 0";
	end
	local id = _this.id;
	_this:AttachToRoot();
	return id;
end

-- @param start_time: time to start playing. if nil, it plays immediately. 
function ObtainItemEffect:Play(start_time)
	if(start_time and start_time>0)then
		UIAnimManager.PlayCustomAnimation(start_time, function(elapsedTime)
			if(elapsedTime == start_time ) then
				self:Play();
			end
		end, nil, start_time)
		return 
	end

	if(not self:Prepare()) then
		-- LOG.std(nil, "warn", "ObtainItemEffect", "prepare failed");
		return
	end

	local id = self:CreateUI();

	UIAnimManager.PlayCustomAnimation(self.duration, function(elapsedTime)
		if(elapsedTime < self.duration ) then
			local _this = ParaUI.GetUIObject(id);
			if(_this:IsValid()) then
				local t = elapsedTime / self.duration;
				_this.x = mathlib.lerp(self.from_2d.x, self.to_2d.x, t);
				_this.y = mathlib.lerp(self.from_2d.y, self.to_2d.y, t^2.5);-- making it accelarate
			end
			
			if(self.fadeIn or self.fadeOut) then
				if(self.fadeIn and elapsedTime <= self.fadeIn) then
					_this.colormask = format("255 255 255 %d", elapsedTime / self.fadeIn*255);
				elseif(self.fadeOut and (self.duration-self.fadeOut)<=elapsedTime) then
					_this.colormask = format("255 255 255 %d", (self.duration - elapsedTime)/self.fadeOut*255);
				else
					_this.colormask = "255 255 255 255";
				end
			end
			
		else
			if self.finishCallback and type(self.finishCallback) == "function" then
				self.finishCallback();
				self.finishCallback = nil;
			end
			ParaUI.Destroy(id);
		end	
	end, nil, 30)
end

-- convenience: create-and-play
function ObtainItemEffect.ShowEffect(params)
	params = params or {};
	local eff = ObtainItemEffect:new(params);
	eff:Play();
	return eff;
end

-- show text flying from an entity to a 2d position
function ObtainItemEffect.FlyTextFromEntityToUI(entity, text, to_2d, color, fontsize, duration)
	if(not entity or type(entity.GetPosition)~="function") then return end
	local fontsize = fontsize or 14;
	local x, y, z = entity:GetPosition();
	y = y + entity:GetHeight();
	local params = {
		text = text,
		color = color,
		duration = duration,
		from_3d = {x = x, y = y, z = z},
		to_2d = to_2d,
		fontsize = fontsize,
	};
	return ObtainItemEffect.ShowEffect(params);
end

-- show image flying from an entity to a 2d position
function ObtainItemEffect.FlyImageFromEntityToUI(entity, background, to_2d, duration, width, height)
	if(not entity or type(entity.GetPosition)~="function") then return end
	local x, y, z = entity:GetPosition();
	y = y + entity:GetHeight();
	local params = {
		background = background,
		duration = duration,
		from_3d = {x = x, y = y, z = z},
		to_2d = to_2d,
		width = width,
		height = height,
	};
	return ObtainItemEffect.ShowEffect(params);
end

-- show text flying to an entity from a source (UI, entity, or offset)
-- @param from_source: can be a string (UI object name), or a 3d position table {x,y,z} or an entity object or nil. 
-- if nil, it will try to fly from 100px above the entity.
function ObtainItemEffect.FlyTextToEntity(text, target_entity, from_source, color, fontsize, duration)
	if(not target_entity or type(target_entity.GetPosition)~="function") then return end
	local fontsize = fontsize or 14;
	local x, y, z = target_entity:GetPosition();
	y = y + target_entity:GetHeight();
	local to_3d = {x = x, y = y, z = z};
	
	local from_2d, from_3d;
	
	if(type(from_source) == "string") then
		from_2d = from_source;
	elseif(type(from_source) == "table") then
		if(type(from_source.GetPosition)=="function") then
			local fx, fy, fz = from_source:GetPosition();
			fy = fy + from_source:GetHeight();
			from_3d = {x = fx, y = fy, z = fz};
		elseif(from_source.x) then
			from_2d = from_source;
		end
	end
	
	if(not from_2d and not from_3d) then
		local screen_pos = {};
		ParaScene.GetScreenPosFrom3DPoint(x, y, z, screen_pos);
		if(screen_pos.x) then
			from_2d = {x = screen_pos.x, y = screen_pos.y - 100};
		else
			from_3d = {x = x, y = y + 1, z = z};
		end
	end

	local params = {
		text = text,
		color = color,
		duration = duration,
		from_2d = from_2d,
		from_3d = from_3d,
		to_3d = to_3d,
		fontsize = fontsize,
	};
	return ObtainItemEffect.ShowEffect(params);
end

-- show image flying to an entity from a source (UI, entity, or offset)
-- @param from_source: can be a string (UI object name), or a 3d position table {x,y,z} or an entity object or nil. 
-- if nil, it will try to fly from 100px above the entity.
function ObtainItemEffect.FlyImageToEntity(background, target_entity, from_source, duration, width, height)
	if(not target_entity or type(target_entity.GetPosition)~="function") then return end
	local x, y, z = target_entity:GetPosition();
	y = y + target_entity:GetHeight();
	local to_3d = {x = x, y = y, z = z};
	
	local from_2d, from_3d;
	
	if(type(from_source) == "string") then
		from_2d = from_source;
	elseif(type(from_source) == "table") then
		if(type(from_source.GetPosition)=="function") then
			local fx, fy, fz = from_source:GetPosition();
			fy = fy + from_source:GetHeight();
			from_3d = {x = fx, y = fy, z = fz};
		elseif(from_source.x) then
			from_2d = from_source;
		end
	end
	
	if(not from_2d and not from_3d) then
		local screen_pos = {};
		ParaScene.GetScreenPosFrom3DPoint(x, y, z, screen_pos);
		if(screen_pos.x) then
			from_2d = {x = screen_pos.x, y = screen_pos.y - 100};
		else
			from_3d = {x = x, y = y + 1, z = z};
		end
	end

	local params = {
		background = background,
		duration = duration,
		from_2d = from_2d,
		from_3d = from_3d,
		to_3d = to_3d,
		width = width,
		height = height,
	};
	return ObtainItemEffect.ShowEffect(params);
end
