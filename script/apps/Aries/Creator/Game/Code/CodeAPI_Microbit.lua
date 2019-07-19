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
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeCoroutine.lua");
NPL.load("(gl)script/ide/timer.lua");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local vector3d = commonlib.gettable("mathlib.vector3d");
local CodeCoroutine = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCoroutine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");


function env_imp:getBoneVariable(name)
    local actor = env_imp.GetActor(self);
    if(actor)then
        local bones_variable = actor:GetBonesVariable();
        local variables = bones_variable:GetVariables();
        local bone_variable = bones_variable:GetChild(name);
        return bone_variable;
    end
end
function env_imp:getBoneAttVariable(name,index)
    local bone_variable = env_imp.getBoneVariable(self,name);
    if(bone_variable)then
        return bone_variable.variables[index];
    end
end
function env_imp:rotateBone(name,angle,axis,duration)
    angle = angle * math.pi / 180;
    local axis_value;
    if(axis == "x")then
        axis_value = vector3d.unit_x;
    elseif(axis == "y")then
        axis_value = vector3d.unit_y;
    elseif(axis == "z")then
        axis_value = vector3d.unit_z;
    end
    local bone_attr_variable_rot = env_imp.getBoneAttVariable(self,name,1);
    if(bone_attr_variable_rot)then
	    local var = bone_attr_variable_rot:CreateGetTimeVar();
	    if(var) then
            var:Reset();
            var.type = "Linear";

            var:AddKey(0,Quaternion.IDENTITY);
            var:AddKey(duration,Quaternion:new():FromAngleAxis(angle, axis_value));
            
            env_imp.playBone(self, name, 0, duration);

        end
    end
end

