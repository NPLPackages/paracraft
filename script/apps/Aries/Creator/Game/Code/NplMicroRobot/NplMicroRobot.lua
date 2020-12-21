--[[
Title: NplMicroRobot
Author(s): leio
Date: 2019/12/12
Desc: NplMicroRobot is a blockly program to control animation on microbit
use the lib:
-------------------------------------------------------
-- make configs
local NplMicroRobot = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobot.lua");
NplMicroRobot.MakeBlocklyFiles();

- NplMicroRobot package: https://github.com/tatfook/NplMicroRobot
- the block item id is: 10517

- NodeJsRuntime: https://github.com/zhangleio/NodeJsRuntime
local NodeJsRuntime = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NodeJsRuntime.lua");

- pxt-microbit: https://github.com/microsoft/pxt-microbit

- CodeAPI_Microbit
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/math3d.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/timer.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local NodeJsRuntime = NPL.load("(gl)script/apps/Aries/Creator/Game/NodeJsRuntime/NodeJsRuntime.lua");

local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CodeCompiler = commonlib.gettable("MyCompany.Aries.Game.Code.CodeCompiler");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local vector3d = commonlib.gettable("mathlib.vector3d");
local NplMicroRobot = NPL.export();
commonlib.setfield("MyCompany.Aries.Game.Code.NplMicroRobot.NplMicroRobot", NplMicroRobot);

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI_Microbit.lua");

NplMicroRobot.exportNoneAnimatedMotors = true;

local is_installed = false;
local all_cmds = {};
local all_cmds_map = {};
NplMicroRobot.categories = {
    {name = "NplMicroRobot.Motion", text = L"运动", colour="#42ccff", },
    {name = "NplMicroRobot.Servo", text = L"舵机", colour = "#0000cd", },
    {name = "NplMicroRobot.Looks", text = L"显示", colour = "#7abb55", },
    {name = "NplMicroRobot.Events", text = L"事件", colour="#764bcc", },
    {name = "NplMicroRobot.Control", text = L"控制", colour = "#d83b01", },
    {name = "NplMicroRobot.Sensing", text = L"感知", colour="#69b090", },
    {name = "NplMicroRobot.Operators", text = L"运算", colour = "#569138", },
    {name = "NplMicroRobot.Data", text = L"数据", colour="#459197", },
    {name = "NplMicroRobot.MbitCar", text = L"小车", colour="#d2691e", },
    
};
NplMicroRobot.type= "NplMicroRobot";
-- make files for blockly 
function NplMicroRobot.MakeBlocklyFiles()
    local categories = NplMicroRobot.GetCategoryButtons();
    local all_cmds = NplMicroRobot.GetAllCmds()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyHelper.lua");
    local CodeBlocklyHelper = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlocklyHelper");
    CodeBlocklyHelper.SaveFiles("block_configs_nplmicrorobot",categories,all_cmds);

    _guihelper.MessageBox("making blockly files finished");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0).."block_configs_nplmicrorobot", "", "", 1); 
end
function NplMicroRobot.GetCategoryButtons()
    return NplMicroRobot.categories;
end
function NplMicroRobot.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;

	local all_source_cmds = {
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Motion.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Servo.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Looks.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Events.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Control.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Sensing.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Operators.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_Data.lua");
        NPL.load("./NplMicroRobotDef/NplMicroRobotDef_MbitCar.lua");
	}
	for k,v in ipairs(all_source_cmds) do
		NplMicroRobot.AppendDefinitions(v);
	end
end


function NplMicroRobot.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
            if(v.type)then
			    table.insert(all_cmds,v);
			    all_cmds_map[v.type] = v;
            else
	            LOG.std(nil, "error", "NplMicroRobot find empty type in cmd:", v);
            end
		end
	end
end

function NplMicroRobot.GetAllCmds()
	NplMicroRobot.AppendAll();
	return all_cmds;
end

function NplMicroRobot.CreateActorFromMovieClip(movieEntity)
	local itemStack = movieEntity:GetFirstActorStack();
	if(itemStack) then
		local item = itemStack:GetItem();
		if(item and item.CreateActorFromItemStack) then
			local actor = item:CreateActorFromItemStack(itemStack, movieEntity, false, "ActorForNplMicroRobot_");
			if(actor) then
				return actor
			end
		end
	end
end

-- return nil or array of exported motor bones
function NplMicroRobot.GetBonesFromMovieEntity(movieEntity)
	if(movieEntity and movieEntity.inventory)then
		local actor = NplMicroRobot.CreateActorFromMovieClip(movieEntity)
		if(actor) then
			actor:SetTime(0);
			actor:FrameMove(0);
			local bonesVars = actor:GetBonesVariable();
			local bones = actor:GetTimeSeries():GetChild("bones");

			NPL.load("(gl)script/ide/System/Scene/Animations/Bones/BoneProxy.lua");
			local BoneProxy = commonlib.gettable("System.Scene.Animations.Bones.BoneProxy");
			local obj_attr = actor:GetEntity():GetInnerObject():GetAttributeObject();
			local bones_ = {};
			local motor_bones = {};
			local animInstance = obj_attr:GetChildAt(1,1);
			-- because time series may contain redundent bone info, we will only export those in X file. 
			if(animInstance and animInstance:IsValid()) then
				local bone_count = animInstance:GetChildCount(1);
				for i = 0, bone_count-1 do
					local boneProxy = BoneProxy:new():init(animInstance:GetChildAt(i, 1), bones_);
					local serverId = boneProxy:GetBoneProperty("servoId")
					if(serverId) then
						local name = boneProxy.name.."_rot";
						local bone = bones:GetData()[name]
						if(bone) then
							bone = commonlib.copy(bone)
						end
						if(not bone and NplMicroRobot.exportNoneAnimatedMotors) then
							-- Note: bones without animation will have default 0 values
							bone = {ranges={{1,1},}, times={0}, data={{0,0,0,1}}, name=name}
						end
						if(bone) then
							bone.properties = boneProxy:GetProperties();
							motor_bones[#motor_bones+1] = bone;
						end
					end
				end
			end

			actor:OnRemove();
			actor:Destroy();

			motor_bones = NplMicroRobot.fixeRangesToJsIndex(motor_bones)
			motor_bones = NplMicroRobot.fixRotationValuesAndID(motor_bones);

			--echo("1111111111111111111")
			--echo(motor_bones)

			return motor_bones;
		end
	end
end

function NplMicroRobot.OnClickExport(exportType,code,bx, by, bz)
    local codeblock = CodeBlockWindow.GetCodeBlock()
    if(not codeblock)then
        return
    end
    if(not NodeJsRuntime.IsValid())then
        -- only download
        NodeJsRuntime.Check()
        return;
    end
    -- check new version
    NodeJsRuntime.Check();

    local movieEntity = codeblock:GetMovieEntity();
	local bones = NplMicroRobot.GetBonesFromMovieEntity(movieEntity)
    if(bones) then
		local values = bones;
        local len = #values;
		if(exportType == "view")then
			local NplMicroRobotAdapterPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplMicroRobot/NplMicroRobotAdapterPage.lua");
			NplMicroRobotAdapterPage.ShowPage(values);
			return
		end
        local data;
        if(len ~= 0)then
		    values = NplMicroRobot.helper_clear_names(values)
		    data = NPL.ToJson(values);
        else
		    data = nil;
        end
		
		code = NplMicroRobot.fixCode(code);
		NplMicroRobot.Run(exportType, data, code);
    end
end
function NplMicroRobot.fixCode(code)
    if(not code)then
        return
    end
    local var_line_fixed = "";
    local var_line  = string.match(code,"var%s+(.-);")
    if(var_line)then
		for var_name in string.gmatch(var_line, "([^,]+)") do
            if(var_line_fixed == "")then
                var_line_fixed = string.format("%s:any",var_name);
            else
                var_line_fixed = string.format("%s,%s:any",var_line_fixed,var_name);
            end
        end
    end
    if(var_line_fixed ~= "")then
        code = string.gsub(code, "var%s+(.-);",string.format("let %s;",var_line_fixed));
    end
    
    return code;
end
function NplMicroRobot.getBonesDataFromInventory(inventory)
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

-- set ranges index to 0 as first 
function NplMicroRobot.fixeRangesToJsIndex(bones)
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

function NplMicroRobot.helper_radianToDegreeInt(v)
    v = v * 180 / 3.1415926;
    v = math.floor(v + 0.5);
    return v;
end

-- clear names to save memory in microbit
function NplMicroRobot.helper_clear_names(values)
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
function NplMicroRobot.fixRotationValuesAndID(bones)
    if(not bones)then
        return
    end
    local result = {};
    for k,v in pairs(bones) do
        if(type(v) == "table" and v.data and v.properties)then
            local display_name = v.name;
            local properties = v.properties;
            v.properties = nil;
            local rotAxis = properties.rotAxis;
            local servoId = properties.servoId;
            local servoOffset = properties.servoOffset; -- input is radian
            local servoScale = properties.servoScale or 1;
            local tag = properties.tag;
            if(servoId and servoId > -1)then
                v.id = servoId; --set servo id
                v.offset = NplMicroRobot.helper_radianToDegreeInt(servoOffset or 0) --set servo offset
                v.display_name = display_name;
                if(properties.min and properties.max)then
                    v.min = NplMicroRobot.helper_radianToDegreeInt(properties.min);
                    v.max = NplMicroRobot.helper_radianToDegreeInt(properties.max);
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
                            data[kk] = v.offset + servoScale * NplMicroRobot.helper_radianToDegreeInt(last_angle)
                        
                        end
                    end
                end
                table.insert(result,v);
            end
        end
    end
    return result;
end


function NplMicroRobot.TestData()
    return [[
    [
    {
        "id": 0, // channel
        "ranges": [
            [0, 4]
        ],
        "times": [0, 2000, 4000, 6000, 8000],
        "data": [0, 45, 90, 135, 180]
    },
    {
        "id": 4, // channel
        "ranges": [
            [0, 3]
        ],
        "times": [0, 2000, 4000, 6000],
        "data": [0, 45, 90, 180]
    }
]
    ]]
end
function NplMicroRobot.WriteAnimationData(data)
    data = data or "[]";
    if(not data)then
        return
    end
    local code = string.format([[
let AnimationData:Array<any>  = %s
    ]],data)
    local filename = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/AnimationData.ts");
	LOG.std(nil, "info", "NplMicroRobot", "write animation to:%s",filename);
    local file = ParaIO.open(filename,"w");
    if(file:IsValid()) then
		file:WriteString(code);
		file:close();
	end
end
function NplMicroRobot.WriteCodeData(code)
    code = code or ""
    local filename = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/main.ts");
	LOG.std(nil, "info", "NplMicroRobot", "write code to:%s",filename);
    local file = ParaIO.open(filename,"w");
    if(file:IsValid()) then
		file:WriteString(code);
		file:close();
	end
end
function NplMicroRobot.GetHexFileName()
    local filename = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/built/binary.hex");
    return filename;
end
-- @type "build" or "deploy"
function NplMicroRobot.Run(type,animation_data,code)
    type = type or "build"
    if(not NodeJsRuntime.IsValid())then
	    LOG.std(nil, "error", "NplMicroRobot", "NodeJsRuntime isn't valid()");
        return
    end
    local filename = NplMicroRobot.GetHexFileName();
	LOG.std(nil, "info", "NplMicroRobot", "the hex filename:%s",filename);
	ParaIO.DeleteFile(filename)


    NplMicroRobot.WriteAnimationData(animation_data)
    NplMicroRobot.WriteCodeData(code)
    local cmd;
    if(type == "build")then
        cmd = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/build.bat");
    else
        cmd = string.format("%s/%s",NodeJsRuntime.GetRoot(),"projects/NplMicroRobot/deploy.bat");
    end
	ParaGlobal.ShellExecute("open", cmd, "", "", 1); 


--    local timer = commonlib.Timer:new({callbackFunc = function(timer)
--        if(ParaIO.DoesFileExist(filename))then
--            timer:Change()
--            
--             _guihelper.MessageBox(string.format(L"成功生成:%s,是否打开文件夹？", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
--			if(res and res == _guihelper.DialogResult.Yes) then
--		            local folder,name,extension = string.match(filename, "(.+)/(.+)%.(%w+)$")
--                    commonlib.echo(folder);
--					if(folder) then
--	                    ParaGlobal.ShellExecute("open", commonlib.Encoding.DefaultToUtf8(folder), "", "", 1); 
--					end
--				end
--			end, _guihelper.MessageBoxButtons.YesNo);
--        end
--    end})
--
--    timer:Change(0, 1000)
end

function NplMicroRobot.GetCode(code)
	if(not NplMicroRobot.templateCode) then
			NplMicroRobot.templateCode = [[
start_NplMicroRobot();
%s
]]
	end
    local s = string.format(NplMicroRobot.templateCode, code or "");
    return s
end

-- custom compiler here: 
-- @param codeblock: code block object here
function NplMicroRobot.CompileCode(code, filename, codeblock)
    code = NplMicroRobot.GetCode(code);
	local compiler = CodeCompiler:new():SetFilename(filename)
	return compiler:Compile(code);
end