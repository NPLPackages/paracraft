--[[
Title: CodeAPI_Microbit
Author(s): leio
Date: 2019/7/16
Desc: sandbox API environment
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

function env_imp:robotRotateLeftArm(angle)
	commonlib.echo("===robotRotateLeftArm");
	local entity = env_imp.GetEntity(self);
	if(entity) then
        local variables = entity:GetVariables();
		if(variables) then
            for k,v in pairs(variables) do
	            commonlib.echo(v);
            end
		end
    end
end
function env_imp:robotRotateRightArm(angle)
	commonlib.echo("===robotRotateRightArm");
	commonlib.echo(angle);
end
function env_imp:robotRotateLeftLeg(angle)
	commonlib.echo("===robotRotateLeftLeg");
	commonlib.echo(angle);
end
function env_imp:robotRotateRightLeg(angle)
	commonlib.echo("===robotRotateRightLeg");
	commonlib.echo(angle);
end
function env_imp:robotRotateBody(angle)
	commonlib.echo("===robotRotateBody");
	commonlib.echo(angle);
end

