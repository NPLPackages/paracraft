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


function env_imp:start_NplMicroRobot()
    local MicrobitEmulatorPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/MicrobitEmulatorPage.lua");
    MicrobitEmulatorPage.ShowPage();
end
----------------------------Motion
function env_imp:createOrGetAnimationClip_NplMicroRobot(name)
    if(not self.robot_clips)then
        self.robot_clips = {};
    end
    local clip = self.robot_clips[name];
    if(not clip)then
        clip = {};

        self.robot_clips[name] = clip
    end
    self.cur_robot_clip = clip;
    return clip;
end
function env_imp:createAnimationClip_NplMicroRobot(name)
    env_imp.createOrGetAnimationClip_NplMicroRobot(self,name);
end

function env_imp:createTimeLine_NplMicroRobot(from,to,loopTimes,speed)
    if(self.cur_robot_clip)then
        table.insert(self.cur_robot_clip,{from = from, to = to, loopTimes = loopTimes, speed = speed});
    end
end

function env_imp:join_timelines_NplMicroRobot(clip)
    if(not clip)then
        return
    end
    local actor = env_imp.GetActor(self);
	if(not actor) then
		return
	end
    local duration = actor:GetMovieClip():GetLength();
    local result = {};
    for k,timeline in ipairs(clip) do
        local from = timeline.from;
        local to = timeline.to;
        local loopTimes = timeline.loopTimes;
        local speed = timeline.speed;
        if(to < 0)then
            to = duration;
        end
        if(loopTimes > 0)then
            for kk = 1,loopTimes do
                table.insert(result,{from = from, to = to, speed = speed});
            end
        end
    end
    return result;
end
function env_imp:play_next_NplMicroRobot(clip,index,callback)
    local timeline = clip[index];
    if(not timeline)then
        if(callback)then
            callback();
        end
        return
    end
    local from = timeline.from;
    local to = timeline.to;
    local loopTimes = timeline.loopTimes;
    local speed = timeline.speed;
     self.play(from,to,false,function()
        env_imp.play_next_NplMicroRobot(self,clip,index+1,callback)
    end,speed);
end
function env_imp:playAnimationClip_NplMicroRobot(name)
    
    local clip = env_imp.createOrGetAnimationClip_NplMicroRobot(self,name);
    if(clip)then
        clip = env_imp.join_timelines_NplMicroRobot(self,clip);
        env_imp.play_next_NplMicroRobot(self,clip,1,function()
			env_imp.resume(self);
        end)
		env_imp.yield(self);
    end
end

function env_imp:stopAnimationClip_NplMicroRobot()
    self:stop();
end
----------------------------Looks
function env_imp:microbit_show_leds(v)
end
function env_imp:microbit_show_string(v)
    env_imp.broadcast(self,"microbit_show_string",v)
end
function env_imp:microbit_clear_screen()
end
-- @param v: milliseconds
function env_imp:microbit_pause(v)
    local seconds = math.floor(v / 1000);
    env_imp.wait(self, seconds);
end

----------------------------Events
-- @param name: "A" or "B" or "AB"
function env_imp:registerKeyPressedEvent_NplMicroRobot(name,callback)
    if(not name)then
        return
    end
    name = string.format("microbit_btn_%s",name);
    env_imp.registerBroadcastEvent(self,name,callback)
end
function env_imp:registerGestureEvent_NplMicroRobot(name,callback)
    name = string.format("microbit_gesture_%s",name);
    env_imp.registerBroadcastEvent(self,name,callback)
end

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
function env_imp:createOrUpdateVariableRotation(name,axis,type,values)
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
            var.type = type or "Linear";

            for k,v in ipairs(values) do
                local angle = v.value * math.pi / 180;
                var:AddKey(v.time,Quaternion:new():FromAngleAxis(angle, axis_value));
            end
        end
        return var;
    end
end
function env_imp:microbit_servo(bone_name, axis, value, channel, offset)
    env_imp.rotateBone(self,bone_name,value,axis,1000);
end
function env_imp:microbit_sleep(time)
    time = time or 0;
    env_imp.wait(self,time/1000);
end
function env_imp:microbit_is_pressed(btn)
    if(not btn)then
        return
    end
    local key = string.lower(btn);
    if(key == "a")then
        key = "t"
    end
    if(key == "b")then
        key = "y"
    end
    local v = env_imp.isKeyPressed(self,key);
    if(v)then
        commonlib.echo({btn = btn , key = key, v = v, });
    end
    return v;
end
function env_imp:microbit_display_show(s)
end
function env_imp:microbit_display_scroll(s)
end
function env_imp:microbit_display_clear()
end
function env_imp:createRobotAnimation(name)
    if(not self.robot_anims)then
        self.robot_anims = {};
    end
    local robot_animation_container = {};
    self.robot_anims[name] = robot_animation_container;
    self.cur_robot_animation_container = robot_animation_container;
    self.cur_robot_anim = nil;
end
function env_imp:playRobotAnimation(name)
    if(not name or not self.robot_anims[name])then
        return
    end
    local robot_animation_container = self.robot_anims[name];
    local rot_variables = {};
    for k,v in ipairs(robot_animation_container)do
        local bone_name = v.bone_name;
        local values = v.values;
        local len = #values;
        local min_time = values[1].time;
        local max_time = values[len].time;
        local var = env_imp.createOrUpdateVariableRotation(self,bone_name,v.axis,v.type,values);
        if(var)then
            table.insert(rot_variables,{ bone_name = bone_name, min_time = min_time, max_time = max_time, });
        end
    end
    for k,v in ipairs(rot_variables) do
        env_imp.playBone(self, v.bone_name, v.min_time, v.max_time - v.min_time);
    end
end
function env_imp:addRobotAnimationChannel(bone_name,axis,channel,type)
    if(not bone_name)then
        return
    end
    if(env_imp.findBoneAnimByName(self,bone_name))then
        return
    end
    -- create a animation table for bone
    local anim = {
        bone_name = bone_name,
        axis = axis,
        type = type,
        values = {};
    }
    table.insert(self.cur_robot_animation_container,anim);
    self.cur_robot_anim = anim;
end
function env_imp:addAnimationTimeValue_Rotation(time,value)
    if(self.cur_robot_anim and self.cur_robot_anim.values)then
        table.insert(self.cur_robot_anim.values,{ time = time, value = value }); 

        table.sort(self.cur_robot_anim.values,function(a,b)
            return a.time < b.time;
        end)
    end
end
function env_imp:findBoneAnimByName(bone_name)
    if(not bone_name)then
        return
    end
    if(self.robot_anims)then
        for k,v in ipairs(self.robot_anims) do
            if(v.bone_name == bone_name)then
                return v;
            end
        end
    end
end


