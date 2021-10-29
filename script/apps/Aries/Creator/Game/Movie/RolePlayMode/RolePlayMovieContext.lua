--[[
Title: Role Play Movie Context
Author(s): LiXizhi
Date: 2021/9/27
Desc: Role playing mode for movie block. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieContext.lua");
local RolePlayMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext");
------------------------------------------------------------
]]
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
local RolePlayMovieContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext"));

RolePlayMovieContext:Property("Name", "RolePlayMovieContext");
RolePlayMovieContext:Signal("boneChanged", function(boneEntity) end);
function RolePlayMovieContext:ctor()
end

-- virtual function: 
-- try to select this context. 
function RolePlayMovieContext:OnSelect()
	BaseContext.OnSelect(self);
	self:updateManipulators();
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function RolePlayMovieContext:OnUnselect()
	RolePlayMovieContext._super.OnUnselect(self);
	return true;
end

function RolePlayMovieContext:updateManipulators()
	self:DeleteManipulators();
end


function RolePlayMovieContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	
	if(event:isAccepted()) then
		return true;
	end
	
	if(dik_key == "DIK_X") then
		-- event:accept();
	end
	return event:isAccepted();
end

-- virtual: 
function RolePlayMovieContext:mousePressEvent(event)
	event:accept();
	if(event:isAccepted()) then
		return
	end
end

-- virtual: 
function RolePlayMovieContext:mouseMoveEvent(event)
	event:accept();
	if(event:isAccepted()) then
		return
	end
end

function RolePlayMovieContext:mouseReleaseEvent(event)
	event:accept();
	if(event:isAccepted()) then
		return
	end
end

-- virtual: actually means key stroke. 
function RolePlayMovieContext:keyPressEvent(event)
	RolePlayMovieContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

