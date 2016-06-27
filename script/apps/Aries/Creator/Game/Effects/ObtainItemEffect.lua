--[[
Title: Obtain Item Effect
Author(s): LiXizhi
Date: 2013/11/25
Desc: an UI object that flys from a 3d position to a 2d position
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
ObtainItemEffect:new({background="Texture/whitedot.png", duration=1000, color="#00ff00ff", width=6,height=6, 
	from_3d={}, to_2d={x=0,y=0}}):Play();
ObtainItemEffect:new({background="Texture/whitedot.png", color="#ffffffff", width=32,height=32, 
	from_3d={bx=0,by=0,bz=0}, to_2d={x=0,y=0}}):Play();
ObtainItemEffect:new({text="hello world", color="#ffffffff", width=128,height=32, 
	from_3d={bx=0,by=0,bz=0, offset_x=0, offset_y=0}, to_2d={x=0,y=0}
	fadeIn=100, fadeOut=100}):Play();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local mathlib = commonlib.gettable("mathlib");

local ObtainItemEffect = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect"));

function ObtainItemEffect:ctor()
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
			ParaUI.Destroy(id);
		end	
	end, nil, 30)
end
