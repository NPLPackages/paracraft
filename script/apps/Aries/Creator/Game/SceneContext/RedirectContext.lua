--[[
Title: RedirectContext or CommandContext
Author(s): LiXizhi
Date: 2015/8/8
Desc: RedirectContext is also called CommandContext, since it is usually binded with a command object. 
Custom commands or tasks can redirect input to their own member functions with RedirectContext. 
Please note when context is deacticated, the command's OnExit will also be called. 
See SelectBlocksTask for example. 
By default, the redirect context does very little, and it will never modify the scene in anyway. 
Thus making it a good candicate base class to user defined scene context, besides BaseContext. 

virtual or redirected functions:
	mousePressEvent(event)
	mouseMoveEvent(event)
	mouseReleaseEvent(event)
	mouseWheelEvent(event)
	keyPressEvent(event)
	
	handleLeftClickScene(event)
	handleRightClickScene(event)
	handleMiddleClickScene(event)
	handlePlayerKeyEvent(event)
	UpdateManipulators()

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/RedirectContext.lua");
-- usage one: subclass and provide your own handler
local MyContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.RedirectContext"), nil);
-- usage two: redirect event handler to another class
function cmdOrTaskInstance:mousePressEvent(event)
end
MyContext = Game.SceneContext.RedirectContext:new():RedirectInput(cmdOrTaskInstance);
-- activate this context
MyContext:activate();
-- switch back to default context. 
MyContext:close();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local RedirectContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.RedirectContext"));

RedirectContext:Property("Name", "RedirectContext");

function RedirectContext:ctor()
	self:EnableAutoCamera(true);
end

-- redirect input to a given command or task object. 
-- for example, cmd:keyPressEvent(event) will be called. 
function RedirectContext:RedirectInput(cmd)
	self.redirect_cmd = cmd;
	return self;
end

-- virtual function: 
-- try to select this context. 
function RedirectContext:OnSelect(lastContext)
	RedirectContext._super.OnSelect(self);
	self:EnableMousePickTimer(true);
end

-- the command object should use close() to deactivate. 
-- calling deactivate directly will also exit the associated command object. 
function RedirectContext:deactivate()
	if(RedirectContext._super.deactivate(self)) then
		if(not self.is_closing) then
			if(self.redirect_cmd and self.redirect_cmd.OnExit) then
				self.redirect_cmd:OnExit();
			end
		end
		return true;
	end
end

function RedirectContext:close()
	self.is_closing = true;
	local res = RedirectContext._super.close(self);
	self.is_closing = nil;
	return res;
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function RedirectContext:OnUnselect()
	RedirectContext._super.OnUnselect(self);
	return true;
end

-- return true if redirection occurs
function RedirectContext:RedirectEvent(eventName, event)
	if(self.redirect_cmd and self.redirect_cmd[eventName] and not self.is_redirecting) then
		self.is_redirecting = true;
		self.redirect_cmd[eventName](self.redirect_cmd, event);
		self.is_redirecting = false;
		return true;
	end
end


--virtual:
function RedirectContext:UpdateManipulators()
	return self:RedirectEvent("UpdateManipulators");
end

-- virtual: 
function RedirectContext:mousePressEvent(event)
	if(self:RedirectEvent("mousePressEvent", event)) then
		return;
	end
	RedirectContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function RedirectContext:handleItemMouseEvent(event)
	-- disable item event
end

function RedirectContext:handleItemKeyEvent(event)
	-- disable item event
end

-- virtual: 
function RedirectContext:mouseMoveEvent(event)
	if(self:RedirectEvent("mouseMoveEvent", event)) then
		return;
	end
	RedirectContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function RedirectContext:handleLeftClickScene(event)
	if(self:RedirectEvent("handleLeftClickScene", event)) then
		return;
	end
end

function RedirectContext:handleRightClickScene(event)
	if(self:RedirectEvent("handleRightClickScene", event)) then
		return;
	end
end

function RedirectContext:handleMiddleClickScene(event)
	if(self:RedirectEvent("handleMiddleClickScene", event)) then
		return;
	end
	return RedirectContext._super.handleMiddleClickScene(self, event);
end

-- virtual: 
function RedirectContext:mouseReleaseEvent(event)
	if(self:RedirectEvent("mouseReleaseEvent", event)) then
		return;
	end
	RedirectContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	if(self.is_click) then
		local result = Game.SelectionManager:GetPickingResult();
		if(event.mouse_button == "left") then
			self:handleLeftClickScene(event, result)
		elseif(event.mouse_button == "right") then
			self:handleRightClickScene(event, result);
		elseif(event.mouse_button == "middle") then
			self:handleMiddleClickScene(event, result);
		end
	end
end
-- virtual: 
function RedirectContext:mouseWheelEvent(event)
	if(self:RedirectEvent("mouseWheelEvent", event)) then
		return;
	end
	RedirectContext._super.mouseWheelEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

--virtual 
function RedirectContext:handlePlayerKeyEvent(event)
	if(self:RedirectEvent("handlePlayerKeyEvent", event)) then
		return event:isAccepted();
	end
	return RedirectContext._super.handlePlayerKeyEvent(self, event);
end

-- virtual: actually means key stroke. 
function RedirectContext:keyPressEvent(event)
	if(self:RedirectEvent("keyPressEvent", event)) then
		return;
	end
	RedirectContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	if( self:handlePlayerKeyEvent(event)) then
		return;
	end
end
