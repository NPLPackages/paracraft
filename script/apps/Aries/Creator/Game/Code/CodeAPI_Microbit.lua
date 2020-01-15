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

-- set ranges index to 0 as first 
function env_imp.fixeRangesToJsIndex(bones)
    if(not bones)then
        return
    end
    local result = {};
    for k,v in pairs(bones) do
        if(type(v) == "table" and v.ranges)then
            for kk,vv in ipairs(v.ranges) do
                for kkk,vvv in ipairs(vv) do
                    vv[kkk] = vv[kkk] - 1;
                end
            end
            v.type = nil; -- remove wrong type
            v.offset = 0; -- set offset value for servo rotation
            table.insert(result,v);
        end
    end
    return result;
end

function env_imp.helper_ReadBonePropertiesFromName(name)
    if(not name)then
        return
    end
	local display_name, properties = name:match("^(.*)%s*(%{[^%}]+%})_rot");
	if(properties) then
		properties = NPL.LoadTableFromString(properties);
	end
    return display_name, properties;
end

function env_imp.helper_radianToDegreeInt(v)
    v = v * 180 / 3.1415926;
    v = math.floor(v + 0.5);
    return v;
end

-- clear names to save memory in microbit
function env_imp.helper_clear_names(values)
    for k,v in ipairs(values) do
        v.name = nil;
        v.display_name = nil;
        v.axis = nil;
        v.min = nil;
        v.max = nil;
        v.offset = nil;
        v.servoScale = nil;
    end
    return values;
end
function env_imp.fixRotationValuesAndID(bones)
    if(not bones)then
        return
    end
    local result = {};
    for k,v in pairs(bones) do
        if(type(v) == "table" and v.data)then
            local name = v.name
            local display_name, properties = env_imp.helper_ReadBonePropertiesFromName(name);
            properties = properties or {};
            local rotAxis = properties.rotAxis;
            local servoId = properties.servoId;
            local servoOffset = properties.servoOffset; -- input is radian
            local servoScale = properties.servoScale or 1;
            local tag = properties.tag;
            if(servoId and servoId > -1)then
                v.id = servoId; --set servo id
                v.offset = env_imp.helper_radianToDegreeInt(servoOffset or 0) --set servo offset
                v.display_name = display_name;
                if(properties.min and properties.max)then
                    v.min = env_imp.helper_radianToDegreeInt(properties.min);
                    v.max = env_imp.helper_radianToDegreeInt(properties.max);
                end
                v.servoScale = servoScale;
                v.tag = tag;
                local data = v.data
                for kk,vv in ipairs(data) do
                    -- change every quaternion to degree on one axis
                    if(type(vv) == "table")then
                        local len = #vv;
                        if(len >= 4)then
                            local last_angle = 0;
                            local q = Quaternion:new(vv);    
                            if(rotAxis)then
                                rotAxis = string.lower(rotAxis);
                                local rot_y,rot_z,rot_x = q:ToEulerAngles();
                                if(rotAxis == "x")then
                                    last_angle = rot_x;
                                elseif(rotAxis == "y")then
                                    last_angle = rot_y;
                                elseif(rotAxis == "z")then
                                    last_angle = rot_z;
                                end
                                v.axis = rotAxis;
                            else
                                local angle, axis = q:ToAngleAxis();
                                last_angle = angle;
                            end
                            data[kk] = v.offset + servoScale * env_imp.helper_radianToDegreeInt(last_angle)
                        
                        end
                    end
                end
                table.insert(result,v);
            end
        end
    end
    return result;
end
function env_imp.getBonesDataFromInventory(inventory)
    if(not inventory)then
        return
    end
    local slots = inventory.slots or {};
    local serverdata;
    for k,v in ipairs(slots) do
        if(v.id == 10062)then
            serverdata = v.serverdata;
            break;
        end
    end
    if(serverdata and serverdata.timeseries and serverdata.timeseries.bones)then
        return serverdata.timeseries.bones;
    end
end
function env_imp:createMicrobitRobot()
    local NodeJsRuntime = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NodeJsRuntime.lua");
    if(not NodeJsRuntime.IsValid())then
        -- only download
        NodeJsRuntime.Check()
        return;
    end
    -- check new version
    NodeJsRuntime.Check();

    local movieEntity = self.codeblock:GetMovieEntity();
    local filename = self.codeblock:GetBlockName();
    if(filename == "" or not filename)then
        filename = "default";
    end
    local filename_really = string.format("test/robot/%s_really.json",filename);
    filename = string.format("test/robot/%s.json",filename);
    if(movieEntity and movieEntity.inventory)then
        local inventory = movieEntity.inventory;

        local bones = env_imp.getBonesDataFromInventory(inventory) or {};
        bones = commonlib.copy(bones);
        bones = env_imp.fixeRangesToJsIndex(bones)
        bones = env_imp.fixRotationValuesAndID(bones);
        local NplMicroRobotAdapterPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NplMicroRobotAdapterPage.lua");
        NplMicroRobotAdapterPage.ShowPage(bones,function(type,values)
                local NplMicroRobot = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NplMicroRobot.lua");

                ParaIO.CreateDirectory(filename);
                local file = ParaIO.open(filename,"w");
                if(file:IsValid()) then
		            file:WriteString(NPL.ToJson(values));
		            file:close();
	            end
                values = env_imp.helper_clear_names(values)

                local data = NPL.ToJson(values);
                local file = ParaIO.open(filename_really,"w");
                if(file:IsValid()) then
		            file:WriteString(data);
		            file:close();
	            end

                NplMicroRobot.Run(type,data);
        end);

    end
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


