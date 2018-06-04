--[[
Title: CodeAPI
Author(s): LiXizhi
Date: 2018/5/16
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Sensing.lua");
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- @param objName: 
--  "mouse-pointer" is mouse position. 
--  "@a" means nearby players. 
--  "block" or nil means scene blocks. if number string like "62", it means given block id. 
-- @return true if actor is touching another object
function env_imp:isTouching(actor, objName)
end

function env_imp:isTouchingSide(actor, blockid)
end

function env_imp:isTouchingTop(actor, objName)
end

function env_imp:isTouchingBottom(actor, objName)
end


function env_imp:ask(actor, text, callbackFunc)
end

function env_imp:isKeyPressed(text)
end

function env_imp:isMouseDown()
end

-- @param objName: if nil or "self", it means the calling actor
function env_imp:getX(actor, objName)
end

function env_imp:getY(actor, objName)
end

function env_imp:getZ(actor, objName)
end

function env_imp:getPlayTime(actor, objName)
end

function env_imp:getFacing(actor, objName)
end

function env_imp:getSize(actor, objName)
end


